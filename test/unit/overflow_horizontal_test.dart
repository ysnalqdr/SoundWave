import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Penjaga overflow horizontal.
///
/// Overflow horizontal terjadi ketika sebuah `Row` berisi anak yang tidak mau
/// mengecil — teks panjang, `Wrap`, atau `Row` bersarang — tanpa dibungkus
/// `Expanded` / `Flexible`. Hasilnya pita kuning-hitam "RIGHT OVERFLOWED"
/// yang hanya muncul di perangkat, tidak saat kompilasi.
///
/// Tes ini memeriksa pola yang **benar-benar pernah meluber**: halaman
/// inspect konser dengan 6 genre, dan beberapa baris teks+tombol.
void main() {
  group('Inspect konser — genre tidak meluber', () {
    final sumber =
        File('lib/screens/admin/inspect_konser_screen.dart').readAsStringSync();

    test('Wrap genre dibungkus Flexible', () {
      // Ini bug yang dilaporkan: 6 genre (K-Pop, Country, Indie, R&B,
      // Electronic, Pop) memaksa lebar melebihi layar.
      final idx = sumber.indexOf('widget.konser.genre.map');
      expect(idx, greaterThan(-1));
      // 500 karakter ke belakang: cukup untuk melihat pembungkusnya.
      final konteks = sumber.substring((idx - 500).clamp(0, idx), idx);
      expect(konteks.contains('Flexible('), isTrue,
          reason: 'Wrap sebagai anak Row tanpa batas lebar akan meluber '
              'saat jumlah genre banyak');
    });

    test('judul tetap Expanded', () {
      final idx = sumber.indexOf('widget.konser.judul');
      final konteks = sumber.substring((idx - 200).clamp(0, idx), idx);
      expect(konteks.contains('Expanded('), isTrue);
    });
  });

  group('Baris teks + tombol', () {
    test('gate scanner: teks petunjuk bisa mengecil', () {
      final sumber =
          File('lib/screens/admin/gate_scanner_screen.dart').readAsStringSync();
      final idx = sumber.indexOf("'Arahkan QR tiket ke kotak bidik'");
      final konteks = sumber.substring((idx - 400).clamp(0, idx), idx);
      expect(konteks.contains('Expanded('), isTrue,
          reason: 'dua IconButton di kanan bisa mendorong teks keluar layar');
    });

    test('checkout: judul seksi jumlah tiket dibungkus Flexible', () {
      final sumber = File('lib/screens/user/checkout_parts/checkout_steps.dart')
          .readAsStringSync();
      final jumlah = RegExp(r"Flexible\(child: _sectionTitle\('Jumlah Tiket'\)\)")
          .allMatches(sumber)
          .length;
      expect(jumlah, 2,
          reason: 'ada dua baris "Jumlah Tiket" (pemesanan baru & lanjutan)');
    });

    test('checkout: label konfirmasi bisa mengecil', () {
      final sumber = File('lib/screens/user/checkout_parts/checkout_steps.dart')
          .readAsStringSync();
      final idx = sumber.indexOf('child: Row(\n        mainAxisAlignment: MainAxisAlignment.spaceBetween,\n        children: [\n          Flexible(');
      expect(idx, greaterThan(-1),
          reason: 'label kiri tanpa Flexible akan meluber saat teks panjang');
    });
  });

  group('Komponen bersama', () {
    test('AppLoadingRow: label dibungkus Flexible', () {
      final sumber =
          File('lib/widgets/feedback/app_state_views.dart').readAsStringSync();
      final idx = sumber.indexOf('class AppLoadingRow');
      final blok = sumber.substring(idx);
      expect(blok.contains('Flexible(\n              child: Text('), isTrue);
    });
  });

  group('Pola berbahaya yang sudah bersih', () {
    test('tidak ada Wrap sebagai anak langsung Row tanpa pelindung', () {
      // Pemeriksaan kasar tapi berguna: setiap kemunculan `children: [` yang
      // berisi `Wrap(` harus punya Flexible/Expanded di depannya.
      for (final berkas in [
        'lib/screens/admin/inspect_konser_screen.dart',
        'lib/screens/user/user_konser_detail_screen.dart',
      ]) {
        final s = File(berkas).readAsStringSync();
        for (final m in RegExp(r'Row\(').allMatches(s)) {
          final blok = s.substring(m.start, (m.start + 900).clamp(0, s.length));
          if (!blok.contains('Wrap(')) continue;
          // Kalau ada Wrap di dalam Row, harus ada pelindung di blok itu.
          final aman = blok.contains('Flexible(') || blok.contains('Expanded(');
          expect(aman, isTrue,
              reason: '$berkas: Wrap di dalam Row tanpa Flexible/Expanded');
        }
      }
    });
  });
}
