import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  GoogleSignIn? _googleSignIn;
  final GoogleSignIn? _injectedGoogleSignIn;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _injectedGoogleSignIn = googleSignIn;

  /// Lazy-initialise GoogleSignIn so an assertion failure on Web
  /// (missing client ID in index.html) does not crash the entire app.
  GoogleSignIn _getGoogleSignIn() {
    if (_googleSignIn != null) return _googleSignIn!;
    if (_injectedGoogleSignIn != null) {
      _googleSignIn = _injectedGoogleSignIn;
      return _googleSignIn!;
    }
    try {
      _googleSignIn = GoogleSignIn();
    } catch (e) {
      debugPrint('[AuthService] GoogleSignIn init failed: $e');
      rethrow;
    }
    return _googleSignIn!;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('[AuthService] Error fetching user data: $e');
      rethrow;
    }
  }

  /// Real-time stream of user profile from Cloud Firestore.
  Stream<UserModel?> streamUserData(String uid) {
    return _firestore
        .collection(AppConstants.collectionUsers)
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return UserModel.fromMap(snapshot.data()!, snapshot.id);
    });
  }

  /// Idempotent: returns existing profile if found.
  Future<UserModel> ensureProfile(User user) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(user.uid)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (_) {}

    final profile = UserModel(
      id: user.uid,
      nama: user.displayName?.isNotEmpty == true
          ? user.displayName!
          : 'Pengguna SoundWave',
      email: user.email ?? '',
      role: AppConstants.roleUser,
      fotoUrl: user.photoURL,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(user.uid)
        .set(profile.toMap());

    return profile;
  }

  /// Register always creates a buyer (`user`). Admin roles are assigned
  /// by super_admin via User Management, never via public registration.
  Future<UserModel?> register({
    required String nama,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) return null;

      final userModel = UserModel(
        id: credential.user!.uid,
        nama: nama,
        email: email,
        role: AppConstants.roleUser,
        createdAt: DateTime.now(),
      );

      try {
        await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(credential.user!.uid)
            .set(userModel.toMap());
      } on FirebaseException catch (e) {
        debugPrint('[AuthService.register] Firestore profile write failed: [${e.code}] ${e.message}');
        throw mapFirestoreError(e);
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService.register] FirebaseAuthException: [${e.code}] ${e.message}');
      throw mapAuthError(e);
    } on FirebaseException catch (e) {
      debugPrint('[AuthService.register] FirebaseException: [${e.code}] ${e.message}');
      throw mapFirestoreError(e);
    } catch (e) {
      debugPrint('[AuthService.register] Unexpected error: $e');
      if (e is String) rethrow;
      throw 'Terjadi kesalahan tidak terduga saat pendaftaran: $e';
    }
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) return null;

      var profile = await getUserData(credential.user!.uid);

      // Ensure Firestore profile exists for Auth-only accounts
      if (profile == null) {
        profile = UserModel(
          id: credential.user!.uid,
          nama: credential.user!.displayName ?? 'Pengguna SoundWave',
          email: credential.user!.email ?? email,
          role: AppConstants.roleUser,
          createdAt: DateTime.now(),
        );
        try {
          await _firestore
              .collection(AppConstants.collectionUsers)
              .doc(credential.user!.uid)
              .set(profile.toMap());
        } on FirebaseException catch (e) {
          debugPrint('[AuthService.login] Profile creation fallback failed: [${e.code}] ${e.message}');
        }
      }

      return profile;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService.login] FirebaseAuthException: [${e.code}] ${e.message}');
      throw mapAuthError(e);
    } on FirebaseException catch (e) {
      debugPrint('[AuthService.login] FirebaseException: [${e.code}] ${e.message}');
      throw mapFirestoreError(e);
    } catch (e) {
      debugPrint('[AuthService.login] Unexpected error: $e');
      if (e is String) rethrow;
      throw 'Terjadi kesalahan tidak terduga saat login: $e';
    }
  }

  /// Google Sign-In: authenticates via Google provider and creates/reconciles
  /// Firestore profile. Does not duplicate accounts — existing profiles are preserved.
  Future<UserModel?> signInWithGoogle() async {
    try {
      final googleUser = await _getGoogleSignIn().signIn();
      if (googleUser == null) {
        // User cancelled the sign-in flow
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) return null;

      // Check if Firestore profile already exists
      var profile = await getUserData(firebaseUser.uid);

      if (profile == null) {
        // First-time Google sign-in: create Firestore profile
        profile = UserModel(
          id: firebaseUser.uid,
          nama: firebaseUser.displayName ?? googleUser.displayName ?? 'Pengguna SoundWave',
          email: firebaseUser.email ?? googleUser.email,
          role: AppConstants.roleUser,
          fotoUrl: firebaseUser.photoURL ?? googleUser.photoUrl,
          createdAt: DateTime.now(),
        );

        try {
          await _firestore
              .collection(AppConstants.collectionUsers)
              .doc(firebaseUser.uid)
              .set(profile.toMap());
        } on FirebaseException catch (e) {
          debugPrint('[AuthService.signInWithGoogle] Firestore profile write failed: [${e.code}] ${e.message}');
        }
      } else {
        // Existing user — update photo if available and currently empty
        if (profile.fotoUrl == null || profile.fotoUrl!.isEmpty) {
          final photoUrl = firebaseUser.photoURL ?? googleUser.photoUrl;
          if (photoUrl != null && photoUrl.isNotEmpty) {
            await _firestore
                .collection(AppConstants.collectionUsers)
                .doc(firebaseUser.uid)
                .update({
              'fotoUrl': photoUrl,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            profile = profile.copyWith(fotoUrl: photoUrl);
          }
        }
      }

      return profile;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService.signInWithGoogle] FirebaseAuthException: [${e.code}] ${e.message}');
      throw mapAuthError(e);
    } on FirebaseException catch (e) {
      debugPrint('[AuthService.signInWithGoogle] FirebaseException: [${e.code}] ${e.message}');
      throw mapFirestoreError(e);
    } catch (e) {
      debugPrint('[AuthService.signInWithGoogle] Unexpected error: $e');
      if (e is String) rethrow;
      final errStr = e.toString();
      if (errStr.contains('10') || errStr.contains('DEVELOPER_ERROR')) {
        throw 'Google Sign-In gagal (Kode 10): SHA-1 fingerprint aplikasi belum didaftarkan di Firebase Console.';
      }
      throw 'Terjadi kesalahan saat masuk dengan Google: $e';
    }
  }

  Future<void> logout() async {
    // Lepas token push device ini SEBELUM sign-out, supaya HP ini tidak lagi
    // menerima notifikasi untuk akun yang baru saja keluar. Ditulis selagi
    // masih punya izin (rules Firestore butuh userId == request.auth.uid).
    final uidKeluar = _auth.currentUser?.uid;
    if (uidKeluar != null) {
      try {
        await NotificationService().lepasToken(uidKeluar);
      } catch (e) {
        debugPrint('[AuthService.logout] lepas token push gagal: $e');
      }
    }

    // Best-effort Google provider cleanup.
    // Only attempt if GoogleSignIn was already initialised or injected — never trigger
    // construction here, because a missing Web client-ID would throw and
    // could prevent Firebase Auth sign-out.
    final gsi = _googleSignIn ?? _injectedGoogleSignIn;
    if (gsi != null) {
      try {
        await gsi.signOut();
      } catch (e) {
        debugPrint('[AuthService.logout] Google sign-out failed (non-critical): $e');
      }
    }
    await _auth.signOut();
  }

  Future<void> updateProfile({
    required String uid,
    required String nama,
    String? fotoUrl,
  }) async {
    final updates = <String, dynamic>{
      'nama': nama,
      if (fotoUrl != null) 'fotoUrl': fotoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(uid)
        .update(updates);
  }

  Future<void> updateUserRole(String uid, String newRole) async {
    final caller = _auth.currentUser;
    if (caller == null) {
      throw 'Pengguna belum terautentikasi.';
    }
    if (caller.uid == uid) {
      throw 'Tidak dapat mengubah role akun sendiri.';
    }
    if (![AppConstants.roleUser, AppConstants.roleAdmin].contains(newRole)) {
      throw 'Role target tidak valid.';
    }

    final callerDoc = await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(caller.uid)
        .get();
    if (!callerDoc.exists || callerDoc.data()?['role'] != AppConstants.roleSuperAdmin) {
      throw 'Hanya superadmin yang berhak mengubah role pengguna.';
    }

    try {
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint('[AuthService.updateUserRole] Firestore error: [${e.code}] ${e.message}');
      throw mapFirestoreError(e);
    } catch (e) {
      throw 'Gagal mengubah role: $e';
    }
  }

  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection(AppConstants.collectionUsers)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> deleteUser(String uid) async {
    final caller = _auth.currentUser;
    if (caller == null) {
      throw 'Pengguna belum terautentikasi.';
    }
    if (caller.uid == uid) {
      throw 'Tidak dapat menghapus akun sendiri.';
    }

    final callerDoc = await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(caller.uid)
        .get();
    if (!callerDoc.exists || callerDoc.data()?['role'] != AppConstants.roleSuperAdmin) {
      throw 'Hanya superadmin yang berhak menghapus profil pengguna.';
    }

    final targetDoc = await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(uid)
        .get();
    if (targetDoc.exists && targetDoc.data()?['role'] == AppConstants.roleSuperAdmin) {
      throw 'Tidak dapat menghapus profil superadmin lain.';
    }

    try {
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .delete();
    } on FirebaseException catch (e) {
      debugPrint('[AuthService.deleteUser] Firestore error: [${e.code}] ${e.message}');
      throw mapFirestoreError(e);
    } catch (e) {
      throw 'Gagal menghapus user: $e';
    }
  }

  /// Maps [FirebaseAuthException] to user-friendly messages while retaining
  /// safe diagnostic context without exposing credentials or secrets.
  static String mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'weak-password':
        return 'Password terlalu lemah (min. 6 karakter)';
      case 'operation-not-allowed':
      case 'configuration-not-found':
        return 'Metode email/password belum diaktifkan di Firebase Console';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password salah';
      case 'user-disabled':
        return 'Akun pengguna telah dinonaktifkan';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti';
      case 'network-request-failed':
        return 'Koneksi ke server gagal';
      case 'permission-denied':
        return 'Pembuatan profil pengguna ditolak oleh Firestore Rules';
      case 'account-exists-with-different-credential':
        return 'Akun sudah terdaftar dengan metode login lain';
      default:
        if (e.message != null &&
            e.message!.trim().isNotEmpty &&
            e.message!.trim() != 'Error') {
          return 'Terjadi kesalahan autentikasi [${e.code}]: ${e.message}';
        }
        return 'Terjadi kesalahan autentikasi [${e.code}]';
    }
  }

  /// Maps [FirebaseException] (e.g. from Cloud Firestore) to user-friendly messages.
  static String mapFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Pembuatan profil pengguna ditolak oleh Firestore Rules';
      case 'unavailable':
        return 'Koneksi ke server gagal';
      default:
        if (e.message != null &&
            e.message!.trim().isNotEmpty &&
            e.message!.trim() != 'Error') {
          return 'Kesalahan database [${e.code}]: ${e.message}';
        }
        return 'Kesalahan database [${e.code}]';
    }
  }
}
