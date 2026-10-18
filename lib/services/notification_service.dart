import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../constants/app_constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  bool _initialized = false;
  int _nextId = 1000;

  /// ID channel Android untuk push FCM saat app ditutup.
  /// HARUS sama dengan `android.notification.channelId` yang dikirim backend
  /// (soundwave-backend/notifikasi.js -> CHANNEL_ANDROID).
  static const String channelId = 'soundwave_updates';

  /// Diisi oleh FcmGateway (main.dart): dipanggil saat user menekan
  /// notifikasi push ketika app sedang berjalan di background.
  void Function(RemoteMessage message)? onTapNotifikasi;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      // Fall back to UTC if timezone data is unavailable.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Channel ini dipakai DUA hal: banner saat app terbuka
    // (showInstantNotification) dan push FCM dari backend saat app ditutup.
    // Kalau channel belum ada, Android memakai channel bawaan (tanpa
    // prioritas tinggi / getar), jadi wajib dibuat lebih dulu.
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    try {
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          'Pembaruan Tiket & Pembayaran',
          description:
              'Status tiket, pembayaran, refund, dan pengumuman SoundWave',
          importance: Importance.high,
        ),
      );
    } catch (_) {
      // channel gagal dibuat: notifikasi lokal tetap dicoba, tidak fatal
    }

    try {
      await androidPlugin?.requestNotificationsPermission();
    } catch (_) {
      // izin ditolak / belum bisa diminta: tidak boleh menggagalkan app
    }

    _initialized = true;
  }

  /// Registers device FCM token and syncs to user document in Firestore.
  /// Sets up foreground notification listeners.
  Future<void> initFcmForUser(String userId) async {
    await init();

    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await _fcm.getToken();
        if (token != null) {
          await _saveFcmTokenToUser(userId, token);
        }

        // Listen for token updates (e.g. app re-install or rotation)
        _fcm.onTokenRefresh.listen((newToken) {
          _saveFcmTokenToUser(userId, newToken);
        });

        // Handle foreground notifications
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          if (notification != null) {
            showInstantNotification(
              title: notification.title ?? 'SoundWave',
              body: notification.body ?? '',
            );
          }
        });

        // Push ditekan saat app ada di background -> FcmGateway mengarahkan
        // ke halaman Tiket Saya (lihat lib/widgets/fcm_gateway.dart).
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          onTapNotifikasi?.call(message);
        });
      }
    } catch (_) {
      // Graceful fallback: FCM failure must not break app core execution
    }
  }

  Future<void> _saveFcmTokenToUser(String userId, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // User doc might not exist yet during initial registration
    }
  }

  /// Displays an instant high-priority local banner
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      channelId,
      'Pembaruan Tiket & Pembayaran',
      channelDescription: 'Notifikasi status tiket, pembayaran, dan konser',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    await _plugin.show(
      _nextId++,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// Schedules a local reminder at [when] (device-local / Asia/Jakarta).
  Future<void> scheduleEventReminder(
    DateTime when,
    String title,
    String body,
  ) async {
    await init();

    if (when.isBefore(DateTime.now())) return;

    final scheduled = tz.TZDateTime.from(when, tz.local);
    final id = _nextId++;

    const androidDetails = AndroidNotificationDetails(
      'soundwave_reminders',
      'Pengingat Konser',
      channelDescription: 'Notifikasi pengingat jadwal konser SoundWave',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Lepas token push device ini. Dipanggil saat LOGOUT — sengaja dari
  /// AuthService.logout() selagi user masih punya izin tulis ke dokumennya
  /// (rules butuh userId == request.auth.uid).
  ///
  /// Tanpa ini, HP yang dipakai bergantian akun masih bisa menerima push
  /// milik akun sebelumnya. Kalau pun gagal, backend membersihkannya
  /// otomatis begitu FCM menolak token (lihat notifikasi.js).
  Future<void> lepasToken(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .update({'fcmToken': null});
    } catch (_) {
      // non-fatal
    }
    try {
      await _fcm.deleteToken();
    } catch (_) {
      // non-fatal
    }
  }
}
