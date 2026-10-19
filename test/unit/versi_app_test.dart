// Versi aplikasi tidak boleh melenceng
// Footer admin sempat menulis "SoundWave V2.3 (Secure)" padahal APK-nya
// 2.4.6 — angka versi dipatok manual sementara pubspec naik terus. Test ini
// membaca pubspec.yaml dan memastikan keduanya sama, jadi lupa menaikkan
// salah satunya langsung ketahuan.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/constants/app_constants.dart';

void main() {
  test('AppConstants.appVersion sama dengan version di pubspec.yaml', () {
    final isi = File('pubspec.yaml').readAsStringSync();
    final barisVersi = isi
        .split(RegExp(r'\r?\n'))
        .firstWhere((b) => b.startsWith('version:'));
    final versiPubspec = barisVersi.split(':')[1].trim().split('+').first;

    expect(AppConstants.appVersion, versiPubspec);
  });
}
