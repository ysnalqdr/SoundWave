class TiketKonserModel {
  final String id;
  String idKonser;
  String judulKonser;
  String gambarKonser;
  String kategori;
  double harga;
  int stok;
  int terjual;
  String? deskripsi;
  int revisionCounter;

  TiketKonserModel({
    required this.id,
    required this.idKonser,
    required this.judulKonser,
    required this.gambarKonser,
    required this.kategori,
    required this.harga,
    required this.stok,
    this.terjual = 0,
    this.deskripsi,
    this.revisionCounter = 0,
  });

  factory TiketKonserModel.fromMap(Map<String, dynamic> map, String id) {
    return TiketKonserModel(
      id: id,
      idKonser: map['idKonser'] ?? '',
      judulKonser: map['judulKonser'] ?? '',
      gambarKonser: map['gambarKonser'] ?? '',
      kategori: map['kategori'] ?? '',
      harga: (map['harga'] ?? 0.0).toDouble(),
      stok: (map['stok'] as num?)?.toInt() ?? 0,
      terjual: (map['terjual'] as num?)?.toInt() ?? 0,
      deskripsi: map['deskripsi'],
      revisionCounter: (map['revisionCounter'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idKonser': idKonser,
      'judulKonser': judulKonser,
      'gambarKonser': gambarKonser,
      'kategori': kategori,
      'harga': harga,
      'stok': stok,
      'terjual': terjual,
      'deskripsi': deskripsi,
      'revisionCounter': revisionCounter,
    };
  }

  String get statusStok {
    if (stok == 0) return 'habis';
    if (stok <= 50) return 'hampir';
    return 'oke';
  }

  String get labelStok {
    if (stok == 0) return 'Habis Terjual';
    if (stok <= 50) return 'Hampir Habis';
    return 'Tersedia';
  }

  bool get isVVIP => kategori.toUpperCase().contains('VVIP');
  bool get isVIP => kategori.toUpperCase().contains('VIP') && !isVVIP;

  String get zonaVenue {
    if (isVVIP) return 'VVIP Royal Pass (Front Row)';
    if (isVIP) return 'VIP Premier (Center Stage)';
    if (kategori.toUpperCase().contains('FESTIVAL')) return 'Festival (Standing Area)';
    if (kategori.toUpperCase().contains('TRIBUN')) return 'Tribun (Seating Area)';
    return 'Reguler (Tribun Atas)';
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

  TiketKonserModel copyWith({
    String? idKonser,
    String? judulKonser,
    String? gambarKonser,
    String? kategori,
    double? harga,
    int? stok,
    int? terjual,
    String? deskripsi,
    int? revisionCounter,
  }) {
    return TiketKonserModel(
      id: id,
      idKonser: idKonser ?? this.idKonser,
      judulKonser: judulKonser ?? this.judulKonser,
      gambarKonser: gambarKonser ?? this.gambarKonser,
      kategori: kategori ?? this.kategori,
      harga: harga ?? this.harga,
      stok: stok ?? this.stok,
      terjual: terjual ?? this.terjual,
      deskripsi: deskripsi ?? this.deskripsi,
      revisionCounter: revisionCounter ?? this.revisionCounter,
    );
  }
}
