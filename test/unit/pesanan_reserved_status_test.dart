// ═══════════════════════════════════════════════════════════════════
// STATUS RESERVED = MENUNGGU BAYAR (bukan status asing)
// ═══════════════════════════════════════════════════════════════════
// Pesanan yang sudah masuk wizard pembayaran disimpan sebagai RESERVED
// (stok sudah dipotong). Sebelum ini aplikasi tidak mengenal status itu,
// sehingga tiketnya hilang dari tab PENDING dan tidak punya hitungan waktu.
// Test ini mengunci pemetaannya.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/constants/app_constants.dart';
import 'package:soundwave/models/pesanan_tiket_model.dart';

PesananTiketModel buat({
  String status = AppConstants.orderStatusPending,
  DateTime? reservedUntil,
  DateTime? tanggalBeli,
}) {
  return PesananTiketModel(
    id: 'ord-1',
    kodeBooking: 'SW-1',
    idKonser: 'k1',
    judulKonser: 'Soundwave Fest',
    gambarKonser: 'assets/images/konser/baskara.jpg',
    kategoriTiket: 'Festival',
    idTiket: 't1',
    jumlahTiket: 1,
    totalHarga: 105000,
    tanggalBeli: tanggalBeli ?? DateTime.now(),
    tanggalKonser: DateTime(2026, 12, 1),
    lokasiKonser: 'GBK Jakarta',
    namaPembeli: 'Budi',
    emailPembeli: 'budi@example.com',
    userId: 'uid-budi',
    status: status,
    reservedUntil: reservedUntil,
  );
}

void main() {
  test('RESERVED dihitung sebagai menunggu pembayaran', () {
    final order = buat(
      status: AppConstants.orderStatusReserved,
      reservedUntil: DateTime.now().add(const Duration(minutes: 2)),
    );
    expect(order.isPending, isTrue,
        reason: 'RESERVED harus muncul di tab PENDING dan punya tombol bayar');
    expect(order.isExpired, isFalse);
    expect(order.isAktif, isFalse);
  });

  test('RESERVED yang waktunya lewat dianggap kedaluwarsa', () {
    final order = buat(
      status: AppConstants.orderStatusReserved,
      reservedUntil: DateTime.now().subtract(const Duration(seconds: 1)),
    );
    expect(order.isExpired, isTrue);
  });

  test('PENDING yang waktunya lewat juga kedaluwarsa', () {
    final order = buat(
      status: AppConstants.orderStatusPending,
      reservedUntil: DateTime.now().subtract(const Duration(minutes: 1)),
    );
    expect(order.isExpired, isTrue);
  });

  test('status EXPIRED eksplisit tetap kedaluwarsa', () {
    final order = buat(status: AppConstants.orderStatusExpired);
    expect(order.isExpired, isTrue);
    expect(order.isPending, isFalse);
  });

  test('AKTIF tidak pernah dianggap pending', () {
    final order = buat(
      status: AppConstants.orderStatusActive,
      reservedUntil: DateTime.now().add(const Duration(minutes: 3)),
    );
    expect(order.isPending, isFalse);
    expect(order.isExpired, isFalse);
    expect(order.isAktif, isTrue);
  });

  test('reservedUntil kosong pada PENDING memakai batas 24 jam (data lama)', () {
    // Data lama tanpa reservedUntil, umur pesanan masih di bawah 24 jam.
    final order = buat(
      status: AppConstants.orderStatusPending,
      tanggalBeli: DateTime.now().subtract(const Duration(hours: 23)),
    );
    expect(order.isExpired, isFalse);
  });

  test('reservedUntil kosong dan umur lewat 24 jam dianggap kedaluwarsa', () {
    final order = buat(
      status: AppConstants.orderStatusPending,
      tanggalBeli: DateTime.now().subtract(const Duration(hours: 25)),
    );
    expect(order.isExpired, isTrue);
  });
}
