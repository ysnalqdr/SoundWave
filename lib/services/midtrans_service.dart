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

  // Lama cache alamat backend. Pendek, supaya tunnel yang di-restart
  // tidak membuat APK memakai alamat mati terlalu lama.
  static const Duration _umurCache = Duration(seconds: 60);

  // Batas tunggu satu permintaan ke backend.
  static const Duration _batasTunggu = Duration(seconds: 25);

  // Pesan yang dilihat user saat server tidak bisa dihubungi.
  static const String pesanServerMati =
      'Server pembayaran sedang tidak bisa dihubungi. Coba lagi sebentar.';

  // Pesan saat alamat backend belum tersedia sama sekali.
  static const String pesanServerBelumSiap =
      'Server pembayaran belum siap. Pastikan START_SOUNDWAVE sedang berjalan, lalu coba lagi.';

  static String? _cachedBackendUrl;
  static DateTime? _lastFetch;

  /// Drops the cached address so the next request re-reads Firestore.
  static void lupakanCacheUrl() {
    _cachedBackendUrl = null;
    _lastFetch = null;
  }

  /// Resolves the backend URL from Firestore. No fallback address is baked
  /// in, so a missing value fails with a clear message instead of calling
  /// a tunnel that is already dead.
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

  /// True when [e] means the server was unreachable, not a server error.
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

  /// User-facing message. Never leaks exception text.
  static String _pesanGalat(Object e, String awalan) {
    if (e is ServerTidakTerhubungException) return e.pesan;
    if (e is FormatException) {
      return 'Jawaban server tidak dikenali. Coba lagi sebentar.';
    }
    if (_galatKoneksi(e)) return pesanServerMati;
    return '$awalan. Coba lagi sebentar.';
  }

  /// Public form of [pesanRamah] for screens that catch their own errors.
  static String pesanRamah(Object e, String awalan) => _pesanGalat(e, awalan);

  // Header rute /admin/*. Backend menolak token yang bukan milik admin
  // (lihat auth_admin.js).
  static Future<Map<String, String>> kepalaAdmin() async {
    final pengguna = FirebaseAuth.instance.currentUser;
    final token = await pengguna?.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Sends a request to the backend using a freshly resolved address.
  ///
  /// A network or address-not-found failure drops the cache, re-reads
  /// Firestore, and retries once, so the app survives a tunnel restart.
  static Future<http.Response> _kirim(
    String jalur, {
    String metode = 'POST',
    Map<String, String>? headers,
    String? body,
  }) async {
    // Setiap permintaan membawa ID token pengguna. Backend memakai token
    // itu sebagai identitas, bukan userId yang dikirim di body.
    final kepala = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };
    if (!kepala.containsKey('Authorization')) {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) kepala['Authorization'] = 'Bearer $token';
    }

    Future<http.Response> sekali(String baseUrl) {
      final uri = Uri.parse('$baseUrl$jalur');
      switch (metode) {
        case 'GET':
          return http.get(uri, headers: kepala).timeout(_batasTunggu);
        case 'DELETE':
          return http
              .delete(uri, headers: kepala, body: body)
              .timeout(_batasTunggu);
        default:
          return http
              .post(uri, headers: kepala, body: body)
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

  /// Reserves stock and creates a Snap token in one backend transaction,
  /// which avoids overselling on popular tickets.
  /// Returns a map with `success`, `token`, `redirect_url`,
  /// `ticketRevision`, `conflict` (true on a 409 revision mismatch), and
  /// `message`.
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

      // 409 Conflict: stok atau revision berubah.
      if (response.statusCode == 409) {
        return {
          'success': false,
          'conflict': true,
          'message': data['message'] ?? 'Stok tiket berubah',
          'currentRevision': data['currentRevision'],
        };
      }

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

  /// Dev/sandbox helper: settles a payment when the Snap UI is unavailable.
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

  /// Creates a bank transfer virtual account (bca, bni, or mandiri).
  /// Returns `{ success, va_number, bank, expires_at, order_id }`.
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

  /// Creates a GoPay QR charge, valid for 5 minutes.
  /// Returns `{ success, qr_string, qr_image_url, expires_at, order_id }`.
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

  /// Creates a QRIS charge, valid for 5 minutes.
  /// Returns `{ success, qr_string, qr_image_url, expires_at, order_id }`.
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

  /// Polls Midtrans payment status.
  /// Returns `{ success, transaction_status, status, is_paid }`.
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


  /// Validates a promo code before checkout.
  /// Sweeps reservations whose payment window has passed: status becomes
  /// EXPIRED and stock is released once. The backend sweeps every 30
  /// seconds on its own, so this only speeds up the ticket screen.
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


  /// Asks the backend to refund an order.
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

  /// Lists refund requests, optionally filtered by status.
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

  /// Approves a refund request. Money is returned manually by the admin.
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

  /// Rejects a refund and returns the order to AKTIF, or TERPAKAI when the
  /// ticket was already scanned.
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


  /// Returns invoice details for an order.
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


  /// Returns the seat layout and the seats already booked for a concert.
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

  /// Reserves seats atomically.
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

  /// Releases a seat booking.
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

/// Thrown when the backend cannot be reached at all.
///
/// [toString] returns only the user-facing message, never technical detail
/// such as `ClientException with SocketException`.
class ServerTidakTerhubungException implements Exception {
  final String pesan;
  const ServerTidakTerhubungException(
      [this.pesan = MidtransService.pesanServerMati]);

  @override
  String toString() => pesan;
}
