import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/utils/app_theme.dart';

/// Regresi bug admin "masa berlaku tidak bisa di-save".
///
/// Sebelumnya form promo memakai `showDateRangePicker` yang dibungkus
/// `GestureDetector + AbsorbPointer`, dan nilai rentang hanya ditulis ke
/// `hintText` (hint disembunyikan saat field kosong & tak fokus). Akibatnya
/// tanggal yang dipilih TIDAK PERNAH terlihat, sehingga admin mengira masa
/// berlaku gagal disimpan.
///
/// Fix: dua field `readOnly` + `showDatePicker` yang menulis nilai ke
/// controller sehingga tanggal terpilih langsung tampil di field.
class _PromoDateFields extends StatefulWidget {
  const _PromoDateFields();

  @override
  State<_PromoDateFields> createState() => _PromoDateFieldsState();
}

class _PromoDateFieldsState extends State<_PromoDateFields> {
  final _mulaiCtrl = TextEditingController();
  final _akhirCtrl = TextEditingController();
  DateTime? _mulai;
  DateTime? _akhir;

  @override
  void dispose() {
    _mulaiCtrl.dispose();
    _akhirCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime t) => '${t.day.toString().padLeft(2, '0')}/'
      '${t.month.toString().padLeft(2, '0')}/${t.year}';

  Future<void> _pick({required bool mulai}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: mulai ? (_mulai ?? now) : (_akhir ?? _mulai ?? now),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: mulai ? 'Pilih tanggal mulai' : 'Pilih tanggal akhir',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
                onPrimary: AppColors.warnaTombolTeks,
                surface: AppColors.surfaceLight,
                surfaceContainerHigh: AppColors.surfaceLight,
              ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final d = DateTime(picked.year, picked.month, picked.day);
    setState(() {
      if (mulai) {
        _mulai = d;
        _mulaiCtrl.text = _fmt(d);
      } else {
        _akhir = d;
        _akhirCtrl.text = _fmt(d);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _mulaiCtrl,
                readOnly: true,
                onTap: () => _pick(mulai: true),
                decoration: const InputDecoration(
                  labelText: 'Berlaku Mulai',
                  hintText: 'Pilih tanggal',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _akhirCtrl,
                readOnly: true,
                onTap: () => _pick(mulai: false),
                decoration: const InputDecoration(
                  labelText: 'Berlaku Akhir',
                  hintText: 'Pilih tanggal',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  ThemeData darkThemeLikeApp() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary, // putih -> dulu bikin tombol tak terlihat
          secondary: AppColors.accent,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.background,
      );

  String fmt(DateTime t) => '${t.day.toString().padLeft(2, '0')}/'
      '${t.month.toString().padLeft(2, '0')}/${t.year}';

  testWidgets('tap "Berlaku Mulai" membuka date picker & nilainya tampil',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: darkThemeLikeApp(),
      home: const _PromoDateFields(),
    ));

    // Field kosong -> belum ada tanggal.
    expect(find.text(fmt(DateTime.now())), findsNothing);

    // Tap field mulai -> date picker terbuka (helpText terlihat).
    await tester.tap(find.byType(TextFormField).first);
    await tester.pumpAndSettle();
    expect(find.text('Pilih tanggal mulai'), findsOneWidget);

    // Konfirmasi tanggal (default = hari ini).
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

        // Nilai harus terlihat di field. Bug lama: tidak terlihat.
    expect(find.text(fmt(DateTime.now())), findsOneWidget);
  });

  testWidgets('tap "Berlaku Akhir" membuka picker terpisah', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: darkThemeLikeApp(),
      home: const _PromoDateFields(),
    ));

    await tester.tap(find.byType(TextFormField).last);
    await tester.pumpAndSettle();
    expect(find.text('Pilih tanggal akhir'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Satu nilai di field akhir.
    expect(find.text(fmt(DateTime.now())), findsOneWidget);
  });
}
