import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ============================================================================
/// PENJAGA ALUR VOUCHER — klaim, simpan, pakai, tandai
/// ============================================================================
///
/// Alur yang dijaga:
///
/// 1. Kartu promo diketuk → lembaran ketentuan → tombol klaim di dalamnya.
/// 2. Kode manual yang lolos validasi **otomatis tersimpan** ke
///    `users/{uid}/claimed_promos`, sehingga muncul di "Diskon Saya".
/// 3. Saat dipakai, voucher — baik dari daftar maupun dari kode manual —
///    **ditandai terpakai**, supaya tidak bisa dipakai berulang dan tidak
///    terus tampil seolah masih tersedia.
/// 4. Halaman "Diskon Saya" memisahkan yang masih bisa dipakai dari yang
///    sudah lewat.
///
/// Semua ini adalah kabel antar-berkas yang tidak terlihat dari tipe data,
/// jadi diperiksa dengan membaca sumber.
void main() {
  String baca(String path) {
    final f = File(path);
    expect(f.existsSync(), isTrue, reason: '$path tidak ditemukan');
    return f.readAsStringSync();
  }

  // Repo backend berada di direktori terpisah dan tidak ikut di-clone oleh CI
  // repo aplikasi. Tes lintas-repo dilewati bila berkasnya tidak ada, supaya
  // CI tetap hijau tanpa kehilangan pemeriksaan saat dijalankan lokal.
  final backendAda = File('../soundwave-backend/server.js').existsSync();

  group('kartu promo → lembaran → klaim', () {
    test('kartu membuka lembaran, bukan langsung mengklaim', () {
      final kartu = baca('lib/widgets/promo/promo_card.dart');
      // Kartu hanya punya satu aksi: `onKetuk`.
      expect(kartu, contains('onKetuk'));
      expect(kartu, isNot(contains('onKlaim')));
    });

    test('tombol klaim ada di dalam lembaran', () {
      final lembar = baca('lib/widgets/promo/promo_lembar.dart');
      expect(lembar, contains("'Klaim Voucher'"));
      expect(lembar, contains('onKlaim'));
    });

    test('lembaran memuat tanggal berlaku dan ketentuan lain', () {
      final lembar = baca('lib/widgets/promo/promo_lembar.dart');
      for (final teks in [
        'Minimum belanja',
        'Masa berlaku',
        'Kuota',
        'Cara pakai',
        'Ketentuan lain',
      ]) {
        expect(lembar, contains(teks),
            reason: 'Lembaran harus memuat "$teks".');
      }
      // Tanggal kedaluwarsa harus tampil.
      expect(lembar, contains('berlakuAkhir'));
    });
  });

  group('kode manual otomatis tersimpan', () {
    test('checkout memanggil claimPromo setelah kode lolos validasi', () {
      final sumber = baca('lib/screens/user/checkout_screen.dart');
      expect(
        sumber,
        contains('.claimPromo(uid, promo)'),
        reason: 'Tanpa ini kode manual hanya dipakai sekali lalu menguap: '
            'tidak masuk Diskon Saya dan tidak pernah ditandai terpakai.',
      );
    });

    test('klaim hanya dilakukan bila backend menyatakan valid', () {
      final sumber = baca('lib/screens/user/checkout_screen.dart');
      // Harus ada gerbang `sah` sebelum blok klaim.
      final iSah = sumber.indexOf('final sah = hasil[\'valid\'] == true;');
      final iKlaim = sumber.indexOf('.claimPromo(uid, promo)');
      expect(iSah, greaterThan(-1));
      expect(iKlaim, greaterThan(iSah),
          reason: 'Klaim tidak boleh terjadi sebelum validasi lolos.');
    });

    test('voucher yang sudah ada tidak dianggap gagal', () {
      final sumber = baca('lib/screens/user/checkout_screen.dart');
      expect(
        sumber,
        contains("teks.contains('sudah ada')"),
        reason: 'Klaim ulang bukan kegagalan — voucher tetap bisa dipakai.',
      );
    });
  });

  group('voucher ditandai terpakai', () {
    test('voucher manual ikut ditandai, bukan hanya voucher dari daftar', () {
      final sumber = baca('lib/screens/user/checkout_parts/checkout_logic.dart');
      expect(
        sumber,
        contains('_selectedClaim?.promoId ?? _voucherManual?.kode'),
        reason: 'Voucher manual akan tetap berstatus TERSEDIA selamanya '
            'dan bisa dipakai berulang.',
      );
    });

    test('state voucher dibersihkan setelah dipakai', () {
      final sumber = baca('lib/screens/user/checkout_parts/checkout_logic.dart');
      expect(sumber, contains('_voucherManual = null;'));
    });
  });

  group('backend mengirim data promo lengkap untuk auto-claim', () {
    test('validate-promo mengembalikan objek promo utuh', () {
      final sumber = baca('../soundwave-backend/server.js');
      expect(sumber, contains('promo: {'));
      // Field yang wajib ada, kalau tidak voucher tersimpan jadi cacat.
      for (final field in [
        'berlakuMulai: keIso(',
        'berlakuAkhir: keIso(',
        'minPembelian:',
        'maxPakai:',
      ]) {
        expect(sumber, contains(field),
            reason: 'Tanpa $field, voucher tersimpan tanpa syarat.');
      }
    });

    test('klien meneruskan objek promo dari respons backend', () {
      final sumber = baca('lib/services/midtrans_service.dart');
      expect(sumber, contains("'promo': data['promo']"));
    });
  }, skip: backendAda ? false : 'repo ../soundwave-backend tidak tersedia');

  group('Diskon Saya memisahkan voucher lewat', () {
    test('ada dua bagian: tersedia dan sudah dipakai', () {
      final sumber = baca('lib/screens/user/diskon_saya_screen.dart');
      expect(sumber, contains('final tersedia = list'));
      expect(sumber, contains('final lewat = list'));
      expect(sumber, contains("'Voucher saya'"));
      expect(sumber, contains("'Sudah dipakai'"));
    });

    test('voucher lewat tetap ditampilkan, tidak dihapus', () {
      final sumber = baca('lib/screens/user/diskon_saya_screen.dart');
      // Kedua kelompok dirender.
      expect(sumber, contains('for (final c in tersedia)'));
      expect(sumber, contains('for (final c in lewat)'));
    });
  });
}
