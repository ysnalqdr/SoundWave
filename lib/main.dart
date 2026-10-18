import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'constants/app_constants.dart';
import 'services/notification_service.dart';
import 'widgets/fcm_gateway.dart';

/// Dipakai untuk membuka halaman dari notifikasi push (app di background).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Siapkan kanal notifikasi + izin (Android 13+). DIBUNGKUS try/catch:
  // kegagalan notifikasi tidak boleh menggagalkan startup app.
  try {
    await NotificationService().init();
  } catch (_) {
    // lanjut tanpa notifikasi
  }

  await initializeDateFormatting('id_ID', null);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: SoundWaveApp(),
    ),
  );
}

class SoundWaveApp extends StatelessWidget {
  const SoundWaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    // FcmGateway membungkus app untuk mencolokkan push notification ke siklus
    // hidup login: saat login -> ambil & simpan token FCM ke users/{uid}.
    return FcmGateway(
      navigatorKey: navigatorKey,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/',
        routes: {
          // All entry points go through SplashScreen which handles auth check
          // and role-based routing. This prevents direct URL bypass.
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/user': (_) => const SplashScreen(),
          '/admin': (_) => const SplashScreen(),
        },
      ),
    );
  }
}

