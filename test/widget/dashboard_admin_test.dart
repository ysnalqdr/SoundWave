// Dashboard admin: cek tampil tanpa pixels error
// Dashboard adalah layar pertama setelah login admin, jadi paling sering
// dilihat dan paling mahal kalau meluber. Dua lebar diuji:
//   393 dp = HP normal (sumber screenshot README)
//   320 dp = HP kecil, batas bawah yang masih didukung
// Semua provider diganti data palsu supaya test tidak menyentuh Firebase.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/constants/app_constants.dart';
import 'package:soundwave/models/konser_model.dart';
import 'package:soundwave/models/pesanan_tiket_model.dart';
import 'package:soundwave/models/tiket_konser_model.dart';
import 'package:soundwave/models/user_model.dart';
import 'package:soundwave/providers/app_providers.dart';
import 'package:soundwave/screens/admin/dashboard_admin_screen.dart';

UserModel adminUji() => UserModel(
      id: 'uid-admin',
      nama: 'Operator SoundWave',
      email: 'admin@example.com',
      role: AppConstants.roleAdmin,
    );

KonserModel konserUji(String id, {int hariKe = 20}) => KonserModel(
      id: id,
      judul: 'SoundWave Fest Jakarta 2026',
      lokasi: 'Gelora Bung Karno, Jakarta',
      tanggal: DateTime.now().add(Duration(days: hariKe)),
      harga: 500000,
      genre: const ['Pop', 'Rock'],
    );

TiketKonserModel tiketUji(
  String id,
  String kategori, {
  required int stok,
  int terjual = 0,
}) =>
    TiketKonserModel(
      id: id,
      idKonser: 'k1',
      judulKonser: 'SoundWave Fest Jakarta 2026',
      gambarKonser: '',
      kategori: kategori,
      harga: 500000,
      stok: stok,
      terjual: terjual,
    );

PesananTiketModel pesananUji(
  String id, {
  required String status,
  double total = 1005000,
  int jumlah = 2,
  DateTime? reservedUntil,
  String? refundStatus,
}) {
  final kini = DateTime.now();
  return PesananTiketModel(
    id: id,
    kodeBooking: 'SW-28273727',
    idKonser: 'k1',
    judulKonser: 'SoundWave Fest Jakarta 2026',
    gambarKonser: '',
    kategoriTiket: 'VVIP',
    jumlahTiket: jumlah,
    totalHarga: total,
    tanggalBeli: kini,
    tanggalKonser: kini.add(const Duration(days: 20)),
    lokasiKonser: 'Gelora Bung Karno, Jakarta',
    namaPembeli: 'Pembeli Uji',
    emailPembeli: 'pembeli@example.com',
    userId: 'uid-pembeli',
    status: status,
    reservedUntil: reservedUntil,
    refundStatus: refundStatus,
  );
}

Future<void> pumpDashboard(
  WidgetTester tester,
  double lebar, {
  double tinggi = 852,
}) async {
  tester.view.physicalSize = Size(lebar, tinggi);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final pesanan = [
    pesananUji('o1', status: AppConstants.orderStatusActive),
    pesananUji('o2', status: AppConstants.orderStatusUsed, total: 750000),
    pesananUji(
      'o3',
      status: AppConstants.orderStatusReserved,
      total: 400000,
      reservedUntil: DateTime.now().add(const Duration(minutes: 3)),
    ),
    pesananUji(
      'o4',
      status: AppConstants.orderStatusRefundRequested,
      total: 300000,
      refundStatus: AppConstants.orderStatusRefundRequested,
    ),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        eventsProvider.overrideWith(
          (ref) => Stream<List<KonserModel>>.value([
            konserUji('k1'),
            konserUji('k2', hariKe: 45),
          ]),
        ),
        allTicketsProvider.overrideWith(
          (ref) => Stream<List<TiketKonserModel>>.value([
            tiketUji('t1', 'VVIP', stok: 4, terjual: 46),
            tiketUji('t2', 'VIP', stok: 80, terjual: 20),
          ]),
        ),
        allOrdersProvider.overrideWith(
          (ref) => Stream<List<PesananTiketModel>>.value(pesanan),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: DashboardAdminScreen(
          user: adminUji(),
          onBukaSidebar: () {},
          onBukaMenu: (_) {},
        ),
      ),
    ),
  );

  // Biarkan stream mengirim snapshot pertama.
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dashboard tampil penuh di 393dp tanpa overflow',
      (tester) async {
    await pumpDashboard(tester, 393);

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Pendapatan'), findsOneWidget);
    expect(find.text('Menunggu bayar'), findsOneWidget);
    expect(find.text('Refund ditinjau'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard tidak meluber di 320dp', (tester) async {
    await pumpDashboard(tester, 320);
    expect(tester.takeException(), isNull);
  });

  testWidgets('semua bagian dashboard ada saat layar tinggi', (tester) async {
    await pumpDashboard(tester, 393, tinggi: 1800);

    expect(find.text('PENJUALAN 7 HARI TERAKHIR'), findsOneWidget);
    expect(find.text('PERLU TINDAKAN'), findsOneWidget);
    expect(find.text('KONSER TERDEKAT'), findsOneWidget);
    expect(find.text('JALAN PINTAS'), findsOneWidget);
    expect(find.text('Scan Gate'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bagian "Perlu tindakan" menampilkan refund & stok kritis',
      (tester) async {
    await pumpDashboard(tester, 393, tinggi: 1800);

    expect(find.textContaining('refund menunggu keputusan'), findsOneWidget);
    expect(find.textContaining('pesanan hampir kedaluwarsa'), findsOneWidget);
    expect(find.textContaining('kategori tiket stok kritis'), findsOneWidget);
  });

  testWidgets('kartu tindakan meneruskan label menu yang benar',
      (tester) async {
    tester.view.physicalSize = const Size(393, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final diklik = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventsProvider.overrideWith(
            (ref) => Stream<List<KonserModel>>.value([konserUji('k1')]),
          ),
          allTicketsProvider.overrideWith(
            (ref) => Stream<List<TiketKonserModel>>.value([
              tiketUji('t1', 'VVIP', stok: 2, terjual: 48),
            ]),
          ),
          allOrdersProvider.overrideWith(
            (ref) => Stream<List<PesananTiketModel>>.value([
              pesananUji(
                'o1',
                status: AppConstants.orderStatusRefundRequested,
                refundStatus: AppConstants.orderStatusRefundRequested,
              ),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: DashboardAdminScreen(
            user: adminUji(),
            onBukaSidebar: () {},
            onBukaMenu: diklik.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('refund menunggu keputusan'));
    await tester.pumpAndSettle();
    expect(diklik, contains('Kelola Refund'));

    await tester.tap(find.text('Scan Gate'));
    await tester.pumpAndSettle();
    expect(diklik, contains('Validasi Gate (Scan)'));
  });
}
