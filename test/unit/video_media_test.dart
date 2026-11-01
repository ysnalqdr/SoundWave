import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/core/media/duration_format.dart';
import 'package:soundwave/core/media/media_resolver.dart';
import 'package:soundwave/models/event_media_model.dart';

/// Penjaga tahap "admin mengisi trailer video".
///
/// Dua kelas bug yang paling mungkin muncul di sini, dan keduanya tidak
/// terlihat dari UI:
///
/// 1. **Saling menghapus.** Form punya pemilih audio dan pemilih video
///    berdampingan. Kalau salah satunya membangun `EventMedia` dari nol,
///    mengisi video akan menghapus audio — admin tidak akan sadar sampai
///    membuka halaman user.
/// 2. **Tautan tidak dikenali.** Admin menempel tautan yang sah secara
///    manusia, tapi ekstraksi gagal sehingga trailer tidak pernah muncul.
void main() {
  group('EventMedia — bagian tidak saling menghapus', () {
    test('mengisi video mempertahankan audio', () {
      const awal = EventMedia(
        audioRef: 'assets/audio/preview_01.mp3',
        audioTitle: 'When I Was Your Man',
        audioDurationSec: 20,
      );

      final hasil = awal.withVideo(
        videoYoutubeId: 'dQw4w9WgXcQ',
        videoStartSec: 30,
        videoDurationSec: 30,
      );

      expect(hasil.audioRef, 'assets/audio/preview_01.mp3');
      expect(hasil.audioTitle, 'When I Was Your Man');
      expect(hasil.audioDurationSec, 20);
      expect(hasil.videoYoutubeId, 'dQw4w9WgXcQ');
    });

    test('mengisi audio mempertahankan video', () {
      const awal = EventMedia(
        videoYoutubeId: 'dQw4w9WgXcQ',
        videoStartSec: 15,
        videoDurationSec: 45,
      );

      final hasil = awal.withAudio(
        audioRef: 'assets/audio/preview_02.mp3',
        audioTitle: 'Membasuh',
      );

      expect(hasil.videoYoutubeId, 'dQw4w9WgXcQ');
      expect(hasil.videoStartSec, 15);
      expect(hasil.videoDurationSec, 45);
      expect(hasil.audioRef, 'assets/audio/preview_02.mp3');
    });

    test('melepas video tidak menyentuh audio', () {
      const awal = EventMedia(
        audioRef: 'assets/audio/preview_03.mp3',
        audioTitle: 'Best Friend',
        videoYoutubeId: 'dQw4w9WgXcQ',
      );

      final hasil = awal.withVideo();

      expect(hasil.videoYoutubeId, isNull);
      expect(hasil.audioRef, 'assets/audio/preview_03.mp3');
      expect(hasil.hasAudio, isTrue);
    });

    test('melepas audio tidak menyentuh video', () {
      const awal = EventMedia(
        audioRef: 'assets/audio/preview_03.mp3',
        videoYoutubeId: 'dQw4w9WgXcQ',
      );

      final hasil = awal.withAudio();

      expect(hasil.audioRef, isNull);
      expect(hasil.videoYoutubeId, 'dQw4w9WgXcQ');
      expect(hasil.hasVideo, isTrue);
    });

    test('model 3D ikut bertahan saat audio/video diubah', () {
      const awal = EventMedia(
        venueModelRef: 'assets/models/venue.glb',
        venuePosterRef: 'assets/images/venue/poster.png',
      );

      final lewatVideo = awal.withVideo(videoYoutubeId: 'dQw4w9WgXcQ');
      final lewatAudio = lewatVideo.withAudio(audioRef: 'assets/audio/x.mp3');

      expect(lewatAudio.venueModelRef, 'assets/models/venue.glb');
      expect(lewatAudio.venuePosterRef, 'assets/images/venue/poster.png');
    });

    test('toMap hanya menulis field yang terisi', () {
      const kosong = EventMedia(videoYoutubeId: 'dQw4w9WgXcQ');
      final map = kosong.toMap();

      expect(map.containsKey('videoYoutubeId'), isTrue);
      expect(map.containsKey('audioRef'), isFalse,
          reason: 'field null tidak boleh masuk Firestore');
    });
  });

  group('MediaResolver.extractYoutubeId', () {
    const id = 'dQw4w9WgXcQ';

    test('menerima ID murni', () {
      expect(MediaResolver.extractYoutubeId(id), id);
    });

    test('menerima semua bentuk tautan yang lazim', () {
      for (final tautan in [
        'https://youtu.be/$id',
        'https://www.youtube.com/watch?v=$id',
        'https://youtube.com/watch?v=$id&t=30s',
        'https://www.youtube.com/embed/$id',
        'https://www.youtube.com/shorts/$id',
        'https://www.youtube.com/live/$id',
        'http://youtu.be/$id',
      ]) {
        expect(MediaResolver.extractYoutubeId(tautan), id,
            reason: 'gagal mengenali: $tautan');
      }
    });

    test('menerima tautan dengan spasi di tepi', () {
      expect(MediaResolver.extractYoutubeId('  https://youtu.be/$id  '), id);
    });

    test('menolak masukan yang bukan video YouTube', () {
      for (final salah in [
        '',
        '   ',
        null,
        'https://vimeo.com/123456',
        'bukan tautan',
        'https://www.youtube.com/',
        'https://www.youtube.com/watch?v=terlalupendek',
      ]) {
        expect(MediaResolver.extractYoutubeId(salah), isNull,
            reason: 'seharusnya ditolak: $salah');
      }
    });
  });

  group('DurationFormat', () {
    test('menulis detik dua digit', () {
      expect(DurationFormat.clock(0), '0:00');
      expect(DurationFormat.clock(5), '0:05');
      expect(DurationFormat.clock(30), '0:30');
      expect(DurationFormat.clock(65), '1:05');
      expect(DurationFormat.clock(600), '10:00');
    });

    test('nilai negatif dijepit ke nol', () {
      expect(DurationFormat.clock(-10), '0:00');
    });

    test('rentang menampilkan awal dan akhir', () {
      expect(DurationFormat.rentang(30, 30), '0:30 – 1:00');
      expect(DurationFormat.rentang(0, 20), '0:00 – 0:20');
    });

    test('mengurai format jam:menit dan angka polos', () {
      expect(DurationFormat.parseClock('0:30'), 30);
      expect(DurationFormat.parseClock('1:05'), 65);
      expect(DurationFormat.parseClock('75'), 75);
      expect(DurationFormat.parseClock(' 2:00 '), 120);
    });

    test('menolak masukan tidak sah', () {
      for (final salah in ['', 'abc', '1:2:3', '-5', '1:75', ':30', '1:']) {
        expect(DurationFormat.parseClock(salah), isNull,
            reason: 'seharusnya ditolak: "$salah"');
      }
    });
  });
}
