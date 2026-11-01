import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

/// Penjaga blok A–D: keamanan, performa, ketahanan, aksesibilitas.
///
/// Setiap tes di sini mewakili satu temuan audit yang sudah diperbaiki. Kalau
/// salah satunya kembali ke bentuk lama, tes ini gagal — supaya perbaikannya
/// tidak hilang diam-diam saat kode disentuh lagi.
void main() {
  // Membuang komentar supaya pemeriksaan teks tidak tertipu oleh dokumentasi
  // yang sengaja mengutip pola lama sebagai penjelasan.
  String tanpaKomentar(String isi) {
    final hasil = <String>[];
    for (final b in isi.split('\n')) {
      if (!b.trimLeft().startsWith('//')) hasil.add(b);
    }
    return hasil.join('\n');
  }

  group('A. Keamanan', () {
    test('kode booking tidak bisa bertabrakan', () {
      // Dulu: potong timestamp saja — dua pesanan pada milidetik sama
      // menghasilkan kode identik. Karena kodeBooking dipakai sebagai
      // order_id Midtrans, tabrakan berarti dua pesanan bisa bertukar status
      // pembayaran.
      final isi = tanpaKomentar(
          File('lib/services/database_service.dart').readAsStringSync());

      expect(isi.contains('.substring(5)'), isFalse,
          reason: 'pola lama (potong timestamp) masih ada di kode');
      expect(isi.contains('Random.secure()'), isTrue,
          reason: 'kode booking harus memakai keacakan kriptografis');
      expect(isi.contains("const abjad = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ'"),
          isTrue,
          reason: 'abjad tanpa I/O/0/1 supaya tidak salah dibaca petugas');
    });

    test('kode booking punya bentuk yang diharapkan dan tidak berulang', () {
      // Simulasi fungsi yang sama seperti di service, untuk membuktikan
      // keunikannya — bukan sekadar memeriksa teks sumber.
      String buat() {
        const abjad = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
        final rnd = Random.secure();
        final acak =
            List.generate(4, (_) => abjad[rnd.nextInt(abjad.length)]).join();
        return 'SW-${DateTime.now().millisecondsSinceEpoch}-$acak';
      }

      final hasil = <String>{};
      for (var i = 0; i < 2000; i++) {
        hasil.add(buat());
      }
      expect(hasil.length, greaterThan(1990),
          reason: 'terlalu banyak tabrakan: ${2000 - hasil.length} dari 2000');

      final contoh = buat();
      expect(RegExp(r'^SW-\d{13}-[2-9A-HJ-NP-Z]{4}$').hasMatch(contoh), isTrue,
          reason: 'format tak sesuai: $contoh');
    });

    test('refunds tidak bisa dibuat pembeli', () {
      final r = File('firestore.rules').readAsStringSync();
      final i = r.indexOf('match /refunds/');
      expect(i, greaterThan(0));
      final blok = r.substring(i, i + 900);

      expect(blok.contains('allow create: if isAdmin()'), isTrue,
          reason: 'pembeli tidak boleh membuat dokumen refund — dulu bisa, '
              'dan tanpa validasi field sama sekali');
      expect(blok.contains('request.resource.data.totalHarga is number'),
          isTrue,
          reason: 'nominal refund harus divalidasi tipenya');
      expect(blok.contains('request.resource.data.jumlahTiket is int'), isTrue);
    });

    test('webhook memakai perbandingan signature constant-time', () {
      final f = File('functions/index.js').readAsStringSync();
      expect(f.contains('crypto.timingSafeEqual'), isTrue,
          reason: 'perbandingan === membocorkan panjang awalan yang benar');
      expect(f.contains('function signatureSama('), isTrue);
      expect(f.contains('signatureKey !== calculatedSignature'), isFalse,
          reason: 'perbandingan lama masih ada');
    });

    test('webhook mencocokkan nominal dengan pesanan', () {
      final f = File('functions/index.js').readAsStringSync();
      expect(f.contains('Nominal webhook tidak cocok'), isTrue,
          reason: 'tanpa ini, notifikasi sah untuk nominal lain bisa dipakai '
              'menandai pesanan mahal lunas');
    });

    test('IP allowlist TIDAK dipakai (sesuai anjuran Midtrans)', () {
      final f = File('functions/index.js').readAsStringSync();
      expect(f.contains('recommend relying on IP whitelisting'), isTrue,
          reason: 'alasan tidak memakai IP allowlist harus tercatat');
    });

    test('tickets tetap boleh dibaca publik — itu katalog, bukan data pribadi',
        () {
      // Koreksi audit: dokumen tickets berisi kategori/harga/stok, bukan nama
      // atau email. Menguncinya akan memutus halaman detail konser bagi
      // pengunjung yang belum login, tanpa menambah keamanan apa pun.
      final r = File('firestore.rules').readAsStringSync();
      final i = r.indexOf('match /tickets/');
      final blok = r.substring(i, i + 1400);
      expect(blok.contains('allow read: if true'), isTrue);
      expect(blok.contains('allow create, update, delete: if isAdmin()'), isTrue,
          reason: 'tulis stok hanya lewat admin/functions');
    });
  });

  group('B. Performa', () {
    test('gambar memakai cache disk, bukan Image.network', () {
      final g = tanpaKomentar(
          File('lib/widgets/gambar_widget.dart').readAsStringSync());
      expect(g.contains('CachedNetworkImage'), isTrue,
          reason: 'Image.network mengunduh ulang setiap kali digulir balik');
      expect(g.contains('Image.network'), isFalse,
          reason: 'masih memakai Image.network di kode');
      expect(g.contains('memCacheWidth'), isTrue,
          reason: 'tanpa ini, thumbnail 56px menyimpan gambar 2000px');
    });

    test('cached_network_image memang terdaftar di pubspec', () {
      final p = File('pubspec.yaml').readAsStringSync();
      expect(p.contains('cached_network_image'), isTrue);
    });
  });

  group('C. Ketahanan', () {
    test('ada penangkap galat global dan dipasang sebelum runApp', () {
      final m = File('lib/main.dart').readAsStringSync();
      expect(m.contains('PenangkapGalat.pasang()'), isTrue,
          reason: 'tanpa ini, galat hilang tanpa jejak di mode rilis');
      expect(m.contains('ErrorWidget.builder'), isTrue,
          reason: 'kotak merah bawaan tidak berguna bagi pengguna');
      expect(m.contains('PenangkapGalat.jalankan'), isTrue,
          reason: 'galat async di luar framework juga harus tertangkap');

      // Harus dipasang SEBELUM Firebase.initializeApp — kalau init gagal,
      // galatnya tetap tercatat.
      final iP = m.indexOf('PenangkapGalat.pasang()');
      final iF = m.indexOf('Firebase.initializeApp');
      expect(iP, lessThan(iF),
          reason: 'penangkap harus dipasang sebelum apa pun yang bisa gagal');
    });

    test('penangkap membatasi jumlah catatan', () {
      final p =
          File('lib/core/diagnostik/penangkap_galat.dart').readAsStringSync();
      expect(p.contains('_catatan.length > 50'), isTrue,
          reason: 'tanpa batas, catatan tumbuh terus dan memakan memori');
    });
  });

  group('D. Aksesibilitas', () {
    test('setiap IconButton punya tooltip', () {
      // 23 tombol ikon sebelumnya tidak punya label, jadi pembaca layar
      // membacanya sebagai "tombol" tanpa keterangan.
      final pelanggaran = <String>[];

      String blok(String s, int i) {
        var d = 0;
        for (var j = i; j < s.length; j++) {
          if (s[j] == '(') d++;
          if (s[j] == ')') {
            d--;
            if (d == 0) return s.substring(i, j + 1);
          }
        }
        return s.substring(i);
      }

      for (final e in Directory('lib').listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('.dart')) continue;
        final s = e.readAsStringSync();
        for (final m in RegExp(r'IconButton\(').allMatches(s)) {
          final b = blok(s, m.end - 1);
          if (!b.contains('tooltip')) {
            final baris = s.substring(0, m.start).split('\n').length;
            pelanggaran.add('${e.path}:$baris');
          }
        }
      }

      expect(pelanggaran, isEmpty,
          reason: 'IconButton tanpa tooltip:\n${pelanggaran.join('\n')}');
    });

    test('teks judul di kartu dibatasi jumlah barisnya', () {
      // Judul konser datang dari data admin dan bisa sangat panjang. Tanpa
      // batas, ia mendorong tata letak dan bisa meluber di layar sempit.
      final berkas = <String>[
        'lib/screens/user/user_explore_screen.dart',
        'lib/screens/user/user_favorit_screen.dart',
        'lib/screens/user/user_tiket_screen.dart',
      ];
      for (final p in berkas) {
        final isi = File(p).readAsStringSync();
        expect(isi.contains('TextOverflow.ellipsis'), isTrue,
            reason: '$p belum membatasi teks panjang');
      }
    });

    test('kode booking yang lebih panjang tidak mendorong tata letak', () {
      // Kode booking naik dari 15 ke 21 karakter. Setiap tempat yang
      // menampilkannya harus punya batas baris.
      final t = tanpaKomentar(
          File('lib/screens/user/user_tiket_screen.dart').readAsStringSync());

      final pola = RegExp(r'Text\(\s*tiket\.kodeBooking');
      var jumlah = 0;
      for (final m in pola.allMatches(t)) {
        jumlah++;
        final akhir = (m.start + 320).clamp(0, t.length);
        final sekitar = t.substring(m.start, akhir);
        expect(
          sekitar.contains('maxLines') || sekitar.contains('Flexible'),
          isTrue,
          reason: 'teks kode booking tanpa batas di dekat: '
              '${t.substring(m.start, (m.start + 60).clamp(0, t.length))}',
        );
      }
      expect(jumlah, greaterThan(0), reason: 'pola pemeriksaan tidak cocok');
    });
  });
}
