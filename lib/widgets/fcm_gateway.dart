import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../services/notification_service.dart';

/// Menyambungkan push notification ke siklus hidup login.
///
/// NotificationService sudah lengkap sejak awal, tapi tidak pernah dipanggil,
/// jadi tidak ada HP yang punya token dan push mustahil dikirim. Widget ini
/// yang mencolokkannya: login memanggil initFcmForUser, logout melepas token.
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

  /// Notifikasi push ditekan saat app di background: kembali ke menu utama
  /// akun yang sedang login tanpa menumpuk halaman baru. User mendarat di tab
  /// Jelajah, admin di dashboard. Tujuan ditentukan halaman utama yang sedang
  /// terpasang, jadi tidak mungkin salah akun.
  void _bukaMenuUtama(RemoteMessage message) {
    final NavigatorState? navigator = widget.navigatorKey.currentState;
    if (navigator == null) return;
    // Balik ke halaman utama — bukan push halaman baru di atasnya.
    navigator.popUntil((route) => route.isFirst);
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
