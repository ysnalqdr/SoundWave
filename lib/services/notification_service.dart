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

  // ID channel Android untuk push saat app ditutup. Harus sama dengan
  // channelId yang dikirim backend (notifikasi.js -> CHANNEL_ANDROID).
  static const String channelId = 'soundwave_updates';

  // Diisi FcmGateway saat user menekan notifikasi push ketika app berjalan
  // di background.
  void Function(RemoteMessage message)? onTapNotifikasi;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      // Pakai UTC kalau data zona waktu tidak tersedia.
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

    // Channel ini dipakai dua hal: banner saat app terbuka dan push dari
    // backend saat app ditutup. Tanpa channel, Android memakai channel
    // bawaan tanpa prioritas tinggi dan tanpa getar.
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
      // Channel gagal dibuat: notifikasi lokal tetap dicoba, tidak fatal.
    }

    try {
      await androidPlugin?.requestNotificationsPermission();
    } catch (_) {
      // Izin ditolak: tidak boleh menggagalkan app.
    }

    _initialized = true;
  }

  /// Registers the device FCM token, syncs it to the user document, and
  /// sets up foreground listeners.
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

        // Token bisa berubah setelah reinstall.
        _fcm.onTokenRefresh.listen((newToken) {
          _saveFcmTokenToUser(userId, newToken);
        });

        // Notifikasi yang masuk saat app terbuka.
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
      // FCM gagal tidak boleh menghentikan app.
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
      // Dokumen user mungkin belum ada saat pendaftaran awal.
    }
  }

  /// Shows an instant high-priority local banner.
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

  // Lepas token push device ini saat logout, selagi user masih punya izin
  // tulis ke dokumennya (rules butuh userId == request.auth.uid).
  //
  // Tanpa ini, HP yang dipakai bergantian akun masih menerima push milik
  // akun sebelumnya. Kalau gagal, backend membersihkannya begitu FCM
  // menolak token.
  Future<void> lepasToken(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .update({'fcmToken': null});
    } catch (_) {
      // Non-fatal.
    }
    try {
      await _fcm.deleteToken();
    } catch (_) {
      // Non-fatal.
    }
  }
}
