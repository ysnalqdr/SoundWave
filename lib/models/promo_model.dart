import 'package:cloud_firestore/cloud_firestore.dart';

/// Model kode promo untuk diskon checkout.
/// Disimpan di koleksi Firestore `promo_codes`.
class PromoCodeModel {
  final String id;
  final String kode;
  final String tipe; // 'percentage' | 'fixed'
  final double nilai;
  final String? idKonser;
  final double minPembelian;
  final int maxPakai;
  final int sudahDipakai;
  final DateTime berlakuMulai;
  final DateTime berlakuAkhir;
  final bool aktif;
  final String? deskripsi;

  PromoCodeModel({
    required this.id,
    required this.kode,
    required this.tipe,
    required this.nilai,
    this.idKonser,
    this.minPembelian = 0,
    this.maxPakai = 100,
    this.sudahDipakai = 0,
    required this.berlakuMulai,
    required this.berlakuAkhir,
    this.aktif = true,
    this.deskripsi,
  });

  factory PromoCodeModel.fromMap(Map<String, dynamic> map, String id) {
    return PromoCodeModel(
      id: id,
      kode: map['kode'] ?? '',
      tipe: map['tipe'] ?? 'percentage',
      nilai: (map['nilai'] ?? 0.0).toDouble(),
      idKonser: map['idKonser'],
      minPembelian: (map['minPembelian'] ?? 0.0).toDouble(),
      maxPakai: (map['maxPakai'] as num?)?.toInt() ?? 100,
      sudahDipakai: (map['sudahDipakai'] as num?)?.toInt() ?? 0,
      berlakuMulai: _parseDateTime(map['berlakuMulai']) ?? DateTime.now(),
      berlakuAkhir: _parseDateTime(map['berlakuAkhir']) ??
          DateTime.now().add(const Duration(days: 30)),
      aktif: map['aktif'] ?? true,
      deskripsi: map['deskripsi'],
    );
  }

  /// Defensive parse tanggal: menerima Timestamp, DateTime, int (epoch ms),
  /// atau String (ISO-8601 / epoch). Mencegah crash
  /// `type 'String' is not a subtype of type 'Timestamp?'`.
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    if (value is String) {
      final s = value.trim();
      if (s.isEmpty) return null;
      final parsed = DateTime.tryParse(s);
      if (parsed != null) return parsed;
      final ms = int.tryParse(s);
      if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'kode': kode,
      'tipe': tipe,
      'nilai': nilai,
      'idKonser': idKonser,
      'minPembelian': minPembelian,
      'maxPakai': maxPakai,
      'sudahDipakai': sudahDipakai,
      'berlakuMulai': Timestamp.fromDate(berlakuMulai),
      'berlakuAkhir': Timestamp.fromDate(berlakuAkhir),
      'aktif': aktif,
      'deskripsi': deskripsi,
    };
  }

  /// Hitung nominal diskon berdasarkan tipe & subtotal.
  /// - percentage: subtotal * (nilai / 100)
  /// - fixed: nilai (tidak melebihi subtotal)
  /// Mengembalikan 0 jika subtotal < minPembelian.
  double discountAmount(double subtotal) {
    if (subtotal < minPembelian) return 0;
    if (tipe == 'percentage') {
      final raw = subtotal * (nilai / 100);
      return raw > subtotal ? subtotal : raw;
    }
    return nilai > subtotal ? subtotal : nilai;
  }

  /// Valid ketika aktif, dalam masa berlaku, dan kuota belum habis.
  bool get isValid =>
      aktif &&
      DateTime.now().isAfter(berlakuMulai) &&
      DateTime.now().isBefore(berlakuAkhir) &&
      sudahDipakai < maxPakai;

  /// Label singkat nilai diskon, mis. "10%" atau "Rp 25.000".
  String get labelNilai => tipe == 'percentage'
      ? '${nilai.toStringAsFixed(0)}%'
      : 'Rp ${nilai.toStringAsFixed(0)}';

  PromoCodeModel copyWith({
    String? id,
    String? kode,
    String? tipe,
    double? nilai,
    String? idKonser,
    double? minPembelian,
    int? maxPakai,
    int? sudahDipakai,
    DateTime? berlakuMulai,
    DateTime? berlakuAkhir,
    bool? aktif,
    String? deskripsi,
  }) {
    return PromoCodeModel(
      id: id ?? this.id,
      kode: kode ?? this.kode,
      tipe: tipe ?? this.tipe,
      nilai: nilai ?? this.nilai,
      idKonser: idKonser ?? this.idKonser,
      minPembelian: minPembelian ?? this.minPembelian,
      maxPakai: maxPakai ?? this.maxPakai,
      sudahDipakai: sudahDipakai ?? this.sudahDipakai,
      berlakuMulai: berlakuMulai ?? this.berlakuMulai,
      berlakuAkhir: berlakuAkhir ?? this.berlakuAkhir,
      aktif: aktif ?? this.aktif,
      deskripsi: deskripsi ?? this.deskripsi,
    );
  }
}
