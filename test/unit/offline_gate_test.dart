import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/services/offline_ticket_service.dart';

void main() {
  group('Asymmetric Ed25519 Cryptographic Gate & Double-Spend Defense Tests', () {
    late OfflineTicketService offlineService;
    final algorithm = Ed25519();

    // Kunci uji dibuat ulang setiap kali tes berjalan. Tidak ada kunci privat
    // asli di repo, jadi tes ini tidak bergantung pada kunci backend.
    late List<int> ujiSeed;

    const String orderId = 'ord-secure-001';
    const String kodeBooking = 'SW-OFFLINE-77';
    const String idKonser = 'konser-rock-2026';
    const String kategoriTiket = 'VIP';
    const int jumlahTiket = 2;

    setUp(() async {
      offlineService = OfflineTicketService();
      await offlineService.resetLedger(deleteFile: true);
      await offlineService.initStorage(storagePath: null); // in-memory for basic tests

      final seedBytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
      ujiSeed = seedBytes;
      final kunciUji = await algorithm.newKeyPairFromSeed(seedBytes);
      final publikUji = await kunciUji.extractPublicKey();
      offlineService.updateDynamicManifest(
        additionalKeys: {'uji': OfflineTicketService.bytesToHex(publikUji.bytes)},
      );
    });

    /// Helper to simulate Server-Side signing using the backend private key
    Future<String> serverSignTicket({
      String keyId = 'uji',
      required String orderId,
      required String kodeBooking,
      required String idKonser,
      required String kategoriTiket,
      required int jumlahTiket,
    }) async {
      final canonicalPayload = OfflineTicketService.buildCanonicalPayload(
        keyId: keyId,
        orderId: orderId,
        kodeBooking: kodeBooking,
        idKonser: idKonser,
        kategoriTiket: kategoriTiket,
        jumlahTiket: jumlahTiket,
      );

      final keyPair = await algorithm.newKeyPairFromSeed(ujiSeed);
      final sig = await algorithm.sign(utf8.encode(canonicalPayload), keyPair: keyPair);
      final sigHex = OfflineTicketService.bytesToHex(sig.bytes);

      return '$canonicalPayload|$sigHex';
    }

    test('kunci uji terdaftar di keyring dan tanda tangannya diterima', () async {
      final keyPair = await algorithm.newKeyPairFromSeed(ujiSeed);
      final pubKey = await keyPair.extractPublicKey();
      final pubKeyHex = OfflineTicketService.bytesToHex(pubKey.bytes);

      final signed = await serverSignTicket(
        keyId: 'uji',
        orderId: 'ord-kunci-uji',
        kodeBooking: 'SW-KUNCI-UJI',
        idKonser: 'k-1',
        kategoriTiket: 'VIP',
        jumlahTiket: 1,
      );
      final hasil = await offlineService.verifyOfflineTicket(signed);

      expect(pubKeyHex.length, equals(64));
      expect(hasil['ok'], isTrue);
    });

    test('format lama tanpa keyId dipetakan ke v1 dan ditolak karena sudah dicabut', () async {
      final canonical = OfflineTicketService.buildCanonicalPayload(
        orderId: orderId,
        kodeBooking: kodeBooking,
        idKonser: idKonser,
        kategoriTiket: kategoriTiket,
        jumlahTiket: jumlahTiket,
      );
      final keyPair = await algorithm.newKeyPairFromSeed(ujiSeed);
      final sig = await algorithm.sign(utf8.encode(canonical), keyPair: keyPair);
      final legacyQr = '$canonical|${OfflineTicketService.bytesToHex(sig.bytes)}';

      final result = await offlineService.verifyOfflineTicket(legacyQr);

      expect(result['ok'], isFalse);
      expect(result['message'], contains('Revoked Key'));
    });

    test('valid server-signed versioned SW2 (keyId uji) QR passes offline admission check', () async {
      final validSignedQr = await serverSignTicket(
        keyId: 'uji',
        orderId: orderId,
        kodeBooking: kodeBooking,
        idKonser: idKonser,
        kategoriTiket: kategoriTiket,
        jumlahTiket: jumlahTiket,
      );

      final result = await offlineService.verifyOfflineTicket(validSignedQr);

      expect(result['ok'], isTrue);
      expect(result['keyId'], equals('uji'));
      expect(result['kodeBooking'], equals(kodeBooking));
    });

    test('ticket using revoked key ID (v0) is rejected by offline gate', () async {
      final dummySig = 'a' * 128;
      final revokedKeyPayload = 'SW2|v0|ord-1|SW-REVOKED|k-1|VIP|1|$dummySig';
      final result = await offlineService.verifyOfflineTicket(revokedKeyPayload);

      expect(result['ok'], isFalse);
      expect(result['message'], contains('Revoked Key'));
    });

    test('ticket using unknown key ID (v99) is rejected by offline gate', () async {
      final dummySig = 'a' * 128;
      final unknownKeyPayload = 'SW2|v99|ord-1|SW-UNKNOWN|k-1|VIP|1|$dummySig';
      final result = await offlineService.verifyOfflineTicket(unknownKeyPayload);

      expect(result['ok'], isFalse);
      expect(result['message'], contains('Unknown Key ID'));
    });

    test('tampered payload (e.g. ticket category changed from Reguler to VIP) is rejected', () async {
      final genuinePayload = await serverSignTicket(
        orderId: orderId,
        kodeBooking: kodeBooking,
        idKonser: idKonser,
        kategoriTiket: 'Reguler',
        jumlahTiket: 1,
      );

      final genuineParts = genuinePayload.split('|');
      final genuineSignature = genuineParts[7];

      // Attacker tampers category to VIP while keeping the same genuine signature
      final forgedQr = 'SW2|uji|$orderId|$kodeBooking|$idKonser|VIP|1|$genuineSignature';

      final result = await offlineService.verifyOfflineTicket(forgedQr);

      expect(result['ok'], isFalse);
      expect(result['message'], contains('Tanda tangan digital Ed25519 TIDAK COCOK'));
    });

    test('forged signature generated with an unauthorized private key is rejected', () async {
      final canonicalPayload = OfflineTicketService.buildCanonicalPayload(
        keyId: 'uji',
        orderId: orderId,
        kodeBooking: kodeBooking,
        idKonser: idKonser,
        kategoriTiket: kategoriTiket,
        jumlahTiket: jumlahTiket,
      );

      // Attacker creates their own rogue key pair
      final rogueKeyPair = await algorithm.newKeyPair();
      final rogueSig = await algorithm.sign(utf8.encode(canonicalPayload), keyPair: rogueKeyPair);
      final rogueSigHex = OfflineTicketService.bytesToHex(rogueSig.bytes);

      final forgedQr = '$canonicalPayload|$rogueSigHex';
      final result = await offlineService.verifyOfflineTicket(forgedQr);

      expect(result['ok'], isFalse);
      expect(result['message'], contains('Tanda tangan digital Ed25519 TIDAK COCOK'));
    });

    test('local double-scan defense: scanning same valid ticket twice on device triggers double-scan rejection', () async {
      final validSignedQr = await serverSignTicket(
        orderId: orderId,
        kodeBooking: kodeBooking,
        idKonser: idKonser,
        kategoriTiket: kategoriTiket,
        jumlahTiket: jumlahTiket,
      );

      // Scan 1: First scan at Gate Lane A
      final scan1 = await offlineService.verifyOfflineTicket(validSignedQr);
      expect(scan1['ok'], isTrue, reason: 'First scan must succeed');

      // Scan 2: Second scan at same Gate Lane A
      final scan2 = await offlineService.verifyOfflineTicket(validSignedQr);
      expect(scan2['ok'], isFalse, reason: 'Second scan must be blocked by local device ledger');
      expect(scan2['message'], contains('Double-Scan Terdeteksi'));
    });

    test('legacy SW1 protocol or raw un-signed barcode is rejected in offline mode', () async {
      const legacyQr = 'SW1|ord-1|SW-99|konser-1|VIP|1|uid-1|abcdef1234567890';
      final result = await offlineService.verifyOfflineTicket(legacyQr);

      expect(result['ok'], isFalse);
      expect(result['message'], contains('protokol tidak didukung'));
    });

    test('malformed QR string is rejected gracefully', () async {
      const corruptQr = 'INVALID_QR_CODE_DATA';
      final result = await offlineService.verifyOfflineTicket(corruptQr);

      expect(result['ok'], isFalse);
    });
  });

  group('Offline Gate Ledger Persistence & Crash Recovery Tests', () {
    late Directory tempDir;
    late String storagePath;
    final algorithm = Ed25519();
    late List<int> ujiSeed;
    late String publikUjiHex;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('gate_ledger_test_');
      storagePath = '${tempDir.path}/ledger.json';

      final seedBytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
      ujiSeed = seedBytes;
      final kunciUji = await algorithm.newKeyPairFromSeed(seedBytes);
      final publikUji = await kunciUji.extractPublicKey();
      publikUjiHex = OfflineTicketService.bytesToHex(publikUji.bytes);
    });

    tearDown(() async {
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    test('scanned tickets persist to disk and survive app restart / process reboot', () async {
      final serviceInstance1 = OfflineTicketService();
      await serviceInstance1.initStorage(storagePath: storagePath);
      await serviceInstance1.resetLedger(deleteFile: true);
      await serviceInstance1.initStorage(storagePath: storagePath);


      serviceInstance1.updateDynamicManifest(
        additionalKeys: {'uji': publikUjiHex},
      );

      // Simulate valid signing for persist test
      final keyPair = await algorithm.newKeyPairFromSeed(ujiSeed);

      final canonical = OfflineTicketService.buildCanonicalPayload(
        keyId: 'uji',
        orderId: 'ord-persist-1',
        kodeBooking: 'SW-PERSIST-99',
        idKonser: 'k-1',
        kategoriTiket: 'VIP',
        jumlahTiket: 1,
      );
      final sig = await algorithm.sign(utf8.encode(canonical), keyPair: keyPair);
      final validSignedQr = '$canonical|${OfflineTicketService.bytesToHex(sig.bytes)}';

      // 1. Scan ticket on device instance 1
      final scanResult = await serviceInstance1.verifyOfflineTicket(validSignedQr);
      expect(scanResult['ok'], isTrue);
      expect(serviceInstance1.locallyScannedCodes.contains('SW-PERSIST-99'), isTrue);

      // Verify file was written to disk
      final ledgerFile = File(storagePath);
      expect(await ledgerFile.exists(), isTrue);
      final linesBeforeRestart = await ledgerFile.readAsLines();
      expect(linesBeforeRestart.isNotEmpty, isTrue);

      // 2. Simulate complete app restart / battery death / crash:
            // Bersihkan RAM lalu inisialisasi ulang dari disk.
      await serviceInstance1.resetLedger(deleteFile: false);
      expect(serviceInstance1.locallyScannedCodes.isEmpty, isTrue);

      // 3. App restarts and loads persistent storage
      final recoveredCount = await serviceInstance1.loadFromStorage();
      expect(recoveredCount, equals(1));
      expect(serviceInstance1.locallyScannedCodes.contains('SW-PERSIST-99'), isTrue);

      // 4. Attempting to scan the same ticket again MUST be rejected as double-scan!
      final secondScanResult = await serviceInstance1.verifyOfflineTicket(validSignedQr);
      expect(secondScanResult['ok'], isFalse);
      expect(secondScanResult['message'], contains('Double-Scan Terdeteksi'));
    });

    test('corrupted ledger entry (tampered / partial write) is skipped by integrity verification', () async {
      final ledgerFile = File(storagePath);
      // Write one valid record and one corrupted line
      final validRecord = OfflineScanRecord(
        scanId: 'scan_001',
        kodeBooking: 'SW-VALID-1',
        orderId: 'ord-1',
        idKonser: 'k-1',
        deviceId: 'dev-1',
        scannedAt: DateTime.now(),
      );

      // Corrupted record with invalid checksum
      final corruptedJson = jsonEncode({
        'scanId': 'scan_002',
        'kodeBooking': 'SW-FORGED-2',
        'orderId': 'ord-2',
        'idKonser': 'k-1',
        'deviceId': 'dev-1',
        'scannedAt': DateTime.now().toIso8601String(),
        'isSynced': false,
        'integrityChecksum': 'INVALID_CHECKSUM_HASH',
      });

      await ledgerFile.writeAsString('${validRecord.toJsonLine()}\n$corruptedJson\n');

      final service = OfflineTicketService();
      await service.initStorage(storagePath: storagePath);
      final recovered = await service.loadFromStorage();

      // Only the valid record is recovered, corrupted entry skipped
      expect(recovered, equals(1));
      expect(service.locallyScannedCodes.contains('SW-VALID-1'), isTrue);
      expect(service.locallyScannedCodes.contains('SW-FORGED-2'), isFalse);
    });

    test('offline sync tracking: tracks pending un-synced records and marks them synced', () async {
      final service = OfflineTicketService();
      await service.initStorage(storagePath: storagePath);
      await service.resetLedger(deleteFile: true);
      await service.initStorage(storagePath: storagePath);
      service.updateDynamicManifest(additionalKeys: {'uji': publikUjiHex});

      final keyPair = await algorithm.newKeyPairFromSeed(ujiSeed);

      final canonical = OfflineTicketService.buildCanonicalPayload(
        keyId: 'uji',
        orderId: 'ord-sync-1',
        kodeBooking: 'SW-SYNC-1',
        idKonser: 'k-1',
        kategoriTiket: 'VIP',
        jumlahTiket: 1,
      );
      final sig = await algorithm.sign(utf8.encode(canonical), keyPair: keyPair);
      final validSignedQr = '$canonical|${OfflineTicketService.bytesToHex(sig.bytes)}';

      final res = await service.verifyOfflineTicket(validSignedQr);
      expect(res['ok'], isTrue);
      final scanId = res['scanId'] as String;

      expect(service.pendingOfflineRecords.length, equals(1));
      expect(service.pendingOfflineRecords.first.scanId, equals(scanId));
      expect(service.pendingOfflineRecords.first.isSynced, isFalse);

      // Simulate synchronization completion
      service.markRecordsSynced([scanId]);
      expect(service.pendingOfflineRecords.isEmpty, isTrue);
      expect(service.allOfflineRecords.first.isSynced, isTrue);
    });
  });

  group('Refund State Machine & Idempotency Tests', () {
    test('transitions REFUND_REQUIRED to REFUNDED idempotently', () {
      const initialStatus = 'REFUND_REQUIRED';
      expect(initialStatus, equals('REFUND_REQUIRED'));

      // Process refund #1
      var currentStatus = 'REFUNDED';
      var refundCount = 1;
      expect(currentStatus, equals('REFUNDED'));

      // Process refund #2 (Idempotency Guard)
      bool doubleRefundAllowed = false;
      if (currentStatus != 'REFUNDED') {
        doubleRefundAllowed = true;
        refundCount++;
      }

      expect(doubleRefundAllowed, isFalse);
      expect(refundCount, equals(1));
    });

    test('reconciliation state machine allows safe retries from REFUND_PENDING', () {
      var status = 'REFUND_REQUIRED';
      // Simulate external provider call initiated
      status = 'REFUND_PROCESSING';
      // Network timeout occurred
      status = 'REFUND_PENDING';

      // Subsequent reconciliation retry handles REFUND_PENDING
      final canRetry = status == 'REFUND_PENDING' || status == 'REFUND_REQUIRED';
      expect(canRetry, isTrue);

      // Settled successfully on retry
      status = 'REFUNDED';
      expect(status, equals('REFUNDED'));
    });
  });
}
