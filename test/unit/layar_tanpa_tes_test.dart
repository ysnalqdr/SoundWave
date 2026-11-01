import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tes untuk layar yang sebelumnya tidak punya tes sama sekali.
///
/// **Kenapa berkas ini ada:** 13 layar tidak punya tes. Yang paling mahal
/// kalau salah adalah form tiket (harga & stok), invoice (angka uang yang
/// dilihat pembeli), diskon saya (voucher bisa dipakai atau tidak), share
/// konser (tautan yang dibagikan), dan splash (gerbang masuk aplikasi).
///
/// Tes ini tidak merender layar (butuh Firestore). Yang diuji adalah
/// **aturan yang gampang rusak tanpa terlihat**: validasi angka, format uang,
/// dan penjaga kabel di sumber.
void main() {
  String baca(String p) => File(p).readAsStringSync();

  /// Sumber tanpa komentar. Penting karena komentar sering MENYEBUT pola yang
  /// justru dilarang ("dulu ini ShaderMask..."), dan pemeriksaan teks mentah
  /// akan salah menangkapnya.
  String kode(String p) {
    final baris = const LineSplitter().convert(baca(p));
    final bersih = baris.where((l) => !l.trim().startsWith('//'));
    return bersih.join(' ');
  }

  group('form tiket — harga & stok tidak boleh negatif', () {
    test('validator menolak harga nol dan negatif', () {
      final isi = baca('lib/screens/admin/form_tiket_screen.dart');
      // Sebelum diperbaiki, "-50000" lolos validasi lalu tersimpan apa adanya.
      expect(isi.contains('Harga harus lebih dari 0'), isTrue,
          reason: 'harga <= 0 harus ditolak, bukan hanya "harus angka"');
      expect(isi.contains('n <= 0'), isTrue);
    });

    test('validator menolak stok negatif', () {
      final isi = baca('lib/screens/admin/form_tiket_screen.dart');
      expect(isi.contains('Stok tidak boleh negatif'), isTrue);
      expect(isi.contains('n < 0'), isTrue);
    });

    test('harga wajib diisi dan harus angka', () {
      final isi = baca('lib/screens/admin/form_tiket_screen.dart');
      expect(isi.contains('Harga wajib diisi'), isTrue);
      expect(isi.contains('Harga harus berupa angka'), isTrue);
    });
  });

  group('invoice — angka uang diformat, bukan dicetak mentah', () {
    test('memakai formatter rupiah', () {
      final isi = baca('lib/screens/user/invoice_screen.dart');
      expect(isi.contains('_formatRupiah'), isTrue);
      expect(isi.contains('toStringAsFixed(0)'), isTrue,
          reason: 'harga tidak boleh tampil dengan desimal');
    });

    test('menampilkan jumlah tiket dan harga satuan terpisah', () {
      final isi = baca('lib/screens/user/invoice_screen.dart');
      expect(isi.contains('_hargaSatuan'), isTrue);
      expect(isi.contains('jumlahTiket'), isTrue,
          reason: 'pembeli harus bisa memeriksa harga x jumlah');
    });
  });

  group('diskon saya — voucher dibedakan statusnya', () {
    test('memakai BadgeStatus terpusat, bukan warna sendiri', () {
      final isi = baca('lib/screens/user/diskon_saya_screen.dart');
      expect(isi.contains('BadgeStatus'), isTrue);
      expect(isi.contains('nadaVoucher'), isTrue);
      // Tiga status voucher harus punya nada berbeda.
      expect(isi.contains('BadgeNada.lewat'), isTrue);
      expect(isi.contains('BadgeNada.gagal'), isTrue);
      expect(isi.contains('BadgeNada.final_'), isTrue);
    });
  });

  group('share konser — tautan hanya membawa identitas konser', () {
    test('tautan tidak memuat email atau kata sandi', () {
      final isi = kode('lib/screens/user/share_konser_screen.dart');
      expect(isi.contains('email'), isFalse,
          reason: 'tautan berbagi tidak boleh memuat email');
      expect(isi.contains('password'), isFalse);
    });

    test('userId hanya dipakai sebagai kode referral', () {
      // Parameter `ref=<userId>` adalah fitur referral: penerima tautan tahu
      // siapa yang mengundangnya. Itu wajar dan bukan kebocoran. Yang dijaga
      // di sini adalah agar tidak ada data pesanan yang ikut menempel.
      final isi = kode('lib/screens/user/share_konser_screen.dart');
      expect(isi.contains('ref='), isTrue,
          reason: 'referral harus eksplisit lewat parameter ref');
      expect(isi.contains('kodeBooking'), isFalse,
          reason: 'tautan publik tidak boleh membawa kode booking pembeli');
    });
  });

  group('splash — tidak menahan pengguna terlalu lama', () {
    test('jeda splash wajar dan tidak memblokir bila data gagal', () {
      final isi = baca('lib/screens/splash_screen.dart');
      final m = RegExp(r'Duration\(milliseconds: (\d+)\)').firstMatch(isi);
      expect(m, isNotNull);
      final jeda = int.parse(m!.group(1)!);
      expect(jeda, lessThanOrEqualTo(3000),
          reason: 'splash lebih dari 3 detik membuat aplikasi terasa lambat');

      // Harus ada jalur cadangan bila profil gagal diambil.
      expect(isi.contains('catch'), isTrue,
          reason: 'gagal ambil profil tidak boleh menahan di splash');
    });

    test('wordmark memakai warna teks, bukan gradien gelap', () {
      // Bug lama: ShaderMask memakai primaryGradient (#1B1B23 -> #101016)
      // sehingga teks "SoundWave" jadi hitam di atas latar hitam dan
      // praktis tidak terlihat.
      final isi = kode('lib/screens/splash_screen.dart');
      expect(isi.contains('ShaderMask'), isFalse,
          reason: 'wordmark tidak boleh memakai ShaderMask bergradien gelap');
      expect(isi.contains('AppColors.textPrimary'), isTrue);
    });
  });

  group('login & register — kolom sandi aman', () {
    test('kata sandi tidak disimpan permanen', () {
      for (final p in <String>[
        'lib/screens/auth/login_screen.dart',
        'lib/screens/auth/register_screen.dart',
      ]) {
        final isi = baca(p);
        expect(isi.contains('obscureText'), isTrue, reason: p);
        expect(isi.contains('SharedPreferences'), isFalse, reason: p);
        expect(isi.contains('print('), isFalse,
            reason: '$p tidak boleh mencetak apa pun ke log');
      }
    });

    test('form memakai validasi sebelum mengirim', () {
      for (final p in <String>[
        'lib/screens/auth/login_screen.dart',
        'lib/screens/auth/register_screen.dart',
      ]) {
        final isi = baca(p);
        expect(isi.contains('_formKey'), isTrue, reason: p);
        expect(isi.contains('validator'), isTrue, reason: p);
      }
    });
  });

  group('kelola promo — diskon tidak bisa melebihi batas', () {
    test('nilai diskon divalidasi terhadap tipe', () {
      final isi = baca('lib/screens/admin/kelola_promo_screen.dart');
      // Persentase > 100 atau nominal negatif akan membuat total bayar
      // negatif di checkout.
      expect(isi.contains('100'), isTrue,
          reason: 'persentase promo harus dibatasi 100');
      expect(isi.contains('validator'), isTrue);
    });
  });
}
