import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

/// Client-side Midtrans bridge. Server key never leaves backend.
class MidtransService {
  static final MidtransService _instance = MidtransService._internal();
  factory MidtransService() => _instance;
  MidtransService._internal();

  /// Lama cache alamat backend. Dulu 10 menit: kalau tunnel di-restart,
  /// APK masih memakai alamat mati sampai 10 menit ke depan.
  static const Duration _umurCache = Duration(seconds: 60);

  /// Batas tunggu satu permintaan ke backend.
  static const Duration _batasTunggu = Duration(seconds: 25);

  /// Pesan yang dilihat user saat server tidak bisa dihubungi.
  static const String pesanServerMati =
      'Server pembayaran sedang tidak bisa dihubungi. Coba lagi sebentar.';

  /// Pesan saat alamat backend belum tersedia sama sekali.
  static const String pesanServerBelumSiap =
      'Server pembayaran belum siap. Pastikan START_SOUNDWAVE sedang berjalan, lalu coba lagi.';

  static String? _cachedBackendUrl;
  static DateTime? _lastFetch;

  /// Buang alamat tersimpan supaya permintaan berikutnya membaca ulang
  /// dari Firestore.
  static void lupakanCacheUrl() {
    _cachedBackendUrl = null;
    _lastFetch = null;
  }

  /// Ambil URL backend dinamis dari Firestore.
  ///
  /// Tidak ada alamat cadangan yang ditanam di kode: kalau Firestore tidak
  /// memberi alamat yang sah, permintaan dihentikan dengan pesan jelas
  /// daripada mencoba alamat tunnel lama yang sudah mati.
  static Future<String> getBackendUrl({bool paksa = false}) async {
    if (!paksa &&
        _cachedBackendUrl != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _umurCache) {
      return _cachedBackendUrl!;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('events')
          .doc('_backend_config')
          .get();
      final u = (doc.data()?['url'] as String?)?.trim();
      if (u != null && u.isNotEmpty) {
        _cachedBackendUrl = u;
        _lastFetch = DateTime.now();
        return u;
      }
    } catch (_) {}
    // Firestore tidak terjangkau: alamat lama masih lebih baik daripada tidak.
    if (_cachedBackendUrl != null) return _cachedBackendUrl!;
    throw const ServerTidakTerhubungException(pesanServerBelumSiap);
  }

  /// Benar bila [e] berarti "tidak bisa menghubungi server", bukan jawaban
  /// error dari server.
  static bool _galatKoneksi(Object e) {
    if (e is ServerTidakTerhubungException) return true;
    if (e is http.ClientException) return true;
    if (e is TimeoutException) return true;
    final t = e.toString().toLowerCase();
    return t.contains('socketexception') ||
        t.contains('clientexception') ||
        t.contains('failed host lookup') ||
        t.contains('connection refused') ||
        t.contains('connection closed') ||
        t.contains('timed out') ||
        t.contains('network is unreachable');
  }

  /// Pesan siap tampil untuk user — tidak pernah membocorkan teks exception.
  static String _pesanGalat(Object e, String awalan) {
    if (e is ServerTidakTerhubungException) return e.pesan;
    if (e is FormatException) {
      return 'Jawaban server tidak dikenali. Coba lagi sebentar.';
    }
    if (_galatKoneksi(e)) return pesanServerMati;
    return '$awalan. Coba lagi sebentar.';
  }

  /// Versi publik [pesanRamah] untuk layar yang menangkap exception sendiri.
  static String pesanRamah(Object e, String awalan) => _pesanGalat(e, awalan);

  /// Kirim permintaan ke backend dengan alamat yang selalu segar.
  ///
  /// Kalau percobaan pertama gagal karena jaringan / alamat tidak ditemukan,
  /// cache dibuang, alamat dibaca ulang dari Firestore, lalu dicoba SEKALI
  /// lagi. Ini yang membuat APK tetap jalan setelah tunnel di-restart.
  /// Header untuk rute /admin/*. Backend menolak permintaan yang tidak
  /// membawa ID token milik akun ber-role admin (lihat auth_admin.js).
  static Future<Map<String, String>> kepalaAdmin() async {
    final pengguna = FirebaseAuth.instance.currentUser;
    final token = await pengguna?.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> _kirim(
    String jalur, {
    String metode = 'POST',
    Map<String, String>? headers,
    String? body,
  }) async {
    Future<http.Response> sekali(String baseUrl) {
      final uri = Uri.parse('$baseUrl$jalur');
      switch (metode) {
        case 'GET':
          return http.get(uri, headers: headers).timeout(_batasTunggu);
        case 'DELETE':
          return http
              .delete(uri, headers: headers, body: body)
              .timeout(_batasTunggu);
        default:
          return http
              .post(uri, headers: headers, body: body)
              .timeout(_batasTunggu);
      }
    }

    final urlAwal = await getBackendUrl();
    try {
      return await sekali(urlAwal);
    } catch (e) {
      if (!_galatKoneksi(e)) rethrow;
      lupakanCacheUrl();
      final urlBaru = await getBackendUrl(paksa: true);
      try {
        return await sekali(urlBaru);
      } catch (e2) {
        if (_galatKoneksi(e2)) {
          throw const ServerTidakTerhubungException(pesanServerMati);
        }
        rethrow;
      }
    }
  }

  /// Asks backend to create a Snap transaction for [orderId].
  Future<Map<String, dynamic>> createSnapToken({
    required String orderId,
    required double amount,
    required String customerName,
    required String customerEmail,
    String? customerPhone,
    String itemName = 'Tiket Konser SoundWave',
  }) async {
    try {
      final response = await _kirim('/create-transaction',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orderId': orderId,
          'amount': amount.toInt(),
          'customerName': customerName,
          'customerEmail': customerEmail,
          'customerPhone': customerPhone,
          'itemName': itemName,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': data['success'] == true,
        'token': data['token'],
        'redirect_url': data['redirect_url'],
        'order_id': orderId,
        'message': data['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': _pesanGalat(e, 'Gagal menghubungi server pembayaran'),
      };
    }
  }

  /// Atomic checkout: reserve tiket + create Snap token dalam 1 transaction
  /// Menghindari race condition pada tiket viral
  /// 
  /// Returns:
  /// - success: true/false
  /// - token: Snap token (jika sukses)
  /// - redirect_url: Snap payment URL
  /// - ticketRevision: versi ticket saat ini (untuk retry jika conflict)
  /// - conflict: true jika terjadi revision mismatch (409)
  /// - message: error message
  Future<Map<String, dynamic>> checkoutAtomic({
    required String orderId,
    required String ticketId,
    required int jumlahTiket,
    required int? revisionCounter,
    String? metodePembayaran,
  }) async {
    try {
      final response = await _kirim('/checkout-atomic',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orderId': orderId,
          'ticketId': ticketId,
          'jumlahTiket': jumlahTiket,
          'revisionCounter': revisionCounter,
          if (metodePembayaran != null && metodePembayaran.isNotEmpty)
            'metodePembayaran': metodePembayaran,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // 409 Conflict: stok atau revision berubah
      if (response.statusCode == 409) {
        return {
          'success': false,
          'conflict': true,
          'message': data['message'] ?? 'Stok tiket berubah',
          'currentRevision': data['currentRevision'],
        };
      }

      // Sukses atau error lainnya
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'token': data['token'],
        'redirect_url': data['redirect_url'],
        'order_id': orderId,
        'ticketRevision': data['ticketRevision'],
        'message': data['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': _pesanGalat(e, 'Gagal menghubungi server checkout'),
      };
    }
  }

  /// Dev/sandbox helper: settle payment via backend when Snap UI unavailable.
  Future<Map<String, dynamic>> settleOrderDev(String orderId) async {
    try {
      final response = await _kirim('/settle-dev',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'orderId': orderId}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': data['success'] == true,
        'message': data['message'] ?? 'Pembayaran berhasil',
      };
    } catch (e) {
      return {
        'success': false,
        'message': _pesanGalat(e, 'Gagal menyelesaikan pembayaran'),
      };
    }
  }

  /// POST /create-va — buat Virtual Account untuk Transfer Bank (bca/bni/mandiri)
  /// Return: { success, va_number, bank, expires_at, order_id, ... }
  Future<Map<String, dynamic>> createVA({
    required String orderId,
    required String bank,
  }) async {
    try {
      final response = await _kirim('/create-va',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orderId': orderId,
          'bank': bank.toLowerCase(),
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'va_number': data['va_number'],
        'bank': data['bank'],
        'bill_key': data['bill_key'],
        'biller_code': data['biller_code'],
        'expires_at': data['expires_at'],
        'order_id': data['order_id'] ?? orderId,
        'transaction_status': data['transaction_status'] ?? 'pending',
        'message': data['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': _pesanGalat(e, 'Gagal membuat Virtual Account'),
      };
    }
  }

  /// POST /create-gopay — buat transaksi GoPay + QR code (berlaku 5 menit)
  /// Return: { success, qr_string, qr_image_url, expires_at, order_id, ... }
  Future<Map<String, dynamic>> createGoPay({required String orderId}) async {
    try {
      final response = await _kirim('/create-gopay',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'orderId': orderId}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'qr_string': data['qr_string'],
        'qr_image_url': data['qr_image_url'],
        'expires_at': data['expires_at'],
        'order_id': data['order_id'] ?? orderId,
        'transaction_status': data['transaction_status'] ?? 'pending',
        'message': data['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': _pesanGalat(e, 'Gagal membuat QR GoPay'),
      };
    }
  }

  /// POST /create-qris — buat transaksi QRIS + QR code (berlaku 5 menit)
  /// Return: { success, qr_string, qr_image_url, expires_at, order_id, ... }
  Future<Map<String, dynamic>> createQRIS({required String orderId}) async {
    try {
      final response = await _kirim('/create-qris',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'orderId': orderId}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'qr_string': data['qr_string'],
        'qr_image_url': data['qr_image_url'],
        'expires_at': data['expires_at'],
        'order_id': data['order_id'] ?? orderId,
        'transaction_status': data['transaction_status'] ?? 'pending',
        'message': data['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': _pesanGalat(e, 'Gagal membuat QR QRIS'),
      };
    }
  }

  /// POST /poll-payment — cek status pembayaran Midtrans secara periodik
  /// Return: { success, transaction_status, status, is_paid, ... }
  Future<Map<String, dynamic>> pollPayment({required String orderId}) async {
    try {
      final response = await _kirim('/poll-payment',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'orderId': orderId}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final isPaid = data['is_paid'] == true;
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'transaction_status': data['transaction_status'] ?? 'pending',
        'status': data['status'] ?? 'PENDING',
        'is_paid': isPaid,
        'payment_type': data['payment_type'],
        'message': data['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'is_paid': false,
        'transaction_status': 'pending',
        'status': 'PENDING',
        'message': _pesanGalat(e, 'Gagal mengecek status pembayaran'),
      };
    }
  }

  String mapTransactionStatus(String midtransStatus) {
    switch (midtransStatus) {
      case 'capture':
      case 'settlement':
        return AppConstants.orderStatusActive;
      case 'pending':
        return AppConstants.orderStatusPending;
      case 'deny':
      case 'cancel':
      case 'expire':
        return AppConstants.orderStatusCancelled;
      default:
        return AppConstants.orderStatusPending;
    }
  }

  // ══════════════════════════════════════════
  // PROMO CODES
  // ══════════════════════════════════════════

  /// POST /validate-promo — validasi kode promo
  /// Minta backend menyapu reservasi yang jendela bayarnya sudah lewat
  /// (status -> EXPIRED, stok dilepas SEKALI). Backend juga menyapu sendiri
  /// tiap 30 detik; panggilan ini hanya mempercepat saat layar tiket dibuka.
  Future<Map<String, dynamic>> sweepExpired() async {
    try {
      final response = await _kirim('/sweep-expired',
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode != 200) {
        return {'success': false, 'message': 'HTTP ${response.statusCode}'};
      }
      final data = jsonDecode(response.body);
      return data is Map<String, dynamic> ? data : {'success': false};
    } catch (e) {
      return {
        'success': false,
        'message': _pesanGalat(e, 'Gagal menyapu reservasi kedaluwarsa'),
      };
    }
  }

  Future<Map<String, dynamic>> validatePromo({
    required String kode,
    required String idKonser,
    required double subtotal,
  }) async {
    try {
      final response = await _kirim('/validate-promo',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'kode': kode,
          'idKonser': idKonser,
          'subtotal': subtotal,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'valid': data['valid'] == true,
        'tipe': data['tipe'],
        'nilai': data['nilai'],
        'discountAmount': data['discountAmount'],
        'deskripsi': data['deskripsi'],
        'message': data['message'],
      };
    } catch (e) {
      return {'valid': false, 'message': _pesanGalat(e, 'Gagal validasi promo')};
    }
  }

  // ══════════════════════════════════════════
  // REFUND WORKFLOW
  // ══════════════════════════════════════════

  /// POST /request-refund — user minta refund
  Future<Map<String, dynamic>> requestRefund({
    required String orderId,
    required String userId,
    required String alasan,
  }) async {
    try {
      final response = await _kirim('/request-refund',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orderId': orderId,
          'userId': userId,
          'alasan': alasan,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': data['success'] == true,
        'refundId': data['refundId'],
        'message': data['message'],
      };
    } catch (e) {
      return {'success': false, 'message': _pesanGalat(e, 'Gagal mengajukan refund')};
    }
  }

  /// GET /admin/refunds — list semua refund
  Future<Map<String, dynamic>> getRefunds({String? status}) async {
    try {
      final response = await _kirim(
        '/admin/refunds${status != null ? '?status=\$status' : ''}',
        metode: 'GET',
        headers: await kepalaAdmin(),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': data['success'] == true,
        'refunds': data['refunds'] ?? [],
      };
    } catch (e) {
      return {
        'success': false,
        'refunds': [],
        'message': _pesanGalat(e, 'Gagal memuat daftar refund'),
      };
    }
  }

  /// POST /admin/refund/approve — admin setujui refund
  Future<Map<String, dynamic>> approveRefund({
    required String refundId,
    required String orderId,
  }) async {
    try {
      final response = await _kirim('/admin/refund/approve',
        headers: await kepalaAdmin(),
        body: jsonEncode({
          'refundId': refundId,
          'orderId': orderId,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': data['success'] == true,
        'message': data['message'],
      };
    } catch (e) {
      return {'success': false, 'message': _pesanGalat(e, 'Gagal approve refund')};
    }
  }

  /// POST /admin/refund/reject — admin tolak refund
  Future<Map<String, dynamic>> rejectRefund({
    required String refundId,
    required String alasanReject,
  }) async {
    try {
      final response = await _kirim('/admin/refund/reject',
        headers: await kepalaAdmin(),
        body: jsonEncode({
          'refundId': refundId,
          'alasanReject': alasanReject,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': data['success'] == true,
        'message': data['message'],
      };
    } catch (e) {
      return {'success': false, 'message': _pesanGalat(e, 'Gagal reject refund')};
    }
  }

  // ══════════════════════════════════════════
  // INVOICE
  // ══════════════════════════════════════════

  /// GET /invoice/:orderId — generate invoice
  Future<Map<String, dynamic>> getInvoice({required String orderId}) async {
    try {
      final response = await _kirim('/invoice/$orderId', metode: 'GET');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': data['success'] == true,
        'invoiceNumber': data['invoiceNumber'],
        'date': data['date'],
        'buyerName': data['buyerName'],
        'buyerEmail': data['buyerEmail'],
        'items': data['items'],
        'subtotal': data['subtotal'],
        'ppn': data['ppn'],
        'total': data['total'],
        'status': data['status'],
        'paymentMethod': data['paymentMethod'],
      };
    } catch (e) {
      return {'success': false, 'message': _pesanGalat(e, 'Gagal generate invoice')};
    }
  }

  // ══════════════════════════════════════════
  // SEAT SELECTION
  // ══════════════════════════════════════════

  /// GET /seat-layout/:idKonser — ambil layout kursi + booked seats
  Future<Map<String, dynamic>> getSeatLayout({required String idKonser}) async {
    try {
      final response = await _kirim('/seat-layout/$idKonser', metode: 'GET');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': data['success'] == true,
        'hasLayout': data['hasLayout'] == true,
        'kategori': data['kategori'] ?? [],
      };
    } catch (e) {
      return {'success': false, 'hasLayout': false, 'message': _pesanGalat(e, 'Gagal load seat layout')};
    }
  }

  /// POST /reserve-seats — booking kursi atomically
  Future<Map<String, dynamic>> reserveSeats({
    required String idKonser,
    required List<String> seats,
    required String orderId,
  }) async {
    try {
      final response = await _kirim('/reserve-seats',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idKonser': idKonser,
          'seats': seats,
          'orderId': orderId,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': data['success'] == true,
        'message': data['message'] ?? data['error'],
      };
    } catch (e) {
      return {'success': false, 'message': _pesanGalat(e, 'Gagal booking kursi')};
    }
  }

  /// DELETE /release-seats — lepas booking kursi
  Future<Map<String, dynamic>> releaseSeats({
    required String idKonser,
    required List<String> seats,
  }) async {
    try {
      final response = await _kirim('/release-seats', metode: 'DELETE',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idKonser': idKonser,
          'seats': seats,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': data['success'] == true,
        'message': data['message'],
      };
    } catch (e) {
      return {'success': false, 'message': _pesanGalat(e, 'Gagal release kursi')};
    }
  }
}

/// Dilempar saat backend tidak bisa dihubungi sama sekali.
///
/// [toString] sengaja hanya berisi pesan untuk user, tanpa detail teknis
/// seperti `ClientException with SocketException`.
class ServerTidakTerhubungException implements Exception {
  final String pesan;
  const ServerTidakTerhubungException(
      [this.pesan = MidtransService.pesanServerMati]);

  @override
  String toString() => pesan;
}
