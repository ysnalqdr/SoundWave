import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart' show PlayerState, ProcessingState;

import '../../services/audio_service.dart';
import '../../utils/app_theme.dart';

/// Mini player yang menempel di bawah layar selama ada audio aktif.
///
/// Kenapa perlu: pemutar utama berada di dalam daftar yang bisa digulung.
/// Begitu pengguna menggulir ke syarat & ketentuan, tombol jeda ikut hilang
/// dari layar — padahal audionya masih berbunyi. Tanpa bar ini, satu-satunya
/// cara menghentikan bunyi adalah menggulir balik ke atas atau keluar halaman.
///
/// Bar muncul selama ada track aktif (baik sedang main maupun dijeda), dan
/// hilang sendiri saat [AudioService.stopPreview] dipanggil.
class AudioMiniPlayer extends StatefulWidget {
  const AudioMiniPlayer({super.key});

  @override
  State<AudioMiniPlayer> createState() => _AudioMiniPlayerState();
}

class _AudioMiniPlayerState extends State<AudioMiniPlayer> {
  final AudioService _audio = AudioService.instance;
  StreamSubscription<PlayerState>? _sub;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _sub = _audio.playerStateStream.listen((state) {
      if (!mounted) return;
      final playing =
          state.playing && state.processingState != ProcessingState.completed;
      if (playing != _playing) setState(() => _playing = playing);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: _audio.nowPlaying,
      builder: (context, title, _) {
        // Tidak ada audio aktif -> tidak menempati ruang sama sekali.
        if (title == null) return const SizedBox.shrink();

        return Material(
          color: AppColors.surfaceLight,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.divider),
                  bottom: BorderSide(color: AppColors.divider),
                ),
              ),
              child: Row(
                children: [
                  // Indikator bunyi: bergerak saat main, diam saat jeda.
                  _PulseDot(playing: _playing),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          _playing ? 'Sedang diputar' : 'Dijeda',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tombol jeda/lanjut — target sentuh 40x40.
                  IconButton(
                    onPressed: () {
                      if (_playing) {
                        _audio.pausePreview();
                      } else {
                        _audio.resumePreview();
                      }
                    },
                    tooltip: _playing ? 'Jeda' : 'Lanjutkan',
                    icon: Icon(
                      _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: AppColors.aksi,
                      size: 22,
                    ),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(40, 40),
                      backgroundColor: AppColors.aksi.withValues(alpha: 0.10),
                    ),
                  ),
                  // Hentikan sepenuhnya — sekaligus menyembunyikan bar.
                  IconButton(
                    onPressed: _audio.stopPreview,
                    tooltip: 'Hentikan',
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(40, 40),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Titik kecil yang berdenyut saat audio berbunyi.
class _PulseDot extends StatefulWidget {
  final bool playing;
  const _PulseDot({required this.playing});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.playing) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulseDot old) {
    super.didUpdateWidget(old);
    if (widget.playing && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.playing && _c.isAnimating) {
      _c.stop();
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = widget.playing ? (0.45 + 0.55 * _c.value) : 0.35;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.aksi.withValues(alpha: t),
          ),
        );
      },
    );
  }
}
