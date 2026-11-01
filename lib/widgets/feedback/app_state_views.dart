import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../core/media/lottie_assets.dart';
import '../../utils/app_theme.dart';

/// Animasi tunggu untuk keadaan memuat.
///
/// Menggantikan `CircularProgressIndicator` di **layar tunggu penuh**, bukan di
/// setiap spinner kecil. Alasannya: Lottie merender vektor 30–60 fps; kalau
/// dipasang di dalam tombol atau baris daftar, biayanya tidak sepadan dengan
/// manfaatnya. Untuk progres di dalam tombol, tetap pakai indikator biasa.
///
/// Animasi `loading_cat` monokrom, jadi di-tint ke emerald dengan
/// [BlendMode.srcIn]. Tint hanya bekerja rapi pada animasi monokrom — untuk
/// animasi berwarna penuh, gunakan [AppErrorState] yang tidak di-tint.
class AppLoading extends StatelessWidget {
  /// Keterangan di bawah animasi. Null = tanpa teks.
  final String? label;

  /// Sisi kotak animasi.
  final double size;

  /// Tampilkan latar lingkaran lembut di belakang animasi.
  final bool withBackdrop;

  const AppLoading({
    super.key,
    this.label,
    this.size = 96,
    this.withBackdrop = true,
  });

  @override
  Widget build(BuildContext context) {
    final animasi = Lottie.asset(
      LottieAssets.loading,
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: true,
      // Bila berkas gagal dimuat (korup / tidak terbundel), jangan biarkan
      // layar kosong — jatuh ke indikator biasa.
      errorBuilder: (context, error, stack) => SizedBox(
        width: size,
        height: size,
        child: Center(
          child: SizedBox(
            width: size * 0.32,
            height: size * 0.32,
            child: const CircularProgressIndicator(
              strokeWidth: 2.5,
              // Putih: ini cadangan saat Lottie gagal dimuat, bukan uang.
              color: AppColors.aksi,
            ),
          ),
        ),
      ),
    );

    return Semantics(
      label: label ?? 'Memuat',
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (withBackdrop)
            Container(
              width: size * 1.55,
              height: size * 1.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.aksi.withValues(alpha: 0.04),
              ),
              // `ColorFiltered` DIHAPUS.
              //
              // Dulu seluruh animasi Lottie dipaksa menjadi satu warna
              // (hijau) lewat `BlendMode.srcIn`. Akibatnya aset yang
              // sebenarnya sudah hitam-putih tampil hijau — dan setiap kali
              // aset diwarnai ulang, hasilnya tetap hijau karena filternya
              // menimpa semua warna. Sekarang animasi tampil apa adanya.
              child: Center(child: animasi),
            )
          else
            animasi,
          if (label != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              label!,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: AppColors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Keadaan galat dengan ilustrasi.
///
/// Ilustrasi `error_404` berwarna penuh (navy + amber + abu), jadi **tidak**
/// di-tint. Memberinya `ColorFilter` akan meratakan seluruh gambar menjadi
/// satu blok emerald dan menghapus detail yang justru membuatnya terbaca.
///
/// Selalu sertakan [onRetry] bila kegagalan bersifat sementara (jaringan).
/// Tanpa tombol coba lagi, pengguna terjebak di layar buntu.
class AppErrorState extends StatelessWidget {
  /// Kalimat utama. Sebutkan apa yang gagal, bukan "Terjadi kesalahan".
  final String title;

  /// Penjelasan tambahan. Null = tidak ditampilkan.
  final String? message;

  /// Aksi coba lagi. Null = tombol tidak ditampilkan.
  final VoidCallback? onRetry;

  /// Label tombol coba lagi.
  final String retryLabel;

  final double illustrationSize;

  const AppErrorState({
    super.key,
    this.title = 'Gagal memuat data',
    this.message,
    this.onRetry,
    this.retryLabel = 'Coba lagi',
    this.illustrationSize = 180,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              LottieAssets.error,
              width: illustrationSize,
              height: illustrationSize,
              fit: BoxFit.contain,
              repeat: false,
              errorBuilder: (context, error, stack) => Icon(
                Icons.error_outline_rounded,
                size: illustrationSize * 0.4,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.rajdhani(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.3,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Baris tunggu ringkas untuk daftar yang sedang memuat.
///
/// Sengaja **bukan** Lottie: dipakai berulang di dalam daftar, dan animasi
/// vektor di banyak baris sekaligus membebani render. Ini versi ringan yang
/// tetap bergerak halus.
class AppLoadingRow extends StatefulWidget {
  final String? label;
  const AppLoadingRow({super.key, this.label});

  @override
  State<AppLoadingRow> createState() => _AppLoadingRowState();
}

class _AppLoadingRowState extends State<AppLoadingRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              // Tiga titik dengan fase berbeda — cukup untuk menyatakan
              // "sedang bekerja" tanpa memuat berkas animasi.
              return Row(
                children: List.generate(3, (i) {
                  final fase = (_c.value + i * 0.22) % 1.0;
                  final skala = 0.6 + 0.4 * math.sin(fase * math.pi);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Transform.scale(
                      scale: skala,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.aksi,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          if (widget.label != null) ...[
            const SizedBox(width: AppSpacing.md),
            // `Flexible` supaya label panjang tidak mendorong titik keluar
            // layar saat baris ini dipakai di kolom sempit.
            Flexible(
              child: Text(
                widget.label!,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
