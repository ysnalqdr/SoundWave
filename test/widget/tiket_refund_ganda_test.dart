// Penjaga sumber: catatan penolakan refund, badge ganda, tanggal beli
// Mengunci tiga hal yang pernah salah di layar "Tiket Saya":
//   1. catatan penolakan refund TIDAK muncul (query `refunds` tanpa filter
//      `userId` → ditolak aturan Firestore → ditelan `catch` → null);
//   2. badge hanya "AKTIF" padahal refundnya ditolak → harus dua badge
//      berdampingan kiri-kanan: [REFUND GAGAL] [AKTIF];
//   3. tidak ada tanggal + waktu pembelian di tiket.
// Test ini membaca sumber dan gagal kalau salah satunya balik lagi.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const String berkasLayar = 'lib/screens/user/user_tiket_screen.dart';
  const String berkasService = 'lib/services/database_service.dart';

  late String layar;
  late String service;

  setUpAll(() {
    layar = File(berkasLayar).readAsStringSync();
    service = File(berkasService).readAsStringSync();
  });

  test('layar tiket TIDAK lagi query koleksi refunds (aturan Firestore '
      'menolak query tanpa filter userId)', () {
    expect(layar.contains("collection('refunds')"), isFalse,
        reason: 'query refunds dari sisi user akan ditolak aturan '
            '("rules are not filters") dan errornya tak terlihat');
    expect(layar.contains('getLatestRefundForOrder'), isFalse);
    expect(service.contains('getLatestRefundForOrder'), isFalse,
        reason: 'method query refunds tanpa filter userId sudah dihapus '
            'supaya tidak jadi jebakan lagi');
  });

  test('catatan penolakan dibaca dari dokumen order', () {
    expect(layar.contains('tiket.refundDitolak'), isTrue);
    expect(layar.contains('tiket.alasanRefundDitolak'), isTrue);
    expect(layar.contains('PENGAJUAN REFUND DITOLAK'), isTrue);
  });

  test('badge "REFUND GAGAL" ada dan dipakai berdampingan dengan badge status',
      () {
    expect(layar.contains("'REFUND GAGAL'"), isTrue,
        reason: 'label badge merah refund gagal');
    expect(layar.contains("_buildBadgeStatus('REFUND_REJECTED')"), isTrue);
    expect(layar.contains('_buildBadgeGanda'), isTrue);

    final int idx = layar.indexOf('Widget _buildBadgeGanda(');
    expect(idx, greaterThanOrEqualTo(0));

    final String badan = layar.substring(idx, idx + 1400);
    expect(badan.contains("_buildBadgeStatus('REFUND_REJECTED')"), isTrue);
    expect(badan.contains("_buildBadgeStatus(item.isExpired ? 'EXPIRED' : item.status)"),
        isTrue,
        reason: 'badge kedua harus status ASLI tiket (AKTIF/TERPAKAI), '
            'jangan di-hardcode "AKTIF"');
  });

  test('badge ganda dipakai di kartu daftar DAN di detail tiket', () {
    final int kartu = layar.indexOf('Widget _buildKartuTiket(');
    final int sheet = layar.indexOf('Widget _buildSheet(');
    expect(kartu, greaterThanOrEqualTo(0));
    expect(sheet, greaterThan(kartu));

    final String isiKartu = layar.substring(kartu, sheet);
    expect(isiKartu.contains('_buildBadgeGanda(item'), isTrue,
        reason: 'kartu daftar tiket harus memakai badge ganda');

    final String isiSheet = layar.substring(sheet);
    expect(isiSheet.contains("_buildBadgeStatus('REFUND_REJECTED')"), isTrue,
        reason: 'detail tiket harus menampilkan badge REFUND GAGAL');
  });

  test('tanggal + waktu pembelian tampil di kartu dan di detail', () {
    expect(layar.contains('_formatTanggalWaktu'), isTrue);
    expect(
        layar.contains("'Dibeli \${_formatTanggalWaktu(item.tanggalBeli)}'"),
        isTrue,
        reason: 'kartu daftar tiket harus menampilkan tanggal beli');
    expect(layar.contains("'Dibeli', _formatTanggalWaktu(tiket.tanggalBeli)"),
        isTrue,
        reason: 'detail tiket harus punya baris Dibeli + jam pembelian');
    expect(layar.contains('·'), isTrue,
        reason: 'format "16 Okt 2026 · 16:42" memakai pemisah titik tengah');
  });

  test('baris badge memakai Wrap supaya tidak meluber di layar sempit', () {
    final int kartu = layar.indexOf('Widget _buildKartuTiket(');
    final int sheet = layar.indexOf('Widget _buildSheet(');
    expect(kartu, greaterThanOrEqualTo(0));
    expect(sheet, greaterThan(kartu));

    final String isiKartu = layar.substring(kartu, sheet);
    expect(isiKartu.contains('Wrap('), isTrue,
        reason: 'dua badge + kategori bisa meluber di layar sempit; '
            'pakai Wrap supaya badge turun baris, bukan overflow');
    expect(isiKartu.contains('_buildBadgeGanda(item'), isTrue);
  });
}
