import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//!Config Colors

class AppColors {
  //! Warna Latar Belakang (Gelap Tearang)
  static const Color background   = Color(0xFF0A0A0F);
  static const Color surface      = Color(0xFF12121A);
  static const Color surfaceLight = Color(0xFF1C1C28);
  static const Color card         = Color(0xFF1A1A26);

  //! Warna Utama
  static const Color primary  = Color(0xFF6C63FF); // ungu
  static const Color accent   = Color(0xFFFF6B9D); // pink
  static const Color success  = Color(0xFF4ECDC4); // tosca
  static const Color error    = Color(0xFFFF6B6B); // merah
  static const Color warning  = Color(0xFFFFB347); // oranye

  //! Warna Teks
  static const Color textPrimary   = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF9090A8);
  static const Color textMuted     = Color(0xFF5A5A72);

  //! Garis Pembatas
  static const Color divider = Color(0xFF2A2A3C);

  //! Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1A0A3E), Color(0xFF0A0A0F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

//!Config Theme

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.spaceGroteskTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: AppColors.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleTextStyle: GoogleFonts.rajdhani(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        hintStyle: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontSize: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

//?Constant 

class AppConstants {
  static const String appName = 'SoundWave';
  static const String tagline = 'Feel the Pulse of Live Music';

  static const List<String> genres = [
    'Pop', 'Rock', 'Jazz', 'Electronic',
    'Hip-Hop', 'R&B', 'K-Pop', 'Pop Rock',
    'Indie', 'Metal', 'Classical',
  ];

  static const List<String> ticketCategories = [
    'Festival', 'Reguler', 'Tribun', 'VIP', 'VVIP',
  ];

  static const List<String> cities = [
    'Jakarta', 'Bandung', 'Surabaya', 'Bali',
    'Medan', 'Yogyakarta', 'Semarang', 'Makassar',
  ];
}