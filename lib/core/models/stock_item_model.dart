import 'package:cloud_firestore/cloud_firestore.dart';

class StockItem {
  final String id;
  final String nom;
  final String categorie;
  final double quantite;
  final String unite;
  final String? imageUrl;
  final DateTime misAJourLe;
  final double? shortageThreshold; // Alert threshold

  StockItem({
    required this.id,
    required this.nom,
    required this.categorie,
    required this.quantite,
    required this.unite,
    this.imageUrl,
    required this.misAJourLe,
    this.shortageThreshold,
  });

  factory StockItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockItem(
      id: doc.id,
      nom: data['nom'] ?? '',
      categorie: data['categorie'] ?? '',
      quantite: (data['quantite'] ?? 0).toDouble(),
      unite: data['unite'] ?? '',
      imageUrl: data['imageUrl'],
      misAJourLe: (data['misAJourLe'] as Timestamp?)?.toDate() ?? DateTime.now(),
      shortageThreshold: data['shortageThreshold']?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'nom': nom,
      'categorie': categorie,
      'quantite': quantite,
      'unite': unite,
      'misAJourLe': Timestamp.fromDate(misAJourLe),
    };
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      data['imageUrl'] = imageUrl;
    }
    if (shortageThreshold != null) {
      data['shortageThreshold'] = shortageThreshold;
    }
    return data;
  }

  StockItem copyWith({
    String? id,
    String? nom,
    String? categorie,
    double? quantite,
    String? unite,
    String? imageUrl,
    bool clearImage = false,
    DateTime? misAJourLe,
    double? shortageThreshold,
  }) {
    return StockItem(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      categorie: categorie ?? this.categorie,
      quantite: quantite ?? this.quantite,
      unite: unite ?? this.unite,
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      misAJourLe: misAJourLe ?? this.misAJourLe,
      shortageThreshold: shortageThreshold ?? this.shortageThreshold,
    );
  }

  bool get isLowStock {
    if (shortageThreshold == null) return false;
    return quantite <= shortageThreshold!;
  }
}

