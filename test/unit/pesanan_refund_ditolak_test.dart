// Unit test: catatan penolakan refund dibaca dari dokumen ORDER
// Latar belakang: admin menolak refund (order.refundStatus='REJECTED',
// order.refundRejectReason='Sorry') tetapi detail tiket user tidak
// menampilkan apa pun. Sebabnya app mengambil catatan itu lewat query ke
// koleksi `refunds` TANPA filter `userId`, sedangkan aturan Firestore
// menolak query seperti itu ("rules are not filters — all or nothing"),
// lalu error-nya ditelan `catch (_) { return null; }` → blok catatan
// penolakan tidak pernah dirender, tanpa error apa pun.
//
// Perbaikannya: baca langsung dari dokumen ORDER, yang sudah mengalir
// real-time ke daftar tiket (tanpa query tambahan, tanpa risiko aturan).
// Test ini mengunci pemetaan field-nya supaya tidak hilang lagi.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/constants/app_constants.dart';
import 'package:soundwave/models/pesanan_tiket_model.dart';

Map<String, dynamic> _order({
  String status = AppConstants.orderStatusActive,
  String? refundStatus,
  String? refundRejectReason,
}) {
  return <String, dynamic>{
    'kodeBooking': 'SW-43738457',
    'userId': 'user-uji',
    'status': status,
    'jumlahTiket': 1,
    'totalHarga': 6000,
    'tanggalBeli': Timestamp.fromDate(DateTime(2026, 10, 16, 16, 42)),
    'tanggalKonser': Timestamp.fromDate(DateTime(2026, 11, 1, 19, 0)),
    'refundStatus': refundStatus,
    'refundRejectReason': refundRejectReason,
  };
}

void main() {
  test('order dgn refund REJECTED → refundDitolak true + alasan terbaca', () {
    final t = PesananTiketModel.fromMap(
      _order(refundStatus: 'REJECTED', refundRejectReason: 'Sorry'),
      'ord-1',
    );

    expect(t.refundDitolak, isTrue);
    expect(t.alasanRefundDitolak, 'Sorry');
    expect(t.isAktif, isTrue,
        reason: 'tiket tetap AKTIF walau pengajuan refundnya ditolak');
  });

  test('alasan berisi spasi saja dianggap kosong (badge tidak bohong)', () {
    final t = PesananTiketModel.fromMap(
      _order(refundStatus: 'REJECTED', refundRejectReason: '   '),
      'ord-1',
    );

    expect(t.refundDitolak, isTrue);
    expect(t.alasanRefundDitolak, isEmpty);
  });

  test('order tanpa refundStatus → bukan refund gagal', () {
    final t = PesananTiketModel.fromMap(_order(), 'ord-1');

    expect(t.refundDitolak, isFalse);
    expect(t.alasanRefundDitolak, isEmpty);
  });

  test('status refund selain REJECTED tidak dianggap gagal', () {
    for (final String s in <String>['APPROVED', 'PENDING', 'REJECT', 'rejected']) {
      final t = PesananTiketModel.fromMap(_order(refundStatus: s), 'ord-1');
      expect(t.refundDitolak, isFalse, reason: 'status "$s" bukan REJECTED');
    }
  });

  test('copyWith (dipakai saat scan gate) TIDAK menghapus catatan penolakan',
      () {
    final t = PesananTiketModel.fromMap(
      _order(refundStatus: 'REJECTED', refundRejectReason: 'Sorry'),
      'ord-1',
    );
    final setelahScan = t.copyWith(status: AppConstants.orderStatusUsed);

    expect(setelahScan.refundDitolak, isTrue);
    expect(setelahScan.alasanRefundDitolak, 'Sorry');
    expect(setelahScan.isTerpakai, isTrue);
  });

  test('toMap membawa field refund apa adanya', () {
    final t = PesananTiketModel.fromMap(
      _order(refundStatus: 'REJECTED', refundRejectReason: 'Sorry'),
      'ord-1',
    );
    final Map<String, dynamic> m = t.toMap();

    expect(m['refundStatus'], 'REJECTED');
    expect(m['refundRejectReason'], 'Sorry');
  });
}
