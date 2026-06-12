class TiketKonserModel {
  final String id;
  String idKonser;
  String judulKonser;
  String gambarKonser;
  String kategori;
  double harga;
  int stok;
  String? deskripsi;

  TiketKonserModel({
    required this.id,
    required this.idKonser,
    required this.judulKonser,
    required this.gambarKonser,
    required this.kategori,
    required this.harga,
    required this.stok,
    this.deskripsi,
  });

  //TODO: Status Stok
  //!badge sesaui stok
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

  //!Format Harga Ripiah
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
    String? deskripsi,
  }) {
    return TiketKonserModel(
      id: id,
      idKonser: idKonser ?? this.idKonser,
      judulKonser: judulKonser ?? this.judulKonser,
      gambarKonser: gambarKonser ?? this.gambarKonser,
      kategori: kategori ?? this.kategori,
      harga: harga ?? this.harga,
      stok: stok ?? this.stok,
      deskripsi: deskripsi ?? this.deskripsi,
    );
  }
}