import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintMessageModel {
  final String id;
  final String complaintId;
  final String content;
  final bool isRead;
  final String senderId;
  final String senderName;
  final String senderRole;
  final DateTime createdAt;
  final DateTime updatedAt;

  ComplaintMessageModel({
    required this.id,
    required this.complaintId,
    required this.content,
    required this.isRead,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ComplaintMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ComplaintMessageModel(
      id: doc.id,
      complaintId: data['complaintID'] ?? data['complaintId'] ?? '',
      content: data['content'] ?? '',
      isRead: (data['isRead'] as bool?) ?? false,
      senderId: data['SenderId'] ?? data['senderId'] ?? '',
      senderName: data['sender name'] ?? data['senderName'] ?? '',
      senderRole: data['sender role'] ?? data['senderRole'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'complaintID': complaintId,
      'content': content,
      'isRead': isRead,
      'SenderId': senderId,
      'sender name': senderName,
      'sender role': senderRole,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ComplaintMessageModel copyWith({
    String? id,
    String? complaintId,
    String? content,
    bool? isRead,
    String? senderId,
    String? senderName,
    String? senderRole,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ComplaintMessageModel(
      id: id ?? this.id,
      complaintId: complaintId ?? this.complaintId,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

