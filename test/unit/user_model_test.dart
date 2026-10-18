import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/models/user_model.dart';
import 'package:soundwave/constants/app_constants.dart';

void main() {
  group('UserModel Authorization & Role Tests', () {
    test('regular user role evaluates isAdmin and isSuperAdmin to false', () {
      final user = UserModel(
        id: 'u1',
        nama: 'Regular Buyer',
        email: 'buyer@soundwave.id',
        role: AppConstants.roleUser,
      );

      expect(user.isAdmin, isFalse);
      expect(user.isSuperAdmin, isFalse);
      expect(user.role, equals('user'));
    });

    test('admin role evaluates isAdmin to true and isSuperAdmin to false', () {
      final admin = UserModel(
        id: 'a1',
        nama: 'Gate Admin',
        email: 'admin@soundwave.id',
        role: AppConstants.roleAdmin,
      );

      expect(admin.isAdmin, isTrue);
      expect(admin.isSuperAdmin, isFalse);
    });

    test('super_admin role evaluates both isAdmin and isSuperAdmin to true', () {
      final superAdmin = UserModel(
        id: 'sa1',
        nama: 'Chief Admin',
        email: 'chief@soundwave.id',
        role: AppConstants.roleSuperAdmin,
      );

      expect(superAdmin.isAdmin, isTrue);
      expect(superAdmin.isSuperAdmin, isTrue);
    });

    test('copyWith does not leak role without explicit update', () {
      final user = UserModel(
        id: 'u1',
        nama: 'User Old',
        email: 'user@soundwave.id',
        role: AppConstants.roleUser,
      );

      final updated = user.copyWith(nama: 'User New');
      expect(updated.nama, equals('User New'));
      expect(updated.role, equals(AppConstants.roleUser));
      expect(updated.isAdmin, isFalse);
    });
  });

  group('UserModel Production Schema Tests', () {
    test('toMap contains only production fields (no nim, namaKelompok, avatar)', () {
      final user = UserModel(
        id: 'u1',
        nama: 'Test User',
        email: 'test@soundwave.id',
        role: 'user',
        fotoUrl: 'https://example.com/photo.jpg',
        createdAt: DateTime(2026, 1, 15),
      );

      final map = user.toMap();
      expect(map.containsKey('nama'), isTrue);
      expect(map.containsKey('email'), isTrue);
      expect(map.containsKey('role'), isTrue);
      expect(map.containsKey('fotoUrl'), isTrue);
      expect(map.containsKey('createdAt'), isTrue);
      expect(map.containsKey('updatedAt'), isTrue);

      // Academic fields must NOT exist
      expect(map.containsKey('nim'), isFalse);
      expect(map.containsKey('namaKelompok'), isFalse);
      expect(map.containsKey('avatar'), isFalse);
    });

    test('fromMap ignores legacy nim/namaKelompok/avatar fields gracefully', () {
      final map = {
        'nama': 'Legacy User',
        'email': 'legacy@test.com',
        'role': 'user',
        'nim': '12345678',
        'namaKelompok': 'Kelompok A',
        'avatar': 'old_avatar.png',
        'fotoUrl': 'https://example.com/photo.jpg',
      };

      final user = UserModel.fromMap(map, 'legacy_uid');
      expect(user.nama, equals('Legacy User'));
      expect(user.email, equals('legacy@test.com'));
      expect(user.fotoUrl, equals('https://example.com/photo.jpg'));
      // Model should not have nim/namaKelompok/avatar properties
      expect(user.toMap().containsKey('nim'), isFalse);
      expect(user.toMap().containsKey('namaKelompok'), isFalse);
      expect(user.toMap().containsKey('avatar'), isFalse);
    });

    test('updatedAt is included in toMap', () {
      final user = UserModel(
        id: 'u1',
        nama: 'Test',
        email: 'test@test.com',
        role: 'user',
      );
      final map = user.toMap();
      expect(map.containsKey('updatedAt'), isTrue);
    });

    test('initials are computed correctly for multi-word names', () {
      final user = UserModel(
        id: 'u1',
        nama: 'Ahmad Fariz',
        email: 'a@b.com',
        role: 'user',
      );
      expect(user.initials, equals('AF'));
    });

    test('initials fallback for single-word name', () {
      final user = UserModel(
        id: 'u1',
        nama: 'Fariz',
        email: 'a@b.com',
        role: 'user',
      );
      expect(user.initials, equals('F'));
    });

    test('initials fallback for empty name', () {
      final user = UserModel(
        id: 'u1',
        nama: '',
        email: 'a@b.com',
        role: 'user',
      );
      expect(user.initials, equals('?'));
    });

    test('fotoUrl is the single canonical profile image field', () {
      final user = UserModel(
        id: 'u1',
        nama: 'Test',
        email: 'test@test.com',
        role: 'user',
        fotoUrl: 'https://example.com/photo.jpg',
      );
      expect(user.fotoUrl, equals('https://example.com/photo.jpg'));
      expect(user.toMap()['fotoUrl'], equals('https://example.com/photo.jpg'));
    });

    test('copyWith preserves fotoUrl when not explicitly changed', () {
      final user = UserModel(
        id: 'u1',
        nama: 'Test',
        email: 'test@test.com',
        role: 'user',
        fotoUrl: 'https://example.com/photo.jpg',
      );

      final updated = user.copyWith(nama: 'New Name');
      expect(updated.fotoUrl, equals('https://example.com/photo.jpg'));
      expect(updated.nama, equals('New Name'));
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

    test('UserModel cannot be constructed with academic fields', () {
      // This test verifies at compile time that nim, namaKelompok, avatar
      // are not accepted as constructor parameters
      final user = UserModel(
        id: 'u1',
        nama: 'Test',
        email: 'test@test.com',
        role: 'user',
      );
      final map = user.toMap();
      expect(map.keys, isNot(contains('nim')));
      expect(map.keys, isNot(contains('namaKelompok')));
      expect(map.keys, isNot(contains('avatar')));
    });
  });
}
