/// Daftar potongan audio yang dibundel di dalam aplikasi.
///
/// Kenapa dipusatkan di sini: form admin menampilkan pilihan lagu, dan
/// `DemoMedia` memilih cadangan untuk event yang belum diisi. Keduanya harus
/// membaca daftar yang sama — kalau tidak, admin bisa memilih track yang tidak
/// dikenal pemutar.
///
/// Menambah lagu baru:
/// 1. Simpan berkas di `assets/audio/`
/// 2. Tambahkan satu entri di [tracks]
/// 3. Daftarkan folder di `pubspec.yaml` (sudah dilakukan)
/// 4. Build ulang aplikasi — berkas lokal ikut di dalam APK
///
/// Untuk menambah lagu **tanpa** build ulang, admin memakai kolom URL pada
/// form konser (lihat `form_konser_screen.dart`).
class AudioLibrary {
  AudioLibrary._();

  static const List<AudioTrack> tracks = [
    AudioTrack(
      ref: 'assets/audio/preview_01.mp3',
      title: 'When I Was Your Man',
      durationSec: 20,
    ),
    AudioTrack(
      ref: 'assets/audio/preview_02.mp3',
      title: 'Membasuh',
      durationSec: 20,
    ),
    AudioTrack(
      ref: 'assets/audio/preview_03.mp3',
      title: 'Best Friend',
      durationSec: 20,
    ),
    AudioTrack(
      ref: 'assets/audio/preview_04.mp3',
      title: 'Treat You Better',
      durationSec: 20,
    ),
    AudioTrack(
      ref: 'assets/audio/preview_05.mp3',
      title: 'Semua Aku Dirayakan',
      durationSec: 20,
    ),
  ];

  /// Mencari track berdasarkan referensinya. Null bila tidak ada di pustaka.
  static AudioTrack? byRef(String? ref) {
    if (ref == null) return null;
    for (final t in tracks) {
      if (t.ref == ref) return t;
    }
    return null;
  }
}

/// Satu potongan audio bawaan.
class AudioTrack {
  /// Path aset, mis. `assets/audio/preview_01.mp3`.
  final String ref;

  /// Judul yang ditampilkan ke pengguna.
  final String title;

  /// Panjang potongan dalam detik.
  final int durationSec;

  const AudioTrack({
    required this.ref,
    required this.title,
    required this.durationSec,
  });
}
