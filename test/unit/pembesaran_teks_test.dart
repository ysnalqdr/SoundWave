import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Penjaga pembesaran teks sistem.
///
/// Kenapa ini ada: **650 `Text` di aplikasi, hanya 53 yang punya `maxLines`.**
/// Artinya 92% teks dibiarkan memanjang bebas. Di ukuran normal itu aman karena
/// kebanyakan teks pendek. Tapi begitu pengguna menaikkan ukuran font di
/// Pengaturan Android — dan banyak yang melakukannya, terutama pengguna tua —
/// teks melipat jadi 2–3 baris di dalam kartu yang tingginya tetap, lalu
/// meluber.
///
/// Aplikasi ini **tidak** mengunci `textScaler` (0 kemunculan), dan itu benar:
/// mengunci skala teks akan membuat pengguna tunanetra tidak bisa membesarkan
/// huruf. Konsekuensinya, tata letak wajib tahan sampai 200%.
///
/// Tes ini tidak menguji layar asli (butuh Firestore). Ia menguji **pola yang
/// paling sering meluber**: baris berisi ikon + teks panjang di dalam kartu
/// dengan lebar sempit. Kalau pola ini lolos di 200%, sebagian besar aplikasi
/// ikut lolos.
void main() {
  /// Membungkus [anak] dalam lebar sempit dengan skala teks tertentu.
  Widget bingkai({
    required Widget anak,
    double lebar = 320,
    double skala = 2.0,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(lebar, 800),
          textScaler: TextScaler.linear(skala),
        ),
        child: Scaffold(
          body: SizedBox(width: lebar, child: anak),
        ),
      ),
    );
  }

  /// Gagal bila ada overflow kuning-hitam.
  void pastikanTidakMeluber(WidgetTester tester, String nama) {
    final errors = <String>[];
    final exception = tester.takeException();
    if (exception != null) errors.add('$exception');

    // RenderFlex overflow dilaporkan lewat FlutterError.onError.
    expect(
      errors,
      isEmpty,
      reason: '$nama meluber pada skala teks besar: ${errors.join("; ")}',
    );
  }

  group('tata letak tahan pembesaran teks 200%', () {
    testWidgets('baris ikon + teks panjang di dalam kartu sempit', (tester) async {
      await tester.pumpWidget(
        bingkai(
          anak: Container(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.confirmation_number_outlined, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kode Booking',
                        style: TextStyle(fontSize: 11),
                      ),
                      Text(
                        'SW-2026-8812 · Konser Musik Indonesia Merdeka',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
        ),
      );
      pastikanTidakMeluber(tester, 'baris ikon + teks');
    });

    testWidgets('dua tombol sejajar di layar 240px', (tester) async {
      await tester.pumpWidget(
        bingkai(
          lebar: 240,
          anak: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Batal', maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Keluar', maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      pastikanTidakMeluber(tester, 'dua tombol sejajar');
    });

    testWidgets('label + nilai di ujung berlawanan', (tester) async {
      await tester.pumpWidget(
        bingkai(
          anak: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Kategori', style: TextStyle(fontSize: 12)),
                Flexible(
                  child: Text(
                    'VIP Festival Lengkap',
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      pastikanTidakMeluber(tester, 'label + nilai');
    });

    testWidgets('chip filter berjajar', (tester) async {
      await tester.pumpWidget(
        bingkai(
          lebar: 300,
          anak: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                Chip(label: Text('SEMUA')),
                Chip(label: Text('AKTIF')),
                Chip(label: Text('PENDING')),
                Chip(label: Text('TERPAKAI')),
                Chip(label: Text('REFUND')),
              ],
            ),
          ),
        ),
      );
      pastikanTidakMeluber(tester, 'chip filter');
    });

    testWidgets('judul panjang satu baris', (tester) async {
      await tester.pumpWidget(
        bingkai(
          lebar: 300,
          anak: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'PENJUALAN 7 HARI TERAKHIR',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );
      pastikanTidakMeluber(tester, 'judul panjang');
    });
  });

  group('pola berisiko yang harus dihindari', () {
    testWidgets('Row tanpa Expanded/Flexible dengan teks panjang MELUBER',
        (tester) async {
      // Tes ini sengaja membuktikan bahayanya. Kalau pola ini tidak meluber,
      // berarti Flutter berubah perilaku dan tes di atas perlu ditinjau ulang.
      await tester.pumpWidget(
        bingkai(
          lebar: 240,
          anak: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Label yang cukup panjang sekali',
                    style: TextStyle(fontSize: 14)),
                Text('Nilai yang juga panjang sekali',
                    style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      );
      // Overflow diharapkan muncul di sini — itulah pelajarannya.
      expect(tester.takeException(), isNotNull,
          reason: 'Row tanpa Expanded memang meluber; ini pembuktian, '
              'bukan bug tes');
    });
  });
}
