import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ============================================================================
/// PENJAGA REVISI USER (U1–U8)
/// ============================================================================
///
/// Aturan warna final:
///
/// | Peran | Warna |
/// |---|---|
/// | Uang (harga, pendapatan) | hijau |
/// | Status berhasil (AKTIF, APPROVED, tersedia) | hijau |
/// | Kendali (tombol, tab, radio, slider, step) | putih |
/// | Peringatan (PENDING) | sunset |
/// | Gagal (DIBATALKAN, REFUND GAGAL) | merah |
/// | Selesai (TERPAKAI, REFUND, KEDALUWARSA) | satu abu + ikon berbeda |
void main() {
  String baca(String path) {
    final f = File(path);
    expect(f.existsSync(), isTrue, reason: '$path tidak ditemukan');
    return f.readAsStringSync();
  }

  /// Bagian sumber di sekitar sebuah penanda.
  String sekitar(String sumber, String penanda, {int panjang = 400}) {
    final i = sumber.indexOf(penanda);
    expect(i, greaterThan(-1), reason: 'penanda "$penanda" tidak ditemukan');
    return sumber.substring(i, i + panjang);
  }

  group('U1 spinner di tombol putih harus gelap', () {
    test('spinner login memakai onAksi', () {
      final s = baca('lib/screens/auth/login_screen.dart');
      expect(sekitar(s, 'CircularProgressIndicator(', panjang: 600),
          contains('AppColors.onAksi'),
          reason: 'Spinner putih di tombol putih tidak terlihat — pengguna '
              'mengira aplikasi diam.');
    });

    test('tidak ada spinner putih di tombol putih', () {
      for (final f in [
        'lib/screens/admin/form_konser_screen.dart',
        'lib/screens/admin/profil_screen.dart',
      ]) {
        final s = baca(f);
        expect(s, isNot(contains('CircularProgressIndicator(\n                            color: Colors.white')),
            reason: '$f: spinner putih di tombol putih akan tak terlihat.');
      }
    });
  });

  group('U2 spinner cadangan tidak hijau', () {
    test('app_state_views memakai putih', () {
      final s = baca('lib/widgets/feedback/app_state_views.dart');
      expect(s, contains('color: AppColors.aksi'));
      expect(s, isNot(contains('color: AppColors.primary')));
    });

    test('diskon_saya tidak memaksa hijau', () {
      final s = baca('lib/screens/user/diskon_saya_screen.dart');
      expect(s, isNot(contains('AppColors.warnaHarga')));
    });

    test('progress bar dashboard tidak hijau', () {
      final s = baca('lib/screens/admin/dashboard_admin_screen.dart');
      expect(s, isNot(contains('AppColors.primary,\n              ),\n            ),')));
    });
  });

  group('U3 teks Jelajah putih', () {
    test('tagline, Konser spesial, Promo & diskon bukan hijau', () {
      final s = baca('lib/screens/user/user_explore_screen.dart');
      for (final teks in [
        'Feel the Pulse of Live Music',
        'Konser spesial',
        'Promo & diskon',
      ]) {
        final potongan = sekitar(s, teks, panjang: 250);
        expect(potongan, isNot(contains('AppColors.warnaHarga')),
            reason: '"$teks" bukan uang, tidak boleh hijau.');
      }
    });

    test('harga konser di Jelajah TETAP hijau', () {
      final s = baca('lib/screens/user/user_explore_screen.dart');
      final jumlah = 'AppColors.warnaHarga'.allMatches(s).length;
      expect(jumlah, greaterThanOrEqualTo(2),
          reason: 'dua harga konser harus tetap hijau');
    });
  });

  group('U4-U6 detail konser', () {
    test('hanya harga yang tersisa hijau', () {
      final s = baca('lib/screens/user/user_konser_detail_screen.dart');
      // 12 pemakaian -> tinggal 2 (harga di kartu & di tab tiket).
      expect('AppColors.warnaHarga'.allMatches(s).length, lessThanOrEqualTo(2),
          reason: 'ikon info, genre, tab, jadwal, syarat, tombol PILIH '
              'semua harus putih.');
    });

    test('badge genre memakai putih', () {
      final s = baca('lib/screens/user/user_konser_detail_screen.dart');
      final potongan = sekitar(s, 'widget.konser.genre.map', panjang: 700);
      expect(potongan, contains('AppColors.aksi'));
      expect(potongan, isNot(contains('AppColors.warnaHarga')));
    });

    test('mini player audio memakai putih', () {
      final s = baca('lib/widgets/media/audio_mini_player.dart');
      expect(s, isNot(contains('AppColors.primary')));
    });
  });

  group('U7 checkout: token dipisah', () {
    test('palet punya token aksi terpisah dari green', () {
      final s = baca('lib/screens/user/checkout/checkout_palette.dart');
      expect(s, contains('static const Color aksi = AppColors.aksi;'));
      expect(s, contains('static const Color green = AppColors.primary;'));
    });

    test('step indicator memakai aksi', () {
      final s = baca('lib/screens/user/checkout_parts/checkout_layout.dart');
      final potongan = sekitar(s, 'final active = i <= _currentStep', panjang: 900);
      expect(potongan, contains('SwCheckout.aksi'));
      expect(potongan, isNot(contains('SwCheckout.green')));
    });

    test('kartu metode pembayaran memakai aksi', () {
      final s = baca('lib/screens/user/checkout_parts/checkout_steps.dart');
      expect(s, isNot(contains('selected ? SwCheckout.green')));
    });

    test('status berhasil di checkout TETAP hijau', () {
      final s = baca('lib/screens/user/checkout_parts/checkout_steps.dart');
      expect(s, contains('SwCheckout.green'),
          reason: 'centang sukses tidak boleh ikut jadi putih.');
    });
  });

  group('U8 tiket saya', () {
    test('tipe tiket putih', () {
      final s = baca('lib/screens/user/user_tiket_screen.dart');
      final potongan = sekitar(s, 'item.kategoriTiket.toUpperCase()', panjang: 250);
      expect(potongan, contains('AppColors.aksi'));
      expect(potongan, isNot(contains('AppColors.warnaHarga')));
    });

    test('tombol Pesan Ulang putih', () {
      final s = baca('lib/widgets/kotak_pending_tiket.dart');
      expect(s, contains('backgroundColor: AppColors.aksi'));
      expect(s, contains('foregroundColor: AppColors.onAksi'));
    });

    test('badge ganda hanya di detail, tidak di daftar', () {
      final s = baca('lib/screens/user/user_tiket_screen.dart');
      final kartu = s.indexOf('Widget _buildKartuTiket(');
      final sheet = s.indexOf('Widget _buildSheet(');
      expect(kartu, greaterThanOrEqualTo(0));
      expect(sheet, greaterThan(kartu));

      final isiKartu = s.substring(kartu, sheet);
      expect(isiKartu, isNot(contains("_buildBadgeStatus('REFUND_REJECTED')")),
          reason: 'di daftar cukup satu badge status.');

      // Di detail tetap ada.
      final isiSheet = s.substring(sheet);
      expect(isiSheet, contains("_buildBadgeStatus('REFUND_REJECTED')"));
    });
  });

  group('badge: status selesai satu warna, beda ikon', () {
    test('TERPAKAI / REFUND / KEDALUWARSA memakai nada selesai', () {
      final s = baca('lib/widgets/badge_status.dart');
      expect(s, contains('BadgeNada.selesai'));
      expect(s, contains("teks: 'TERPAKAI'"));
      expect(s, contains("teks: 'REFUND'"));
      expect(s, contains("teks: 'KEDALUWARSA'"));
    });

    test('AKTIF hijau, PENDING sunset', () {
      final s = baca('lib/widgets/badge_status.dart');
      final aktif = sekitar(s, "case 'AKTIF':", panjang: 200);
      expect(aktif, contains('BadgeNada.valid'));
      final pending = sekitar(s, "case 'PENDING':", panjang: 250);
      expect(pending, contains('BadgeNada.peringatan'));
    });
  });

  group('U9-U10 revisi ronde 2', () {
    test('U9: sortir harga tidak ditimpa urutan tanggal', () {
      final s = baca('lib/screens/user/user_explore_screen.dart');
      // Urutan tanggal hanya boleh dipakai saat pengguna tidak memilih
      // sortir harga.
      expect(
        s,
        contains("if (_selectedPriceSort == 'Semua') {"),
        reason: 'tanpa syarat ini, pilihan Termurah/Termahal ditimpa dan '
            'filter harga terasa tidak berfungsi.',
      );
      // Variabel mati yang tidak pernah diisi harus hilang.
      expect(s, isNot(contains('if (_minPrice != null')));
      expect(s, isNot(contains('double? _minPrice;')));
    });

    test('U10: label tema dibatasi satu baris', () {
      final s = baca('lib/widgets/promo/promo_card.dart');
      final i = s.indexOf('labelTampil,');
      expect(i, greaterThan(-1));
      // maxLines harus muncul dekat label.
      final sekitar = s.substring(i, i + 250);
      expect(sekitar, contains('maxLines: 1'));
    });

    test('U10: wadah kartu punya ruang aman', () {
      final s = baca('lib/screens/user/user_explore_screen.dart');
      expect(s, contains('height: 208'));
      expect(s, isNot(contains('height: 200,')),
          reason: '200px menyisakan overflow 1px pada kartu tertentu.');
    });
  });
}
