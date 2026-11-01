import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class PesananTiketModel {
  String id;
  String kodeBooking;
  final String idKonser;
  final String judulKonser;
  final String gambarKonser;
  final String kategoriTiket;
  final String? idTiket;
  final int jumlahTiket;
  final double totalHarga;
  final DateTime tanggalBeli;
  final DateTime tanggalKonser;
  final String lokasiKonser;
  final String namaPembeli;
  final String emailPembeli;
  final String? teleponPembeli;
  final String? metodePembayaran;
  String status;
  DateTime? tanggalDigunakan;
  DateTime? reservedUntil;
  final String userId;
  String? snapToken;
  String? snapRedirectUrl;
  String? qrPayloadSignature;
  Map<String, dynamic>? paymentDetails;

  /// Status refund terakhir pada level ORDER ('REJECTED' bila ditolak).
  ///
  /// Dibaca dari dokumen ORDER, bukan koleksi `refunds`: aturan Firestore
  /// menolak query tanpa filter `userId` ("rules are not filters"), jadi
  /// catatan penolakan tidak pernah muncul walau datanya ada.
  final String? refundStatus;
  final String? refundRejectReason;

  // ---------------------------------------------------------- rincian harga
  //
  // Sebelum Okt 2026, pesanan hanya menyimpan `totalHarga`. Akibatnya:
  //   * voucher yang dipakai pembeli tidak punya jejak — refund menghitung
  //     ulang dari total penuh, padahal pembeli sudah dapat potongan;
  //   * pajak dan biaya layanan tidak terlihat di struk;
  //   * backend tidak bisa memverifikasi bahwa potongan memang sah.
  //
  // Semua nilai di bawah ini ditulis backend saat pesanan dibuat, memakai
  // rumus yang sama dengan `lib/utils/rincian_harga.dart`.
  /// Harga tiket sebelum potongan & biaya: `hargaSatuan x jumlahTiket`.
  final double subtotal;

  /// Kode voucher yang dipakai, mis. `EARLYBIRD50`. Null bila tanpa voucher.
  final String? kodePromo;

  /// Potongan voucher dalam rupiah (sudah dibatasi subtotal).
  final double diskon;

  /// Pajak hiburan (PBJT) 10% dari dasar setelah potongan.
  final double pajak;

  /// Biaya layanan 5% dari dasar setelah potongan.
  final double biayaLayananPersen;

  /// Biaya layanan tetap per transaksi.
  final double biayaLayananTetap;

  PesananTiketModel({
    required this.id,
    required this.kodeBooking,
    required this.idKonser,
    required this.judulKonser,
    required this.gambarKonser,
    required this.kategoriTiket,
    this.idTiket,
    required this.jumlahTiket,
    required this.totalHarga,
    required this.tanggalBeli,
    required this.tanggalKonser,
    required this.lokasiKonser,
    required this.namaPembeli,
    required this.emailPembeli,
    required this.userId,
    this.teleponPembeli,
    this.metodePembayaran,
    this.status = AppConstants.orderStatusPending,
    this.tanggalDigunakan,
    this.reservedUntil,
    this.snapToken,
    this.snapRedirectUrl,
    this.qrPayloadSignature,
    this.paymentDetails,
    this.refundStatus,
    this.refundRejectReason,
    this.subtotal = 0,
    this.kodePromo,
    this.diskon = 0,
    this.pajak = 0,
    this.biayaLayananPersen = 0,
    this.biayaLayananTetap = 0,
  });

  factory PesananTiketModel.fromMap(Map<String, dynamic> map, String id) {
    return PesananTiketModel(
      id: id,
      kodeBooking: map['kodeBooking'] ?? '',
      idKonser: map['idKonser'] ?? '',
      judulKonser: map['judulKonser'] ?? '',
      gambarKonser: map['gambarKonser'] ?? '',
      kategoriTiket: map['kategoriTiket'] ?? '',
      idTiket: map['idTiket'],
      jumlahTiket: (map['jumlahTiket'] as num?)?.toInt() ?? 0,
      totalHarga: (map['totalHarga'] ?? 0.0).toDouble(),
      tanggalBeli:
          (map['tanggalBeli'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tanggalKonser:
          (map['tanggalKonser'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lokasiKonser: map['lokasiKonser'] ?? '',
      namaPembeli: map['namaPembeli'] ?? '',
      emailPembeli: map['emailPembeli'] ?? '',
      teleponPembeli: map['teleponPembeli'],
      metodePembayaran: map['metodePembayaran'],
      userId: map['userId'] ?? '',
      status: map['status'] ?? AppConstants.orderStatusPending,
      tanggalDigunakan: (map['tanggalDigunakan'] as Timestamp?)?.toDate(),
      reservedUntil: (map['reservedUntil'] as Timestamp?)?.toDate(),
      snapToken: map['snapToken'],
      snapRedirectUrl: map['snapRedirectUrl'],
      qrPayloadSignature: map['qrPayloadSignature'],
      paymentDetails: map['paymentDetails'] != null
          ? Map<String, dynamic>.from(map['paymentDetails'] as Map)
          : null,
      refundStatus: map['refundStatus'],
      refundRejectReason: map['refundRejectReason'],
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      kodePromo: map['kodePromo'],
      diskon: (map['diskon'] as num?)?.toDouble() ?? 0,
      pajak: (map['pajak'] as num?)?.toDouble() ?? 0,
      biayaLayananPersen:
          (map['biayaLayananPersen'] as num?)?.toDouble() ?? 0,
      biayaLayananTetap:
          (map['biayaLayananTetap'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kodeBooking': kodeBooking,
      'idKonser': idKonser,
      'judulKonser': judulKonser,
      'gambarKonser': gambarKonser,
      'kategoriTiket': kategoriTiket,
      'idTiket': idTiket,
      'jumlahTiket': jumlahTiket,
      'totalHarga': totalHarga,
      'tanggalBeli': Timestamp.fromDate(tanggalBeli),
      'tanggalKonser': Timestamp.fromDate(tanggalKonser),
      'lokasiKonser': lokasiKonser,
      'namaPembeli': namaPembeli,
      'emailPembeli': emailPembeli,
      'teleponPembeli': teleponPembeli,
      'metodePembayaran': metodePembayaran,
      'userId': userId,
      'status': status,
      'tanggalDigunakan': tanggalDigunakan != null
          ? Timestamp.fromDate(tanggalDigunakan!)
          : null,
      'reservedUntil': reservedUntil != null
          ? Timestamp.fromDate(reservedUntil!)
          : null,
      'snapToken': snapToken,
      'snapRedirectUrl': snapRedirectUrl,
      'qrPayloadSignature': qrPayloadSignature,
      'paymentDetails': paymentDetails,
      // Diisi backend (approve/reject refund); ditulis apa adanya.
      'refundStatus': refundStatus,
      'refundRejectReason': refundRejectReason,
      // Rincian harga: ditulis backend, dibaca aplikasi untuk struk.
      'subtotal': subtotal,
      'kodePromo': kodePromo,
      'diskon': diskon,
      'pajak': pajak,
      'biayaLayananPersen': biayaLayananPersen,
      'biayaLayananTetap': biayaLayananTetap,
    };
  }

  /// Menunggu pembayaran: PENDING (pesanan baru, stok belum dipotong) atau
  /// RESERVED (stok sudah dipotong saat pembayaran dimulai).
  bool get isPending =>
      status == AppConstants.orderStatusPending ||
      status == AppConstants.orderStatusReserved;
  bool get isAktif =>
      status == AppConstants.orderStatusActive ||
      status == AppConstants.orderStatusPaid;
  bool get isTerpakai => status == AppConstants.orderStatusUsed;
  bool get isCancelled => status == AppConstants.orderStatusCancelled;
  bool get isExpired =>
      status == AppConstants.orderStatusExpired ||
      (isPending &&
          (reservedUntil != null
              ? !DateTime.now().isBefore(reservedUntil!)
              : DateTime.now().difference(tanggalBeli).inHours >= 24));
  bool get isRefundRequired =>
      status == AppConstants.orderStatusRefundRequired ||
      status == AppConstants.orderStatusRefundRequested;
  bool get isRefundRequested =>
      status == AppConstants.orderStatusRefundRequested;
  bool get isRefunded => status == AppConstants.orderStatusRefunded;

  /// True bila pengajuan refund terakhir DITOLAK admin. Tiketnya sendiri tetap
  /// bisa dipakai (backend mengembalikan status order ke AKTIF/TERPAKAI).
  bool get refundDitolak => refundStatus == 'REJECTED';

  /// Alasan penolakan dari admin ('' bila admin tidak menulis catatan).
  String get alasanRefundDitolak => refundRejectReason?.trim() ?? '';

  String get formatTotalHarga {
    final formatted = totalHarga
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }

  PesananTiketModel copyWith({
    String? id,
    String? kodeBooking,
    String? status,
    DateTime? tanggalDigunakan,
    DateTime? reservedUntil,
    String? userId,
    String? snapToken,
    String? snapRedirectUrl,
    String? qrPayloadSignature,
    Map<String, dynamic>? paymentDetails,
    String? refundStatus,
    String? refundRejectReason,
  }) {
    return PesananTiketModel(
      id: id ?? this.id,
      kodeBooking: kodeBooking ?? this.kodeBooking,
      idKonser: idKonser,
      judulKonser: judulKonser,
      gambarKonser: gambarKonser,
      kategoriTiket: kategoriTiket,
      idTiket: idTiket,
      jumlahTiket: jumlahTiket,
      totalHarga: totalHarga,
      tanggalBeli: tanggalBeli,
      tanggalKonser: tanggalKonser,
      lokasiKonser: lokasiKonser,
      namaPembeli: namaPembeli,
      emailPembeli: emailPembeli,
      teleponPembeli: teleponPembeli,
      metodePembayaran: metodePembayaran,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      tanggalDigunakan: tanggalDigunakan ?? this.tanggalDigunakan,
      reservedUntil: reservedUntil ?? this.reservedUntil,
      snapToken: snapToken ?? this.snapToken,
      snapRedirectUrl: snapRedirectUrl ?? this.snapRedirectUrl,
      qrPayloadSignature: qrPayloadSignature ?? this.qrPayloadSignature,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      refundStatus: refundStatus ?? this.refundStatus,
      refundRejectReason: refundRejectReason ?? this.refundRejectReason,
      // Rincian harga ikut disalin apa adanya. `copyWith` tidak menerima
      // parameter untuk field ini karena nilainya ditetapkan backend saat
      // pesanan dibuat dan tidak boleh berubah setelahnya.
      subtotal: subtotal,
      kodePromo: kodePromo,
      diskon: diskon,
      pajak: pajak,
      biayaLayananPersen: biayaLayananPersen,
      biayaLayananTetap: biayaLayananTetap,
    );
  }
}
