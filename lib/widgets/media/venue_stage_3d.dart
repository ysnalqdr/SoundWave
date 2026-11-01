import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pemutar panggung 3D yang **tidak memakai WebView sama sekali**.
///
/// Kenapa begini, bukan `model_viewer_plus`:
///
/// Perangkat uji menunjukkan halaman WebView berhasil dimuat
/// (`url: http://127.0.0.1:36799/` terbaca), tetapi JavaScript-nya tidak
/// dieksekusi — judul halaman tidak berubah, panel diagnostik tidak muncul,
/// dan tidak ada satu pun laporan balik. Artinya mesin render berbasis
/// WebView tidak bisa diandalkan di sana, apa pun model yang dipakai.
///
/// Karena itu proyeksi dihitung sendiri dengan `Canvas` Flutter. Tidak ada
/// JavaScript, tidak ada WebGL, tidak ada WebView — hanya matematika
/// proyeksi di atas `CustomPainter`, yang pasti berjalan di semua perangkat
/// Android yang bisa menjalankan Flutter.
///
/// **Auto-fit.** Panggung diskalakan dan digeser otomatis agar seluruh
/// bounding box-nya pas di dalam kanvas, dengan margin. Tanpa ini, ukuran
/// gambar bergantung pada asumsi tinggi kartu — dan hasilnya panggung
/// menjulang keluar bingkai (terukur: 283 px melewati atas pada kartu
/// setinggi 200 px).
class VenueStage3D extends StatefulWidget {
  /// Warna aksen panggung, biasanya `AppColors.primary`.
  final Color warnaAksen;

  /// Tinggi area gambar.
  final double tinggi;

  const VenueStage3D({
    super.key,
    required this.warnaAksen,
    this.tinggi = 200,
  });

  @override
  State<VenueStage3D> createState() => _VenueStage3DState();
}

class _VenueStage3DState extends State<VenueStage3D>
    // Dua controller: `_auto` (putaran otomatis) dan `_momentum` (sisa
    // gesekan setelah disentuh). Mixin "Single" hanya boleh satu ticker,
    // sehingga controller kedua melempar error begitu pengguna menggeser
    // panggung — bug yang sama seperti yang sempat membuat splash crash.
    with TickerProviderStateMixin {
  /// Sudut putar horizontal awal (derajat).
  static const double _yawAwal = 28;

  /// Sudut pandang vertikal awal (derajat). Sedikit dari atas, seperti orang
  /// berdiri di area penonton.
  static const double _pitchAwal = 16;

  /// Besar ayunan putaran otomatis, derajat.
  ///
  /// **Bukan 360°.** Panggung ini punya bagian belakang yang kosong; kalau
  /// diputar penuh, pengunjung akan melihat sisi belakang yang tidak berarti.
  /// Ayunan ±14° di sekitar sudut penonton membuatnya terlihat hidup tanpa
  /// pernah kehilangan muka depannya.
  static const double _ayunan = 14;

  double _yaw = _yawAwal;
  double _pitch = _pitchAwal;

  /// Jarak kamera. Semakin kecil, semakin dekat.
  double _jarak = 1.0;

  late final AnimationController _auto = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  bool _disentuh = false;

  /// Nilai acuan saat cubitan dimulai. Tanpa ini, `d.scale` yang bersifat
  /// kumulatif akan dikalikan berulang dan cubitan terasa mati.
  double _skalaAwal = 1.0;
  double _jarakAwal = 1.0;

  /// Kecepatan putar terakhir (derajat per frame), dipakai untuk meneruskan
  /// putaran setelah jari dilepas. Geseran sekali lepas tidak langsung
  /// berhenti — terasa jauh lebih ringan di layar sentuh.
  double _kecepatanYaw = 0;
  double _kecepatanPitch = 0;

  /// Pengendali animasi momentum. Dipisah dari [_auto] supaya putaran
  /// otomatis dan sisa geseran tidak saling mematikan.
  AnimationController? _momentum;

  @override
  void dispose() {
    _auto.dispose();
    _momentum?.dispose();
    super.dispose();
  }

  void _hentikanAuto() {
    if (_disentuh) return;
    _disentuh = true;
    _auto.stop();
  }

  void _hentikanMomentum() {
    _momentum?.stop();
    _momentum = null;
  }

  /// Meneruskan putaran setelah jari dilepas, lalu melambat perlahan.
  ///
  /// Tanpa ini, satu geseran pendek langsung berhenti dan terasa kaku.
  /// Dengan ini, satu kibasan bisa memutar panggung hampir penuh.
  void _mulaiMomentum() {
    final kecepatanAwal = _kecepatanYaw;
    final pitchAwal = _kecepatanPitch;
    // Kibasan terlalu pelan: jangan beri momentum, biar terasa presisi.
    if (kecepatanAwal.abs() < 0.6 && pitchAwal.abs() < 0.4) return;

    _hentikanMomentum();
    var sisaYaw = kecepatanAwal;
    var sisaPitch = pitchAwal;
    // Pelambatan per frame. 0,94 berarti sekitar 90% kecepatan hilang dalam
    // ~37 frame (0,6 detik) — cukup terasa, tidak berlebihan.
    const pelambatan = 0.94;

    _momentum = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _momentum!.addListener(() {
      sisaYaw *= pelambatan;
      sisaPitch *= pelambatan;
      if (sisaYaw.abs() < 0.05 && sisaPitch.abs() < 0.05) {
        _hentikanMomentum();
        return;
      }
      setState(() {
        _yaw = (_yaw + sisaYaw) % 360;
        _pitch = (_pitch + sisaPitch).clamp(2.0, 78.0);
      });
    });
    _momentum!.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (_) {
        _hentikanAuto();
        _hentikanMomentum();
        _skalaAwal = 1.0;
        _jarakAwal = _jarak;
        _kecepatanYaw = 0;
        _kecepatanPitch = 0;
      },
      onScaleUpdate: (d) {
        // Skala dihitung RELATIF terhadap skala awal cubitan.
        //
        // `d.scale` adalah skala kumulatif sejak jari menyentuh layar, bukan
        // perubahan per frame. Mengalikannya berulang kali seperti sebelumnya
        // membuat nilai langsung mentok di batas dan cubitan terasa mati.
        final skalaRelatif = d.scale / _skalaAwal;
        setState(() {
          // Geser satu jari = putar 360° bebas. `_yaw` TIDAK dibatasi:
          // pengguna boleh memutar penuh ke segala arah.
          final geserYaw = d.focalPointDelta.dx * 0.5;
          final geserPitch = -d.focalPointDelta.dy * 0.3;
          _yaw = (_yaw + geserYaw) % 360;
          _pitch = (_pitch + geserPitch).clamp(2.0, 78.0);
          // Simpan kecepatan untuk momentum setelah jari dilepas.
          _kecepatanYaw = geserYaw;
          _kecepatanPitch = geserPitch;
          if (skalaRelatif != 1.0) {
            // Cubit: jari menjauh (scale > 1) harus MEMBESARKAN objek.
            // Batas 0.65–1.25: cukup untuk melihat detail, tapi tidak sampai
            // panggung hilang keluar bingkai.
            _jarak = (_jarakAwal * skalaRelatif).clamp(0.65, 1.25);
          }
        });
      },
      onScaleEnd: (_) => _mulaiMomentum(),
      child: AnimatedBuilder(
        animation: _auto,
        builder: (context, _) {
          // Sebelum disentuh: mengayun pelan di sekitar sudut awal.
          // Sesudah disentuh: sudut sepenuhnya milik pengguna.
          final ayun = _disentuh
              ? 0.0
              : math.sin(_auto.value * 2 * math.pi) * _ayunan;
          return CustomPaint(
            size: Size.infinite,
            painter: StagePainter(
              yaw: _yaw + ayun,
              pitch: _pitch,
              jarak: _jarak,
              aksen: widget.warnaAksen,
              terang: Theme.of(context).brightness == Brightness.light,
            ),
            child: SizedBox(height: widget.tinggi, width: double.infinity),
          );
        },
      ),
    );
  }
}

/// Satu batang panggung: dua sudut berlawanan pada ruang 3D.
class StageBalok {
  final double x1, y1, z1, x2, y2, z2;

  /// `true` = permukaan (lantai, layar) digambar berisi.
  /// `false` = kerangka truss, hanya garis.
  final bool isi;

  const StageBalok(
    this.x1,
    this.y1,
    this.z1,
    this.x2,
    this.y2,
    this.z2, {
    required this.isi,
  });

  /// Kedelapan sudut balok, urut: bawah (0–3) lalu atas (4–7).
  List<List<double>> get sudut => [
        [x1, y1, z1],
        [x2, y1, z1],
        [x2, y1, z2],
        [x1, y1, z2],
        [x1, y2, z1],
        [x2, y2, z1],
        [x2, y2, z2],
        [x1, y2, z2],
      ];
}

/// Menggambar panggung 3D dengan proyeksi perspektif sederhana.
class StagePainter extends CustomPainter {
  final double yaw;
  final double pitch;
  final double jarak;
  final Color aksen;
  final bool terang;

  const StagePainter({
    required this.yaw,
    required this.pitch,
    required this.jarak,
    required this.aksen,
    required this.terang,
  });

  /// Geometri panggung. Satuan bebas; yang penting proporsinya.
  ///
  /// Sumbu: x = kiri-kanan, y = atas-bawah, z = depan-belakang (z positif
  /// berarti ke arah penonton).
  static const List<StageBalok> balok = [
    // Lantai panggung utama.
    StageBalok(-1.0, 0.0, -0.9, 1.0, 0.10, 0.5, isi: true),
    // Runway menjorok ke depan.
    StageBalok(-0.34, 0.0, 0.5, 0.34, 0.10, 1.45, isi: true),
    // Empat tiang truss.
    StageBalok(-1.0, 0.10, -0.90, -0.88, 1.15, -0.78, isi: false),
    StageBalok(0.88, 0.10, -0.90, 1.0, 1.15, -0.78, isi: false),
    StageBalok(-1.0, 0.10, 0.38, -0.88, 1.15, 0.50, isi: false),
    StageBalok(0.88, 0.10, 0.38, 1.0, 1.15, 0.50, isi: false),
    // Rangka atas: depan, belakang, kiri, kanan.
    StageBalok(-1.0, 1.05, -0.88, 1.0, 1.20, -0.76, isi: false),
    StageBalok(-1.0, 1.05, 0.40, 1.0, 1.20, 0.52, isi: false),
    StageBalok(-1.0, 1.05, -0.88, -1.0, 1.20, 0.52, isi: false),
    StageBalok(1.0, 1.05, -0.88, 1.0, 1.20, 0.52, isi: false),
    // Layar backdrop di belakang panggung.
    StageBalok(-0.74, 0.10, -0.88, 0.74, 0.95, -0.86, isi: true),
  ];

  /// Jarak kamera untuk proyeksi perspektif. Semakin besar, semakin datar.
  static const double _kamera = 3.2;

  /// Memproyeksikan satu titik 3D ke koordinat layar mentah.
  ///
  /// Dipakai oleh [paint] dan juga oleh tes, sehingga arah pandang kamera
  /// bisa diperiksa dengan angka — bukan dengan menilai gambar.
  ///
  /// `f` adalah faktor skala: lebih besar berarti lebih dekat ke kamera.
  static ({double sx, double sy, double d, double f}) proyeksiMentah({
    required double x,
    required double y,
    required double z,
    required double yaw,
    required double pitch,
  }) {
    final ry = yaw * math.pi / 180;
    final rx = pitch * math.pi / 180;
    final cosY = math.cos(ry), sinY = math.sin(ry);
    final cosX = math.cos(rx), sinX = math.sin(rx);
    // Rotasi terhadap sumbu Y (putar kiri-kanan).
    final x1 = x * cosY - z * sinY;
    final z1 = x * sinY + z * cosY;
    // Rotasi terhadap sumbu X (kamera menunduk).
    final y2 = y * cosX - z1 * sinX;
    final z2 = y * sinX + z1 * cosX;
    // z2 positif = titik berada di sisi PENONTON = lebih dekat ke kamera.
    final zc = z2.clamp(-_kamera + 0.6, _kamera - 0.6);
    final f = _kamera / (_kamera - zc);
    // y dunia positif = ke atas, sedangkan layar y positif = ke bawah.
    return (sx: x1 * f, sy: -y2 * f, d: z2, f: f);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    ({double sx, double sy, double d, double f}) mentah(
      double x,
      double y,
      double z,
    ) =>
        StagePainter.proyeksiMentah(x: x, y: y, z: z, yaw: yaw, pitch: pitch);

    // ---- Tahap 1: cari bounding box seluruh titik ----
    var minX = double.infinity, maxX = -double.infinity;
    var minY = double.infinity, maxY = -double.infinity;
    for (final b in balok) {
      for (final s in b.sudut) {
        final p = mentah(s[0], s[1], s[2]);
        if (p.sx < minX) minX = p.sx;
        if (p.sx > maxX) maxX = p.sx;
        if (p.sy < minY) minY = p.sy;
        if (p.sy > maxY) maxY = p.sy;
      }
    }

    final lebarIsi = (maxX - minX).clamp(0.0001, double.infinity);
    final tinggiIsi = (maxY - minY).clamp(0.0001, double.infinity);

    // ---- Tahap 2: skalakan agar pas di kanvas ----
    // Margin 8% tiap sisi supaya garis tepi tidak menempel bingkai.
    final margin = size.shortestSide * 0.08;
    final skala = math.min(
          (size.width - margin * 2) / lebarIsi,
          (size.height - margin * 2) / tinggiIsi,
        ) *
        jarak;

    // Titik tengah isi dipetakan ke titik tengah kanvas.
    final tengahIsiX = (minX + maxX) / 2;
    final tengahIsiY = (minY + maxY) / 2;
    final pusat = Offset(size.width / 2, size.height / 2);

    Offset proyeksi(double x, double y, double z) {
      final p = mentah(x, y, z);
      return pusat +
          Offset(
            (p.sx - tengahIsiX) * skala,
            (p.sy - tengahIsiY) * skala,
          );
    }

    // ---- Tahap 3: urutkan dari jauh ke dekat ----
    final urut = <({StageBalok balok, double d})>[];
    for (final b in balok) {
      var jumlah = 0.0;
      for (final s in b.sudut) {
        jumlah += mentah(s[0], s[1], s[2]).d;
      }
      urut.add((balok: b, d: jumlah / 8));
    }
    urut.sort((a, b) => b.d.compareTo(a.d));

    final warnaGaris = terang
        ? const Color(0xFF6B7280)
        : const Color(0xFFA1A1AA);
    final warnaAtas = terang
        ? const Color(0xFFE5E7EB)
        : const Color(0xFF26262F);
    final warnaSisi = terang
        ? const Color(0xFFD1D5DB)
        : const Color(0xFF14141A);

    for (final item in urut) {
      final b = item.balok;
      final v = [
        for (final s in b.sudut) proyeksi(s[0], s[1], s[2]),
      ];

      // Enam sisi balok.
      const sisi = <List<int>>[
        [0, 1, 2, 3], // bawah
        [4, 5, 6, 7], // atas
        [0, 1, 5, 4], // depan
        [1, 2, 6, 5], // kanan
        [2, 3, 7, 6], // belakang
        [3, 0, 4, 7], // kiri
      ];

      for (var i = 0; i < sisi.length; i++) {
        final s = sisi[i];
        final jalur = Path()
          ..addPolygon([v[s[0]], v[s[1]], v[s[2]], v[s[3]]], true);

        if (b.isi) {
          canvas.drawPath(
            jalur,
            Paint()..color = i == 1 ? warnaAtas : warnaSisi,
          );
          canvas.drawPath(
            jalur,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.9
              ..color = aksen.withValues(alpha: 0.45),
          );
        } else {
          canvas.drawPath(
            jalur,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.3
              ..strokeJoin = StrokeJoin.round
              ..color = warnaGaris,
          );
        }
      }
    }

    // Lampu panggung di bawah rangka atas.
    for (final x in [-0.6, -0.2, 0.2, 0.6]) {
      final l = proyeksi(x, 1.00, -0.82);
      canvas.drawCircle(
        l,
        math.max(3.0, size.shortestSide * 0.020),
        Paint()..color = aksen.withValues(alpha: 0.20),
      );
      canvas.drawCircle(
        l,
        math.max(1.4, size.shortestSide * 0.009),
        Paint()..color = aksen,
      );
    }

    // Garis tepi depan panggung & ujung runway sebagai penegas.
    final tepi = Paint()
      ..strokeWidth = 1.3
      ..color = aksen.withValues(alpha: 0.6);
    canvas.drawLine(proyeksi(-1.0, 0.0, 0.5), proyeksi(1.0, 0.0, 0.5), tepi);
    canvas.drawLine(
        proyeksi(-0.34, 0.0, 1.45), proyeksi(0.34, 0.0, 1.45), tepi);
  }

  @override
  bool shouldRepaint(covariant StagePainter old) =>
      old.yaw != yaw ||
      old.pitch != pitch ||
      old.jarak != jarak ||
      old.aksen != aksen ||
      old.terang != terang;
}
