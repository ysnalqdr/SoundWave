import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:soundwave/services/midtrans_service.dart';

/// Penjaga pemulihan alamat backend.
///
/// Latar belakang: 17 Okt 2026 keempat metode bayar gagal serentak karena APK
/// masih memakai alamat tunnel lama yang sudah mati (cache 10 menit). Test ini
/// mengunci empat perbaikan supaya tidak mundur lagi:
///   1. gagal koneksi -> cache dibuang, alamat dibaca ulang, dicoba sekali lagi
///   2. cache 10 menit -> 60 detik
///   3. tidak ada alamat tunnel mati yang ditanam di kode
///   4. pesan ke user ramah, bukan teks exception mentah
void main() {
  final berkas = File('lib/services/midtrans_service.dart');
  final checkout = File('lib/screens/user/checkout_screen.dart');

  group('midtrans_service.dart — sumber', () {
    late String isi;

    setUpAll(() {
      isi = berkas.readAsStringSync();
    });

    test('1. gagal koneksi membuang cache lalu mencoba ulang sekali', () {
      final mulai = isi.indexOf('Future<http.Response> _kirim(');
      expect(mulai, greaterThan(-1), reason: '_kirim harus ada');

      // ambil badan _kirim sampai akhir method (penanda: pesanRamah berikutnya)
      var akhir = isi.indexOf('static String pesanRamah', mulai);
      if (akhir < 0) akhir = isi.length;
      final badan = isi.substring(mulai, akhir);

      expect(badan, contains('lupakanCacheUrl()'),
          reason: 'cache harus dibuang saat koneksi gagal');
      expect(badan, contains('getBackendUrl(paksa: true)'),
          reason: 'alamat harus dibaca ulang dari Firestore');
      expect(badan, contains('_galatKoneksi'),
          reason: 'hanya galat jaringan yang memicu percobaan ulang');
      // dua percobaan: sekali(urlAwal) dan sekali(urlBaru)
      expect('sekali('.allMatches(badan).length, greaterThanOrEqualTo(3),
          reason: 'harus ada percobaan pertama + percobaan ulang');
    });

    test('2. cache alamat hanya 60 detik', () {
      expect(isi, contains('Duration(seconds: 60)'));
      expect(isi, isNot(contains('inMinutes < 10')),
          reason: 'cache 10 menit penyebab kegagalan 17 Okt');
    });

    test('3. tidak ada alamat tunnel mati yang ditanam', () {
      expect(isi, isNot(contains('_defaultBackendUrl')));
      expect(isi, isNot(contains('brother-barcelona-assigned-panels')),
          reason: 'alamat mati tidak boleh jadi cadangan');
      expect(isi, contains('ServerTidakTerhubungException(pesanServerBelumSiap)'),
          reason: 'tanpa alamat sah harus berhenti dengan pesan jelas');
    });

    test('4. tidak ada pesan error mentah ke user', () {
      expect(RegExp(r"'Gagal[^']*: \$e'").hasMatch(isi), isFalse,
          reason: 'jangan tampilkan ClientException/SocketException');
      expect(isi, contains('Server pembayaran sedang tidak bisa dihubungi'));
      expect(isi, contains('_pesanGalat'));
    });

    test('semua panggilan http lewat _kirim (alamat selalu segar)', () {
      expect(RegExp(r'await http\.(post|get|delete)\(').hasMatch(isi), isFalse,
          reason: 'panggilan langsung tidak ikut pemulihan alamat');
    });
  });

  group('checkout_screen.dart — pesan ramah', () {
    test('layar memakai MidtransService.pesanRamah', () {
      final isi = checkout.readAsStringSync();
      expect(isi, contains('MidtransService.pesanRamah'));
      expect(RegExp(r"'Gagal[^']*: \$e'").hasMatch(isi), isFalse);
    });
  });

  group('pesanRamah — perilaku', () {
    test('exception server mati tampil apa adanya', () {
      const e = ServerTidakTerhubungException();
      expect(MidtransService.pesanRamah(e, 'Gagal membuat Virtual Account'),
          MidtransService.pesanServerMati);
      expect(e.toString(), MidtransService.pesanServerMati);
      expect(e.toString(), isNot(contains('ClientException')));
      expect(e.toString(), isNot(contains('SocketException')));
    });

    test('galat jaringan dari package:http disamarkan', () {
      final e = http.ClientException(
          "Failed host lookup: 'x.trycloudflare.com' (OS Error: No address "
          'associated with hostname, errno = 7)');
      expect(MidtransService.pesanRamah(e, 'Gagal membuat QR QRIS'),
          MidtransService.pesanServerMati);
    });

    test('jawaban server yang tidak dikenali', () {
      expect(
          MidtransService.pesanRamah(
              const FormatException('Unexpected character'), 'Gagal'),
          contains('tidak dikenali'));
    });

    test('galat lain tetap menyebut langkah yang gagal', () {
      expect(MidtransService.pesanRamah(Exception('boom'), 'Gagal bayar'),
          'Gagal bayar. Coba lagi sebentar.');
    });

    test('tidak pernah memuat teks teknis', () {
      final contoh = [
        http.ClientException('SocketException: Connection refused'),
        Exception('boom'),
        const FormatException('bad json'),
        const ServerTidakTerhubungException(),
      ];
      for (final e in contoh) {
        final pesan = MidtransService.pesanRamah(e, 'Gagal');
        expect(pesan, isNot(contains('SocketException')));
        expect(pesan, isNot(contains('ClientException')));
        expect(pesan, isNot(contains('Exception:')));
        expect(jsonEncode(pesan), isNotEmpty);
      }
    });
  });
}
