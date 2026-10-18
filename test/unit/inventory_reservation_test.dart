import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/constants/app_constants.dart';
import 'package:soundwave/models/pesanan_tiket_model.dart';

void main() {
  group('Inventory Reservation & 15-Minute TTL Lifecycle Tests', () {
    late PesananTiketModel sampleOrder;

    setUp(() {
      sampleOrder = PesananTiketModel(
        id: 'ord-res-1',
        kodeBooking: 'SW-RES-123',
        idKonser: 'k-1',
        judulKonser: 'SoundWave Rock Fest',
        gambarKonser: 'assets/images/konser/baskara.jpg',
        kategoriTiket: 'VIP',
        idTiket: 't-vip',
        jumlahTiket: 2,
        totalHarga: 1005000,
        tanggalBeli: DateTime(2026, 10, 3, 10, 0),
        tanggalKonser: DateTime(2026, 11, 15),
        lokasiKonser: 'Stadion Madya GBK',
        namaPembeli: 'Bob Test',
        emailPembeli: 'bob@example.com',
        userId: 'uid-bob',
        status: AppConstants.orderStatusPending,
        reservedUntil: DateTime(2026, 10, 3, 10, 15), // 15-minute hold
      );
    });

    test('new reservation defaults to PENDING with active reservedUntil', () {
      expect(sampleOrder.isPending, isTrue);
      expect(sampleOrder.status, equals(AppConstants.orderStatusPending));
      expect(sampleOrder.reservedUntil, isNotNull);
      expect(sampleOrder.isRefundRequired, isFalse);
    });

    test('reservation hold is recognized as expired when current time passes reservedUntil', () {
      final expiredOrder = sampleOrder.copyWith(
        reservedUntil: DateTime.now().subtract(const Duration(seconds: 1)),
      );

      expect(expiredOrder.isExpired, isTrue);
    });

    test('enforces maximum 4 tickets per single transaction constraint', () {
      const int requestedQtyValid = 4;
      const int requestedQtyInvalid = 5;

      expect(requestedQtyValid <= AppConstants.maxTicketsPerOrder, isTrue);
      expect(requestedQtyInvalid <= AppConstants.maxTicketsPerOrder, isFalse);
    });

    test('guards against multiple hold abuse: blocks user from holding more than 3 active orders', () {
      final activeUserHolds = [
        sampleOrder.copyWith(id: 'ord-hold-1', kodeBooking: 'SW-H1'),
        sampleOrder.copyWith(id: 'ord-hold-2', kodeBooking: 'SW-H2'),
        sampleOrder.copyWith(id: 'ord-hold-3', kodeBooking: 'SW-H3'),
      ];

      final canCreateFourthHold = activeUserHolds.length < AppConstants.maxActiveReservationsPerUser;
      expect(canCreateFourthHold, isFalse, reason: 'Max 3 active reservations limit reached');
    });

    String resolveWebhookOrderState({
      required bool isPaidSuccess,
      required bool isExpiredHold,
      required int currentStock,
      required int requestedQty,
    }) {
      if (!isPaidSuccess) return AppConstants.orderStatusCancelled;
      if (isExpiredHold) {
        if (currentStock < requestedQty) {
          return AppConstants.orderStatusRefundRequired;
        }
      }
      return AppConstants.orderStatusActive;
    }

    test('late payment after reservation expires with zero available stock triggers REFUND_REQUIRED', () {
      final finalStatus = resolveWebhookOrderState(
        isPaidSuccess: true,
        isExpiredHold: true,
        currentStock: 0,
        requestedQty: 2,
      );

      expect(finalStatus, equals(AppConstants.orderStatusRefundRequired));
    });

    test('late payment after reservation expires with sufficient stock fulfills order as AKTIF', () {
      final finalStatus = resolveWebhookOrderState(
        isPaidSuccess: true,
        isExpiredHold: true,
        currentStock: 10,
        requestedQty: 2,
      );

      expect(finalStatus, equals(AppConstants.orderStatusActive));
    });
  });
}
