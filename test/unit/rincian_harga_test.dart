import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/models/promo_model.dart';
import 'package:soundwave/utils/rincian_harga.dart';

/// Penjaga rumus harga checkout.
///
/// **Kenapa ini ada:** sampai Okt 2026, total dihitung dua kali dengan rumus
/// berbeda. Klien memakai `subtotal + 5000 - diskon`, backend memakai
/// `harga x jumlah + 5000` **tanpa diskon** lalu menimpa nilai klien.
/// Akibatnya voucher yang dipilih pembeli hilang saat pembayaran dimulai:
/// layar menampilkan satu angka, Midtrans menagih angka lain.
///
/// Tes ini mengunci rumus yang disepakati (Opsi A):
/// diskon dulu, baru pajak & layanan dihitung dari sisa.
void main() {
  group('urutan perhitungan — diskon dulu, pajak kemudian', () {
    test('tanpa diskon: angka lengkap', () {
      const r = RincianHarga(hargaSatuan: 500000, jumlah: 2);
      expect(r.subtotal, 1000000);
      expect(r.potongan, 0);
      expect(r.dasar, 1000000);
      expect(r.pajak, 100000); // 10%
      expect(r.layananPersen, 50000); // 5%
      expect(r.layananTetap, 5000);
      expect(r.totalBiaya, 155000);
      expect(r.total, 1155000);
    });

    test('dengan diskon: pajak & layanan ikut turun', () {
      const r = RincianHarga(
        hargaSatuan: 500000,
        jumlah: 2,
        diskon: 50000,
        kodePromo: 'EARLYBIRD50',
      );
      expect(r.subtotal, 1000000);
      expect(r.potongan, 50000);
      expect(r.dasar, 950000);
      expect(r.pajak, 95000); // 10% dari 950.000, bukan dari 1.000.000
      expect(r.layananPersen, 47500);
      expect(r.totalBiaya, 147500);
      expect(r.total, 1097500);
    });

    test('diskon menurunkan total lebih dari nilainya sendiri', () {
      // Karena pajak & layanan ikut dihitung dari dasar yang lebih kecil,
      // potongan Rp 50.000 menurunkan total sebesar Rp 57.500.
      const tanpa = RincianHarga(hargaSatuan: 500000, jumlah: 2);
      const dengan = RincianHarga(
        hargaSatuan: 500000,
        jumlah: 2,
        diskon: 50000,
      );
      expect(tanpa.total - dengan.total, 57500);
    });

    test('total = jumlah komponen yang sudah dibulatkan', () {
      // Kalau total dihitung dari angka pecahan lalu dibulatkan sekali,
      // hasilnya bisa beda 1 rupiah dari jumlah baris di layar. Itu yang
      // membuat "jumlah baris tidak sama dengan total" terlihat di struk.
      const r = RincianHarga(hargaSatuan: 333333, jumlah: 1);
      final jumlahBaris = r.dasar + r.pajak + r.layananPersen + r.layananTetap;
      expect(r.total, jumlahBaris);
      expect(r.total, 388333);
    });
  });

  group('batas aman', () {
    test('diskon tidak pernah melebihi subtotal', () {
      const r = RincianHarga(hargaSatuan: 100000, jumlah: 1, diskon: 500000);
      expect(r.potongan, 100000);
      expect(r.dasar, 0);
      expect(r.pajak, 0);
      expect(r.layananPersen, 0);
      // Biaya layanan tetap masih berlaku: transaksi tetap diproses.
      expect(r.total, 5000);
    });

    test('diskon negatif diabaikan', () {
      const r = RincianHarga(hargaSatuan: 100000, jumlah: 1, diskon: -25000);
      expect(r.potongan, 0);
      expect(r.dasar, 100000);
    });

    test('jumlah nol tidak menghasilkan angka negatif', () {
      const r = RincianHarga(hargaSatuan: 100000, jumlah: 0);
      expect(r.subtotal, 0);
      expect(r.dasar, 0);
      expect(r.total, 5000); // hanya biaya layanan tetap
    });
  });

  group('rincian yang ditampilkan', () {
    test('baris berurutan dan totalnya cocok', () {
      const r = RincianHarga(
        hargaSatuan: 500000,
        jumlah: 2,
        diskon: 50000,
        kodePromo: 'HEMAT50',
      );
      final baris = r.baris;

      expect(baris.first.label, 'Harga tiket');
      expect(baris.first.nilai, 1000000);
      expect(baris.last.label, 'Total bayar');
      expect(baris.last.tebal, isTrue);

      // Jumlah semua baris kecuali total = total.
      final jumlah = baris
          .where((b) => b.label != 'Total bayar')
          .fold<int>(0, (a, b) => a + b.nilai);
      expect(jumlah, r.total);
    });

    test('diskon tampil negatif dan menyebut kodenya', () {
      const r = RincianHarga(
        hargaSatuan: 100000,
        jumlah: 1,
        diskon: 20000,
        kodePromo: 'MEMBER20',
      );
      final diskon = r.baris.firstWhere((b) => b.label.startsWith('Diskon'));
      expect(diskon.nilai, -20000);
      expect(diskon.label, contains('MEMBER20'));
    });

    test('baris diskon tidak muncul bila tidak ada potongan', () {
      const r = RincianHarga(hargaSatuan: 100000, jumlah: 1);
      expect(r.baris.any((b) => b.label.startsWith('Diskon')), isFalse);
    });
  });

  group('konsisten dengan PromoCodeModel', () {
    PromoCodeModel promo({
      required String tipe,
      required double nilai,
      double minPembelian = 0,
    }) =>
        PromoCodeModel(
          id: 'p1',
          kode: 'UJI',
          tipe: tipe,
          nilai: nilai,
          minPembelian: minPembelian,
          maxPakai: 100,
          sudahDipakai: 0,
          berlakuMulai: DateTime.now().subtract(const Duration(days: 1)),
          berlakuAkhir: DateTime.now().add(const Duration(days: 1)),
          aktif: true,
        );

    test('persentase 10% dari subtotal 1 juta = 100 ribu', () {
      final p = promo(tipe: 'percentage', nilai: 10);
      final r = RincianHarga(
        hargaSatuan: 500000,
        jumlah: 2,
        diskon: p.discountAmount(1000000),
      );
      expect(r.potongan, 100000);
      expect(r.dasar, 900000);
      expect(r.total, 1040000); // 900.000 + 90.000 + 45.000 + 5.000
    });

    test('nominal tetap 75 ribu', () {
      final p = promo(tipe: 'fixed', nilai: 75000);
      final r = RincianHarga(
        hargaSatuan: 500000,
        jumlah: 2,
        diskon: p.discountAmount(1000000),
      );
      expect(r.potongan, 75000);
      expect(r.dasar, 925000);
      expect(r.total, 1068750); // 925.000 + 92.500 + 46.250 + 5.000
    });

    test('minimum belanja tidak terpenuhi = tidak ada potongan', () {
      final p = promo(tipe: 'fixed', nilai: 75000, minPembelian: 2000000);
      final r = RincianHarga(
        hargaSatuan: 500000,
        jumlah: 2,
        diskon: p.discountAmount(1000000),
      );
      expect(p.discountAmount(1000000), 0);
      expect(r.potongan, 0);
    });
  });

  group('baris rincian yang ditampilkan', () {
    test('urutan: harga, diskon, pajak, layanan %, layanan tetap, total', () {
      final r = RincianHarga(
        hargaSatuan: 500000,
        jumlah: 2,
        diskon: 75000,
        kodePromo: 'HEMAT',
      );
      final label = r.baris.map((b) => b.label).toList();
      expect(label, [
        'Harga tiket',
        'Diskon (HEMAT)',
        'Pajak hiburan 10%',
        'Biaya layanan 5%',
        'Biaya layanan tetap',
        'Total bayar',
      ]);
    });

    test('tanpa diskon, baris diskon tidak muncul', () {
      final r = RincianHarga(hargaSatuan: 100000, jumlah: 1);
      expect(r.baris.map((b) => b.label), isNot(contains('Diskon')));
    });

    test('diskon tampil negatif', () {
      final r = RincianHarga(
          hargaSatuan: 500000, jumlah: 2, diskon: 50000);
      final barisDiskon = r.baris.firstWhere((b) => b.label.startsWith('Diskon'));
      expect(barisDiskon.nilai, -50000);
    });

    test('hanya baris total yang tebal', () {
      final r = RincianHarga(hargaSatuan: 100000, jumlah: 1);
      final tebal = r.baris.where((b) => b.tebal).toList();
      expect(tebal.length, 1);
      expect(tebal.first.label, 'Total bayar');
    });

    test('jumlah semua baris (kecuali total) = total', () {
      final r = RincianHarga(
          hargaSatuan: 500000, jumlah: 2, diskon: 75000);
      final jumlahBaris = r.baris
          .where((b) => b.label != 'Total bayar')
          .fold<int>(0, (a, b) => a + b.nilai);
      expect(jumlahBaris, r.total);
    });

    test('nilai baris selalu bilangan bulat rupiah', () {
      // Tidak boleh ada pecahan yang membuat layar menampilkan .5
      final r = RincianHarga(hargaSatuan: 333333, jumlah: 3, diskon: 12345);
      for (final b in r.baris) {
        expect(b.nilai, isA<int>());
      }
    });
  });

    test('label tarif tidak menampilkan desimal', () {
      // `tarifPajakPersen` bertipe double. Interpolasi double di Dart
      // menghasilkan "10.0", sehingga labelnya pernah terbaca
      // "Pajak hiburan 10.0%" — terlihat seperti keluaran mesin.
      final r = RincianHarga(hargaSatuan: 100000, jumlah: 1);
      for (final b in r.baris) {
        expect(b.label, isNot(contains('.0')),
            reason: 'label "${b.label}" mengandung desimal');
      }
      expect(r.baris.map((b) => b.label), contains('Pajak hiburan 10%'));
      expect(r.baris.map((b) => b.label), contains('Biaya layanan 5%'));
    });

    test('dua baris biaya layanan bisa dibedakan namanya', () {
      // Dulu keduanya bernama "Biaya layanan" sehingga pembeli tidak tahu
      // mana yang persentase dan mana yang nominal tetap.
      final r = RincianHarga(hargaSatuan: 100000, jumlah: 1);
      final layanan =
          r.baris.where((b) => b.label.startsWith('Biaya layanan')).toList();
      expect(layanan.length, 2);
      expect(layanan.map((b) => b.label).toSet().length, 2);
    });
}
