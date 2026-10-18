import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/models/user_model.dart';
import 'package:soundwave/constants/app_constants.dart';

/// Simulation of Super Admin Bootstrap logic matching functions/index.js:bootstrapSuperAdmin
class SuperAdminBootstrapSimulator {
  final String designatedEmail;
  final Map<String, Map<String, dynamic>> firestoreUsers = {};

  SuperAdminBootstrapSimulator({this.designatedEmail = 'admin@soundwave.id'});

  Map<String, dynamic> bootstrapSuperAdmin({
    required bool isAuthenticated,
    String? callerEmail,
    String? callerUid,
    String? callerName,
  }) {
    // Condition A: unauthenticated caller
    if (!isAuthenticated || callerUid == null) {
      throw Exception('unauthenticated: Login diperlukan.');
    }

    // Condition B: authenticated user with wrong email
    if (callerEmail != designatedEmail) {
      throw Exception('permission-denied: Email Anda tidak memiliki hak untuk bootstrap super admin.');
    }

    // Condition D: after a super_admin already exists -> reject
    final existingSuperAdmin = firestoreUsers.values.any((u) => u['role'] == AppConstants.roleSuperAdmin);
    if (existingSuperAdmin) {
      throw Exception('already-exists: Super admin sudah ada di sistem. Bootstrap tidak dapat dijalankan lagi.');
    }

    // Condition C: designated bootstrap identity accepted
    final userDoc = firestoreUsers[callerUid] ?? {
      'id': callerUid,
      'email': callerEmail,
      'nama': callerName ?? 'Super Admin',
      'role': AppConstants.roleUser,
    };
    userDoc['role'] = AppConstants.roleSuperAdmin;
    userDoc['updatedAt'] = DateTime.now().toIso8601String();
    firestoreUsers[callerUid] = userDoc;

    return {
      'success': true,
      'uid': callerUid,
      'role': AppConstants.roleSuperAdmin,
    };
  }

  /// Simulation of Role Management matching functions/index.js:promoteToAdmin and firestore.rules
  Map<String, dynamic> updateUserRole({
    required UserModel caller,
    required String targetUid,
    required String targetRole,
  }) {
    // Rule: USER cannot promote self or others
    if (caller.role == AppConstants.roleUser) {
      throw Exception('permission-denied: Pembeli biasa tidak memiliki wewenang mengubah role.');
    }

    // Rule: ADMIN cannot promote self to super_admin or promote others to super_admin
    if (caller.role == AppConstants.roleAdmin) {
      if (targetRole == AppConstants.roleSuperAdmin) {
        throw Exception('permission-denied: Admin tidak dapat memberikan hak super_admin.');
      }
      throw Exception('permission-denied: Hanya super_admin yang berhak mengelola role pengguna.');
    }

    // Rule: Self-promotion / self-demotion protection
    if (caller.id == targetUid) {
      throw Exception('failed-precondition: Super admin tidak dapat mengubah role akun sendiri via endpoint ini.');
    }

    // Rule: targetRole must be 'admin' or 'user' (cannot create super_admin via promoteToAdmin)
    if (![AppConstants.roleAdmin, AppConstants.roleUser].contains(targetRole)) {
      throw Exception('invalid-argument: Role baru hanya boleh "admin" atau "user".');
    }

    // SUPER_ADMIN authorized execution
    final target = firestoreUsers[targetUid];
    if (target == null) {
      throw Exception('not-found: Pengguna target tidak ditemukan.');
    }

    target['role'] = targetRole;
    return {'success': true, 'targetUid': targetUid, 'newRole': targetRole};
  }
}

void main() {
  group('Super Admin Bootstrap & Role Security Verification', () {
    late SuperAdminBootstrapSimulator simulator;

    setUp(() {
      simulator = SuperAdminBootstrapSimulator(designatedEmail: 'admin@soundwave.id');
    });

    test('Condition A: unauthenticated caller is rejected with unauthenticated error', () {
      expect(
        () => simulator.bootstrapSuperAdmin(
          isAuthenticated: false,
          callerEmail: null,
          callerUid: null,
        ),
        throwsA(predicate((e) => e.toString().contains('unauthenticated'))),
      );
    });

    test('Condition B: authenticated user with wrong email is rejected with permission-denied', () {
      expect(
        () => simulator.bootstrapSuperAdmin(
          isAuthenticated: true,
          callerEmail: 'attacker@evil.com',
          callerUid: 'attacker_123',
        ),
        throwsA(predicate((e) => e.toString().contains('permission-denied'))),
      );
    });

    test('Condition C: designated bootstrap identity succeeds when no super_admin exists', () {
      final res = simulator.bootstrapSuperAdmin(
        isAuthenticated: true,
        callerEmail: 'admin@soundwave.id',
        callerUid: 'super_admin_001',
        callerName: 'System Super Admin',
      );

      expect(res['success'], isTrue);
      expect(res['role'], equals('super_admin'));
      expect(simulator.firestoreUsers['super_admin_001']?['role'], equals('super_admin'));
    });

    test('Condition D: once a super_admin exists, further bootstrap calls are permanently rejected', () {
      // First bootstrap
      simulator.bootstrapSuperAdmin(
        isAuthenticated: true,
        callerEmail: 'admin@soundwave.id',
        callerUid: 'super_admin_001',
      );

      // Attempt second bootstrap
      expect(
        () => simulator.bootstrapSuperAdmin(
          isAuthenticated: true,
          callerEmail: 'admin@soundwave.id',
          callerUid: 'super_admin_002',
        ),
        throwsA(predicate((e) => e.toString().contains('already-exists'))),
      );
    });

    test('Role Security: USER cannot promote self', () {
      final user = UserModel(
        id: 'buyer_1',
        nama: 'Buyer',
        email: 'buyer@test.com',
        role: AppConstants.roleUser,
      );

      expect(
        () => simulator.updateUserRole(
          caller: user,
          targetUid: user.id,
          targetRole: AppConstants.roleAdmin,
        ),
        throwsA(predicate((e) => e.toString().contains('permission-denied'))),
      );
    });

    test('Role Security: ADMIN cannot promote self to super_admin', () {
      final admin = UserModel(
        id: 'admin_1',
        nama: 'Admin Gate',
        email: 'gate@test.com',
        role: AppConstants.roleAdmin,
      );

      expect(
        () => simulator.updateUserRole(
          caller: admin,
          targetUid: admin.id,
          targetRole: AppConstants.roleSuperAdmin,
        ),
        throwsA(predicate((e) => e.toString().contains('permission-denied'))),
      );
    });

    test('Role Security: USER cannot promote another user', () {
      final user = UserModel(
        id: 'buyer_1',
        nama: 'Buyer',
        email: 'buyer@test.com',
        role: AppConstants.roleUser,
      );

      expect(
        () => simulator.updateUserRole(
          caller: user,
          targetUid: 'buyer_2',
          targetRole: AppConstants.roleAdmin,
        ),
        throwsA(predicate((e) => e.toString().contains('permission-denied'))),
      );
    });

    test('Role Security: ADMIN cannot promote another user to super_admin', () {
      final admin = UserModel(
        id: 'admin_1',
        nama: 'Admin Gate',
        email: 'gate@test.com',
        role: AppConstants.roleAdmin,
      );

      expect(
        () => simulator.updateUserRole(
          caller: admin,
          targetUid: 'buyer_2',
          targetRole: AppConstants.roleSuperAdmin,
        ),
        throwsA(predicate((e) => e.toString().contains('permission-denied'))),
      );
    });

    test('Role Security: SUPER_ADMIN can promote a user to admin and demote back to user', () {
      // Seed a buyer in Firestore
      simulator.firestoreUsers['buyer_target'] = {
        'id': 'buyer_target',
        'email': 'buyer@soundwave.id',
        'role': AppConstants.roleUser,
      };

      final superAdmin = UserModel(
        id: 'super_admin_001',
        nama: 'Super Admin',
        email: 'admin@soundwave.id',
        role: AppConstants.roleSuperAdmin,
      );

      // 1. Promote to admin
      final promoteRes = simulator.updateUserRole(
        caller: superAdmin,
        targetUid: 'buyer_target',
        targetRole: AppConstants.roleAdmin,
      );
      expect(promoteRes['success'], isTrue);
      expect(simulator.firestoreUsers['buyer_target']?['role'], equals('admin'));

      // 2. Demote back to user
      final demoteRes = simulator.updateUserRole(
        caller: superAdmin,
        targetUid: 'buyer_target',
        targetRole: AppConstants.roleUser,
      );
      expect(demoteRes['success'], isTrue);
      expect(simulator.firestoreUsers['buyer_target']?['role'], equals('user'));
    });
  });
}
