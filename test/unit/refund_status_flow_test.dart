import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/constants/app_constants.dart';
import 'package:soundwave/models/pesanan_tiket_model.dart';
import 'package:soundwave/models/refund_model.dart';

/// Regresi alur refund admin → user:
/// - APPROVE  : order REFUNDED  → badge "DI-REFUND", TIDAK bisa discan, stok dipulihkan
/// - REJECT   : order AKTIF     → tiket bisa discan lagi + user lihat alasan tolak
void main() {
  PesananTiketModel order(String status, {bool scanned = false}) =>
      PesananTiketModel(
        id: 'o1',
        kodeBooking: 'SW-1',
        idKonser: 'e1',
        judulKonser: 'Konser Uji',
        gambarKonser: '',
        kategoriTiket: 'VVIP',
        jumlahTiket: 2,
        totalHarga: 200000,
        tanggalBeli: DateTime(2026, 1, 1),
        tanggalKonser: DateTime(2026, 6, 1),
        lokasiKonser: 'Jakarta',
        namaPembeli: 'Uji',
        emailPembeli: 'uji@test.com',
        userId: 'u1',
        status: status,
        tanggalDigunakan: scanned ? DateTime(2026, 2, 1) : null,
      );

  RefundModel refund({String status = 'PENDING', String? alasanReject}) =>
      RefundModel(
        id: 'r1',
        orderId: 'o1',
        userId: 'u1',
        alasan: 'tidak bisa hadir',
        status: status,
        alasanReject: alasanReject,
        tanggalRequest: DateTime(2026, 1, 2),
        kodeBooking: 'SW-1',
        judulKonser: 'Konser Uji',
        namaPembeli: 'Uji',
        jumlahTiket: 2,
        totalHarga: 200000,
      );

  group('Status pesanan terkait refund', () {
    test('REFUND_REQUESTED: ditinjau admin, tiket belum bisa dipakai', () {
      final o = order(AppConstants.orderStatusRefundRequested);
      expect(o.isRefundRequested, isTrue);
      expect(o.isRefundRequired, isTrue);
      expect(o.isRefunded, isFalse);
      expect(o.isAktif, isFalse);
    });

    test('REFUND_REQUIRED: refund otomatis (pembayaran telat)', () {
      final o = order(AppConstants.orderStatusRefundRequired);
      expect(o.isRefundRequired, isTrue);
      expect(o.isRefundRequested, isFalse);
      expect(o.isRefunded, isFalse);
    });

    test('REFUNDED (disetujui): final, tidak dihitung aktif', () {
      final o = order(AppConstants.orderStatusRefunded);
      expect(o.isRefunded, isTrue);
      expect(o.isRefundRequired, isFalse);
      expect(o.isRefundRequested, isFalse);
      expect(o.isAktif, isFalse);
    });

    test('AKTIF (ditolak): kembali normal', () {
      final o = order(AppConstants.orderStatusActive);
      expect(o.isAktif, isTrue);
      expect(o.isRefundRequired, isFalse);
      expect(o.isRefunded, isFalse);
    });
  });

  group('Filter tab "Tiket Saya"', () {
    final semua = [
      order(AppConstants.orderStatusActive),
      order(AppConstants.orderStatusPending),
      order(AppConstants.orderStatusUsed),
      order(AppConstants.orderStatusRefundRequested),
      order(AppConstants.orderStatusRefundRequired),
      order(AppConstants.orderStatusRefunded),
    ];

    test('tab REFUND memuat yang diproses DAN yang sudah di-refund', () {
      final tab = semua
          .where((p) => p.isRefundRequired || p.isRefunded)
          .map((p) => p.status)
          .toList();
      expect(tab, containsAll([
        AppConstants.orderStatusRefundRequested,
        AppConstants.orderStatusRefundRequired,
        AppConstants.orderStatusRefunded,
      ]));
      expect(tab.length, 3);
    });

    test('tab AKTIF tidak memuat tiket yang sudah DI-REFUND', () {
      final tab = semua
          .where((p) => p.isAktif || p.isRefundRequired)
          .map((p) => p.status)
          .toList();
      expect(tab, isNot(contains(AppConstants.orderStatusRefunded)));
            // Refund DIPROSES tetap tampil supaya tiket tidak "menghilang".
      expect(tab, contains(AppConstants.orderStatusRefundRequested));
    });
  });

  group('Validasi scan gate (hanya AKTIF yang boleh masuk)', () {
    test('REFUND_REQUESTED & REFUNDED ditolak, AKTIF diterima', () {
      expect(order(AppConstants.orderStatusActive).isAktif, isTrue);
      expect(order(AppConstants.orderStatusRefundRequested).isAktif, isFalse);
      expect(order(AppConstants.orderStatusRefunded).isAktif, isFalse);
      expect(
        order(AppConstants.orderStatusUsed).isAktif,
        isFalse,
        reason: 'tiket yang sudah discan tidak boleh dipakai 2x',
      );
    });
  });

  group('RefundModel', () {
    test('predikat status', () {
      expect(refund(status: 'PENDING').isPending, isTrue);
      expect(refund(status: 'APPROVED').isApproved, isTrue);
      expect(refund(status: 'REJECTED', alasanReject: 'maaf').isRejected, isTrue);
    });

    test('fromMap: status uppercase + alasanReject + amount → refundAmount', () {
      final r = RefundModel.fromMap({
        'orderId': 'o9',
        'userId': 'u9',
        'alasan': 'sakit',
        'status': 'rejected',
        'alasanReject': 'melewati batas H-3',
        'amount': 150000,
        'createdAt': Timestamp.fromDate(DateTime(2026, 3, 5)),
      }, 'r9');
      expect(r.status, 'REJECTED');
      expect(r.isRejected, isTrue);
      expect(r.alasanReject, 'melewati batas H-3');
      expect(r.refundAmount, 150000);
      expect(r.tanggalRequest.year, 2026);
      expect(r.tanggalRequest.month, 3);
    });
  });
}
