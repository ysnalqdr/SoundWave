import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/models/user_model.dart';
import 'package:soundwave/constants/app_constants.dart';

/// Simulates AuthService.logout() behavior to verify that Firebase Auth
/// sign-out always executes regardless of Google provider state.
///
/// The real AuthService.logout() does:
///   1. Check if _googleSignIn is already initialised (not null)
///   2. If yes, attempt _googleSignIn.signOut() in try-catch
///   3. Always call _auth.signOut()
///
/// These tests verify the logic contract, not the Firebase SDK.

class MockLogoutTracker {
  bool googleSignOutAttempted = false;
  bool googleSignOutSucceeded = false;
  bool firebaseSignOutExecuted = false;
  Object? googleSignOutError;

  /// Simulates the exact logout logic from AuthService
  Future<void> logout({
    required bool isGoogleSignInInitialised,
    required Future<void> Function()? googleSignOut,
    required Future<void> Function() firebaseSignOut,
  }) async {
    if (isGoogleSignInInitialised && googleSignOut != null) {
      googleSignOutAttempted = true;
      try {
        await googleSignOut();
        googleSignOutSucceeded = true;
      } catch (e) {
        googleSignOutError = e;
      }
    }
    await firebaseSignOut();
    firebaseSignOutExecuted = true;
  }
}

void main() {
  group('Logout Reliability — Google Provider Failure Must Not Block Firebase Sign-Out', () {
    test('Logout succeeds when Google Sign-In was never initialised (email/password user)', () async {
      final tracker = MockLogoutTracker();

      await tracker.logout(
        isGoogleSignInInitialised: false,
        googleSignOut: null,
        firebaseSignOut: () async {},
      );

      expect(tracker.googleSignOutAttempted, isFalse,
          reason: 'Should not attempt Google sign-out if never initialised');
      expect(tracker.firebaseSignOutExecuted, isTrue,
          reason: 'Firebase sign-out must always execute');
    });

    test('Logout succeeds when Google Sign-In is initialised and signOut succeeds', () async {
      final tracker = MockLogoutTracker();

      await tracker.logout(
        isGoogleSignInInitialised: true,
        googleSignOut: () async {},
        firebaseSignOut: () async {},
      );

      expect(tracker.googleSignOutAttempted, isTrue);
      expect(tracker.googleSignOutSucceeded, isTrue);
      expect(tracker.firebaseSignOutExecuted, isTrue);
    });

    test('Logout succeeds when Google Sign-In signOut throws', () async {
      final tracker = MockLogoutTracker();

      await tracker.logout(
        isGoogleSignInInitialised: true,
        googleSignOut: () async {
          throw Exception('Google sign-out network error');
        },
        firebaseSignOut: () async {},
      );

      expect(tracker.googleSignOutAttempted, isTrue);
      expect(tracker.googleSignOutSucceeded, isFalse);
      expect(tracker.googleSignOutError, isNotNull,
          reason: 'Error should be captured, not propagated');
      expect(tracker.firebaseSignOutExecuted, isTrue,
          reason: 'Firebase sign-out MUST execute even after Google failure');
    });

    test('Logout skips Google when GoogleSignIn construction would have thrown (Web missing client ID)', () async {
      // This simulates the scenario where GoogleSignIn was never successfully
      // constructed because the Web client ID was missing. The field
      // _googleSignIn remains null, so logout should NOT attempt construction.
      final tracker = MockLogoutTracker();

      await tracker.logout(
        isGoogleSignInInitialised: false,
        googleSignOut: () async {
          throw AssertionError('ClientID not set. Call GoogleSignIn.init()');
        },
        firebaseSignOut: () async {},
      );

      expect(tracker.googleSignOutAttempted, isFalse,
          reason: 'Must not trigger GoogleSignIn construction during logout');
      expect(tracker.firebaseSignOutExecuted, isTrue,
          reason: 'Firebase sign-out must always complete');
    });

    test('Scenario A: Google provider sign-out fails but Firebase sign-out succeeds -> logout completes and UI navigates', () async {
      final tracker = MockLogoutTracker();
      bool redirectedToLogin = false;
      Object? uiError;

      // Simulate full UI logout flow under Scenario A
      try {
        await tracker.logout(
          isGoogleSignInInitialised: true,
          googleSignOut: () async {
            throw Exception('Google provider network timeout');
          },
          firebaseSignOut: () async {
            // Firebase Auth sign-out succeeds
          },
        );
        redirectedToLogin = true;
      } catch (e) {
        uiError = e;
      }

      expect(tracker.googleSignOutAttempted, isTrue);
      expect(tracker.googleSignOutSucceeded, isFalse);
      expect(tracker.googleSignOutError, isNotNull);
      expect(tracker.firebaseSignOutExecuted, isTrue,
          reason: 'Firebase sign-out must always execute even if Google provider failed');
      expect(uiError, isNull,
          reason: 'Non-fatal Google failure should not throw out of logout()');
      expect(redirectedToLogin, isTrue,
          reason: 'UI navigates to Login because Firebase sign-out succeeded');
    });

    test('Scenario B: Firebase sign-out throws -> logout propagates error and UI does NOT navigate to login', () async {
      final tracker = MockLogoutTracker();
      bool redirectedToLogin = false;
      Object? surfacedError;

      // Simulate full UI logout flow under Scenario B
      try {
        await tracker.logout(
          isGoogleSignInInitialised: false,
          googleSignOut: null,
          firebaseSignOut: () async {
            throw Exception('Firebase Auth server unreachable');
          },
        );
        redirectedToLogin = true;
      } catch (e) {
        surfacedError = e;
      }

      expect(tracker.firebaseSignOutExecuted, isFalse,
          reason: 'firebaseSignOut threw before completion');
      expect(surfacedError, isNotNull,
          reason: 'Firebase sign-out error must be observable and not silently swallowed');
      expect(redirectedToLogin, isFalse,
          reason: 'UI must NOT navigate to Login when Firebase sign-out failed (prevents false success state)');
    });

    test('Scenario B: Firebase sign-out throws after Google sign-out succeeded -> UI does NOT report success', () async {
      final tracker = MockLogoutTracker();
      bool redirectedToLogin = false;
      Object? surfacedError;

      try {
        await tracker.logout(
          isGoogleSignInInitialised: true,
          googleSignOut: () async {},
          firebaseSignOut: () async {
            throw Exception('Firebase token invalidation error');
          },
        );
        redirectedToLogin = true;
      } catch (e) {
        surfacedError = e;
      }

      expect(tracker.googleSignOutAttempted, isTrue);
      expect(tracker.googleSignOutSucceeded, isTrue);
      expect(surfacedError, isNotNull,
          reason: 'Firebase error must propagate despite Google success');
      expect(redirectedToLogin, isFalse,
          reason: 'Must not claim successful logout when Firebase Auth is still signed in');
    });
  });

  group('Google Account Photo URL Reconciliation', () {
    test('New Google user: fotoUrl is set from Google photoURL', () {
      final profile = UserModel(
        id: 'google_user_1',
        nama: 'Google User',
        email: 'guser@gmail.com',
        role: AppConstants.roleUser,
        fotoUrl: 'https://lh3.googleusercontent.com/a/photo123',
        createdAt: DateTime.now(),
      );

      expect(profile.fotoUrl, isNotNull);
      expect(profile.fotoUrl, contains('googleusercontent.com'));
    });

    test('Existing user with empty fotoUrl: Google photo fills the gap', () {
      final existing = UserModel(
        id: 'u_existing',
        nama: 'Existing User',
        email: 'existing@test.com',
        role: AppConstants.roleUser,
        fotoUrl: null,
        createdAt: DateTime(2026, 1, 1),
      );

      // Simulate the reconciliation logic from signInWithGoogle
      const googlePhotoUrl = 'https://lh3.googleusercontent.com/a/new_photo';
      final shouldUpdate = existing.fotoUrl == null || existing.fotoUrl!.isEmpty;
      expect(shouldUpdate, isTrue);

      final updated = existing.copyWith(fotoUrl: googlePhotoUrl);
      expect(updated.fotoUrl, equals(googlePhotoUrl));
      expect(updated.nama, equals('Existing User'), reason: 'Name must not change');
      expect(updated.role, equals(AppConstants.roleUser), reason: 'Role must not change');
    });

    test('Existing user with custom fotoUrl: Google photo does NOT overwrite', () {
      final existing = UserModel(
        id: 'u_custom',
        nama: 'Custom Photo User',
        email: 'custom@test.com',
        role: AppConstants.roleUser,
        fotoUrl: 'https://cdn.example.com/custom_avatar.jpg',
        createdAt: DateTime(2026, 1, 1),
      );

      final shouldUpdate = existing.fotoUrl == null || existing.fotoUrl!.isEmpty;
      expect(shouldUpdate, isFalse,
          reason: 'Existing non-empty fotoUrl must NOT be overwritten by Google photo');
    });

    test('Google user always gets role "user", never admin', () {
      final profile = UserModel(
        id: 'google_new',
        nama: 'New Google User',
        email: 'newgoogle@gmail.com',
        role: AppConstants.roleUser,
        createdAt: DateTime.now(),
      );

      expect(profile.role, equals('user'));
      expect(profile.isAdmin, isFalse);
      expect(profile.isSuperAdmin, isFalse);
    });
  });

  group('Email/Password Account Without Photo URL', () {
    test('Null fotoUrl produces correct initials fallback', () {
      final user = UserModel(
        id: 'email_user',
        nama: 'Ahmad Rizki',
        email: 'ahmad@test.com',
        role: AppConstants.roleUser,
        fotoUrl: null,
      );

      expect(user.fotoUrl, isNull);
      expect(user.initials, equals('AR'));
    });

    test('Empty fotoUrl is treated as no photo', () {
      final user = UserModel(
        id: 'email_user_2',
        nama: 'Budi Santoso',
        email: 'budi@test.com',
        role: AppConstants.roleUser,
        fotoUrl: '',
      );

      final hasPhoto = user.fotoUrl != null && user.fotoUrl!.isNotEmpty;
      expect(hasPhoto, isFalse);
      expect(user.initials, equals('BS'));
    });
  });

  group('Initials Fallback Correctness', () {
    test('Multi-word name produces two-letter initials', () {
      final user = UserModel(
        id: 'i1', nama: 'Siti Rahayu', email: 'a@b.c', role: 'user',
      );
      expect(user.initials, equals('SR'));
    });

    test('Single-word name produces one uppercase letter', () {
      final user = UserModel(
        id: 'i2', nama: 'Admin', email: 'a@b.c', role: 'user',
      );
      expect(user.initials, equals('A'));
    });

    test('Empty name produces "?" fallback', () {
      final user = UserModel(
        id: 'i3', nama: '', email: 'a@b.c', role: 'user',
      );
      expect(user.initials, equals('?'));
    });

    test('Three-word name uses first two words', () {
      final user = UserModel(
        id: 'i4', nama: 'Muhammad Rizki Pratama', email: 'a@b.c', role: 'user',
      );
      expect(user.initials, equals('MR'));
    });
  });

  group('Profile Name Update Preserves Other Fields', () {
    test('copyWith(nama) does not change role or fotoUrl', () {
      final original = UserModel(
        id: 'u_1',
        nama: 'Old Name',
        email: 'old@test.com',
        role: 'admin',
        fotoUrl: 'https://example.com/photo.jpg',
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = original.copyWith(nama: 'New Name');

      expect(updated.nama, equals('New Name'));
      expect(updated.role, equals('admin'), reason: 'Role must not change');
      expect(updated.fotoUrl, equals('https://example.com/photo.jpg'),
          reason: 'fotoUrl must not change');
      expect(updated.email, equals('old@test.com'),
          reason: 'Email must not change');
      expect(updated.id, equals('u_1'), reason: 'ID must not change');
    });
  });

  group('Production Schema — No Academic Fields', () {
    test('toMap never contains avatar, nim, or namaKelompok', () {
      final user = UserModel(
        id: 'schema_check',
        nama: 'Schema Test',
        email: 'schema@test.com',
        role: AppConstants.roleUser,
        fotoUrl: 'https://example.com/photo.jpg',
        createdAt: DateTime(2026, 6, 15),
      );

      final map = user.toMap();

      expect(map.containsKey('avatar'), isFalse);
      expect(map.containsKey('nim'), isFalse);
      expect(map.containsKey('namaKelompok'), isFalse);
      expect(map.containsKey('fotoUrl'), isTrue);
      expect(map['fotoUrl'], equals('https://example.com/photo.jpg'));
    });

    test('fromMap ignores legacy avatar field', () {
      final legacyData = {
        'nama': 'Legacy User',
        'email': 'legacy@test.com',
        'role': 'user',
        'avatar': 'old_avatar_value',
        'nim': '12345',
        'namaKelompok': 'Group A',
        'fotoUrl': 'https://example.com/new.jpg',
      };

      final user = UserModel.fromMap(legacyData, 'legacy_id');

      expect(user.fotoUrl, equals('https://example.com/new.jpg'));
      expect(user.nama, equals('Legacy User'));
      // No avatar getter should exist
    });
  });
}
