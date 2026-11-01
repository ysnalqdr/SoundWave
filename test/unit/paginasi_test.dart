import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Penjaga paginasi & biaya baca Firestore.
///
/// **Kenapa ini ada:** sampai Okt 2026, `getAllOrders()` memakai
/// `.snapshots()` tanpa `limit`. Artinya setiap kali dashboard admin dibuka,
/// **seluruh riwayat pesanan** diunduh ke HP lalu dihitung di memori. Pada
/// 5.000 pesanan itu ribuan pembacaan Firestore + perhitungan di UI thread:
/// dashboard terasa beku, dan kuota baca habis hanya untuk satu layar.
///
/// Perbaikannya dua lapis:
///   1. KPI memakai **agregasi** (`count()` / `sum()`) yang tidak mengunduh
///      dokumen sama sekali.
///   2. Grafik memakai **jendela 7 hari**, bukan seluruh riwayat.
///
/// Tes ini membaca sumber, karena menguji perilaku Firestore butuh emulator.
/// Yang dijaga bukan angka arahannya, melainkan **tidak kembalinya pola lama**.
void main() {
  late String service;

  setUpAll(() {
    service = File('lib/services/database_service.dart').readAsStringSync();
  });

  /// Mengambil badan sebuah method berdasarkan nama.
  /// Mengambil badan sebuah method berdasarkan nama.
  ///
  /// Tidak mencari penutup kurung kurawal: badan method di berkas ini punya
  /// blok bersarang (if, loop), jadi `}` pertama bukan akhir method. Yang
  /// dipakai adalah jendela tetap sampai deklarasi berikutnya.
  String badanMethod(String nama, {int panjang = 2600}) {
    final i = service.indexOf(nama);
    expect(i, greaterThanOrEqualTo(0), reason: '$nama tidak ditemukan');
    final batas = (i + panjang).clamp(0, service.length);
    return service.substring(i, batas);
  }

  group('setiap stream daftar punya batas', () {
    const daftar = <String, String>{
      'getAllEvents': 'katalog konser',
      'getAllTickets': 'katalog tiket',
      'getAllOrders': 'pesanan',
      'getPesananSejak': 'jendela grafik 7 hari',
    };

    daftar.forEach((nama, keterangan) {
      test('$nama ($keterangan) memakai .limit()', () {
        final badan = badanMethod(nama);
        expect(badan.contains('.limit('), isTrue,
            reason: '$nama mengunduh tanpa batas — pada data besar ini '
                'membekukan UI dan menghabiskan kuota baca');
      });
    });
  });

  group('dashboard memakai agregasi, bukan unduh-semua', () {
    test('ada method agregasi di service', () {
      expect(service.contains('getStatistikPesanan'), isTrue);
      expect(service.contains('.aggregate('), isTrue,
          reason: 'KPI harus memakai sum() di server');
      expect(service.contains('.count()'), isTrue,
          reason: 'KPI harus memakai count() di server');
    });

    test('dashboard TIDAK lagi memakai allOrdersProvider', () {
      // Kalau ini kembali, grafik akan mengunduh seluruh riwayat lagi.
      final layar =
          File('lib/screens/admin/dashboard_admin_screen.dart')
              .readAsStringSync();
      expect(layar.contains('allOrdersProvider'), isFalse,
          reason: 'dashboard harus memakai pesananTujuhHariProvider '
              'dan statistikPesananProvider');
      expect(layar.contains('pesananTujuhHariProvider'), isTrue);
      expect(layar.contains('statistikPesananProvider'), isTrue);
    });

    test('provider jendela 7 hari benar-benar membatasi rentang', () {
      final prov = File('lib/providers/app_providers.dart').readAsStringSync();
      expect(prov.contains('Duration(days: 7)'), isTrue,
          reason: 'jendela grafik harus tetap 7 hari');
    });
  });

  group('agregasi memakai field yang benar', () {
    test('sum() memakai totalHarga dan jumlahTiket', () {
      final badan = badanMethod('getStatistikPesanan');
      expect(badan.contains("sum('totalHarga')"), isTrue);
      expect(badan.contains("sum('jumlahTiket')"), isTrue);
    });

    test('count() memakai status yang sama dengan definisi "lunas"', () {
      // Kalau status di sini berbeda dari ringkasan_admin.dart, KPI dan grafik
      // akan saling bertentangan — dan itu jenis bug yang sulit dilihat.
      final badan = badanMethod('getStatistikPesanan');
      expect(badan.contains('orderStatusActive'), isTrue);
      expect(badan.contains('orderStatusUsed'), isTrue);
      expect(badan.contains('orderStatusPending'), isTrue);
      expect(badan.contains('orderStatusReserved'), isTrue);
    });
  });

  group('batas angka tetap wajar', () {
    test('batasMuatPesanan dan batasMuatKatalog masuk akal', () {
      final m = RegExp(r'batasMuatPesanan = (\d+)').firstMatch(service);
      final k = RegExp(r'batasMuatKatalog = (\d+)').firstMatch(service);
      expect(m, isNotNull);
      expect(k, isNotNull);

      final pesanan = int.parse(m!.group(1)!);
      final katalog = int.parse(k!.group(1)!);

      expect(pesanan, inInclusiveRange(200, 5000));
      expect(katalog, inInclusiveRange(100, 2000));
      // Katalog konser wajar lebih kecil dari riwayat pesanan.
      expect(katalog, lessThan(pesanan));
    });
  });
}
