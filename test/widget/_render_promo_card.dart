// Skrip render sementara — hanya untuk melihat hasil desain kartu promo
// tanpa membangun APK. Memakai font sistem (bukan GoogleFonts.*) karena
// `GoogleFonts.*` mencoba mengunduh font lewat jaringan dan menggantung di
// lingkungan `flutter test`.
//
// Jalankan: flutter test test/widget/_render_promo_card.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soundwave/models/promo_model.dart';
import 'package:soundwave/utils/app_theme.dart';
import 'package:soundwave/widgets/promo/promo_card.dart';

Future<void> _muatFont() async {
  // `google_fonts` mendaftarkan font dengan nama "<Family>_<weight><style>",
  // mis. "SpaceGrotesk_700normal". Kalau nama itu tidak ada, TextStyle
  // memakai font bawaan tes yang tidak punya glyph — teks tampil sebagai
  // balok. Jadi font sistem didaftarkan ulang dengan nama-nama tersebut.
  const berkas = <String>[
    r'C:\Windows\Fonts\segoeui.ttf',
    r'C:\Windows\Fontsrial.ttf',
    '/System/Library/Fonts/Supplemental/Arial.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
  ];

  File? sumber;
  for (final path in berkas) {
    final f = File(path);
    if (f.existsSync()) {
      sumber = f;
      break;
    }
  }
  if (sumber == null) return;

  final Uint8List bytes = await sumber.readAsBytes();
  final data =
      ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);

  // Nama persis yang dipakai `google_fonts`: "<Family>_regular" untuk
  // w400, "<Family>_<weight>" untuk bobot lain (mis. "_700").
  const keluarga = <String>[
    'SpaceGrotesk_regular',
    'SpaceGrotesk_500',
    'SpaceGrotesk_600',
    'SpaceGrotesk_700',
    'Rajdhani_regular',
    'Rajdhani_500',
    'Rajdhani_600',
    'Rajdhani_700',
    'Roboto',
  ];

  for (final nama in keluarga) {
    await (FontLoader(nama)..addFont(Future<ByteData>.value(data))).load();
  }
}

void main() {
  testWidgets('render kartu promo', (tester) async {
    // Tanpa ini, `GoogleFonts.*` mencoba mengunduh font lewat jaringan dan
    // tes menggantung sampai timeout.
    GoogleFonts.config.allowRuntimeFetching = false;
    // Pemuatan font membaca berkas dari disk, jadi harus di dalam runAsync —
    // kalau tidak, Future-nya tidak pernah selesai dan tes menggantung.
    await tester.runAsync(_muatFont);

    tester.view.physicalSize = const Size(3300, 1180);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final now = DateTime.now();

    PromoCard kartu({
      required String kode,
      required String tipe,
      required double nilai,
      required TemaPromo tema,
    }) =>
        PromoCard(
          promo: PromoCodeModel(
            id: kode,
            kode: kode,
            tipe: tipe,
            nilai: nilai,
            minPembelian: 200000,
            maxPakai: 100,
            berlakuMulai: now.subtract(const Duration(days: 2)),
            berlakuAkhir: now.add(const Duration(days: 20)),
          ),
          tema: tema,
          onKetuk: () {},
        );

    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: key,
          child: Container(
            color: const Color(0xFF08080C),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Voucher & promo',
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ketuk kartu untuk melihat ketentuan',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    kartu(
                        kode: 'EARLYBIRD50',
                        tipe: 'percentage',
                        nilai: 50,
                        tema: TemaPromo.gold),
                    const SizedBox(width: 12),
                    kartu(
                        kode: 'MEMBER20',
                        tipe: 'percentage',
                        nilai: 20,
                        tema: TemaPromo.emerald),
                    const SizedBox(width: 12),
                    kartu(
                        kode: 'AMETHYST100',
                        tipe: 'fixed',
                        nilai: 100000,
                        tema: TemaPromo.amethyst),
                    const SizedBox(width: 12),
                    kartu(
                        kode: 'PLATINUM25',
                        tipe: 'percentage',
                        nilai: 25,
                        tema: TemaPromo.silver),
                    const SizedBox(width: 12),
                    kartu(
                        kode: 'LIVEVIBES15',
                        tipe: 'percentage',
                        nilai: 15,
                        tema: TemaPromo.red),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    late ui.Image image;
    await tester.runAsync(() async {
      image = await boundary.toImage(pixelRatio: 2.0);
    });
    late ByteData? bytes;
    await tester.runAsync(() async {
      bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    });
    final file = File('docs/mockup/kartu-promo.png');
    await tester.runAsync(() async {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    });
    // ignore: avoid_print
    print('tersimpan: ${file.absolute.path}');
  });
}
