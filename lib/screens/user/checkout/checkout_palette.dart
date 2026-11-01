import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';

/// Palet layar checkout.
///
/// Sebelumnya kelas ini mendefinisikan warna sendiri (`#0A0A0F`, hijau
/// `#00E676`, dst.) sehingga checkout terlihat berbeda dari sisa aplikasi:
/// tombolnya hijau neon sementara layar lain memakai tombol putih.
///
/// Sekarang seluruh nilainya menunjuk ke token [AppColors], jadi:
/// - tidak ada lagi dua sumber kebenaran warna;
/// - mengganti aksen brand cukup di `app_theme.dart`;
/// - kontras dan state tombol dijamin sama dengan layar lain.
///
/// Nama field lama dipertahankan sebagai alias agar ratusan call site di
/// widget checkout tidak perlu diubah sekaligus.
class SwCheckout {
  SwCheckout._();

  // ---------------------------------------------------------------- kanvas
  static const Color bg = AppColors.background;
  static const Color surface = AppColors.surfaceLight;
  static const Color chip = AppColors.surfaceLight;
  static const Color line = AppColors.divider;

  // ---------------------------------------------------------------- teks
  static const Color ink = AppColors.textPrimary;
  static const Color sub = AppColors.textSecondary;
  static const Color muted = AppColors.textMuted;

  // ---------------------------------------------------------------- aksen
  /// Hijau — HANYA untuk uang dan status berhasil.
  ///
  /// Jangan pakai untuk kendali (tombol, radio, tab, step indicator).
  /// Untuk itu ada [aksi].
  static const Color green = AppColors.primary;
  static const Color greenDark = AppColors.primaryDim;

  /// Putih — kendali: kartu metode terpilih, step indicator, tab, slider.
  ///
  /// Dipisahkan dari [green] supaya mengubah warna kendali tidak ikut
  /// mematikan sinyal "pembayaran berhasil". Sebelumnya keduanya satu token
  /// (`green`), sehingga setiap kali kendali dijadikan putih, centang sukses
  /// ikut hilang.
  static const Color aksi = AppColors.aksi;
  static const Color onAksi = AppColors.onAksi;

  static const Color btnBg = AppColors.primary;
  static const Color btnFg = AppColors.onPrimary;
  static const Color greenSoft = AppColors.primarySoft;

  // ---------------------------------------------------------------- status
  static const Color error = AppColors.error;
  static const Color warning = AppColors.warning;

  /// Merah pekat untuk aksi destruktif (mis. tombol simulasi).
  static const Color redBright = Color(0xFFF50000);

  /// Latar netral untuk panel informasi sekunder.
  static const Color navy = Color(0xFF14141C);
}
