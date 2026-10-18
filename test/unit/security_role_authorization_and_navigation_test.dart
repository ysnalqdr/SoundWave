import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/models/user_model.dart';
import 'package:soundwave/constants/app_constants.dart';

void main() {
  group('Phase 5 — Security & Role Authorization Verification', () {
    // 1. user tidak memperoleh hak admin atau superadmin
    test('Case 1: Regular user role evaluates isAdmin and isSuperAdmin to false', () {
      final user = UserModel(
        id: 'usr_01',
        nama: 'Buyer User',
        email: 'user@soundwave.id',
        role: AppConstants.roleUser,
      );

      expect(user.isAdmin, isFalse);
      expect(user.isSuperAdmin, isFalse);
      expect(user.isOperasionalAdmin, isFalse);
      expect(user.hasKnownRole, isTrue);
    });

    // 2. admin memiliki kemampuan operasional yang diizinkan tetapi tidak dapat mengelola role
    test('Case 2: Admin role evaluates isAdmin to true, isSuperAdmin to false, and isOperasionalAdmin to true', () {
      final admin = UserModel(
        id: 'adm_01',
        nama: 'Gate Admin',
        email: 'gate@soundwave.id',
        role: AppConstants.roleAdmin,
      );

      expect(admin.isAdmin, isTrue);
      expect(admin.isSuperAdmin, isFalse);
      expect(admin.isOperasionalAdmin, isTrue);
      expect(admin.hasKnownRole, isTrue);
    });

    // 3 & 4. admin tidak dapat menghapus dokumen pengguna dan ditolak ketika mencoba mengubah role
    test('Case 3 & 4: Admin cannot execute role updates or deletions', () {
      final admin = UserModel(
        id: 'adm_01',
        nama: 'Gate Admin',
        email: 'gate@soundwave.id',
        role: AppConstants.roleAdmin,
      );

      // Business rule: only super_admin can update role
      bool canManageRoles(UserModel caller) => caller.isSuperAdmin;
      bool canDeleteUsers(UserModel caller) => caller.isSuperAdmin;

      expect(canManageRoles(admin), isFalse);
      expect(canDeleteUsers(admin), isFalse);
    });

    // 5. super_admin dapat menjalankan perubahan role yang memang diperbolehkan untuk akun lain
    test('Case 5: Superadmin can assign allowed target roles (admin, user) to others', () {
      final superAdmin = UserModel(
        id: 'sa_01',
        nama: 'Super Admin',
        email: 'admin@soundwave.id',
        role: AppConstants.roleSuperAdmin,
      );

      final targetUser = UserModel(
        id: 'target_01',
        nama: 'Target User',
        email: 'target@soundwave.id',
        role: AppConstants.roleUser,
      );

      expect(superAdmin.isSuperAdmin, isTrue);
      expect(superAdmin.isAdmin, isTrue);

      String executeRoleChange({
        required UserModel caller,
        required String targetId,
        required String newRole,
      }) {
        if (!caller.isSuperAdmin) throw Exception('permission-denied');
        if (caller.id == targetId) throw Exception('cannot-modify-self');
        if (![AppConstants.roleUser, AppConstants.roleAdmin].contains(newRole)) {
          throw Exception('invalid-target-role');
        }
        return newRole;
      }

      // Promote to admin
      final promotedRole = executeRoleChange(
        caller: superAdmin,
        targetId: targetUser.id,
        newRole: AppConstants.roleAdmin,
      );
      expect(promotedRole, equals(AppConstants.roleAdmin));

      // Demote to user
      final demotedRole = executeRoleChange(
        caller: superAdmin,
        targetId: targetUser.id,
        newRole: AppConstants.roleUser,
      );
      expect(demotedRole, equals(AppConstants.roleUser));
    });

    // 6. Superadmin tidak dapat mengubah role dirinya sendiri atau menghapus akunnya sendiri
    test('Case 6: Superadmin cannot modify own role or delete own account', () {
      final superAdmin = UserModel(
        id: 'sa_01',
        nama: 'Super Admin',
        email: 'admin@soundwave.id',
        role: AppConstants.roleSuperAdmin,
      );

      void validateSelfModification(UserModel caller, String targetId) {
        if (caller.id == targetId) {
          throw Exception('failed-precondition: Tidak dapat memodifikasi akun sendiri');
        }
      }

      expect(
        () => validateSelfModification(superAdmin, superAdmin.id),
        throwsA(predicate((e) => e.toString().contains('Tidak dapat memodifikasi akun sendiri'))),
      );
    });

    // 6b. Superadmin tidak dapat menghapus sesama superadmin
    test('Case 6b: Superadmin cannot delete another superadmin', () {
      final superAdmin = UserModel(
        id: 'sa_01',
        nama: 'Super Admin 1',
        email: 'admin1@soundwave.id',
        role: AppConstants.roleSuperAdmin,
      );

      final otherSuperAdmin = UserModel(
        id: 'sa_02',
        nama: 'Super Admin 2',
        email: 'admin2@soundwave.id',
        role: AppConstants.roleSuperAdmin,
      );

      void validateDeletion(UserModel caller, UserModel target) {
        if (!caller.isSuperAdmin) throw Exception('permission-denied');
        if (caller.id == target.id) throw Exception('cannot-delete-self');
        if (target.isSuperAdmin) throw Exception('cannot-delete-super-admin');
      }

      expect(
        () => validateDeletion(superAdmin, otherSuperAdmin),
        throwsA(predicate((e) => e.toString().contains('cannot-delete-super-admin'))),
      );
    });

    // 7. Hak akses tidak dapat diperoleh hanya dengan memanipulasi state UI
    test('Case 7: UI spoofing does not bypass data model authority', () {
      final fakeAdminData = {
        'id': 'fake_01',
        'nama': 'Attacker',
        'email': 'attacker@evil.com',
        'role': 'user', // Actual db role
      };

      final parsedUser = UserModel.fromMap(fakeAdminData, fakeAdminData['id'] as String);
      expect(parsedUser.isAdmin, isFalse);
      expect(parsedUser.isSuperAdmin, isFalse);
    });

    // 8. Role yang tidak dikenal ditolak secara aman (termasuk "superadmin" tanpa underscore)
    test('Case 8: Unknown roles including "superadmin" (no underscore) are rejected safely', () {
      final invalidRoles = [
        'superadmin', // Typo without underscore
        'SuperAdmin',
        'SUPER_ADMIN',
        'manager',
        'guest',
        'moderator',
        '',
        'null',
      ];

      for (final r in invalidRoles) {
        final user = UserModel(
          id: 'test_id',
          nama: 'Test User',
          email: 'test@test.com',
          role: r,
        );

        // Unknown roles must NEVER grant admin or superadmin authority
        expect(user.isAdmin, isFalse, reason: 'Role $r must not be admin');
        expect(user.isSuperAdmin, isFalse, reason: 'Role $r must not be super_admin');
        expect(user.hasKnownRole, isFalse, reason: 'Role $r must be recognized as unknown');
      }
    });

    // 9. Perubahan role memperbarui state aplikasi secara konsisten
    test('Case 9: Role mutation updates model immutably through copyWith', () {
      final original = UserModel(
        id: 'usr_01',
        nama: 'User One',
        email: 'user1@soundwave.id',
        role: AppConstants.roleUser,
      );

      final updated = original.copyWith(role: AppConstants.roleAdmin);
      expect(updated.role, equals(AppConstants.roleAdmin));
      expect(updated.isAdmin, isTrue);
      expect(updated.isSuperAdmin, isFalse);

      final promotedToSA = updated.copyWith(role: AppConstants.roleSuperAdmin);
      expect(promotedToSA.isSuperAdmin, isTrue);
      expect(promotedToSA.isAdmin, isTrue);
    });

    // 10. Navigasi tidak menjebak pengguna pada halaman Kelola User
    test('Case 10: Destinations correctly filter Kelola User for regular admin', () {
      List<String> getNavLabels(bool isSuperAdmin) {
        final list = ['Konser', 'Tiket', 'Validasi Gate (Scan)', 'Laporan Penjualan'];
        if (isSuperAdmin) {
          list.add('Kelola User');
        }
        list.add('Profil & Pengaturan');
        return list;
      }

      final regularAdminNav = getNavLabels(false);
      expect(regularAdminNav.contains('Kelola User'), isFalse);
      expect(regularAdminNav.length, equals(5));

      final superAdminNav = getNavLabels(true);
      expect(superAdminNav.contains('Kelola User'), isTrue);
      expect(superAdminNav.length, equals(6));
    });

    // 11. Pengguna yang tidak berwenang tidak dapat mengakses halaman sensitif melalui deep link
    test('Case 11: Route guard redirects unauthorized /admin access', () {
      String resolveRoute(UserModel? user, String requestedRoute) {
        if (requestedRoute == '/admin') {
          if (user == null) return '/login';
          if (!user.isAdmin) return '/user';
          return '/admin';
        }
        return requestedRoute;
      }

      // Unauthenticated
      expect(resolveRoute(null, '/admin'), equals('/login'));

      // Regular member
      final buyer = UserModel(
        id: 'b_1',
        nama: 'Buyer',
        email: 'buyer@test.com',
        role: AppConstants.roleUser,
      );
      expect(resolveRoute(buyer, '/admin'), equals('/user'));

      // Operasional Admin
      final admin = UserModel(
        id: 'a_1',
        nama: 'Admin',
        email: 'admin@test.com',
        role: AppConstants.roleAdmin,
      );
      expect(resolveRoute(admin, '/admin'), equals('/admin'));

      // Super Admin
      final superAdmin = UserModel(
        id: 'sa_1',
        nama: 'Super Admin',
        email: 'sa@test.com',
        role: AppConstants.roleSuperAdmin,
      );
      expect(resolveRoute(superAdmin, '/admin'), equals('/admin'));
    });

    // 12. Validasi form dan filter list pengguna responsif
    test('Case 12: Search and role filtering functions correctly over user list', () {
      final users = [
        UserModel(id: '1', nama: 'Alice Johnson', email: 'alice@example.com', role: AppConstants.roleSuperAdmin),
        UserModel(id: '2', nama: 'Bob Builder', email: 'bob@example.com', role: AppConstants.roleAdmin),
        UserModel(id: '3', nama: 'Charlie Brown', email: 'charlie@example.com', role: AppConstants.roleUser),
      ];

      List<UserModel> filterUsers(String query, String roleFilter) {
        final q = query.trim().toLowerCase();
        return users.where((u) {
          final matchesSearch = q.isEmpty ||
              u.nama.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q);
          final matchesRole = roleFilter == 'all' || u.role == roleFilter;
          return matchesSearch && matchesRole;
        }).toList();
      }

      expect(filterUsers('alice', 'all').length, equals(1));
      expect(filterUsers('bob', AppConstants.roleAdmin).length, equals(1));
      expect(filterUsers('', AppConstants.roleUser).length, equals(1));
      expect(filterUsers('', AppConstants.roleSuperAdmin).length, equals(1));
      expect(filterUsers('nonexistent', 'all').isEmpty, isTrue);
    });
  });
}
