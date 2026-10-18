import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/models/konser_model.dart';
import 'package:soundwave/models/tiket_konser_model.dart';
import 'package:soundwave/constants/app_constants.dart';

void main() {
  group('Tahap C — Concert Filtering & Sorting Logic Tests', () {
    final now = DateTime.now();

    final testKonserList = [
      KonserModel(
        id: 'k1',
        judul: 'Bandung Pop Fest',
        lokasi: 'Trans Studio Mall, Bandung',
        tanggal: now.add(const Duration(days: 3)),
        harga: 250000,
        genre: ['Pop'],
      ),
      KonserModel(
        id: 'k2',
        judul: 'Jakarta Rock Revival',
        lokasi: 'Stadion Gelora Bung Karno, Jakarta',
        tanggal: now.add(const Duration(days: 15)),
        harga: 650000,
        genre: ['Rock'],
      ),
      KonserModel(
        id: 'k3',
        judul: 'Surabaya Electronic Night',
        lokasi: 'Jatim Expo, Surabaya',
        tanggal: now.add(const Duration(days: 45)),
        harga: 400000,
        genre: ['Electronic'],
      ),
      KonserModel(
        id: 'k4',
        judul: 'Yogyakarta Acoustic Vibes',
        lokasi: 'Prambanan, Yogyakarta',
        tanggal: now.add(const Duration(days: 1)),
        harga: 150000,
        genre: ['Indie'],
      ),
      KonserModel(
        id: 'k5',
        judul: 'Jakarta Metal Fest',
        lokasi: 'Tennis Indoor Senayan, Jakarta',
        tanggal: now.add(const Duration(days: 90)),
        harga: 900000,
        genre: ['Metal'],
      ),
    ];

    test('Filter Kota matches accurate location substring', () {
      final filteredJakarta = testKonserList.where((k) {
        return k.lokasi.toLowerCase().contains('jakarta');
      }).toList();

      expect(filteredJakarta.length, 2);
      expect(
          filteredJakarta.every((k) => k.lokasi.contains('Jakarta')), isTrue);

      final filteredBandung = testKonserList.where((k) {
        return k.lokasi.toLowerCase().contains('bandung');
      }).toList();
      expect(filteredBandung.length, 1);
      expect(filteredBandung.first.judul, 'Bandung Pop Fest');
    });

    test('Filter Tanggal 7 Hari Ke Depan correctly isolates upcoming concerts',
        () {
      final todayStart = DateTime(now.year, now.month, now.day);
      final end7 =
          todayStart.add(const Duration(days: 7, hours: 23, minutes: 59));

      final within7Days = testKonserList.where((k) {
        return k.tanggal
                .isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
            k.tanggal.isBefore(end7);
      }).toList();

      // k4 (1 day) and k1 (3 days) are within 7 days
      expect(within7Days.length, 2);
      final ids = within7Days.map((k) => k.id).toSet();
      expect(ids.contains('k1'), isTrue);
      expect(ids.contains('k4'), isTrue);
    });

    test('Filter Rentang Harga (Min & Max) limits results accurately', () {
      const minPrice = 300000.0;
      const maxPrice = 700000.0;

      final priceFiltered = testKonserList.where((k) {
        return k.harga >= minPrice && k.harga <= maxPrice;
      }).toList();

      // k2 (650000) and k3 (400000) match
      expect(priceFiltered.length, 2);
      expect(priceFiltered.any((k) => k.id == 'k2'), isTrue);
      expect(priceFiltered.any((k) => k.id == 'k3'), isTrue);
      expect(priceFiltered.any((k) => k.id == 'k1'), isFalse); // 250000 < min
      expect(priceFiltered.any((k) => k.id == 'k5'), isFalse); // 900000 > max
    });

    test('Sorting by Harga Terendah & Harga Tertinggi works reliably in-memory',
        () {
      final ascList = List<KonserModel>.from(testKonserList);
      ascList.sort((a, b) => a.harga.compareTo(b.harga));
      expect(ascList.first.harga, 150000); // k4
      expect(ascList.last.harga, 900000); // k5

      final descList = List<KonserModel>.from(testKonserList);
      descList.sort((a, b) => b.harga.compareTo(a.harga));
      expect(descList.first.harga, 900000); // k5
      expect(descList.last.harga, 150000); // k4
    });

    test('Sorting by Nama A-Z works alphabetically', () {
      final azList = List<KonserModel>.from(testKonserList);
      azList.sort(
          (a, b) => a.judul.toLowerCase().compareTo(b.judul.toLowerCase()));
      expect(azList.first.judul, 'Bandung Pop Fest');
      expect(azList.last.judul, 'Yogyakarta Acoustic Vibes');
    });
  });

  group('Tahap C — VIP and VVIP Venue Layout Separation Tests', () {
    test('AppConstants.ticketCategories contains both VIP and VVIP', () {
      expect(AppConstants.ticketCategories.contains('VIP'), isTrue);
      expect(AppConstants.ticketCategories.contains('VVIP'), isTrue);
    });

    test(
        'TiketKonserModel correctly identifies VVIP and VIP zones and formats labels',
        () {
      final vvipTicket = TiketKonserModel(
        id: 't_vvip',
        idKonser: 'k1',
        judulKonser: 'Konser Test',
        gambarKonser: 'https://example.com/poster.jpg',
        kategori: 'VVIP',
        harga: 1500000,
        stok: 50,
      );
      expect(vvipTicket.isVVIP, isTrue);
      expect(vvipTicket.isVIP, isFalse);
      expect(vvipTicket.zonaVenue, 'VVIP Royal Pass (Front Row)');

      final vipTicket = TiketKonserModel(
        id: 't_vip',
        idKonser: 'k1',
        judulKonser: 'Konser Test',
        gambarKonser: 'https://example.com/poster.jpg',
        kategori: 'VIP',
        harga: 1000000,
        stok: 100,
      );
      expect(vipTicket.isVVIP, isFalse);
      expect(vipTicket.isVIP, isTrue);
      expect(vipTicket.zonaVenue, 'VIP Premier (Center Stage)');

      // Legacy combined category compatibility
      final legacyTicket = TiketKonserModel(
        id: 't_legacy',
        idKonser: 'k1',
        judulKonser: 'Konser Test',
        gambarKonser: 'https://example.com/poster.jpg',
        kategori: 'VVIP & VIP PASS',
        harga: 1200000,
        stok: 20,
      );
      expect(legacyTicket.isVVIP, isTrue);
      expect(legacyTicket.zonaVenue, 'VVIP Royal Pass (Front Row)');
    });

    test(
        'Filter Kota matches legacy location text aliases (Jogja, DKI Jakarta)',
        () {
      final legacyConcerts = [
        KonserModel(
          id: 'l1',
          judul: 'Jogja Indie Fest',
          lokasi: 'Stadion Kridosono, Jogja',
          tanggal: DateTime.now(),
          harga: 100000,
          genre: ['Indie'],
        ),
        KonserModel(
          id: 'l2',
          judul: 'Jakarta Big Sound',
          lokasi: 'Ancol, DKI Jakarta',
          tanggal: DateTime.now(),
          harga: 500000,
          genre: ['Rock'],
        ),
      ];

      bool matchesTarget(String lokasi, String targetKota) {
        final lowerLokasi = lokasi.toLowerCase();
        final lowerTarget = targetKota.toLowerCase();
        if (lowerLokasi.contains(lowerTarget)) return true;
        if (lowerTarget == 'yogyakarta' &&
            (lowerLokasi.contains('jogja') || lowerLokasi.contains('diy'))) {
          return true;
        }
        if (lowerTarget == 'jakarta' && lowerLokasi.contains('dki')) {
          return true;
        }
        return false;
      }

      expect(matchesTarget(legacyConcerts[0].lokasi, 'Yogyakarta'), isTrue);
      expect(matchesTarget(legacyConcerts[1].lokasi, 'Jakarta'), isTrue);
    });
  });
}
