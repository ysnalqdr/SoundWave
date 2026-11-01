import 'package:flutter/widgets.dart';

/// Penentu sumber media dari sebuah *referensi*.
///
/// Referensi boleh berupa path aset lokal atau URL absolut. Semua widget media
/// memakai helper ini agar perpindahan aset dari bundle aplikasi ke CDN (atau
/// sebaliknya) tidak menuntut perubahan pada widget mana pun.
///
/// Aturan deteksi: apa pun yang diawali `http://` atau `https://` dianggap
/// jaringan, sisanya dianggap aset lokal.
class MediaResolver {
  MediaResolver._();

  static const List<String> _schemes = ['http://', 'https://', 'data:'];

  /// True bila [ref] menunjuk sumber jaringan (bukan aset lokal).
  static bool isRemote(String ref) {
    final value = ref.trim().toLowerCase();
    return _schemes.any(value.startsWith);
  }

  /// True bila [ref] menunjuk aset lokal yang dibundel dalam aplikasi.
  static bool isAsset(String ref) =>
      ref.trim().isNotEmpty && !isRemote(ref);

  /// [ImageProvider] yang sesuai untuk [ref]: [NetworkImage] atau [AssetImage].
  ///
  /// Mengembalikan `null` bila [ref] kosong, sehingga pemanggil dapat memakai
  /// gambar placeholder tanpa perlu mengecek string kosong lebih dulu.
  static ImageProvider<Object>? imageProvider(String? ref) {
    if (ref == null || ref.trim().isEmpty) return null;
    final value = ref.trim();
    // Ditulis sebagai if/else, bukan ternary: kedua cabang punya tipe generik
    // berbeda (`ImageProvider<NetworkImage>` vs `<AssetImage>`), sehingga
    // ternary menyimpulkan `Object` dan gagal dikembalikan.
    if (isRemote(value)) {
      return NetworkImage(value);
    }
    return AssetImage(value);
  }

  /// [AssetImage] untuk poster venue 3D. Model 3D selalu dibundel lokal pada
  /// iterasi ini; helper tetap disediakan agar konsisten bila kelak di-host.
  static ImageProvider<Object>? venuePoster(String? ref) => imageProvider(ref);

  /// Menormalkan referensi audio menjadi path/URL yang bisa dibaca pemutar.
  ///
  /// `just_audio` membutuhkan [Uri] untuk sumber jaringan dan path aset untuk
  /// sumber lokal, sehingga pemanggil perlu tahu jenisnya lebih dulu.
  static bool isAudioRemote(String ref) => isRemote(ref);

  /// Mengambil ID video YouTube dari beberapa bentuk masukan yang lazim
  /// ditemui admin saat mengisi form:
  ///
  /// - `dQw4w9WgXcQ` (ID murni)
  /// - `https://youtu.be/dQw4w9WgXcQ`
  /// - `https://www.youtube.com/watch?v=dQw4w9WgXcQ`
  /// - `https://www.youtube.com/embed/dQw4w9WgXcQ`
  /// - `https://www.youtube.com/shorts/dQw4w9WgXcQ`
  ///
  /// Mengembalikan `null` bila tidak ada ID yang bisa dikenali, sehingga UI
  /// dapat menampilkan poster sebagai gantinya (degradasi anggun).
  static String? extractYoutubeId(String? input) {
    if (input == null) return null;
    final value = input.trim();
    if (value.isEmpty) return null;

    // ID murni: 11 karakter alfanumerik, tanda hubung, atau garis bawah.
    final bare = RegExp(r'^[A-Za-z0-9_-]{11}$');
    if (bare.hasMatch(value)) return value;

    // Batas `(?![A-Za-z0-9_-])` wajib ada. Tanpa itu, regex hanya mengambil
    // 11 karakter pertama dari string yang lebih panjang — sehingga
    // `watch?v=terlalupendek` diterima sebagai ID `terlalupend`, dan admin
    // mendapat trailer yang tidak pernah bisa diputar tanpa pesan galat.
    const batas = r'(?![A-Za-z0-9_-])';
    final patterns = <RegExp>[
      RegExp(r'youtu\.be/([A-Za-z0-9_-]{11})' + batas),
      RegExp(r'[?&]v=([A-Za-z0-9_-]{11})' + batas),
      RegExp(r'/embed/([A-Za-z0-9_-]{11})' + batas),
      RegExp(r'/shorts/([A-Za-z0-9_-]{11})' + batas),
      RegExp(r'/live/([A-Za-z0-9_-]{11})' + batas),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(value);
      if (match != null) return match.group(1);
    }
    return null;
  }
}
