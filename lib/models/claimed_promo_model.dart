import 'package:cloud_firestore/cloud_firestore.dart';

/// Voucher yang sudah diklaim user.
///
/// Disimpan di `users/{userId}/claimed_promos/{promoId}`, docId = promoId,
/// jadi klaim ganda tidak menghasilkan dokumen dobel. Nilai diskon
/// di-snapshot saat klaim supaya tidak berubah walau admin mengedit promo.
class ClaimedPromoModel {
  final String promoId;
  final String kode;
  final String tipe; // 'percentage' | 'fixed'
  final double nilai;
  final double minPembelian;
  final String? deskripsi;
  final DateTime? berlakuAkhir;
  final DateTime claimedAt;
  final bool used;
  final DateTime? usedAt;
  final String? orderId;

  ClaimedPromoModel({
    required this.promoId,
    required this.kode,
    required this.tipe,
    required this.nilai,
    this.minPembelian = 0,
    this.deskripsi,
    this.berlakuAkhir,
    required this.claimedAt,
    this.used = false,
    this.usedAt,
    this.orderId,
  });

  factory ClaimedPromoModel.fromMap(Map<String, dynamic> map, String id) {
    return ClaimedPromoModel(
      promoId: (map['promoId'] as String?)?.isNotEmpty == true
          ? map['promoId'] as String
          : id,
      kode: (map['kode'] ?? '').toString(),
      tipe: (map['tipe'] ?? 'percentage').toString(),
      nilai: (map['nilai'] as num?)?.toDouble() ?? 0,
      minPembelian: (map['minPembelian'] as num?)?.toDouble() ?? 0,
      deskripsi: map['deskripsi'] as String?,
      berlakuAkhir: _parseDateTime(map['berlakuAkhir']),
      claimedAt: _parseDateTime(map['claimedAt']) ?? DateTime.now(),
      used: map['used'] == true,
      usedAt: _parseDateTime(map['usedAt']),
      orderId: map['orderId'] as String?,
    );
  }

  /// Defensive parse: Timestamp / DateTime / int(epoch) / String(ISO|epoch).
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
      'promoId': promoId,
      'kode': kode,
      'tipe': tipe,
      'nilai': nilai,
      'minPembelian': minPembelian,
      'deskripsi': deskripsi,
      'berlakuAkhir':
          berlakuAkhir == null ? null : Timestamp.fromDate(berlakuAkhir!),
      'claimedAt': Timestamp.fromDate(claimedAt),
      'used': used,
      'usedAt': usedAt == null ? null : Timestamp.fromDate(usedAt!),
      'orderId': orderId,
    };
  }

  /// Nominal diskon untuk subtotal tertentu.
  /// 0 bila subtotal di bawah minPembelian.
  double discountAmount(double subtotal) {
    if (subtotal < minPembelian) return 0;
    if (tipe == 'percentage') {
      final raw = subtotal * (nilai / 100);
      return raw > subtotal ? subtotal : raw;
    }
    return nilai > subtotal ? subtotal : nilai;
  }

  /// Masih bisa dipakai (belum terpakai & belum kedaluwarsa).
  bool get isUsable {
    if (used) return false;
    if (berlakuAkhir != null && DateTime.now().isAfter(berlakuAkhir!)) {
      return false;
    }
    return true;
  }

  /// Label singkat nilai diskon, mis. "10%" atau "Rp 25.000".
  String get labelNilai => tipe == 'percentage'
      ? '${nilai.toStringAsFixed(0)}%'
      : 'Rp ${nilai.toStringAsFixed(0)}';

  /// Status ringkas untuk UI.
  String get statusLabel {
    if (used) return 'TERPAKAI';
    if (berlakuAkhir != null && DateTime.now().isAfter(berlakuAkhir!)) {
      return 'KEDALUWARSA';
    }
    return 'TERSEDIA';
  }
}
