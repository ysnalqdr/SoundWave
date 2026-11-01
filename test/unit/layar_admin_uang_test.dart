import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:soundwave/constants/app_constants.dart';
import 'package:soundwave/models/promo_model.dart';
import 'package:soundwave/models/refund_model.dart';
import 'package:soundwave/utils/app_theme.dart';

/// Tes untuk layar admin yang menyangkut uang: refund, promo, laporan, dan
/// manajemen pengguna.
///
/// **Kenapa empat layar ini dulu:** keempatnya tidak punya tes sama sekali
/// padahal menangani hal yang paling mahal kalau salah — menyetujui refund
/// (uang keluar), membuat promo (diskon salah = rugi), membaca laporan
/// (angka salah = keputusan salah), dan mengubah peran pengguna (member bisa
/// jadi admin).
///
/// Tes ini **tidak** merender layarnya (butuh Firestore). Yang diuji:
/// aturan model yang dipakai layar itu, dan penjaga kabel di berkas sumber
/// supaya aksi berbahaya tidak bisa diam-diam kehilangan konfirmasi.
/// Membaca berkas sumber. Dipakai untuk penjaga kabel: memeriksa bahwa
/// konfirmasi dan pola aman tidak hilang dari layar.
String baca(String path) => File(path).readAsStringSync();

void main() {
  group('RefundModel — status menentukan aksi yang boleh', () {
    RefundModel refund({String status = 'PENDING'}) => RefundModel(
          id: 'r1',
          orderId: 'o1',
          userId: 'u1',
          alasan: 'Tidak bisa hadir',
          status: status,
          tanggalRequest: DateTime(2026, 10, 20),
          kodeBooking: 'SW-2026-8812',
          judulKonser: 'Konser Uji',
          namaPembeli: 'Andi',
          jumlahTiket: 2,
          totalHarga: 1000000,
        );

    test('PENDING berarti belum diputuskan', () {
      final r = refund();
      expect(r.isPending, isTrue);
      expect(r.isApproved, isFalse);
      expect(r.isRejected, isFalse);
    });

    test('APPROVED dan REJECTED saling meniadakan', () {
      final setuju = refund(status: 'APPROVED');
      expect(setuju.isApproved, isTrue);
      expect(setuju.isPending, isFalse);
      expect(setuju.isRejected, isFalse);

      final tolak = refund(status: 'REJECTED');
      expect(tolak.isRejected, isTrue);
      expect(tolak.isApproved, isFalse);
      expect(tolak.isPending, isFalse);
    });

    test('status tidak dikenal tidak dianggap disetujui', () {
      // Kalau `isApproved` ditulis sebagai `!isRejected`, status aneh seperti
      // '' atau 'TYPO' akan lolos sebagai disetujui — dan uang keluar.
      final aneh = refund(status: 'ENTAH');
      expect(aneh.isApproved, isFalse);
      expect(aneh.isPending, isFalse);
      expect(aneh.isRejected, isFalse);
    });

    test('dokumen lama tanpa status dianggap PENDING, bukan disetujui', () {
      final lama = RefundModel.fromMap({
        'orderId': 'o1',
        'userId': 'u1',
        'kodeBooking': 'SW-1',
        'judulKonser': 'K',
        'namaPembeli': 'A',
        'jumlahTiket': 1,
        'totalHarga': 100000,
      }, 'r1');
      expect(lama.isPending, isTrue);
      expect(lama.isApproved, isFalse);
    });
  });

  group('PromoCodeModel — validitas menentukan diskon boleh dipakai', () {
    PromoCodeModel promo({
      required DateTime mulai,
      required DateTime akhir,
      int maxPakai = 10,
      int sudahDipakai = 0,
      bool aktif = true,
    }) =>
        PromoCodeModel(
          id: 'p1',
          kode: 'HEMAT',
          tipe: 'percentage',
          nilai: 10,
          idKonser: '',
          minPembelian: 0,
          maxPakai: maxPakai,
          sudahDipakai: sudahDipakai,
          berlakuMulai: mulai,
          berlakuAkhir: akhir,
          aktif: aktif,
        );

    final kini = DateTime.now();

    test('promo dalam masa berlaku dan kuota tersisa = valid', () {
      final p = promo(
        mulai: kini.subtract(const Duration(days: 1)),
        akhir: kini.add(const Duration(days: 1)),
      );
      expect(p.isValid, isTrue);
    });

    test('promo kedaluwarsa tidak valid', () {
      final p = promo(
        mulai: kini.subtract(const Duration(days: 10)),
        akhir: kini.subtract(const Duration(days: 1)),
      );
      expect(p.isValid, isFalse);
    });

    test('promo belum mulai tidak valid', () {
      final p = promo(
        mulai: kini.add(const Duration(days: 1)),
        akhir: kini.add(const Duration(days: 10)),
      );
      expect(p.isValid, isFalse);
    });

    test('kuota habis tidak valid meski tanggal masih berlaku', () {
      final p = promo(
        mulai: kini.subtract(const Duration(days: 1)),
        akhir: kini.add(const Duration(days: 1)),
        maxPakai: 5,
        sudahDipakai: 5,
      );
      expect(p.isValid, isFalse);
    });

    test('promo nonaktif tidak valid meski tanggal & kuota oke', () {
      final p = promo(
        mulai: kini.subtract(const Duration(days: 1)),
        akhir: kini.add(const Duration(days: 1)),
        aktif: false,
      );
      expect(p.isValid, isFalse);
    });

    test('label nilai mengikuti tipe promo', () {
      final persen = promo(
        mulai: kini.subtract(const Duration(days: 1)),
        akhir: kini.add(const Duration(days: 1)),
      );
      expect(persen.labelNilai, '10%');

      final nominal = PromoCodeModel(
        id: 'p2',
        kode: 'POTONG',
        tipe: 'fixed',
        nilai: 25000,
        idKonser: '',
        minPembelian: 0,
        maxPakai: 10,
        sudahDipakai: 0,
        berlakuMulai: kini.subtract(const Duration(days: 1)),
        berlakuAkhir: kini.add(const Duration(days: 1)),
        aktif: true,
      );
      expect(nominal.labelNilai, 'Rp 25000');
    });
  });

  group('penjaga kabel — aksi berbahaya tetap minta konfirmasi', () {
    test('menyetujui refund memakai dialog konfirmasi', () {
      final isi = baca('lib/screens/admin/kelola_refund_screen.dart');
      expect(isi.contains('_konfirmasiSetujui'), isTrue,
          reason: 'menyetujui refund mengeluarkan uang — harus dua langkah');
      expect(isi.contains('Setujui Refund?'), isTrue);
      expect(isi.contains('Tolak'), isTrue);

      // Tombol TIDAK boleh memanggil aksi uang secara langsung.
      expect(isi.contains('() => _approveRefund(refund)'), isFalse,
          reason: 'tombol harus lewat _konfirmasiSetujui, bukan langsung');
    });

    test('menonaktifkan promo memakai konfirmasi', () {
      final isi = baca('lib/screens/admin/kelola_promo_screen.dart');
      expect(isi.contains('showDialog'), isTrue);
      expect(isi.contains('nonaktifkanPromo') || isi.contains('_nonaktifkanPromo'),
          isTrue);
    });

    test('menghapus profil pengguna memakai konfirmasi', () {
      final isi = baca('lib/screens/admin/user_management_screen.dart');
      expect(isi.contains('showDialog'), isTrue,
          reason: 'menghapus profil tidak boleh sekali klik');
      expect(isi.contains('Hapus Profil Pengguna?'), isTrue);
    });
  });

  group('penjaga kabel — laporan tidak menghitung ulang dengan rumus sendiri', () {
    test('laporan memakai formatRupiah yang konsisten', () {
      for (final p in <String>[
        'lib/screens/admin/laporan_penjualan_screen.dart',
        'lib/screens/admin/laporan_revenue_screen.dart',
      ]) {
        final isi = baca(p);
        expect(isi.contains('_formatRupiah') || isi.contains('NumberFormat'),
            isTrue,
            reason: '$p harus memakai satu formatter, bukan sprintf manual');
      }
    });

    test('laporan memakai warna harga (hijau) untuk angka uang', () {
      // Hijau = uang. Kalau laporan memakai warna lain untuk pendapatan,
      // aturan tema itu hilang di layar yang paling butuh.
      final penjualan = baca('lib/screens/admin/laporan_penjualan_screen.dart');
      expect(penjualan.contains('AppColors.primary'), isTrue,
          reason: 'TOTAL PENDAPATAN harus hijau');
    });
  });

  group('penjaga kabel — layar auth tidak menyimpan kata sandi', () {
    test('login & register tidak menyimpan password ke variabel persisten', () {
      for (final p in <String>[
        'lib/screens/auth/login_screen.dart',
        'lib/screens/auth/register_screen.dart',
      ]) {
        final isi = baca(p);
        // Kata sandi hanya boleh hidup di controller yang dibuang saat layar
        // ditutup. Tidak boleh ada field statis atau penyimpanan ke disk.
        expect(isi.contains('static String') && isi.contains('password'),
            isFalse,
            reason: '$p tidak boleh menyimpan kata sandi di field statis');
        expect(isi.contains('SharedPreferences'), isFalse,
            reason: '$p tidak boleh menyimpan kata sandi ke preferensi');
      }
    });

    test('kolom kata sandi disembunyikan', () {
      for (final p in <String>[
        'lib/screens/auth/login_screen.dart',
        'lib/screens/auth/register_screen.dart',
      ]) {
        final isi = baca(p);
        expect(isi.contains('obscureText'), isTrue,
            reason: '$p harus menyembunyikan isi kolom kata sandi');
      }
    });
  });

  group('warna status tidak dipakai untuk hal yang salah', () {
    test('hijau hanya untuk uang, bukan untuk tombol di layar uang', () {
      // Layar laporan boleh memakai hijau untuk ANGKA. Tombolnya tetap putih.
      final isi = baca('lib/screens/admin/laporan_revenue_screen.dart');
      final baris = isi.split('\n');
      for (var i = 0; i < baris.length; i++) {
        final t = baris[i].trim();
        if (t.startsWith('//')) continue;
        expect(t.contains('backgroundColor: AppColors.primary'), isFalse,
            reason: 'baris ${i + 1}: tombol hijau di chrome admin');
      }
      expect(AppColors.primary.toARGB32(),
          isNot(AppColors.aksi.toARGB32()));
      expect(AppConstants.orderStatusActive, 'AKTIF');
    });
  });
}
