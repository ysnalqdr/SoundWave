// ═══════════════════════════════════════════════════════════════════
// ANGKA DASHBOARD ADMIN
// ═══════════════════════════════════════════════════════════════════
// Dashboard menghitung sendiri dari stream yang sudah ada. Test ini mengunci
// definisinya supaya angka di layar tidak pernah "beda rasa" dengan laporan:
// pendapatan hanya dari pesanan lunas, tiket terjual menghitung lembar,
// dan grafik 7 hari memakai tanggal beli.

import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/constants/app_constants.dart';
import 'package:soundwave/models/pesanan_tiket_model.dart';
import 'package:soundwave/models/tiket_konser_model.dart';
import 'package:soundwave/utils/ringkasan_admin.dart';

PesananTiketModel pesanan({
  required String status,
  double total = 100000,
  int jumlah = 1,
  DateTime? tanggalBeli,
  DateTime? reservedUntil,
  String? refundStatus,
}) {
  final kini = DateTime.now();
  return PesananTiketModel(
    id: 'ord-$status-${total.toInt()}-$jumlah',
    kodeBooking: 'SW-1',
    idKonser: 'k1',
    judulKonser: 'SnapFest',
    gambarKonser: '',
    kategoriTiket: 'VVIP',
    jumlahTiket: jumlah,
    totalHarga: total,
    tanggalBeli: tanggalBeli ?? kini,
    tanggalKonser: kini.add(const Duration(days: 30)),
    lokasiKonser: 'Medan',
    namaPembeli: 'Budi',
    emailPembeli: 'budi@example.com',
    userId: 'uid-1',
    status: status,
    reservedUntil: reservedUntil,
    refundStatus: refundStatus,
  );
}

TiketKonserModel tiket(String kategori, {required int stok, int terjual = 0}) =>
    TiketKonserModel(
      id: 't-$kategori',
      idKonser: 'k1',
      judulKonser: 'SnapFest',
      gambarKonser: '',
      kategori: kategori,
      harga: 500000,
      stok: stok,
      terjual: terjual,
    );

void main() {
  test('pendapatan hanya dari pesanan lunas, bukan yang menunggu bayar', () {
    final r = hitungRingkasan(
      pesanan: [
        pesanan(status: AppConstants.orderStatusActive, total: 500000, jumlah: 2),
        pesanan(status: AppConstants.orderStatusUsed, total: 300000),
        pesanan(status: AppConstants.orderStatusPending, total: 900000),
        pesanan(status: AppConstants.orderStatusReserved, total: 700000),
        pesanan(status: AppConstants.orderStatusExpired, total: 800000),
      ],
      tiket: const [],
    );

    expect(r.pendapatan, 800000);
    expect(r.tiketTerjual, 3, reason: '2 lembar AKTIF + 1 lembar TERPAKAI');
    expect(r.totalPesanan, 5);
  });

  test('pesanan menunggu bayar dihitung terpisah dari pendapatan', () {
    final r = hitungRingkasan(
      pesanan: [
        pesanan(status: AppConstants.orderStatusPending),
        pesanan(status: AppConstants.orderStatusReserved),
        pesanan(status: AppConstants.orderStatusActive),
      ],
      tiket: const [],
    );

    expect(r.menungguBayar, 2);
    expect(r.pendapatan, 100000);
  });

  test('reservasi dengan sisa waktu di bawah 10 menit ditandai mendesak', () {
    final kini = DateTime.now();
    final r = hitungRingkasan(
      pesanan: [
        pesanan(
          status: AppConstants.orderStatusReserved,
          reservedUntil: kini.add(const Duration(minutes: 4)),
        ),
        pesanan(
          status: AppConstants.orderStatusReserved,
          reservedUntil: kini.add(const Duration(minutes: 40)),
        ),
      ],
      tiket: const [],
      sekarang: kini,
    );

    expect(r.menungguBayar, 2);
    expect(r.hampirKedaluwarsa, 1);
  });

  test('refund yang menunggu keputusan dihitung, yang sudah selesai tidak', () {
    final r = hitungRingkasan(
      pesanan: [
        pesanan(status: AppConstants.orderStatusRefundRequested),
        pesanan(status: AppConstants.orderStatusRefundRequired),
        pesanan(status: AppConstants.orderStatusRefunded),
        pesanan(status: AppConstants.orderStatusActive),
      ],
      tiket: const [],
    );

    expect(r.refundPerluTinjauan, 2);
  });

  test('stok kritis menghitung kategori dengan sisa 10 atau kurang', () {
    final r = hitungRingkasan(
      pesanan: const [],
      tiket: [
        tiket('VVIP', stok: 0),
        tiket('VIP', stok: 10),
        tiket('Festival', stok: 11),
        tiket('Tribun', stok: 40),
      ],
    );

    expect(r.stokKritis, 2);
  });

  test('grafik selalu 7 titik dan menjumlahkan per tanggal beli', () {
    final kini = DateTime.now();
    final kemarin = kini.subtract(const Duration(days: 1));

    final r = hitungRingkasan(
      pesanan: [
        pesanan(
          status: AppConstants.orderStatusActive,
          total: 200000,
          tanggalBeli: kini,
        ),
        pesanan(
          status: AppConstants.orderStatusUsed,
          total: 300000,
          tanggalBeli: kini,
        ),
        pesanan(
          status: AppConstants.orderStatusActive,
          total: 150000,
          tanggalBeli: kemarin,
        ),
        // Di luar jendela 7 hari -> tidak masuk grafik, tapi tetap dihitung
        // sebagai pendapatan total.
        pesanan(
          status: AppConstants.orderStatusActive,
          total: 999000,
          tanggalBeli: kini.subtract(const Duration(days: 30)),
        ),
      ],
      tiket: const [],
      sekarang: kini,
    );

    expect(r.penjualanHarian.length, 7);
    expect(r.penjualanHarian.last, 500000, reason: 'hari ini');
    expect(r.penjualanHarian[5], 150000, reason: 'kemarin');
    expect(r.pendapatan, 1649000);
    expect(r.hariTerbaik, isNotNull);
  });

  test('dashboard tenang hanya bila tidak ada refund, stok kritis, atau urgensi', () {
    final bersih = hitungRingkasan(
      pesanan: [pesanan(status: AppConstants.orderStatusActive)],
      tiket: [tiket('VVIP', stok: 100)],
    );
    expect(bersih.tenang, isTrue);

    final adaRefund = hitungRingkasan(
      pesanan: [pesanan(status: AppConstants.orderStatusRefundRequested)],
      tiket: [tiket('VVIP', stok: 100)],
    );
    expect(adaRefund.tenang, isFalse);
  });
}
