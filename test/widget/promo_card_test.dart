import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/models/promo_model.dart';
import 'package:soundwave/widgets/promo/promo_card.dart';

/// ============================================================================
/// PENJAGA KARTU PROMO
/// ============================================================================
///
/// Permintaan pemilik produk: kartu promo **tidak boleh** punya tombol klaim.
/// Klaim hanya boleh terjadi dari lembaran ketentuan yang terbuka saat kartu
/// diketuk. Tes ini menjaga tiga hal yang mudah rusak tanpa disadari:
///
/// 1. Tidak ada teks "Klaim" di dalam kartu.
/// 2. Mengetuk kartu memanggil callback (bukan diam saja).
/// 3. Tema bergilir sesuai indeks bila promo tidak menentukan tema sendiri.
void main() {
  PromoCodeModel buatPromo({
    String kode = 'EARLYBIRD50',
    String tipe = 'percentage',
    double nilai = 50,
    String? tema,
  }) {
    final now = DateTime.now();
    return PromoCodeModel(
      id: 'p1',
      kode: kode,
      tipe: tipe,
      nilai: nilai,
      minPembelian: 0,
      maxPakai: 100,
      berlakuMulai: now.subtract(const Duration(days: 1)),
      berlakuAkhir: now.add(const Duration(days: 30)),
      tema: tema,
    );
  }

  Widget bungkus(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  group('kartu promo tanpa tombol klaim', () {
    testWidgets('tidak menampilkan teks "Klaim" di dalam kartu',
        (tester) async {
      await tester.pumpWidget(bungkus(PromoCard(
        promo: buatPromo(),
        tema: TemaPromo.gold,
        onKetuk: () {},
      )));

      // Tombol klaim hanya boleh ada di lembaran ketentuan.
      expect(find.textContaining('Klaim'), findsNothing);
      expect(find.textContaining('KLAIM'), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('mengetuk kartu memanggil callback', (tester) async {
      var diketuk = 0;
      await tester.pumpWidget(bungkus(PromoCard(
        promo: buatPromo(),
        tema: TemaPromo.gold,
        onKetuk: () => diketuk++,
      )));

      await tester.tap(find.byType(PromoCard));
      await tester.pumpAndSettle();
      expect(diketuk, 1);
    });

    testWidgets('menampilkan kode voucher', (tester) async {
      await tester.pumpWidget(bungkus(PromoCard(
        promo: buatPromo(kode: 'HEMAT25'),
        tema: TemaPromo.emerald,
        onKetuk: () {},
      )));

      expect(find.text('HEMAT25'), findsOneWidget);
    });

    testWidgets('persentase tampil sebagai persen, nominal sebagai rupiah',
        (tester) async {
      await tester.pumpWidget(bungkus(PromoCard(
        promo: buatPromo(tipe: 'percentage', nilai: 50),
        tema: TemaPromo.gold,
        onKetuk: () {},
      )));
      expect(find.text('50%'), findsOneWidget);

      await tester.pumpWidget(bungkus(PromoCard(
        promo: buatPromo(tipe: 'fixed', nilai: 50000),
        tema: TemaPromo.gold,
        onKetuk: () {},
      )));
      expect(find.text('Rp 50.000'), findsOneWidget);
    });

    testWidgets('tanda centang muncul bila sudah diklaim', (tester) async {
      await tester.pumpWidget(bungkus(PromoCard(
        promo: buatPromo(),
        tema: TemaPromo.gold,
        onKetuk: () {},
        sudahDiklaim: true,
      )));

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });
  });

  group('pemilihan tema', () {
    test('tema dari dokumen promo dipakai bila ada', () {
      expect(TemaPromo.untuk(buatPromo(tema: 'gold'), 2), TemaPromo.gold);
      expect(TemaPromo.untuk(buatPromo(tema: 'amethyst'), 0), TemaPromo.amethyst);
      expect(TemaPromo.untuk(buatPromo(tema: 'EMERALD'), 1), TemaPromo.emerald);
    });

    test('tanpa tema, warna bergilir menurut indeks', () {
      expect(TemaPromo.untuk(buatPromo(), 0), TemaPromo.gold);
      expect(TemaPromo.untuk(buatPromo(), 1), TemaPromo.emerald);
      expect(TemaPromo.untuk(buatPromo(), 2), TemaPromo.amethyst);
      expect(TemaPromo.untuk(buatPromo(), 3), TemaPromo.silver);
      expect(TemaPromo.untuk(buatPromo(), 4), TemaPromo.red);
      // Berputar kembali ke awal.
      expect(TemaPromo.untuk(buatPromo(), 5), TemaPromo.gold);
    });

    test('lima tema, semuanya punya label', () {
      expect(TemaPromo.values.length, 5);
      for (final t in TemaPromo.values) {
        expect(t.label.trim(), isNotEmpty);
      }
      // Nama bermakna, bukan nama warna.
      expect(TemaPromo.gold.label, 'SIGNATURE');
      expect(TemaPromo.silver.label, 'PLATINUM');
      expect(TemaPromo.amethyst.label, 'NOCTURNE');
      expect(TemaPromo.emerald.label, 'RESERVE');
      expect(TemaPromo.red.label, 'BACKSTAGE');
    });

    test('label dari data promo menang atas label tema', () {
      // Warna dan makna dipisah: promo emas boleh berlabel "EARLY BIRD".
      final p = buatPromo(tema: 'gold');
      final denganLabel = PromoCodeModel(
        id: p.id, kode: p.kode, tipe: p.tipe, nilai: p.nilai,
        minPembelian: p.minPembelian, maxPakai: p.maxPakai,
        berlakuMulai: p.berlakuMulai, berlakuAkhir: p.berlakuAkhir,
        tema: 'gold', label: 'EARLY BIRD',
      );
      expect(denganLabel.label, 'EARLY BIRD');
      expect(TemaPromo.untuk(denganLabel, 0).label, 'SIGNATURE');
    });

    test('silver dan red bisa dipilih lewat dokumen promo', () {
      expect(TemaPromo.untuk(buatPromo(tema: 'silver'), 0), TemaPromo.silver);
      expect(TemaPromo.untuk(buatPromo(tema: 'red'), 0), TemaPromo.red);
    });

    test('tema tak dikenal diabaikan, kembali bergilir', () {
      expect(TemaPromo.untuk(buatPromo(tema: 'ungu'), 1), TemaPromo.emerald);
    });

    test('setiap tema punya warna aksen berbeda', () {
      final warna = TemaPromo.values.map((t) => t.aksen).toSet();
      expect(warna.length, TemaPromo.values.length);
    });
  });
}
