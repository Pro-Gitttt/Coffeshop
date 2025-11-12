import 'package:cloud_firestore/cloud_firestore.dart';

enum ComplaintStatus {
  pending,
  inProgress,
  resolved,
  closed,
}

enum ComplaintPriority {
  low,
  medium,
  high,
}

class ComplaintModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String? imageUrl;
  final ComplaintPriority priority;
  final ComplaintStatus status;
  final int? rating;
  final String? ratingComment;
  final String? assignedTo; // Admin/Employee user ID
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  ComplaintModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.priority,
    required this.status,
    this.rating,
    this.ratingComment,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
  });

  factory ComplaintModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ComplaintModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] as String?,
      priority: _priorityFromString(data['priority'] as String?),
      status: _statusFromString(data['status'] as String?),
      rating: data['rating'] as int?,
      ratingComment: data['ratingComment'] as String?,
      assignedTo: data['assignedTo'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'userId': userId,
      'title': title,
      'description': description,
      'priority': priority.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      data['imageUrl'] = imageUrl;
    }
    if (rating != null) {
      data['rating'] = rating;
    }
    if (ratingComment != null && ratingComment!.isNotEmpty) {
      data['ratingComment'] = ratingComment;
    }
    if (assignedTo != null && assignedTo!.isNotEmpty) {
      data['assignedTo'] = assignedTo;
    }
    if (resolvedAt != null) {
      data['resolvedAt'] = Timestamp.fromDate(resolvedAt!);
    }

    return data;
  }

  ComplaintModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? imageUrl,
    ComplaintPriority? priority,
    ComplaintStatus? status,
    int? rating,
    String? ratingComment,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      ratingComment: ratingComment ?? this.ratingComment,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  static ComplaintStatus _statusFromString(String? status) {
    if (status == null) return ComplaintStatus.pending;
    switch (status.toLowerCase()) {
      case 'pending':
        return ComplaintStatus.pending;
      case 'inprogress':
      case 'in_progress':
        return ComplaintStatus.inProgress;
      case 'resolved':
        return ComplaintStatus.resolved;
      case 'closed':
        return ComplaintStatus.closed;
      default:
        return ComplaintStatus.pending;
    }
  }

  static ComplaintPriority _priorityFromString(String? priority) {
    if (priority == null) return ComplaintPriority.medium;
    switch (priority.toLowerCase()) {
      case 'low':
        return ComplaintPriority.low;
      case 'medium':
        return ComplaintPriority.medium;
      case 'high':
        return ComplaintPriority.high;
      default:
        return ComplaintPriority.medium;
    }
  }

  String get statusLabel {
    switch (status) {
      case ComplaintStatus.pending:
        return 'Pending';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.closed:
        return 'Closed';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case ComplaintPriority.low:
        return 'Low';
      case ComplaintPriority.medium:
        return 'Medium';
      case ComplaintPriority.high:
        return 'High';
    }
  }
}

