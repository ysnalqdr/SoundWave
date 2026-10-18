import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/widgets/tombol_dialog_sejajar.dart';

/// Membungkus widget dalam lebar tertentu supaya bisa diuji di "layar sempit".
Future<void> _tampilkan(
  WidgetTester tester, {
  required double lebar,
  VoidCallback? onBatal,
  VoidCallback? onKonfirmasi,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: lebar,
            child: TombolDialogSejajar(
              onBatal: onBatal ?? () {},
              onKonfirmasi: onKonfirmasi ?? () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Batal & Keluar SEJAJAR kiri-kanan (bukan atas-bawah)',
      (tester) async {
    await _tampilkan(tester, lebar: 300);

    final batal =
        tester.getCenter(find.widgetWithText(OutlinedButton, 'Batal'));
    final keluar =
        tester.getCenter(find.widgetWithText(ElevatedButton, 'Keluar'));

    expect((batal.dy - keluar.dy).abs(), lessThan(1.0),
        reason: 'kedua tombol harus satu baris (dy sama) — bukan bertumpuk');
    expect(batal.dx, lessThan(keluar.dx),
        reason: 'Batal harus di KIRI, Keluar di KANAN');
  });

  testWidgets('tetap sejajar di layar sempit 240px (anti-regresi)',
      (tester) async {
    await _tampilkan(tester, lebar: 240);

    final batal =
        tester.getCenter(find.widgetWithText(OutlinedButton, 'Batal'));
    final keluar =
        tester.getCenter(find.widgetWithText(ElevatedButton, 'Keluar'));

    expect((batal.dy - keluar.dy).abs(), lessThan(1.0),
        reason: 'regresi: actions/OverflowBar AlertDialog menumpuk tombol '
            'ke atas-bawah saat layar sempit');
    expect(batal.dx, lessThan(keluar.dx));
  });

  testWidgets('lebar kedua tombol sama besar', (tester) async {
    await _tampilkan(tester, lebar: 320);

    final batal = tester.getSize(find.widgetWithText(OutlinedButton, 'Batal'));
    final keluar =
        tester.getSize(find.widgetWithText(ElevatedButton, 'Keluar'));

    expect((batal.width - keluar.width).abs(), lessThan(0.5));
  });

  testWidgets('tap memanggil callback yang tepat', (tester) async {
    var batalDipanggil = false;
    var keluarDipanggil = false;

    await _tampilkan(
      tester,
      lebar: 320,
      onBatal: () => batalDipanggil = true,
      onKonfirmasi: () => keluarDipanggil = true,
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Batal'));
    await tester.pumpAndSettle();
    expect(batalDipanggil, isTrue);
    expect(keluarDipanggil, isFalse);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Keluar'));
    await tester.pumpAndSettle();
    expect(keluarDipanggil, isTrue);
  });

  group('penjaga kabel — 3 dialog keluar memakai tombol sejajar', () {
    const berkas = [
      'lib/screens/admin/admin_dashboard.dart',
      'lib/screens/admin/profil_screen.dart',
      'lib/screens/user/user_main_screen.dart',
    ];

    for (final f in berkas) {
      test(f, () {
        final src = File(f).readAsStringSync();

        final awal = src.contains('void _logout()')
            ? src.indexOf('void _logout()')
            : src.indexOf('Future<void> _confirmLogout()');
        expect(awal, greaterThanOrEqualTo(0), reason: 'method dialog tak ketemu');

        final tombol = src.indexOf('TombolDialogSejajar(', awal);
        expect(tombol, greaterThan(awal),
            reason: '$f harus memakai TombolDialogSejajar');

        // Di antara awal method dan tombol baru: TIDAK boleh ada `actions: [`.
        final sebelum = src.substring(awal, tombol);
        expect(sebelum.contains('actions: ['), isFalse,
            reason: 'jangan pakai actions: AlertDialog (OverflowBar menumpuk '
                'tombol ke atas-bawah)');
      });
    }
  });
}
