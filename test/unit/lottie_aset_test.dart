import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Penjaga aset Lottie layar sukses.
///
/// Aset pihak ketiga mudah tergeser dari brand tanpa ketahuan: file diganti,
/// warna dikembalikan ke default, atau ukurannya membengkak sampai APK berat.
/// Tes ini mengunci tiga hal yang paling sering bocor.
void main() {
  const path = 'assets/lottie/success_confetti.json';

  late Map<String, dynamic> lottie;

  setUpAll(() {
    final file = File(path);
    expect(file.existsSync(), isTrue, reason: 'aset Lottie harus ada di $path');
    lottie = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  });

  group('success_confetti.json — struktur', () {
    test('JSON valid dan punya field wajib Lottie', () {
      expect(lottie['v'], isA<String>());
      expect(lottie['fr'], isA<num>());
      expect(lottie['ip'], isA<num>());
      expect(lottie['op'], isA<num>());
      expect(lottie['layers'], isA<List>());
      expect((lottie['layers'] as List), isNotEmpty);
    });

    test('kanvas persegi (sesuai pemakaian BoxFit.contain)', () {
      expect(lottie['w'], lottie['h']);
    });

    test('berdurasi wajar, tidak terlalu panjang', () {
      final fr = (lottie['fr'] as num).toDouble();
      final durasi = ((lottie['op'] as num) - (lottie['ip'] as num)) / fr;
      expect(durasi, greaterThan(1.0));
      expect(durasi, lessThanOrEqualTo(5.0),
          reason: 'perayaan lebih dari 5 detik akan terasa mengganggu');
    });
  });

  group('success_confetti.json — ukuran', () {
    test('di bawah 150 KB agar APK tidak membengkak', () {
      final bytes = File(path).lengthSync();
      expect(bytes, lessThan(150 * 1024),
          reason: 'ukuran aktual: ${(bytes / 1024).toStringAsFixed(1)} KB');
    });
  });

  group('success_confetti.json — warna brand', () {
    /// Mengumpulkan semua warna `fill` di seluruh layer.
    List<Color> fillColors(dynamic node) {
      final out = <Color>[];
      void walk(dynamic n) {
        if (n is Map) {
          if (n['ty'] == 'fl' && n['c'] is Map) {
            final k = (n['c'] as Map)['k'];
            if (k is List && k.length >= 3) {
              out.add(Color.fromARGB(
                255,
                ((k[0] as num) * 255).round(),
                ((k[1] as num) * 255).round(),
                ((k[2] as num) * 255).round(),
              ));
            }
          }
          for (final v in n.values) {
            walk(v);
          }
        } else if (n is List) {
          for (final v in n) {
            walk(v);
          }
        }
      }

      walk(node);
      return out;
    }

    test('aset kembali ke warna default (berwarna, bukan monokrom)', () {
      // Okt 2026: confetti sempat diwarnai ulang jadi monokrom, tetapi
      // pekerjaan itu TIDAK TUNTAS — 6 warna diganti abu, 2 warna tertinggal
      // (hijau dan merah muda), sehingga hasilnya abu kusam bercampur bintik
      // warna nyasar.
      //
      // Atas permintaan pemilik produk, aset dikembalikan ke versi aslinya.
      // Tes ini menjaga agar tidak ada yang mewarnai ulang setengah jalan
      // lagi: confetti HARUS berwarna.
      final colors = fillColors(lottie);
      expect(colors, isNotEmpty, reason: 'aset harus punya minimal satu fill');

      final berwarna = colors.where((c) {
        final r = ((c.toARGB32() >> 16) & 0xFF);
        final g = ((c.toARGB32() >> 8) & 0xFF);
        final b = (c.toARGB32() & 0xFF);
        final maks = [r, g, b].reduce((a, b) => a > b ? a : b);
        final min = [r, g, b].reduce((a, b) => a < b ? a : b);
        final saturasi = maks == 0 ? 0.0 : (maks - min) / maks;
        return saturasi > 0.05;
      }).toList();

      expect(berwarna, isNotEmpty,
          reason: 'aset kembali monokrom — confetti seharusnya berwarna.');
    });

    test('tidak memakai hijau neon lama #00E676', () {
      const neonLama = Color(0xFF00E676);
      final colors = fillColors(lottie);
      final adaNeon =
          colors.any((c) => c.toARGB32() == neonLama.toARGB32());
      expect(adaNeon, isFalse,
          reason: 'aset masih memakai hijau neon yang sudah diganti emerald');
    });
  });

  // ---------------------------------------------------------------------------
  // Animasi tambahan: tunggu & galat.
  //
  // Keduanya datang dari sumber berbeda dan punya sifat berbeda:
  // `loading_cat` monokrom (aman di-tint), `error_404` berilustrasi penuh
  // (tidak boleh di-tint). Perbedaan ini mudah terlewat dan akibatnya terlihat
  // jelas di layar, jadi dikunci di sini.
  // ---------------------------------------------------------------------------
  group('loading_cat.json', () {
    late Map<String, dynamic> animasi;

    setUpAll(() {
      final f = File('assets/lottie/loading_cat.json');
      expect(f.existsSync(), isTrue, reason: 'berkas animasi tunggu hilang');
      animasi = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    });

    test('JSON Lottie sah dengan layer', () {
      for (final k in ['v', 'fr', 'ip', 'op', 'w', 'h', 'layers']) {
        expect(animasi.containsKey(k), isTrue, reason: 'kunci "$k" tidak ada');
      }
      expect((animasi['layers'] as List), isNotEmpty);
    });

    test('berdurasi loop yang wajar', () {
      final fr = (animasi['fr'] as num).toDouble();
      final durasi = ((animasi['op'] as num) - (animasi['ip'] as num)) / fr;
      expect(durasi, greaterThan(0.5));
      expect(durasi, lessThanOrEqualTo(6.0));
    });

    test('ukurannya ringan', () {
      final kb = File('assets/lottie/loading_cat.json').lengthSync() / 1024;
      expect(kb, lessThan(100), reason: 'aktual: ${kb.toStringAsFixed(0)} KB');
    });
  });

  group('error_404.json', () {
    late Map<String, dynamic> animasi;

    setUpAll(() {
      final f = File('assets/lottie/error_404.json');
      expect(f.existsSync(), isTrue, reason: 'berkas ilustrasi galat hilang');
      animasi = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    });

    test('JSON Lottie sah dengan layer', () {
      for (final k in ['v', 'fr', 'ip', 'op', 'w', 'h', 'layers']) {
        expect(animasi.containsKey(k), isTrue, reason: 'kunci "$k" tidak ada');
      }
      expect((animasi['layers'] as List), isNotEmpty);
    });

    test('tidak di-tint oleh komponen', () {
      final komponen = File('lib/widgets/feedback/app_state_views.dart')
          .readAsStringSync();
      final awal = komponen.indexOf('class AppErrorState');
      final akhir = komponen.indexOf('class AppLoadingRow');
      expect(awal, greaterThan(-1));
      final blok = komponen.substring(awal, akhir);
      expect(blok.contains('ColorFilter'), isFalse,
          reason: 'ilustrasi berwarna rata jadi satu blok bila di-tint');
    });
  });

  group('komponen tampilan keadaan', () {
    final komponen = File('lib/widgets/feedback/app_state_views.dart')
        .readAsStringSync();
    final daftar =
        File('lib/core/media/lottie_assets.dart').readAsStringSync();

    test('path animasi dipusatkan di satu tempat', () {
      expect(daftar.contains("assets/lottie/loading_cat.json"), isTrue);
      expect(daftar.contains("assets/lottie/error_404.json"), isTrue);
      expect(daftar.contains("assets/lottie/success_confetti.json"), isTrue);
    });

    test('animasi tunggu di-loop dan diberi cadangan', () {
      expect(komponen.contains('repeat: true'), isTrue);
      expect(komponen.contains('errorBuilder'), isTrue,
          reason: 'layar tidak boleh kosong total saat animasi rusak');
    });

    test('animasi tunggu monokrom di-tint ke warna tema', () {
      expect(komponen.contains('BlendMode.srcIn'), isTrue);
    });

    test('galat selalu menawarkan jalan keluar', () {
      expect(komponen.contains('final VoidCallback? onRetry'), isTrue);
      expect(komponen.contains('retryLabel'), isTrue);
    });

    test('baris tunggu di dalam daftar tidak memakai Lottie', () {
      final idx = komponen.indexOf('class AppLoadingRow');
      expect(komponen.substring(idx).contains('Lottie.asset'), isFalse,
          reason: 'animasi vektor di banyak baris membebani render');
    });

    test('layar Jelajah sudah memakai komponen baru', () {
      final explore = File('lib/screens/user/user_explore_screen.dart')
          .readAsStringSync();
      expect(explore.contains('AppLoading('), isTrue);
      expect(explore.contains('AppErrorState('), isTrue);
      expect(explore.contains('onRetry:'), isTrue);
    });
  });

  group('pendaftaran aset', () {
    test('folder assets/lottie terdaftar di pubspec', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.contains('assets/lottie/'), isTrue,
          reason: 'tanpa pendaftaran, Lottie.asset akan gagal memuat');
    });

    test('package lottie terpasang', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.contains('lottie:'), isTrue);
    });
  });
}
