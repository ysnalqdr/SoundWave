import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/media/duration_format.dart';
import '../../services/audio_service.dart';
import '../../utils/app_theme.dart';

/// Pemutar trailer YouTube yang dipotong sesuai rentang dari admin.
///
/// Empat keputusan desain yang menentukan bentuk widget ini:
///
/// 1. **Tidak memuat apa pun sebelum diketuk.** WebView yang langsung memuat
///    pemutar YouTube membuat halaman berat dan menghabiskan kuota. Sebelum
///    diketuk, yang tampil hanya thumbnail — murah dan cepat.
///
/// 2. **Memutar audio pratinjau otomatis dijeda.** Kalau tidak, lagu dan
///    trailer berbunyi bersamaan. Tidak ada cara bagi pengguna mematikan salah
///    satunya selain menghentikan keduanya.
///
/// 3. **Berhenti di akhir potongan.** Ini trailer, bukan video penuh. Saat
///    potongan habis, pemutar berhenti dan pengguna diberi jalan ke YouTube
///    untuk menonton lengkapnya.
///
/// 4. **Kegagalan tidak boleh jadi kotak kosong.** Kalau WebView tidak tersedia
///    atau video tidak bisa disematkan, tampilkan pesan dan tombol "Buka di
///    YouTube" — jalan keluar yang selalu bekerja.
class TrailerPlayer extends StatefulWidget {
  /// ID video YouTube (11 karakter).
  final String videoId;

  /// Detik mulai potongan.
  final int startSec;

  /// Panjang potongan dalam detik.
  final int durationSec;

  /// Judul konser, dipakai sebagai label aksesibilitas dan di halaman YouTube.
  final String? judulKonser;

  const TrailerPlayer({
    super.key,
    required this.videoId,
    required this.startSec,
    required this.durationSec,
    this.judulKonser,
  });

  @override
  State<TrailerPlayer> createState() => _TrailerPlayerState();
}

class _TrailerPlayerState extends State<TrailerPlayer> {
  YoutubePlayerController? _controller;
  StreamSubscription<YoutubePlayerValue>? _sub;

  /// Pengawas batas akhir potongan.
  ///
  /// `endSeconds` pada `loadVideoById` **tidak dihormati** oleh semua klien
  /// YouTube — pada perangkat uji, video tetap berjalan sampai durasi penuh
  /// (48 menit), bukan berhenti di detik 60. Jadi batas akhir ditegakkan
  /// sendiri: posisi diperiksa berkala, dan pemutaran dijeda paksa begitu
  /// melewati batas.
  Timer? _pengawas;

  bool _aktif = false;
  bool _selesai = false;
  bool _gagal = false;

  /// Detik akhir potongan.
  int get _batasAkhir => widget.startSec + widget.durationSec;

  @override
  void initState() {
    super.initState();
    // Sengaja TIDAK menjeda audio di sini.
    //
    // `initState` berjalan setiap kali widget dibuat, dan `ListView` membuat
    // ulang anak yang tergulung kembali ke layar. Kalau audio dijeda di sini,
    // lagu berhenti sendiri setiap kali pengguna menggulir melewati seksi
    // trailer — tanpa disentuh. Penjedaannya dipindah ke [_mulai], yang hanya
    // berjalan saat pengguna benar-benar menekan tombol play.
  }

  @override
  void dispose() {
    _pengawas?.cancel();
    _sub?.cancel();
    _controller?.close();
    super.dispose();
  }

  /// Menghentikan pemutaran tepat di batas akhir.
  ///
  /// Diperiksa tiap 400 ms — cukup rapat agar potongan tidak melewati batas
  /// lebih dari setengah detik, tapi tidak terlalu rapat sehingga membebani
  /// jembatan JavaScript.
  void _mulaiPengawas() {
    _pengawas?.cancel();
    _pengawas = Timer.periodic(const Duration(milliseconds: 400), (_) async {
      final c = _controller;
      if (c == null || _selesai) return;
      try {
        final posisi = await c.currentTime;
        if (posisi >= _batasAkhir) {
          await c.pauseVideo();
          _pengawas?.cancel();
          if (mounted) setState(() => _selesai = true);
        }
      } catch (_) {
        // Jembatan JS bisa gagal sesaat saat iframe dimuat ulang; abaikan
        // dan coba lagi pada tick berikutnya.
      }
    });
  }

  /// Membuat pemutar saat pertama kali dibutuhkan.
  ///
  /// `autoPlay: true` dipakai karena pemuatan hanya terjadi setelah pengguna
  /// menekan tombol play — niatnya sudah jelas, tidak perlu satu ketukan lagi.
  void _mulai() {
    // Hentikan audio pratinjau supaya tidak ada dua sumber bunyi sekaligus.
    // Di sini — bukan di initState — karena hanya di titik ini pengguna
    // benar-benar berniat memutar trailer.
    AudioService.instance.pausePreview();

    final mulai = widget.startSec.toDouble();
    final akhir = (widget.startSec + widget.durationSec).toDouble();

    final controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      startSeconds: mulai,
      endSeconds: akhir,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        // Video terkait dari kanal lain bisa menampilkan konten yang tidak
        // berhubungan dengan konser. Batasi ke kanal yang sama.
        strictRelatedVideos: true,
        enableCaption: false,
        // Pemutar tidak perlu keyboard di perangkat sentuh.
        enableKeyboard: false,
        interfaceLanguage: 'id',
      ),
    );

    _sub = controller.listen((value) {
      if (!mounted) return;
      // `endSeconds` sudah membatasi pemutaran, tapi status berakhirnya tetap
      // perlu ditangkap agar UI bisa menampilkan ajakan menonton lengkap.
      if (value.playerState == PlayerState.ended && !_selesai) {
        setState(() => _selesai = true);
      }
      if (value.hasError && !_gagal) {
        setState(() => _gagal = true);
      }
    });

    setState(() {
      _controller = controller;
      _aktif = true;
      _gagal = false;
    });

    _mulaiPengawas();
  }

  /// Memutar potongan lagi dari detik awal.
  Future<void> _ulangDariAwal() async {
    final c = _controller;
    if (c == null) return;
    try {
      await c.seekTo(seconds: widget.startSec.toDouble(), allowSeekAhead: true);
      await c.playVideo();
      setState(() => _selesai = false);
      _mulaiPengawas();
    } catch (_) {}
  }

  /// Membuka video di aplikasi YouTube, mulai dari detik yang sama.
  ///
  /// Memakai `url_launcher` yang sudah terpasang. Bila aplikasi YouTube tidak
  /// ada, sistem akan menawarkan peramban — tidak perlu penanganan khusus.
  Future<void> _bukaDiYoutube() async {
    final url = Uri.parse(
      'https://www.youtube.com/watch?v=${widget.videoId}'
      '&t=${widget.startSec}s',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Tidak ada yang bisa dilakukan bila peluncur gagal; tombol tetap ada
      // sehingga pengguna bisa mencoba lagi.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_gagal) return _tampilanGagal();

    if (_aktif && _controller != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppRadius.rMd,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: YoutubePlayer(
                controller: _controller!,
                aspectRatio: 16 / 9,
                // Menjaga pemutar tetap hidup saat pengguna menggulir keluar
                // layar lalu kembali — tanpa ini video dimuat ulang.
                keepAlive: true,
              ),
            ),
          ),
          if (_selesai) ...[
            const SizedBox(height: AppSpacing.sm),
            _ajakanMenontonLengkap(),
          ],
        ],
      );
    }

    return _tampilanPoster();
  }

  /// Poster sebelum diputar. Thumbnail diambil dari YouTube, bukan dibingkai
  /// ulang, supaya yang terlihat benar-benar isi videonya.
  Widget _tampilanPoster() {
    final thumb = 'https://img.youtube.com/vi/${widget.videoId}/hqdefault.jpg';

    return Semantics(
      button: true,
      label: 'Putar trailer ${widget.judulKonser ?? ''}'.trim(),
      child: InkWell(
        borderRadius: AppRadius.rMd,
        onTap: _mulai,
        child: ClipRRect(
          borderRadius: AppRadius.rMd,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  thumb,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surfaceLight,
                    child: const Center(
                      child: Icon(Icons.movie_outlined,
                          size: 36, color: AppColors.textMuted),
                    ),
                  ),
                ),
                Container(color: Colors.black.withValues(alpha: 0.34)),
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      // Tombol aksi = isi penuh putih (aturan: isi penuh =
                      // aksi, garis tepi = identitas).
                      color: AppColors.aksi,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        size: 32, color: AppColors.onAksi),
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.62),
                      borderRadius: AppRadius.rXs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.smart_display_rounded,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Trailer ${DurationFormat.clock(widget.durationSec)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
      ),
    );
  }

  Widget _ajakanMenontonLengkap() {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline_rounded,
            size: 15, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            'Trailer selesai.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ),
        TextButton(
          onPressed: _ulangDariAwal,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
          child: Text(
            'Putar ulang',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.aksi,
            ),
          ),
        ),
        TextButton(
          onPressed: _bukaDiYoutube,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
          child: Text(
            'YouTube',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.aksi,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tampilanGagal() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Icon(Icons.videocam_off_outlined,
              size: 28, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Trailer tidak bisa diputar di sini',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Video mungkin tidak mengizinkan pemutaran di aplikasi lain.',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              height: 1.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _bukaDiYoutube,
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Buka di YouTube'),
          ),
        ],
      ),
    );
  }
}
