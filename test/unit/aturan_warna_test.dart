import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ============================================================================
/// PENJAGA ATURAN WARNA
/// ============================================================================
///
/// Aturan yang disepakati:
///
/// | Peran                        | Warna  |
/// |------------------------------|--------|
/// | Uang (harga, pendapatan)     | hijau  |
/// | Status berhasil (AKTIF/APPROVED) | hijau |
/// | Navigasi/tab/kendali aktif   | putih  |
/// | Peringatan (PENDING/BERAKHIR)| sunset |
/// | Gagal (REJECTED/DIBATALKAN)  | merah  |
///
/// Aturan ini mudah rusak tanpa disadari karena tidak ada error kompilasi:
/// warna hanyalah nilai, dan salah warna tetap "berhasil" dibangun. Karena
/// itu diperiksa dengan membaca sumber.
void main() {
  String baca(String path) {
    final f = File(path);
    expect(f.existsSync(), isTrue, reason: '$path tidak ditemukan');
    return f.readAsStringSync();
  }

  group('alias tombol tidak boleh hijau', () {
    test('warnaTombolBg menunjuk putih, bukan primary', () {
      final tema = baca('lib/utils/app_theme.dart');
      expect(
        tema,
        contains('static const Color warnaTombolBg = aksi;'),
        reason: 'Alias ini dulu menunjuk `primary` dan lolos dari sapu hijau, '
            'sehingga filter di Kelola Refund menyala hijau.',
      );
      expect(
        tema,
        isNot(contains('static const Color warnaTombolBg = primary;')),
      );
    });
  });

  group('uang tetap hijau', () {
    test('harga di Manage Konser hijau', () {
      final s = baca('lib/screens/admin/konser_screen.dart');
      expect(
        s,
        contains('konser.formatHarga'),
      );
      // Warna hijau harus muncul di sekitar formatHarga.
      final i = s.indexOf('konser.formatHarga');
      final potongan = s.substring(i, i + 400);
      expect(potongan, contains('AppColors.primary'));
      expect(potongan, isNot(contains('Colors.white')));
    });

    test('harga di Laporan Penjualan hijau', () {
      final s = baca('lib/screens/admin/laporan_penjualan_screen.dart');
      final i = s.indexOf('p.formatTotalHarga');
      expect(i, greaterThan(-1));
      expect(s.substring(i, i + 200), contains('AppColors.primary'));
    });

    test('status di Laporan Penjualan punya pemetaan eksplisit', () {
      // AKTIF sengaja PUTIH di sini, bukan hijau: harga di baris yang sama
      // sudah hijau, dan dua hijau berdampingan menghilangkan fungsi hijau
      // sebagai penanda uang.
      final s = baca('lib/screens/admin/laporan_penjualan_screen.dart');
      expect(s, contains('Color _warnaStatus(PesananTiketModel p)'));
      expect(s, contains('if (p.isAktif) return AppColors.aksi;'));
      expect(s, contains('if (p.isExpired || p.isCancelled) return AppColors.error;'));
    });
  });

  group('status berhasil hijau', () {
    test('badge AKTIF promo hijau', () {
      final s = baca('lib/screens/admin/kelola_promo_screen.dart');
      expect(s, contains("promo.isValid\n        ? AppColors.primary"));
    });

    test('badge APPROVED refund hijau', () {
      final s = baca('lib/screens/admin/kelola_refund_screen.dart');
      expect(s, contains('refund.isApproved ? AppColors.primary : AppColors.error'));
    });
  });

  group('navigasi tetap putih', () {
    test('tab gate scanner memakai aksi (putih)', () {
      final s = baca('lib/screens/admin/gate_scanner_screen.dart');
      expect(s, contains('indicatorColor: AppColors.aksi'));
      expect(s, contains('labelColor: AppColors.aksi'));
    });
  });

  group('hijau tidak dipakai untuk chrome', () {
    test('login bebas hijau', () {
      final s = baca('lib/screens/auth/login_screen.dart');
      expect(
        s,
        isNot(contains('AppColors.primary')),
        reason: 'Glow kanan atas dan teks "Daftar" dulu hijau.',
      );
    });

    test('pemutar audio memakai putih', () {
      final s = baca('lib/widgets/media/audio_preview_player.dart');
      expect(s, isNot(contains('AppColors.primary')));
    });

    test('pemilih audio memakai putih', () {
      final s = baca('lib/widgets/media/audio_picker_field.dart');
      expect(s, isNot(contains('AppColors.primary')));
    });

    test('badge SUPER ADMIN tidak memakai warna peringatan', () {
      final s = baca('lib/screens/admin/admin_dashboard.dart');
      expect(
        s,
        isNot(contains('isSuperAdmin ? AppColors.warning')),
        reason: 'Status tertinggi tidak boleh terlihat seperti peringatan.',
      );
    });
  });

  group('grafik revenue', () {
    test('garis Penjualan 7 Hari hijau', () {
      final s = baca('lib/screens/admin/laporan_revenue_screen.dart');
      // Warna garis pada LineChartBarData grafik 7 hari.
      final i = s.indexOf('spots: _dailySpots');
      expect(i, greaterThan(-1));
      final potongan = s.substring(i, i + 400);
      expect(potongan, contains('AppColors.primary'));
    });

    test('TOP 5 KONSER tetap memakai palet beragam', () {
      final s = baca('lib/screens/admin/laporan_revenue_screen.dart');
      expect(s, contains('_palette[i % _palette.length]'),
          reason: 'Kalau semua batang satu warna, legenda jadi tidak berguna.');
    });
  });

  group('tema voucher', () {
    test('lima tema tersedia', () {
      final s = baca('lib/widgets/promo/promo_card.dart');
      for (final tema in ['gold', 'emerald', 'amethyst', 'silver', 'red']) {
        expect(s, contains('TemaPromo.$tema'), reason: 'tema $tema hilang');
      }
    });

    test('merah promo berbeda dari merah galat', () {
      final s = baca('lib/widgets/promo/promo_card.dart');
      expect(s, contains('0xFFFF3048'), reason: 'merah luxury');
      // Merah galat #FF5A5F tidak boleh dipakai di kartu promo.
      expect(s, isNot(contains('0xFFFF5A5F')));
    });
  });

  group('bug yang pernah muncul', () {
    test('GambarWidget tahan terhadap double.infinity', () {
      final s = baca('lib/widgets/gambar_widget.dart');
      expect(
        s,
        contains('width!.isFinite'),
        reason: 'Tanpa ini, `double.infinity * dpr` lalu `.round()` melempar '
            '"Unsupported operation: Infinity or NaN toInt".',
      );
    });

    test('wadah kartu promo cukup tinggi', () {
      final s = baca('lib/screens/user/user_explore_screen.dart');
      expect(
        s,
        isNot(contains('height: 172,')),
        reason: '172px menyebabkan "BOTTOM OVERFLOWED BY 13 PIXELS".',
      );
    });
  });

  group('splash & ikon', () {
    test('equalizer splash beranimasi, bukan statis', () {
      final s = baca('lib/screens/splash_screen.dart');
      expect(s, contains('_eqController'));
      expect(s, contains('..repeat()'));
      expect(s, contains('math.sin'));
    });

    test('latar peluncur opak, bukan putih', () {
      final s = baca('android/app/src/main/res/drawable/launch_background.xml');
      expect(s, contains('@color/latar_peluncur'));
      expect(s, isNot(contains('@android:color/white')));
    });

    test('ada values-v31 untuk Android 12+', () {
      final f = File('android/app/src/main/res/values-v31/styles.xml');
      expect(f.existsSync(), isTrue,
          reason: 'Tanpa ini, Android 12+ memakai splash default (ikon saja, '
              'tanpa teks) dengan warna berbeda.');
      final s = f.readAsStringSync();
      expect(s, contains('windowSplashScreenBackground'));
      expect(s, contains('windowSplashScreenAnimatedIcon'));
    });

    test('warna peluncur sama dengan latar aplikasi', () {
      final s = baca('android/app/src/main/res/values/colors.xml');
      expect(s, contains('#08080C'));
    });
  });

  group('revisi admin A1-A7', () {
    test('A1 badge SUPER ADMIN tanpa pembungkus ganda', () {
      final s = baca('lib/screens/admin/admin_dashboard.dart');
      final i = s.indexOf("isSuperAdmin ? 'SUPER ADMIN' : 'ADMIN'");
      expect(i, greaterThan(-1));
      final sebelum = s.substring(i - 400, i);
      expect(sebelum, isNot(contains('borderRadius: AppRadius.rLg')),
          reason: 'Pembungkus Container lama membuat dua lapis latar '
              'bertumpuk sehingga badge terlihat tertimpa.');
    });

    test('A3 stok tersedia hijau', () {
      final s = baca('lib/screens/admin/tiket_screen.dart');
      expect(s, contains('_ => BadgeNada.valid'));
      expect(s, isNot(contains('_ => BadgeNada.lewat')));
    });

    test('A4 harga di Manage Tiket hijau', () {
      final s = baca('lib/screens/admin/tiket_screen.dart');
      final i = s.indexOf('tiket.formatHarga');
      expect(i, greaterThan(-1));
      expect(s.substring(i, i + 500), contains('AppColors.primary'));
    });

    test('A7 form Edit Konser bebas hijau', () {
      for (final f in [
        'lib/widgets/media/video_picker_field.dart',
        'lib/widgets/media/venue_model_picker_field.dart',
        'lib/widgets/media/trailer_player.dart',
      ]) {
        expect(baca(f), isNot(contains('AppColors.primary')),
            reason: '$f masih memakai hijau untuk kendali.');
      }
    });

    test('tema global tidak mewarnai kendali dengan hijau', () {
      final s = baca('lib/utils/app_theme.dart');
      for (final komponen in [
        'progressIndicatorTheme',
        'tabBarTheme',
        'switchTheme',
        'checkboxTheme',
        'radioTheme',
        'snackBarTheme',
        'listTileTheme',
      ]) {
        final i = s.indexOf(komponen);
        expect(i, greaterThan(-1), reason: '$komponen hilang dari tema');
        final blok = s.substring(i, i + 500);
        expect(blok, isNot(contains('AppColors.primary')),
            reason: '$komponen masih memakai hijau — hijau akan muncul lagi '
                'di layar mana pun tanpa disadari.');
      }
    });
  });
}
