import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../services/notification_service.dart';

/// Menyambungkan PUSH NOTIFICATION (FCM) ke siklus hidup login.
///
/// Kenapa widget ini perlu ada: `NotificationService` sebenarnya sudah lengkap
/// sejak awal (minta izin, ambil token, simpan ke `users/{uid}.fcmToken`),
/// TAPI tidak pernah dipanggil dari mana pun — jadi tidak ada satu HP pun yang
/// punya token, dan push mustahil dikirim. Widget ini yang mencolokkannya:
///
///   login  -> initFcmForUser(uid) : ambil token + pasang listener
///   logout -> AuthService.logout() : lepas token (ada di notification_service)
///
/// Semua kegagalan NON-FATAL: push tidak boleh mengganggu alur utama app.
class FcmGateway extends ConsumerStatefulWidget {
  const FcmGateway({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  ConsumerState<FcmGateway> createState() => _FcmGatewayState();
}

class _FcmGatewayState extends ConsumerState<FcmGateway> {
  String? _uidTerpasang;

  @override
  void initState() {
    super.initState();
    // Aksi ketika user menekan notifikasi push dari HP.
    NotificationService().onTapNotifikasi = _bukaMenuUtama;
  }

  @override
  void dispose() {
    NotificationService().onTapNotifikasi = null;
    super.dispose();
  }

  /// Notifikasi push ditekan saat app ada di background -> kembali ke MENU
  /// UTAMA akun yang sedang login, TANPA menumpuk halaman baru:
  ///   · user  -> halaman utama user, tab Jelajah
  ///   · admin -> dashboard admin, menu Konser
  ///
  /// Yang menentukan tujuan adalah halaman utama yang SEDANG terpasang (lihat
  /// `permintaanMenuUtamaProvider`), jadi tidak mungkin salah akun: admin
  /// tidak akan pernah dilempar ke halaman user, dan sebaliknya.
  ///
  /// Catatan: kalau app benar-benar TERTUTUP (bukan sekadar background), app
  /// dibuka lewat SplashScreen seperti biasa — SplashScreen yang menentukan
  /// rute berdasarkan peran, jadi di sini tidak perlu dipaksa apa pun.
  void _bukaMenuUtama(RemoteMessage message) {
    final NavigatorState? navigator = widget.navigatorKey.currentState;
    if (navigator == null) return;
    // Balik ke halaman utama — bukan push halaman baru di atasnya.
    navigator.popUntil((route) => route.isFirst);
    // Minta halaman utama pindah ke menu utamanya.
    ref.read(permintaanMenuUtamaProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = ref.watch(authStateProvider).valueOrNull?.uid;

    if (uid != null && uid != _uidTerpasang) {
      _uidTerpasang = uid;
      // Ditunda ke frame berikutnya: efek samping jangan dijalankan saat build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationService().initFcmForUser(uid);
      });
    } else if (uid == null) {
      _uidTerpasang = null;
    }

    return widget.child;
  }
}
