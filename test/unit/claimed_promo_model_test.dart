import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/models/claimed_promo_model.dart';

void main() {
  ClaimedPromoModel build({
    String tipe = 'percentage',
    double nilai = 10,
    double minPembelian = 0,
    DateTime? berlakuAkhir,
    bool used = false,
  }) {
    return ClaimedPromoModel(
      promoId: 'p1',
      kode: 'HEMAT10',
      tipe: tipe,
      nilai: nilai,
      minPembelian: minPembelian,
      berlakuAkhir: berlakuAkhir,
      claimedAt: DateTime(2026, 1, 1),
      used: used,
    );
  }

  group('ClaimedPromoModel.discountAmount', () {
    test('percentage: potong sesuai persen subtotal', () {
      expect(build(tipe: 'percentage', nilai: 10).discountAmount(100000), 10000);
    });

    test('percentage tidak melebihi subtotal', () {
      expect(build(tipe: 'percentage', nilai: 150).discountAmount(100000),
          100000);
    });

    test('fixed: potong nominal tetap', () {
      expect(build(tipe: 'fixed', nilai: 25000).discountAmount(100000), 25000);
    });

    test('fixed tidak melebihi subtotal', () {
      expect(build(tipe: 'fixed', nilai: 25000).discountAmount(10000), 10000);
    });

    test('subtotal di bawah minPembelian -> tidak dapat diskon', () {
      expect(build(minPembelian: 50000).discountAmount(40000), 0);
    });

    test('subtotal tepat sama dengan minPembelian -> dapat diskon', () {
      expect(build(nilai: 10, minPembelian: 50000).discountAmount(50000), 5000);
    });
  });

  group('ClaimedPromoModel status', () {
    test('voucher baru -> TERSEDIA & isUsable', () {
      final v = build();
      expect(v.statusLabel, 'TERSEDIA');
      expect(v.isUsable, isTrue);
    });

    test('sudah dipakai -> TERPAKAI & tidak usable', () {
      final v = build(used: true);
      expect(v.statusLabel, 'TERPAKAI');
      expect(v.isUsable, isFalse);
    });

    test('lewat masa berlaku -> KEDALUWARSA & tidak usable', () {
      final v = build(berlakuAkhir: DateTime.now().subtract(const Duration(days: 1)));
      expect(v.statusLabel, 'KEDALUWARSA');
      expect(v.isUsable, isFalse);
    });

    test('labelNilai untuk percentage & fixed', () {
      expect(build(tipe: 'percentage', nilai: 15).labelNilai, '15%');
      expect(build(tipe: 'fixed', nilai: 25000).labelNilai, 'Rp 25000');
    });
  });

  group('ClaimedPromoModel.fromMap (defensive)', () {
    test('parse Timestamp, ISO string, dan null', () {
      final fromTs = ClaimedPromoModel.fromMap({
        'promoId': 'x',
        'kode': 'ABC',
        'tipe': 'fixed',
        'nilai': 10000,
        'claimedAt': Timestamp.fromDate(DateTime(2026, 3, 4)),
        'berlakuAkhir': '2027-01-01T00:00:00.000Z',
        'used': false,
      }, 'x');
      expect(fromTs.kode, 'ABC');
      expect(fromTs.claimedAt.year, 2026);
      expect(fromTs.claimedAt.month, 3);
      expect(fromTs.berlakuAkhir?.year, 2027);
      expect(fromTs.isUsable, isTrue);

      // claimedAt null -> fallback DateTime.now(), tidak crash
      final nullish = ClaimedPromoModel.fromMap({
        'kode': 'DEF',
      }, 'def-id');
      expect(nullish.promoId, 'def-id');
      expect(nullish.claimedAt, isNotNull);
      expect(nullish.nilai, 0);
    });
  });
}
