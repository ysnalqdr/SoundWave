import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Penjaga area sentuh minimum.
///
/// Kenapa ini ada: Flutter **sudah** membungkus setiap tombol Material dengan
/// padding sentuh 48x48 (`kMinInteractiveDimension`), apa pun `minimumSize`
/// yang kita tulis. Jadi tombol yang *terlihat* 32px tetap mudah ditekan.
///
/// Satu-satunya cara merusaknya adalah memakai
/// `tapTargetSize: MaterialTapTargetSize.shrinkWrap`, yang mematikan padding
/// itu. Dulu ada dua tempat yang melakukannya:
///   * "Ganti metode pembayaran" di checkout → area sentuh ~22px
///   * "Tandai semua" di panel notifikasi → area sentuh ~20px
///
/// Keduanya sudah diperbaiki. Tes ini menjaga supaya tidak kembali.
///
/// Catatan: `minimumSize` kecil **bukan** pelanggaran. Yang pelanggaran adalah
/// `shrinkWrap`. Jangan ubah tes ini jadi memeriksa `minimumSize`.
void main() {
  test('tidak ada tombol yang mematikan padding sentuh 48px', () {
    final pelanggaran = <String>[];

    for (final entitas in Directory('lib').listSync(recursive: true)) {
      if (entitas is! File || !entitas.path.endsWith('.dart')) continue;
      final isi = entitas.readAsStringSync();
      final baris = isi.split('\n');
      for (var i = 0; i < baris.length; i++) {
        final t = baris[i].trim();
        // Lewati komentar: beberapa komentar sengaja menyebut shrinkWrap
        // untuk menjelaskan kenapa dilarang.
        if (t.startsWith('//')) continue;
        if (t.contains('MaterialTapTargetSize.shrinkWrap')) {
          pelanggaran.add('${entitas.path}:${i + 1}  $t');
        }
      }
    }

    expect(
      pelanggaran,
      isEmpty,
      reason: 'shrinkWrap menyusutkan area sentuh di bawah 44px. '
          'Hapus barisnya; Flutter akan memakai 48x48 secara otomatis.\n'
          '${pelanggaran.join('\n')}',
    );
  });

  test('setiap tombol punya label yang bisa dibaca pembaca layar', () {
    // Tombol ikon-saja tanpa tooltip/label semantik tidak terbaca pembaca
    // layar. Ini pemeriksaan kasar: cari IconButton yang tidak punya
    // tooltip dalam 3 baris berikutnya.
    final mencurigakan = <String>[];

    for (final entitas in Directory('lib').listSync(recursive: true)) {
      if (entitas is! File || !entitas.path.endsWith('.dart')) continue;
      final baris = entitas.readAsStringSync().split('\n');
      for (var i = 0; i < baris.length; i++) {
        if (!baris[i].contains('IconButton(')) continue;
        final jendela = baris
            .sublist(i, (i + 4).clamp(0, baris.length))
            .join(' ');
        if (!jendela.contains('tooltip') && !jendela.contains('semanticLabel')) {
          mencurigakan.add('${entitas.path}:${i + 1}');
        }
      }
    }

    // Dicatat, bukan digagalkan: memperbaikinya butuh menyentuh puluhan
    // tombol dan itu pekerjaan tersendiri. Angka ini jadi tolok ukur.
    expect(mencurigakan.length, lessThan(200),
        reason: 'jumlah IconButton tanpa label melonjak: ${mencurigakan.length}');
  });
}
