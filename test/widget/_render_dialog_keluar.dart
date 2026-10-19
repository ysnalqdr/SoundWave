// Skrip render sementara, hanya untuk melihat hasil tata letak dialog.
// Memakai TextStyle(fontFamily:) langsung (bukan GoogleFonts.*) supaya font
// sistem yang didaftarkan benar-benar dipakai saat render di `flutter test`.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/utils/app_theme.dart';
import 'package:soundwave/widgets/tombol_dialog_sejajar.dart';

const List<String> _fontCandidates = <String>[
  r'C:\Windows\Fonts\arial.ttf',
  '/System/Library/Fonts/Supplemental/Arial.ttf',
  '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
];

Future<void> _loadRealFont() async {
  for (final String path in _fontCandidates) {
    final File file = File(path);
    if (!file.existsSync()) continue;
    final Uint8List bytes = await file.readAsBytes();
    final ByteData data =
        ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);
    for (final String family in <String>[
      'SpaceGrotesk',
      'Rajdhani',
      'Roboto',
    ]) {
      await (FontLoader(family)..addFont(Future<ByteData>.value(data))).load();
    }
    return;
  }
}

TextStyle _sg({Color? color, double size = 14, FontWeight w = FontWeight.w400}) =>
    TextStyle(fontFamily: 'SpaceGrotesk', color: color, fontSize: size, fontWeight: w);

TextStyle _rj({Color? color, double size = 22, FontWeight w = FontWeight.w700}) =>
    TextStyle(fontFamily: 'Rajdhani', color: color, fontSize: size, fontWeight: w);

/// Replika PERSIS dialog `_logout()` di admin_dashboard.dart setelah perbaikan.
Widget _dialogKeluar() => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Keluar Akun?', style: _rj(color: AppColors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Yakin ingin keluar dari dashboard SoundWave?',
              style: _sg(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          TombolDialogSejajar(onBatal: () {}, onKonfirmasi: () {}),
        ],
      ),
    );

Future<void> _render(WidgetTester tester, double lebar, String nama) async {
  tester.view.physicalSize = Size(lebar * 3, 640 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final GlobalKey rootKey = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        key: rootKey,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.background),
            Container(color: Colors.black54),
            Center(child: _dialogKeluar()),
          ],
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));

  final Rect rBatal = tester.getRect(find.widgetWithText(OutlinedButton, 'Batal'));
  final Rect rKeluar = tester.getRect(find.widgetWithText(ElevatedButton, 'Keluar'));
  // ignore: avoid_print
  print('LEBAR=$lebar  '
      'Batal=${rBatal.left.toStringAsFixed(1)},${rBatal.top.toStringAsFixed(1)} '
      '${rBatal.width.toStringAsFixed(1)}x${rBatal.height.toStringAsFixed(1)}  |  '
      'Keluar=${rKeluar.left.toStringAsFixed(1)},${rKeluar.top.toStringAsFixed(1)} '
      '${rKeluar.width.toStringAsFixed(1)}x${rKeluar.height.toStringAsFixed(1)}  |  '
      'selisih_y=${(rBatal.top - rKeluar.top).abs().toStringAsFixed(2)}  '
      'sejajar=${(rBatal.top - rKeluar.top).abs() < 1 ? "YA" : "TIDAK"}');

  final RenderRepaintBoundary boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(rootKey));
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
    File(nama).writeAsBytesSync(data!.buffer.asUint8List());
    // ignore: avoid_print
    print('PNG -> $nama  (${File(nama).lengthSync()} byte)');
  });
}

void main() {
  setUpAll(_loadRealFont);

  testWidgets('render dialog keluar — normal 390px', (tester) async {
    await _render(tester, 390, r'_render_dialog_normal.png');
  });

  testWidgets('render dialog keluar — sempit 300px', (tester) async {
    await _render(tester, 300, r'_render_dialog_sempit.png');
  });
}
