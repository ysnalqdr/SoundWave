import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart' as dart_crypto;
import 'package:cryptography/cryptography.dart';

/// A validated offline admission record.
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

  /// Maps key ID to Ed25519 public key (32 bytes, hex), so rotating a key
  /// does not invalidate tickets issued earlier.
  static const Map<String, String> publicKeyRing = {
    'v3': '850e6f046f020a0c24dec7c29ba5290304bcaaae8c2da2870778c2e4df831aea',
  };

  /// Revoked key IDs. v0 to v2 were once committed to a public repo, so their
  /// private keys count as leaked and their tickets are rejected.
  static const Set<String> revokedKeyIds = <String>{
    'v0',
    'v1',
    'v2',
  };

  /// Key ID the backend signs with today (ED25519_KEY_ID in .env).
  static const String activeKeyId = 'v3';

  /// Primary public key, used by the UI and tests.
  static const String masterPublicKeyHex =
      '850e6f046f020a0c24dec7c29ba5290304bcaaae8c2da2870778c2e4df831aea';

  /// Key ring fetched while online, so revocation and rotation work at runtime.
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

  /// Device identifier for the audit trail.
  String deviceId = 'gate-handheld-01';

  /// In-memory index of scanned booking codes.
  final Set<String> _locallyScannedCodes = <String>{};

  /// Chronological ledger of offline scans.
  final List<OfflineScanRecord> _offlineScanRecords = <OfflineScanRecord>[];

  /// Ledger file path. Null keeps everything in memory for unit tests.
  File? _ledgerFile;

  Set<String> get locallyScannedCodes => Set.unmodifiable(_locallyScannedCodes);
  List<OfflineScanRecord> get allOfflineRecords => List.unmodifiable(_offlineScanRecords);
  List<OfflineScanRecord> get pendingOfflineRecords =>
      List.unmodifiable(_offlineScanRecords.where((r) => !r.isSynced));

  /// Opens the ledger file and rebuilds the in-memory index, so a restart or
  /// crash keeps the scan history.
  Future<void> initStorage({String? storagePath}) async {
    if (storagePath == null || storagePath.isEmpty) {
      _ledgerFile = null;
      return;
    }

    _ledgerFile = File(storagePath);
    await loadFromStorage();
  }

  /// Loads the ledger, verifies each record, and rebuilds the index.
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

        // Tolak catatan yang tertulis separuh atau sudah diubah.
        if (!record.verifyIntegrity()) {
          continue;
        }

        _locallyScannedCodes.add(record.kodeBooking);
        _offlineScanRecords.add(record);
        recoveredCount++;
      } catch (_) {
        // Baris korup dari penulisan yang terputus dilewati.
        continue;
      }
    }

    return recoveredCount;
  }

  /// Appends one scan record to disk.
  Future<void> _persistRecord(OfflineScanRecord record) async {
    if (_ledgerFile == null) return;

    try {
      final sink = _ledgerFile!.openWrite(mode: FileMode.append);
      sink.writeln(record.toJsonLine());
      await sink.flush();
      await sink.close();
    } catch (_) {
      // Gagal menulis tidak menggagalkan pemindaian yang sudah divalidasi.
    }
  }

  static List<int> hexToBytes(String hex) {
    final result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  static String bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Builds the canonical payload used for signing and verification. The key
  /// ID is part of it, so a rotated key yields a different signature.
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

  /// Verifies a signed offline QR payload against the public key ring.
  ///
  /// SW2|keyId|orderId|kodeBooking|idKonser|kategori|jumlah|signature is the
  /// current form (8 parts). The legacy 7-part form is treated as v1.
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
      // Format lama tanpa keyId diperlakukan sebagai v1.
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

    // Bentuk tanda tangan diperiksa lebih dulu.
    if (signatureHex.length != 128) {
      return {
        'ok': false,
        'message': 'Format tanda tangan digital Ed25519 tidak valid (panjang tidak 64 byte).',
        'isOffline': true,
      };
    }

    // Kunci harus dikenal dan belum dicabut.
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

    // Verifikasi tanda tangan Ed25519.
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

    // Tolak pindai ganda di perangkat yang sama.
    if (_locallyScannedCodes.contains(kodeBooking)) {
      return {
        'ok': false,
        'message': 'Tiket SUDAH DISCAN pada gate ini sebelumnya (Double-Scan Terdeteksi).',
        'isOffline': true,
        'kodeBooking': kodeBooking,
      };
    }

    // scanId acak supaya tidak pernah bertabrakan.
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

    // Perbarui indeks di memori, lalu tambahkan ke berkas.
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

  /// Marks scans as synced and writes the ledger back to disk.
  Future<void> markRecordsSynced(List<String> scanIds) async {
    final idSet = scanIds.toSet();
    for (final record in _offlineScanRecords) {
      if (idSet.contains(record.scanId)) {
        record.isSynced = true;
      }
    }
    await _flushLedgerToDisk();
  }

  /// Writes the in-memory ledger to disk.
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

  /// Clears the ledger, for example at the start of a new shift.
  Future<void> resetLedger({bool deleteFile = false}) async {
    _locallyScannedCodes.clear();
    _offlineScanRecords.clear();
    if (deleteFile && _ledgerFile != null && await _ledgerFile!.exists()) {
      await _ledgerFile!.delete();
    }
  }
}
