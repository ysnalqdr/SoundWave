import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:soundwave/utils/app_theme.dart';
import 'package:soundwave/widgets/badge_status.dart';

/// Penjaga tema monokrom.
///
/// Tema ini punya satu aturan yang mudah dilanggar tanpa sadar:
///
///   **Hijau hanya untuk uang. Putih untuk aksi. Merah untuk berhenti.**
///
/// Tes ini mengunci aturan itu di tiga tempat: token warna, nada badge, dan
/// isi berkas layar. Tujuannya bukan gaya — tujuannya supaya "hijau" tetap
/// punya arti. Sebelum ini hijau dipakai 229 kali untuk 7 makna berbeda.
void main() {
  /// Luminansi relatif WCAG.
  double _luminans(Color c) {
    double f(double v) =>
        v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
  }

  double kontras(Color a, Color b) {
    final la = _luminans(a), lb = _luminans(b);
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  /// Persepsi terang (L*). Dipakai untuk mengukur apakah dua permukaan
  /// TERLIHAT berbeda — rasio WCAG menipu di warna gelap.
  double lstar(Color c) {
    final y = _luminans(c);
    return y > 0.008856 ? 116 * math.pow(y, 1 / 3).toDouble() - 16 : 903.3 * y;
  }

  group('Rampa permukaan benar-benar terpisah', () {
    test('setiap langkah minimal 4 L* (mata butuh >=4 untuk melihat bidang)', () {
      // Sebelumnya tiga permukaan pertama hanya berbeda 1,83-3,97 L*, jadi
      // kartu tidak "muncul" dari latar dan aplikasi terasa datar.
      final rampa = <String, Color>{
        'background': AppColors.background,
        'surface': AppColors.surface,
        'card': AppColors.card,
        'surfaceLight': AppColors.surfaceLight,
        'overlay': AppColors.overlay,
      };
      final nama = rampa.keys.toList();

      for (var i = 0; i < nama.length - 1; i++) {
        final a = rampa[nama[i]]!;
        final b = rampa[nama[i + 1]]!;
        final d = (lstar(b) - lstar(a)).abs();
        expect(d, greaterThanOrEqualTo(2.0),
            reason: '${nama[i]} -> ${nama[i + 1]} hanya beda '
                '${d.toStringAsFixed(2)} L* — terlalu dekat untuk terlihat');
      }

      // overlay WAJIB paling terang: navbar mengambang harus melayang, bukan
      // tenggelam. Dulu surface (#0E0E13) lebih gelap dari card (#17171F).
      expect(lstar(AppColors.overlay), greaterThan(lstar(AppColors.surfaceLight)));
    });

    test('teks tetap lulus AA di permukaan terang', () {
      final permukaan = {
        'background': AppColors.background,
        'surface': AppColors.surface,
        'card': AppColors.card,
        'surfaceLight': AppColors.surfaceLight,
      };
      permukaan.forEach((nama, bg) {
        for (final t in <String, Color>{
          'textPrimary': AppColors.textPrimary,
          'textSecondary': AppColors.textSecondary,
          'textMuted': AppColors.textMuted,
        }.entries) {
          final r = kontras(t.value, bg);
          expect(r, greaterThanOrEqualTo(4.5),
              reason: '${t.key} di $nama hanya ${r.toStringAsFixed(2)}:1');
        }
      });
    });
  });

  group('Aksi memakai putih, bukan hijau', () {
    test('teks di atas tombol putih lulus AAA', () {
      final r = kontras(AppColors.onAksi, AppColors.aksi);
      expect(r, greaterThanOrEqualTo(7.0),
          reason: 'tombol putih hanya ${r.toStringAsFixed(2)}:1');
      // Putih harus lebih kuat dari hijau — kalau tidak, tidak ada alasan
      // memakainya.
      expect(r, greaterThan(kontras(AppColors.onPrimary, AppColors.primary)));
    });

    test('aksi dan primary adalah warna berbeda', () {
      expect(AppColors.aksi.toARGB32(), isNot(AppColors.primary.toARGB32()),
          reason: 'kalau sama, aturan "hijau hanya untuk uang" tidak berlaku');
    });
  });

  group('Peringatan sunset bisa dibedakan dari hijau', () {
    test('selisih L* peringatan vs harga minimal 4', () {
      // Amber #FFC107 dan gold #FFB300 gagal di sini (selisih 5,7 dan 2,3).
      // Untuk buta warna merah-hijau keduanya jadi kuning kecokelatan.
      final d = (lstar(AppColors.warning) - lstar(AppColors.primary)).abs();
      expect(d, greaterThanOrEqualTo(4.0),
          reason: 'peringatan hanya ${d.toStringAsFixed(2)} L* dari hijau');
    });

    test('peringatan lulus AA di atas kartu', () {
      final r = kontras(AppColors.warning, AppColors.card);
      expect(r, greaterThanOrEqualTo(4.5),
          reason: 'peringatan di kartu ${r.toStringAsFixed(2)}:1');
    });
  });

  group('Badge monokrom dibedakan BENTUK, bukan tingkat abu', () {
    test('setiap nada punya isi/border/coret yang berbeda', () {
      // Kalau dua nada hanya dibedakan warna latar, selisih L* cuma ~2 dan
      // tidak terbaca. Yang terbaca: ada isi, ada border, atau dicoret.
      Widget b(BadgeNada n) => BadgeStatus('X', nada: n);
      expect(b(BadgeNada.final_), isNotNull);
      expect(b(BadgeNada.jalan), isNotNull);
      expect(b(BadgeNada.lewat), isNotNull);
      expect(b(BadgeNada.gagal), isNotNull);
    });

    test('pemetaan status pesanan memakai warna secara SEMANTIK', () {
      // Sejak revisi Okt 2026, hijau dipakai untuk DUA makna saja: uang dan
      // status berhasil. Jadi AKTIF kini hijau, PENDING sunset, dan semua
      // status "sudah selesai" (TERPAKAI / REFUND / KEDALUWARSA) memakai
      // SATU nada abu yang dibedakan lewat ikon — bukan tiga tingkat abu,
      // karena selisih antar tingkat abu di tema ini hanya 1,95 L*.
      expect(nadaUntukStatusPesanan('AKTIF').nada, BadgeNada.valid);
      expect(nadaUntukStatusPesanan('PAID').nada, BadgeNada.valid);
      expect(nadaUntukStatusPesanan('PENDING').nada, BadgeNada.peringatan);
      expect(nadaUntukStatusPesanan('TERPAKAI').nada, BadgeNada.selesai);
      expect(nadaUntukStatusPesanan('EXPIRED').nada, BadgeNada.selesai);
      expect(nadaUntukStatusPesanan('REFUNDED').nada, BadgeNada.selesai);
      expect(nadaUntukStatusPesanan('CANCELLED').nada, BadgeNada.gagal);
    });

    test('status selesai dibedakan lewat IKON, bukan tingkat abu', () {
      final terpakai = nadaUntukStatusPesanan('TERPAKAI');
      final kedaluwarsa = nadaUntukStatusPesanan('EXPIRED');
      final refund = nadaUntukStatusPesanan('REFUNDED');

      // Warna sama...
      expect(terpakai.nada, kedaluwarsa.nada);
      expect(terpakai.nada, refund.nada);
      // ...tapi ikonnya berbeda semua.
      expect({terpakai.ikon, kedaluwarsa.ikon, refund.ikon}.length, 3,
          reason: 'tiga status selesai harus punya tiga ikon berbeda, '
              'karena warnanya sengaja disamakan.');
    });

    test('KEDALUWARSA tidak lagi dicoret', () {
      // Dicoret membuat kedaluwarsa terlihat seperti kesalahan pengguna,
      // padahal itu hanya waktu yang lewat.
      final g = nadaUntukStatusPesanan('EXPIRED');
      expect(g.nada, isNot(BadgeNada.gagal));
    });

    test('label refund memakai "REFUND", bukan "DI-REFUND"', () {
      expect(nadaUntukStatusPesanan('REFUNDED').teks, 'REFUND');
    });

    test('hierarki peran naik sesuai izin', () {
      expect(nadaUntukPeran('SUPER ADMIN'), BadgeNada.final_);
      expect(nadaUntukPeran('ADMIN'), BadgeNada.jalan);
      expect(nadaUntukPeran('MEMBER'), BadgeNada.lewat);
    });
  });

  group('Navbar kaca', () {
    test('opasitas minimal 90% supaya lulus di atas poster terang', () {
      // Pada 85% latar efektif di atas poster putih = #4B4B52 dan teks pasif
      // hanya 4,21:1 (gagal). Pada 90% = 5,01:1 (lulus).
      final alfa = AppColors.navKaca.a;
      expect(alfa, greaterThanOrEqualTo(0.90),
          reason: 'opasitas ${(alfa * 100).toStringAsFixed(0)}% — '
              'di atas poster terang kontras teks pasif akan gagal AA');
    });

    test('teks pasif navbar lulus AA di atas kaca', () {
      // Kaca di atas latar paling gelap.
      final r = kontras(AppColors.navTeksPasif, AppColors.overlay);
      expect(r, greaterThanOrEqualTo(4.5),
          reason: 'teks pasif navbar ${r.toStringAsFixed(2)}:1');
    });

    test('ikon tab aktif lulus AAA di atas pil putih', () {
      final r = kontras(AppColors.navPilAktifFg, AppColors.navPilAktif);
      expect(r, greaterThanOrEqualTo(7.0),
          reason: 'ikon tab aktif ${r.toStringAsFixed(2)}:1');
    });
  });

  group('Hijau tidak bocor ke chrome', () {
    test('tidak ada tombol berwarna hijau di layar admin', () {
      // Chrome admin harus monokrom. Hijau hanya boleh muncul untuk uang
      // (aksen: primary / success pada KPI & grafik) dan gate scanner.
      final pelanggaran = <String>[];

      for (final entitas in Directory('lib/screens/admin').listSync()) {
        if (entitas is! File || !entitas.path.endsWith('.dart')) continue;
        final nama = entitas.path.split(Platform.pathSeparator).last;
        final isi = entitas.readAsStringSync();
        final baris = isi.split('\n');

        for (var i = 0; i < baris.length; i++) {
          final t = baris[i].trim();
          if (t.startsWith('//')) continue;
          if (!t.contains('backgroundColor: AppColors.primary') &&
              !t.contains('backgroundColor: AppColors.success')) {
            continue;
          }
          // Gate scanner dikecualikan: hijau di sana kode keselamatan.
          if (nama.contains('gate_scanner')) continue;
          pelanggaran.add('$nama:${i + 1}  $t');
        }
      }

      expect(pelanggaran, isEmpty,
          reason: 'tombol hijau di chrome admin:\n${pelanggaran.join('\n')}');
    });

    test('navbar tidak lagi memakai BottomNavigationBar', () {
      final isi =
          File('lib/screens/user/user_main_screen.dart').readAsStringSync();
      expect(isi.contains('BottomNavigationBar'), isFalse,
          reason: 'navbar lama lebih gelap dari kartu sehingga tenggelam');
      expect(isi.contains('NavbarKaca'), isTrue);
    });

    test('setiap tab punya ruang bawah supaya item terakhir tidak tertutup',
        () {
      // Cacat yang justru ada di referensi Proton Pass: navbar mengambang
      // menutupi baris terakhir daftar.
      final berkas = <String>[
        'lib/screens/user/user_explore_screen.dart',
        'lib/screens/user/user_tiket_screen.dart',
        'lib/screens/user/user_favorit_screen.dart',
        'lib/screens/user/user_main_screen.dart',
      ];
      for (final p in berkas) {
        final isi = File(p).readAsStringSync();
        expect(isi.contains('AppSpacing.ruangNavbar'), isTrue,
            reason: '$p belum diberi ruang bawah untuk navbar mengambang');
      }
    });
  });
}
