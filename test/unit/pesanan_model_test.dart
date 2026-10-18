import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/models/pesanan_tiket_model.dart';
import 'package:soundwave/constants/app_constants.dart';
import 'package:soundwave/services/midtrans_service.dart';

void main() {
  group('PesananTiketModel Lifecycle & Status Tests', () {
    test('default status is PENDING', () {
      final order = PesananTiketModel(
        id: 'ord-1',
        kodeBooking: 'SW-12345',
        idKonser: 'k1',
        judulKonser: 'Hindia Live',
        gambarKonser: 'assets/images/konser/baskara.jpg',
        kategoriTiket: 'Festival',
        jumlahTiket: 2,
        totalHarga: 505000,
        tanggalBeli: DateTime(2026, 10, 2),
        tanggalKonser: DateTime(2026, 12, 1),
        lokasiKonser: 'GBK Jakarta',
        namaPembeli: 'John Doe',
        emailPembeli: 'john@example.com',
        userId: 'uid-john',
      );

      expect(order.isPending, isTrue);
      expect(order.isAktif, isFalse);
      expect(order.isTerpakai, isFalse);
      expect(order.isCancelled, isFalse);
      expect(order.formatTotalHarga, equals('Rp 505.000'));
    });

    test('order status AKTIF evaluates isAktif to true', () {
      final order = PesananTiketModel(
        id: 'ord-2',
        kodeBooking: 'SW-67890',
        idKonser: 'k1',
        judulKonser: 'Hindia Live',
        gambarKonser: 'assets/images/konser/baskara.jpg',
        kategoriTiket: 'VVIP',
        jumlahTiket: 1,
        totalHarga: 1500000,
        tanggalBeli: DateTime(2026, 10, 2),
        tanggalKonser: DateTime(2026, 12, 1),
        lokasiKonser: 'GBK Jakarta',
        namaPembeli: 'Jane Doe',
        emailPembeli: 'jane@example.com',
        userId: 'uid-jane',
        status: AppConstants.orderStatusActive,
      );

      expect(order.isPending, isFalse);
      expect(order.isAktif, isTrue);
      expect(order.isTerpakai, isFalse);
    });

    test('order status TERPAKAI evaluates isTerpakai to true', () {
      final order = PesananTiketModel(
        id: 'ord-3',
        kodeBooking: 'SW-99999',
        idKonser: 'k1',
        judulKonser: 'Hindia Live',
        gambarKonser: 'assets/images/konser/baskara.jpg',
        kategoriTiket: 'Festival',
        jumlahTiket: 1,
        totalHarga: 250000,
        tanggalBeli: DateTime(2026, 10, 2),
        tanggalKonser: DateTime(2026, 12, 1),
        lokasiKonser: 'GBK Jakarta',
        namaPembeli: 'Gate Checker',
        emailPembeli: 'checker@example.com',
        userId: 'uid-checker',
        status: AppConstants.orderStatusUsed,
      );

      expect(order.isAktif, isFalse);
      expect(order.isTerpakai, isTrue);
    });

    test('order with snapToken and snapRedirectUrl preserves payment metadata', () {
      final order = PesananTiketModel(
        id: 'ord-4',
        kodeBooking: 'SW-SNAP-01',
        idKonser: 'k1',
        judulKonser: 'Hindia Live',
        gambarKonser: 'assets/images/konser/baskara.jpg',
        kategoriTiket: 'VIP',
        jumlahTiket: 1,
        totalHarga: 755000,
        tanggalBeli: DateTime(2026, 10, 2),
        tanggalKonser: DateTime(2026, 12, 1),
        lokasiKonser: 'GBK Jakarta',
        namaPembeli: 'Snap Tester',
        emailPembeli: 'snap@example.com',
        userId: 'uid-snap',
        snapToken: 'snap-token-abc-123',
        snapRedirectUrl: 'https://app.sandbox.midtrans.com/snap/v2/vtweb/snap-token-abc-123',
      );

      final map = order.toMap();
      expect(map['snapToken'], equals('snap-token-abc-123'));
      expect(map['snapRedirectUrl'], equals('https://app.sandbox.midtrans.com/snap/v2/vtweb/snap-token-abc-123'));
    });
  });

  group('MidtransService Transaction Status Mapping Tests', () {
    final midtrans = MidtransService();

    test('capture and settlement map to AKTIF', () {
      expect(midtrans.mapTransactionStatus('capture'), equals(AppConstants.orderStatusActive));
      expect(midtrans.mapTransactionStatus('settlement'), equals(AppConstants.orderStatusActive));
    });

    test('pending maps to PENDING', () {
      expect(midtrans.mapTransactionStatus('pending'), equals(AppConstants.orderStatusPending));
    });

    test('deny, cancel, and expire map to CANCELLED', () {
      expect(midtrans.mapTransactionStatus('deny'), equals(AppConstants.orderStatusCancelled));
      expect(midtrans.mapTransactionStatus('cancel'), equals(AppConstants.orderStatusCancelled));
      expect(midtrans.mapTransactionStatus('expire'), equals(AppConstants.orderStatusCancelled));
    });
  });
}
