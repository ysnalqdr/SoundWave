/// Daftar berkas Lottie yang dibundel aplikasi.
///
/// Kenapa dipusatkan: animasi dipakai di banyak layar, dan path yang salah
/// ketik hanya muncul sebagai kotak kosong saat runtime — tidak ketahuan saat
/// kompilasi. Dengan satu daftar, tes bisa memastikan setiap berkas benar-benar
/// ada di disk dan terdaftar di `pubspec.yaml`.
///
/// Catatan pemakaian:
/// - [loading] **monokrom** (putih/hitam), jadi aman di-tint. Komponen
///   `AppLoading` memberinya warna emerald lewat `BlendMode.srcIn`.
/// - [error] **berilustrasi penuh** (navy, amber, abu terang). Jangan di-tint —
///   filter warna akan meratakan seluruh gambar menjadi satu blok.
/// - [confetti] dipakai di layar sukses pembayaran.
/// - [scanSuccess] dipakai sekali di gate, satu layar penuh, tidak di-tint.
class LottieAssets {
  LottieAssets._();

  /// Animasi tunggu. Loop, 5 detik, 500×500.
  static const String loading = 'assets/lottie/loading_cat.json';

  /// Ilustrasi galat. 6 detik, 512×512. Tidak di-tint.
  static const String error = 'assets/lottie/error_404.json';

  /// Confetti keberhasilan. 3 detik, 1920×1920.
  static const String confetti = 'assets/lottie/success_confetti.json';

  /// Tiket sah discan di gate. 2,3 detik, 512×512.
  ///
  /// Berwarna sendiri (merah pemindai, hijau centang), jadi **jangan di-tint**.
  /// Durasinya sengaja tidak diubah dari aslinya.
  static const String scanSuccess = 'assets/lottie/scan_success.json';

  /// Semua berkas yang wajib ada. Dipakai oleh tes penjaga aset.
  static const List<String> semua = [
    loading,
    error,
    confetti,
    scanSuccess,
  ];
}
