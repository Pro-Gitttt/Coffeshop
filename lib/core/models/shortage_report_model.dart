import 'package:cloud_firestore/cloud_firestore.dart';

class ShortageReport {
  final String id;
  final String stockItemId;
  final String stockItemName;
  final String category;
  final double currentQuantity;
  final String unit;
  final String userId;
  final String? userEmail;
  final String? userName;
  final String? comment;
  final DateTime timestamp;
  final bool resolved;

  ShortageReport({
    required this.id,
    required this.stockItemId,
    required this.stockItemName,
    required this.category,
    required this.currentQuantity,
    required this.unit,
    required this.userId,
    this.userEmail,
    this.userName,
    this.comment,
    required this.timestamp,
    this.resolved = false,
  });

  factory ShortageReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShortageReport(
      id: doc.id,
      stockItemId: data['stockItemId'] ?? '',
      stockItemName: data['stockItemName'] ?? '',
      category: data['category'] ?? '',
      currentQuantity: (data['currentQuantity'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'],
      userName: data['userName'],
      comment: data['comment'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolved: data['resolved'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'stockItemId': stockItemId,
      'stockItemName': stockItemName,
      'category': category,
      'currentQuantity': currentQuantity,
      'unit': unit,
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'resolved': resolved,
    };
    if (userEmail != null) {
      data['userEmail'] = userEmail;
    }
    if (userName != null) {
      data['userName'] = userName;
    }
    if (comment != null) {
      data['comment'] = comment;
    }
    return data;
  }
}

