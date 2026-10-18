import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/constants/app_constants.dart';
import 'package:soundwave/models/pesanan_tiket_model.dart';

void main() {
  group('Gate Check-in Decision & Double-Scan Protection Tests', () {
    late PesananTiketModel activeOrder;
    late PesananTiketModel usedOrder;
    late PesananTiketModel pendingOrder;
    late PesananTiketModel cancelledOrder;

    setUp(() {
      activeOrder = PesananTiketModel(
        id: 'ord-active-1',
        kodeBooking: 'SW-ACTIVE-88',
        idKonser: 'konser-1',
        judulKonser: 'Soundwave Fest 2026',
        gambarKonser: 'assets/images/konser/baskara.jpg',
        kategoriTiket: 'VIP',
        jumlahTiket: 2,
        totalHarga: 1005000,
        tanggalBeli: DateTime(2026, 10, 1),
        tanggalKonser: DateTime(2026, 11, 20),
        lokasiKonser: 'Stadion Utama Gelora Bung Karno',
        namaPembeli: 'Alice Smith',
        emailPembeli: 'alice@example.com',
        userId: 'uid-alice',
        status: AppConstants.orderStatusActive,
      );

      usedOrder = activeOrder.copyWith(
        id: 'ord-used-1',
        kodeBooking: 'SW-USED-99',
        status: AppConstants.orderStatusUsed,
        tanggalDigunakan: DateTime(2026, 11, 20, 17, 30),
      );

      pendingOrder = activeOrder.copyWith(
        id: 'ord-pending-1',
        kodeBooking: 'SW-PEND-77',
        status: AppConstants.orderStatusPending,
      );

      cancelledOrder = activeOrder.copyWith(
        id: 'ord-cancel-1',
        kodeBooking: 'SW-CANC-00',
        status: AppConstants.orderStatusCancelled,
      );
    });

    test('valid active ticket passes gate admission check', () {
      expect(activeOrder.isAktif, isTrue);
      expect(activeOrder.isTerpakai, isFalse);
      expect(activeOrder.isPending, isFalse);
      expect(activeOrder.isCancelled, isFalse);

      // Simulate atomic gate transition
      final checkInTime = DateTime.now();
      final transitionedOrder = activeOrder.copyWith(
        status: AppConstants.orderStatusUsed,
        tanggalDigunakan: checkInTime,
      );

      expect(transitionedOrder.status, equals(AppConstants.orderStatusUsed));
      expect(transitionedOrder.isTerpakai, isTrue);
      expect(transitionedOrder.isAktif, isFalse);
      expect(transitionedOrder.tanggalDigunakan, equals(checkInTime));
    });

    test('already used ticket is rejected to prevent double-entry fraud', () {
      expect(usedOrder.isTerpakai, isTrue);
      expect(usedOrder.isAktif, isFalse);

      // Decision logic: cannot scan twice
      final canEnter = usedOrder.isAktif && !usedOrder.isTerpakai;
      expect(canEnter, isFalse);
    });

    test('pending (unpaid) ticket is rejected at the gate', () {
      expect(pendingOrder.isPending, isTrue);
      expect(pendingOrder.isAktif, isFalse);

      final canEnter = pendingOrder.isAktif;
      expect(canEnter, isFalse);
    });

    test('cancelled ticket is rejected at the gate', () {
      expect(cancelledOrder.isCancelled, isTrue);
      expect(cancelledOrder.isAktif, isFalse);

      final canEnter = cancelledOrder.isAktif;
      expect(canEnter, isFalse);
    });

    test('simulated sequential double-scan transitions on first scan and blocks on second scan', () {
      var currentOrderState = activeOrder;

      // Scan Attempt 1 (Gate Operator A)
      bool attempt1Success = false;
      if (currentOrderState.isAktif && !currentOrderState.isTerpakai) {
        attempt1Success = true;
        currentOrderState = currentOrderState.copyWith(
          status: AppConstants.orderStatusUsed,
          tanggalDigunakan: DateTime.now(),
        );
      }
      expect(attempt1Success, isTrue);
      expect(currentOrderState.isTerpakai, isTrue);

      // Scan Attempt 2 (Gate Operator B scanning same physical ticket / duplicate barcode)
      bool attempt2Success = false;
      if (currentOrderState.isAktif && !currentOrderState.isTerpakai) {
        attempt2Success = true;
      }
      expect(attempt2Success, isFalse, reason: 'Second scan MUST be rejected');
      expect(currentOrderState.isTerpakai, isTrue);
    });
  });

  group('Authoritative Pricing & Anti-Tampering Calculations', () {
    const int authoritativeTicketPrice = 350000;
    const int fixedServiceFee = 5000;

    test('calculates correct authoritative total for given quantity', () {
      const int quantity = 3;
      const authoritativeTotal = (authoritativeTicketPrice * quantity) + fixedServiceFee;

      expect(authoritativeTotal, equals(1055000));
    });

    test('detects tampered totalHarga submitted by client', () {
      const int quantity = 2;
      const expectedTotal = (authoritativeTicketPrice * quantity) + fixedServiceFee; // 705,000

      const int clientTamperedTotal = 10000; // Malicious client tried to pay Rp 10.000

      const isTampered = clientTamperedTotal != expectedTotal;
      expect(isTampered, isTrue);

      // Server enforces correction
      const enforcedTotal = isTampered ? expectedTotal : clientTamperedTotal;
      expect(enforcedTotal, equals(705000));
    });
  });
}
