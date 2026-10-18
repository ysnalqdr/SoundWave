import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart' as dart_crypto;
import 'package:cryptography/cryptography.dart';

/// Represents a validated offline admission record
class OfflineScanRecord {
  final String scanId;
  final String kodeBooking;
  final String orderId;
  final String idKonser;
  final String deviceId;
  final DateTime scannedAt;
  bool isSynced;
  final String integrityChecksum;

  OfflineScanRecord({
    required this.scanId,
    required this.kodeBooking,
    required this.orderId,
    required this.idKonser,
    required this.deviceId,
    required this.scannedAt,
    this.isSynced = false,
    String? integrityChecksum,
  }) : integrityChecksum = integrityChecksum ??
            _computeChecksum(scanId, kodeBooking, orderId, scannedAt);

  static String _computeChecksum(
      String scanId, String kodeBooking, String orderId, DateTime scannedAt) {
    final raw = '$scanId|$kodeBooking|$orderId|${scannedAt.toIso8601String()}';
    return dart_crypto.sha256.convert(utf8.encode(raw)).toString().substring(0, 16);
  }

  bool verifyIntegrity() {
    final expected = _computeChecksum(scanId, kodeBooking, orderId, scannedAt);
    return integrityChecksum == expected;
  }

  Map<String, dynamic> toMap() => {
        'scanId': scanId,
        'kodeBooking': kodeBooking,
        'orderId': orderId,
        'idKonser': idKonser,
        'deviceId': deviceId,
        'scannedAt': scannedAt.toIso8601String(),
        'isSynced': isSynced,
        'integrityChecksum': integrityChecksum,
      };

  factory OfflineScanRecord.fromMap(Map<String, dynamic> map) {
    return OfflineScanRecord(
      scanId: map['scanId'] as String,
      kodeBooking: map['kodeBooking'] as String,
      orderId: map['orderId'] as String,
      idKonser: map['idKonser'] as String,
      deviceId: map['deviceId'] as String? ?? 'scanner-default',
      scannedAt: DateTime.parse(map['scannedAt'] as String),
      isSynced: map['isSynced'] as bool? ?? false,
      integrityChecksum: map['integrityChecksum'] as String?,
    );
  }

  String toJsonLine() => jsonEncode(toMap());
}

class OfflineTicketService {
  static final OfflineTicketService _instance = OfflineTicketService._internal();
  factory OfflineTicketService() => _instance;
  OfflineTicketService._internal();

  /// Public Key Ring: Maps keyId -> Ed25519 Public Key (32 bytes in Hex)
  /// Enables seamless key rotation without invalidating previously issued valid tickets.
  static const Map<String, String> publicKeyRing = {
    'v1': '738e21632d5a495fd5ea57d289333bf2cca00d84f8810f7e4961c417eff91697',
    'v2': '3b6a27bcceb6a42d62a3a8d02a6f0d73653215771de243a63ac048a18b59da29',
  };

  /// Set of compromised or retired key IDs that must be immediately rejected
  static const Set<String> revokedKeyIds = <String>{
    'v0', // Compromised historical test key
  };

  /// Active default key version for new signatures
  static const String activeKeyId = 'v1';

  /// Primary master public key hex alias for backwards compatibility
  static const String masterPublicKeyHex =
      '738e21632d5a495fd5ea57d289333bf2cca00d84f8810f7e4961c417eff91697';

  /// Dynamic key ring fetched when online to allow runtime revocation & rotation
  final Map<String, String> _dynamicKeyRing = {};
  final Set<String> _dynamicRevokedKeyIds = {};

  void updateDynamicManifest({
    Map<String, String>? additionalKeys,
    Set<String>? revokedKeys,
  }) {
    if (additionalKeys != null) _dynamicKeyRing.addAll(additionalKeys);
    if (revokedKeys != null) _dynamicRevokedKeyIds.addAll(revokedKeys);
  }

  final Ed25519 _ed25519 = Ed25519();

  /// Device hardware identifier for audit trail
  String deviceId = 'gate-handheld-01';

  /// In-memory fast-lookup index of scanned booking codes
  final Set<String> _locallyScannedCodes = <String>{};

  /// Chronological audit ledger of offline scans
  final List<OfflineScanRecord> _offlineScanRecords = <OfflineScanRecord>[];

  /// Persistent ledger file path (null = in-memory mode for unit tests)
  File? _ledgerFile;

  Set<String> get locallyScannedCodes => Set.unmodifiable(_locallyScannedCodes);
  List<OfflineScanRecord> get allOfflineRecords => List.unmodifiable(_offlineScanRecords);
  List<OfflineScanRecord> get pendingOfflineRecords =>
      List.unmodifiable(_offlineScanRecords.where((r) => !r.isSynced));

  /// Initializes persistent storage for the offline ledger.
  /// Reads existing entries on disk into RAM index so restart/crash preserves scan history.
  Future<void> initStorage({String? storagePath}) async {
    if (storagePath == null || storagePath.isEmpty) {
      _ledgerFile = null;
      return;
    }

    _ledgerFile = File(storagePath);
    await loadFromStorage();
  }

  /// Loads records from persistent file, verifies integrity, and repopulates the index.
  Future<int> loadFromStorage() async {
    if (_ledgerFile == null || !await _ledgerFile!.exists()) {
      return 0;
    }

    _locallyScannedCodes.clear();
    _offlineScanRecords.clear();

    final lines = await _ledgerFile!.readAsLines();
    int recoveredCount = 0;

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        final map = jsonDecode(line.trim()) as Map<String, dynamic>;
        final record = OfflineScanRecord.fromMap(map);

        // Integrity Verification: Reject partially written or tampered records
        if (!record.verifyIntegrity()) {
          continue;
        }

        _locallyScannedCodes.add(record.kodeBooking);
        _offlineScanRecords.add(record);
        recoveredCount++;
      } catch (_) {
        // Skip corrupted line from crash/partial write
        continue;
      }
    }

    return recoveredCount;
  }

  /// Persists a single scan record to disk with append-only semantics
  Future<void> _persistRecord(OfflineScanRecord record) async {
    if (_ledgerFile == null) return;

    try {
      final sink = _ledgerFile!.openWrite(mode: FileMode.append);
      sink.writeln(record.toJsonLine());
      await sink.flush();
      await sink.close();
    } catch (_) {
      // In critical environments, persistent write failures can be logged to telemetry
    }
  }

  /// Helper: converts hex string to byte list
  static List<int> hexToBytes(String hex) {
    final result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  /// Helper: converts byte list to hex string
  static String bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Constructs canonical payload for signing and verification.
  /// If [keyId] is provided, incorporates key version into the canonical structure.
  static String buildCanonicalPayload({
    String? keyId,
    required String orderId,
    required String kodeBooking,
    required String idKonser,
    required String kategoriTiket,
    required int jumlahTiket,
  }) {
    if (keyId != null && keyId.isNotEmpty) {
      return 'SW2|$keyId|$orderId|$kodeBooking|$idKonser|$kategoriTiket|$jumlahTiket';
    }
    return 'SW2|$orderId|$kodeBooking|$idKonser|$kategoriTiket|$jumlahTiket';
  }

  /// Verifies an offline signed QR code payload using the public key ring.
  /// Supports:
  /// - Versioned protocol: SW2|keyId|orderId|kodeBooking|idKonser|kategoriTiket|jumlahTiket|sigHex (8 parts)
  /// - Legacy unversioned: SW2|orderId|kodeBooking|idKonser|kategoriTiket|jumlahTiket|sigHex (7 parts -> maps to 'v1')
  Future<Map<String, dynamic>> verifyOfflineTicket(String rawQr) async {
    final parts = rawQr.trim().split('|');

    if (parts.isEmpty || parts[0] != 'SW2') {
      return {
        'ok': false,
        'message': 'Format QR tidak valid atau protokol tidak didukung.',
        'isOffline': true,
      };
    }

    String keyId = 'v1';
    String orderId;
    String kodeBooking;
    String idKonser;
    String kategoriTiket;
    int jumlahTiket;
    String signatureHex;
    String canonicalPayload;

    if (parts.length == 8) {
      // Versioned SW2
      keyId = parts[1];
      orderId = parts[2];
      kodeBooking = parts[3];
      idKonser = parts[4];
      kategoriTiket = parts[5];
      jumlahTiket = int.tryParse(parts[6]) ?? 1;
      signatureHex = parts[7];
      canonicalPayload = buildCanonicalPayload(
        keyId: keyId,
        orderId: orderId,
        kodeBooking: kodeBooking,
        idKonser: idKonser,
        kategoriTiket: kategoriTiket,
        jumlahTiket: jumlahTiket,
      );
    } else if (parts.length == 7) {
      // Legacy unversioned SW2 (defaults to keyId v1)
      keyId = 'v1';
      orderId = parts[1];
      kodeBooking = parts[2];
      idKonser = parts[3];
      kategoriTiket = parts[4];
      jumlahTiket = int.tryParse(parts[5]) ?? 1;
      signatureHex = parts[6];
      canonicalPayload = buildCanonicalPayload(
        orderId: orderId,
        kodeBooking: kodeBooking,
        idKonser: idKonser,
        kategoriTiket: kategoriTiket,
        jumlahTiket: jumlahTiket,
      );
    } else {
      return {
        'ok': false,
        'message': 'Format QR korup (jumlah segmen tidak valid).',
        'isOffline': true,
      };
    }

    // 1. Signature Structure Validation
    if (signatureHex.length != 128) {
      return {
        'ok': false,
        'message': 'Format tanda tangan digital Ed25519 tidak valid (panjang tidak 64 byte).',
        'isOffline': true,
      };
    }

    // 2. Key Ring & Revocation Enforcement
    if (revokedKeyIds.contains(keyId)) {
      return {
        'ok': false,
        'message': 'Kunci kriptografis telah dicabut ($keyId: Revoked Key). Tiket dibatalkan oleh otoritas.',
        'isOffline': true,
      };
    }

    final isRevoked = revokedKeyIds.contains(keyId) || _dynamicRevokedKeyIds.contains(keyId);
    if (isRevoked) {
      return {
        'ok': false,
        'message': 'Kunci kriptografis telah dicabut ($keyId: Revoked Key). Tiket dibatalkan oleh otoritas.',
        'isOffline': true,
      };
    }

    final publicKeyHex = _dynamicKeyRing[keyId] ?? publicKeyRing[keyId];
    if (publicKeyHex == null) {
      return {
        'ok': false,
        'message': 'Versi kunci kriptografis tidak dikenali ($keyId: Unknown Key ID). Perbarui aplikasi scanner.',
        'isOffline': true,
      };
    }

    // 3. Asymmetric Digital Signature Verification (Ed25519)
    try {
      final payloadBytes = utf8.encode(canonicalPayload);
      final signatureBytes = hexToBytes(signatureHex);
      final pubKeyBytes = hexToBytes(publicKeyHex);

      final publicKey = SimplePublicKey(pubKeyBytes, type: KeyPairType.ed25519);
      final signature = Signature(signatureBytes, publicKey: publicKey);

      final isValidSignature = await _ed25519.verify(payloadBytes, signature: signature);

      if (!isValidSignature) {
        return {
          'ok': false,
          'message': 'Tanda tangan digital Ed25519 TIDAK COCOK. Tiket palsu atau telah dimanipulasi.',
          'isOffline': true,
        };
      }
    } catch (e) {
      return {
        'ok': false,
        'message': 'Gagal memverifikasi tanda tangan digital: $e',
        'isOffline': true,
      };
    }

    // 4. Local Double-Scan Protection (Anti Double-Spend on this device)
    if (_locallyScannedCodes.contains(kodeBooking)) {
      return {
        'ok': false,
        'message': 'Tiket SUDAH DISCAN pada gate ini sebelumnya (Double-Scan Terdeteksi).',
        'isOffline': true,
        'kodeBooking': kodeBooking,
      };
    }

    // 5. Create scan record with high-entropy unique scanId (collision-proof)
    final randHex = bytesToHex(List<int>.generate(8, (_) => Random.secure().nextInt(256)));
    final scanId = 'scan_${kodeBooking}_${DateTime.now().millisecondsSinceEpoch}_$randHex';
    final record = OfflineScanRecord(
      scanId: scanId,
      kodeBooking: kodeBooking,
      orderId: orderId,
      idKonser: idKonser,
      deviceId: deviceId,
      scannedAt: DateTime.now(),
    );

    // 6. Atomically update in-memory ledger and append to persistent file
    _locallyScannedCodes.add(kodeBooking);
    _offlineScanRecords.add(record);
    await _persistRecord(record);

    return {
      'ok': true,
      'message': 'Tiket Valid (Asymmetric Ed25519 Verified) — Silakan Masuk',
      'isOffline': true,
      'keyId': keyId,
      'kodeBooking': kodeBooking,
      'orderId': orderId,
      'idKonser': idKonser,
      'kategoriTiket': kategoriTiket,
      'jumlahTiket': jumlahTiket,
      'scanId': scanId,
    };
  }

  /// Marks a list of scanIds as successfully synced with the server and flushes to disk
  Future<void> markRecordsSynced(List<String> scanIds) async {
    final idSet = scanIds.toSet();
    for (final record in _offlineScanRecords) {
      if (idSet.contains(record.scanId)) {
        record.isSynced = true;
      }
    }
    await _flushLedgerToDisk();
  }

  /// Flushes current in-memory ledger state to persistent storage
  Future<void> _flushLedgerToDisk() async {
    if (_ledgerFile == null) return;
    try {
      final sink = _ledgerFile!.openWrite(mode: FileMode.write);
      for (final r in _offlineScanRecords) {
        sink.writeln(r.toJsonLine());
      }
      await sink.flush();
      await sink.close();
    } catch (_) {}
  }

  /// Clears local scanned ledger (e.g. at the start of a new concert shift)
  Future<void> resetLedger({bool deleteFile = false}) async {
    _locallyScannedCodes.clear();
    _offlineScanRecords.clear();
    if (deleteFile && _ledgerFile != null && await _ledgerFile!.exists()) {
      await _ledgerFile!.delete();
    }
  }
}
