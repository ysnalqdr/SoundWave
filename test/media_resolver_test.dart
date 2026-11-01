import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/core/media/media_resolver.dart';
import 'package:soundwave/models/event_media_model.dart';

void main() {
  group('MediaResolver.isRemote', () {
    test('mengenali URL http dan https', () {
      expect(MediaResolver.isRemote('https://cdn.example.com/a.mp3'), isTrue);
      expect(MediaResolver.isRemote('http://cdn.example.com/a.mp3'), isTrue);
    });

    test('mengenali data URI', () {
      expect(MediaResolver.isRemote('data:audio/mp3;base64,AAAA'), isTrue);
    });

    test('path aset lokal bukan remote', () {
      expect(MediaResolver.isRemote('assets/audio/preview_01.mp3'), isFalse);
      expect(MediaResolver.isAsset('assets/audio/preview_01.mp3'), isTrue);
    });

    test('string kosong bukan remote dan bukan aset', () {
      expect(MediaResolver.isRemote(''), isFalse);
      expect(MediaResolver.isAsset(''), isFalse);
    });

    test('spasi di tepi diabaikan', () {
      expect(MediaResolver.isRemote('  https://x.test/a  '), isTrue);
    });
  });

  group('MediaResolver.extractYoutubeId', () {
    const id = 'dQw4w9WgXcQ';

    test('menerima ID murni', () {
      expect(MediaResolver.extractYoutubeId(id), id);
    });

    test('menerima bentuk youtu.be', () {
      expect(MediaResolver.extractYoutubeId('https://youtu.be/$id'), id);
    });

    test('menerima watch?v=', () {
      expect(
        MediaResolver.extractYoutubeId('https://www.youtube.com/watch?v=$id'),
        id,
      );
    });

    test('menerima embed', () {
      expect(
        MediaResolver.extractYoutubeId('https://www.youtube.com/embed/$id'),
        id,
      );
    });

    test('menerima shorts', () {
      expect(
        MediaResolver.extractYoutubeId('https://www.youtube.com/shorts/$id'),
        id,
      );
    });

    test('menerima parameter tambahan', () {
      expect(
        MediaResolver.extractYoutubeId(
            'https://www.youtube.com/watch?v=$id&t=30s'),
        id,
      );
    });

    test('menolak masukan tidak valid', () {
      expect(MediaResolver.extractYoutubeId(null), isNull);
      expect(MediaResolver.extractYoutubeId(''), isNull);
      expect(MediaResolver.extractYoutubeId('bukan url'), isNull);
      expect(MediaResolver.extractYoutubeId('https://vimeo.com/123456'), isNull);
    });
  });

  group('EventMedia.fromMap', () {
    test('membaca peta lengkap', () {
      final media = EventMedia.fromMap({
        'audioRef': 'assets/audio/preview_01.mp3',
        'audioTitle': 'Judul Lagu',
        'audioDurationSec': 20,
        'videoYoutubeId': 'dQw4w9WgXcQ',
        'videoStartSec': 30,
        'videoDurationSec': 30,
        'venueModelRef': 'assets/models/venue.glb',
        'venuePosterRef': 'assets/images/venue/poster.png',
      });

      expect(media.hasAudio, isTrue);
      expect(media.hasVideo, isTrue);
      expect(media.hasVenue, isTrue);
      expect(media.audioDurationSec, 20);
      expect(media.videoStartSec, 30);
      expect(media.isEmpty, isFalse);
    });

    test('null menjadi media kosong', () {
      final media = EventMedia.fromMap(null);
      expect(media.isEmpty, isTrue);
      expect(media.hasAudio, isFalse);
    });

    test('peta kosong memakai nilai bawaan', () {
      final media = EventMedia.fromMap(<String, dynamic>{});
      expect(media.isEmpty, isTrue);
      expect(media.audioDurationSec, 20);
      expect(media.videoDurationSec, 30);
    });

    test('tahan terhadap tipe campuran dan string kosong', () {
      final media = EventMedia.fromMap({
        'audioRef': '   ',
        'audioDurationSec': '25',
        'videoYoutubeId': 123,
      });
      expect(media.hasAudio, isFalse, reason: 'string spasi dianggap kosong');
      expect(media.audioDurationSec, 25, reason: 'string angka diparse');
      expect(media.hasVideo, isFalse, reason: 'angka bukan teks');
    });

    test('toMap hanya menulis field terisi', () {
      const media = EventMedia(audioRef: 'assets/audio/a.mp3');
      final map = media.toMap();
      expect(map.containsKey('audioRef'), isTrue);
      expect(map.containsKey('videoYoutubeId'), isFalse);
      expect(map.containsKey('venueModelRef'), isFalse);
    });

    test('bolak-balik fromMap/toMap stabil', () {
      const asli = EventMedia(
        audioRef: 'assets/audio/a.mp3',
        audioTitle: 'Lagu',
        videoYoutubeId: 'dQw4w9WgXcQ',
        videoStartSec: 15,
        venueModelRef: 'assets/models/v.glb',
      );
      final hasil = EventMedia.fromMap(asli.toMap());
      expect(hasil.audioRef, asli.audioRef);
      expect(hasil.audioTitle, asli.audioTitle);
      expect(hasil.videoYoutubeId, asli.videoYoutubeId);
      expect(hasil.videoStartSec, asli.videoStartSec);
      expect(hasil.venueModelRef, asli.venueModelRef);
    });
  });
}
