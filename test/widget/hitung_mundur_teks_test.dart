// Hitungan waktu yang berdetak, widget
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/widgets/hitung_mundur_teks.dart';

String teks(WidgetTester tester) =>
    tester.widget<Text>(find.byType(Text)).data ?? '';

void main() {
  testWidgets('menampilkan sisa waktu dan berdetak tiap detik',
      (tester) async {
    // Jam palsu: 10:00:00, batas bayar 10:02:00 → 02:00.
    var sekarang = DateTime(2026, 10, 17, 10, 0, 0);
    final batas = DateTime(2026, 10, 17, 10, 2, 0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HitungMundurTeks(
            sampai: batas,
            awalan: 'Sisa waktu ',
            jam: () => sekarang,
          ),
        ),
      ),
    );

    expect(teks(tester), 'Sisa waktu 02:00');

    // Satu detik kemudian: 01:59.
    sekarang = sekarang.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(teks(tester), 'Sisa waktu 01:59',
        reason: 'angka harus berkurang tiap detik');

    // Tiga menit kemudian: habis.
    sekarang = sekarang.add(const Duration(minutes: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(teks(tester), '00:00');

    // Lepas widget supaya Timer-nya benar-benar dibatalkan.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('waktu habis menampilkan 00:00', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HitungMundurTeks(
            sampai: DateTime.now().subtract(const Duration(minutes: 1)),
            awalan: 'Sisa waktu ',
          ),
        ),
      ),
    );

    expect(teks(tester), '00:00');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tanpa awalan hanya angka', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HitungMundurTeks(
            sampai: DateTime.now().add(const Duration(minutes: 3)),
          ),
        ),
      ),
    );

    expect(RegExp(r'^0[23]:\d{2}$').hasMatch(teks(tester)), isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
