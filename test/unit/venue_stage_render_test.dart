import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/widgets/media/venue_stage_3d.dart';

/// Menjaga dua hal yang keduanya pernah rusak:
///
/// 1. **Panggung tidak keluar bingkai.** Dulu menjulang 283 px melewati atas
///    kartu setinggi 200 px, sehingga 59% gambar terpotong.
/// 2. **Kamera berada di sisi penonton.** Dulu rumus perspektifnya terbalik:
///    runway yang menjorok ke arah penonton justru digambar lebih kecil,
///    sehingga yang terlihat seolah bagian belakang panggung.
void main() {
  /// Menggambar pada ukuran tertentu, mengembalikan bounding box isi.
  Future<({int kiri, int atas, int kanan, int bawah, int w, int h})> gambar({
    required Size ukuran,
    double yaw = 28,
    double pitch = 16,
    double jarak = 1.0,
  }) async {
    const latar = Color(0xFF101216);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Offset.zero & ukuran, Paint()..color = latar);
    StagePainter(
      yaw: yaw,
      pitch: pitch,
      jarak: jarak,
      aksen: const Color(0xFF34D399),
      terang: false,
    ).paint(canvas, ukuran);
    final img = await recorder.endRecording().toImage(
          ukuran.width.toInt(),
          ukuran.height.toInt(),
        );
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    final px = data!.buffer.asUint8List();
    final w = img.width, h = img.height;

    var kiri = w, kanan = -1, atas = h, bawah = -1;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = (y * w + x) * 4;
        final r = px[i], g = px[i + 1], b = px[i + 2], a = px[i + 3];
        if (a < 200) continue;
        final beda = (r - 0x10).abs() + (g - 0x12).abs() + (b - 0x16).abs();
        if (beda > 24) {
          if (x < kiri) kiri = x;
          if (x > kanan) kanan = x;
          if (y < atas) atas = y;
          if (y > bawah) bawah = y;
        }
      }
    }
    return (kiri: kiri, atas: atas, kanan: kanan, bawah: bawah, w: w, h: h);
  }

  group('Panggung tidak keluar bingkai', () {
    test('semua ukuran kartu', () async {
      const ukuran = <Size>[
        Size(320, 200),
        Size(360, 180),
        Size(280, 240),
        Size(400, 220),
        Size(300, 150),
        Size(320, 320),
      ];

      for (final s in ukuran) {
        final r = await gambar(ukuran: s);
        final label = '${s.width.toInt()}x${s.height.toInt()}';
        expect(r.kanan, greaterThan(-1),
            reason: 'Tidak ada isi tergambar pada $label');
        expect(r.kiri, greaterThan(2), reason: '$label: keluar tepi kiri');
        expect(r.atas, greaterThan(2), reason: '$label: keluar tepi atas');
        expect(r.kanan, lessThan(r.w - 3),
            reason: '$label: keluar tepi kanan');
        expect(r.bawah, lessThan(r.h - 3),
            reason: '$label: keluar tepi bawah');
        expect((r.kanan - r.kiri) / r.w, greaterThan(0.4),
            reason: '$label: panggung terlalu kecil');
      }
    });

    test('sudut putar ekstrem', () async {
      const s = Size(320, 200);
      for (final yaw in [0.0, 45.0, 90.0, 135.0, 180.0, 270.0, 315.0]) {
        for (final pitch in [4.0, 16.0, 45.0, 70.0]) {
          final r = await gambar(ukuran: s, yaw: yaw, pitch: pitch);
          final label = 'yaw ${yaw.toInt()} pitch ${pitch.toInt()}';
          expect(r.kiri, greaterThan(1), reason: '$label: keluar kiri');
          expect(r.atas, greaterThan(1), reason: '$label: keluar atas');
          expect(r.kanan, lessThan(r.w - 2), reason: '$label: keluar kanan');
          expect(r.bawah, lessThan(r.h - 2), reason: '$label: keluar bawah');
        }
      }
    });

    test('zoom keluar tetap utuh', () async {
      const s = Size(320, 200);
      for (final jarak in [0.65, 0.8, 1.0]) {
        final r = await gambar(ukuran: s, jarak: jarak);
        final label = 'jarak $jarak';
        expect(r.kiri, greaterThan(1), reason: '$label: keluar kiri');
        expect(r.atas, greaterThan(1), reason: '$label: keluar atas');
        expect(r.kanan, lessThan(r.w - 2), reason: '$label: keluar kanan');
        expect(r.bawah, lessThan(r.h - 2), reason: '$label: keluar bawah');
      }
    });

    test('zoom masuk tetap di tengah', () async {
      const s = Size(320, 200);
      final r = await gambar(ukuran: s, jarak: 1.25);
      final tengahX = ((r.kiri + r.kanan) / 2) / r.w;
      final tengahY = ((r.atas + r.bawah) / 2) / r.h;
      expect(tengahX, closeTo(0.5, 0.12),
          reason: 'Panggung bergeser dari tengah saat di-zoom');
      expect(tengahY, closeTo(0.5, 0.12),
          reason: 'Panggung bergeser dari tengah saat di-zoom');
    });
  });

  group('Kamera di sisi penonton', () {
    test('runway tampak lebih besar daripada truss belakang', () {
      // Uji geometris murni, tanpa render.
      //
      // Runway adalah bagian paling dekat penonton (z = +1.45); truss
      // belakang paling jauh (z = -0.88). Pada proyeksi yang benar, faktor
      // skala runway harus LEBIH BESAR.
      //
      // Dulu rumusnya `kamera / (kamera + z)`, sehingga titik dekat justru
      // dikecilkan dan kamera terlihat berada di belakang panggung.
      final runway = StagePainter.proyeksiMentah(
        x: 0,
        y: 0.05,
        z: 1.45,
        yaw: 28,
        pitch: 16,
      );
      final truss = StagePainter.proyeksiMentah(
        x: 0,
        y: 1.10,
        z: -0.88,
        yaw: 28,
        pitch: 16,
      );

      // ignore: avoid_print
      print('RUNWAY f=${runway.f.toStringAsFixed(3)} '
          'sy=${runway.sy.toStringAsFixed(3)} | '
          'TRUSS f=${truss.f.toStringAsFixed(3)} '
          'sy=${truss.sy.toStringAsFixed(3)}');

      expect(runway.f, greaterThan(truss.f),
          reason: 'Runway harus tampak lebih besar karena lebih dekat ke '
              'penonton. Kalau tidak, kamera berada di belakang panggung.');
      // Runway (dekat) harus berada di BAWAH truss (jauh) pada layar.
      expect(runway.sy, greaterThan(truss.sy),
          reason: 'Bagian dekat penonton harus tergambar lebih rendah di '
              'layar daripada bagian jauh');
    });

    test('sudut awal memang menghadap muka panggung', () {
      // Layar backdrop ada di belakang panggung (z = -0.86); runway di depan
      // (z = +1.45). Kamera harus melihat layar backdrop lebih jauh daripada
      // runway.
      final layar = StagePainter.proyeksiMentah(
        x: 0,
        y: 0.5,
        z: -0.86,
        yaw: 28,
        pitch: 16,
      );
      final runway = StagePainter.proyeksiMentah(
        x: 0,
        y: 0.05,
        z: 1.45,
        yaw: 28,
        pitch: 16,
      );
      expect(layar.f, lessThan(runway.f),
          reason: 'Layar backdrop harus lebih jauh daripada runway');
    });
  });

  test('simpan bukti gambar untuk diperiksa manusia', () async {
    const s = Size(720, 400);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Offset.zero & s,
      Paint()..color = const Color(0xFF101216),
    );
    StagePainter(
      yaw: 28,
      pitch: 16,
      jarak: 1.0,
      aksen: const Color(0xFF34D399),
      terang: false,
    ).paint(canvas, s);
    final img = await recorder.endRecording().toImage(
          s.width.toInt(),
          s.height.toInt(),
        );
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    final f = File('${Directory.systemTemp.path}/panggung_bukti.png');
    f.writeAsBytesSync(png!.buffer.asUint8List());
    // ignore: avoid_print
    print('BUKTI gambar: ${f.path}');
    expect(f.existsSync(), isTrue);
  });
}
