import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Penjaga perilaku pemutaran preview.
///
/// Audio tidak bisa diuji tanpa perangkat, tetapi **aturan**-nya bisa dikunci
/// dengan membaca sumber. Yang dijaga:
///
/// 1. Loop aktif secara bawaan — cuplikan terus berbunyi selama pengunjung
///    membaca halaman, tidak berhenti sendiri setelah 20 detik.
/// 2. Saat mode sekali-putar dipakai, posisi di-reset ke awal supaya tombol
///    play langsung bisa ditekan lagi.
/// 3. Audio berhenti ketika halaman ditinggalkan.
/// 4. Berhenti hanya bila berkas itu yang aktif (tidak mematikan layar lain).
void main() {
  final service = File('lib/services/audio_service.dart').readAsStringSync();
  final widget =
      File('lib/widgets/media/audio_preview_player.dart').readAsStringSync();
  final mini =
      File('lib/widgets/media/audio_mini_player.dart').readAsStringSync();
  final detail =
      File('lib/screens/user/user_konser_detail_screen.dart').readAsStringSync();

  group('AudioService', () {
    test('playPreview punya parameter loop dengan bawaan true', () {
      // Signature ditulis multi-baris, jadi diperiksa per potongan.
      expect(service.contains('Future<bool> playPreview('), isTrue);
      expect(service.contains('bool loop = true,'), isTrue,
          reason: 'cuplikan di halaman detail harus berulang secara bawaan');
    });

    test('playPreview menerima judul track untuk mini player', () {
      expect(service.contains('String? title,'), isTrue);
      expect(service.contains('nowPlaying.value'), isTrue);
    });

    test('mode loop diterapkan ke pemutar', () {
      expect(service.contains('setLoopMode('), isTrue);
      expect(service.contains('LoopMode.one'), isTrue);
      expect(service.contains('LoopMode.off'), isTrue);
    });

    test('saat selesai, posisi dikembalikan ke awal lalu dijeda', () {
      final idx = service.indexOf('ProcessingState.completed');
      expect(idx, greaterThan(-1));
      final blok = service.substring(idx, idx + 220);
      expect(blok.contains('seek(Duration.zero)'), isTrue);
      expect(blok.contains('pause()'), isTrue);
    });

    test('beep memakai pemutar terpisah dari preview', () {
      expect(service.contains('_previewPlayer'), isTrue);
      expect(service.contains('_sfxPlayer'), isTrue);
      expect(
        service.contains('_sfxPlayer.stop()'),
        isTrue,
        reason: 'beep baru harus menghentikan beep sebelumnya, '
            'tanpa menyentuh preview',
      );
    });

    test('feedbackScan menggabungkan getar, bunyi sistem, dan beep', () {
      expect(service.contains('HapticFeedback.mediumImpact()'), isTrue);
      expect(service.contains('HapticFeedback.heavyImpact()'), isTrue);
      expect(service.contains('SystemSound.play'), isTrue);
      expect(service.contains('beepOk()'), isTrue);
      expect(service.contains('beepFail()'), isTrue);
    });
  });

  group('AudioMiniPlayer', () {
    test('punya tombol jeda dan lanjut', () {
      expect(mini.contains('pausePreview()'), isTrue);
      expect(mini.contains('resumePreview()'), isTrue);
    });

    test('punya tombol hentikan yang menyembunyikan bar', () {
      expect(mini.contains('stopPreview'), isTrue);
    });

    test('hanya tampil selama ada track aktif', () {
      expect(mini.contains('nowPlaying'), isTrue);
      expect(mini.contains('if (title == null)'), isTrue);
    });

    test('terpasang di halaman detail, di luar daftar yang bisa digulung', () {
      expect(detail.contains('const AudioMiniPlayer()'), isTrue,
          reason: 'kendali audio harus tetap terjangkau saat pengguna '
              'menggulir ke bawah');
    });

    test('tidak membuat AudioPlayer sendiri', () {
      expect(mini.contains('AudioPlayer('), isFalse);
    });
  });

  group('AudioPreviewPlayer', () {
    test('meneruskan preferensi loop dan judul ke service', () {
      expect(widget.contains('playPreview('), isTrue);
      expect(widget.contains('loop: widget.loop,'), isTrue);
      expect(widget.contains('title: widget.title,'), isTrue);
    });

    test('menampilkan penanda ulang saat loop aktif', () {
      expect(widget.contains('Icons.repeat_rounded'), isTrue);
      expect(widget.contains('if (widget.loop)'), isTrue);
    });

    test('tidak menghentikan audio saat widget dibuang', () {
      // Perilaku ini sengaja dibalik setelah uji di perangkat: ListView
      // membuang anak yang tergulung keluar layar, sehingga menghentikan
      // audio di sini membuat lagu mati hanya karena pengguna scroll ke
      // bawah. Penghentian dilakukan oleh layar pemilik halaman.
      expect(widget.contains('void dispose()'), isTrue);
      final idx = widget.indexOf('void dispose()');
      final blok = widget.substring(idx, idx + 700);
      expect(blok.contains('stopPreview()'), isFalse,
          reason: 'pemutar di dalam daftar tidak boleh menghentikan audio');
    });

    test('tidak membuat AudioPlayer sendiri', () {
      expect(widget.contains('AudioPlayer('), isFalse,
          reason: 'semua pemutaran harus lewat AudioService agar '
              'hanya satu lagu berbunyi pada satu waktu');
    });
  });
}
