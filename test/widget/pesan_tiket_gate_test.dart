// Penjaga sumber: pilih dulu, baru pesan, di halaman detail konser
// Mengunci aturan alur pembelian:
//   1. Tombol "PILIH" di kartu jenis tiket hanya MEMILIH kategori —
//      tidak boleh membuka wizard pembayaran 3 langkah.
//   2. Tombol "PESAN TIKET" di bar bawah hanya aktif kalau user sudah
//      memilih jenis tiket yang kuotanya masih ada.
//   3. Tidak ada jalur lain yang bisa menembus gerbang itu.
// Test ini membaca sumber dan gagal kalau salah satunya balik lagi.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const String berkas = 'lib/screens/user/user_konser_detail_screen.dart';

  late String sumber;

  setUpAll(() {
    sumber = File(berkas).readAsStringSync();
  });

  test('tombol PILIH hanya memilih kategori, tidak membuka pembayaran', () {
    final int idx = sumber.indexOf('// Pilih hanya memilih jenis tiket');
    expect(idx, greaterThanOrEqualTo(0),
        reason: 'penanda komentar PILIH hilang — periksa blok kartu tiket');

    final String tombol = sumber.substring(idx, idx + 900);
    expect(tombol.contains('_kategoriDipilih = t.kategori'), isTrue,
        reason: 'PILIH harus menyimpan kategori yang dipilih');
    expect(tombol.contains('_bukaCheckout'), isFalse,
        reason: 'PILIH tidak boleh langsung membuka pembayaran');
    expect(tombol.contains('CheckoutScreen'), isFalse);
  });

  test('PESAN TIKET terkunci sampai ada jenis tiket yang dipilih', () {
    expect(sumber.contains('final bisaPesanTiket = tiketTerpilih != null && !tiketHabis;'),
        isTrue,
        reason: 'syarat tombol: sudah memilih DAN kuota masih ada');
    expect(sumber.contains('onPressed: bisaPesanTiket'), isTrue,
        reason: 'tombol harus mati (null) selama belum ada pilihan');
    expect(sumber.contains("'PILIH TIKET DULU'"), isTrue,
        reason: 'label tombol saat belum memilih');
    expect(sumber.contains("'Pilih jenis tiket dulu'"), isTrue,
        reason: 'petunjuk di bar bawah saat belum memilih');
    expect(sumber.contains('disabledBackgroundColor: AppColors.surfaceLight'),
        isTrue,
        reason: 'tombol mati harus kelihatan jelas tidak aktif');
  });

  test('_pesanTiket menolak pesanan tanpa pilihan / kuota habis', () {
    final int idx = sumber.indexOf('Future<void> _pesanTiket(');
    expect(idx, greaterThanOrEqualTo(0));
    final String badan = sumber.substring(idx, idx + 1400);

    expect(badan.contains('if (_kategoriDipilih == null)'), isTrue);
    expect(badan.contains("'Pilih jenis tiket dulu sebelum memesan'"), isTrue);
    expect(badan.contains('if (tiket.stok <= 0)'), isTrue);
    expect(badan.contains('sudah habis'), isTrue);
    expect(badan.contains('await _bukaCheckout(tiket)'), isTrue,
        reason: 'satu-satunya jalan ke pembayaran adalah lewat gerbang ini');
  });

  test('tidak ada jalur lain yang melompat ke pembayaran tanpa memilih', () {
    expect('_bukaCheckout('.allMatches(sumber).length, 2,
        reason: 'harus tepat 2: definisi + pemanggilan di dalam _pesanTiket');
    expect(sumber.contains('_bukaCheckout(daftarTiket'), isFalse,
        reason: 'panggilan lama dari kartu tiket harus hilang');
    expect(sumber.contains('_bukaCheckout(tickets'), isFalse,
        reason: 'panggilan lama ke CheckoutScreen harus hilang');
    expect(sumber.contains('() => _pesanTiket(daftarTiketSemua)'), isTrue,
        reason: 'satu-satunya pintu: tombol di bar bawah');
  });

  test('kategori terpilih dicari lewat helper yang sama di semua jalur', () {
    expect(sumber.contains('TiketKonserModel? _tiketUntukKategori('), isTrue);
    expect(sumber.contains('final tiketTerpilih = _tiketUntukKategori(daftarTiketSemua);'),
        isTrue,
        reason: 'status tombol memakai helper yang sama dengan _pesanTiket');
  });

  test('petunjuk "Pilih jenis tiket dulu" bisa disentuh ke tab TIKET', () {
    expect(sumber.contains('onTap: tiketTerpilih == null ? _keTabTiket : null'),
        isTrue,
        reason: 'petunjuk di bar bawah harus bisa ditekan selama belum memilih');
    expect(sumber.contains('void _keTabTiket()'), isTrue);
    expect(sumber.contains('_tabController.animateTo(1)'), isTrue,
        reason: 'tab TIKET ada di index 1');
    expect(sumber.contains('Icons.chevron_right_rounded'), isTrue,
        reason: 'penanda visual bahwa teks itu bisa disentuh');
    // Setelah user sudah memilih, petunjuk tidak lagi jadi tombol.
    expect(sumber.contains('tiketTerpilih == null ? _keTabTiket : null'), isTrue);
  });

  test('tab TIKET tetap di index 1 sesuai tujuan pintasan', () {
    final int idxTab = sumber.indexOf("Tab(text: 'TIKET')");
    expect(idxTab, greaterThanOrEqualTo(0));
    final String urutanTab = sumber.substring(
        sumber.indexOf('tabs: const ['), sumber.indexOf('tabs: const [') + 200);
    final int posTentang = urutanTab.indexOf("'TENTANG'");
    final int posTiket = urutanTab.indexOf("'TIKET'");
    expect(posTentang, greaterThanOrEqualTo(0));
    expect(posTiket, greaterThan(posTentang),
        reason: 'TIKET harus setelah TENTANG (index 1)');
    expect(urutanTab.contains("'DENAH VENUE'"), isFalse,
        reason: 'tab denah venue sudah dihapus');
  });
}
