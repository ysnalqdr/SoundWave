// Layar sempit: cek pixels error (RenderFlex overflow)
// Dijalankan di lebar 320 dp (HP kecil) karena kotak pending memuat teks
// besar, tombol lebar penuh, dan baris badge. Kalau ada yang meluber,
// Flutter melempar exception dan test ini gagal.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/constants/app_constants.dart';
import 'package:soundwave/models/pesanan_tiket_model.dart';
import 'package:soundwave/widgets/hitung_mundur_teks.dart';
import 'package:soundwave/widgets/kotak_pending_tiket.dart';

PesananTiketModel pesanan({DateTime? reservedUntil}) => PesananTiketModel(
      id: 'ord-1',
      kodeBooking: 'SW-1',
      idKonser: 'k1',
      judulKonser: 'Soundwave Fest 2026',
      gambarKonser: 'assets/images/konser/baskara.jpg',
      kategoriTiket: 'Festival',
      idTiket: 't1',
      jumlahTiket: 2,
      totalHarga: 210000,
      tanggalBeli: DateTime(2026, 10, 17, 10, 0),
      tanggalKonser: DateTime(2026, 12, 1),
      lokasiKonser: 'Gelora Bung Karno, Jakarta',
      namaPembeli: 'Budi',
      emailPembeli: 'budi@example.com',
      userId: 'uid-budi',
      status: AppConstants.orderStatusReserved,
      reservedUntil: reservedUntil,
    );

Future<void> pumpDiLayarSempit(WidgetTester tester, Widget anak) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: anak,
      ),
    ),
  ));
}

void main() {
  testWidgets('kotak menunggu bayar tidak meluber di 320dp', (tester) async {
    await pumpDiLayarSempit(
      tester,
      KotakPendingTiket(
        tiket: pesanan(reservedUntil: DateTime.now().add(const Duration(minutes: 5))),
        onBayar: () {},
        onPesanUlang: () {},
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Bayar Sekarang'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('kotak reservasi berakhir tidak meluber di 320dp',
      (tester) async {
    await pumpDiLayarSempit(
      tester,
      KotakPendingTiket(
        tiket: pesanan(
            reservedUntil: DateTime.now().subtract(const Duration(minutes: 1))),
        onBayar: () {},
        onPesanUlang: () {},
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('RESERVASI BERAKHIR'), findsOneWidget);
    expect(find.text('Pesan Ulang'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('hitungan waktu 5 menit tidak meluber di 320dp', (tester) async {
    await pumpDiLayarSempit(
      tester,
      HitungMundurTeks(
        sampai: DateTime.now().add(const Duration(minutes: 5)),
        awalan: 'Sisa waktu ',
        gaya: const TextStyle(fontSize: 34, letterSpacing: 2),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('kotak pending aman di layar sangat pendek (568dp)', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: KotakPendingTiket(
          tiket: pesanan(
              reservedUntil: DateTime.now().add(const Duration(seconds: 30))),
          onBayar: () {},
          onPesanUlang: () {},
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
