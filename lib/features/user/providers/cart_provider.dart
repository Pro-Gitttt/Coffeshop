import 'package:flutter/material.dart';
import '../../../core/models/order_model.dart';
import '../../../core/models/menu_item_model.dart';

class CartProvider extends ChangeNotifier {
  final List<OrderItem> _items = [];

  List<OrderItem> get items => List.unmodifiable(_items);

  double get totalPrice => _items.fold(0, (sum, it) => sum + it.price * it.quantity);

  void add(MenuItemModel menuItem, {int quantity = 1, Map<String, dynamic>? options}) {
    final index = _items.indexWhere((e) => e.menuItemId == menuItem.id && _deepEquals(e.options, options));
    if (index >= 0) {
      final existing = _items[index];
      _items[index] = OrderItem(
        menuItemId: existing.menuItemId,
        name: existing.name,
        price: existing.price,
        quantity: existing.quantity + quantity,
        options: existing.options,
      );
    } else {
      _items.add(OrderItem(
        menuItemId: menuItem.id,
        name: menuItem.name,
        price: menuItem.price,
        quantity: quantity,
        options: options,
      ));
    }
    notifyListeners();
  }

  void removeAt(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  bool _deepEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || b[key] != a[key]) return false;
    }
    return true;
  }
}


