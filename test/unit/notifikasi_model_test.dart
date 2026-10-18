// ═══════════════════════════════════════════════════════════════════
// UNIT TEST — NotifikasiModel
// ═══════════════════════════════════════════════════════════════════
// Model ini membaca dokumen yang ditulis OTOMATIS oleh backend
// (server.js → kirimNotifikasi). Test ini mengunci:
//   · parsing semua field + tahan terhadap field hilang / tipe aneh
//   · createdAt bisa Timestamp / ISO string / epoch ms
//   · label jenis & umur notifikasi ("baru saja", "3 jam lalu", ...)
// ═══════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/models/notifikasi_model.dart';

void main() {
  group('NotifikasiModel.fromMap', () {
    test('membaca seluruh field dengan benar', () {
      final now = DateTime(2026, 10, 16, 20, 0);
      final n = NotifikasiModel.fromMap(<String, dynamic>{
        'userId': 'u1',
        'title': 'Refund Disetujui',
        'message': 'Rp 155.000 untuk SW-1234 disetujui.',
        'type': 'refund_approved',
        'refId': 'SW-1234',
        'read': true,
        'createdAt': Timestamp.fromDate(now),
      }, 'notif1');

      expect(n.id, 'notif1');
      expect(n.userId, 'u1');
      expect(n.title, 'Refund Disetujui');
      expect(n.message, 'Rp 155.000 untuk SW-1234 disetujui.');
      expect(n.type, 'refund_approved');
      expect(n.refId, 'SW-1234');
      expect(n.read, isTrue);
      expect(n.createdAt, now);
      expect(n.belumDibaca, isFalse);
    });

    test('field hilang memakai nilai aman (tidak crash)', () {
      final n = NotifikasiModel.fromMap(<String, dynamic>{}, 'n2');
      expect(n.id, 'n2');
      expect(n.userId, '');
      expect(n.title, 'Notifikasi');
      expect(n.message, '');
      expect(n.type, 'info');
      expect(n.refId, isNull);
      expect(n.read, isFalse);
      expect(n.belumDibaca, isTrue);
    });

    test('createdAt diterima sebagai Timestamp / ISO string / epoch ms', () {
      final now = DateTime(2026, 10, 16, 20, 0);

      final a = NotifikasiModel.fromMap(
          <String, dynamic>{'createdAt': Timestamp.fromDate(now)}, 'a');
      expect(a.createdAt, now);

      final b = NotifikasiModel.fromMap(
          <String, dynamic>{'createdAt': now.toIso8601String()}, 'b');
      expect(b.createdAt, now);

      final c = NotifikasiModel.fromMap(
          <String, dynamic>{'createdAt': now.millisecondsSinceEpoch}, 'c');
      expect(c.createdAt, now);
    });

    test('read hanya true bila benar-benar boolean true', () {
      expect(
          NotifikasiModel.fromMap(<String, dynamic>{'read': 'true'}, 'x').read,
          isFalse);
      expect(
          NotifikasiModel.fromMap(<String, dynamic>{'read': true}, 'x').read,
          isTrue);
    });
  });

  group('jenisLabel', () {
    NotifikasiModel buat(String type) =>
        NotifikasiModel.fromMap(<String, dynamic>{'type': type}, 'x');

    test('pembayaran → PEMBAYARAN', () {
      expect(buat('payment_success').jenisLabel, 'PEMBAYARAN');
      expect(buat('payment_cancelled').jenisLabel, 'PEMBAYARAN');
    });

    test('refund → REFUND (semua tahap)', () {
      for (final String t in <String>[
        'refund_requested',
        'refund_approved',
        'refund_rejected',
        'refund_required',
      ]) {
        expect(buat(t).jenisLabel, 'REFUND', reason: 'jenis $t');
      }
    });

    test('jenis tak dikenal → INFO', () {
      expect(buat('apa_saja').jenisLabel, 'INFO');
    });
  });

  group('waktuRelatif', () {
    NotifikasiModel umur(Duration d) => NotifikasiModel(
          id: 'x',
          userId: 'u1',
          title: 't',
          message: 'm',
          createdAt: DateTime.now().subtract(d),
        );

    test('di bawah 1 menit → "baru saja"', () {
      expect(umur(const Duration(seconds: 10)).waktuRelatif, 'baru saja');
    });

    test('menit', () {
      expect(umur(const Duration(minutes: 5, seconds: 30)).waktuRelatif,
          '5 menit lalu');
    });

    test('jam', () {
      expect(umur(const Duration(hours: 3, seconds: 30)).waktuRelatif,
          '3 jam lalu');
    });

    test('hari', () {
      expect(umur(const Duration(days: 2, seconds: 30)).waktuRelatif,
          '2 hari lalu');
    });

    test('lebih dari 7 hari → tanggal absolut (tanpa kata "lalu")', () {
      final DateTime d = DateTime.now().subtract(const Duration(days: 10));
      final String label = umur(const Duration(days: 10)).waktuRelatif;
      expect(label, isNot(contains('lalu')));
      expect(label, contains('${d.year}'));
      expect(label, contains('${d.day}'));
    });

    test('createdAt di masa depan tidak bikin angka negatif', () {
      expect(umur(const Duration(minutes: -5)).waktuRelatif, 'baru saja');
    });
  });
}
