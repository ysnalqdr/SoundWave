/// Daftar model venue 3D yang dibundel di dalam aplikasi.
///
/// Pola ini sama dengan [AudioLibrary]: satu sumber kebenaran, sehingga admin
/// memilih dari daftar yang pasti dikenal pemutar, dan tes bisa memastikan
/// setiap berkas benar-benar ada di disk.
///
/// **Lisensi wajib dicantumkan.** Setiap model di sini berlisensi Creative
/// Commons Attribution (CC-BY) atau CC0. Untuk CC-BY, mencantumkan kredit
/// bukan formalitas — itu syarat hukum pemakaiannya. Karena itu [VenueModel]
/// membawa `pembuat`, `lisensi`, dan `sumber`, dan UI menampilkannya di bawah
/// model.
///
/// **Setelan kamera disimpan per model.** Dua model berbeda hampir selalu
/// butuh sudut, jarak, dan exposure berbeda: satu berupa ruangan tertutup yang
/// gelap, satu lagi panggung terbuka dengan lantai hitam mengkilap. Memakai
/// satu setelan untuk semua membuat salah satunya pasti terlihat buruk.
class VenueModelLibrary {
  VenueModelLibrary._();

  static const List<VenueModel> models = [
    VenueModel(
      ref: 'assets/models/concert_stage.glb',
      nama: 'Concert Stage',
      judulAsli: 'Concert Stage',
      pembuat: 'iPoly3D',
      lisensi: 'CC BY 4.0',
      sumber: 'https://sketchfab.com/iPoly3D',
      // Tanpa tekstur sama sekali: 20.122 segitiga, 4 material warna solid.
      // Berkas 0,73 MB — paling ringan dan paling mungkin berhasil dirender
      // di WebView perangkat kelas menengah.
      ukuranMb: 0.7,
      keterangan: 'Panggung konser dengan truss, lighting, dan runway. '
          'Tanpa tekstur gambar, jadi paling ringan untuk perangkat mobile.',
      // Panggung terbuka. Kamera ditarik jauh (75m) karena runway menjorok
      // ke depan; dengan jarak lebih dekat ujung runway terpotong.
      cameraOrbit: '30deg 68deg 75m',
      cameraTarget: '0m 5m 0m',
      minCameraOrbit: '0deg 48deg 55m',
      maxCameraOrbit: '70deg 85deg 95m',
      fieldOfView: '50deg',
      // Lantai panggung hitam mengkilap; tanpa exposure tinggi seluruh
      // bagian bawah hilang dalam bayangan.
      exposure: 2.2,
      posterRef: 'assets/images/panggung/concert.jpg',
    ),
    VenueModel(
      ref: 'assets/models/every_gig_ever.glb',
      nama: 'Stage',
      // Nama asli model di Sketchfab, dipakai sebagai judul kredit.
      judulAsli: 'Every gig, ever...',
      pembuat: 'PippyJ',
      lisensi: 'CC BY 4.0',
      sumber: 'https://sketchfab.com/3d-models/every-gig-ever-c8cdb7d1538477380445d2f0d2531b2',
      // Angka setelah optimasi: 24.7k segitiga, tekstur 512px, tanpa normal map.
      ukuranMb: 3.7,
      keterangan: 'Panggung band lengkap: drum, amplifier, monitor, dan lampu '
          'panggung. Cocok untuk venue kecil sampai menengah.',
      // Model ini berupa ruangan TERTUTUP. Titik pusat geometrinya jatuh di
      // tengah ruangan, dan kamera bawaan model-viewer menempatkan diri di
      // luar gedung — yang terlihat hanya dinding bata dari belakang.
      // Orbit 270° menempatkan kamera di sisi penonton; target 2.4m 3.4m 0m
      // adalah panggungnya; jarak 13m memuat truss sampai monitor.
      cameraOrbit: '270deg 72deg 13m',
      cameraTarget: '2.4m 3.4m 0m',
      // Busur orbit dikunci ke sisi penonton: di luar ini kamera keluar
      // gedung dan yang tampil hanya dinding bata bagian luar.
      minCameraOrbit: '245deg 54deg 10m',
      maxCameraOrbit: '295deg 86deg 18m',
      fieldOfView: '55deg',
      exposure: 1.9,
      posterRef: 'assets/images/panggung/gig.jpg',
    ),
  ];

  /// Mencari model berdasarkan referensinya. Null bila tidak ada di pustaka.
  static VenueModel? byRef(String? ref) {
    if (ref == null) return null;
    for (final m in models) {
      if (m.ref == ref) return m;
    }
    return null;
  }
}

/// Satu model venue yang dibundel.
class VenueModel {
  /// Path aset, mis. `assets/models/concert_stage.glb`.
  final String ref;

  /// Nama pendek yang ditampilkan di pemilih admin.
  final String nama;

  /// Judul asli dari pembuatnya, dipakai di baris kredit.
  final String judulAsli;

  /// Nama pembuat model. **Wajib ditampilkan** untuk lisensi CC-BY.
  final String pembuat;

  /// Jenis lisensi, mis. `CC BY 4.0`.
  final String lisensi;

  /// Alamat halaman asal model.
  final String sumber;

  /// Ukuran berkas dalam MB, untuk ditampilkan di pemilih.
  final double ukuranMb;

  /// Keterangan singkat untuk membantu admin memilih.
  final String keterangan;

  /// Sudut pandang awal, format `model-viewer` (`azimuth polar jarak`).
  final String cameraOrbit;

  /// Titik yang dibidik kamera, format `model-viewer` (`x y z`).
  final String cameraTarget;

  /// Batas busur orbit. Di luar batas ini kamera bisa keluar dari ruangan
  /// atau melihat bagian yang tidak dimaksudkan.
  final String minCameraOrbit;
  final String maxCameraOrbit;

  /// Sudut pandang kamera dalam derajat.
  final String fieldOfView;

  /// Tingkat pencahayaan. Model bervenue gelap butuh nilai lebih tinggi.
  final double exposure;

  /// Path poster: hasil render model ini, dipakai sebagai gambar utama
  /// karena WebView tidak bisa diandalkan di semua perangkat.
  final String posterRef;

  const VenueModel({
    required this.ref,
    required this.nama,
    required this.judulAsli,
    required this.pembuat,
    required this.lisensi,
    required this.sumber,
    required this.ukuranMb,
    required this.keterangan,
    required this.cameraOrbit,
    required this.cameraTarget,
    required this.minCameraOrbit,
    required this.maxCameraOrbit,
    required this.fieldOfView,
    required this.exposure,
    required this.posterRef,
  });

  /// Baris kredit siap tampil, mis.
  /// `"Every gig, ever..." oleh PippyJ · CC BY 4.0`.
  String get kredit => 'by $pembuat';

  /// Azimuth awal sebagai angka, dipakai tombol geser kiri/kanan di layar
  /// penuh. Format `cameraOrbit` adalah `azimuth polar jarak`.
  double get azimuthAwal =>
      double.tryParse(cameraOrbit.split(' ').first.replaceAll('deg', '')) ?? 0;

  /// Batas azimuth minimum, dibaca dari [minCameraOrbit].
  double get azimuthMin => double.tryParse(
        minCameraOrbit.split(' ').first.replaceAll('deg', ''),
      ) ??
      0;

  /// Batas azimuth maksimum, dibaca dari [maxCameraOrbit].
  double get azimuthMax => double.tryParse(
        maxCameraOrbit.split(' ').first.replaceAll('deg', ''),
      ) ??
      360;

  /// Polar dan jarak awal, dipakai saat menggeser azimuth agar sudut tegak
  /// dan jarak tidak ikut berubah.
  String get polarDanJarak {
    final bagian = cameraOrbit.split(' ');
    return bagian.length >= 3 ? '${bagian[1]} ${bagian[2]}' : '70deg 20m';
  }
}
