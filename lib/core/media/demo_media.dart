import '../../models/event_media_model.dart';
import 'audio_library.dart';

/// Media contoh untuk keperluan demonstrasi.
///
/// Kenapa ada berkas ini: data event di Firestore belum tentu punya field
/// `media`, sedangkan fitur audio perlu bisa dicoba tanpa menunggu admin
/// mengisi data. Daripada menaruh `if (demo) ...` bertebaran di UI, seluruh
/// aturan cadangan dikumpulkan di satu tempat dan ditandai jelas.
///
/// Aturan pemakaian:
/// - Media dari Firestore **selalu menang**. Cadangan hanya dipakai bila
///   event benar-benar belum punya media.
/// - Cadangan dipilih deterministik dari id event, supaya event yang sama
///   selalu memutar potongan yang sama (tidak berubah tiap rebuild).
/// - Saat data asli sudah diisi, berkas ini tidak berpengaruh dan aman
///   dihapus.
class DemoMedia {
  DemoMedia._();

  /// Mengembalikan [media] apa adanya bila sudah berisi audio; kalau belum,
  /// kembalikan cadangan berbasis [eventId].
  ///
  /// [eventId] boleh apa saja — hash-nya dipakai sebagai pemilih.
  static EventMedia withAudioFallback(EventMedia media, String eventId) {
    if (media.hasAudio) return media;
    final index = eventId.hashCode.abs() % AudioLibrary.tracks.length;
    final track = AudioLibrary.tracks[index];
    return media.copyWith(
      audioRef: track.ref,
      audioTitle: track.title,
      audioDurationSec: track.durationSec,
    );
  }
}
