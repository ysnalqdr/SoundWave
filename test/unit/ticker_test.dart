import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ============================================================================
/// PENJAGA TICKER
/// ============================================================================
///
/// `SingleTickerProviderStateMixin` hanya boleh melayani **satu**
/// `AnimationController`/`TabController`. Kalau sebuah State membuat
/// controller kedua, Flutter melempar:
///
///   _SplashScreenState uses a SingleTickerProviderStateMixin but multiple
///   tickers were created
///
/// dan — karena splash adalah layar pertama — aplikasi **gagal total begitu
/// dibuka**. Ini persis yang terjadi saat equalizer splash ditambahkan: satu
/// controller baru dibuat, mixin tidak ikut diganti.
///
/// Bug ini lolos dari `flutter analyze` (0 error) dan dari seluruh tes unit,
/// karena hanya muncul saat runtime. Karena itu diperiksa dengan membaca
/// sumber: hitung controller per berkas, bandingkan dengan mixin yang dipakai.
void main() {
  /// Daftar berkas .dart di lib/ yang memakai SingleTickerProviderStateMixin.
  List<File> berkasSingleTicker() {
    final hasil = <File>[];
    for (final e in Directory('lib').listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      final isi = e.readAsStringSync();
      // Cari pemakaian sebagai mixin (`with X {`), bukan penyebutan di
      // komentar — komentar penjelasan tidak menciptakan ticker.
      final regex = RegExp(r'with\s+SingleTickerProviderStateMixin\b');
      if (regex.hasMatch(isi)) hasil.add(e);
    }
    return hasil;
  }

  /// Hitung controller yang benar-benar dibuat, bukan yang disebut di komentar.
  int hitungController(String isi) {
    final tanpaKomentar = isi
        .split('\n')
        .where((b) => !b.trimLeft().startsWith('//'))
        .join('\n');
    final anim = RegExp(r'AnimationController\(').allMatches(tanpaKomentar).length;
    final tab = RegExp(r'TabController\(').allMatches(tanpaKomentar).length;
    return anim + tab;
  }

  group('SingleTickerProviderStateMixin hanya untuk satu controller', () {
    test('tidak ada State dengan >1 controller memakai mixin Single', () {
      final pelanggaran = <String>[];

      for (final f in berkasSingleTicker()) {
        final isi = f.readAsStringSync();
        final jumlah = hitungController(isi);
        if (jumlah > 1) {
          pelanggaran.add('${f.path} membuat $jumlah controller');
        }
      }

      expect(
        pelanggaran,
        isEmpty,
        reason: 'State dengan lebih dari satu AnimationController/TabController '
            'wajib memakai TickerProviderStateMixin. Kalau tidak, aplikasi '
            'crash saat layar itu dibuka:\n${pelanggaran.join('\n')}',
      );
    });

    test('splash memakai TickerProviderStateMixin (dua controller)', () {
      final isi = File('lib/screens/splash_screen.dart').readAsStringSync();
      expect(hitungController(isi), greaterThan(1),
          reason: 'splash punya controller fade + controller equalizer');
      expect(
        isi,
        contains('with TickerProviderStateMixin'),
        reason: 'Tanpa ini, splash crash dan aplikasi tidak bisa dibuka.',
      );
    });

    test('venue_stage_3d memakai TickerProviderStateMixin (dua controller)', () {
      final isi = File('lib/widgets/media/venue_stage_3d.dart').readAsStringSync();
      expect(hitungController(isi), greaterThan(1),
          reason: 'ada controller putaran otomatis + controller momentum');
      expect(isi, contains('with TickerProviderStateMixin'));
    });
  });

  group('setiap controller yang dibuat di-dispose', () {
    test('tidak ada AnimationController tanpa dispose', () {
      final pelanggaran = <String>[];

      for (final e in Directory('lib').listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('.dart')) continue;
        final isi = e.readAsStringSync();
        final tanpaKomentar = isi
            .split('\n')
            .where((b) => !b.trimLeft().startsWith('//'))
            .join('\n');

        final dibuat = RegExp(r'(\w+)\s*=\s*(?:AnimationController|TabController)\(')
            .allMatches(tanpaKomentar)
            .map((m) => m.group(1)!)
            .toSet();

        for (final nama in dibuat) {
          // Terima `x.dispose()` maupun `x?.dispose()` — controller yang
          // nullable memang di-dispose dengan `?.`.
          final sudah = tanpaKomentar.contains('$nama.dispose()') ||
              tanpaKomentar.contains('$nama?.dispose()');
          if (!sudah) {
            pelanggaran.add('${e.path}: $nama tidak di-dispose');
          }
        }
      }

      expect(pelanggaran, isEmpty,
          reason: 'Controller yang tidak di-dispose membocorkan ticker dan '
              'membuat animasi berjalan selamanya:\n${pelanggaran.join('\n')}');
    });
  });
}
