import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ============================================================================
/// PENJAGA FORM ADMIN
/// ============================================================================
///
/// Form admin adalah satu-satunya jalan masuk data ke sistem. Kesalahan di
/// sini tidak memunculkan error: nilainya tersimpan apa adanya dan baru
/// terasa akibatnya di layar pembeli — atau saat Midtrans menolak transaksi.
///
/// Yang dijaga:
///
/// 1. Harga konser/tiket tidak boleh nol atau negatif.
/// 2. Form promo tidak boleh crash saat kolom angka kosong.
/// 3. Diskon persentase tidak boleh di atas 100%.
/// 4. **ID dokumen promo = kode promo.** Backend mencari voucher dengan
///    `.doc(kode)`; kalau admin menyimpan dengan `.add()` (ID acak), kode
///    yang diketik pengguna tidak akan pernah ditemukan.
void main() {
  String baca(String path) {
    final f = File(path);
    expect(f.existsSync(), isTrue, reason: '$path tidak ditemukan');
    return f.readAsStringSync();
  }

  group('harga tidak boleh nol atau negatif', () {
    test('form konser menolak harga <= 0', () {
      final sumber = baca('lib/screens/admin/form_konser_screen.dart');
      expect(sumber, contains("if (n <= 0) return 'Harga harus lebih dari 0';"),
          reason: 'Harga nol membuat tiket gratis tanpa sengaja; harga '
              'negatif membuat total checkout negatif dan Midtrans menolak.');
    });

    test('form tiket menolak harga <= 0', () {
      final sumber = baca('lib/screens/admin/form_tiket_screen.dart');
      expect(sumber, contains("if (n <= 0)"));
      expect(sumber, contains("'Harga harus lebih dari 0'"));
    });

    test('form tiket menolak stok negatif', () {
      final sumber = baca('lib/screens/admin/form_tiket_screen.dart');
      expect(sumber, contains("if (n < 0)"));
      expect(sumber, contains("'Stok tidak boleh negatif'"));
    });
  });

  group('form promo tidak crash karena kolom kosong', () {
    test('minPembelian punya validator', () {
      final sumber = baca('lib/screens/admin/kelola_promo_screen.dart');
      // Kolom kosong harus diizinkan (berarti tanpa minimum), tapi bukan
      // teks sampah.
      expect(sumber, contains("if (teks.isEmpty) return null;"));
      expect(sumber, contains("'Masukkan angka yang valid'"));
    });

    test('jalur simpan memakai tryParse, bukan parse', () {
      final sumber = baca('lib/screens/admin/kelola_promo_screen.dart');
      expect(
        sumber,
        isNot(contains('double.parse(_nilaiCtrl.text.trim())')),
        reason: 'parse melempar FormatException di dalam try, sehingga '
            'tombol Simpan tampak tidak bereaksi tanpa pesan apa pun.',
      );
      expect(sumber, contains('double.tryParse(_nilaiCtrl.text.trim())'));
      expect(sumber, contains('int.tryParse(_maxPakaiCtrl.text.trim())'));
    });
  });

  group('batas nilai diskon', () {
    test('persentase di atas 100% ditolak', () {
      final sumber = baca('lib/screens/admin/kelola_promo_screen.dart');
      expect(sumber, contains("if (_tipe == 'percentage' && n > 100)"));
      expect(sumber, contains("'Maksimal 100%'"));
    });

    test('nilai diskon harus lebih dari 0', () {
      final sumber = baca('lib/screens/admin/kelola_promo_screen.dart');
      expect(sumber, contains("if (n == null || n <= 0) return 'Nilai tidak valid';"));
    });

    test('maks. pakai harus lebih dari 0', () {
      final sumber = baca('lib/screens/admin/kelola_promo_screen.dart');
      expect(sumber, contains("if (n == null || n <= 0) return 'Angka tidak valid';"));
    });
  });

  group('ID dokumen promo = kode promo', () {
    test('admin menyimpan dengan .doc(kode), bukan .add()', () {
      final sumber = baca('lib/screens/admin/kelola_promo_screen.dart');
      expect(
        sumber,
        contains('.doc(promo.kode)'),
        reason: 'Backend mencari voucher dengan .doc(kode). Kalau ID-nya '
            'acak, kode yang diketik pengguna selalu "tidak ditemukan".',
      );
      expect(
        sumber,
        isNot(contains(".collection('promo_codes')\n          .add(")),
        reason: '.add() membuat ID acak yang tidak bisa dicari lewat kode.',
      );
    });

    test('backend mencari voucher dengan doc id = kode', () {
      final sumber = baca('../soundwave-backend/server.js');
      expect(sumber, contains("db.collection('promo_codes').doc(kode)"));
    });

    test('klaim voucher memakai kode sebagai doc id', () {
      final sumber = baca('lib/services/database_service.dart');
      expect(
        sumber,
        contains('final kunci = promo.kode.trim().toUpperCase();'),
        reason: 'Kalau kunci klaim berbeda dari kunci pencarian backend, '
            'status voucher tidak pernah berubah menjadi TERPAKAI.',
      );
      expect(sumber, contains('.doc(kunci);'));
    });
  });

  group('penandaan terpakai mencakup voucher manual', () {
    test('kunci voucher diambil dari daftar ATAU kode manual', () {
      final sumber = baca('lib/screens/user/checkout_parts/checkout_logic.dart');
      expect(sumber, contains('_selectedClaim?.promoId ?? _voucherManual?.kode'));
    });

    test('dipanggil setelah pembayaran sukses', () {
      final sumber = baca('lib/screens/user/checkout_parts/checkout_logic.dart');
      expect(sumber, contains('unawaited(_markVoucherUsed());'));
    });
  });
}
