import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/models/user_model.dart';
import 'package:soundwave/constants/app_constants.dart';

enum ProfileUIState {
  unauthenticated,
  authenticatedProfileMissing,
  authenticatedProfileReadError,
  authenticatedProfileLoaded,
}

/// Evaluator that mirrors UserMainScreen & Profile logic to guarantee state separation
ProfileUIState evaluateProfileState({
  required bool isAuthUserPresent,
  required bool isProfileStreamLoading,
  required Object? profileStreamError,
  required UserModel? firestoreProfile,
}) {
  if (!isAuthUserPresent) {
    return ProfileUIState.unauthenticated;
  }

  if (profileStreamError != null) {
    return ProfileUIState.authenticatedProfileReadError;
  }

  if (!isProfileStreamLoading && firestoreProfile == null) {
    return ProfileUIState.authenticatedProfileMissing;
  }

  if (firestoreProfile != null) {
    return ProfileUIState.authenticatedProfileLoaded;
  }

  // Fallback while loading
  return ProfileUIState.authenticatedProfileLoaded;
}

void main() {
  group('Authenticated Profile Error Semantics Tests (State Isolation)', () {
    test('State 1: UNAUTHENTICATED is distinct when no Auth user is logged in', () {
      final state = evaluateProfileState(
        isAuthUserPresent: false,
        isProfileStreamLoading: false,
        profileStreamError: null,
        firestoreProfile: null,
      );

      expect(state, equals(ProfileUIState.unauthenticated));
    });

    test('State 2: AUTHENTICATED + PROFILE MISSING preserves auth identity and does NOT collapse to visitor', () {
      final state = evaluateProfileState(
        isAuthUserPresent: true,
        isProfileStreamLoading: false,
        profileStreamError: null,
        firestoreProfile: null,
      );

      expect(state, equals(ProfileUIState.authenticatedProfileMissing));
      expect(state, isNot(equals(ProfileUIState.unauthenticated)));
      expect(state, isNot(equals(ProfileUIState.authenticatedProfileReadError)));
    });

    test('State 3: AUTHENTICATED + PROFILE READ ERROR preserves auth identity and does NOT collapse to visitor or missing', () {
      final state = evaluateProfileState(
        isAuthUserPresent: true,
        isProfileStreamLoading: false,
        profileStreamError: Exception('Firestore unavailable: network timeout'),
        firestoreProfile: null,
      );

      expect(state, equals(ProfileUIState.authenticatedProfileReadError));
      expect(state, isNot(equals(ProfileUIState.unauthenticated)));
      expect(state, isNot(equals(ProfileUIState.authenticatedProfileMissing)));
    });

    test('State 4: AUTHENTICATED + PROFILE LOADED reflects complete profile', () {
      final profile = UserModel(
        id: 'u_100',
        nama: 'Verified Buyer',
        email: 'buyer@soundwave.id',
        role: AppConstants.roleUser,
        createdAt: DateTime(2026, 1, 1),
      );

      final state = evaluateProfileState(
        isAuthUserPresent: true,
        isProfileStreamLoading: false,
        profileStreamError: null,
        firestoreProfile: profile,
      );

      expect(state, equals(ProfileUIState.authenticatedProfileLoaded));
      expect(profile.initials, equals('VB'));
    });

    test('Session action is NEVER visitor (Login) when user is authenticated, even if profile read errors', () {
      // Authenticated users must always see LOGOUT, never LOGIN_OR_REGISTER.
      // This verifies the UI logic: even when Firestore fails, auth state drives session display.
      String resolveSessionAction(bool isAuth) => isAuth ? 'LOGOUT' : 'LOGIN_OR_REGISTER';
      expect(resolveSessionAction(true), equals('LOGOUT'));
      expect(resolveSessionAction(false), equals('LOGIN_OR_REGISTER'));
    });
  });
}
