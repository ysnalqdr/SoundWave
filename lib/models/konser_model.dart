import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import 'event_media_model.dart';

class KonserModel {
  final String id;
  String judul;
  String lokasi;
  DateTime tanggal;
  double harga;
  final List<String> genre;
  String gambarUrl;
  String? deskripsi;
  String? penyelenggara;
  String status;
  int views;

  /// Media tambahan (audio pratinjau, trailer video, venue 3D).
  /// Bernilai [EventMedia.empty] bila event belum punya media.
  EventMedia media;

  KonserModel({
    required this.id,
    required this.judul,
    required this.lokasi,
    required this.tanggal,
    required this.harga,
    required this.genre,
    this.gambarUrl = '',
    this.deskripsi,
    this.penyelenggara,
    this.status = AppConstants.eventStatusUpcoming,
    this.views = 0,
    this.media = EventMedia.empty,
  });

  factory KonserModel.fromMap(Map<String, dynamic> map, String id) {
    return KonserModel(
      id: id,
      judul: map['judul'] ?? '',
      lokasi: map['lokasi'] ?? '',
      tanggal: (map['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now(),
      harga: (map['harga'] ?? 0.0).toDouble(),
      genre: List<String>.from(map['genre'] ?? []),
      gambarUrl: map['gambarUrl'] ?? '',
      deskripsi: map['deskripsi'],
      penyelenggara: map['penyelenggara'],
      status: map['status'] ?? AppConstants.eventStatusUpcoming,
      views: (map['views'] as num?)?.toInt() ?? 0,
      media: EventMedia.fromMap(map['media']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'judul': judul,
      'lokasi': lokasi,
      'tanggal': Timestamp.fromDate(tanggal),
      'harga': harga,
      'genre': genre,
      'gambarUrl': gambarUrl,
      'deskripsi': deskripsi,
      'penyelenggara': penyelenggara,
      'status': status,
      'views': views,
      'media': media.toMap(),
    };
  }

  String get formatHarga {
    if (harga == 0) return 'GRATIS';
    final formatted = harga
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }

  KonserModel copyWith({
    String? judul,
    String? lokasi,
    DateTime? tanggal,
    double? harga,
    List<String>? genre,
    String? gambarUrl,
    String? deskripsi,
    String? penyelenggara,
    String? status,
    int? views,
    EventMedia? media,
  }) {
    return KonserModel(
      id: id,
      judul: judul ?? this.judul,
      lokasi: lokasi ?? this.lokasi,
      tanggal: tanggal ?? this.tanggal,
      harga: harga ?? this.harga,
      genre: genre ?? this.genre,
      gambarUrl: gambarUrl ?? this.gambarUrl,
      deskripsi: deskripsi ?? this.deskripsi,
      penyelenggara: penyelenggara ?? this.penyelenggara,
      status: status ?? this.status,
      views: views ?? this.views,
      media: media ?? this.media,
    );
  }
}
