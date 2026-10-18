import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String eventId;
  final double rating;
  final String komentar;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.eventId,
    required this.rating,
    required this.komentar,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      eventId: map['eventId'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      komentar: map['komentar'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'eventId': eventId,
      'rating': rating,
      'komentar': komentar,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
