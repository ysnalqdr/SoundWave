import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart' show PlayerState, ProcessingState;

import '../../services/audio_service.dart';
import '../../utils/app_theme.dart';

/// Pemutar potongan audio untuk halaman detail event.
///
/// Kenapa satu tombol besar, bukan progress bar penuh:
/// - Tujuannya bukan "mendengarkan lagu", tapi "mengenali lagu". 20 detik
///   cukup, dan satu tombol lebih cepat dipahami daripada bilah seek.
/// - Tetap ada progress bar tipis sebagai penanda berjalan, dan bisa
///   ditekan untuk melompat.
///
/// Widget ini **tidak** membuat `AudioPlayer` sendiri — semua lewat
/// [AudioService] supaya hanya satu lagu yang bisa berbunyi pada satu waktu.
class AudioPreviewPlayer extends StatefulWidget {
  /// Path aset, mis. `assets/audio/preview_01.mp3`.
  final String assetPath;

  /// Judul lagu yang ditampilkan di atas kontrol.
  final String? title;

  /// Durasi yang dijanjikan (untuk label sebelum berkas termuat).
  final int durationSec;

  /// Detik mulai potongan. 0 untuk berkas bawaan yang sudah dipotong.
  final int startSec;

  /// Ulang potongan terus-menerus sampai dijeda atau halaman ditinggalkan.
  ///
  /// Bawaan `true`: pada halaman detail event, cuplikan sebaiknya terus
  /// berbunyi selama pengunjung membaca, bukan berhenti sendiri setelah
  /// 20 detik. Set `false` bila ingin perilaku sekali-putar.
  final bool loop;

  const AudioPreviewPlayer({
    super.key,
    required this.assetPath,
    this.title,
    this.durationSec = 20,
    this.startSec = 0,
    this.loop = true,
  });

  @override
  State<AudioPreviewPlayer> createState() => _AudioPreviewPlayerState();
}

class _AudioPreviewPlayerState extends State<AudioPreviewPlayer> {
  final AudioService _audio = AudioService.instance;

  StreamSubscription<PlayerState>? _stateSub;
  bool _playing = false;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    // Kalau layar dibuka saat lagu lain sedang diputar, hentikan dulu agar
    // tidak ada dua sumber bunyi.
    if (_audio.activePreview != null &&
        _audio.activePreview != widget.assetPath) {
      unawaited(_audio.stopPreview());
    }
    _stateSub = _audio.playerStateStream.listen((state) {
      if (!mounted) return;
      final playing = state.playing &&
          state.processingState != ProcessingState.completed;
      if (playing != _playing) {
        setState(() => _playing = playing);
      }
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    // Sengaja TIDAK menghentikan audio di sini.
    //
    // `ListView` membuang anak yang tergulung keluar layar. Kalau audio
    // dihentikan di sini, lagu mati begitu pengguna menggulir sampai bawah —
    // tombol jeda menghilang dan audio berhenti tanpa sebab yang jelas.
    // Penghentian yang benar dilakukan oleh layar pemilik halaman, di
    // `UserKonserDetailScreen.dispose()`, yang hanya berjalan saat pengguna
    // benar-benar meninggalkan halaman.
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      if (_playing) {
        await _audio.pausePreview();
      } else {
        final ok = await _audio.playPreview(
          widget.assetPath,
          loop: widget.loop,
          title: widget.title,
          startSec: widget.startSec,
          durationSec: widget.durationSec,
        );
        if (!ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Preview tidak dapat diputar')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.title ?? '').trim();
    final fallback = Duration(seconds: widget.durationSec);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.graphic_eq_rounded,
                  size: 16, color: AppColors.aksi),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Pratinjau lagu',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppColors.textMuted,
                ),
              ),
              if (widget.loop) ...[
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.repeat_rounded,
                    size: 12, color: AppColors.textMuted),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _PlayButton(
                playing: _playing,
                busy: _starting,
                onTap: _toggle,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? 'Potongan audio' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _ProgressLine(
                      audio: _audio,
                      fallbackDuration: fallback,
                      active: _playing,
                      format: _fmt,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final bool playing;
  final bool busy;
  final VoidCallback onTap;

  const _PlayButton({
    required this.playing,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: playing ? 'Jeda preview' : 'Putar preview',
      child: Material(
        color: AppColors.aksi,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy ? null : onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.onPrimary),
                    ),
                  )
                : Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: AppColors.onPrimary,
                    size: 26,
                  ),
          ),
        ),
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final AudioService audio;
  final Duration fallbackDuration;
  final bool active;
  final String Function(Duration) format;

  const _ProgressLine({
    required this.audio,
    required this.fallbackDuration,
    required this.active,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: audio.positionStream,
      builder: (context, posSnap) {
        return StreamBuilder<Duration?>(
          stream: audio.durationStream,
          builder: (context, durSnap) {
            final total = durSnap.data ?? fallbackDuration;
            final pos = posSnap.data ?? Duration.zero;
            final maxMs = total.inMilliseconds.toDouble();
            final valueMs = pos.inMilliseconds
                .clamp(0, total.inMilliseconds)
                .toDouble();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: AppRadius.rXs,
                  child: LinearProgressIndicator(
                    value: maxMs <= 0 ? 0 : valueMs / maxMs,
                    minHeight: 3,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.aksi),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${format(pos)} / ${format(total)}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
