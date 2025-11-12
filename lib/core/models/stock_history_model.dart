import 'package:cloud_firestore/cloud_firestore.dart';

enum HistoryType { input, output, update }

class StockHistory {
  final String id;
  final HistoryType type;
  final String stockItemId;
  final String stockItemName;
  final String category;
  final double quantityChange;
  final double? previousQuantity;
  final double? newQuantity;
  final String unit;
  final String userId;
  final String? userEmail;
  final DateTime timestamp;

  StockHistory({
    required this.id,
    required this.type,
    required this.stockItemId,
    required this.stockItemName,
    required this.category,
    required this.quantityChange,
    this.previousQuantity,
    this.newQuantity,
    required this.unit,
    required this.userId,
    this.userEmail,
    required this.timestamp,
  });

  factory StockHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockHistory(
      id: doc.id,
      type: HistoryType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => HistoryType.update,
      ),
      stockItemId: data['stockItemId'] ?? '',
      stockItemName: data['stockItemName'] ?? '',
      category: data['category'] ?? '',
      quantityChange: (data['quantityChange'] ?? 0).toDouble(),
      previousQuantity: (data['previousQuantity'] as num?)?.toDouble(),
      newQuantity: (data['newQuantity'] as num?)?.toDouble(),
      unit: data['unit'] ?? '',
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'type': type.toString().split('.').last,
      'stockItemId': stockItemId,
      'stockItemName': stockItemName,
      'category': category,
      'quantityChange': quantityChange,
      'unit': unit,
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
    if (userEmail != null) {
      data['userEmail'] = userEmail;
    }
    if (previousQuantity != null) {
      data['previousQuantity'] = previousQuantity;
    }
    if (newQuantity != null) {
      data['newQuantity'] = newQuantity;
    }
    return data;
  }

  String get typeLabel {
    switch (type) {
      case HistoryType.input:
        return 'Input';
      case HistoryType.output:
        return 'Output';
      case HistoryType.update:
        return 'Update';
    }
  }

  String get displayQuantity {
    switch (type) {
      case HistoryType.input:
        return '+${quantityChange.toStringAsFixed(quantityChange.truncateToDouble() == quantityChange ? 0 : 1)} $unit';
      case HistoryType.output:
        return '${quantityChange.toStringAsFixed(quantityChange.truncateToDouble() == quantityChange ? 0 : 1)} $unit';
      case HistoryType.update:
        if (previousQuantity != null && newQuantity != null) {
          return '${previousQuantity!.toStringAsFixed(previousQuantity!.truncateToDouble() == previousQuantity! ? 0 : 1)} → ${newQuantity!.toStringAsFixed(newQuantity!.truncateToDouble() == newQuantity! ? 0 : 1)} $unit';
        }
        return '${quantityChange.toStringAsFixed(quantityChange.truncateToDouble() == quantityChange ? 0 : 1)} $unit';
    }
  }
}

