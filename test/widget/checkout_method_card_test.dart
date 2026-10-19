// Widget test: kartu "Pilih Metode Pembayaran" di CheckoutScreen
//
// Latar belakang
// User melaporkan "warna teks nama metode tidak terbaca" + screenshot
// (image_709131.png) yang menunjukkan 4 kartu KOSONG. Analisis piksel +
// timestamp membuktikan screenshot itu berasal dari APK usang
// (APK dibuild 16 Okt 15:55, checkout_screen.dart diubah 18:43).
//
// Test ini mengunci perilaku kode SAAT INI supaya bug "kartu kosong"
// tidak bisa lolos lagi tanpa ketahuan:
//   1. keempat nama metode benar-benar ter-render di widget tree
//   2. warnanya putih #FFFFFF di atas kartu #1C1C26 (kontras AA >= 4.5:1)
//   3. BUKTI PIKSEL: di dalam area nama metode benar-benar ada glif putih
//      di atas latar gelap — persis kebalikan dari screenshot bug.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soundwave/models/konser_model.dart';
import 'package:soundwave/models/tiket_konser_model.dart';
import 'package:soundwave/providers/app_providers.dart';
import 'package:soundwave/screens/user/checkout_screen.dart';

const Color _inkWhite = Color(0xFFFFFFFF); // teks nama metode
const Color _cardSurface = Color(0xFF1C1C26); // latar kartu

const double _dpr = 3.0;

const Map<String, String> _methods = <String, String>{
  'Transfer Bank': 'BCA, BNI, Mandiri',
  'Kartu Kredit/Debit': 'Visa, Mastercard',
  'GoPay': 'Bayar dengan GoPay',
  'QRIS': 'Scan untuk bayar',
};

const List<IconData> _methodIcons = <IconData>[
  Icons.account_balance,
  Icons.credit_card,
  Icons.wallet,
  Icons.qr_code,
];

// util warna — kontras WCAG 2.1
double _luminance(Color c) {
  final int v = c.toARGB32();
  double chan(int x) {
    final double s = x / 255.0;
    return s <= 0.03928
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * chan((v >> 16) & 0xFF) +
      0.7152 * chan((v >> 8) & 0xFF) +
      0.0722 * chan(v & 0xFF);
}

double _contrastRatio(Color a, Color b) {
  final double la = _luminance(a);
  final double lb = _luminance(b);
  final double hi = math.max(la, lb);
  final double lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

// data uji
KonserModel _konser() => KonserModel(
      id: 'konser-test',
      judul: 'Jakarta Fest',
      lokasi: 'Jakarta',
      tanggal: DateTime(2026, 11, 1),
      harga: 150000,
      genre: const <String>['Pop'],
      gambarUrl: '', // kosong → placeholder, tidak menyentuh jaringan
    );

TiketKonserModel _tiket() => TiketKonserModel(
      id: 'tiket-test',
      idKonser: 'konser-test',
      judulKonser: 'Jakarta Fest',
      gambarKonser: '',
      kategori: 'VIP',
      harga: 150000,
      stok: 10,
    );

/// Bungkus layar tanpa menyentuh Firebase: `build()` hanya membaca dua
/// provider ini, dan `_bindClaimedPromos` langsung keluar saat uid null
/// (jadi `databaseServiceProvider` tidak pernah dikonstruksi).
Widget _checkoutApp() => ProviderScope(
      overrides: <Override>[
        authStateProvider.overrideWith((ref) => Stream.value(null)),
        currentUserStreamProvider.overrideWith((ref) => Stream.value(null)),
      ],
      child: MaterialApp(
        home: CheckoutScreen(konser: _konser(), tiketDipilih: _tiket()),
      ),
    );

Future<void> _pumpCheckout(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = _dpr;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_checkoutApp());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

// Font — `flutter test` tidak memuat font asli: glif digambar KOSONG dan
// font fallback-nya berlebar 1em/karakter, sehingga layout palsu jadi
// overflow 79px. Kita daftarkan font sistem sebagai 'SpaceGrotesk' &
// 'Rajdhani' agar glif benar-benar ter-render dan metrik lebar wajar.
const List<String> _fontCandidates = <String>[
  r'C:\Windows\Fonts\arial.ttf',
  '/System/Library/Fonts/Supplemental/Arial.ttf',
  '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
  '/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf',
];

bool _realFontLoaded = false;

Future<void> _loadRealFont() async {
  for (final String path in _fontCandidates) {
    final File file = File(path);
    if (!file.existsSync()) continue;
    final Uint8List bytes = await file.readAsBytes();
    final ByteData data =
        ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);
    // google_fonts menamai family dengan bobot di belakang, mis. 'SpaceGrotesk_600'
    // → daftarkan semua varian bobot supaya tidak jatuh ke font test (Ahem).
    final List<String> families = <String>[
      'SpaceGrotesk',
      'Rajdhani',
      'Roboto',
      for (final int w in <int>[100, 200, 300, 400, 500, 600, 700, 800, 900])
        ...<String>['SpaceGrotesk_$w', 'Rajdhani_$w', 'Roboto_$w'],
    ];
    for (final String family in families) {
      await (FontLoader(family)..addFont(Future<ByteData>.value(data))).load();
    }
    _realFontLoaded = true;
    return;
  }
}

/// google_fonts melempar exception di lingkungan `flutter test` karena font
/// tidak di-bundle sebagai asset (allowRuntimeFetching=false). Kita buang
/// KHUSUS exception itu; exception LAIN — mis. assert paint bug kartu —
/// tetap menggagalkan test.
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

void main() {
  setUpAll(() async {
    // Jangan tembak jaringan saat test.
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadRealFont();
    // ignore: avoid_print
    print(_realFontLoaded
        ? 'INFO  font sistem dimuat sebagai SpaceGrotesk/Rajdhani → glif ter-render'
        : 'WARN  font sistem tidak ditemukan → bukti piksel akan dilewati');
  });

  testWidgets('4 kartu metode ter-render lengkap — bukan kartu kosong',
      (WidgetTester tester) async {
    _ignoreGoogleFontsNoise();
    await _pumpCheckout(tester);

    expect(find.text('Pilih Metode Pembayaran'), findsOneWidget);

    for (final String title in _methods.keys) {
      expect(find.text(title), findsWidgets,
          reason: 'nama metode "$title" harus ada di widget tree');
    }
    for (final String sub in _methods.values) {
      expect(find.text(sub), findsWidgets,
          reason: 'subtitle "$sub" harus ada di widget tree');
    }
    // kotak ikon 42dp — elemen yang HILANG di screenshot bug
    for (final IconData icon in _methodIcons) {
      expect(find.byIcon(icon), findsOneWidget,
          reason: 'kotak ikon metode harus ter-render');
    }

    // ignore: avoid_print
    print('OK  struktur: 4 nama metode + 4 subtitle + 4 ikon ter-render');
  });

  testWidgets('nama metode putih #FFFFFF di atas kartu #1C1C26 (kontras AA)',
      (WidgetTester tester) async {
    _ignoreGoogleFontsNoise();
    await _pumpCheckout(tester);

    for (final String title in _methods.keys) {
      final Finder label = find.text(title).first;
      final Text text = tester.widget<Text>(label);

      expect(text.style?.color, _inkWhite,
          reason: 'nama metode "$title" harus putih #FFFFFF');

      // kartu pembungkusnya harus berlatar _SwWhite.surface
      final Finder card = find.ancestor(
        of: label,
        matching: find.byWidgetPredicate((Widget w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).color == _cardSurface),
      );
      expect(card, findsOneWidget,
          reason: 'kartu "$title" harus berlatar #1C1C26');

      final double ratio = _contrastRatio(_inkWhite, _cardSurface);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'kontras "$title" harus >= 4.5:1 (WCAG AA)');

      // ignore: avoid_print
      print('OK  "$title"  teks=#FFFFFF  kartu=#1C1C26  '
          'kontras=${ratio.toStringAsFixed(2)}:1');
    }
  });

  testWidgets('BUKTI PIKSEL — glif nama metode benar-benar terlihat di layar',
      (WidgetTester tester) async {
    _ignoreGoogleFontsNoise();
    if (!_realFontLoaded) {
      // ignore: avoid_print
      print('SKIP  bukti piksel: font asli tidak tersedia di mesin ini');
      return;
    }

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = _dpr;
    addTearDown(tester.view.reset);

    final GlobalKey rootKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: rootKey, child: _checkoutApp()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final Rect labelRect = tester.getRect(find.text('Transfer Bank').first);
    expect(labelRect.width, greaterThan(0),
        reason: 'area nama metode harus punya ukuran');
    expect(labelRect.height, greaterThan(0));

    final RenderRepaintBoundary boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(rootKey));

    ui.Image? image;
    ByteData? raw;
    await tester.runAsync(() async {
      image = await boundary.toImage(pixelRatio: _dpr);
      raw = await image!.toByteData(format: ui.ImageByteFormat.rawRgba);
    });

    final ui.Image img = image!;
    final Uint8List px = raw!.buffer.asUint8List();
    final int iw = img.width;
    final int ih = img.height;

    // simpan PNG agar bisa diperiksa (I/O wajib di dalam runAsync)
    final File outFile = File('${Directory.current.path}/_render_checkout.png');
    await tester.runAsync(() async {
      final ByteData? png =
          await img.toByteData(format: ui.ImageByteFormat.png);
      await outFile.writeAsBytes(png!.buffer.asUint8List());
    });
    // ignore: avoid_print
    print('DEBUG PNG tersimpan: ${outFile.path}');

    int paintedIn(Rect r, int minChannel) {
      final int ax = (r.left * _dpr).floor().clamp(0, iw - 1);
      final int bx = (r.right * _dpr).ceil().clamp(0, iw);
      final int ay = (r.top * _dpr).floor().clamp(0, ih - 1);
      final int by = (r.bottom * _dpr).ceil().clamp(0, ih);
      int c = 0;
      for (int y = ay; y < by; y++) {
        for (int x = ax; x < bx; x++) {
          final int i = (y * iw + x) * 4;
          if (px[i] > minChannel &&
              px[i + 1] > minChannel &&
              px[i + 2] > minChannel) {
            c++;
          }
        }
      }
      return c;
    }

    // ignore: avoid_print
    print('DEBUG boundary=${tester.getRect(find.byKey(rootKey))} '
        'gambar=${iw}x$ih dpr=$_dpr');
    final List<(String, Finder)> probes = <(String, Finder)>[
      ('judul halaman', find.text('Pilih Metode Pembayaran')),
      ('nama metode', find.text('Transfer Bank')),
      ('tombol lanjut', find.text('Lanjut')),
      ('ikon metode', find.byIcon(Icons.account_balance)),
    ];
    for (final (String label, Finder f) in probes) {
      final int n = f.evaluate().length;
      if (n == 0) {
        // ignore: avoid_print
        print('DEBUG $label: TIDAK ADA');
        continue;
      }
      for (int k = 0; k < n; k++) {
        final Rect r = tester.getRect(f.at(k));
        // ignore: avoid_print
        print('DEBUG $label [$k/$n] rect=$r putih=${paintedIn(r, 200)}');
      }
    }

    // area nama metode di koordinat gambar
    final int x0 = (labelRect.left * _dpr).floor().clamp(0, iw - 1);
    final int x1 = (labelRect.right * _dpr).ceil().clamp(0, iw);
    final int y0 = (labelRect.top * _dpr).floor().clamp(0, ih - 1);
    final int y1 = (labelRect.bottom * _dpr).ceil().clamp(0, ih);

    int total = 0;
    int terang = 0; // piksel mendekati putih  = glif nama metode
    int gelap = 0; // piksel gelap             = latar kartu #1C1C26
    for (int y = y0; y < y1; y++) {
      for (int x = x0; x < x1; x++) {
        final int i = (y * iw + x) * 4;
        final int r = px[i];
        final int g = px[i + 1];
        final int b = px[i + 2];
        total++;
        if (r > 200 && g > 200 && b > 200) terang++;
        if (r < 70 && g < 70 && b < 70) gelap++;
      }
    }

    // ignore: avoid_print
    print('OK  piksel area "Transfer Bank": total=$total  '
        'putih=$terang  gelap=$gelap  '
        '(${(gelap / total * 100).toStringAsFixed(1)}% latar gelap)');

    expect(total, greaterThan(1000),
        reason: 'area nama metode harus cukup besar untuk diukur');
    expect(terang, greaterThan(50),
        reason: 'harus ADA piksel putih (glif nama metode) — inilah yang '
            'hilang pada APK lama sehingga kartu tampak kosong');
    expect(gelap / total, greaterThan(0.3),
        reason: 'latar di dalam area nama metode harus gelap (kartu #1C1C26), '
            'membuktikan teks putih menempel pada kartu gelap — bukan '
            'putih-di-atas-putih');

    // Subtitle kartu juga harus tergambar: bug lama membatalkan paint SELURUH
    // isi kartu, bukan cuma nama metodenya.
    final Rect subRect = tester.getRect(find.text('BCA, BNI, Mandiri'));
    final int subPainted = paintedIn(subRect, 100);
    // ignore: avoid_print
    print('OK  piksel subtitle "BCA, BNI, Mandiri": tergambar=$subPainted  '
        'rect=$subRect');
    expect(subPainted, greaterThan(50),
        reason: 'subtitle kartu harus tergambar juga — bug lama mematikan '
            'SELURUH isi kartu');
  });
}
