// Widget test: NotifikasiBell dan NotifikasiSheet
// Notifikasi ditulis backend, bukan app.
// Test ini mengunci perilaku UI-nya:
//   · badge lonceng menampilkan JUMLAH yang belum dibaca
//   · badge hilang bila semua sudah dibaca
//   · user belum login (userId null) tidak error
//   · sheet menampilkan isi notifikasi apa adanya dari data
//   · sheet kosong menampilkan pesan "Belum ada notifikasi"

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soundwave/models/notifikasi_model.dart';
import 'package:soundwave/providers/app_providers.dart';
import 'package:soundwave/widgets/notifikasi_bell.dart';

const String _uid = 'user-uji';

/// `flutter test` tidak memuat font Google (allowRuntimeFetching=false).
/// Buang KHUSUS exception itu; exception lain tetap menggagalkan test.
void _ignoreGoogleFontsNoise() {
  final void Function(FlutterErrorDetails)? original = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final String text = '${details.exception}';
    if (text.contains('allowRuntimeFetching') ||
        text.contains('unable to load font')) {
      return;
    }
    original?.call(details);
  };
}

NotifikasiModel _notif({
  required String id,
  required String title,
  required String message,
  String type = 'info',
  bool read = false,
  Duration umur = const Duration(minutes: 5),
}) {
  return NotifikasiModel(
    id: id,
    userId: _uid,
    title: title,
    message: message,
    type: type,
    refId: 'SW-1234',
    read: read,
    createdAt: DateTime.now().subtract(umur),
  );
}

Widget _bungkus(Widget child, List<NotifikasiModel> daftar, {String? uid = _uid}) {
  return ProviderScope(
    overrides: <Override>[
      if (uid != null)
        notifikasiProvider(uid)
            .overrideWith((ref) => Stream<List<NotifikasiModel>>.value(daftar)),
    ],
    child: MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('badge lonceng menampilkan jumlah yang BELUM dibaca',
      (WidgetTester tester) async {
    _ignoreGoogleFontsNoise();
    final daftar = <NotifikasiModel>[
      _notif(id: 'a', title: 'Pembayaran Berhasil', message: 'E-tiket siap.'),
      _notif(id: 'b', title: 'Refund Disetujui', message: 'Rp 155.000.'),
      _notif(id: 'c', title: 'Refund Ditolak', message: 'Alasan: salah beli.'),
      _notif(
        id: 'd',
        title: 'Pengajuan Refund Diterima',
        message: 'Sedang ditinjau.',
        read: true, // sudah dibaca → tidak dihitung
      ),
    ];

    await tester.pumpWidget(
        _bungkus(const NotifikasiBell(userId: _uid), daftar));
    await tester.pump(); // tunggu stream mengalir

    expect(find.text('3'), findsOneWidget,
        reason: 'badge harus menunjukkan 3 notifikasi belum dibaca (dari 4)');
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
  });

  testWidgets('badge hilang bila semua notifikasi sudah dibaca',
      (WidgetTester tester) async {
    _ignoreGoogleFontsNoise();
    final daftar = <NotifikasiModel>[
      _notif(id: 'a', title: 'Pembayaran Berhasil', message: 'x', read: true),
      _notif(id: 'b', title: 'Refund Disetujui', message: 'y', read: true),
    ];

    await tester.pumpWidget(
        _bungkus(const NotifikasiBell(userId: _uid), daftar));
    await tester.pump();

    expect(find.text('2'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
  });

  testWidgets('user belum login (userId null) tetap tampil tanpa error',
      (WidgetTester tester) async {
    _ignoreGoogleFontsNoise();
    await tester.pumpWidget(
        _bungkus(const NotifikasiBell(userId: null), <NotifikasiModel>[]));
    await tester.pump();

    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sheet menampilkan isi notifikasi dari data',
      (WidgetTester tester) async {
    _ignoreGoogleFontsNoise();
    final daftar = <NotifikasiModel>[
      _notif(
        id: 'a',
        title: 'Pembayaran Berhasil',
        message: 'E-tiket Konser Uji (1 tiket) sudah aktif.',
        type: 'payment_success',
      ),
      _notif(
        id: 'b',
        title: 'Refund Disetujui',
        message: 'Rp 155.000 untuk SW-1234 disetujui.',
        type: 'refund_approved',
      ),
    ];

    await tester.pumpWidget(
        _bungkus(const NotifikasiSheet(userId: _uid), daftar));
    await tester.pump();

    expect(find.text('NOTIFIKASI'), findsOneWidget);
    expect(find.text('2 baru'), findsOneWidget);
    expect(find.text('Tandai semua'), findsOneWidget);
    expect(find.text('Pembayaran Berhasil'), findsOneWidget);
    expect(find.text('Refund Disetujui'), findsOneWidget);
    expect(find.text('E-tiket Konser Uji (1 tiket) sudah aktif.'), findsOneWidget);
    expect(find.text('Rp 155.000 untuk SW-1234 disetujui.'), findsOneWidget);
    expect(find.text('PEMBAYARAN'), findsOneWidget);
    expect(find.text('REFUND'), findsOneWidget);
    expect(find.text('Baru'), findsNWidgets(2));
  });

  testWidgets('sheet kosong menampilkan pesan "Belum ada notifikasi"',
      (WidgetTester tester) async {
    _ignoreGoogleFontsNoise();
    await tester
        .pumpWidget(_bungkus(const NotifikasiSheet(userId: _uid), <NotifikasiModel>[]));
    await tester.pump();

    expect(find.text('Belum ada notifikasi'), findsOneWidget);
    expect(find.text('Tandai semua'), findsNothing);
    expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
  });

  testWidgets('tap kartu TIDAK pindah halaman — panel tetap terbuka',
      (WidgetTester tester) async {
    _ignoreGoogleFontsNoise();
    // Kartu yang SUDAH dibaca: tap-nya tidak menyentuh Firestore sama sekali,
    // jadi test ini murni menguji navigasi (bukan koneksi database).
    final daftar = <NotifikasiModel>[
      _notif(
        id: 'a',
        title: 'Refund Disetujui',
        message: 'Rp 155.000 untuk SW-1234 disetujui.',
        type: 'refund_approved',
        read: true,
      ),
    ];

    await tester.pumpWidget(
        _bungkus(const NotifikasiSheet(userId: _uid), daftar));
    await tester.pump();

    expect(find.text('NOTIFIKASI'), findsOneWidget);

    await tester.tap(find.text('Refund Disetujui'));
    await tester.pumpAndSettle();

        // Panel harus tetap terbuka. Dulu tap menutup panel lalu error.
    // user ke halaman Tiket Saya.
    expect(find.text('NOTIFIKASI'), findsOneWidget,
        reason: 'tap kartu tidak boleh menutup panel / pindah halaman');
    expect(tester.takeException(), isNull);
  });

  test('kartu notifikasi tidak lagi memuat kode navigasi (baca sumber)', () {
    final String src =
        File('lib/widgets/notifikasi_bell.dart').readAsStringSync();

    expect(src.contains('UserTiketScreen'), isFalse,
        reason: 'tap kartu tidak boleh mengarahkan ke halaman Tiket Saya');
    expect(src.contains('MaterialPageRoute'), isFalse,
        reason: 'tidak ada push halaman dari kartu notifikasi');
    expect(src.contains('_tandaiDibaca(ref)'), isTrue,
        reason: 'tap kartu hanya menandai sudah dibaca');
  });
}
