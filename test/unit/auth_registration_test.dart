import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:soundwave/services/auth_service.dart';
import 'package:soundwave/models/user_model.dart';
import 'package:soundwave/constants/app_constants.dart';

void main() {
  group('AuthService Registration & Error Mapping Regression Tests', () {
    test('maps configuration-not-found to informative console activation message', () {
      final exc = FirebaseAuthException(
        code: 'configuration-not-found',
        message: 'Error',
      );
      final mapped = AuthService.mapAuthError(exc);
      expect(mapped, equals('Metode email/password belum diaktifkan di Firebase Console'));
      expect(mapped, isNot(equals('Error')));
    });

    test('maps operation-not-allowed to provider activation message', () {
      final exc = FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'The given sign-in provider is disabled for this Firebase project.',
      );
      final mapped = AuthService.mapAuthError(exc);
      expect(mapped, equals('Metode email/password belum diaktifkan di Firebase Console'));
    });

    test('maps email-already-in-use to friendly duplicate email message', () {
      final exc = FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'The email address is already in use by another account.',
      );
      final mapped = AuthService.mapAuthError(exc);
      expect(mapped, equals('Email sudah terdaftar'));
    });

    test('maps invalid-email to format error message', () {
      final exc = FirebaseAuthException(
        code: 'invalid-email',
        message: 'The email address is badly formatted.',
      );
      final mapped = AuthService.mapAuthError(exc);
      expect(mapped, equals('Format email tidak valid'));
    });

    test('maps weak-password to minimum length guidance', () {
      final exc = FirebaseAuthException(
        code: 'weak-password',
        message: 'Password should be at least 6 characters',
      );
      final mapped = AuthService.mapAuthError(exc);
      expect(mapped, equals('Password terlalu lemah (min. 6 karakter)'));
    });

    test('maps network-request-failed to connectivity message', () {
      final exc = FirebaseAuthException(
        code: 'network-request-failed',
        message: 'A network error occurred.',
      );
      final mapped = AuthService.mapAuthError(exc);
      expect(mapped, equals('Koneksi ke server gagal'));
    });

    test('maps permission-denied in FirebaseAuthException to rules error message', () {
      final exc = FirebaseAuthException(
        code: 'permission-denied',
        message: 'Missing or insufficient permissions.',
      );
      final mapped = AuthService.mapAuthError(exc);
      expect(mapped, equals('Pembuatan profil pengguna ditolak oleh Firestore Rules'));
    });

    test('maps invalid credentials and user-not-found cleanly', () {
      for (final code in ['user-not-found', 'wrong-password', 'invalid-credential']) {
        final exc = FirebaseAuthException(code: code);
        expect(AuthService.mapAuthError(exc), equals('Email atau password salah'));
      }
    });

    test('maps too-many-requests cleanly', () {
      final exc = FirebaseAuthException(code: 'too-many-requests');
      expect(AuthService.mapAuthError(exc), equals('Terlalu banyak percobaan. Coba lagi nanti'));
    });

    test('maps user-disabled cleanly', () {
      final exc = FirebaseAuthException(code: 'user-disabled');
      expect(AuthService.mapAuthError(exc), equals('Akun pengguna telah dinonaktifkan'));
    });

    test('maps unknown auth code without displaying raw "Error"', () {
      final exc1 = FirebaseAuthException(code: 'unknown-code', message: 'Error');
      expect(AuthService.mapAuthError(exc1), equals('Terjadi kesalahan autentikasi [unknown-code]'));

      final exc2 = FirebaseAuthException(code: 'custom-error', message: 'Specific detail');
      expect(
        AuthService.mapAuthError(exc2),
        equals('Terjadi kesalahan autentikasi [custom-error]: Specific detail'),
      );
    });

    test('maps Firestore permission-denied to clear security rules message', () {
      final exc = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Missing or insufficient permissions.',
      );
      final mapped = AuthService.mapFirestoreError(exc);
      expect(mapped, equals('Pembuatan profil pengguna ditolak oleh Firestore Rules'));
      expect(mapped, isNot(contains('Error')));
    });

    test('maps Firestore unavailable to connectivity message', () {
      final exc = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'Service unavailable',
      );
      final mapped = AuthService.mapFirestoreError(exc);
      expect(mapped, equals('Koneksi ke server gagal'));
    });

    test('maps unknown Firestore error code safely', () {
      final exc = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'resource-exhausted',
        message: 'Quota exceeded',
      );
      final mapped = AuthService.mapFirestoreError(exc);
      expect(mapped, equals('Kesalahan database [resource-exhausted]: Quota exceeded'));
    });
  });

  group('Registration Security & Role Creation Rules', () {
    test('public registration payload always mandates buyer role ("user")', () {
      final registeredUser = UserModel(
        id: 'new_uid_123',
        nama: 'muhmmad',
        email: 'muhmmad@gmail.com',
        role: AppConstants.roleUser,
      );

      final map = registeredUser.toMap();
      expect(map['role'], equals('user'));
      expect(map['role'], isNot(equals('admin')));
      expect(map['role'], isNot(equals('super_admin')));
      expect(map['email'], equals('muhmmad@gmail.com'));
      expect(map['nama'], equals('muhmmad'));
      expect(registeredUser.isAdmin, isFalse);
      expect(registeredUser.isSuperAdmin, isFalse);
    });
  });
}
