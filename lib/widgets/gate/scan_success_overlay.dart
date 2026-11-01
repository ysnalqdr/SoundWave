import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../core/media/lottie_assets.dart';
import '../../utils/app_theme.dart';

/// Layar penuh yang muncul di HP pembeli begitu tiketnya sah discan di gate.
///
/// Kenapa layar penuh, bukan kartu: momen ini terjadi sekali per tiket, di
/// depan petugas, dan pembeli sedang menatap layar karena QR-nya ada di sana.
/// Animasi 2,3 detik adalah cara tercepat memberi tahu "kamu boleh masuk"
/// tanpa perlu membaca apa pun.
///
/// Kenapa tidak bisa ditutup: kalau bisa di-swipe, orang akan menutupnya
/// sebelum sempat melihat hasilnya, lalu bertanya ke petugas. AbsorbPointer
/// menahan sentuhan sampai animasi selesai.
///
/// Durasi mengikuti aset apa adanya (69 frame @ 30 fps). Tidak diperpanjang,
/// tidak dipercepat. Yang ditambahkan hanya [jedaBaca] setelah animasi habis,
/// supaya tulisan di bawah sempat terbaca sebelum layar hilang.
class ScanSuccessOverlay extends StatefulWidget {
  /// Dipanggil setelah animasi + jeda baca selesai.
  final VoidCallback onSelesai;

  /// Nama konser, ditampilkan sebagai penguat konteks.
  final String? judulKonser;

  /// Kode booking. Ditampilkan kecil di bawah, berguna saat petugas perlu
  /// mencocokkan layar dengan daftar di gate.
  final String? kodeBooking;

  /// Jeda diam setelah animasi habis. Animasi memegang centang hijau di
  /// akhirnya, jadi jeda ini terasa seperti "napas" — bukan layar kosong.
  final Duration jedaBaca;

  const ScanSuccessOverlay({
    super.key,
    required this.onSelesai,
    this.judulKonser,
    this.kodeBooking,
    this.jedaBaca = const Duration(milliseconds: 900),
  });

  @override
  State<ScanSuccessOverlay> createState() => _ScanSuccessOverlayState();
}

class _ScanSuccessOverlayState extends State<ScanSuccessOverlay>
    with SingleTickerProviderStateMixin {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Getar sekali saat layar muncul. Pembeli merasakan hasilnya sebelum
    // sempat mengangkat mata ke layar.
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Dipanggil sekali saat Lottie melaporkan komposisinya termuat. Dari sini
  /// durasi asli aset diketahui, jadi jeda tidak perlu ditebak.
  void _jadwalkanSelesai(LottieComposition komposisi) {
    _timer?.cancel();
    _timer = Timer(komposisi.duration + widget.jedaBaca, () {
      if (mounted) widget.onSelesai();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Tombol back Android ditahan. Tanpa ini, back akan menutup lapisan
      // animasi lebih awal dan pengawas tidak pernah menerima sinyal selesai —
      // akibatnya animasi tidak akan muncul lagi untuk tiket berikutnya.
      canPop: false,
      child: AbsorbPointer(
        // Menelan semua sentuhan: tidak ada tombol tutup, tidak bisa di-swipe.
        absorbing: true,
        // `Material` WAJIB ada.
        //
        // Layar ini dibuka sebagai halaman lewat `PageRouteBuilder`, dan
        // isinya tidak punya leluhur Material sama sekali. Tanpa Material,
        // Flutter menggambar SEMUA teks dengan garis bawah kuning ganda —
        // penanda debug "text has no Material ancestor". Itu yang membuat
        // "Tiket terverifikasi", nama konser, dan kode booking terlihat
        // seperti sedang ditandai error.
        child: Material(
          color: AppColors.background,
          child: ColoredBox(
            color: AppColors.background,
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Animasi memakai ukuran aslinya (512×512) yang diperkecil
                // proporsional. Tidak di-tint: hijau aset sengaja dibiarkan
                // sesuai aslinya.
                ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 320, maxHeight: 320),
                  child: Lottie.asset(
                    LottieAssets.scanSuccess,
                    repeat: false,
                    fit: BoxFit.contain,
                    onLoaded: _jadwalkanSelesai,
                    errorBuilder: (context, error, stack) {
                      // Aset rusak jangan sampai membuat layar kosong.
                      // Tampilkan centang biasa, dan jadwalkan selesai dengan
                      // durasi perkiraan supaya alur tidak macet di sini.
                      _timer?.cancel();
                      _timer = Timer(
                        const Duration(milliseconds: 2300) + widget.jedaBaca,
                        () {
                          if (mounted) widget.onSelesai();
                        },
                      );
                      return const Center(
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 120,
                          color: AppColors.success,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Tiket terverifikasi',
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Selamat menikmati acaranya.',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (widget.judulKonser != null &&
                    widget.judulKonser!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl,
                    ),
                    child: Text(
                      widget.judulKonser!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.rajdhani(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
                if (widget.kodeBooking != null &&
                    widget.kodeBooking!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.kodeBooking!,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
