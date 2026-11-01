import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/media/venue_model_library.dart';
import '../../utils/app_theme.dart';
import 'venue_stage_3d.dart';

/// Penampil panggung 3D di halaman detail konser.
///
/// **Kenapa bukan `model_viewer_plus` lagi.**
///
/// Di perangkat uji, halaman WebView berhasil dimuat (`url:
/// http://127.0.0.1:36799/` terbaca dari sisi Flutter), tetapi JavaScript-nya
/// tidak pernah dieksekusi: judul halaman tidak berubah, panel diagnostik di
/// dalam halaman tidak muncul, dan tidak ada satu pun laporan balik. Itu tiga
/// sinyal independen yang menunjuk ke kesimpulan yang sama — mesin render
/// berbasis WebView tidak bisa diandalkan di perangkat tersebut.
///
/// Karena itu panggung digambar langsung dengan `Canvas` Flutter
/// ([VenueStage3D]): tanpa WebView, tanpa WebGL, tanpa JavaScript.
///
/// **Tidak ada tombol layar penuh.** Layar penuh sempat ada, tetapi panggung
/// di sana tergambar di bagian atas dan tidak bisa dipindahkan — lebih buruk
/// daripada di dalam kartu. Karena putaran 360° sekarang bisa dilakukan
/// langsung di kartu, layar terpisah tidak lagi memberi nilai tambah.
///
/// Poster hasil render model asli tetap ditampilkan di atas panggung
/// interaktif, supaya pengunjung melihat bentuk venue yang sesungguhnya —
/// lengkap dengan kredit CC-BY pemilik model.
class VenueViewer extends StatelessWidget {
  /// Model venue yang dipilih admin.
  final VenueModel model;

  /// Nama pendek model, dipakai sebagai label.
  final String? nama;

  /// Baris kredit wajib untuk lisensi CC-BY. Null = tidak ditampilkan.
  final String? kredit;

  const VenueViewer({
    super.key,
    required this.model,
    this.nama,
    this.kredit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Poster: hasil render model 3D yang sebenarnya.
        ClipRRect(
          borderRadius: AppRadius.rMd,
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  model.posterRef,
                  fit: BoxFit.cover,
                  // Poster hilang bukan alasan menampilkan kotak kosong.
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surfaceLight,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textMuted,
                      size: 26,
                    ),
                  ),
                ),
                // Gradasi bawah supaya label nama model tetap terbaca di atas
                // poster yang bagian bawahnya bisa terang.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.background.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                    child: Text(
                      nama ?? model.nama,
                      style: GoogleFonts.rajdhani(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Panggung interaktif: digambar dengan Canvas, tanpa WebView.
        //
        // Petunjuk kontrol diletakkan di dalam kartu sebagai lapisan tipis di
        // bawah, supaya pengguna tahu kartunya bisa disentuh tanpa perlu
        // membaca teks di luar kartu.
        ClipRRect(
          borderRadius: AppRadius.rMd,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              border: Border.all(color: AppColors.divider),
              borderRadius: AppRadius.rMd,
            ),
            child: Stack(
              children: [
                VenueStage3D(
                  warnaAksen: AppColors.primary,
                  tinggi: 220,
                ),
                // Petunjuk di dalam kartu, bukan di luarnya.
                Positioned(
                  left: AppSpacing.sm,
                  right: AppSpacing.sm,
                  bottom: AppSpacing.xs,
                  child: IgnorePointer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.swipe_rounded,
                          size: 12,
                          color: AppColors.textMuted.withValues(alpha: 0.75),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Geser untuk memutar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 9.5,
                              color: AppColors.textMuted.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (kredit != null) ...[
          const SizedBox(height: AppSpacing.sm),
          // Kredit lisensi CC-BY. Bukan hiasan — ini syarat pemakaian model.
          Text(
            kredit!,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 9,
              height: 1.4,
              color: AppColors.textMuted.withValues(alpha: 0.8),
            ),
          ),
        ],
      ],
    );
  }
}
