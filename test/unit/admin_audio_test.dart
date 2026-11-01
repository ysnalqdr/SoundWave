import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Penjaga fitur "admin menambahkan lagu saat membuat konser".
///
/// Yang dikunci di sini bukan tampilan, melainkan **jalur data**: pilihan
/// audio di form harus benar-benar ikut tersimpan ke Firestore, dan pemutar
/// harus bisa memutar baik berkas bawaan maupun URL.
///
/// Kenapa perlu dijaga: kalau `media` lupa disertakan pada salah satu cabang
/// `_simpan()`, admin bisa memilih lagu, menekan Simpan, melihat snackbar
/// sukses — lalu audio tidak pernah muncul. Kegagalan senyap seperti ini tidak
/// terlihat dari UI.
void main() {
  final form = File('lib/screens/admin/form_konser_screen.dart')
      .readAsStringSync();
  final picker =
      File('lib/widgets/media/audio_picker_field.dart').readAsStringSync();
  final service = File('lib/services/audio_service.dart').readAsStringSync();
  final library =
      File('lib/core/media/audio_library.dart').readAsStringSync();
  final demo = File('lib/core/media/demo_media.dart').readAsStringSync();

  group('Form konser — menyimpan audio', () {
    test('cabang edit menyertakan media', () {
      final idx = form.indexOf('await db.updateEvent(');
      expect(idx, greaterThan(-1));
      final blok = form.substring(idx, idx + 700);
      expect(blok.contains("'media': _media.toMap()"), isTrue,
          reason: 'tanpa ini, audio yang dipilih admin hilang saat edit');
    });

    test('cabang buat baru menyertakan media', () {
      final idx = form.indexOf('final konserBaru = KonserModel(');
      expect(idx, greaterThan(-1));
      final blok = form.substring(idx, idx + 700);
      expect(blok.contains('media: _media,'), isTrue,
          reason: 'tanpa ini, konser baru tidak pernah punya audio');
    });

    test('media awal dibaca dari konser yang diedit', () {
      expect(form.contains('_media = k?.media ?? EventMedia.empty'), isTrue);
    });

    test('pemilih audio terpasang di form', () {
      expect(form.contains('AudioPickerField('), isTrue);
      expect(form.contains('onChanged: (m) => setState(() => _media = m)'),
          isTrue);
    });
  });

  group('AudioPickerField', () {
    test('menyediakan dua sumber: pustaka dan URL', () {
      expect(picker.contains("label: 'Pustaka'"), isTrue);
      expect(picker.contains("label: 'URL'"), isTrue);
    });

    test('memvalidasi skema URL sebelum diterapkan', () {
      expect(picker.contains('http://'), isTrue);
      expect(picker.contains('https://'), isTrue);
    });

    test('menolak URL tanpa ekstensi audio', () {
      expect(picker.contains("'.mp3'"), isTrue);
      expect(picker.contains('Berkas harus berformat'), isTrue);
    });

    test('tahan terhadap query string pada URL CDN', () {
      expect(picker.contains("split('?')"), isTrue,
          reason: 'CDN sering memakai lagu.mp3?token=abc');
    });

    test('bisa melepas pilihan audio (opsional)', () {
      // Dulu memakai `EventMedia.empty`, tapi itu menghapus video dan model 3D
      // yang sudah diisi. Sekarang melepas audio hanya mengosongkan bagian
      // audio saja.
      expect(picker.contains('withAudio()'), isTrue);
      expect(picker.contains('EventMedia.empty'), isFalse,
          reason: 'membangun EventMedia dari nol akan menghapus field lain');
    });

    test('memberi pratinjau sebelum disimpan', () {
      expect(picker.contains('AudioPreviewPlayer('), isTrue);
    });

    test('tidak mengunggah berkas — hanya path atau URL', () {
      expect(picker.contains('FirebaseStorage'), isFalse);
      expect(picker.contains('uploadBytes'), isFalse);
    });
  });

  group('AudioService — memutar aset maupun URL', () {
    test('membedakan URL jaringan dari path aset', () {
      expect(service.contains('_isRemote'), isTrue);
      expect(service.contains("startsWith('http://')"), isTrue);
      expect(service.contains("startsWith('https://')"), isTrue);
    });

    test('memakai setUrl untuk jaringan dan setAsset untuk lokal', () {
      expect(service.contains('setUrl(ref)'), isTrue);
      expect(service.contains('setAsset(ref)'), isTrue);
    });
  });

  group('Pustaka audio', () {
    test('berisi 5 track dengan durasi masuk akal', () {
      // Dihitung dari entri `ref:`, bukan dari nama kelas — deklarasi
      // konstruktor juga memuat teks 'AudioTrack('.
      final jumlah = RegExp(r"ref: 'assets/audio/").allMatches(library).length;
      expect(jumlah, 5);
      // Semua potongan bawaan seragam 20 detik. Sebelumnya preview_05
      // hanya 10 detik karena rentang yang dipilih user memang 10 detik.
      final durasi = RegExp(r'durationSec: (\d+)')
          .allMatches(library)
          .map((m) => int.parse(m.group(1)!))
          .toList();
      expect(durasi.length, 5);
      expect(durasi.every((d) => d == 20), isTrue);
    });

    test('setiap track menunjuk berkas yang benar-benar ada', () {
      for (final m in RegExp(r"ref: '(assets/audio/[^']+)'")
          .allMatches(library)) {
        final path = m.group(1)!;
        expect(File(path).existsSync(), isTrue,
            reason: '$path terdaftar di pustaka tapi tidak ada di disk');
      }
    });

    test('DemoMedia membaca pustaka, bukan daftar terpisah', () {
      expect(demo.contains('AudioLibrary.tracks'), isTrue);
      expect(demo.contains('_previewAssets'), isFalse,
          reason: 'dua daftar terpisah mudah melenceng satu sama lain');
    });

    test('data dari Firestore selalu menang atas cadangan', () {
      expect(demo.contains('if (media.hasAudio) return media;'), isTrue);
    });
  });
}
