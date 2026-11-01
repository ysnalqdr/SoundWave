import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/core/media/demo_media.dart';
import 'package:soundwave/models/event_media_model.dart';

/// Penjaga aset audio dan aturan cadangan demo.
///
/// Dua hal yang mudah rusak tanpa ketahuan:
/// 1. Berkas mp3 hilang atau ukurannya membengkak (APK ikut membengkak).
/// 2. Aturan "media dari database selalu menang" berubah, sehingga data asli
///    tertimpa contoh bawaan.
void main() {
  group('aset audio', () {
    const wajib = [
      'assets/audio/beep_ok.mp3',
      'assets/audio/beep_fail.mp3',
      'assets/audio/preview_01.mp3',
      'assets/audio/preview_02.mp3',
      'assets/audio/preview_03.mp3',
      'assets/audio/preview_04.mp3',
      'assets/audio/preview_05.mp3',
    ];

    test('semua berkas ada', () {
      for (final path in wajib) {
        expect(File(path).existsSync(), isTrue, reason: 'hilang: $path');
      }
    });

    test('beep cukup kecil (< 20 KB)', () {
      for (final path in ['assets/audio/beep_ok.mp3', 'assets/audio/beep_fail.mp3']) {
        final kb = File(path).lengthSync() / 1024;
        expect(kb, lessThan(20), reason: '$path = ${kb.toStringAsFixed(1)} KB');
      }
    });

    test('preview 20 detik @96kbps wajar (< 320 KB)', () {
      for (final path in [
        'assets/audio/preview_01.mp3',
        'assets/audio/preview_02.mp3',
        'assets/audio/preview_03.mp3',
        'assets/audio/preview_04.mp3',
        'assets/audio/preview_05.mp3',
      ]) {
        final kb = File(path).lengthSync() / 1024;
        expect(kb, lessThan(320), reason: '$path = ${kb.toStringAsFixed(1)} KB');
      }
    });

    test('total aset audio di bawah 2 MB', () {
      final total = wajib
          .map((p) => File(p).lengthSync())
          .fold<int>(0, (a, b) => a + b);
      expect(total, lessThan(2 * 1024 * 1024),
          reason: 'total ${(total / 1024).toStringAsFixed(0)} KB');
    });

    test('folder assets/audio terdaftar di pubspec', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.contains('assets/audio/'), isTrue);
    });

    test('package just_audio dan audio_session terpasang', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.contains('just_audio:'), isTrue);
      expect(pubspec.contains('audio_session:'), isTrue);
    });
  });

  group('DemoMedia.withAudioFallback', () {
    test('media dari database tidak pernah ditimpa', () {
      const asli = EventMedia(
        audioRef: 'assets/audio/preview_01.mp3',
        audioTitle: 'Lagu Asli',
        audioDurationSec: 20,
      );
      final hasil = DemoMedia.withAudioFallback(asli, 'event-apa-saja');
      expect(hasil.audioRef, asli.audioRef);
      expect(hasil.audioTitle, asli.audioTitle);
    });

    test('media kosong mendapat cadangan', () {
      final hasil = DemoMedia.withAudioFallback(EventMedia.empty, 'abc');
      expect(hasil.hasAudio, isTrue);
      expect(hasil.audioRef, startsWith('assets/audio/preview_'));
      expect(hasil.audioDurationSec, 20);
    });

    test('pemilihan cadangan deterministik untuk id yang sama', () {
      final a = DemoMedia.withAudioFallback(EventMedia.empty, 'event-123');
      final b = DemoMedia.withAudioFallback(EventMedia.empty, 'event-123');
      expect(a.audioRef, b.audioRef);
    });

    test('cadangan hanya menambah audio, field lain tidak diubah', () {
      const asli = EventMedia(
        videoYoutubeId: 'dQw4w9WgXcQ',
        venueModelRef: 'assets/models/venue.glb',
      );
      final hasil = DemoMedia.withAudioFallback(asli, 'x');
      expect(hasil.videoYoutubeId, asli.videoYoutubeId);
      expect(hasil.venueModelRef, asli.venueModelRef);
      expect(hasil.hasAudio, isTrue);
    });
  });
}
