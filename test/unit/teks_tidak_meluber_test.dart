import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Penjaga teks yang bisa meluber.
///
/// **Kenapa ini ada:** dari 642 `Text(` di aplikasi, hanya 63 yang punya
/// `maxLines`. Angka itu terlihat buruk, tapi sebagian besar sisanya adalah
/// label pendek statis (`'Total'`, `'Email'`, `'Batal'`) yang tidak mungkin
/// meluber.
///
/// Yang benar-benar berbahaya adalah pola sempit ini:
///
/// ```dart
/// Row(children: [
///   Text(user.nama),        // ← panjangnya tidak diketahui
///   Spacer(),
///   Text('Rp 500.000'),
/// ])
/// ```
///
/// Di dalam `Row`, `Text` tanpa `maxLines`/`Flexible` **tidak boleh**
/// melebihi lebar yang tersedia. Kalau isinya nama konser atau email yang
/// panjang, seluruh baris meluber dan muncul garis kuning-hitam.
///
/// Tes ini menolak pola tersebut, kecuali teksnya literal pendek yang sudah
/// diketahui aman.
void main() {
  late List<({String berkas, int baris, String isi})> pelanggaran;

  setUpAll(() {
    pelanggaran = [];
    final berkasDart = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final f in berkasDart) {
      final isi = f.readAsStringSync();
      final baris = isi.split('\n');

      for (var i = 0; i < baris.length; i++) {
        final t = baris[i].trim();
        if (t.startsWith('//')) continue;
        if (!t.contains('Text(')) continue;

        // Jendela beberapa baris ke depan: properti Text bisa ditulis
        // multi-baris.
        final jendela = baris
            .sublist(i, (i + 6).clamp(0, baris.length))
            .join(' ');

        if (jendela.contains('maxLines') || jendela.contains('overflow')) {
          continue;
        }

        // Hanya peduli pada Text yang menampilkan DATA, bukan literal.
        // Data = ada interpolasi `$` atau pemanggilan field/Getter.
        final argumen = jendela.substring(
          jendela.indexOf('Text(') + 5,
          jendela.length.clamp(0, 200),
        );
        final menampilkanData = argumen.contains(r'$') ||
            RegExp(r'\b[a-z][A-Za-z0-9]*\.[a-zA-Z]').hasMatch(argumen);
        if (!menampilkanData) continue;

        // Harus berada di dalam Row tanpa Expanded/Flexible di sekitarnya.
        final sebelum = baris
            .sublist((i - 8).clamp(0, i), i)
            .join('\n');
        if (!sebelum.contains('Row(')) continue;
        if (sebelum.contains('Expanded(') || sebelum.contains('Flexible(')) {
          continue;
        }

        pelanggaran.add((berkas: f.path, baris: i + 1, isi: t));
      }
    }
  });

  test('tidak ada Text berisi data di dalam Row tanpa maxLines', () {
    final daftar = pelanggaran
        .map((p) => '${p.berkas}:${p.baris}  ${p.isi}')
        .toList();

    expect(daftar, isEmpty,
        reason: 'Teks ini bisa meluber di layar sempit. Tambahkan '
            'maxLines + overflow, atau bungkus dengan Expanded/Flexible.\n'
            '${daftar.join('\n')}');
  });

  test('halaman detail tiket & konser membatasi judul panjang', () {
    // Dua layar ini menampilkan nama konser dan nama pembeli — data yang
    // panjangnya tidak kita kendalikan.
    for (final p in <String>[
      'lib/screens/user/user_tiket_screen.dart',
      'lib/screens/user/user_konser_detail_screen.dart',
    ]) {
      final isi = File(p).readAsStringSync();
      expect(isi.contains('maxLines'), isTrue,
          reason: '$p harus membatasi baris teks');
      expect(isi.contains('TextOverflow'), isTrue,
          reason: '$p harus memakai ellipsis untuk teks yang dipotong');
    }
  });
}
