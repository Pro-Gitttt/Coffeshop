import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final List<String> images;
  final String category;
  final bool available;
  final double rating; // average rating
  // Recipe entries to link with stock ingredients
  final List<MenuIngredient> recipe;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.images,
    required this.category,
    required this.available,
    required this.rating,
    required this.recipe,
  });

  factory MenuItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MenuItemModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      images: (data['images'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      category: data['category'] ?? '',
      available: (data['available'] as bool?) ?? true,
      rating: (data['rating'] ?? 0).toDouble(),
      recipe: (data['recipe'] as List?)
              ?.map((e) => MenuIngredient.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'images': images,
      'category': category,
      'available': available,
      'rating': rating,
      'recipe': recipe.map((e) => e.toMap()).toList(),
    };
  }
}

class MenuIngredient {
  final String ingredientId;
  final double qtyNeeded;
  final String unit;

  const MenuIngredient({
    required this.ingredientId,
    required this.qtyNeeded,
    required this.unit,
  });

  factory MenuIngredient.fromMap(Map<String, dynamic> map) {
    return MenuIngredient(
      ingredientId: map['ingredientId'] ?? '',
      qtyNeeded: (map['qtyNeeded'] ?? 0).toDouble(),
      unit: map['unit'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ingredientId': ingredientId,
      'qtyNeeded': qtyNeeded,
      'unit': unit,
    };
  }
}


