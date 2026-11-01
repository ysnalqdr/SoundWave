import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// ============================================================================
/// PENANGKAP GALAT GLOBAL
/// ============================================================================
///
/// Sebelum ini aplikasi **tidak punya jaring pengaman sama sekali**: tidak ada
/// `FlutterError.onError`, tidak ada `runZonedGuarded`, tidak ada Crashlytics.
/// Akibatnya galat yang tidak tertangani di UI hanya muncul sebentar sebagai
/// kotak merah (di mode debug) atau **hilang tanpa jejak** (di mode rilis).
///
/// Kalau aplikasi ini dipakai orang sungguhan, itu berarti: pengguna melihat
/// layar putih atau halaman kosong, dan tidak ada satu pun catatan yang bisa
/// dipakai untuk mencari sebabnya.
///
/// Yang dilakukan berkas ini:
///
/// 1. **Mencatat** setiap galat Flutter, galat platform, dan galat async yang
///    lolos, lengkap dengan jejak tumpukan.
/// 2. **Menahan** galat UI supaya satu widget yang rusak tidak membuat seluruh
///    layar menjadi kotak merah. Penggantinya `ErrorWidget` yang tenang.
/// 3. **Menyimpan** 50 galat terakhir di memori, supaya bisa ditampilkan di
///    layar diagnostik admin tanpa perlu Crashlytics.
///
/// Yang **tidak** dilakukan: mengirim ke server. Itu butuh Crashlytics atau
/// backend, dan sengaja dipisah supaya berkas ini tidak menambah dependensi.
class PenangkapGalat {
  PenangkapGalat._();

  /// Catatan galat terakhir. Dibatasi 50 supaya tidak tumbuh terus.
  static final List<CatatanGalat> _catatan = <CatatanGalat>[];

  static List<CatatanGalat> get catatan => List.unmodifiable(_catatan);

  /// Dipasang sekali di `main()` sebelum `runApp`.
  static void pasang() {
    // Galat yang terjadi di dalam framework Flutter (build, layout, paint).
    final asli = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      _simpan(
        pesan: details.exceptionAsString(),
        jejak: details.stack?.toString() ?? '',
        konteks: details.context?.toDescription() ?? 'Flutter framework',
      );
      // Di mode debug, biarkan seperti biasa supaya tetap terlihat saat
      // pengembangan. Di mode rilis, jangan sampai kotak merah muncul di
      // layar pengguna.
      if (kDebugMode) {
        asli?.call(details);
      }
    };

    // Galat async yang tidak tertangkap (Future tanpa catchError, dsb).
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _simpan(
        pesan: error.toString(),
        jejak: stack.toString(),
        konteks: 'Async tidak tertangkap',
      );
      return true; // sudah ditangani, jangan hentikan aplikasi
    };
  }

  /// Membungkus badan `runApp` supaya galat di zona akar ikut tercatat.
  static void jalankan(void Function() badan) {
    runZonedGuarded(
      badan,
      (Object error, StackTrace stack) {
        _simpan(
          pesan: error.toString(),
          jejak: stack.toString(),
          konteks: 'Zona akar',
        );
      },
    );
  }

  static void _simpan({
    required String pesan,
    required String jejak,
    required String konteks,
  }) {
    if (kDebugMode) {
      debugPrint('[GALAT] $konteks :: $pesan');
    }
    _catatan.add(
      CatatanGalat(
        pesan: pesan,
        jejak: jejak,
        konteks: konteks,
        waktu: DateTime.now(),
      ),
    );
    if (_catatan.length > 50) _catatan.removeAt(0);
  }

  /// Membersihkan catatan (dipakai layar diagnostik).
  static void bersihkan() => _catatan.clear();
}

class CatatanGalat {
  const CatatanGalat({
    required this.pesan,
    required this.jejak,
    required this.konteks,
    required this.waktu,
  });

  final String pesan;
  final String jejak;
  final String konteks;
  final DateTime waktu;
}

/// Pengganti kotak merah bawaan Flutter.
///
/// Di mode rilis, `ErrorWidget.builder` bawaan menampilkan kotak abu-abu dengan
/// teks kecil yang tidak berguna bagi pengguna. Widget ini menampilkan pesan
/// yang bisa dipahami dan tidak menakutkan, tanpa membocorkan detail teknis.
class GalatWidget extends StatelessWidget {
  const GalatWidget({super.key, this.pesan});

  final String? pesan;

  @override
  Widget build(BuildContext context) {
    // Di mode debug tetap tampilkan detail: itu yang dibutuhkan saat
    // pengembangan, dan menyembunyikannya justru memperlambat perbaikan.
    if (kDebugMode) {
      return ErrorWidget(pesan ?? 'Terjadi kesalahan');
    }
    return const Material(
      color: Color(0xFF08080C),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: Color(0xFF8C8C9A), size: 36),
              SizedBox(height: 12),
              Text(
                'Bagian ini gagal dimuat.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFF4F4F6),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Coba buka ulang halaman ini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8C8C9A), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
