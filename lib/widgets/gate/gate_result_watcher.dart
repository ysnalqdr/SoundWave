import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/pesanan_tiket_model.dart';
import '../../providers/app_providers.dart';
import 'scan_success_overlay.dart';

/// Memantau tiket milik user dan menampilkan [ScanSuccessOverlay] tepat saat
/// salah satunya berubah jadi TERPAKAI.
///
/// Kenapa di level menu utama, bukan di dalam layar tiket: pembeli bisa sedang
/// membuka tab lain, membaca detail konser, atau melihat halaman pembayaran
/// ketika petugas memindai. Kalau pengawas hanya hidup di layar tiket, momennya
/// hilang — dan pembeli tidak pernah tahu tiketnya sudah dipakai.
///
/// Kenapa **hanya untuk perubahan yang benar-benar baru**: saat pengawas
/// pertama menyala, semua tiket yang sudah terpakai dicatat diam-diam sebagai
/// "sudah dilihat". Tanpa ini, membuka aplikasi akan memicu animasi untuk
/// tiket lama — perayaan yang terlambat 40 menit terasa salah alamat, bukan
/// kabar baik.
///
/// **Mode offline sengaja tidak memicu animasi.** Scan offline hanya ditulis ke
/// ledger HP petugas; Firestore baru berubah setelah perangkat gate kembali
/// online dan menyinkronkan, yang bisa berjam-jam kemudian. Animasi yang muncul
/// saat itu akan menutupi layar pembeli dengan perayaan untuk kejadian yang
/// sudah lewat. Untuk kasus itu cukup badge "SUDAH DIGUNAKAN" yang sudah ada
/// di layar tiket.
///
/// Widget ini tidak menggambar apa pun. Ia menumpang di pohon widget
/// [UserMainScreen] supaya ikut hidup selama menu utama user terpasang, dan
/// memakai Navigator terdekat untuk menumpuk lapisan animasi.
class GateResultWatcher extends ConsumerStatefulWidget {
  /// Dipanggil setelah animasi selesai, untuk memindahkan user ke tab Tiket.
  final VoidCallback onSelesai;

  const GateResultWatcher({super.key, required this.onSelesai});

  @override
  ConsumerState<GateResultWatcher> createState() => _GateResultWatcherState();
}

class _GateResultWatcherState extends ConsumerState<GateResultWatcher> {
  /// ID tiket yang sudah terpakai saat pengawas pertama menyala, ditambah yang
  /// baru saja dipicu. Tidak pernah memicu animasi dua kali.
  Set<String>? _sudahDilihat;

  /// Menahan overlay ganda bila dua perubahan masuk hampir bersamaan.
  bool _sedangTampil = false;

  @override
  Widget build(BuildContext context) {
    // Hanya bertindak bila menu utama user benar-benar yang teratas di layar.
    //
    // Dua hal yang dicegah: (1) animasi menutupi halaman yang sedang dibaca
    // user (detail konser, pembayaran), dan (2) admin yang juga punya tiket
    // sendiri — HP-nya bisa membuka menu user lalu pindah ke gate scanner;
    // tanpa penjaga ini animasinya akan menutupi scanner yang sedang dipakai
    // bertugas.
    //
    // Tiket yang berubah saat menu utama bukan teratas sengaja TIDAK ditandai
    // "sudah dilihat", jadi animasinya menyala begitu user kembali ke menu
    // utama. Kalau ia tidak pernah kembali, status di layar tiket tetap
    // menunjukkan "SUDAH DIGUNAKAN" — tidak ada informasi yang hilang.
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) {
      return const SizedBox.shrink();
    }

    final String? uid = ref.watch(authStateProvider).valueOrNull?.uid;
    if (uid == null) {
      _sudahDilihat = null;
      return const SizedBox.shrink();
    }

    final AsyncValue<List<PesananTiketModel>> pesanan =
        ref.watch(userOrdersProvider(uid));

    // Tunggu data pertama. Jangan menyemai dari daftar kosong: kalau disemai
    // terlalu awal, tiket yang sebenarnya sudah terpakai akan dianggap baru
    // begitu data asli tiba, dan animasi muncul untuk tiket lama.
    if (!pesanan.hasValue) return const SizedBox.shrink();

    final List<PesananTiketModel> daftar = pesanan.requireValue;

    if (_sudahDilihat == null) {
      _sudahDilihat = <String>{
        for (final p in daftar)
          if (p.isTerpakai) p.id,
      };
      return const SizedBox.shrink();
    }

    if (!_sedangTampil) {
      PesananTiketModel? baru;
      for (final p in daftar) {
        if (p.isTerpakai && !_sudahDilihat!.contains(p.id)) {
          baru = p;
          break;
        }
      }

      if (baru != null) {
        _sudahDilihat!.add(baru.id);
        final PesananTiketModel tiketBaru = baru;
        // Ditunda ke frame berikutnya: efek samping tidak boleh dijalankan
        // saat build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tampilkan(tiketBaru);
        });
      } else {
        // Tiket yang kembali AKTIF (mis. refund disetujui lalu tiket
        // diaktifkan lagi) harus bisa memicu animasi bila discan ulang.
        for (final p in daftar) {
          if (!p.isTerpakai) _sudahDilihat!.remove(p.id);
        }
      }
    }

    return const SizedBox.shrink();
  }

  Future<void> _tampilkan(PesananTiketModel tiket) async {
    if (!mounted || _sedangTampil) return;

    final NavigatorState? navigator = Navigator.maybeOf(context);
    if (navigator == null) return;

    _sedangTampil = true;

    final Completer<void> selesai = Completer<void>();

    final Route<void> rute = PageRouteBuilder<void>(
      opaque: true,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => ScanSuccessOverlay(
        judulKonser: tiket.judulKonser,
        kodeBooking: tiket.kodeBooking,
        onSelesai: () {
          if (!selesai.isCompleted) selesai.complete();
        },
      ),
      transitionsBuilder: (_, animasi, __, anak) =>
          FadeTransition(opacity: animasi, child: anak),
    );

    unawaited(navigator.push(rute));

    // Jaring pengaman: kalau karena alasan apa pun overlay tidak pernah
    // melapor selesai (mis. rute ditutup paksa oleh logout), jangan biarkan
    // pengawas macet selamanya. Batas atas = durasi aset + jeda baca + margin.
    try {
      await selesai.future.timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // Lanjut saja: rute ditutup di bawah.
    }

    if (!mounted) return;

    // Tutup lapisan animasi, lalu mendaratkan pembeli di Tiket Saya — tempat
    // statusnya sudah berubah jadi "SUDAH DIGUNAKAN". Tampilannya sama seperti
    // biasa, hanya isinya yang sudah diperbarui.
    if (navigator.canPop()) navigator.pop();

    // Bila pembeli sedang berada di halaman lain (detail konser, pembayaran),
    // kembalikan dulu ke menu utama supaya tab Tiket benar-benar terlihat.
    navigator.popUntil((route) => route.isFirst);

    widget.onSelesai();

    // Beri jeda agar perpindahan tab tidak terlihat berkedip di belakang
    // animasi fade-out.
    await Future<void>.delayed(const Duration(milliseconds: 280));
    _sedangTampil = false;
  }
}
