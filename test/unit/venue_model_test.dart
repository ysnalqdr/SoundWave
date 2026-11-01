import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/core/media/venue_model_library.dart';

/// Mengunci aturan-aturan yang mudah rusak diam-diam saat model baru
/// ditambahkan: berkas benar-benar ada, kredit lisensi lengkap, dan
/// ukurannya masih wajar untuk sebuah APK.
void main() {
  group('Pustaka model venue 3D', () {
    test('setiap model menunjuk berkas yang benar-benar ada', () {
      expect(VenueModelLibrary.models, isNotEmpty);
      for (final m in VenueModelLibrary.models) {
        final f = File(m.ref);
        expect(
          f.existsSync(),
          isTrue,
          reason: 'Berkas model tidak ditemukan: ${m.ref}',
        );
      }
    });

    test('setiap berkas model berformat .glb', () {
      for (final m in VenueModelLibrary.models) {
        expect(
          m.ref.toLowerCase().endsWith('.glb'),
          isTrue,
          reason: 'Hanya GLB yang didukung model_viewer: ${m.ref}',
        );
      }
    });

    test('setiap model mencantumkan pembuat, lisensi, dan sumber', () {
      for (final m in VenueModelLibrary.models) {
        expect(m.pembuat.trim(), isNotEmpty,
            reason: 'CC-BY mewajibkan nama pembuat: ${m.ref}');
        expect(m.lisensi.trim(), isNotEmpty,
            reason: 'Jenis lisensi wajib jelas: ${m.ref}');
        expect(m.sumber.trim(), isNotEmpty,
            reason: 'Sumber wajib ada untuk penelusuran: ${m.ref}');
        expect(m.judulAsli.trim(), isNotEmpty,
            reason: 'Judul asli dipakai di baris kredit: ${m.ref}');
      }
    });

    test('kredit memuat nama pembuat', () {
      // Teks yang tampil sengaja diringkas jadi "by <pembuat>" agar tidak
      // terasa seperti tempelan. Jenis lisensi & tautan sumber tetap
      // disimpan di data model untuk keperluan catatan dan atribusi.
      for (final m in VenueModelLibrary.models) {
        expect(m.kredit, contains(m.pembuat));
        expect(m.kredit, startsWith('by '));
      }
    });

    test('lisensi dan sumber tetap tercatat di data', () {
      // CC-BY mewajibkan atribusi; menyimpan lisensi & tautan sumber di data
      // membuat kewajiban itu tetap bisa dipenuhi (mis. saat kredit diketuk
      // atau di halaman kredit aplikasi).
      for (final m in VenueModelLibrary.models) {
        expect(m.lisensi.trim(), isNotEmpty);
        expect(m.sumber.trim(), isNotEmpty);
      }
    });

    test('lisensi hanya CC-BY atau CC0', () {
      for (final m in VenueModelLibrary.models) {
        final l = m.lisensi.toUpperCase();
        final sah = l.contains('CC BY') ||
            l.contains('CC-BY') ||
            l.contains('CC0') ||
            l.contains('PUBLIC DOMAIN');
        expect(sah, isTrue,
            reason: 'Lisensi di luar CC-BY/CC0 tidak boleh dipakai: '
                '${m.lisensi} (${m.ref})');
      }
    });

    test('tidak ada model yang lebih besar dari 8 MB', () {
      for (final m in VenueModelLibrary.models) {
        final f = File(m.ref);
        final mb = f.lengthSync() / (1024 * 1024);
        expect(mb, lessThan(8.0),
            reason: 'Model ${m.ref} berukuran ${mb.toStringAsFixed(1)} MB, '
                'melebihi batas 8 MB untuk aplikasi seluler');
      }
    });

    test('ukuranMb di pustaka cocok dengan berkas di disk', () {
      for (final m in VenueModelLibrary.models) {
        final f = File(m.ref);
        final mb = f.lengthSync() / (1024 * 1024);
        // Toleransi 0.5 MB: angka di pustaka dibulatkan untuk ditampilkan.
        expect((mb - m.ukuranMb).abs(), lessThan(0.5),
            reason: 'Angka ukuranMb (${m.ukuranMb}) tidak cocok dengan '
                'berkas sebenarnya (${mb.toStringAsFixed(2)} MB)');
      }
    });

    test('setiap ref unik', () {
      final refs = VenueModelLibrary.models.map((m) => m.ref).toList();
      expect(refs.toSet().length, refs.length);
    });
  });

  group('VenueModelLibrary.byRef', () {
    test('mengembalikan model yang cocok', () {
      final m = VenueModelLibrary.models.first;
      expect(VenueModelLibrary.byRef(m.ref)?.ref, m.ref);
    });

    test('null untuk ref yang tidak dikenal', () {
      expect(VenueModelLibrary.byRef('assets/models/tidak_ada.glb'), isNull);
      expect(VenueModelLibrary.byRef(''), isNull);
      expect(VenueModelLibrary.byRef(null), isNull);
    });
  });
}
