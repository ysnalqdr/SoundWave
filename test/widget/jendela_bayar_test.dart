// ═══════════════════════════════════════════════════════════════════
// PENJAGA SUMBER — JENDELA BAYAR 5 MENIT & PEMBUKUAN STOK SEKALI
// ═══════════════════════════════════════════════════════════════════
// Mengunci janji ke pengguna:
//   1. Jendela pembayaran 5 menit, satu angka (AppConstants + backend).
//   2. Tiket pending menampilkan hitungan waktu yang berdetak.
//   3. Waktu habis → RESERVASI BERAKHIR + tombol "Pesan Ulang"
//      (tombol bayar TIDAK boleh muncul lagi), berpindah sendiri saat 00:00.
//   4. Pesanan yang sudah EXPIRED tetap terlihat di filter PENDING.
//   5. Stok dipotong SEKALI saat reservasi, dilepas SEKALI saat
//      kedaluwarsa/gagal — tidak pernah dobel.
// ═══════════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String konstanta;
  late String layarTiket;
  late String kotakPending;
  late String server;
  late String layananDb;
  late bool adaServer;

  setUpAll(() {
    konstanta = File('lib/constants/app_constants.dart').readAsStringSync();
    layarTiket =
        File('lib/screens/user/user_tiket_screen.dart').readAsStringSync();
    kotakPending =
        File('lib/widgets/kotak_pending_tiket.dart').readAsStringSync();
    layananDb = File('lib/services/database_service.dart').readAsStringSync();
    final backend = File('../soundwave-backend/server.js');
    adaServer = backend.existsSync();
    server = adaServer ? backend.readAsStringSync() : '';
  });

  group('jendela pembayaran 5 menit', () {
    test('angka jendela ada di satu tempat', () {
      expect(konstanta.contains('static const int reservationHoldMinutes = 5;'),
          isTrue,
          reason: 'jendela pembayaran harus 5 menit');
      expect(
          konstanta.contains(
              'static const Duration reservationHold =\n      Duration(minutes: reservationHoldMinutes);'),
          isTrue);
    });

    test('status RESERVED dikenali aplikasi', () {
      expect(konstanta.contains("static const String orderStatusReserved = 'RESERVED';"),
          isTrue);
    });
  });

  group('tampilan hitungan waktu di tiket pending', () {
    test('kotak pending memakai hitungan waktu yang berdetak', () {
      expect(kotakPending.contains('HitungMundurTeks('), isTrue);
      expect(kotakPending.contains("awalan: 'Sisa waktu '"), isTrue);
      expect(kotakPending.contains('onHabis: _tandaiHabis'), isTrue,
          reason: 'pergantian keadaan dipicu tepat saat hitungan menyentuh nol');
      expect(
          kotakPending.contains(
              'return _habis ? _kotakBerakhir() : _kotakMenunggu();'),
          isTrue);
    });

    test('badge daftar tiket juga menampilkan sisa waktu', () {
      expect(layarTiket.contains('Widget _buildBadgeMenunggu('), isTrue);
      expect(
          layarTiket.contains(
              'if (item.isPending && !item.isExpired && item.reservedUntil != null)'),
          isTrue,
          reason: 'badge hanya memakai hitungan waktu kalau batas waktunya ada');
      expect(layarTiket.contains('_buildBadgeMenunggu(item, onHabis: onHabis)'),
          isTrue);
    });

    test('tombol bayar HANYA di keadaan masih ada waktu', () {
      final int mulai = kotakPending.indexOf('Widget _kotakMenunggu()');
      final int akhir = kotakPending.indexOf('Widget _kotakBerakhir()');
      expect(mulai, greaterThanOrEqualTo(0));
      expect(akhir, greaterThan(mulai));

      final String cabangAktif = kotakPending.substring(mulai, akhir);
      expect(cabangAktif.contains("'Bayar Sekarang'"), isTrue);
      expect(cabangAktif.contains('onPressed: widget.onBayar'), isTrue);
      expect(cabangAktif.contains("'Pesan Ulang'"), isFalse);

      final String cabangHabis = kotakPending.substring(akhir);
      expect(cabangHabis.contains("'RESERVASI BERAKHIR'"), isTrue);
      expect(cabangHabis.contains("'Pesan Ulang'"), isTrue);
      expect(cabangHabis.contains('onPressed: widget.onPesanUlang'), isTrue);
      expect(cabangHabis.contains("'Bayar Sekarang'"), isFalse,
          reason: 'pesanan kedaluwarsa tidak boleh bisa dibayar lagi');
    });
  });

  group('EXPIRED tetap terlihat di filter PENDING', () {
    test('filter PENDING memuat pesanan yang sudah kedaluwarsa', () {
      expect(layarTiket.contains('.where((p) => p.isPending || p.isExpired)'),
          isTrue,
          reason: 'pesanan EXPIRED harus tetap muncul di tab PENDING '
              'supaya user bisa memesan ulang');
    });

    test('layar tiket menyapu reservasi kedaluwarsa lewat backend', () {
      expect(layarTiket.contains('_sapuReservasiKedaluwarsa'), isTrue);
      expect(layarTiket.contains('sweepExpired()'), isTrue);
    });

    test('sheet detail menyegarkan daftar saat hitungan habis', () {
      expect(layarTiket.contains('onKedaluwarsa: () => _sinkronkanKedaluwarsa'),
          isTrue);
      expect(
          layarTiket.contains('ref.invalidate(userOrdersProvider(tiket.userId))'),
          isTrue);
    });
  });

  group('jaring pengaman di aplikasi', () {
    test('PENDING tidak pernah menambah stok saat disapu', () {
      // Dulu: pesanan PENDING (stok belum dipotong) disapu lalu stok +qty
      // → stok naik palsu. Sekarang stok hanya dilepas kalau memang
      // pernah dipotong dan belum pernah dilepas.
      expect(layananDb.contains('final perluLepasStok ='), isTrue);
      expect(
          layananDb.contains('stokDipotong && !sudahDilepas && (ticketId ?? \'\').isNotEmpty'),
          isTrue);
      expect(layananDb.contains('if (perluLepasStok) {'), isTrue);
      expect(layananDb.contains('stokDilepas\': true'), isTrue,
          reason: 'penanda supaya stok tidak dilepas dua kali');
    });

    test('penyapu aplikasi mengenal PENDING dan RESERVED', () {
      expect(
          layananDb.contains('status != AppConstants.orderStatusPending &&'), isTrue);
      expect(
          layananDb.contains('status != AppConstants.orderStatusReserved'), isTrue);
    });

    test('pesanan baru memakai jendela dari konstanta (5 menit)', () {
      expect(
          layananDb.contains(
              'now.add(const Duration(minutes: AppConstants.reservationHoldMinutes))'),
          isTrue);
    });
  });

  group('pembukuan stok di backend', () {
    test('berkas backend terbaca', () {
      if (!adaServer) {
        markTestSkipped(
            'folder ../soundwave-backend tidak ada (CI hanya checkout repo Flutter)');
        return;
      }
      expect(adaServer, isTrue);
    });

    test('jendela 5 menit juga berlaku di server', () {
      if (!adaServer) return;
      expect(
          server.contains(
              'const HOLD_MENIT = Number(process.env.RESERVATION_HOLD_MINUTES || 5);'),
          isTrue);
    });

    test('ada penyapu otomatis, bukan hanya endpoint', () {
      if (!adaServer) return;
      expect(server.contains('sapuReservasiKedaluwarsa().catch'), isTrue,
          reason: 'penyapu harus jalan sendiri tiap 30 detik');
      expect(server.contains('}, 30000);'), isTrue);
    });

    test('ada satu penentu "stok sudah dipotong"', () {
      if (!adaServer) return;
      expect(server.contains('function stokSudahDipotong(order)'), isTrue);
      expect(server.contains('const sudahPotong = stokSudahDipotong(orderData);'),
          isTrue);
      expect(server.contains('const sudahPotong = stokSudahDipotong(freshData);'),
          isTrue);
    });

    test('settle-dev tidak memotong stok dua kali', () {
      if (!adaServer) return;
      expect(server.contains('if (orderData.idTiket && !stokSudahDipotong(orderData)) {'),
          isTrue,
          reason: 'potongan kedua saat simulasi bayar harus hilang');
    });

    test('penyapu mengenal PENDING dan RESERVED', () {
      if (!adaServer) return;
      expect(server.contains("o.status !== 'PENDING' && o.status !== 'RESERVED'"),
          isTrue,
          reason: 'pesanan RESERVED dulu tidak pernah disapu → stok nyangkut');
      expect(server.contains("app.post('/sweep-expired'"), isTrue);
      expect(server.contains('stokDilepas: true'), isTrue);
    });

    test('gagal bayar menjadi EXPIRED dan stok dilepas sekali', () {
      if (!adaServer) return;
      // Kemunculan terakhir = cabang di dalam transaksi (yang mengurus stok),
      // bukan pemetaan status di atasnya.
      final int idx = server.lastIndexOf(
          "} else if (['cancel', 'deny', 'expire'].includes(transactionStatus)) {");
      expect(idx, greaterThanOrEqualTo(0));
      final String blok = server.substring(idx, idx + 1400);
      expect(blok.contains("finalStatus = 'EXPIRED';"), isTrue,
          reason: 'gagal bayar harus EXPIRED, bukan CANCELLED');
      expect(blok.contains('lepasSekarang = !!sudahPotong && !!freshData.idTiket;'),
          isTrue,
          reason: 'stok hanya dilepas kalau memang pernah dipotong');
      expect(blok.contains('stok: (ticketData.stok || 0) + qty,'), isTrue);
    });
  });
}
