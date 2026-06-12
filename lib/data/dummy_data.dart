import '../models/konser_model.dart';
import '../models/tiket_konser_model.dart';
import '../models/user_model.dart';

class DummyData {

  //!Data Admin (Sekarang bisa diubah isinya melalui Form Registrasi)
  static UserModel? adminUser = UserModel(
    id: 'admin-001',
    nama: 'Admin SoundWave',
    email: 'admin@soundwave.id',
    role: 'admin',

  );

  //!Data Konser
  static List<KonserModel> daftarKonser = [
    KonserModel(
      id: 'konser-001',
      judul: 'Test',
      lokasi: 'Gelora Bung Karno, Jakarta',
      tanggal: DateTime(2025, 3, 15, 19, 0),
      harga: 850000,
      genre: 'Pop Rock',
      gambarUrl: 'assets/images/konser/Test.jpg',
      deskripsi: 'Coldplay World Tour 2025 menghadirkan pengalaman spektakuler yang menggabungkan musik, seni, dan teknologi ramah lingkungan.',
      penyelenggara: 'Live Nation Indonesia',
    ),
    KonserModel(
      id: 'konser-002',
      judul: 'Dua Lipa • Future Nostalgia Tour',
      lokasi: 'Bali International Stadium',
      tanggal: DateTime(2025, 4, 22, 20, 0),
      harga: 1000000,
      genre: 'Pop',
      gambarUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSGzXnCwhc5o0TWICMjm5Lc9rEVTUCVV5Y-XQ&s',
      deskripsi: 'Dua Lipa Future Nostalgia Tour hadir di Bali membawa semua hit terbesar dalam satu malam penuh energi.',
      penyelenggara: 'Promotor Bali Events',
    ),
    KonserModel(
      id: 'konser-003',
      judul: 'Linkin Park • Reunion World Tour',
      lokasi: 'Grand City Convex, Surabaya',
      tanggal: DateTime(2025, 6, 1, 19, 30),
      harga: 500000,
      genre: 'Rock',
      gambarUrl: 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=600',
      deskripsi: 'Linkin Park Reunion World Tour adalah momen bersejarah yang ditunggu jutaan penggemar.',
      penyelenggara: 'Rajawali Indonesia Concert',
    ),
    KonserModel(
      id: 'konser-004',
      judul: 'BTS • Yet To Come World Tour',
      lokasi: 'Stadion Si Jalak Harupat, Bandung',
      tanggal: DateTime(2025, 7, 20, 18, 0),
      harga: 1500000,
      genre: 'K-Pop',
      gambarUrl: 'https://images.unsplash.com/photo-1506157786151-b8491531f063?w=600',
      deskripsi: 'BTS Yet To Come World Tour menghadirkan K-Pop paling epik.',
      penyelenggara: 'Big Hit Entertainment',
    ),
    KonserModel(
      id: 'konser-005',
      judul: 'The Weeknd • After Hours Tour',
      lokasi: 'Medan Convention Center',
      tanggal: DateTime(2025, 8, 9, 20, 0),
      harga: 1200000,
      genre: 'R&B',
      gambarUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600',
      deskripsi: 'The Weeknd After Hours Tour menghadirkan atmosfer gelap dan elegan.',
      penyelenggara: 'Dyandra Entertainment',
    ),
  ];

  //!Data Tiket
  static List<TiketKonserModel> daftarTiket = [
    TiketKonserModel(
      id: 'tiket-001',
      idKonser: 'konser-001',
      judulKonser: 'Coldplay • Music of the Spheres',
      gambarKonser: 'assets/images/konser/Test.jpg',
      kategori: 'Festival',
      harga: 850000,
      stok: 500,
      deskripsi: 'Area festival, standing. Akses penuh ke semua zona publik.',
    ),
    TiketKonserModel(
      id: 'tiket-002',
      idKonser: 'konser-001',
      judulKonser: 'Coldplay • Music of the Spheres',
      gambarKonser: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=400',
      kategori: 'Tribun',
      harga: 1500000,
      stok: 300,
      deskripsi: 'Area tribun, kursi dengan nomor. View lebih baik.',
    ),
    TiketKonserModel(
      id: 'tiket-003',
      idKonser: 'konser-001',
      judulKonser: 'Coldplay • Music of the Spheres',
      gambarKonser: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=400',
      kategori: 'VIP',
      harga: 3000000,
      stok: 50,
      deskripsi: 'Area VIP terdekat dengan panggung. Termasuk goodie bag.',
    ),
    TiketKonserModel(
      id: 'tiket-004',
      idKonser: 'konser-002',
      judulKonser: 'Dua Lipa • Future Nostalgia Tour',
      gambarKonser: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400',
      kategori: 'Reguler',
      harga: 1000000,
      stok: 400,
      deskripsi: 'Tiket reguler, akses venue standar.',
    ),
    TiketKonserModel(
      id: 'tiket-005',
      idKonser: 'konser-002',
      judulKonser: 'Dua Lipa • Future Nostalgia Tour',
      gambarKonser: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400',
      kategori: 'VIP',
      harga: 3500000,
      stok: 20,
      deskripsi: 'Akses VIP lounge + meet and greet.',
    ),
    TiketKonserModel(
      id: 'tiket-006',
      idKonser: 'konser-003',
      judulKonser: 'Linkin Park • Reunion World Tour',
      gambarKonser: 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=400',
      kategori: 'Festival',
      harga: 500000,
      stok: 600,
      deskripsi: 'Standing area, akses penuh.',
    ),
    TiketKonserModel(
      id: 'tiket-007',
      idKonser: 'konser-003',
      judulKonser: 'Linkin Park • Reunion World Tour',
      gambarKonser: 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=400',
      kategori: 'VIP',
      harga: 2000000,
      stok: 0,
      deskripsi: 'Zona VIP + soundcheck experience.',
    ),
    TiketKonserModel(
      id: 'tiket-008',
      idKonser: 'konser-004',
      judulKonser: 'BTS • Yet To Come World Tour',
      gambarKonser: 'https://images.unsplash.com/photo-1506157786151-b8491531f063?w=400',
      kategori: 'Floor',
      harga: 1500000,
      stok: 800,
      deskripsi: 'Floor area, standing, paling dekat panggung.',
    ),
    TiketKonserModel(
      id: 'tiket-009',
      idKonser: 'konser-004',
      judulKonser: 'BTS • Yet To Come World Tour',
      gambarKonser: 'https://images.unsplash.com/photo-1506157786151-b8491531f063?w=400',
      kategori: 'Tribun A',
      harga: 2500000,
      stok: 150,
      deskripsi: 'Tribun A, kursi bernomor view premium.',
    ),
    TiketKonserModel(
      id: 'tiket-010',
      idKonser: 'konser-004',
      judulKonser: 'BTS • Yet To Come World Tour',
      gambarKonser: 'https://images.unsplash.com/photo-1506157786151-b8491531f063?w=400',
      kategori: 'VVIP',
      harga: 5000000,
      stok: 30,
      deskripsi: 'VVIP package: seat premium + exclusive merchandise.',
    ),
    TiketKonserModel(
      id: 'tiket-011',
      idKonser: 'konser-005',
      judulKonser: 'The Weeknd • After Hours Tour',
      gambarKonser: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400',
      kategori: 'Festival',
      harga: 1200000,
      stok: 350,
      deskripsi: 'Standing area utama.',
    ),
    TiketKonserModel(
      id: 'tiket-012',
      idKonser: 'konser-005',
      judulKonser: 'The Weeknd • After Hours Tour',
      gambarKonser: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400',
      kategori: 'VIP',
      harga: 4000000,
      stok: 80,
      deskripsi: 'VIP lounge akses + premium seat.',
    ),
  ];

  //*take tiket sesuai id
  static List<TiketKonserModel> ambilTiketPerKonser(String idKonser) {
    return daftarTiket.where((t) => t.idKonser == idKonser).toList();
  }

  //*create id unique
  static String buatId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}