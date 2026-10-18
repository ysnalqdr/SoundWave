import '../constants/app_constants.dart';
import '../models/pesanan_tiket_model.dart';
import '../models/tiket_konser_model.dart';

/// Angka-angka ringkas untuk Dashboard Admin.
///
/// Semua dihitung dari stream yang SUDAH dipakai layar lain
/// (`allOrdersProvider`, `allTicketsProvider`, `eventsProvider`) — tidak ada
/// query Firestore baru, jadi kuota Spark tidak bertambah karena dashboard.
///
/// Dipisah dari widget supaya bisa diuji tanpa Flutter widget test.
class RingkasanAdmin {
  /// Uang yang benar-benar masuk: pesanan AKTIF + TERPAKAI.
  /// Pesanan REFUNDED tidak dihitung, REFUND_REQUESTED belum diputuskan.
  final double pendapatan;

  /// Jumlah lembar tiket dari pesanan yang sudah lunas.
  final int tiketTerjual;

  /// Pesanan yang masih menunggu pembayaran (RESERVED / PENDING).
  final int menungguBayar;

  /// Bagian dari [menungguBayar] yang sisa waktunya < 10 menit.
  final int hampirKedaluwarsa;

  /// Pesanan yang meminta / ditandai perlu refund dan belum diputuskan.
  final int refundPerluTinjauan;

  /// Kategori tiket dengan sisa kuota <= 10 (termasuk yang sudah habis).
  final int stokKritis;

  /// Total pesanan apa pun statusnya.
  final int totalPesanan;

  /// Tanggal 7 hari terakhir (paling lama di indeks 0, hari ini di indeks 6).
  final List<DateTime> hari;

  /// Pendapatan per hari, sejajar dengan [hari].
  final List<double> penjualanHarian;

  const RingkasanAdmin({
    required this.pendapatan,
    required this.tiketTerjual,
    required this.menungguBayar,
    required this.hampirKedaluwarsa,
    required this.refundPerluTinjauan,
    required this.stokKritis,
    required this.totalPesanan,
    required this.hari,
    required this.penjualanHarian,
  });

  /// Rata-rata pendapatan per hari selama 7 hari terakhir.
  double get rataHarian {
    if (penjualanHarian.isEmpty) return 0;
    final total = penjualanHarian.fold<double>(0, (a, b) => a + b);
    return total / penjualanHarian.length;
  }

  /// Hari dengan pendapatan tertinggi (null bila belum ada penjualan).
  DateTime? get hariTerbaik {
    if (penjualanHarian.isEmpty) return null;
    var idx = 0;
    for (var i = 1; i < penjualanHarian.length; i++) {
      if (penjualanHarian[i] > penjualanHarian[idx]) idx = i;
    }
    return penjualanHarian[idx] <= 0 ? null : hari[idx];
  }

  /// True bila tidak ada satu pun hal yang perlu ditangani operator.
  bool get tenang =>
      hampirKedaluwarsa == 0 && refundPerluTinjauan == 0 && stokKritis == 0;
}

/// Batas sisa kuota yang dianggap kritis.
const int batasStokKritis = 10;

/// Batas waktu (menit) sebuah reservasi dianggap "hampir kedaluwarsa".
const int batasHampirKedaluwarsaMenit = 10;

const Set<String> _statusLunas = {
  AppConstants.orderStatusActive,
  AppConstants.orderStatusUsed,
};

bool _hariSama(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

RingkasanAdmin hitungRingkasan({
  required List<PesananTiketModel> pesanan,
  required List<TiketKonserModel> tiket,
  DateTime? sekarang,
}) {
  final kini = sekarang ?? DateTime.now();
  final awalHariIni = DateTime(kini.year, kini.month, kini.day);

  // 7 hari terakhir, hari ini paling kanan.
  final hari = List<DateTime>.generate(
    7,
    (i) => awalHariIni.subtract(Duration(days: 6 - i)),
  );
  final penjualanHarian = List<double>.filled(7, 0);

  var pendapatan = 0.0;
  var tiketTerjual = 0;
  var menungguBayar = 0;
  var hampirKedaluwarsa = 0;
  var refundPerlu = 0;

  for (final o in pesanan) {
    final lunas = _statusLunas.contains(o.status);
    if (lunas) {
      pendapatan += o.totalHarga;
      tiketTerjual += o.jumlahTiket;
    }

    if (o.isPending) {
      menungguBayar++;
      final batas = o.reservedUntil;
      if (batas != null) {
        final sisa = batas.difference(kini).inMinutes;
        if (sisa >= 0 && sisa < batasHampirKedaluwarsaMenit) {
          hampirKedaluwarsa++;
        }
      }
    }

    if (o.isRefundRequested || o.isRefundRequired) {
      refundPerlu++;
    }

    // Grafik 7 hari memakai pesanan lunas saja.
    if (lunas) {
      for (var i = 0; i < hari.length; i++) {
        if (_hariSama(hari[i], o.tanggalBeli)) {
          penjualanHarian[i] += o.totalHarga;
          break;
        }
      }
    }
  }

  final stokKritis =
      tiket.where((t) => t.stok <= batasStokKritis).length;

  return RingkasanAdmin(
    pendapatan: pendapatan,
    tiketTerjual: tiketTerjual,
    menungguBayar: menungguBayar,
    hampirKedaluwarsa: hampirKedaluwarsa,
    refundPerluTinjauan: refundPerlu,
    stokKritis: stokKritis,
    totalPesanan: pesanan.length,
    hari: hari,
    penjualanHarian: penjualanHarian,
  );
}
