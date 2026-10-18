import 'package:cloud_firestore/cloud_firestore.dart';

/// Notifikasi in-app milik seorang user.
///
/// Ditulis OTOMATIS oleh backend (`server.js` → `kirimNotifikasi`) setiap ada
/// kejadian penting — pembayaran berhasil, pembayaran batal, refund diajukan /
/// disetujui / ditolak. Tidak ada yang perlu diketik manual.
/// User membacanya di layar Jelajah → ikon lonceng.
///
/// Disimpan di koleksi global `notifications/{notifId}`, difilter `userId`.
class NotifikasiModel {
  final String id;
  final String userId;
  final String title;
  final String message;

  /// Jenis kejadian: payment_success | payment_cancelled | refund_requested |
  /// refund_approved | refund_rejected | refund_required | info
  final String type;

  /// Id dokumen terkait (biasanya id order) — dipakai untuk navigasi.
  final String? refId;
  final bool read;
  final DateTime createdAt;

  NotifikasiModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.type = 'info',
    this.refId,
    this.read = false,
    required this.createdAt,
  });

  factory NotifikasiModel.fromMap(Map<String, dynamic> map, String id) {
    return NotifikasiModel(
      id: id,
      userId: (map['userId'] ?? '').toString(),
      title: (map['title'] ?? 'Notifikasi').toString(),
      message: (map['message'] ?? '').toString(),
      type: (map['type'] ?? 'info').toString(),
      refId: map['refId']?.toString(),
      read: map['read'] == true,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
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

  bool get belumDibaca => !read;

  /// Label jenis untuk chip kecil di UI.
  String get jenisLabel {
    switch (type) {
      case 'payment_success':
      case 'payment_cancelled':
        return 'PEMBAYARAN';
      case 'refund_requested':
      case 'refund_approved':
      case 'refund_rejected':
      case 'refund_required':
        return 'REFUND';
      default:
        return 'INFO';
    }
  }

  static const List<String> _namaBulan = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  /// Umur notifikasi dalam bahasa manusia, mis. "baru saja" / "3 jam lalu".
  String get waktuRelatif {
    final selisih = DateTime.now().difference(createdAt);
    if (selisih.isNegative || selisih.inSeconds < 60) return 'baru saja';
    if (selisih.inMinutes < 60) return '${selisih.inMinutes} menit lalu';
    if (selisih.inHours < 24) return '${selisih.inHours} jam lalu';
    if (selisih.inDays < 7) return '${selisih.inDays} hari lalu';
    return '${createdAt.day} ${_namaBulan[createdAt.month - 1]} ${createdAt.year}';
  }
}
