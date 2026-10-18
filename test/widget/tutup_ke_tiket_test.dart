import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/providers/app_providers.dart';

/// Penjaga: tombol penutup alur pembayaran harus mendarat di **Tiket Saya**,
/// bukan tertinggal di langkah 3 checkout.
///
/// Bug 17 Okt 2026: "Tutup" hanya menutup bottom sheet (`Navigator.of(ctx).pop()`),
/// sehingga layar checkout step 3 masih terbuka di bawahnya dan user tidak
/// pernah sampai ke daftar tiketnya.
void main() {
  final checkout = File('lib/screens/user/checkout_screen.dart');
  final mainUser = File('lib/screens/user/user_main_screen.dart');
  final providers = File('lib/providers/app_providers.dart');

  group('checkout_screen.dart', () {
    late String isi;
    setUpAll(() => isi = checkout.readAsStringSync());

    test('kedua tombol penutup memakai _keTiketSaya, bukan pop() polos', () {
      expect(isi, contains('onPressed: _keTiketSaya'));
      expect(isi, isNot(contains('Navigator.of(ctx).pop(),')),
          reason: 'pop() polos hanya menutup sheet dan menyisakan step 3');
      expect(isi, contains('popUntil((r) => r.isFirst)'),
          reason: 'harus keluar dari seluruh alur checkout');
    });

    test('tab tujuan diatur ke indeks 1 (Tiket Saya)', () {
      expect(isi, contains('permintaanTabUserProvider.notifier'));
      expect(isi, contains('tab.state = 1'));
    });

    test('notifier diambil sebelum popUntil (layar ikut ditutup)', () {
      // periksa urutan DI DALAM badan _keTiketSaya saja
      final mulai = isi.indexOf('void _keTiketSaya()');
      expect(mulai, greaterThan(-1), reason: '_keTiketSaya harus ada');
      final badan = isi.substring(mulai, isi.indexOf('void _showWaitingInfo()'));

      final ambil = badan.indexOf('permintaanTabUserProvider.notifier');
      final pop = badan.indexOf('popUntil');
      final set = badan.indexOf('tab.state = 1');
      expect(ambil, greaterThan(-1));
      expect(ambil, lessThan(pop), reason: 'notifier harus diambil dulu');
      expect(pop, lessThan(set), reason: 'state diatur setelah keluar layar');
    });

    test('label tombol jelas: "Ke Tiket Saya", bukan "Tutup"', () {
      // 2 sheet (VA/QR & kartu) + tombol kiri bawah di langkah Bayar
      expect("'Ke Tiket Saya'".allMatches(isi).length, greaterThanOrEqualTo(2),
          reason: 'sheet VA/QR dan sheet kartu');
      expect(isi, isNot(contains("'Tutup'")));
    });

    test('layar sukses juga mendarat di Tiket Saya', () {
      expect(isi, isNot(contains('Navigator.of(context).pop(true)')));
    });
  });

  group('user_main_screen.dart', () {
    test('menu utama mendengarkan permintaan tab', () {
      final isi = mainUser.readAsStringSync();
      expect(isi, contains('ref.listen<int>(permintaanTabUserProvider'));
      expect(isi, contains('_pindahKeTab(tab)'));
    });
  });

  group('app_providers.dart', () {
    test('provider permintaan tab ada', () {
      final isi = providers.readAsStringSync();
      expect(isi, contains('permintaanTabUserProvider = StateProvider<int>'));
    });
  });

  group('perilaku provider', () {
    test('perubahan tab memicu listener, nilai awal 0 (Jelajah)', () {
      final wadah = ProviderContainer();
      addTearDown(wadah.dispose);

      expect(wadah.read(permintaanTabUserProvider), 0);

      final tercatat = <int>[];
      wadah.listen<int>(permintaanTabUserProvider, (_, tab) {
        tercatat.add(tab);
      });

      wadah.read(permintaanTabUserProvider.notifier).state = 1;
      expect(tercatat, [1]);
      expect(wadah.read(permintaanTabUserProvider), 1);
    });
  });
}
