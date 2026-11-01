/// Angka ringkas pesanan untuk Dashboard Admin, dihitung **di server**.
///
/// Dipisah dari [RingkasanAdmin] karena asalnya berbeda:
///
/// * [StatistikPesanan] datang dari **agregasi Firestore** (`count()` dan
///   `sum()`), yang tidak mengunduh satu dokumen pun. Ini yang dipakai untuk
///   KPI, dan biayanya tetap meski riwayat pesanan sudah puluhan ribu.
/// * [RingkasanAdmin] dihitung di HP dari daftar pesanan yang diunduh. Itu
///   hanya layak untuk jendela kecil (grafik 7 hari), bukan seluruh riwayat.
///
/// Memisahkan keduanya membuat jelas mana angka yang murah dan mana yang
/// butuh data mentah.
class StatistikPesanan {
  /// Uang yang benar-benar masuk: pesanan AKTIF + TERPAKAI.
  final double pendapatan;

  /// Jumlah lembar tiket dari pesanan lunas.
  final int tiketTerjual;

  /// Pesanan menunggu pembayaran (PENDING / RESERVED).
  final int menungguBayar;

  /// Refund yang belum diputuskan (REFUND_REQUESTED / REFUND_REQUIRED).
  final int refundPerluTinjauan;

  /// Total pesanan apa pun statusnya.
  final int totalPesanan;

  const StatistikPesanan({
    required this.pendapatan,
    required this.tiketTerjual,
    required this.menungguBayar,
    required this.refundPerluTinjauan,
    required this.totalPesanan,
  });

  static const StatistikPesanan kosong = StatistikPesanan(
    pendapatan: 0,
    tiketTerjual: 0,
    menungguBayar: 0,
    refundPerluTinjauan: 0,
    totalPesanan: 0,
  );
}
