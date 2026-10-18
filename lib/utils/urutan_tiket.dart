import '../constants/app_constants.dart';
import '../models/tiket_konser_model.dart';

/// Mengurutkan daftar tiket untuk ditampilkan: VVIP -> VIP -> Festival ->
/// Tribun -> Reguler.
///
/// Peringkat kategori diambil dari `AppConstants.ticketCategories`, bukan dari
/// harga. Harga hanya menjadi penentu KEDUA, sehingga urutan kategori tidak
/// pernah bergeser gara-gara ada harga promo yang lebih murah.
///
/// Kategori yang belum terdaftar (mis. 'Platinum') tidak dibuang: ia ditaruh di
/// bawah semua kategori resmi, diurutkan dari harga termahal.
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
