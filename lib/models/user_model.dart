class UserModel {
  final String id;
  String nama;
  String email;
  String role;
  String nim;
  String namaKelompok;
  String? fotoUrl;

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    this.nim = '',
    this.namaKelompok = '',
    this.fotoUrl,
  });

  bool get isAdmin => role == 'admin';

  UserModel copyWith({
    String? nama,
    String? nim,
    String? namaKelompok,
    String? fotoUrl,
  }) {
    return UserModel(
      id: id,
      nama: nama ?? this.nama,
      email: email,
      role: role,
      nim: nim ?? this.nim,
      namaKelompok: namaKelompok ?? this.namaKelompok,
      fotoUrl: fotoUrl ?? this.fotoUrl,
    );
  }
}