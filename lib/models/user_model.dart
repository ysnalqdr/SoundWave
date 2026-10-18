import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  String nama;
  String email;
  String role;
  String? fotoUrl;
  DateTime? createdAt;
  DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    this.fotoUrl,
    this.createdAt,
    this.updatedAt,
  });

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      nama: map['nama'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      fotoUrl: map['fotoUrl'],
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'email': email,
      'role': role,
      'fotoUrl': fotoUrl,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static const List<String> validRoles = ['user', 'admin', 'super_admin'];

  bool get isAdmin => role == 'admin' || role == 'super_admin';
  bool get isSuperAdmin => role == 'super_admin';
  bool get isOperasionalAdmin => role == 'admin';
  bool get hasKnownRole => validRoles.contains(role);

  /// Initials for avatar fallback when no fotoUrl is available
  String get initials {
    final parts = nama.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nama.isNotEmpty ? nama[0].toUpperCase() : '?';
  }

  UserModel copyWith({
    String? nama,
    String? fotoUrl,
    String? role,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id,
      nama: nama ?? this.nama,
      email: email,
      role: role ?? this.role,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
