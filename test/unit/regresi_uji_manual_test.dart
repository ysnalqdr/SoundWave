import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Penjaga perbaikan hasil uji manual 24 Okt 2026.
///
/// Setiap tes di sini mewakili satu bug yang **benar-benar terjadi** di
/// perangkat, bukan dugaan. Kalau salah satu gagal lagi, artinya bug lama
/// kembali.
void main() {
  final service = File('lib/services/audio_service.dart').readAsStringSync();
  final preview =
      File('lib/widgets/media/audio_preview_player.dart').readAsStringSync();
  final mini =
      File('lib/widgets/media/audio_mini_player.dart').readAsStringSync();
  final detail =
      File('lib/screens/user/user_konser_detail_screen.dart').readAsStringSync();
  final trailer =
      File('lib/widgets/media/trailer_player.dart').readAsStringSync();
  final steps =
      File('lib/screens/user/checkout_parts/checkout_steps.dart').readAsStringSync();
  final rules = File('firestore.rules').readAsStringSync();
  final library =
      File('lib/core/media/audio_library.dart').readAsStringSync();
  final picker =
      File('lib/widgets/media/audio_picker_field.dart').readAsStringSync();

  group('A6 — audio tidak mati saat digulir', () {
    test('pemutar tidak menghentikan audio di dispose', () {
      final idx = preview.indexOf('void dispose()');
      final blok = preview.substring(idx, idx + 700);
      expect(blok.contains('stopPreview()'), isFalse,
          reason: 'ListView membuang anak yang tergulung keluar layar; '
              'menghentikan audio di sini membuat lagu mati saat scroll');
    });

    test('layar pemilik halaman yang menghentikan audio', () {
      final idx = detail.indexOf('void dispose()');
      final blok = detail.substring(idx, idx + 500);
      expect(blok.contains('stopPreview()'), isTrue,
          reason: 'hanya dispose layar yang menandakan pengguna benar-benar '
              'meninggalkan halaman');
    });

    test('mini player berada di luar area yang bisa digulir', () {
      final idxMini = detail.indexOf('const AudioMiniPlayer()');
      final idxExpanded = detail.indexOf('Expanded(\n              child: TabBarView(');
      expect(idxMini, greaterThan(-1));
      expect(idxMini, greaterThan(idxExpanded),
          reason: 'mini player harus diletakkan setelah Expanded, '
              'bukan di dalam daftar');
    });
  });

  group('C2/C3 — trailer benar-benar dipotong', () {
    test('batas akhir ditegakkan sendiri, bukan hanya endSeconds', () {
      expect(trailer.contains('_pengawas'), isTrue,
          reason: 'endSeconds tidak dihormati semua klien YouTube — '
              'pada perangkat uji video tetap berjalan sampai durasi penuh');
      expect(trailer.contains('pauseVideo()'), isTrue);
    });

    test('pengawas diperiksa berkala dan dibersihkan', () {
      expect(trailer.contains('Timer.periodic'), isTrue);
      final idx = trailer.indexOf('void dispose()');
      final blok = trailer.substring(idx, idx + 250);
      expect(blok.contains('_pengawas?.cancel()'), isTrue);
    });

    test('ada tombol putar ulang setelah potongan selesai', () {
      expect(trailer.contains('Putar ulang'), isTrue);
      expect(trailer.contains('_ulangDariAwal'), isTrue);
    });
  });

  group('C4/C5 — akhir potongan terlihat', () {
    test('status selesai memunculkan ajakan, bukan diam', () {
      expect(trailer.contains('PlayerState.ended'), isTrue);
      expect(trailer.contains('_selesai'), isTrue);
    });
  });

  group('D4 — confetti berulang', () {
    test('animasi sukses di-loop', () {
      final idx = steps.indexOf('success_confetti.json');
      final blok = steps.substring(idx - 400, idx + 200);
      expect(blok.contains('repeat: true'), isTrue,
          reason: 'sekali putar membuat layar sukses terasa mati '
              'padahal pengguna masih membaca kode booking');
    });
  });

  group('D1–D3 — animasi tampil', () {
    test('layar Jelajah memakai komponen animasi', () {
      final explore =
          File('lib/screens/user/user_explore_screen.dart').readAsStringSync();
      expect(explore.contains('AppLoading('), isTrue);
      expect(explore.contains('AppErrorState('), isTrue);
    });

    test('komponen memakai path aset yang benar-benar ada', () {
      final komponen =
          File('lib/widgets/feedback/app_state_views.dart').readAsStringSync();
      for (final path in ['loading_cat.json', 'error_404.json']) {
        expect(File('assets/lottie/$path').existsSync(), isTrue);
      }
      expect(komponen.contains('LottieAssets.loading'), isTrue);
      expect(komponen.contains('LottieAssets.error'), isTrue);
    });
  });

  group('Layar sukses — tidak overflow', () {
    test('isi layar sukses bisa digulir', () {
      expect(steps.contains('SingleChildScrollView'), isTrue,
          reason: 'animasi 460x460 pada Column+Spacer memicu '
              'BOTTOM OVERFLOWED BY 46 PIXELS di layar kecil');
    });

    test('tidak ada Spacer di dalam area yang bisa digulir', () {
      final idx = steps.indexOf('_buildSuccessView');
      final blok = steps.substring(idx, idx + 4200);
      expect(blok.contains('const Spacer()'), isFalse,
          reason: 'Spacer di dalam scroll view tidak punya tinggi terbatas');
    });

    test('ukuran animasi menyesuaikan tinggi layar', () {
      expect(steps.contains('batas.maxHeight'), isTrue);
      expect(steps.contains('sisiAnimasi'), isTrue);
    });
  });

  group('Permission-denied — aturan Firestore', () {
    test('events bisa dibaca tanpa syarat per-dokumen', () {
      final idx = rules.indexOf('match /events/{eventId}');
      final blok = rules.substring(idx, idx + 900);
      // Periksa baris aturan saja — komentar penjelasan boleh menyebut aturan
      // lama sebagai contoh, itu tidak berpengaruh apa pun.
      final barisAturan = blok
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.startsWith('allow '))
          .toList();
      expect(barisAturan.any((l) => l.contains('allow read: if true;')), isTrue,
          reason: 'syarat per-dokumen membuat Firestore menolak seluruh '
              'query koleksi dengan permission-denied');
      expect(
        barisAturan.any((l) => l.contains("eventId != '_backend_config'")),
        isFalse,
        reason: 'aturan baca tidak boleh lagi bergantung pada id dokumen',
      );
    });

    test('penulisan events tetap hanya untuk admin', () {
      final idx = rules.indexOf('match /events/{eventId}');
      final blok = rules.substring(idx, idx + 900);
      expect(blok.contains('allow create, update, delete: if isAdmin();'),
          isTrue);
    });
  });

  group('Audio — potongan dari URL', () {
    test('service mendukung start dan durasi potongan', () {
      expect(service.contains('int startSec = 0'), isTrue);
      expect(service.contains('int durationSec = 0'), isTrue);
      expect(service.contains('_batasAkhirPreview'), isTrue);
      expect(service.contains('_pasangPengawasPreview'), isTrue);
    });

    test('pemilih audio menyediakan kolom mulai dan durasi untuk URL', () {
      expect(picker.contains("labelText: 'Mulai dari'"), isTrue);
      expect(picker.contains("labelText: 'Durasi (detik)'"), isTrue);
      expect(picker.contains('audioStartSec'), isTrue);
    });

    test('durasi dari pustaka menang atas angka di Firestore', () {
      expect(detail.contains('AudioLibrary.byRef(ref)'), isTrue,
          reason: 'audioDurationSec di dokumen bisa basi setelah berkas '
              'diganti; pustaka membaca durasi berkas yang benar-benar ada');
    });

    test('semua preview bawaan berdurasi 20 detik', () {
      final durasi = RegExp(r'durationSec: (\d+)')
          .allMatches(library)
          .map((m) => int.parse(m.group(1)!))
          .toList();
      expect(durasi.length, 5);
      expect(durasi.every((d) => d == 20), isTrue,
          reason: 'semua potongan bawaan harus seragam 20 detik; '
              'sebelumnya preview_05 hanya 10 detik');
    });

    test('berkas audio benar-benar 20 detik di disk', () {
      // Panjang berkas diperiksa lewat ukuran sebagai proksi: 20 detik
      // 96 kbps mono ≈ 235 KB, 10 detik ≈ 118 KB.
      for (var i = 1; i <= 5; i++) {
        final f = File('assets/audio/preview_0$i.mp3');
        expect(f.existsSync(), isTrue);
        final kb = f.lengthSync() / 1024;
        expect(kb, greaterThan(200),
            reason: 'preview_0$i hanya ${kb.toStringAsFixed(0)} KB — '
                'kemungkinan masih 10 detik');
      }
    });
  });

  group('Mini player', () {
    test('tetap tampil selama ada track aktif', () {
      expect(mini.contains('nowPlaying'), isTrue);
      expect(mini.contains('if (title == null)'), isTrue);
    });

    test('punya tombol jeda, lanjut, dan hentikan', () {
      expect(mini.contains('pausePreview()'), isTrue);
      expect(mini.contains('resumePreview()'), isTrue);
      expect(mini.contains('stopPreview'), isTrue);
    });
  });
}
