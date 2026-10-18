import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

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
    );
  }
}
