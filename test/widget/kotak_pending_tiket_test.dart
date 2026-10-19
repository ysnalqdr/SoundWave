// Kotak pending: berpindah sendiri saat waktu habis
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/constants/app_constants.dart';
import 'package:soundwave/models/pesanan_tiket_model.dart';
import 'package:soundwave/widgets/kotak_pending_tiket.dart';

PesananTiketModel pesanan({DateTime? reservedUntil}) => PesananTiketModel(
      id: 'ord-1',
      kodeBooking: 'SW-1',
      idKonser: 'k1',
      judulKonser: 'Soundwave Fest',
      gambarKonser: 'assets/images/konser/baskara.jpg',
      kategoriTiket: 'Festival',
      idTiket: 't1',
      jumlahTiket: 1,
      totalHarga: 105000,
      tanggalBeli: DateTime(2026, 10, 17, 10, 0),
      tanggalKonser: DateTime(2026, 12, 1),
      lokasiKonser: 'GBK Jakarta',
      namaPembeli: 'Budi',
      emailPembeli: 'budi@example.com',
      userId: 'uid-budi',
      status: AppConstants.orderStatusReserved,
      reservedUntil: reservedUntil,
    );

void main() {
  testWidgets('selama ada waktu: hitungan berdetak + tombol bayar',
      (tester) async {
    var sekarang = DateTime(2026, 10, 17, 10, 0, 0);
    var dibayar = 0;
    var kedaluwarsa = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: KotakPendingTiket(
          tiket: pesanan(reservedUntil: DateTime(2026, 10, 17, 10, 0, 2)),
          jam: () => sekarang,
          onBayar: () => dibayar++,
          onPesanUlang: () {},
          onKedaluwarsa: () => kedaluwarsa++,
        ),
      ),
    ));

    expect(find.text('Menunggu Pembayaran'), findsOneWidget);
    expect(find.text('Sisa waktu 00:02'), findsOneWidget);
    expect(find.text('Bayar Sekarang'), findsOneWidget);
    expect(find.text('RESERVASI BERAKHIR'), findsNothing);

    await tester.tap(find.text('Bayar Sekarang'));
    await tester.pump();
    expect(dibayar, 1, reason: 'tombol bayar memanggil wizard pembayaran');

    await tester.pumpWidget(const SizedBox()); // batalkan Timer
  });

  testWidgets('waktu habis: berubah sendiri jadi RESERVASI BERAKHIR',
      (tester) async {
    var sekarang = DateTime(2026, 10, 17, 10, 0, 0);
    var kedaluwarsa = 0;
    var pesanUlang = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: KotakPendingTiket(
          tiket: pesanan(reservedUntil: DateTime(2026, 10, 17, 10, 0, 2)),
          jam: () => sekarang,
          onBayar: () {},
          onPesanUlang: () => pesanUlang++,
          onKedaluwarsa: () => kedaluwarsa++,
        ),
      ),
    ));

    expect(find.text('Bayar Sekarang'), findsOneWidget);

    // Detik ke-2 masih ada waktu.
    sekarang = sekarang.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Sisa waktu 00:01'), findsOneWidget);
    expect(find.text('Bayar Sekarang'), findsOneWidget);
    expect(kedaluwarsa, 0);

    // Detik ke-3: waktu habis → berubah tanpa perlu refresh dari luar.
    sekarang = sekarang.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('RESERVASI BERAKHIR'), findsOneWidget);
    expect(find.text('Pesan Ulang'), findsOneWidget);
    expect(find.text('Bayar Sekarang'), findsNothing,
        reason: 'pesanan kedaluwarsa tidak boleh bisa dibayar lagi');
    expect(kedaluwarsa, 1,
        reason: 'server diminta menyapu pesanan ini tepat saat waktu habis');

    // Tidak boleh terpanggil dua kali.
    sekarang = sekarang.add(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(kedaluwarsa, 1);

    await tester.tap(find.text('Pesan Ulang'));
    await tester.pump();
    expect(pesanUlang, 1);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reservasi tanpa batas waktu langsung berakhir', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: KotakPendingTiket(
          tiket: pesanan(reservedUntil: null),
          onBayar: () {},
          onPesanUlang: () {},
        ),
      ),
    ));

    expect(find.text('RESERVASI BERAKHIR'), findsOneWidget);
    expect(find.text('Bayar Sekarang'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
