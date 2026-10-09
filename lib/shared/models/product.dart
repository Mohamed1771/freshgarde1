import 'package:flutter/material.dart';

enum ProductCategory {
  vegetables('خضروات'),
  fruits('فواكه');

  const ProductCategory(this.label);
  final String label;
}

/// A tradable produce type with its cold-chain targets.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.category,
    required this.optimalTempC,
    required this.optimalHumidity,
  });

  final String id;
  final String name;
  final String emoji;
  final Color color;
  final ProductCategory category;
  final double optimalTempC;
  final double optimalHumidity;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) => other is Product && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

/// Catalogue of supported products (Jordanian export staples).
abstract final class Products {
  static const tomato = Product(id: 'tomato', name: 'بندورة', emoji: '🍅', color: Color(0xFFE5533D), category: ProductCategory.vegetables, optimalTempC: 12, optimalHumidity: 90);
  static const cucumber = Product(id: 'cucumber', name: 'خيار', emoji: '🥒', color: Color(0xFF4E9F3D), category: ProductCategory.vegetables, optimalTempC: 11, optimalHumidity: 92);
  static const pepper = Product(id: 'pepper', name: 'فلفل حلو', emoji: '🫑', color: Color(0xFF3FA34D), category: ProductCategory.vegetables, optimalTempC: 8, optimalHumidity: 92);
  static const potato = Product(id: 'potato', name: 'بطاطا', emoji: '🥔', color: Color(0xFFC49A5A), category: ProductCategory.vegetables, optimalTempC: 7, optimalHumidity: 92);
  static const eggplant = Product(id: 'eggplant', name: 'باذنجان', emoji: '🍆', color: Color(0xFF6A3D8F), category: ProductCategory.vegetables, optimalTempC: 11, optimalHumidity: 92);
  static const zucchini = Product(id: 'zucchini', name: 'كوسا', emoji: '🥬', color: Color(0xFF7DAE4A), category: ProductCategory.vegetables, optimalTempC: 8, optimalHumidity: 93);
  static const lemon = Product(id: 'lemon', name: 'ليمون', emoji: '🍋', color: Color(0xFFE8C431), category: ProductCategory.fruits, optimalTempC: 11, optimalHumidity: 88);
  static const strawberry = Product(id: 'strawberry', name: 'فراولة', emoji: '🍓', color: Color(0xFFD7263D), category: ProductCategory.fruits, optimalTempC: 2, optimalHumidity: 92);
  static const watermelon = Product(id: 'watermelon', name: 'بطيخ', emoji: '🍉', color: Color(0xFF2E8B57), category: ProductCategory.fruits, optimalTempC: 12, optimalHumidity: 88);
  static const dates = Product(id: 'dates', name: 'تمر مجهول', emoji: '🌴', color: Color(0xFF8B5A2B), category: ProductCategory.fruits, optimalTempC: 4, optimalHumidity: 70);

  static const all = [tomato, cucumber, pepper, potato, eggplant, zucchini, lemon, strawberry, watermelon, dates];

  static Product byId(String id) => all.firstWhere((p) => p.id == id, orElse: () => tomato);

  /// Loose name matching used to map AI labels (English or Arabic) back to the catalogue.
  static Product? match(String label) {
    final l = label.toLowerCase().trim();
    for (final p in all) {
      if (p.id == l || p.name == label.trim() || l.contains(p.id)) return p;
    }
    return null;
  }
}
