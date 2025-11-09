import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pending, preparing, ready, completed, cancelled }

class OrderItem {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final Map<String, dynamic>? options; // e.g., size, extra sugar

  const OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.options,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      menuItemId: map['menuItemId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 0) as int,
      options: map['options'] == null ? null : Map<String, dynamic>.from(map['options'] as Map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      if (options != null) 'options': options,
    };
  }
}

class OrderModel {
  final String id;
  final String customerId;
  final List<OrderItem> items;
  final double totalPrice;
  final OrderStatus status;
  final String orderType; // Dine-in | Takeaway
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.orderType,
    required this.createdAt,
    required this.updatedAt,
  });

  OrderModel copyWith({
    String? id,
    String? customerId,
    List<OrderItem>? items,
    double? totalPrice,
    OrderStatus? status,
    String? orderType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      orderType: orderType ?? this.orderType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      items: (data['items'] as List?)
              ?.map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      status: _statusFromString(data['status'] as String?),
      orderType: data['orderType'] ?? 'Takeaway',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'items': items.map((e) => e.toMap()).toList(),
      'totalPrice': totalPrice,
      'status': status.name[0].toUpperCase() + status.name.substring(1),
      'orderType': orderType,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

OrderStatus _statusFromString(String? status) {
  switch ((status ?? 'Pending').toLowerCase()) {
    case 'pending':
      return OrderStatus.pending;
    case 'preparing':
      return OrderStatus.preparing;
    case 'ready':
      return OrderStatus.ready;
    case 'completed':
      return OrderStatus.completed;
    case 'cancelled':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.pending;
  }
}


