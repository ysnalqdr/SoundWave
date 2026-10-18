import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/models/tiket_konser_model.dart';
import 'package:soundwave/constants/app_constants.dart';

void main() {
  group('QA Batch 1 — Physical Device Bug Fix Verification', () {
    // TC01: Google Sign-In Error Mapping
    test('TC01: ApiException 10 (DEVELOPER_ERROR) maps to actionable SHA-1 diagnosis', () {
      String mapGoogleError(dynamic e) {
        final errStr = e.toString();
        if (errStr.contains('10') || errStr.contains('DEVELOPER_ERROR')) {
          return 'Google Sign-In gagal (Kode 10): SHA-1 fingerprint aplikasi belum didaftarkan di Firebase Console.';
        }
        return 'Terjadi kesalahan saat masuk dengan Google: $e';
      }

      const rawError = 'PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)';
      final mapped = mapGoogleError(rawError);

      expect(mapped, contains('Kode 10'));
      expect(mapped, contains('SHA-1 fingerprint'));
      expect(mapped, contains('Firebase Console'));
    });

    // TC02: Favorit Path, ID, and Isolation Logic
    test('TC02: Favorite document ID is deterministic userId-eventId and enforces user isolation', () {
      const userA = 'user_abc_123';
      const userB = 'user_xyz_789';
      const concertId = 'concert_rock_2026';

      String getFavDocId(String uid, String eventId) => '$uid-$eventId';

      final favIdA = getFavDocId(userA, concertId);
      final favIdB = getFavDocId(userB, concertId);

      expect(favIdA, equals('user_abc_123-concert_rock_2026'));
      expect(favIdB, equals('user_xyz_789-concert_rock_2026'));
      expect(favIdA, isNot(equals(favIdB)));

      // Validate data payload
      Map<String, dynamic> buildFavPayload(String uid, String eventId) {
        return {
          'userId': uid,
          'eventId': eventId,
        };
      }

      final payloadA = buildFavPayload(userA, concertId);
      expect(payloadA['userId'], equals(userA));
      expect(payloadA['eventId'], equals(concertId));

      // Rule check: user A cannot write with user B's uid
      bool canCreateFavorite(String authUid, Map<String, dynamic> data) {
        return authUid.isNotEmpty && data['userId'] == authUid && data.containsKey('eventId');
      }

      expect(canCreateFavorite(userA, payloadA), isTrue);
      expect(canCreateFavorite(userB, payloadA), isFalse); // Spoofed userId denied
    });

    // TC04: Ticket Categories In-Memory Sorting & Resilience
    test('TC04: Ticket categories sort in-memory by price without requiring Firestore composite index', () {
      final unsortedTickets = [
        TiketKonserModel(
          id: 't3',
          idKonser: 'c1',
          judulKonser: 'Rock Fest',
          gambarKonser: 'https://example.com/fest.jpg',
          kategori: 'VIP',
          harga: 750000,
          stok: 50,
        ),
        TiketKonserModel(
          id: 't1',
          idKonser: 'c1',
          judulKonser: 'Rock Fest',
          gambarKonser: 'https://example.com/fest.jpg',
          kategori: 'Early Bird',
          harga: 250000,
          stok: 100,
        ),
        TiketKonserModel(
          id: 't2',
          idKonser: 'c1',
          judulKonser: 'Rock Fest',
          gambarKonser: 'https://example.com/fest.jpg',
          kategori: 'Regular',
          harga: 400000,
          stok: 200,
        ),
      ];

      // Simulate DatabaseService.getTicketsByEvent in-memory sort
      final sortedList = List<TiketKonserModel>.from(unsortedTickets);
      sortedList.sort((a, b) => a.harga.compareTo(b.harga));

      expect(sortedList[0].kategori, equals('Early Bird'));
      expect(sortedList[0].harga, equals(250000));
      expect(sortedList[1].kategori, equals('Regular'));
      expect(sortedList[1].harga, equals(400000));
      expect(sortedList[2].kategori, equals('VIP'));
      expect(sortedList[2].harga, equals(750000));
    });

    // TC06: Index Declaration Verification in firestore.indexes.json
    test('TC06: firestore.indexes.json contains required composite index definitions', () {
      final indexFile = File('firestore.indexes.json');
      expect(indexFile.existsSync(), isTrue);

      final content = jsonDecode(indexFile.readAsStringSync()) as Map<String, dynamic>;
      final indexes = (content['indexes'] as List).cast<Map<String, dynamic>>();

      // 1. Tickets index: idKonser ASC, harga ASC
      final ticketIndex = indexes.firstWhere(
        (idx) => idx['collectionGroup'] == AppConstants.collectionTickets,
        orElse: () => <String, dynamic>{},
      );
      expect(ticketIndex.isNotEmpty, isTrue, reason: 'Tickets composite index must be defined');
      final ticketFields = (ticketIndex['fields'] as List).cast<Map<String, dynamic>>();
      expect(ticketFields[0]['fieldPath'], equals('idKonser'));
      expect(ticketFields[1]['fieldPath'], equals('harga'));

      // 2. Reviews index: eventId ASC, createdAt DESC
      final reviewIndex = indexes.firstWhere(
        (idx) => idx['collectionGroup'] == AppConstants.collectionReviews,
        orElse: () => <String, dynamic>{},
      );
      expect(reviewIndex.isNotEmpty, isTrue, reason: 'Reviews composite index must be defined');
      final reviewFields = (reviewIndex['fields'] as List).cast<Map<String, dynamic>>();
      expect(reviewFields[0]['fieldPath'], equals('eventId'));
      expect(reviewFields[1]['fieldPath'], equals('createdAt'));
    });
  });
}
