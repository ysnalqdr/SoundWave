/// ============================================================================
/// RINCIAN HARGA CHECKOUT — SATU RUMUS UNTUK SEMUA
/// ============================================================================
///
/// Sebelum ini, total dihitung di dua tempat dengan rumus berbeda:
///
/// * **Klien** (`checkout_screen.dart`): `subtotal + 5000 - diskon`
/// * **Backend** (`server.js`): `harga x jumlah + 5000` — **tanpa diskon**
///
/// Akibatnya voucher yang dipilih pembeli **hilang** begitu pembayaran
/// dimulai: layar menampilkan Rp 95.000, Midtrans menagih Rp 105.000.
/// Itu bukan bug tampilan — itu bug uang.
///
/// Berkas ini menjadikan rumus itu satu: dipakai layar, dipakai pembuatan
/// pesanan, dan dicerminkan persis di `server.js` (`hitungRincianHarga`).
/// Kalau salah satu berubah, tes `rincian_harga_test.dart` gagal.
///
/// ## Urutan perhitungan (Opsi A — disepakati pemilik produk)
///
/// ```
/// subtotal        = hargaSatuan × jumlah
/// diskon          = voucher, dibatasi subtotal
/// dasar           = subtotal − diskon          ← dasar pengenaan pajak
/// pajak 10%       = dasar × 10%                ← PBJT / pajak hiburan
/// layanan 5%      = dasar × 5%
/// layanan tetap   = Rp 5.000
/// total           = dasar + pajak + layanan5% + layananTetap
/// ```
///
/// Pajak dan layanan dihitung **setelah** diskon, supaya pembeli tidak
/// membayar pajak atas uang yang tidak jadi ia keluarkan.
///
/// ## Kenapa semua angka `int`
///
/// Rupiah tidak punya sen. Setiap komponen dibulatkan sendiri, lalu total
/// adalah **jumlah komponen yang sudah dibulatkan**. Dengan begitu yang
/// tertulis di layar selalu sama dengan yang ditagih Midtrans — tidak ada
/// selisih beberapa rupiah karena pembulatan.
library;

/// Tarif pajak hiburan (PBJT) dalam persen.
const double tarifPajakPersen = 10.0;

/// Tarif biaya layanan berbasis persentase.
const double tarifLayananPersen = 5.0;

/// Biaya layanan tetap, ditambahkan sekali per transaksi.
const int biayaLayananTetap = 5000;

/// Rincian harga satu pesanan. Tidak menyentuh UI maupun jaringan, jadi
/// bisa diuji tanpa Flutter.
class RincianHarga {
  const RincianHarga({
    required this.hargaSatuan,
    required this.jumlah,
    this.diskon = 0,
    this.kodePromo,
  });

  final double hargaSatuan;
  final int jumlah;

  /// Potongan dari voucher. Sudah dalam rupiah, sudah dibatasi subtotal.
  final double diskon;

  /// Kode voucher yang dipakai, bila ada. Disimpan supaya pesanan punya
  /// jejak voucher mana yang menghasilkan potongan ini — tanpa itu, refund
  /// tidak bisa dihitung ulang dengan benar.
  final String? kodePromo;

  /// Harga sebelum potongan dan biaya.
  int get subtotal => (hargaSatuan * jumlah).round();

  /// Potongan yang benar-benar dipakai (tidak pernah melebihi subtotal).
  int get potongan {
    final d = diskon.round();
    if (d < 0) return 0;
    return d > subtotal ? subtotal : d;
  }

  /// Dasar pengenaan pajak & layanan: subtotal setelah potongan.
  int get dasar {
    final d = subtotal - potongan;
    return d < 0 ? 0 : d;
  }

  /// Pajak hiburan 10% dari [dasar].
  int get pajak => (dasar * tarifPajakPersen / 100).round();

  /// Biaya layanan 5% dari [dasar].
  int get layananPersen => (dasar * tarifLayananPersen / 100).round();

  /// Biaya layanan tetap per transaksi.
  int get layananTetap => biayaLayananTetap;

  /// Total biaya tambahan di luar harga tiket.
  int get totalBiaya => pajak + layananPersen + layananTetap;

  /// Angka yang ditagih Midtrans dan ditulis ke `orders.totalHarga`.
  int get total => dasar + totalBiaya;

  /// True bila ada voucher yang benar-benar memotong.
  bool get adaDiskon => potongan > 0;

  /// Rincian berurutan untuk ditampilkan di layar.
  ///
  /// Dikembalikan sebagai data, bukan widget, supaya urutan dan labelnya
  /// bisa diuji tanpa merender apa pun.
  List<({String label, int nilai, bool tebal})> get baris {
    // Tarif ditulis tanpa desimal: "10%", bukan "10.0%".
    //
    // `tarifPajakPersen` bertipe double, dan interpolasi double di Dart
    // menghasilkan "10.0" — labelnya dulu terbaca "Pajak hiburan 10.0%",
    // yang terlihat seperti angka mesin, bukan bahasa manusia.
    String persen(double v) =>
        v == v.roundToDouble() ? '${v.round()}' : v.toString();

    final hasil = <({String label, int nilai, bool tebal})>[
      (label: 'Harga tiket', nilai: subtotal, tebal: false),
      if (adaDiskon)
        (
          label: 'Diskon${kodePromo != null ? ' ($kodePromo)' : ''}',
          nilai: -potongan,
          tebal: false,
        ),
      (
        label: 'Pajak hiburan ${persen(tarifPajakPersen)}%',
        nilai: pajak,
        tebal: false,
      ),
      (
        // Diberi keterangan "(persen)" supaya tidak tertukar dengan baris
        // biaya layanan tetap di bawahnya — dulu keduanya bernama
        // "Biaya layanan" dan pembeli tidak tahu mana yang mana.
        label: 'Biaya layanan ${persen(tarifLayananPersen)}%',
        nilai: layananPersen,
        tebal: false,
      ),
      (label: 'Biaya layanan tetap', nilai: layananTetap, tebal: false),
      (label: 'Total bayar', nilai: total, tebal: true),
    ];
    return hasil;
  }
}
