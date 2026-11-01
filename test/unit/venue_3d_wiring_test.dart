import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard struktural untuk fitur panggung 3D.
///
/// Yang dijaga di sini bukan tampilan, tapi **aturan yang mudah rusak
/// diam-diam**: kredit CC-BY yang wajib tampil, poster yang wajib ada, dan
/// keputusan untuk tidak lagi memakai WebView.
void main() {
  String baca(String p) => File(p).readAsStringSync();

  /// Membuang baris komentar sebelum memeriksa isi berkas.
  ///
  /// Dokumentasi sering menyebut nama API ("WebView", "AppColors.card")
  /// sehingga tes gagal padahal kodenya benar.
  String tanpaKomentar(String s) => s
      .split('\n')
      .where((baris) {
        final t = baris.trimLeft();
        return !t.startsWith('//') && !t.startsWith('///');
      })
      .join('\n');

  group('Penampil panggung 3D', () {
    test('TIDAK memakai WebView lagi', () {
      final kode = tanpaKomentar(baca('lib/widgets/media/venue_viewer.dart'));
      // Di perangkat uji, halaman WebView termuat tetapi JavaScript tidak
      // pernah dieksekusi. Mesin render berbasis WebView tidak bisa
      // diandalkan di sana, jadi pendekatan itu ditinggalkan.
      expect(kode.contains('ModelViewer'), isFalse,
          reason: 'WebView terbukti tidak menjalankan skrip di perangkat uji');
      expect(kode.contains('model_viewer_plus'), isFalse);
      expect(kode.contains('VenueStage3D'), isTrue,
          reason: 'Panggung harus digambar dengan Canvas Flutter');
    });

    test('renderer 3D memakai CustomPainter, bukan WebGL', () {
      final kode = tanpaKomentar(baca('lib/widgets/media/venue_stage_3d.dart'));
      expect(kode.contains('CustomPainter'), isTrue);
      expect(kode.contains('proyeksi'), isTrue,
          reason: 'Proyeksi 3D dihitung sendiri, tidak bergantung WebGL');
    });

    test('panggung bisa diputar dan di-zoom dengan jari', () {
      final kode = tanpaKomentar(baca('lib/widgets/media/venue_stage_3d.dart'));
      expect(kode.contains('onScaleUpdate'), isTrue,
          reason: 'Geser satu jari memutar, cubit dua jari zoom');
      expect(kode.contains('_yaw'), isTrue);
      expect(kode.contains('_jarak'), isTrue);
    });

    test('poster model ditampilkan', () {
      final kode = tanpaKomentar(baca('lib/widgets/media/venue_viewer.dart'));
      expect(kode.contains('model.posterRef'), isTrue,
          reason: 'Pengunjung harus melihat bentuk venue yang sebenarnya, '
              'bukan hanya siluet');
      expect(kode.contains('errorBuilder'), isTrue,
          reason: 'Poster yang gagal dimuat tidak boleh jadi kotak kosong');
    });

    test('kredit CC-BY dirender', () {
      final s = baca('lib/widgets/media/venue_viewer.dart');
      expect(s.contains('kredit'), isTrue,
          reason: 'CC-BY mewajibkan atribusi terlihat di aplikasi');
    });

    test('layar penuh sudah dihapus', () {
      // Layar penuh sempat ada, tetapi panggung di sana tergambar di bagian
      // atas dan tidak bisa dipindahkan — lebih buruk daripada di kartu.
      // Putaran 360° sekarang dilakukan langsung di kartu, jadi layar
      // terpisah tidak lagi memberi nilai tambah.
      expect(
        File('lib/screens/user/venue_fullscreen_screen.dart').existsSync(),
        isFalse,
        reason: 'Berkas layar penuh harus sudah dihapus',
      );
      final kode = tanpaKomentar(baca('lib/widgets/media/venue_viewer.dart'));
      expect(kode.contains('VenueFullscreenScreen'), isFalse,
          reason: 'Tidak boleh ada navigasi ke layar penuh lagi');
      expect(kode.contains('Layar penuh'), isFalse);
    });

    test('putaran 360 derajat bebas, tanpa batas yaw', () {
      final kode = tanpaKomentar(baca('lib/widgets/media/venue_stage_3d.dart'));
      // _yaw harus dimodulo 360 (bebas berputar), bukan di-clamp.
      expect(kode.contains('_yaw = (_yaw + geserYaw) % 360'), isTrue,
          reason: 'Yaw harus bebas 360°, bukan dibatasi');
      expect(kode.contains('_yaw + geserYaw).clamp'), isFalse,
          reason: 'Yaw tidak boleh di-clamp — itu yang membuat putaran '
              'mentok dan tidak bisa sampai 360°');
    });

    test('geseran punya momentum, bukan berhenti mendadak', () {
      final kode = tanpaKomentar(baca('lib/widgets/media/venue_stage_3d.dart'));
      expect(kode.contains('_mulaiMomentum'), isTrue,
          reason: 'Tanpa momentum, satu geseran pendek langsung berhenti '
              'dan terasa kaku di layar sentuh');
      expect(kode.contains('onScaleEnd'), isTrue);
      expect(kode.contains('_kecepatanYaw'), isTrue);
    });
  });

  group('Pustaka model', () {
    test('setiap model punya poster yang benar-benar ada', () {
      final s = baca('lib/core/media/venue_model_library.dart');
      final poster = RegExp(r"posterRef: '([^']+)'")
          .allMatches(s)
          .map((m) => m.group(1)!)
          .toList();
      expect(poster, isNotEmpty);
      for (final p in poster) {
        expect(File(p).existsSync(), isTrue,
            reason: 'Poster tidak ditemukan: $p');
      }
    });

    test('setelan kamera disimpan per model', () {
      final s = baca('lib/core/media/venue_model_library.dart');
      expect(s.contains('cameraOrbit'), isTrue);
      expect(s.contains('exposure'), isTrue);
      final jumlah = RegExp(r'cameraOrbit:').allMatches(s).length;
      expect(jumlah, greaterThanOrEqualTo(2),
          reason: 'Setiap model harus membawa setelan kamera sendiri');
    });
  });

  group('Pemilih model di form admin', () {
    test('hanya mengubah bagian venue, tidak menghapus audio/video', () {
      final s = baca('lib/widgets/media/venue_model_picker_field.dart');
      expect(s.contains('withVenue'), isTrue,
          reason: 'Membangun EventMedia baru akan menghapus audio dan video '
              'yang sudah diisi admin');
    });

    test('pilihan bisa dilepas', () {
      final s = baca('lib/widgets/media/venue_model_picker_field.dart');
      expect(s.contains('_pilih(null)') || s.contains('_pilih(dipilih ? null'),
          isTrue);
    });
  });

  group('Pemasangan di layar', () {
    test('detail konser merender seksi venue', () {
      final s = baca('lib/screens/user/user_konser_detail_screen.dart');
      expect(s.contains('_seksiVenue()'), isTrue);
      expect(s.contains('VenueViewer'), isTrue);
    });

    test('detail konser tidak menampilkan model yang tak dikenal pustaka', () {
      final s = baca('lib/screens/user/user_konser_detail_screen.dart');
      expect(s.contains('VenueModelLibrary.byRef'), isTrue,
          reason: 'Ref usang di Firestore tidak boleh dirender mentah');
    });

    test('form admin memasang pemilih model', () {
      final s = baca('lib/screens/admin/form_konser_screen.dart');
      expect(s.contains('VenueModelPickerField'), isTrue);
    });
  });

  group('Aset', () {
    test('folder aset terdaftar di pubspec', () {
      final s = baca('pubspec.yaml');
      expect(s.contains('assets/models/'), isTrue);
      expect(s.contains('assets/images/panggung/'), isTrue,
          reason: 'Poster panggung harus ikut masuk APK');
    });

    test('tidak ada berkas uji yang tertinggal di folder model', () {
      final berkas = Directory('assets/models').listSync();
      for (final f in berkas) {
        final nama = f.path.toLowerCase();
        expect(nama.endsWith('.glb'), isTrue,
            reason: 'Hanya berkas .glb yang boleh ada di assets/models — '
                'berkas uji HTML/JS sempat ikut masuk APK: ${f.path}');
      }
    });
  });
}
