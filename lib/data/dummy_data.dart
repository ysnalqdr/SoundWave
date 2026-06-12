import '../models/konser_model.dart';
import '../models/tiket_konser_model.dart';
import '../models/user_model.dart';

class DummyData {
  //!Data Admin (Sekarang bisa diubah isinya melalui Form Registrasi)
  static UserModel? adminUser = UserModel(
    id: 'admin1',
    nama: 'Admin SoundWave',
    email: 'admin@soundwave.id',
    role: 'admin',
  );

//!Data Konser
  static List<KonserModel> daftarKonser = [
    KonserModel(
      id: 'konser1',
      judul: 'Hindia',
      lokasi: 'Gelora Bung Karno, Jakarta',
      tanggal: DateTime(2026, 7, 20, 19, 0),
      harga: 250000,
      genre: ['Pop', 'Rock', 'Indie'],
      gambarUrl: 'assets/images/konser/baskara.jpg',
      deskripsi:
          'Rayakan proses mendewasa dan hiruk-pikuk kehidupan bersama Hindia (Baskara Putra). Bersiaplah untuk sing-along massal lagu-lagu hits dari album Menari dengan Bayangan hingga Lagipula Hidup akan Berakhir dalam atmosfer konser yang intim, penuh katarsis, dan emosional.',
      penyelenggara: 'Yukie Wirapratama Channel',
    ),
    KonserModel(
      id: 'konser2',
      judul: 'Nadin Amizah',
      lokasi: 'Hall Senayan, Jakarta',
      tanggal: DateTime.now().add(const Duration(days: 30)),
      harga: 450000,
      genre: ['Indie', 'Pop'],
      gambarUrl: 'assets/images/konser/nadin.jpg',
      penyelenggara: 'Putra Rizky Channel',
      deskripsi:
          'Masuki dunia teatrikal dan puitis bersama Nadin Amizah. Rayakan keindahan untaian kata dalam pertunjukan musik yang intim, magis, dan penuh emosi mendalam khas Gen Z.',
    ),
    KonserModel(
      id: 'konser3',
      judul: 'Sal Priadi', // Sudah diperbaiki dengan spasi
      lokasi: 'Grand City Convex, Surabaya',
      tanggal: DateTime.now().add(const Duration(days: 60)),
      harga: 250000,
      genre: ['Pop', 'Indie'],
      gambarUrl: 'assets/images/konser/salpriadi.jpg',
      deskripsi:
          'Saksikan romansa puitis nan nyentrik dari Sal Priadi secara langsung. Bersiaplah hanyut dalam lantunan lirik ajaib bin magis yang penuh dengan tawa, haru, dan romantis khas Gen Z.',
      penyelenggara: 'Aqil Channel',
    ),
    KonserModel(
      id: 'konser4',
      judul: 'Juicy Luicy',
      lokasi: 'Stadion Si Jalak Harupat, Bandung',
      tanggal: DateTime.now().add(const Duration(days: 45)),
      harga: 500000,
      genre: ['Pop', 'Indie'],
      gambarUrl: 'assets/images/konser/juicyluicy.jpg',
      deskripsi:
          'Ruang aman untuk para sad boy dan sad girl! Mari bernyanyi bersama Juicy Luicy membawakan lagu-lagu galau sejuta umat seperti Lantas, Tanpa Tergesa, dan Asing dalam atmosfer yang sangat intim.',
      penyelenggara: 'Dzakiy Channel',
    ),
    KonserModel(
      id: 'konser5',
      judul: 'The Weeknd',
      lokasi: 'Gelora Bung Karno, Jakarta',
      tanggal: DateTime.now().add(const Duration(days: 5)),
      harga: 2500000,
      genre: ['R&B', 'Pop'],
      gambarUrl: 'assets/images/konser/theweeknd.jpg',
      deskripsi:
          'The Weeknd After Hours Tour menghadirkan atmosfer gelap, megah, dan elegan. Nyanyikan bersama hits global legendaris seperti Blinding Lights dan Starboy dalam panggung spektakuler.',
      penyelenggara: 'Laudya Entertainment',
    ),
  ];

  //!Data Tiket
  static List<TiketKonserModel> daftarTiket = [
    //TODO: KONSER HINDIA
    TiketKonserModel(
      id: 'tiket1',
      idKonser: 'konser1',
      judulKonser: 'Hindia',
      gambarKonser: 'assets/images/konser/baskara.jpg',
      kategori: 'Festival',
      harga: 250000,
      stok: 300,
      deskripsi:
          'Area festival (standing). Akses penuh ke area panggung utama.',
    ),
    TiketKonserModel(
      id: 'tiket2',
      idKonser: 'konser1',
      judulKonser: 'Hindia',
      gambarKonser: 'assets/images/konser/baskara.jpg',
      kategori: 'VVIP',
      harga: 1500000,
      stok: 50,
      deskripsi:
          'Area VIP terdepan + official merchandise pack dari Sun Eater.',
    ),

    //TODO: KONSER NADIN AMIZAH
    TiketKonserModel(
      id: 'tiket3',
      idKonser: 'konser2',
      judulKonser: 'Nadin Amizah',
      gambarKonser: 'assets/images/konser/nadin.jpg',
      kategori: 'Festival',
      harga: 450000,
      stok: 200,
      deskripsi: 'Area festival standing, dekat dengan panggung teatrikal.',
    ),
    TiketKonserModel(
      id: 'tiket4',
      idKonser: 'konser2',
      judulKonser: 'Nadin Amizah',
      gambarKonser: 'assets/images/konser/nadin.jpg',
      kategori: 'Tribun',
      harga: 350000,
      stok: 150,
      deskripsi:
          'Area tribun dengan kursi bernomor. Duduk santai menikmati pertunjukan.',
    ),

    //TODO: KONSER SAL PRIADI
    TiketKonserModel(
      id: 'tiket5',
      idKonser: 'konser3',
      judulKonser: 'Sal Priadi',
      gambarKonser: 'assets/images/konser/salpriadi.jpg',
      kategori: 'Reguler',
      harga: 250000,
      stok: 400,
      deskripsi: 'Akses standar venue, area standing umum.',
    ),
    TiketKonserModel(
      id: 'tiket6',
      idKonser: 'konser3',
      judulKonser: 'Sal Priadi',
      gambarKonser: 'assets/images/konser/salpriadi.jpg',
      kategori: 'VIP',
      harga: 600000,
      stok: 0,
      deskripsi: 'Akses VIP baris terdepan + exclusive soundcheck experience.',
    ),

    //TODO: KONSER JUICY LUICY
    TiketKonserModel(
      id: 'tiket7',
      idKonser: 'konser4',
      judulKonser: 'Juicy Luicy',
      gambarKonser: 'assets/images/konser/juicyluicy.jpg',
      kategori: 'Festival',
      harga: 500000,
      stok: 500,
      deskripsi:
          'Area festival utama, ruang aman untuk bernyanyi galau bersama.',
    ),
    TiketKonserModel(
      id: 'tiket8',
      idKonser: 'konser4',
      judulKonser: 'Juicy Luicy',
      gambarKonser: 'assets/images/konser/juicyluicy.jpg',
      kategori: 'Tribun',
      harga: 350000,
      stok: 250,
      deskripsi: 'Area duduk tribun Stadion Si Jalak Harupat.',
    ),

    //TODO: KONSER THE WEEKND
    TiketKonserModel(
      id: 'tiket9',
      idKonser: 'konser5',
      judulKonser: 'The Weeknd',
      gambarKonser: 'assets/images/konser/theweeknd.jpg',
      kategori: 'VIP',
      harga: 2500000,
      stok: 600,
      deskripsi:
          'Area lapangan utama (standing), sedekat mungkin dengan panggung neon megah.',
    ),
    TiketKonserModel(
      id: 'tiket10',
      idKonser: 'konser5',
      judulKonser: 'The Weeknd',
      gambarKonser: 'assets/images/konser/theweeknd.jpg',
      kategori: 'VVIP Package',
      harga: 5500000,
      stok: 40,
      deskripsi: 'Kursi VVIP premium + Limited Edition Tour Merchandise Box.',
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
