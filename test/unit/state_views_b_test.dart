import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Penjaga dua perbaikan tampilan keadaan.
///
/// Keduanya dipilih dengan alasan yang berbeda, dan alasan itu mudah hilang
/// saat kode dirapikan orang lain:
///
/// - **Skeleton** untuk pemuatan < 1 detik. Menempati ruang yang sama dengan
///   konten asli, jadi tata letak tidak melompat.
/// - **Lottie overlay** untuk operasi 2–8 detik yang menyentuh uang. Layar
///   harus terkunci, dan pengguna butuh tahu bahwa sesuatu sedang terjadi.
void main() {
  /// Membuang baris komentar, supaya pemeriksaan hanya melihat kode.
  ///
  /// Tanpa ini, dokumentasi yang menyebut "Lottie" atau "Shimmer.fromColors"
  /// ikut terhitung dan tes gagal padahal kodenya benar.
  String kodeSaja(String sumber) => sumber
      .split('\n')
      .where((l) {
        final t = l.trimLeft();
        return !t.startsWith('//') && !t.startsWith('*') && !t.startsWith('/*');
      })
      .join('\n');

  final skeleton =
      File('lib/widgets/feedback/skeleton.dart').readAsStringSync();
  final skeletonKode = kodeSaja(skeleton);
  final overlay = File('lib/widgets/feedback/payment_loading_overlay.dart')
      .readAsStringSync();
  final detail =
      File('lib/screens/user/user_konser_detail_screen.dart').readAsStringSync();
  final checkout =
      File('lib/screens/user/checkout_screen.dart').readAsStringSync();
  final pubspec = File('pubspec.yaml').readAsStringSync();

  group('Skeleton', () {
    test('memakai shimmer, bukan paket baru', () {
      expect(pubspec.contains('shimmer:'), isTrue);
      expect(skeletonKode.contains('Shimmer.fromColors'), isTrue);
    });

    test('satu shimmer membungkus seluruh kelompok', () {
      // Kalau setiap kotak punya shimmer sendiri, kilaunya berkedip acak.
      expect(skeletonKode.contains('class SkeletonGroup'), isTrue);
      final jumlahShimmer =
          'Shimmer.fromColors'.allMatches(skeletonKode).length;
      expect(jumlahShimmer, 1,
          reason: 'cukup satu shimmer untuk seluruh kelompok');
    });

    test('tidak memakai animasi Lottie', () {
      expect(skeletonKode.contains('Lottie'), isFalse,
          reason: 'skeleton harus menempati ruang yang sama dengan konten; '
              'Lottie butuh ruang sendiri dan mendorong konten turun');
    });

    test('skeleton tiket meniru bentuk kartu tiket', () {
      expect(skeletonKode.contains('class SkeletonTicketList'), isTrue);
      // Ada blok judul, keterangan, dan tombol di kanan.
      expect(
          skeletonKode.contains('SkeletonBox(width: 120, height: 16)'), isTrue);
      expect(skeletonKode.contains('SkeletonBox(width: 88, height: 34'),
          isTrue);
    });
  });

  group('Overlay pembayaran', () {
    test('memakai Lottie kucing sebagai indikator', () {
      // DIUBAH Okt 2026: pemilik produk menilai spinner 26px terlalu kecil
      // dan tanpa penanda kemajuan, sehingga menunggu terasa "sekilas".
      // Kucing Lottie dikembalikan dengan durasi putaran 3 detik.
      final overlayKode = kodeSaja(overlay);
      expect(overlayKode.contains('Lottie'), isTrue);
      expect(overlayKode.contains('LottieAssets.loading'), isTrue);
      expect(overlayKode.contains('durasiPutaran'), isTrue);
      // Cadangan tetap ada bila aset gagal dimuat.
      expect(overlayKode.contains('CircularProgressIndicator'), isTrue);
    });

    test('overlay dibungkus Material supaya teks tidak bergaris kuning', () {
      // Overlay adalah anak `Stack`, bukan anak Scaffold — tanpa Material,
      // Flutter menggambar teks dengan garis bawah kuning ganda.
      final overlayKode = kodeSaja(overlay);
      expect(overlayKode.contains('Material('), isTrue,
          reason: 'tanpa Material, teks tampil dengan garis kuning debug');
    });

    test('tabir lebih ringan dari versi pertama', () {
      final overlayKode = kodeSaja(overlay);
      expect(overlayKode.contains('alpha: 0.6'), isTrue,
          reason: 'tabir 0,94 membuat layar terasa mati');
    });

    test('mengunci seluruh sentuhan', () {
      expect(overlay.contains('AbsorbPointer'), isTrue);
      expect(overlay.contains('absorbing: true'), isTrue,
          reason: 'pengguna tidak boleh menekan tombol di belakang overlay '
              'selama pembayaran diproses');
    });

    test('menutup seluruh layar', () {
      expect(overlay.contains('Positioned.fill'), isTrue);
    });

    test('memberi tahu pengguna untuk tidak menutup aplikasi', () {
      expect(overlay.contains('Jangan tutup aplikasi'), isTrue);
    });

    test('tidak menempati ruang saat tidak aktif', () {
      // Sejak overlay menjadi StatefulWidget (butuh AnimationController),
      // properti diakses lewat `widget.`.
      expect(overlay.contains('if (!widget.visible) return const SizedBox.shrink()'),
          isTrue);
    });
  });

  group('Pemasangan', () {
    test('detail konser memakai skeleton, bukan spinner', () {
      final idx = detail.indexOf('ticketsAsync.when(');
      final blok = detail.substring(idx, idx + 500);
      expect(blok.contains('SkeletonTicketList'), isTrue);
      expect(blok.contains('CircularProgressIndicator'), isFalse,
          reason: 'spinner polos tidak memesan ruang, tata letak melompat');
    });

    test('checkout memasang overlay di atas Scaffold', () {
      expect(checkout.contains('PaymentLoadingOverlay(visible: _loading)'),
          isTrue);
      // Overlay harus berada di dalam Stack supaya bisa menutup seluruh layar.
      expect(checkout.contains('return Stack('), isTrue);
    });
  });

  group('Teks tidak bergaris kuning (butuh leluhur Material)', () {
    test('overlay pembayaran dibungkus Material', () {
      final kode = File('lib/widgets/feedback/payment_loading_overlay.dart')
          .readAsStringSync();
      expect(kode.contains('Material('), isTrue,
          reason: 'overlay adalah anak Stack, bukan anak Scaffold — tanpa '
              'Material, teks tampil bergaris kuning ganda.');
    });

    test('overlay gate scanner dibungkus Material', () {
      // Layar ini dibuka lewat PageRouteBuilder dan tidak punya Scaffold,
      // jadi Material wajib ada. Tanpa itu SEMUA teks di layar verifikasi
      // tiket tampil bergaris kuning.
      final kode = File('lib/widgets/gate/scan_success_overlay.dart')
          .readAsStringSync();
      expect(kode.contains('Material('), isTrue,
          reason: 'tanpa Material, "Tiket terverifikasi", nama konser, dan '
              'kode booking tampil bergaris kuning.');
    });
  });
}
