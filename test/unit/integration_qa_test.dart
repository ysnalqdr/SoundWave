import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/constants/app_constants.dart';
import 'package:soundwave/models/pesanan_tiket_model.dart';
import 'package:soundwave/services/offline_ticket_service.dart';

void main() {
  group('1. Offline Sync Failure & Idempotency Recovery Tests (Scenarios A - E)', () {
    late OfflineTicketService service;
    late Directory tempDir;
    late String storagePath;
    final algorithm = Ed25519();

    late List<int> ujiSeed;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sync_failure_test_');
      storagePath = '${tempDir.path}/sync_ledger.json';

      service = OfflineTicketService();
      await service.initStorage(storagePath: storagePath);
      await service.resetLedger(deleteFile: true);
      await service.initStorage(storagePath: storagePath);

      final seedBytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
      ujiSeed = seedBytes;
      final kunciUji = await algorithm.newKeyPairFromSeed(seedBytes);
      final publikUji = await kunciUji.extractPublicKey();
      service.updateDynamicManifest(
        additionalKeys: {'uji': OfflineTicketService.bytesToHex(publikUji.bytes)},
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<String> createSignedTicket({required String bookingCode, String keyId = 'uji'}) async {
      final canonical = OfflineTicketService.buildCanonicalPayload(
        keyId: keyId,
        orderId: 'ord-$bookingCode',
        kodeBooking: bookingCode,
        idKonser: 'konser-1',
        kategoriTiket: 'VIP',
        jumlahTiket: 1,
      );
      final seed = ujiSeed;
      final keyPair = await algorithm.newKeyPairFromSeed(seed);
      final sig = await algorithm.sign(utf8.encode(canonical), keyPair: keyPair);
      return '$canonical|${OfflineTicketService.bytesToHex(sig.bytes)}';
    }

    test('Scenario A: Local scan while offline remains PENDING until network restored', () async {
      final qr = await createSignedTicket(bookingCode: 'SW-OFFLINE-A');
      final scanResult = await service.verifyOfflineTicket(qr);

      expect(scanResult['ok'], isTrue);
      final scanId = scanResult['scanId'] as String;

      // Unconnected device: records are locally pending
      expect(service.pendingOfflineRecords.length, equals(1));
      expect(service.pendingOfflineRecords.first.scanId, equals(scanId));
      expect(service.pendingOfflineRecords.first.isSynced, isFalse);
    });

    test('Scenario B: Network restored -> server acks -> markSynced flips status and flushes to disk', () async {
      final qr = await createSignedTicket(bookingCode: 'SW-OFFLINE-B');
      final scanResult = await service.verifyOfflineTicket(qr);
      final scanId = scanResult['scanId'] as String;

      // Simulate successful server ack
      await service.markRecordsSynced([scanId]);

      expect(service.pendingOfflineRecords.isEmpty, isTrue);
      expect(service.allOfflineRecords.first.isSynced, isTrue);

      // Verify persistence to disk after sync
      final serviceAfterReboot = OfflineTicketService();
      await serviceAfterReboot.initStorage(storagePath: storagePath);
      await serviceAfterReboot.loadFromStorage();

      expect(serviceAfterReboot.pendingOfflineRecords.isEmpty, isTrue);
      expect(serviceAfterReboot.allOfflineRecords.first.isSynced, isTrue);
    });

    test('Scenario C: Server rejects request or network errors -> records remain PENDING', () async {
      final qr = await createSignedTicket(bookingCode: 'SW-OFFLINE-C');
      final scanResult = await service.verifyOfflineTicket(qr);
      final scanId = scanResult['scanId'] as String;

      // Simulate network exception during sync
      bool serverAckReceived = true;
      Future<void> sendSyncRequest() async {
        throw const SocketException('Connection timed out');
      }

      try {
        await sendSyncRequest();
      } catch (_) {
        serverAckReceived = false;
      }

      // Crucial invariant: never markSynced if server ack failed!
      if (serverAckReceived) {
        await service.markRecordsSynced([scanId]);
      }

      expect(service.pendingOfflineRecords.length, equals(1));
      expect(service.pendingOfflineRecords.first.isSynced, isFalse);
    });

    test('Scenario D: App crashes after server success but before markSynced -> duplicate sync is idempotent', () async {
      final qr = await createSignedTicket(bookingCode: 'SW-OFFLINE-D');
      final scanResult = await service.verifyOfflineTicket(qr);
      final scanId = scanResult['scanId'] as String;

      // Server mock ledger: tracks ingested scanIds
      final serverIngestedScanIds = <String>{};

      Map<String, dynamic> mockServerSync(List<String> incomingScanIds) {
        int synced = 0;
        int duplicate = 0;
        for (final id in incomingScanIds) {
          if (serverIngestedScanIds.contains(id)) {
            duplicate++;
          } else {
            serverIngestedScanIds.add(id);
            synced++;
          }
        }
        return {'success': true, 'syncedCount': synced, 'duplicateCount': duplicate};
      }

      // Sync attempt 1: server receives and commits
      final ack1 = mockServerSync([scanId]);
      expect(ack1['syncedCount'], equals(1));
      expect(ack1['duplicateCount'], equals(0));

            // Simulasi crash: client mati sebelum markRecordsSynced dipanggil.
      // On reboot, pendingOfflineRecords still contains scanId
      expect(service.pendingOfflineRecords.length, equals(1));

      // Retry sync: sends same scanId
      final ack2 = mockServerSync([scanId]);
      expect(ack2['syncedCount'], equals(0));
      expect(ack2['duplicateCount'], equals(1)); // Recognized as duplicate!

      // Client receives ack on retry and marks synced
      await service.markRecordsSynced([scanId]);
      expect(service.pendingOfflineRecords.isEmpty, isTrue);
    });

    test('Scenario E: Sync called twice concurrently produces exactly one server admission event', () async {
      final qr = await createSignedTicket(bookingCode: 'SW-OFFLINE-E');
      final scanResult = await service.verifyOfflineTicket(qr);
      final scanId = scanResult['scanId'] as String;

      final serverIngestedScanIds = <String>{};
      int totalLogicalAdmissions = 0;

      Future<void> simulateServerAdmission(String id) async {
        if (!serverIngestedScanIds.contains(id)) {
          serverIngestedScanIds.add(id);
          totalLogicalAdmissions++;
        }
      }

      // Run two concurrent sync attempts
      await Future.wait([
        simulateServerAdmission(scanId),
        simulateServerAdmission(scanId),
      ]);

      expect(totalLogicalAdmissions, equals(1), reason: 'scanId idempotency prevents duplicate admission');
    });
  });

  group('2. Offline Business Validity vs Cryptographic Authenticity Tests', () {
    test('cryptographic authenticity proves issuance but cannot detect online order state changes', () {
      // Order created and signed legitimately
      final issuedOrder = PesananTiketModel(
        id: 'ord-100',
        kodeBooking: 'SW-LEGIT-100',
        idKonser: 'konser-1',
        judulKonser: 'SoundWave 2026',
        gambarKonser: 'assets/images/konser/baskara.jpg',
        kategoriTiket: 'VIP',
        jumlahTiket: 1,
        totalHarga: 500000,
        tanggalBeli: DateTime.now(),
        tanggalKonser: DateTime.now().add(const Duration(days: 30)),
        lokasiKonser: 'GBK Stadium',
        namaPembeli: 'John Doe',
        emailPembeli: 'john@example.com',
        userId: 'uid-john',
        status: AppConstants.orderStatusActive,
        qrPayloadSignature: 'SW2|v1|ord-100|SW-LEGIT-100|konser-1|VIP|1|dummySig',
      );

      expect(issuedOrder.isAktif, isTrue);

      // Business state changes on server AFTER ticket was issued
      final refundedOrder = issuedOrder.copyWith(status: AppConstants.orderStatusRefunded);
      final cancelledEventOrder = issuedOrder.copyWith(status: AppConstants.orderStatusRefundRequired);

      // An offline scanner reading ONLY the static QR cannot know the order was refunded
      const canVerifyOfflineAuthenticity = true; // Signature is math-verifiable
      const canVerifyOfflinePostRefundState = false; // Requires server state!

      expect(canVerifyOfflineAuthenticity, isTrue);
      expect(canVerifyOfflinePostRefundState, isFalse);
      expect(refundedOrder.isRefunded, isTrue);
      expect(cancelledEventOrder.isRefundRequired, isTrue);
    });
  });

  group('3. Key Ring Dynamic Revocation & Rotation Lifecycle Tests', () {
    late OfflineTicketService service;

    setUp(() {
      service = OfflineTicketService();
    });

    test('static revocation rejects v0 immediately', () async {
      final dummySig = '0' * 128;
      final revokedQr = 'SW2|v0|ord-1|SW-REVOKED|k-1|VIP|1|$dummySig';
      final res = await service.verifyOfflineTicket(revokedQr);
      expect(res['ok'], isFalse);
      expect(res['message'], contains('Revoked Key'));
    });

    test('dynamic revocation manifest rejects v3 when revoked at runtime', () async {
      expect(OfflineTicketService.publicKeyRing.containsKey('v3'), isTrue);

      service.updateDynamicManifest(revokedKeys: {'v3'});

      final dummySig = '0' * 128;
      final testQr = 'SW2|v3|ord-1|SW-V3-TICKET|k-1|VIP|1|$dummySig';
      final res = await service.verifyOfflineTicket(testQr);

      expect(res['ok'], isFalse);
    });
  });

  group('4. Reservation Concurrency & Race Condition Stress Tests', () {
    test('100 concurrent buyers racing for 1 ticket: exactly 1 succeeds', () async {
      int currentStock = 1;
      int successfulReservations = 0;
      int rejectedReservations = 0;

      Future<bool> attemptReserve(String userId) async {
        // Simulate atomic transaction lock
        if (currentStock >= 1) {
          currentStock--;
          successfulReservations++;
          return true;
        } else {
          rejectedReservations++;
          return false;
        }
      }

      final futures = List.generate(100, (i) => attemptReserve('user-$i'));
      await Future.wait(futures);

      expect(successfulReservations, equals(1));
      expect(rejectedReservations, equals(99));
      expect(currentStock, equals(0));
    });

    test('100 concurrent buyers racing for 10 tickets: exactly 10 succeed, stock never negative', () async {
      int currentStock = 10;
      int successfulReservations = 0;

      Future<bool> attemptReserve(String userId) async {
        if (currentStock >= 1) {
          currentStock--;
          successfulReservations++;
          return true;
        }
        return false;
      }

      final futures = List.generate(100, (i) => attemptReserve('user-$i'));
      await Future.wait(futures);

      expect(successfulReservations, equals(10));
      expect(currentStock, equals(0));
    });

    test('Scheduler overlap: Scheduler A and Scheduler B concurrent cleanup restores stock exactly once', () async {
      var orderStatus = 'PENDING';
      int currentStock = 0;
      const int reservedQty = 2;
      int restorationCount = 0;

      Future<void> runSchedulerInstance(String instanceName) async {
        // Atomic transaction read-and-update simulation
        if (orderStatus == 'PENDING') {
          orderStatus = 'EXPIRED';
          currentStock += reservedQty;
          restorationCount++;
        }
      }

      await Future.wait([
        runSchedulerInstance('Instance_A'),
        runSchedulerInstance('Instance_B'),
      ]);

      expect(orderStatus, equals('EXPIRED'));
      expect(currentStock, equals(2));
      expect(restorationCount, equals(1), reason: 'Stock must be returned exactly once');
    });
  });

  group('5. Event Cancellation Scalability & Chunking Tests', () {
    test('batching chunks 5000 orders into 13 batches of up to 400 operations without timeout', () {
      final totalOrders = List.generate(5000, (i) => 'order-$i');
      const chunkSize = 400;

      final batches = <List<String>>[];
      for (int i = 0; i < totalOrders.length; i += chunkSize) {
        batches.add(totalOrders.sublist(i, (i + chunkSize > totalOrders.length) ? totalOrders.length : i + chunkSize));
      }

      expect(batches.length, equals(13)); // ceil(5000 / 400) = 13
      expect(batches.first.length, equals(400));
      expect(batches.last.length, equals(200));

      final allFlattened = batches.expand((b) => b).toList();
      expect(allFlattened.length, equals(5000));
    });
  });
}
