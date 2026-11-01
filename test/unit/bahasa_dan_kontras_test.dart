import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/core/errors/pesan_galat.dart';
import 'package:soundwave/utils/app_theme.dart';

/// Penjaga bahasa dan kontras antarmuka.
///
/// Dua hal yang mudah mundur tanpa ketahuan:
///
/// 1. **Teks mesin bocor ke layar pengguna.** Nama paket, kode galat, dan nama
///    basis data tidak pernah boleh muncul di UI. Ini bukan soal selera — ia
///    membuat aplikasi terasa belum jadi, dan langsung terlihat saat demo.
///
/// 2. **Kontras teks turun di bawah WCAG.** Satu perubahan hex di palet bisa
///    membuat 211 tempat gagal aksesibilitas sekaligus. Angka kontras dikunci
///    di sini supaya tidak bisa diturunkan tanpa sadar.
void main() {
  group('PesanGalat — menerjemahkan tanpa membocorkan mesin', () {
    test('galat jaringan jadi kalimat yang bisa ditindaklanjuti', () {
      final pesan = PesanGalat.untuk(
        Exception('SocketException: Failed host lookup'),
      );
      expect(pesan.toLowerCase(), contains('koneksi'));
      expect(pesan.toLowerCase(), isNot(contains('socketexception')));
      expect(pesan.toLowerCase(), isNot(contains('host lookup')));
    });

    test('nama paket firestore tidak pernah muncul', () {
      for (final e in <Object>[
        Exception('[cloud_firestore/permission-denied] Missing or insufficient'),
        Exception('PlatformException(channel-error)'),
        Exception('FirebaseException: unavailable'),
      ]) {
        final pesan = PesanGalat.untuk(e, awalan: 'Gagal memuat');
        final rendah = pesan.toLowerCase();
        for (final bocor in <String>[
          'cloud_firestore',
          'platformexception',
          'firebaseexception',
          'channel-error',
          'exception',
        ]) {
          expect(rendah, isNot(contains(bocor)),
              reason: 'pesan "$pesan" membocorkan "$bocor"');
        }
      }
    });

    test('kode galat mentah tidak ikut tampil', () {
      final pesan = PesanGalat.untuk(
        Exception('error: 400 Bad Request'),
        awalan: 'Gagal menyimpan',
      );
      expect(pesan, isNot(contains('400')));
      expect(pesan, contains('Gagal menyimpan'));
    });

    test('exception yang terbungkus tetap diterjemahkan', () {
      // Kasus paling nyata: FirebaseException asli dibungkus lapisan lain
      // sehingga tipenya hilang dan hanya teksnya tersisa.
      final kasus = <String, Object>{
        'permission-denied': Exception(
            '[cloud_firestore/permission-denied] Missing or insufficient permissions.'),
        'unavailable': Exception('[cloud_firestore/unavailable] The service is currently unavailable.'),
        'timeout': Exception('TimeoutException after 0:00:30.000000'),
        'unauthenticated': Exception('unauthenticated: ID token has expired'),
        'resource-exhausted': Exception('[cloud_firestore/resource-exhausted] Quota exceeded'),
      };
      kasus.forEach((kode, e) {
        final pesan = PesanGalat.untuk(e, awalan: 'Gagal memuat');
        expect(pesan, isNot(contains('Gagal memuat')),
            reason: '$kode seharusnya punya pesan khusus, bukan awalan generik');
        expect(pesan.toLowerCase(), isNot(contains(kode)),
            reason: '$kode tidak boleh tampil ke pengguna');
      });
    });

    test('kalimat manusia dari lapisan bawah diteruskan apa adanya', () {
      // database_service melempar string Indonesia yang sudah jadi. Itu pesan
      // terbaik yang bisa diberikan, jadi jangan ditimpa.
      const asli = 'Stok tiket tidak mencukupi (Sisa stok: 3).';
      expect(PesanGalat.untuk(asli), asli);
    });

    test('awalan dipakai saat tidak ada padanan khusus', () {
      final pesan = PesanGalat.untuk(
        Exception('sesuatu yang tidak dikenal'),
        awalan: 'Gagal menyimpan konser',
      );
      expect(pesan, startsWith('Gagal menyimpan konser'));
      expect(pesan.toLowerCase(), isNot(contains('exception')));
    });

    test('selalu ada kalimat, tidak pernah kosong', () {
      for (final e in <Object>[
        Exception(''),
        StateError('x'),
        ArgumentError('y'),
        '',
      ]) {
        expect(PesanGalat.untuk(e).trim(), isNotEmpty);
      }
    });

    test('tidak pernah mengembalikan tipe exception mentah', () {
      final pesan = PesanGalat.untuk(
        Exception('Null check operator used on a null value'),
      );
      expect(pesan, isNot(contains('Null check operator')));
      expect(pesan.trim(), isNotEmpty);
    });
  });

  group('Tidak ada teks mesin tersisa di layar', () {
    /// Semua berkas UI yang dibaca.
    List<File> berkasUi() {
      final out = <File>[];
      for (final dir in <String>['lib/screens', 'lib/widgets']) {
        final d = Directory(dir);
        if (!d.existsSync()) continue;
        for (final f in d.listSync(recursive: true)) {
          if (f is File && f.path.endsWith('.dart')) out.add(f);
        }
      }
      return out;
    }

    test('tidak ada lagi teks UI yang menyisipkan exception mentah', () {
      final pelanggaran = <String>[];
      for (final f in berkasUi()) {
        final isi = f.readAsStringSync();
        for (final baris in isi.split('\n')) {
          final t = baris.trim();
          if (t.startsWith('//') || t.startsWith('debugPrint')) continue;
          // Pola lama: teks UI yang menyisipkan exception mentah.
          if (t.contains(r'$e')) {
            pelanggaran.add('${f.path}: $t');
          }
        }
      }
      expect(pelanggaran, isEmpty,
          reason: 'exception mentah tidak boleh tampil ke pengguna:\n'
              '${pelanggaran.join('\n')}');
    });

    test('tidak ada nama basis data di teks UI', () {
      final pelanggaran = <String>[];
      for (final f in berkasUi()) {
        final isi = f.readAsStringSync();
        for (final baris in isi.split('\n')) {
          final t = baris.trim();
          if (t.startsWith('//') || t.startsWith('debugPrint')) continue;
          if (!t.contains('Text(') && !RegExp(r"'[^']{6,}'").hasMatch(t)) {
            continue;
          }
          if (t.contains('Firestore') || t.contains('Cloud Firestore')) {
            pelanggaran.add('${f.path}: $t');
          }
        }
      }
      expect(pelanggaran, isEmpty,
          reason: 'pengguna tidak perlu tahu nama basis datanya:\n'
              '${pelanggaran.join('\n')}');
    });

    test('tidak ada istilah mesin di layar pembayaran', () {
      final berkas = <String>[
        'lib/screens/user/checkout_parts/checkout_steps.dart',
        'lib/screens/user/checkout_parts/checkout_forms.dart',
        'lib/screens/user/checkout_parts/checkout_sheets.dart',
        'lib/screens/user/checkout_parts/checkout_layout.dart',
      ];
      final pelanggaran = <String>[];
      for (final path in berkas) {
        final f = File(path);
        if (!f.existsSync()) continue;
        final isi = f.readAsStringSync();
        for (final kata in <String>[
          'atomik',
          'checkout-atomic',
          '256-bit',
          'SSL',
          'endpoint',
          'payload',
          'API',
        ]) {
          if (isi.contains(kata)) {
            pelanggaran.add('$path mengandung "$kata"');
          }
        }
      }
      expect(pelanggaran, isEmpty,
          reason: 'layar pembayaran harus bicara soal uang, bukan teknologi:\n'
              '${pelanggaran.join('\n')}');
    });
  });

  group('Hierarki tipografi — huruf kapital tidak dipakai berlebihan', () {
    /// Mengumpulkan judul bagian (bukan judul halaman) yang masih ALL CAPS.
    ///
    /// Kenapa ini dikunci: ada **40 judul** yang dulu ditulis kapital semua.
    /// Huruf kapital semua menghapus bentuk kata, jadi mata mencerna lebih
    /// lambat, dan kalau dipakai di mana-mana tidak ada lagi yang terasa
    /// penting — semuanya berteriak.
    ///
    /// Judul **halaman** (AppBar) sengaja tetap kapital: itu penanda navigasi
    /// dan hanya satu per layar. Yang dilarang adalah judul **bagian** di dalam
    /// halaman.
    List<String> judulBagianKapital() {
      final out = <String>[];
      final pola = RegExp(r"(Text\(\s*|label:\s*)'([A-Z0-9][A-Z0-9 &·\-\./()%]{3,})'");
      final dirs = <String>['lib/screens', 'lib/widgets'];
      for (final dir in dirs) {
        final d = Directory(dir);
        if (!d.existsSync()) continue;
        for (final f in d.listSync(recursive: true)) {
          if (f is! File || !f.path.endsWith('.dart')) continue;
          final isi = f.readAsStringSync();
          for (final m in pola.allMatches(isi)) {
            final t = m.group(2)!;
            final kata = t
                .split(RegExp(r'[^A-Za-z0-9]+'))
                .where((w) => w.isNotEmpty)
                .toList();
            final kapital =
                kata.where((w) => w.length > 1 && w == w.toUpperCase()).length;
            if (kata.length >= 2 && kapital >= 2) {
              out.add('${f.path}: $t');
            }
          }
        }
      }
      return out;
    }

    test('judul bagian tidak lagi ALL CAPS', () {
      // Sisa yang diizinkan: judul halaman (AppBar) dan badge peran. Itu
      // penanda navigasi, bukan judul bagian.
      const diizinkan = <String>{
        // Judul halaman (AppBar): penanda navigasi, satu per layar.
        'KELOLA PROMO',
        'LAPORAN & ANALITIK PENJUALAN',
        'LAPORAN REVENUE',
        'VOUCHER SAYA',
        'BAGIKAN KONSER',
        'TIKET SAYA',
        // Badge status: harus sejajar bentuknya dengan AKTIF / TERPAKAI /
        // PENDING yang sudah kapital. Title Case di sini justru membuat
        // deretan badge terlihat tidak rata.
        'SUPER ADMIN',
        'SUDAH DIGUNAKAN',
        'TIKET BERHASIL DIGUNAKAN',
        'PENGAJUAN REFUND DITOLAK',
        'REFUND SEDANG DITINJAU',
        'REFUND DISETUJUI',
        'RESERVASI BERAKHIR',
      };

      final pelanggaran = judulBagianKapital()
          .where((baris) {
            final judul = baris.split(': ').last;
            return !diizinkan.contains(judul);
          })
          .toList();

      expect(pelanggaran, isEmpty,
          reason: 'judul bagian harus Title Case:\n${pelanggaran.join('\n')}');
    });

    test('istilah fitur konsisten: Favorit, bukan campur Wishlist', () {
      // Tab bawah bernama "Wishlist" sementara judul kartunya "Konser
      // Favorit". Satu konsep, dua nama — membingungkan.
      final pelanggaran = <String>[];
      for (final path in <String>[
        'lib/screens/user/user_main_screen.dart',
        'lib/screens/user/user_favorit_screen.dart',
      ]) {
        final isi = File(path).readAsStringSync();
        for (final baris in isi.split('\n')) {
          final t = baris.trim();
          if (t.startsWith('//')) continue;
          if (t.contains("'Wishlist'") || t.contains('WISHLIST')) {
            pelanggaran.add('$path: $t');
          }
        }
      }
      expect(pelanggaran, isEmpty,
          reason: 'pakai satu istilah saja:\n${pelanggaran.join('\n')}');
    });
  });

  group('Kontras WCAG — angka dikunci', () {
    double luminance(Color c) {
      double ch(double s) =>
          s <= 0.03928 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
      return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
    }

    double kontras(Color a, Color b) {
      final la = luminance(a);
      final lb = luminance(b);
      final hi = la > lb ? la : lb;
      final lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    /// Semua permukaan tempat teks biasanya diletakkan.
    final permukaan = <String, Color>{
      'background': AppColors.background,
      'surface': AppColors.surface,
      'card': AppColors.card,
      'surfaceLight': AppColors.surfaceLight,
    };

    test('textPrimary lulus AA di semua permukaan', () {
      permukaan.forEach((nama, warna) {
        expect(kontras(AppColors.textPrimary, warna), greaterThanOrEqualTo(4.5),
            reason: 'textPrimary di $nama');
      });
    });

    test('textSecondary lulus AA di semua permukaan', () {
      permukaan.forEach((nama, warna) {
        expect(
            kontras(AppColors.textSecondary, warna), greaterThanOrEqualTo(4.5),
            reason: 'textSecondary di $nama');
      });
    });

    test('textMuted lulus AA di semua permukaan', () {
      // Nilai lama #6B6B78 hanya 3,18:1 di surfaceLight — gagal. Tes ini
      // mencegah nilai itu kembali.
      permukaan.forEach((nama, warna) {
        final r = kontras(AppColors.textMuted, warna);
        expect(r, greaterThanOrEqualTo(4.5),
            reason: 'textMuted di $nama hanya ${r.toStringAsFixed(2)}:1');
      });
    });

    test('teks di atas primary lulus AAA', () {
      // Putih di atas emerald hanya 1,92:1 — ini kesalahan paling umum.
      final r = kontras(AppColors.onPrimary, AppColors.primary);
      expect(r, greaterThanOrEqualTo(7.0),
          reason: 'onPrimary di atas primary hanya ${r.toStringAsFixed(2)}:1');
    });

    test('putih TIDAK dipakai di atas primary', () {
      final r = kontras(Colors.white, AppColors.primary);
      expect(r, lessThan(3.0),
          reason: 'kalau angka ini berubah, paletnya sudah berubah — '
              'periksa ulang seluruh tombol');
    });

    test('hierarki antar tingkat teks tetap terbaca', () {
      // Kalau textMuted dinaikkan terlalu jauh, ia menyamai textSecondary dan
      // hierarki hilang. Minimal 1,15× bedanya.
      expect(kontras(AppColors.textSecondary, AppColors.textMuted),
          greaterThan(1.15));
      expect(kontras(AppColors.textMuted, AppColors.textDisabled),
          greaterThan(1.5));
    });

    test('warna status lulus AA di background', () {
      for (final entry in <String, Color>{
        'error': AppColors.error,
        'warning': AppColors.warning,
        'success': AppColors.success,
        'info': AppColors.info,
      }.entries) {
        final r = kontras(entry.value, AppColors.background);
        expect(r, greaterThanOrEqualTo(4.5),
            reason: '${entry.key} hanya ${r.toStringAsFixed(2)}:1');
      }
    });
  });
}
