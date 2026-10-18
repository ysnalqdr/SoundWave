import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// PENJAGA — ikon di bagian "Aktivitas" (halaman Akun) harus SERAGAM.
///
/// Latar belakang: user melaporkan ikon "Diskon Saya" hijau (`AppColors
/// .warnaHarga`) sementara "E-Tiket Saya" & "Konser Favorit" abu — tidak
/// konsisten. Penyebabnya satu baris `iconColor: AppColors.warnaHarga` yang
/// hanya dikirim item itu; `_MenuItemWidget` memakai `iconColor ??
/// AppColors.textSecondary`, jadi item tanpa `iconColor` otomatis abu.
///
/// Test ini membaca sumber dan menolak kalau ada `iconColor` muncul lagi di
/// bagian Aktivitas — supaya warna "nyala sendiri" tidak balik diam-diam.
void main() {
  const String berkas = 'lib/screens/user/user_main_screen.dart';

  late String src;
  late String bagianAktivitas;

  setUpAll(() {
    src = File(berkas).readAsStringSync();

    final int awal = src.indexOf("_sectionLabel('Aktivitas')");
    final int akhir = src.indexOf("_sectionLabel('Pengaturan')");

    expect(awal, greaterThanOrEqualTo(0),
        reason: 'bagian "Aktivitas" tak ketemu di $berkas');
    expect(akhir, greaterThan(awal),
        reason: 'bagian "Pengaturan" harus ada SETELAH "Aktivitas"');

    bagianAktivitas = src.substring(awal, akhir);
  });

  test('ketiga item Aktivitas masih ada (penjaga gagal kalau blok dipindah)',
      () {
    expect(bagianAktivitas.contains("'E-Tiket Saya'"), isTrue);
    expect(bagianAktivitas.contains("'Konser Favorit'"), isTrue);
    expect(bagianAktivitas.contains("'Diskon Saya'"), isTrue);
  });

  test('tidak ada ikon berwarna sendiri di bagian Aktivitas', () {
    expect(bagianAktivitas.contains('iconColor'), isFalse,
        reason: 'ikon di Aktivitas harus seragam abu (textSecondary). '
            'Jangan kirim iconColor di salah satu item saja — ikon akan '
            'terlihat "nyala" dibanding tetangganya.');
  });

  test('ikon default _MenuItemWidget memang abu (textSecondary)', () {
    final int idx = src.indexOf('class _MenuItemWidget');
    expect(idx, greaterThanOrEqualTo(0));

    final String widget = src.substring(idx);
    expect(widget.contains('iconColor ?? AppColors.textSecondary'), isTrue,
        reason: 'default ikon harus AppColors.textSecondary supaya item tanpa '
            'iconColor tampil abu seperti tetangganya');
  });
}
