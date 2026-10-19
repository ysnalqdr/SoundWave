// Test penjaga kabel: rantai push notification FCM
// Push FCM tidak bisa diuji lewat flutter test, karena butuh HP dan APK.
// Yang dikunci adalah rantai sambungannya, dan persis itulah yang dulu
// putus: NotificationService sudah lengkap tapi tidak pernah
// dipanggil, sehingga tidak ada HP yang punya token.
//
// Test ini membaca source code dan memastikan setiap sambungan masih ada.
// Kalau ada yang menghapus satu sambungan, test GAGAL — bukan diam-diam
// jadi dead code lagi.
//
// Bonus: membandingkan channel ID Android antara app (Dart) dan backend
// (JS). Kalau salah satu berubah sendirian, notifikasi push akan jatuh ke
// channel bawaan Android (tanpa prioritas tinggi) tanpa error apa pun —
// jenis bug yang tidak kelihatan sampai ada yang sadar HP-nya tidak bergetar.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const String channelId = 'soundwave_updates';

  group('Rantai kabel FCM tersambung', () {
    late String mainDart;
    late String gateway;
    late String service;
    late String authService;

    setUpAll(() {
      mainDart = File('lib/main.dart').readAsStringSync();
      gateway = File('lib/widgets/fcm_gateway.dart').readAsStringSync();
      service = File('lib/services/notification_service.dart').readAsStringSync();
      authService = File('lib/services/auth_service.dart').readAsStringSync();
    });

    test('1. main.dart menyiapkan notifikasi saat startup', () {
      expect(mainDart, contains('NotificationService().init()'),
          reason: 'kanal + izin notifikasi harus disiapkan sebelum runApp');
    });

    test('2. main.dart membungkus app dengan FcmGateway', () {
      expect(mainDart, contains('FcmGateway('),
          reason: 'tanpa ini, token FCM tidak pernah diambil');
    });

    test('3. gateway memanggil initFcmForUser saat user login', () {
      expect(gateway, contains('initFcmForUser(uid)'),
          reason: 'titik colok utama: login -> simpan token ke users/{uid}');
    });

    test('4. gateway memasang aksi saat push ditekan', () {
      expect(gateway, contains('onTapNotifikasi = _bukaMenuUtama'));
    });

    test('4b. tap push kembali ke halaman utama, tidak menumpuk halaman', () {
      expect(gateway, contains('popUntil'),
          reason: 'kembali ke halaman utama, bukan push halaman baru');
      expect(gateway.contains('UserTiketScreen'), isFalse,
          reason: 'tap push tidak boleh lagi melempar ke Tiket Saya');
      expect(gateway, contains('permintaanMenuUtamaProvider'),
          reason: 'sinyal pindah menu utama harus dikirim ke halaman utama');
    });

    test('4c. user -> Jelajah, admin -> Konser (sesuai akun yang login)', () {
      final String userMain =
          File('lib/screens/user/user_main_screen.dart').readAsStringSync();
      final String adminDash =
          File('lib/screens/admin/admin_dashboard.dart').readAsStringSync();

      expect(userMain, contains('permintaanMenuUtamaProvider'),
          reason: 'halaman utama user harus mendengarkan sinyal');
      expect(userMain, contains('_pindahKeTab(0)'),
          reason: 'user harus mendarat di tab Jelajah (index 0)');

      expect(adminDash, contains('permintaanMenuUtamaProvider'),
          reason: 'dashboard admin harus mendengarkan sinyal');
      expect(adminDash, contains('_halamanAktif = 0'),
          reason: 'admin harus mendarat di menu Konser (index 0)');
    });

    test('5. logout melepas token push', () {
      expect(authService, contains('lepasToken('),
          reason: 'HP dipakai bergantian akun tidak boleh terima push akun lama');
    });

    test('6. kanal Android dibuat & memakai channelId bersama', () {
      expect(service, contains('createNotificationChannel'));
      expect(service, contains("channelId = '$channelId'"));
    });

    test('7. service menyediakan lepasToken + listener tap', () {
      expect(service, contains('Future<void> lepasToken(String userId)'));
      expect(service, contains('onMessageOpenedApp'));
    });

    test('8. channelId app SAMA dengan CHANNEL_ANDROID di backend', () {
      final File backend = File('../soundwave-backend/notifikasi.js');
      if (!backend.existsSync()) {
        markTestSkipped('folder backend tidak ada di mesin ini');
        return;
      }
      final String js = backend.readAsStringSync();
      expect(js, contains("CHANNEL_ANDROID = '$channelId'"),
          reason: 'channelId di notifikasi.js harus sama dengan Dart');
      expect(js, contains('channelId: CHANNEL_ANDROID'),
          reason: 'payload push backend harus menyebut channelId tsb');
    });

    test('9. backend mengirim push dari jalur yang sama dengan inbox', () {
      final File backend = File('../soundwave-backend/notifikasi.js');
      if (!backend.existsSync()) {
        markTestSkipped('folder backend tidak ada di mesin ini');
        return;
      }
      final String js = backend.readAsStringSync();
      expect(js, contains('async function kirimNotifikasi'),
          reason: 'satu jalur untuk notifikasi otomatis & pengumuman manual');
      expect(js, contains('async function kirimPush'));
      expect(js, contains('messaging.send('));
    });
  });
}
