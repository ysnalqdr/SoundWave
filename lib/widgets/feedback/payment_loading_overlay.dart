import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../utils/app_theme.dart';
import '../../core/media/lottie_assets.dart';

/// Lapisan tunggu untuk operasi pembayaran.
///
/// Versi sebelumnya memakai tabir 94% gelap dengan animasi kucing besar di
/// tengah. Terlalu berat untuk operasi 2–8 detik, dan pengguna kehilangan
/// konteks tentang apa yang sedang ia bayar.
///
/// Versi ini hanya kartu ringkas di tengah dengan tabir tipis. Tujuannya
/// bukan menghibur, tapi **mengunci layar** dan memberi tahu bahwa proses
/// berjalan.
///
/// Yang dipertahankan dari versi lama: [AbsorbPointer] menelan semua sentuhan.
/// Selama pembayaran diproses, pengguna tidak boleh menekan tombol kembali,
/// mengganti metode, atau mengirim ulang — tiga hal yang bisa membuat tagihan
/// ganda.
class PaymentLoadingOverlay extends StatefulWidget {
  /// Kalimat utama. Sebutkan apa yang sedang terjadi.
  final String title;

  /// Keterangan pendukung, mis. peringatan agar tidak menutup aplikasi.
  final String? message;

  /// Tampilkan overlay. Bila false, widget tidak menempati ruang sama sekali.
  final bool visible;

  const PaymentLoadingOverlay({
    super.key,
    required this.visible,
    this.title = 'Memproses pembayaran',
    this.message = 'Jangan tutup aplikasi atau tekan tombol kembali.',
  });

  /// Durasi satu putaran animasi kucing.
  ///
  /// Aset aslinya 5 detik (150 frame @30fps). Nilainya TIDAK diubah di
  /// berkas JSON — kecepatan diatur lewat controller, jadi aset tetap utuh
  /// dan bisa dipakai di tempat lain dengan durasi aslinya.
  static const Duration durasiPutaran = Duration(seconds: 3);

  @override
  State<PaymentLoadingOverlay> createState() => _PaymentLoadingOverlayState();
}

class _PaymentLoadingOverlayState extends State<PaymentLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // 3 detik untuk SATU putaran penuh animasi 5 detik -> animasi
      // berjalan 1,67x lebih cepat.
      duration: PaymentLoadingOverlay.durasiPutaran,
    );
    if (widget.visible) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant PaymentLoadingOverlay lama) {
    super.didUpdateWidget(lama);
    // `repeat: true` pada Lottie TIDAK berpengaruh saat kita menyuplai
    // `controller` sendiri — dokumentasinya menyebut properti itu
    // "has no effect if controller is not null". Jadi pengulangan harus
    // dijalankan manual di sini.
    //
    // Controller juga dihentikan saat overlay tidak terlihat, supaya ticker
    // tidak terus berjalan di latar belakang selama layar checkout terbuka.
    if (widget.visible && !lama.visible) {
      _controller.repeat();
    } else if (!widget.visible && lama.visible) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return Positioned.fill(
      // `Material` WAJIB ada di sini.
      //
      // Overlay ini adalah ANAK dari `Stack` di checkout_screen, bukan anak
      // `Scaffold` — jadi ia tidak punya leluhur Material. Tanpa Material,
      // Flutter menggambar teks dengan garis bawah kuning ganda (penanda
      // debug "text has no Material ancestor"), dan itu yang membuat tulisan
      // "Memproses pembayaran" terlihat seperti sedang ditandai/error.
      child: Material(
        color: Colors.transparent,
        child: AbsorbPointer(
        // AbsorbPointer, bukan IgnorePointer: seluruh sentuhan ditelan, jadi
        // pengguna tidak bisa menekan tombol di belakang overlay.
        absorbing: true,
        child: ColoredBox(
          // Tabir lebih ringan dari sebelumnya (0,94 → 0,6). Cukup untuk
          // memisahkan kartu dari latar, tanpa membuat layar terasa mati.
          color: AppColors.background.withValues(alpha: 0.6),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.rLg,
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animasi kucing, 3 detik per putaran, berulang.
                  //
                  // Dulu hanya spinner 26px yang berputar seragam — terlalu
                  // kecil dan tidak punya penanda kemajuan, sehingga terasa
                  // "sekilas" lalu hilang. Kucing memberi gerak yang bisa
                  // diikuti mata, jadi menunggu terasa wajar.
                  //
                  // Durasinya DIPERCEPAT ke 3 detik (aset aslinya 5 detik)
                  // lewat `controller`. Nilai aset tidak diubah.
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Lottie.asset(
                      LottieAssets.loading,
                      fit: BoxFit.contain,
                      // `repeat` sengaja tidak dipakai: lihat didUpdateWidget.
                      controller: _controller,
                      errorBuilder: (_, __, ___) => const Center(
                        // Cadangan bila aset gagal dimuat: spinner putih,
                        // bukan hijau, dan bukan layar kosong.
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppColors.aksi,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (widget.message != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.message!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        height: 1.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
