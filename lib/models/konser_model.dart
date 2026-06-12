class KonserModel {
  final String id;
  String judul;
  String lokasi;
  DateTime tanggal;
  double harga;
  final List<String> genre; // Menggunakan List<String> untuk multi-genre
  String gambarUrl;
  String? deskripsi;
  String? penyelenggara;

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
  });

  // Getter untuk memformat harga ke dalam bentuk Rupiah (Rp)
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

  // Method copyWith untuk menduplikasi objek dengan perubahan data tertentu
  KonserModel copyWith({
    String? judul,
    String? lokasi,
    DateTime? tanggal,
    double? harga,
    List<String>? genre, // <-- Sudah diperbaiki menjadi List<String>?
    String? gambarUrl,
    String? deskripsi,
    String? penyelenggara,
  }) {
    return KonserModel(
      id: id,
      judul: judul ?? this.judul,
      lokasi: lokasi ?? this.lokasi,
      tanggal: tanggal ?? this.tanggal,
      harga: harga ?? this.harga,
      genre: genre ?? this.genre, // <-- Sinkron dengan parameter di atas
      gambarUrl: gambarUrl ?? this.gambarUrl,
      deskripsi: deskripsi ?? this.deskripsi,
      penyelenggara: penyelenggara ?? this.penyelenggara,
    );
  }
}