import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../constants/app_constants.dart';
import '../providers/app_providers.dart';
import 'auth/login_screen.dart';
import 'admin/admin_dashboard.dart';
import 'user/user_main_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    // `TickerProviderStateMixin`, BUKAN `SingleTickerProviderStateMixin`.
    //
    // Layar ini punya DUA AnimationController: `_controller` untuk fade +
    // scale masuk, dan `_eqController` untuk equalizer yang berulang. Mixin
    // "Single" hanya boleh melayani satu ticker; controller kedua langsung
    // melempar error saat `initState` — dan karena splash adalah layar
    // pertama, aplikasi gagal total begitu dibuka.
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  /// Controller khusus batang equalizer.
  ///
  /// Dipisah dari `_controller` karena masa hidupnya berbeda: `_controller`
  /// selesai sekali (fade + scale masuk), sedangkan equalizer perlu
  /// berulang. Memakai satu controller untuk keduanya akan mengulang
  /// animasi fade setiap putaran.
  late AnimationController _eqController;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();

    // Equalizer bergerak: satu putaran 900 ms, berulang sampai layar
    // berganti. Durasinya tetap di dalam 2.200 ms splash, jadi tidak
    // menambah waktu tunggu pengguna.
    _eqController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _routeAfterSplash();
  }

  Future<void> _routeAfterSplash() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted || _navigated) return;

    final auth = ref.read(authServiceProvider);
    final firebaseUser = auth.currentUser;

    if (firebaseUser == null) {
      _go(const LoginScreen(), routeName: '/login');
      return;
    }

    try {
      final profile = await auth.getUserData(firebaseUser.uid);
      if (!mounted || _navigated) return;

      if (profile != null && profile.isAdmin) {
        _go(AdminDashboard(user: profile), routeName: '/admin');
      } else {
        _go(const UserMainScreen(), routeName: '/user');
      }
    } catch (e) {
      debugPrint('[SplashScreen] getUserData fallback on error: $e');
      if (!mounted || _navigated) return;
      _go(const UserMainScreen(), routeName: '/user');
    }
  }

  void _go(Widget page, {String? routeName}) {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => page,
        settings: routeName != null ? RouteSettings(name: routeName) : null,
      ),
    );
  }

  @override
  void dispose() {
    _eqController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    // Dulu hijau 25% — hijau kini hanya untuk harga.
                    AppColors.aksi.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            // Garis tepi = identitas. Lihat login_screen.dart.
                            color: AppColors.aksi.withValues(alpha: 0.045),
                            borderRadius: AppRadius.rXl,
                            border: Border.all(
                              color: AppColors.badgeJalanBorder,
                              width: 1.6,
                            ),
                          ),
                          child: const Icon(
                            Icons.graphic_eq_rounded,
                            color: AppColors.textPrimary,
                            size: 56,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Dulu ini ShaderMask dengan primaryGradient — yang
                        // isinya #1B1B23→#101016, hampir hitam. Hasilnya teks
                        // "SoundWave" jadi HITAM di atas latar hitam dan
                        // praktis tidak terlihat. Sekarang teks putih polos.
                        Text(
                          AppConstants.appName,
                          style: GoogleFonts.rajdhani(
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppConstants.tagline,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            color: AppColors.textMuted,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 60),
                        // Lima batang naik-turun dengan FASE berbeda.
                        //
                        // Fase tiap batang digeser (index * 0.15) supaya
                        // tidak bergerak serempak — gerakan serempak terlihat
                        // seperti satu blok yang membesar, bukan waveform.
                        // Nilainya `sin` sehingga tiap batang punya siklus
                        // naik-turun penuh dalam satu putaran 900 ms.
                        AnimatedBuilder(
                          animation: _eqController,
                          builder: (context, _) {
                            final tinggiDasar = [20.0, 35.0, 50.0, 35.0, 20.0];
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(5, (index) {
                                final fase = _eqController.value + index * 0.15;
                                // 0,55–1,0 dari tinggi dasar: cukup terlihat
                                // bergerak, tidak sampai membuat batang
                                // menghilang.
                                final skala =
                                    0.775 + 0.225 * math.sin(fase * 2 * math.pi);
                                final tinggi = tinggiDasar[index] * skala;
                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  width: 5,
                                  height: tinggi,
                                  decoration: BoxDecoration(
                                    // Dulu primaryGradient (hampir hitam) —
                                    // batang equalizer jadi tak terlihat.
                                    color: AppColors.aksi,
                                    borderRadius: AppRadius.rXs,
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
