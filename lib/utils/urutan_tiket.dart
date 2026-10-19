import '../constants/app_constants.dart';
import '../models/tiket_konser_model.dart';

/// Mengurutkan tiket: VVIP, VIP, Festival, Tribun, Reguler.
///
/// Peringkat diambil dari `AppConstants.ticketCategories`, bukan dari harga,
/// sehingga urutan tidak bergeser karena ada harga promo. Kategori yang
/// belum terdaftar tidak dibuang, hanya ditaruh paling bawah.
void urutkanTiket(List<TiketKonserModel> tiket) {
  tiket.sort((a, b) {
    final peringkatA = AppConstants.peringkatKategori(a.kategori);
    final peringkatB = AppConstants.peringkatKategori(b.kategori);
    if (peringkatA != peringkatB) return peringkatA.compareTo(peringkatB);

    final selisihHarga = b.harga.compareTo(a.harga);
    if (selisihHarga != 0) return selisihHarga;

    return a.kategori.compareTo(b.kategori);
  });
}
