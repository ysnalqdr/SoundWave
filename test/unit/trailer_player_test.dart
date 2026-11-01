import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Penjaga pemutar trailer di halaman detail konser.
///
/// Video tidak bisa diuji tanpa perangkat, tapi **aturan**-nya bisa dikunci:
///
/// 1. Tidak memuat WebView sebelum diketuk — halaman harus tetap ringan.
/// 2. Audio pratinjau dijeda saat trailer mulai — dua sumber bunyi sekaligus
///    tidak bisa dimatikan pengguna satu per satu.
/// 3. Berhenti di akhir potongan dan menawarkan jalan ke YouTube.
/// 4. Kegagalan menampilkan pesan + tombol keluar, bukan kotak kosong.
void main() {
  final pemutar =
      File('lib/widgets/media/trailer_player.dart').readAsStringSync();
  final detail =
      File('lib/screens/user/user_konser_detail_screen.dart').readAsStringSync();

  group('TrailerPlayer', () {
    test('tidak membuat controller sebelum diketuk', () {
      // Controller hanya dibuat di dalam _mulai(), bukan di initState/build.
      final init = pemutar.indexOf('void initState()');
      final blokInit = pemutar.substring(init, init + 400);
      expect(blokInit.contains('fromVideoId'), isFalse,
          reason: 'WebView di initState membuat halaman berat sejak dibuka');
    });

    test('potongan dibatasi start dan end dari admin', () {
      expect(pemutar.contains('startSeconds: mulai'), isTrue);
      expect(pemutar.contains('endSeconds: akhir'), isTrue);
      expect(pemutar.contains('widget.startSec + widget.durationSec'), isTrue);
    });

    test('menjeda audio pratinjau saat trailer diputar', () {
      expect(pemutar.contains('AudioService.instance.pausePreview()'), isTrue,
          reason: 'lagu dan trailer tidak boleh berbunyi bersamaan');
    });

    test('penjediaan audio TIDAK di initState', () {
      // ListView membuat ulang anak yang tergulung kembali ke layar, sehingga
      // initState berjalan berulang. Menjeda audio di sana membuat lagu
      // berhenti sendiri tiap kali pengguna menggulir melewati seksi trailer.
      final idx = pemutar.indexOf('void initState()');
      final blok = pemutar.substring(idx, idx + 600);
      expect(blok.contains('pausePreview'), isFalse,
          reason: 'penjedaan harus terjadi saat tombol play ditekan');
    });

    test('menangani status selesai', () {
      // Dua jalur: event `ended` dari iframe, dan pengawas posisi yang
      // menjeda paksa di batas akhir (endSeconds tidak selalu dihormati).
      expect(pemutar.contains('PlayerState.ended'), isTrue);
      expect(pemutar.contains('_batasAkhir'), isTrue);
      expect(pemutar.contains('Putar ulang'), isTrue);
    });

    test('menawarkan jalan keluar saat gagal', () {
      expect(pemutar.contains('_tampilanGagal'), isTrue);
      expect(pemutar.contains('Buka di YouTube'), isTrue);
      expect(pemutar.contains('value.hasError'), isTrue);
    });

    test('membuka YouTube mulai dari detik yang sama', () {
      expect(pemutar.contains("'&t="), isTrue,
          reason: 'penonton harus lanjut dari titik potongan, bukan dari awal');
      expect(pemutar.contains('LaunchMode.externalApplication'), isTrue);
    });

    test('membatasi video terkait ke kanal yang sama', () {
      expect(pemutar.contains('strictRelatedVideos: true'), isTrue,
          reason: 'video terkait dari kanal lain bisa tidak relevan');
    });

    test('membebaskan controller saat widget dibuang', () {
      final idx = pemutar.indexOf('void dispose()');
      final blok = pemutar.substring(idx, idx + 220);
      expect(blok.contains('close()'), isTrue);
      expect(blok.contains('_sub?.cancel()'), isTrue);
    });

    test('tidak memakai YouTube Data API (tanpa kunci)', () {
      expect(pemutar.contains('googleapis.com'), isFalse,
          reason: 'pemutar iframe tidak butuh API key; jangan tambah beban');
    });
  });

  group('Halaman detail', () {
    test('seksi trailer terpasang setelah audio', () {
      final idxAudio = detail.indexOf('_seksiAudio(),');
      final idxVideo = detail.indexOf('_seksiVideo(),');
      expect(idxAudio, greaterThan(-1));
      expect(idxVideo, greaterThan(idxAudio),
          reason: 'urutan: dengar dulu, lalu tonton');
    });

    test('seksi trailer tidak dirender tanpa video', () {
      final idx = detail.indexOf('Widget _seksiVideo()');
      final blok = detail.substring(idx, idx + 400);
      expect(blok.contains('if (!media.hasVideo)'), isTrue);
      expect(blok.contains('SizedBox.shrink()'), isTrue);
    });

    test('ID video divalidasi sebelum dipakai', () {
      final idx = detail.indexOf('Widget _seksiVideo()');
      final blok = detail.substring(idx, idx + 400);
      expect(blok.contains('extractYoutubeId'), isTrue);
    });

    test('audio tidak lagi menolak URL', () {
      final idx = detail.indexOf('Widget _seksiAudio()');
      final blok = detail.substring(idx, idx + 700);
      expect(blok.contains('isRemote(ref)'), isFalse,
          reason: 'AudioService sudah mendukung URL; penyaringan ini usang');
    });
  });

  group('Dependensi', () {
    test('paket pemutar YouTube terpasang', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.contains('youtube_player_iframe:'), isTrue);
    });
  });
}
