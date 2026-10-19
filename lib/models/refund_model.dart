import 'package:cloud_firestore/cloud_firestore.dart';

/// Permintaan refund tiket, disimpan di koleksi `refunds`.
class RefundModel {
  final String id;
  final String orderId;
  final String userId;
  final String alasan;
  final String status; // 'PENDING' | 'APPROVED' | 'REJECTED'
  final String? alasanReject;
  final DateTime tanggalRequest;
  final DateTime? tanggalProses;
  final double? refundAmount;
  final String kodeBooking;
  final String judulKonser;
  final String namaPembeli;
  final int jumlahTiket;
  final double totalHarga;

  RefundModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.alasan,
    this.status = 'PENDING',
    this.alasanReject,
    required this.tanggalRequest,
    this.tanggalProses,
    this.refundAmount,
    required this.kodeBooking,
    required this.judulKonser,
    required this.namaPembeli,
    required this.jumlahTiket,
    required this.totalHarga,
  });

  factory RefundModel.fromMap(Map<String, dynamic> map, String id) {
    return RefundModel(
      id: id,
      orderId: map['orderId'] ?? '',
      userId: map['userId'] ?? '',
      alasan: map['alasan'] ?? '',
      status: (map['status'] ?? 'PENDING').toString().toUpperCase(),
      alasanReject: map['alasanReject'],
      // Backend menulis `createdAt`, tapi dokumen lama memakai `tanggalRequest`.
      tanggalRequest: _parseDateTime(map['tanggalRequest']) ??
          _parseDateTime(map['createdAt']) ??
          DateTime.now(),
      tanggalProses: _parseDateTime(map['tanggalProses']) ??
          _parseDateTime(map['updatedAt']),
      // Backend menulis `amount`, tapi dokumen lama memakai `refundAmount`.
      refundAmount: (map['refundAmount'] as num?)?.toDouble() ??
          (map['amount'] as num?)?.toDouble(),
      kodeBooking: map['kodeBooking'] ?? '',
      judulKonser: map['judulKonser'] ?? '',
      namaPembeli: map['namaPembeli'] ?? '',
      jumlahTiket: (map['jumlahTiket'] as num?)?.toInt() ?? 0,
      totalHarga: (map['totalHarga'] as num?)?.toDouble() ??
          (map['amount'] as num?)?.toDouble() ??
          0.0,
    );
  }

  /// Defensive parse tanggal (Timestamp / DateTime / int / String ISO).
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
      'orderId': orderId,
      'userId': userId,
      'alasan': alasan,
      'status': status,
      'alasanReject': alasanReject,
      'tanggalRequest': Timestamp.fromDate(tanggalRequest),
      'tanggalProses': tanggalProses != null
          ? Timestamp.fromDate(tanggalProses!)
          : null,
      'refundAmount': refundAmount,
      'kodeBooking': kodeBooking,
      'judulKonser': judulKonser,
      'namaPembeli': namaPembeli,
      'jumlahTiket': jumlahTiket,
      'totalHarga': totalHarga,
    };
  }

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';

  RefundModel copyWith({
    String? status,
    String? alasanReject,
    DateTime? tanggalProses,
    double? refundAmount,
  }) {
    return RefundModel(
      id: id,
      orderId: orderId,
      userId: userId,
      alasan: alasan,
      status: status ?? this.status,
      alasanReject: alasanReject ?? this.alasanReject,
      tanggalRequest: tanggalRequest,
      tanggalProses: tanggalProses ?? this.tanggalProses,
      refundAmount: refundAmount ?? this.refundAmount,
      kodeBooking: kodeBooking,
      judulKonser: judulKonser,
      namaPembeli: namaPembeli,
      jumlahTiket: jumlahTiket,
      totalHarga: totalHarga,
    );
  }
}
