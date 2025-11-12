import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String userId;
  final String? menuItemId; // nullable for general cafe feedback
  final int rating; // 1-5
  final String? comment;
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.userId,
    this.menuItemId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedbackModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      menuItemId: data['menuItemId'],
      rating: (data['rating'] ?? 0) as int,
      comment: data['comment'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      if (menuItemId != null) 'menuItemId': menuItemId,
      'rating': rating,
      if (comment != null) 'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}


