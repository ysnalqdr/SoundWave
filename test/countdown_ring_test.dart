import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/widgets/animasi/countdown_ring.dart';

void main() {
  group('CountdownRing.formatRemaining', () {
    test('menampilkan MM:SS untuk durasi di bawah satu jam', () {
      expect(CountdownRing.formatRemaining(const Duration(seconds: 5)),
          '00:05');
      expect(CountdownRing.formatRemaining(const Duration(minutes: 5)),
          '05:00');
      expect(CountdownRing.formatRemaining(const Duration(minutes: 59, seconds: 59)),
          '59:59');
    });

    test('menampilkan HH:MM:SS untuk durasi satu jam ke atas', () {
      expect(CountdownRing.formatRemaining(const Duration(hours: 1)), '01:00:00');
      expect(
          CountdownRing.formatRemaining(const Duration(hours: 23, minutes: 59)),
          '23:59:00');
      expect(CountdownRing.formatRemaining(const Duration(hours: 24)), '24:00:00');
    });

    test('durasi nol menjadi 00:00', () {
      expect(CountdownRing.formatRemaining(Duration.zero), '00:00');
    });

    test('durasi negatif dijepit ke nol, tidak menampilkan tanda minus', () {
      expect(CountdownRing.formatRemaining(const Duration(seconds: -5)),
          '00:00');
      expect(CountdownRing.formatRemaining(const Duration(minutes: -3)),
          '00:00');
    });

    test('detik dipadding dua digit', () {
      expect(CountdownRing.formatRemaining(const Duration(seconds: 9)), '00:09');
    });
  });

  group('CountdownRing.progressOf', () {
    test('sisa penuh menghasilkan 1.0', () {
      expect(
        CountdownRing.progressOf(
            const Duration(minutes: 5), const Duration(minutes: 5)),
        1.0,
      );
    });

    test('sisa setengah menghasilkan 0.5', () {
      expect(
        CountdownRing.progressOf(
            const Duration(minutes: 5), const Duration(minutes: 10)),
        0.5,
      );
    });

    test('sisa nol menghasilkan 0.0', () {
      expect(
        CountdownRing.progressOf(Duration.zero, const Duration(minutes: 5)),
        0.0,
      );
    });

    test('sisa melebihi total dijepit ke 1.0', () {
      expect(
        CountdownRing.progressOf(
            const Duration(minutes: 20), const Duration(minutes: 5)),
        1.0,
      );
    });

    test('sisa negatif dijepit ke 0.0', () {
      expect(
        CountdownRing.progressOf(
            const Duration(seconds: -30), const Duration(minutes: 5)),
        0.0,
      );
    });

    test('total nol tidak menyebabkan pembagian dengan nol', () {
      expect(CountdownRing.progressOf(Duration.zero, Duration.zero), 0.0);
      expect(
        CountdownRing.progressOf(
            const Duration(seconds: 5), const Duration(seconds: -1)),
        0.0,
      );
    });
  });

  group('CountdownRing.colorFor', () {
    const normal = Color(0xFF00E676);
    const warning = Color(0xFFFF9800);
    const critical = Color(0xFFE53935);

    Color pick(double p) => CountdownRing.colorFor(
          p,
          normal: normal,
          warning: warning,
          critical: critical,
        );

    test('di atas 50 persen memakai warna normal', () {
      expect(pick(1.0), normal);
      expect(pick(0.51), normal);
    });

    test('antara 20 dan 50 persen memakai warna peringatan', () {
      expect(pick(0.5), warning);
      expect(pick(0.21), warning);
    });

    test('20 persen ke bawah memakai warna kritis', () {
      expect(pick(0.2), critical);
      expect(pick(0.0), critical);
    });
  });

  group('CountdownRing widget', () {
    testWidgets('menampilkan label sisa waktu', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CountdownRing(
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
            total: const Duration(minutes: 5),
          ),
        ),
      ));
      await tester.pump();

      // Toleransi: bisa 04:59 atau 05:00 tergantung milidetik berjalan.
      expect(
        find.byWidgetPredicate((w) =>
            w is Text && RegExp(r'^0[45]:\d{2}$').hasMatch(w.data ?? '')),
        findsOneWidget,
      );
    });

    testWidgets('memanggil onExpired ketika waktu habis', (tester) async {
      var expired = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CountdownRing(
            expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
            total: const Duration(minutes: 5),
            onExpired: () => expired++,
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(expired, 1, reason: 'callback harus terpanggil sekali');
    });

    testWidgets('onExpired tidak terpanggil dua kali', (tester) async {
      var expired = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CountdownRing(
            expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
            total: const Duration(minutes: 5),
            onExpired: () => expired++,
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(expired, 1, reason: 'harus idempoten');
    });

    testWidgets('showLabel false menyembunyikan teks', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CountdownRing(
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
            total: const Duration(minutes: 5),
            showLabel: false,
          ),
        ),
      ));
      await tester.pump();

      expect(find.byType(Text), findsNothing);
    });

    testWidgets('mengganti expiresAt me-reset penghitung', (tester) async {
      var expired = 0;
      Widget build(DateTime at) => MaterialApp(
            home: Scaffold(
              body: CountdownRing(
                expiresAt: at,
                total: const Duration(minutes: 5),
                onExpired: () => expired++,
              ),
            ),
          );

      await tester.pumpWidget(build(DateTime.now().add(const Duration(minutes: 5))));
      await tester.pump();
      expect(expired, 0);

      await tester.pumpWidget(build(DateTime.now().subtract(const Duration(seconds: 1))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(expired, 1);
    });
  });
}
