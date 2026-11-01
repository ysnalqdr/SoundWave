// Skrip render sementara — lembaran ketentuan voucher.
// Jalankan: flutter test test/widget/_render_promo_lembar.dart
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
import 'package:soundwave/widgets/promo/promo_lembar.dart';

const List<String> _berkas = <String>[
  r'C:\Windows\Fonts\segoeui.ttf',
  r'C:\Windows\Fonts\arial.ttf',
  '/System/Library/Fonts/Supplemental/Arial.ttf',
  '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
];

Future<void> _muatFont() async {
  File? sumber;
  for (final path in _berkas) {
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
  const keluarga = <String>[
    'SpaceGrotesk_regular',
    'SpaceGrotesk_500',
    'SpaceGrotesk_600',
    'SpaceGrotesk_700',
    'Rajdhani_regular',
    'Rajdhani_700',
    'Roboto',
  ];
  for (final nama in keluarga) {
    await (FontLoader(nama)..addFont(Future<ByteData>.value(data))).load();
  }
}

void main() {
  testWidgets('render lembaran ketentuan', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.runAsync(_muatFont);

    tester.view.physicalSize = const Size(900, 1900);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    final promo = PromoCodeModel(
      id: 'EARLYBIRD50',
      kode: 'EARLYBIRD50',
      tipe: 'percentage',
      nilai: 50,
      minPembelian: 200000,
      maxPakai: 100,
      berlakuMulai: now.subtract(const Duration(days: 2)),
      berlakuAkhir: now.add(const Duration(days: 20)),
    );

    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: key,
          child: Container(
            color: const Color(0xFF08080C),
            alignment: Alignment.bottomCenter,
            child: PromoLembar(
              promo: promo,
              tema: TemaPromo.gold,
              sudahDiklaim: false,
              onKlaim: () async => null,
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
    final file = File('docs/mockup/kartu-promo-ketentuan.png');
    await tester.runAsync(() async {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    });
    // ignore: avoid_print
    print('tersimpan: ${file.absolute.path}');
  });
}
