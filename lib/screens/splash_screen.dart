import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

//!Switch Animation
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  //* AnimationController/otak animasi

  late AnimationController _controller;

  //!Animasi Fade 
  late Animation<double> _fadeAnim;
  //!Animasi Scale
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    //! Duration Animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    //! Fade in Ke Default
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn, // mulai pelan lalu cepat
      ),
    );

    //! Scale Ke Normal
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut, // efek memantul
      ),
    );

    //! Start Animation
    _controller.forward();

    //! Switch Login Screen
    _pindahKeLogin();
  }

  Future<void> _pindahKeLogin() async {
    //! 3Sec 
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {

    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //! Background
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          //! Efek Cahaya Background
          //! Circle Blur
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
                    AppColors.primary.withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          //! Circle Blur Pojok Kiri
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
                    AppColors.accent.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          //! Konter Center
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

                        //! Logo
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.5),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.graphic_eq_rounded,
                            color: Colors.white,
                            size: 56,
                          ),
                        ),

                        const SizedBox(height: 24),

                        //! Nama Apps
                        ShaderMask(
                          //! ShaderMask Efek Gradient Teks
                          shaderCallback: (bounds) =>
                              AppColors.primaryGradient.createShader(bounds),
                          child: Text(
                            AppConstants.appName,
                            style: GoogleFonts.rajdhani(
                              fontSize: 52,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        //! TagLine
                        Text(
                          AppConstants.tagline,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            color: AppColors.textMuted,
                            letterSpacing: 1.5,
                          ),
                        ),

                        const SizedBox(height: 60),

                        //! Animation Gelombang Suara 5 Sec
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(5, (index) {
                            //! Tinggi Perbar
                            final tinggi = [20.0, 35.0, 50.0, 35.0, 20.0][index];

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 5,
                              //! Tinggi Perbar Gerak Sesuai Animasi
                              height: tinggi * _controller.value,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
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