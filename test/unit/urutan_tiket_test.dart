// ═══════════════════════════════════════════════════════════════════
// URUTAN KATEGORI TIKET: VVIP -> VIP -> Festival -> Tribun -> Reguler
// ═══════════════════════════════════════════════════════════════════
// Sebelum ini daftar tiket diurutkan menurut harga, sehingga kategori bisa
// bertukar posisi (VIP murah tampil di atas VVIP). Test ini mengunci aturan
// baru: peringkat kategori lebih dulu, harga hanya penentu kedua.

import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/constants/app_constants.dart';
import 'package:soundwave/models/tiket_konser_model.dart';
import 'package:soundwave/utils/urutan_tiket.dart';

TiketKonserModel tiket(String kategori, double harga) => TiketKonserModel(
      id: 't-$kategori',
      idKonser: 'k1',
      judulKonser: 'SnapFest',
      gambarKonser: '',
      kategori: kategori,
      harga: harga,
      stok: 10,
    );

void main() {
  test('urutan kategori resmi berjenjang dari VVIP sampai Reguler', () {
    expect(AppConstants.ticketCategories, [
      'VVIP',
      'VIP',
      'Festival',
      'Tribun',
      'Reguler',
    ]);
    for (var i = 0; i < AppConstants.ticketCategories.length; i++) {
      expect(
        AppConstants.peringkatKategori(AppConstants.ticketCategories[i]),
        i,
        reason: 'peringkat ${AppConstants.ticketCategories[i]} harus $i',
      );
    }
  });

  test('kategori tak dikenal tetap dapat tempat, di bawah kategori resmi', () {
    expect(
      AppConstants.peringkatKategori('Platinum'),
      AppConstants.ticketCategories.length,
    );
    expect(AppConstants.peringkatKategori(' vip '), 1,
        reason: 'spasi dan huruf besar/kecil tidak boleh mengubah peringkat');
  });

  test('daftar tiket tersusun VVIP, VIP, Festival, Tribun, Reguler', () {
    final daftar = [
      tiket('Reguler', 150000),
      tiket('VIP', 900000),
      tiket('Tribun', 300000),
      tiket('VVIP', 1750000),
      tiket('Festival', 500000),
    ];

    urutkanTiket(daftar);

    expect(
      daftar.map((t) => t.kategori).toList(),
      ['VVIP', 'VIP', 'Festival', 'Tribun', 'Reguler'],
    );
  });

  test('harga tidak bisa membalik urutan kategori', () {
    // VIP sengaja dibuat paling murah: dulu ini yang membuat VIP naik ke atas.
    final daftar = [
      tiket('VVIP', 100000),
      tiket('VIP', 1000),
      tiket('Festival', 500000),
    ];

    urutkanTiket(daftar);

    expect(daftar.first.kategori, 'VVIP',
        reason: 'VVIP harus tetap di atas walau harganya paling murah');
    expect(daftar.map((t) => t.kategori).toList(),
        ['VVIP', 'VIP', 'Festival']);
  });

  test('kategori asing ditaruh paling bawah, termahal lebih dulu', () {
    final daftar = [
      tiket('Platinum', 200000),
      tiket('Reguler', 150000),
      tiket('Platinum', 900000),
    ];

    urutkanTiket(daftar);

    expect(daftar.first.kategori, 'Reguler');
    expect(daftar[1].harga, 900000);
    expect(daftar[2].harga, 200000);
  });
}
