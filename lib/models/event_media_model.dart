/// Model media tambahan milik sebuah event: audio pratinjau, trailer video,
/// dan model venue 3D.
///
/// Setiap field menyimpan **referensi**, bukan URL jadi. Referensi boleh berupa
/// path aset lokal (`assets/audio/preview_01.mp3`) maupun URL absolut
/// (`https://...`). Pemisahan ini disengaja agar aset bisa dipindahkan dari
/// bundle aplikasi ke CDN tanpa mengubah kode maupun skema database — cukup
/// ganti nilai string-nya.
///
/// Contoh dokumen Firestore:
/// ```json
/// {
///   "media": {
///     "audioRef": "assets/audio/preview_01.mp3",
///     "audioTitle": "Hymn for the Weekend",
///     "audioDurationSec": 20,
///     "videoYoutubeId": "dQw4w9WgXcQ",
///     "videoStartSec": 30,
///     "videoDurationSec": 30,
///     "venueModelRef": "assets/models/venue.glb",
///     "venuePosterRef": "assets/images/venue/poster.png"
///   }
/// }
/// ```
class EventMedia {
  /// Referensi audio pratinjau (path aset atau URL).
  final String? audioRef;

  /// Judul lagu yang ditampilkan di atas pemutar audio.
  final String? audioTitle;

  /// Durasi potongan audio dalam detik.
  final int audioDurationSec;

  /// Detik mulai potongan audio.
  ///
  /// Hanya berarti untuk berkas jaringan yang panjangnya tidak diketahui
  /// aplikasi. Berkas bawaan sudah dipotong saat dibundel, jadi selalu 0.
  final int audioStartSec;

  /// ID video YouTube (bukan URL penuh — lihat `extractYoutubeId`).
  final String? videoYoutubeId;

  /// Detik mulai pemutaran trailer.
  final int videoStartSec;

  /// Panjang potongan trailer dalam detik.
  final int videoDurationSec;

  /// Referensi model venue 3D berformat GLB.
  final String? venueModelRef;

  /// Gambar poster yang tampil selagi model 3D dimuat.
  final String? venuePosterRef;

  const EventMedia({
    this.audioRef,
    this.audioTitle,
    this.audioDurationSec = 20,
    this.audioStartSec = 0,
    this.videoYoutubeId,
    this.videoStartSec = 0,
    this.videoDurationSec = 30,
    this.venueModelRef,
    this.venuePosterRef,
  });

  /// Media kosong — dipakai sebagai nilai bawaan ketika event belum punya media.
  static const EventMedia empty = EventMedia();

  bool get hasAudio => (audioRef ?? '').isNotEmpty;
  bool get hasVideo => (videoYoutubeId ?? '').isNotEmpty;
  bool get hasVenue => (venueModelRef ?? '').isNotEmpty;

  /// True bila event tidak punya satu pun media. Berguna untuk memilih tampilan
  /// alternatif (mis. hanya poster) tanpa mengecek tiga getter satu per satu.
  bool get isEmpty => !hasAudio && !hasVideo && !hasVenue;

  /// Membaca peta `media` dari Firestore. Aman terhadap nilai null, tipe
  /// campuran, maupun field yang belum ada pada dokumen lama.
  factory EventMedia.fromMap(dynamic raw) {
    if (raw is! Map) return EventMedia.empty;
    final map = Map<String, dynamic>.from(raw);

    int asInt(String key, int fallback) {
      final value = map[key];
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    String? asText(String key) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      return null;
    }

    return EventMedia(
      audioRef: asText('audioRef'),
      audioTitle: asText('audioTitle'),
      audioDurationSec: asInt('audioDurationSec', 20),
      audioStartSec: asInt('audioStartSec', 0),
      videoYoutubeId: asText('videoYoutubeId'),
      videoStartSec: asInt('videoStartSec', 0),
      videoDurationSec: asInt('videoDurationSec', 30),
      venueModelRef: asText('venueModelRef'),
      venuePosterRef: asText('venuePosterRef'),
    );
  }

  /// Hanya menulis field yang terisi, supaya dokumen Firestore tidak dipenuhi
  /// nilai null.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (audioRef != null) map['audioRef'] = audioRef;
    if (audioTitle != null) map['audioTitle'] = audioTitle;
    if (hasAudio) {
      map['audioDurationSec'] = audioDurationSec;
      // Hanya ditulis bila bukan nol, supaya dokumen lama tidak berubah
      // bentuk hanya karena field baru ditambahkan.
      if (audioStartSec > 0) map['audioStartSec'] = audioStartSec;
    }
    if (videoYoutubeId != null) map['videoYoutubeId'] = videoYoutubeId;
    if (hasVideo) {
      map['videoStartSec'] = videoStartSec;
      map['videoDurationSec'] = videoDurationSec;
    }
    if (venueModelRef != null) map['venueModelRef'] = venueModelRef;
    if (venuePosterRef != null) map['venuePosterRef'] = venuePosterRef;
    return map;
  }

  EventMedia copyWith({
    String? audioRef,
    String? audioTitle,
    int? audioDurationSec,
    int? audioStartSec,
    String? videoYoutubeId,
    int? videoStartSec,
    int? videoDurationSec,
    String? venueModelRef,
    String? venuePosterRef,
  }) {
    return EventMedia(
      audioRef: audioRef ?? this.audioRef,
      audioTitle: audioTitle ?? this.audioTitle,
      audioDurationSec: audioDurationSec ?? this.audioDurationSec,
      audioStartSec: audioStartSec ?? this.audioStartSec,
      videoYoutubeId: videoYoutubeId ?? this.videoYoutubeId,
      videoStartSec: videoStartSec ?? this.videoStartSec,
      videoDurationSec: videoDurationSec ?? this.videoDurationSec,
      venueModelRef: venueModelRef ?? this.venueModelRef,
      venuePosterRef: venuePosterRef ?? this.venuePosterRef,
    );
  }

  /// Mengganti **hanya** bagian audio, sisanya dipertahankan.
  ///
  /// [copyWith] tidak bisa mengosongkan field (null berarti "jangan diubah"),
  /// sehingga pemilih audio tidak bisa memakai [copyWith] untuk melepas
  /// pilihan. Method ini menerima null sebagai nilai sungguhan.
  ///
  /// Kenapa penting: form konser punya pemilih audio dan pemilih video
  /// berdampingan. Kalau salah satunya membangun `EventMedia` baru dari nol,
  /// memilih video akan menghapus audio yang sudah diisi — dan sebaliknya.
  EventMedia withAudio({
    String? audioRef,
    String? audioTitle,
    int? audioDurationSec,
    int? audioStartSec,
  }) {
    return EventMedia(
      audioRef: audioRef,
      audioTitle: audioTitle,
      audioDurationSec: audioDurationSec ?? this.audioDurationSec,
      audioStartSec: audioStartSec ?? this.audioStartSec,
      videoYoutubeId: videoYoutubeId,
      videoStartSec: videoStartSec,
      videoDurationSec: videoDurationSec,
      venueModelRef: venueModelRef,
      venuePosterRef: venuePosterRef,
    );
  }

  /// Mengganti **hanya** bagian video, sisanya dipertahankan.
  EventMedia withVideo({
    String? videoYoutubeId,
    int? videoStartSec,
    int? videoDurationSec,
  }) {
    return EventMedia(
      audioRef: audioRef,
      audioTitle: audioTitle,
      audioDurationSec: audioDurationSec,
      audioStartSec: audioStartSec,
      videoYoutubeId: videoYoutubeId,
      videoStartSec: videoStartSec ?? this.videoStartSec,
      videoDurationSec: videoDurationSec ?? this.videoDurationSec,
      venueModelRef: venueModelRef,
      venuePosterRef: venuePosterRef,
    );
  }

  /// Mengganti **hanya** bagian venue 3D, sisanya dipertahankan.
  EventMedia withVenue({
    String? venueModelRef,
    String? venuePosterRef,
  }) {
    return EventMedia(
      audioRef: audioRef,
      audioTitle: audioTitle,
      audioDurationSec: audioDurationSec,
      audioStartSec: audioStartSec,
      videoYoutubeId: videoYoutubeId,
      videoStartSec: videoStartSec,
      videoDurationSec: videoDurationSec,
      venueModelRef: venueModelRef,
      venuePosterRef: venuePosterRef ?? this.venuePosterRef,
    );
  }

  @override
  String toString() => 'EventMedia(audio: $hasAudio, video: $hasVideo, '
      'venue: $hasVenue)';
}
