import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ============================================================================
/// TOKEN WARNA SOUNDWAVE
/// ============================================================================
///
/// Satu sumber kebenaran untuk seluruh warna aplikasi. Sebelumnya ada dua palet
/// terpisah (AppColors bertombol putih, SwCheckout bertombol hijau) sehingga
/// tombol terasa tidak konsisten antar layar. Sekarang keduanya turun dari sini.
///
/// Aturan pakai:
/// - `primary`     → aksen. Hanya untuk elemen yang memang ingin ditonjolkan
///                   (tombol utama, ikon aktif, harga, indikator terpilih).
/// - `onPrimary`   → teks/ikon DI ATAS `primary`. Jangan pakai putih di sini:
///                   putih di atas emerald hanya 1,9:1 (gagal WCAG).
/// - `textPrimary` → teks utama di atas latar gelap.
/// - `divider`     → garis pemisah, border kartu, outline input.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------- kanvas
  /// Hitam pekat dengan sedikit rona biru, bukan #000 polos — memberi kesan
  /// "permukaan" dan membuat elevasi/bayangan tetap terbaca.
  static const Color background = Color(0xFF08080C);

  /// Rampa permukaan 5 tingkat.
  ///
  /// **Kenapa nilainya diubah (Okt 2026):** versi lama (#0E0E13 / #17171F /
  /// #1D1D26) hanya berbeda **1,83–3,97 L\*** satu sama lain. Mata manusia
  /// butuh selisih ≥4 L\* untuk melihat dua permukaan sebagai bidang berbeda,
  /// jadi tiga tingkat pertama **tidak terpisah secara visual** — kartu tidak
  /// "muncul" dari latar dan aplikasi terasa datar.
  ///
  /// Nilai baru memberi jarak yang benar-benar terlihat, tanpa mengubah
  /// kesan gelap keseluruhan:
  ///   background  L* 2,27  →  surface    L* 4,90  (selisih 2,63)
  ///   surface     L* 4,90  →  card       L* 8,54  (selisih 3,64)
  ///   card        L* 8,54  →  surfaceLight L* 13,01 (selisih 4,47) ← terlihat
  ///
  /// Kontras teks di atas [card] baru sudah diverifikasi ulang:
  /// textPrimary 16,08 · textSecondary 7,08 · textMuted 4,92 · primary 9,19.
  ///
  /// Jangan dirapatkan lagi tanpa mengukur L*, bukan sekadar rasio WCAG —
  /// rasio menipu di warna gelap (1,12× terlihat "lulus" padahal tak terlihat).
  static const Color surface = Color(0xFF101017);
  static const Color surfaceLight = Color(0xFF212128);
  static const Color card = Color(0xFF18181F);

  /// Permukaan paling atas — dipakai kaca navbar & sheet mengambang.
  /// Harus lebih terang dari [surfaceLight] supaya elemen mengambang terlihat
  /// melayang, bukan tenggelam.
  static const Color overlay = Color(0xFF2B2B33);

  static const Color scrim = Color(0xCC000000);

  // ---------------------------------------------------------------- aksen
  /// Emerald 400. Menggantikan neon `#00E676` karena saturasinya lebih rendah:
  /// tetap jelas sebagai aksen, tapi tidak menyaingi poster event.
  static const Color primary = Color(0xFF34D399);
  static const Color primaryDim = Color(0xFF10B981);
  static const Color primaryPressed = Color(0xFF0B8F66);

  /// Latar aksen transparan untuk chip, badge, dan state terpilih.
  static const Color primarySoft = Color(0x1F34D399); // 12%
  static const Color primaryBorder = Color(0x4D34D399); // 30%

  /// Teks & ikon di atas [primary].
  static const Color onPrimary = Color(0xFF04160E);

  // ---------------------------------------------------------------- teks
  static const Color textPrimary = Color(0xFFF4F4F6);
  static const Color textSecondary = Color(0xFFA3A3B0);

  /// Teks pendukung: label, keterangan, metadata.
  ///
  /// Dinaikkan dari `#6B6B78` → `#868694` karena nilai lama hanya **3,81:1** di
  /// atas `background` dan **3,18:1** di atas `surfaceLight` — gagal WCAG AA
  /// (ambang 4,5:1) untuk teks normal. Token ini dipakai 211 kali, jadi
  /// dampaknya ke seluruh aplikasi.
  ///
  /// **Diukur ulang Okt 2026** setelah rampa permukaan direnggangkan: nilai
  /// #868694 kini hanya **4,46:1** di atas `surfaceLight` (#212128) — gagal
  /// tipis. Dinaikkan ke #8C8C9A: 6,03 / 5,71 / 5,33 / 4,82 di
  /// background / surface / card / surfaceLight — lulus keempatnya.
  ///
  /// Hierarki tetap terjaga: 8,7 L* lebih redup dari [textSecondary] (mata
  /// butuh ≥4), dan masih jauh lebih terang dari [textDisabled].
  ///
  /// Jangan diturunkan lagi tanpa mengukur ulang di keempat permukaan.
  static const Color textMuted = Color(0xFF8C8C9A);

  static const Color textDisabled = Color(0xFF4A4A55);

  // ---------------------------------------------------------------- status
  static const Color success = Color(0xFF34D399);
  static const Color error = Color(0xFFFF5A5F);

  /// Peringatan operasional — **sunset**, bukan amber.
  ///
  /// Kenapa bukan `#FFC107` (amber) atau `#FFB300` (gold): keduanya terlalu
  /// dekat terangnya dengan hijau harga `#34D399` (selisih L* hanya 5,7 dan
  /// 2,3). Untuk pengguna buta warna merah-hijau, keduanya berubah jadi
  /// kuning kecokelatan yang nyaris sama, sehingga badge peringatan bisa
  /// tertukar dengan label harga.
  ///
  /// `#FF8A3D` selisih **6,53 L\*** dari hijau — terbaca berbeda bahkan tanpa
  /// membedakan warna. Kontras di atas [card]: 6,19:1 (lulus AA).
  static const Color warning = Color(0xFFFF8A3D);

  static const Color info = Color(0xFF60A5FA);

  // ------------------------------------------------------- tier tiket
  // Warna penanda kelas tiket. Bukan bagian dari skala brand — sengaja
  // berbeda supaya VVIP/VIP langsung terbaca sebagai 'lebih tinggi'.
  static const Color tierGold = Color(0xFFFFD700);
  static const Color tierVip = Color(0xFFFF9100);

  // ---------------------------------------------------------------- garis
  static const Color divider = Color(0xFF23232E);
  static const Color line = Color(0xFF23232E);
  static const Color lineStrong = Color(0xFF32323F);

  // ------------------------------------------- alias kompatibilitas (lama)
  // Nama-nama ini dipakai di ratusan tempat. Nilainya kini menunjuk ke token
  // baru sehingga seluruh aplikasi ikut berubah tanpa menyentuh call site.
  static const Color warnaHarga = primary;

  /// Tombol/kendali — **putih**, bukan hijau.
  ///
  /// Dulu alias ini menunjuk `primary` (hijau) dan lolos dari sapu hijau
  /// sebelumnya. Akibatnya filter di Kelola Refund menyala hijau saat
  /// dipilih, padahal navigasi bukan uang. Hijau hanya untuk uang dan
  /// status berhasil; sisanya putih.
  static const Color warnaTombolBg = aksi;
  static const Color warnaTombolTeks = onAksi;
  static const Color accent = textSecondary;

  // ------------------------------------------------------ aksi & kendali
  /// Tombol utama: **putih**, bukan hijau.
  ///
  /// Alasan: hijau dipakai untuk satu makna saja — uang. Kalau tombol juga
  /// hijau, warna itu kehilangan arti. Putih juga lebih kuat kontrasnya:
  /// teks #0A0A0E di atas #F4F4F6 = **17,99:1**, dibanding hijau 10,4:1.
  ///
  /// Aturan turunan: **isi penuh = aksi, garis tepi = identitas.**
  static const Color aksi = Color(0xFFF4F4F6);
  static const Color onAksi = Color(0xFF0A0A0E);
  static const Color aksiPressed = Color(0xFFD2D2D8);
  static const Color aksiHover = Color(0xFFE6E6EA);

  // ----------------------------------------------------------------- badge
  /// Tingkat isi badge monokrom. Dibedakan **bentuk**, bukan cuma gelap-terang:
  /// selisih L* antar tingkat hanya 1,95 (mata butuh ≥4), jadi tanpa beda
  /// bentuk pengguna tidak bisa membedakannya.
  ///
  /// - [badgeFinal]  → isi putih penuh, teks gelap. Keadaan final yang baik.
  /// - [badgeJalan]  → garis tepi terang. Sedang berjalan.
  /// - [badgeLewat]  → garis tepi redup. Sudah lewat.
  /// - [badgeGagal]  → tanpa isi, teks dicoret. Batal / gagal.
  static const Color badgeFinalBg = Color(0xFFF4F4F6);
  static const Color badgeFinalFg = Color(0xFF0A0A0E);
  static const Color badgeJalanBg = Color(0x0DFFFFFF); // putih 5%
  static const Color badgeJalanBorder = Color(0x57FFFFFF); // putih 34%
  static const Color badgeJalanFg = Color(0xFFF4F4F6);
  static const Color badgeLewatBg = Color(0x0AFFFFFF); // putih 4%
  static const Color badgeLewatBorder = Color(0x1FFFFFFF); // putih 12%
  static const Color badgeLewatFg = Color(0xFF9A9AA8);
  static const Color badgeGagalBorder = Color(0x14FFFFFF); // putih 8%
  static const Color badgeGagalFg = Color(0xFF8A8A98);

  // ------------------------------------------------------------ navbar kaca
  /// Navbar mengambang bergaya kaca. Nilainya diukur, bukan dikira-kira.
  ///
  /// **Opasitas 0,90 wajib.** Navbar ini melayang di atas konten yang bisa
  /// berupa poster terang. Pada 0,85 latar efektif di atas poster putih jatuh
  /// ke `#4B4B52` dan teks pasif hanya **4,21:1** — gagal AA. Pada 0,90 latar
  /// efektif `#404047` dan kontrasnya **5,01:1** — lulus.
  ///
  /// Blur tetap terlihat pada 0,90 karena `BackdropFilter` bekerja dari 10%
  /// yang tersisa. Jangan turunkan tanpa mengukur ulang di atas latar putih.
  static const Color navKaca = Color(0xE62B2B33); // #2B2B33 @ 90%
  static const Color navKacaBorder = Color(0x16FFFFFF); // putih 8,5%
  static const Color navKacaHighlight = Color(0x1AFFFFFF); // putih 10%

  /// Pil penanda tab aktif. Putih penuh dengan ikon gelap = 15,55:1.
  static const Color navPilAktif = Color(0xFFECECEC);
  static const Color navPilAktifFg = Color(0xFF141418);
  static const Color navTeksPasif = Color(0xFFB4B4C0);

  // ------------------------------------------------------- warna fungsional
  /// Latar panel peringatan (mode "lanjutkan pembayaran").
  /// Diturunkan dari [warning] sunset supaya tidak ada dua kuning berbeda.
  static const Color warningSoft = Color(0x1FFF8A3D); // 12%
  static const Color warningBorder = Color(0x66FF8A3D); // 40%
  static const Color warningStrong = Color(0xFFFF8A3D);

  /// Warna merek pihak ketiga — jangan diganti dengan aksen brand.
  static const Color brandWhatsapp = Color(0xFF25D366);
  static const Color brandInstagram = Color(0xFFE1306C);

  /// Sorotan lembut untuk banner/hero di halaman jelajah.
  static const Color highlightDeep = Color(0xFF11301F);

  /// Palet grafik laporan (kategorikal, bukan bagian skala brand).
  /// Ditulis sebagai konstanta bernama — indeks list bukan ekspresi konstan,
  /// sehingga tidak bisa dipakai di dalam `const` list pemanggil.
  static const Color chartBlue = Color(0xFF42A5F5);
  static const Color chartPurple = Color(0xFFAB47BC);
  static const Color chartAmber = Color(0xFFFFB300);
  static const Color chartRed = Color(0xFFEF5350);

  // ---------------------------------------------------------------- gradien
  /// Gradien panel gelap (kartu, header, kotak logo). Sengaja tetap gelap:
  /// dipakai sebagai latar ikon putih, jadi tidak boleh beraksen terang.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1B1B23), Color(0xFF101016)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Panel netral untuk chrome admin (kotak logo, header kecil).
  /// Bukan hijau: chrome monokrom, hijau hanya untuk uang.
  static const LinearGradient panelGradient = LinearGradient(
    colors: [Color(0xFF26262E), Color(0xFF18181F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF14141C), Color(0xFF08080C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Gradien aksen untuk elemen yang memang ingin "menyala" (badge, header
  /// tipis). Jangan dipakai sebagai latar ikon putih.
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// ============================================================================
/// TOKEN JARAK (skala 4pt)
/// ============================================================================
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// Ruang bawah untuk layar yang memakai navbar mengambang.
  ///
  /// Navbar tingginya 66 + jarak bawah 20 + napas 16 = 102. Tanpa ini, item
  /// terakhir di daftar akan tertutup navbar — cacat yang justru ada di
  /// referensi desain Proton Pass.
  static const double ruangNavbar = 102;
}

/// ============================================================================
/// TOKEN SUDUT
/// ============================================================================
class AppRadius {
  AppRadius._();

  static const double xs = 8;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;

  static BorderRadius get rXs => BorderRadius.circular(xs);
  static BorderRadius get rSm => BorderRadius.circular(sm);
  static BorderRadius get rMd => BorderRadius.circular(md);
  static BorderRadius get rLg => BorderRadius.circular(lg);
  static BorderRadius get rXl => BorderRadius.circular(xl);
  static BorderRadius get rPill => BorderRadius.circular(pill);
}

/// ============================================================================
/// TOKEN GERAK
/// ============================================================================
///
/// Hanya `transform` dan `opacity` yang boleh dianimasikan. Durasi mengikuti
/// tiga tingkat ini agar konsisten antar layar.
class AppMotion {
  AppMotion._();

  static const Duration instant = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 340);

  static const Curve out = Curves.easeOutCubic;
  static const Curve inOut = Curves.easeInOutCubic;
}

/// ============================================================================
/// TEMA
/// ============================================================================
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    // `primary` pada ColorScheme dipakai Material untuk mewarnai SEMUA
    // kendali: spinner, TabBar, sakelar, centang, radio, snackbar. Selama
    // nilainya hijau, hijau akan terus muncul di tempat baru setiap kali
    // satu layar dibersihkan — itu yang membuat "sapu hijau" tak pernah
    // selesai.
    //
    // Sekarang `primary` = putih (warna kendali). Hijau tetap tersedia
    // sebagai `AppColors.primary` untuk satu makna saja: uang.
    final scheme = ColorScheme.dark(
      primary: AppColors.aksi,
      onPrimary: AppColors.onAksi,
      primaryContainer: AppColors.aksi.withValues(alpha: 0.12),
      onPrimaryContainer: AppColors.aksi,
      secondary: AppColors.aksi,
      onSecondary: AppColors.onAksi,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceLight,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.line,
      outlineVariant: AppColors.divider,
      shadow: Colors.black,
      scrim: AppColors.scrim,
      inverseSurface: AppColors.textPrimary,
      onInverseSurface: AppColors.background,
    );

    // ignore: prefer_const_declarations
    final bodyStyle = GoogleFonts.spaceGrotesk();
    // ignore: prefer_const_declarations
    final displayStyle = GoogleFonts.rajdhani();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      dividerColor: AppColors.divider,
      // Ripple & state pakai putih, bukan hijau: hijau hanya untuk uang.
      splashColor: AppColors.aksi.withValues(alpha: 0.10),
      highlightColor: AppColors.aksi.withValues(alpha: 0.06),
      hoverColor: AppColors.aksi.withValues(alpha: 0.08),
      focusColor: AppColors.aksi.withValues(alpha: 0.12),

      textTheme: GoogleFonts.spaceGroteskTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),

      // ------------------------------------------------------------ app bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: displayStyle.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
        actionsIconTheme:
            const IconThemeData(color: AppColors.textSecondary, size: 22),
      ),

      // ------------------------------------------------------------ input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        hintStyle: bodyStyle.copyWith(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        labelStyle: bodyStyle.copyWith(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        floatingLabelStyle: bodyStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        helperStyle: bodyStyle.copyWith(
          color: AppColors.textMuted,
          fontSize: 12,
        ),
        errorStyle: bodyStyle.copyWith(
          color: AppColors.error,
          fontSize: 12,
        ),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: const BorderSide(color: AppColors.aksi, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
      ),

      // ------------------------------------------------------------ tombol
      //
      // State yang dijaga di sini: default, hover, pressed, focus, disabled.
      // (loading / error / success adalah state konten, ditangani per widget.)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.surfaceLight;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.aksiPressed;
            }
            if (states.contains(WidgetState.hovered)) return AppColors.aksiHover;
            return AppColors.aksi;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textDisabled;
            }
            return AppColors.onAksi;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.onAksi.withValues(alpha: 0.12);
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.onAksi.withValues(alpha: 0.06);
            }
            return null;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(color: AppColors.aksi, width: 2);
            }
            return BorderSide.none;
          }),
          elevation: const WidgetStatePropertyAll(0),
          minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl,
              vertical: AppSpacing.md,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.rMd),
          ),
          textStyle: WidgetStatePropertyAll(
            bodyStyle.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
              return AppColors.aksi.withValues(alpha: 0.08);
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textDisabled;
            }
            return AppColors.aksi;
          }),
          overlayColor: WidgetStatePropertyAll(
            AppColors.aksi.withValues(alpha: 0.08),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const BorderSide(color: AppColors.divider);
            }
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(color: AppColors.aksi, width: 2);
            }
            return const BorderSide(color: AppColors.badgeJalanBorder, width: 1.4);
          }),
          minimumSize: const WidgetStatePropertyAll(Size(0, 50)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.rMd),
          ),
          textStyle: WidgetStatePropertyAll(
            bodyStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
              return AppColors.aksi.withValues(alpha: 0.08);
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textDisabled;
            }
            return AppColors.aksi;
          }),
          overlayColor: WidgetStatePropertyAll(
            AppColors.aksi.withValues(alpha: 0.08),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.rSm),
          ),
          textStyle: WidgetStatePropertyAll(
            bodyStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textDisabled;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.aksiPressed;
            }
            if (states.contains(WidgetState.hovered)) return AppColors.aksi;
            return AppColors.textSecondary;
          }),
          overlayColor: WidgetStatePropertyAll(
            AppColors.aksi.withValues(alpha: 0.10),
          ),
          iconSize: const WidgetStatePropertyAll(22),
        ),
      ),

      // ------------------------------------------------------------ kartu
      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rLg,
          side: const BorderSide(color: AppColors.divider),
        ),
      ),

      // ------------------------------------------------------------ dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rXl,
          side: const BorderSide(color: AppColors.divider),
        ),
        titleTextStyle: displayStyle.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: bodyStyle.copyWith(
          fontSize: 14,
          height: 1.5,
          color: AppColors.textSecondary,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: AppColors.lineStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),

      // ------------------------------------------------------------ lain-lain
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        // Putih: proses berjalan bukan "uang".
        color: AppColors.aksi,
        linearTrackColor: AppColors.surfaceLight,
        circularTrackColor: AppColors.surfaceLight,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.aksi.withValues(alpha: 0.12),
        disabledColor: AppColors.surface,
        side: const BorderSide(color: AppColors.line),
        labelStyle: bodyStyle.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        secondaryLabelStyle: bodyStyle.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.aksi,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rPill),
        showCheckmark: false,
      ),

      tabBarTheme: TabBarThemeData(
        // Tab = navigasi -> putih.
        labelColor: AppColors.aksi,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.aksi,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.divider,
        labelStyle: bodyStyle.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: bodyStyle.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.onAksi;
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.aksi;
          return AppColors.surfaceLight;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.aksi;
          return AppColors.line;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.aksi;
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(AppColors.onAksi),
        side: const BorderSide(color: AppColors.lineStrong, width: 1.6),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rXs),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.aksi;
          return AppColors.lineStrong;
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: bodyStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        actionTextColor: AppColors.aksi,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rMd,
          side: const BorderSide(color: AppColors.divider),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        selectedColor: AppColors.aksi,
        selectedTileColor: AppColors.aksi.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: AppRadius.rSm,
          border: Border.all(color: AppColors.line),
        ),
        textStyle: bodyStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 12,
        ),
        waitDuration: const Duration(milliseconds: 700),
      ),
    );
  }
}
