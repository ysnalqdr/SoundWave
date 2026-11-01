/// Pemformat durasi untuk label media.
///
/// Dipakai audio dan video sekaligus, supaya "0:30" selalu berarti hal yang
/// sama di seluruh aplikasi. Tanpa satu tempat, satu layar menulis "30 detik",
/// layar lain "0:30", dan layar ketiga "00:00:30".
class DurationFormat {
  DurationFormat._();

  /// `0:30`, `1:05`, `12:00`. Detik selalu dua digit.
  ///
  /// Nilai negatif dijepit ke nol: durasi negatif tidak punya arti bagi
  /// pengguna, dan menampilkan "-0:05" hanya membingungkan.
  static String clock(int detik) {
    final total = detik < 0 ? 0 : detik;
    final menit = total ~/ 60;
    final sisa = total % 60;
    return '$menit:${sisa.toString().padLeft(2, '0')}';
  }

  /// Label ringkas untuk rentang potongan: `0:30 – 1:00`.
  static String rentang(int mulaiDetik, int durasiDetik) {
    final akhir = (mulaiDetik < 0 ? 0 : mulaiDetik) +
        (durasiDetik < 0 ? 0 : durasiDetik);
    return '${clock(mulaiDetik)} – ${clock(akhir)}';
  }

  /// Mengurai `1:05` atau `75` menjadi detik. Null bila tidak sah.
  static int? parseClock(String input) {
    final teks = input.trim();
    if (teks.isEmpty) return null;
    if (teks.contains(':')) {
      final bagian = teks.split(':');
      if (bagian.length != 2) return null;
      final menit = int.tryParse(bagian[0].trim());
      final detik = int.tryParse(bagian[1].trim());
      if (menit == null || detik == null) return null;
      if (menit < 0 || detik < 0 || detik > 59) return null;
      return menit * 60 + detik;
    }
    final polos = int.tryParse(teks);
    if (polos == null || polos < 0) return null;
    return polos;
  }
}
