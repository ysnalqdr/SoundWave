import 'dart:io';

/// Menggabungkan isi berkas utama dan seluruh `part`-nya.
///
/// Dipakai oleh tes yang memeriksa sumber kode sebagai teks. Sejak
/// `checkout_screen.dart` dipecah menjadi beberapa `part`, pemeriksaan pada
/// satu berkas saja tidak lagi mewakili keseluruhan layar.
///
/// Urutan penting: **`part` ditulis lebih dulu, berkas utama paling akhir.**
/// Berkas utama memuat deklarasi abstrak (`void _foo();`) di kelas basis, yang
/// bentuk teksnya sama dengan implementasi (`void _foo() {`) pada `part`.
/// Dengan menaruh `part` di depan, `indexOf('void _foo()')` menemukan
/// implementasinya — bukan deklarasi — sehingga tes yang memeriksa isi badan
/// method tetap sahih.
String bacaLibrary(String berkasUtama) {
  final utama = File(berkasUtama);
  if (!utama.existsSync()) return '';
  final isiUtama = utama.readAsStringSync();
  final dir = utama.parent;

  final buffer = StringBuffer();
  final partRegex = RegExp(r"""^part\s+'([^']+)';""", multiLine: true);
  for (final m in partRegex.allMatches(isiUtama)) {
    final relatif = m.group(1)!;
    final berkas = File('${dir.path}/$relatif');
    if (berkas.existsSync()) {
      buffer.writeln(berkas.readAsStringSync());
    }
  }
  buffer.writeln(isiUtama);
  return buffer.toString();
}

/// Jalur berkas utama layar checkout.
const String berkasCheckoutUtama = 'lib/screens/user/checkout_screen.dart';
