import 'package:cloud_firestore/cloud_firestore.dart';

class OrderForecast {
  final String id;
  final String stockItemId;
  final String stockItemName;
  final String category;
  final double quantity;
  final String unit;
  final DateTime scheduledDate;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  final bool completed;

  OrderForecast({
    required this.id,
    required this.stockItemId,
    required this.stockItemName,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.scheduledDate,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    this.completed = false,
  });

  factory OrderForecast.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderForecast(
      id: doc.id,
      stockItemId: data['stockItemId'] ?? '',
      stockItemName: data['stockItemName'] ?? '',
      category: data['category'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      scheduledDate: (data['scheduledDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completed: data['completed'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'stockItemId': stockItemId,
      'stockItemName': stockItemName,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'completed': completed,
      if (notes != null) 'notes': notes,
    };
  }

  OrderForecast copyWith({
    String? id,
    String? stockItemId,
    String? stockItemName,
    String? category,
    double? quantity,
    String? unit,
    DateTime? scheduledDate,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    bool? completed,
  }) {
    return OrderForecast(
      id: id ?? this.id,
      stockItemId: stockItemId ?? this.stockItemId,
      stockItemName: stockItemName ?? this.stockItemName,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      completed: completed ?? this.completed,
    );
  }
}

