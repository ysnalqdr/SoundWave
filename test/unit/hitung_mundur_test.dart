// Hitungan waktu pembayaran
// Mengunci: satu format waktu ("02:47"), sisa waktu tidak pernah negatif,
// dan angka jendela pembayaran hanya ada di satu tempat (AppConstants).

import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/constants/app_constants.dart';
import 'package:soundwave/utils/hitung_mundur.dart';

void main() {
  group('formatHitungMundur', () {
    test('menit:detik dua digit', () {
      expect(formatHitungMundur(const Duration(minutes: 2, seconds: 47)), '02:47');
      expect(formatHitungMundur(const Duration(minutes: 3)), '03:00');
      expect(formatHitungMundur(const Duration(seconds: 59)), '00:59');
      expect(formatHitungMundur(const Duration(seconds: 5)), '00:05');
    });

    test('nol dan negatif tetap 00:00', () {
      expect(formatHitungMundur(Duration.zero), '00:00');
      expect(formatHitungMundur(const Duration(seconds: -30)), '00:00');
    });
  });

  group('sisaReservasi', () {
    final sekarang = DateTime(2026, 10, 17, 10, 0, 0);

    test('menghitung sisa dari reservedUntil', () {
      final sisa = sisaReservasi(
        sekarang.add(const Duration(minutes: 3)),
        sekarang: sekarang,
      );
      expect(sisa, const Duration(minutes: 3));
      expect(formatHitungMundur(sisa), '03:00');
    });

    test('sudah lewat → nol, bukan negatif', () {
      final sisa = sisaReservasi(
        sekarang.subtract(const Duration(seconds: 1)),
        sekarang: sekarang,
      );
      expect(sisa, Duration.zero);
    });

    test('reservedUntil null → nol', () {
      expect(sisaReservasi(null, sekarang: sekarang), Duration.zero);
    });
  });

  group('masihAdaWaktuBayar', () {
    final sekarang = DateTime(2026, 10, 17, 10, 0, 0);

    test('masih ada waktu', () {
      expect(
        masihAdaWaktuBayar(
            sekarang.add(const Duration(seconds: 30)), sekarang: sekarang),
        isTrue,
      );
    });

    test('tepat di batas → sudah habis', () {
      expect(masihAdaWaktuBayar(sekarang, sekarang: sekarang), isFalse);
    });

    test('lewat → habis', () {
      expect(
        masihAdaWaktuBayar(
            sekarang.subtract(const Duration(minutes: 1)), sekarang: sekarang),
        isFalse,
      );
    });
  });

  group('konstanta jendela pembayaran', () {
    test('5 menit, satu sumber angka', () {
      expect(AppConstants.reservationHoldMinutes, 5);
      expect(AppConstants.reservationHold, const Duration(minutes: 5));
    });

    test('kalimat penjelas memakai angka dari konstanta', () {
      expect(kalimatJendelaBayar(), contains('5 menit'));
      expect(kalimatJendelaBayar(), contains('stok tiket otomatis dilepas'));
    });

    test('status RESERVED dikenali', () {
      expect(AppConstants.orderStatusReserved, 'RESERVED');
    });
  });
}
