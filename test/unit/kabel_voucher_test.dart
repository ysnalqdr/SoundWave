import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ============================================================================
/// PENJAGA KABEL VOUCHER
/// ============================================================================
///
/// Dua bug nyata pernah lolos ke kode dan tidak tertangkap `flutter analyze`
/// maupun tes widget, karena keduanya bukan soal tampilan — keduanya soal
/// **angka yang dikirim ke backend**:
///
/// 1. Pesanan hanya membawa `_selectedClaim?.kode`, sehingga voucher yang
///    **diketik manual** menghasilkan potongan di layar tetapi backend
///    menagih harga penuh.
/// 2. Backend memakai kosakata tipe `persen`/`nominal` sementara aplikasi
///    menulis `percentage`/`fixed`, sehingga **voucher 50% dianggap potongan
///    Rp 50**.
///
/// Keduanya tidak terlihat sampai ada pembeli sungguhan. Tes ini membaca
/// berkas sumber dan memastikan kabelnya tetap tersambung.
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

  group('aplikasi mengirim voucher yang benar ke backend', () {
    test('pesanan membawa voucher aktif, bukan hanya voucher dari daftar', () {
      final sumber = baca('lib/screens/user/checkout_parts/checkout_logic.dart');

      // `_voucherAktif` mencakup voucher dari daftar klaim DAN kode manual.
      expect(
        sumber,
        contains('kodePromo: _voucherAktif?.kode'),
        reason: 'Kode voucher manual tidak akan terkirim ke backend, '
            'sehingga layar menampilkan potongan tapi tagihan tetap penuh.',
      );

      // Jangan kembali ke bentuk lama.
      expect(
        sumber,
        isNot(contains('kodePromo: _selectedClaim?.kode')),
        reason: 'Voucher manual akan hilang saat pembayaran dibuat.',
      );
    });

    test('potongan yang dikirim berasal dari RincianHarga', () {
      final sumber = baca('lib/screens/user/checkout_parts/checkout_logic.dart');
      expect(sumber, contains('diskon: _rincian.potongan.toDouble()'));
      expect(sumber, contains('pajak: _rincian.pajak.toDouble()'));
      expect(sumber, contains('subtotal: _rincian.subtotal.toDouble()'));
    });

    test('checkout memakai satu sumber angka, bukan hitungan sendiri', () {
      final sumber = baca('lib/screens/user/checkout_screen.dart');
      expect(sumber, contains('RincianHarga get _rincian'));
      // Konstanta biaya admin lokal dulu ada di sini dan berbeda dari
      // backend. Yang diperiksa adalah deklarasinya (`final double _biayaAdmin`),
      // bukan penyebutan namanya di komentar penjelasan.
      expect(
        sumber,
        isNot(contains('final double _biayaAdmin')),
        reason: 'Biaya layanan harus dihitung RincianHarga, bukan konstanta '
            'lokal yang bisa berbeda dari backend.',
      );
    });
  });

  group('backend memakai rumus dan kosakata yang sama', () {
    test('total dihitung dengan hitungRincianHarga', () {
      final sumber = baca('../soundwave-backend/server.js');
      expect(sumber, contains('hitungRincianHarga('));
      // Bentuk lama yang menghanguskan voucher.
      expect(
        sumber,
        isNot(contains('(authoritativePrice * orderData.jumlahTiket) + serviceFee')),
        reason: 'Rumus lama menimpa total klien tanpa diskon — voucher hangus.',
      );
    });

    test('tipe diskon dinormalkan sebelum dipakai', () {
      final sumber = baca('../soundwave-backend/server.js');
      expect(sumber, contains('normalkanTipe(promo.tipe)'));
      expect(
        sumber,
        isNot(contains("tipe === 'persen'")),
        reason: 'Dokumen aplikasi berisi "percentage", sehingga kondisi ini '
            'selalu gagal dan voucher 50% dipotong Rp 50.',
      );
    });

    test('rincian disimpan ke dokumen pesanan', () {
      final sumber = baca('../soundwave-backend/server.js');
      for (final field in [
        'subtotal:',
        'kodePromo:',
        'diskon:',
        'pajak:',
        'biayaLayananPersen:',
        'biayaLayananTetap:',
      ]) {
        expect(sumber, contains(field),
            reason: 'Field $field harus tersimpan supaya struk dan refund benar.');
      }
    });

    test('item_details Midtrans berjumlah sama dengan total', () {
      final sumber = baca('../soundwave-backend/server.js');
      // Diskon harus muncul sebagai item negatif, bukan dihilangkan.
      expect(sumber, contains("id: 'DISKON'"));
      expect(sumber, contains('price: -rincian.diskon'));
      expect(sumber, contains("id: 'PAJAK'"));
      expect(sumber, contains("id: 'LAYANAN-PERSEN'"));
      expect(sumber, contains("id: 'LAYANAN-TETAP'"));
    });

    test('kuota voucher bertambah saat pembayaran lunas', () {
      final sumber = baca('../soundwave-backend/server.js');
      expect(
        sumber,
        contains('sudahDipakai: admin.firestore.FieldValue.increment(1)'),
        reason: 'Tanpa ini voucher berkuota 10 bisa dipakai tanpa batas.',
      );
    });
  }, skip: backendAda ? false : 'repo ../soundwave-backend tidak tersedia');

  group('rumus Flutter dan backend memakai tarif yang sama', () {
    test('tarif pajak 10% dan layanan 5% di kedua sisi', () {
      final flutter = baca('lib/utils/rincian_harga.dart');
      final node = baca('../soundwave-backend/perhitungan_harga.js');

      expect(flutter, contains('tarifPajakPersen = 10'));
      expect(flutter, contains('tarifLayananPersen = 5'));
      expect(node, contains('TARIF_PAJAK_PERSEN = 10'));
      expect(node, contains('TARIF_LAYANAN_PERSEN = 5'));
      expect(flutter, contains('biayaLayananTetap = 5000'));
      expect(node, contains('BIAYA_LAYANAN_TETAP = 5000'));
    });
  }, skip: backendAda ? false : 'repo ../soundwave-backend tidak tersedia');
}
