import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';

/// Cincin hitung-mundur berbasis **waktu kedaluwarsa absolut**.
///
/// Berbeda dari timer biasa yang mengurangi penghitung tiap detik, widget ini
/// selalu menghitung sisa waktu dari `expiresAt - DateTime.now()`. Konsekuensinya:
///
/// - Tidak melenceng bila frame terlewat, aplikasi di-background, atau perangkat
///   lambat.
/// - Bila pengguna menutup lalu membuka kembali layar, sisa waktu tetap benar
///   karena acuannya waktu kedaluwarsa dari server, bukan waktu mulai tampil.
///
/// [expiresAt] **wajib** berasal dari server (mis. `expires_at` Midtrans),
/// bukan hasil `DateTime.now().add(...)` di klien.
class CountdownRing extends StatefulWidget {
  /// Batas waktu pembayaran, dalam waktu absolut.
  final DateTime expiresAt;

  /// Panjang total jendela waktu, dipakai menghitung porsi cincin.
  /// Contoh: VA 24 jam, QRIS 5 menit.
  final Duration total;

  /// Dipanggil sekali ketika sisa waktu mencapai nol.
  final VoidCallback? onExpired;

  /// Diameter widget.
  final double size;

  /// Ketebalan cincin.
  final double strokeWidth;

  /// Tampilkan teks sisa waktu di tengah cincin.
  final bool showLabel;

  /// Warna cincin saat waktu masih longgar.
  final Color colorNormal;

  /// Warna cincin saat waktu mulai menipis.
  final Color colorWarning;

  /// Warna cincin saat waktu hampir habis.
  final Color colorCritical;

  /// Warna jalur cincin di belakang.
  final Color trackColor;

  /// Warna teks sisa waktu.
  final Color textColor;

  /// Gaya teks sisa waktu.
  final TextStyle? textStyle;

  const CountdownRing({
    super.key,
    required this.expiresAt,
    required this.total,
    this.onExpired,
    this.size = 64,
    this.strokeWidth = 5,
    this.showLabel = true,
    this.colorNormal = AppColors.primary,
    this.colorWarning = AppColors.warning,
    this.colorCritical = AppColors.error,
    this.trackColor = AppColors.divider,
    this.textColor = AppColors.textPrimary,
    this.textStyle,
  });

  /// Format sisa waktu: `HH:MM:SS` bila ≥ 1 jam, selain itu `MM:SS`.
  ///
  /// Nilai negatif diperlakukan sebagai nol sehingga tidak pernah muncul
  /// tampilan seperti `-1:-5`.
  static String formatRemaining(Duration remaining) {
    final total = remaining.inSeconds < 0 ? 0 : remaining.inSeconds;
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$mm:$ss';
    }
    return '$mm:$ss';
  }

  /// Porsi sisa waktu terhadap [total], dijepit ke rentang 0..1.
  ///
  /// Mengembalikan 0 bila [total] nol atau negatif, agar tidak terjadi
  /// pembagian dengan nol.
  static double progressOf(Duration remaining, Duration total) {
    if (total.inMilliseconds <= 0) return 0;
    final value = remaining.inMilliseconds / total.inMilliseconds;
    return value.clamp(0.0, 1.0);
  }

  /// Ambang warna: > 50% normal, > 20% peringatan, sisanya kritis.
  static Color colorFor(
    double progress, {
    required Color normal,
    required Color warning,
    required Color critical,
  }) {
    if (progress > 0.5) return normal;
    if (progress > 0.2) return warning;
    return critical;
  }

  @override
  State<CountdownRing> createState() => _CountdownRingState();
}

class _CountdownRingState extends State<CountdownRing>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _ticker;
  bool _expiredFired = false;

  Duration get _remaining {
    final diff = widget.expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _expiredFired = false;
    final remaining = _remaining;

    _controller = AnimationController(
      vsync: this,
      duration: remaining > Duration.zero ? remaining : const Duration(seconds: 1),
    )..forward();

    // Timer 1 detik hanya untuk memperbarui teks; cincin digerakkan oleh
    // AnimationController agar halus. Dua sumber ini murah dan saling lepas.
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      _checkExpiry();
    });

    // Kasus batas: sudah kedaluwarsa saat widget dibuat.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkExpiry());
  }

  void _checkExpiry() {
    if (_expiredFired) return;
    if (_remaining > Duration.zero) return;
    _expiredFired = true;
    _ticker?.cancel();
    _controller.stop();
    widget.onExpired?.call();
  }

  @override
  void didUpdateWidget(covariant CountdownRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed = oldWidget.expiresAt != widget.expiresAt ||
        oldWidget.total != widget.total;
    if (changed) {
      _controller.dispose();
      _start();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    final progress = CountdownRing.progressOf(remaining, widget.total);
    final color = CountdownRing.colorFor(
      progress,
      normal: widget.colorNormal,
      warning: widget.colorWarning,
      critical: widget.colorCritical,
    );

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cincin digambar ulang setiap frame lewat controller.
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final animated = CountdownRing.progressOf(
                _remaining,
                widget.total,
              );
              return CustomPaint(
                size: Size.square(widget.size),
                painter: _RingPainter(
                  progress: animated,
                  color: CountdownRing.colorFor(
                    animated,
                    normal: widget.colorNormal,
                    warning: widget.colorWarning,
                    critical: widget.colorCritical,
                  ),
                  trackColor: widget.trackColor,
                  strokeWidth: widget.strokeWidth,
                ),
              );
            },
          ),
          if (widget.showLabel)
            Padding(
              padding: EdgeInsets.all(widget.strokeWidth + 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  CountdownRing.formatRemaining(remaining),
                  textAlign: TextAlign.center,
                  style: (widget.textStyle ??
                          const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ))
                      .copyWith(color: color),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    // Mulai dari pukul 12, berjalan searah jarum jam.
    const start = -math.pi / 2;
    canvas.drawArc(rect, start, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
