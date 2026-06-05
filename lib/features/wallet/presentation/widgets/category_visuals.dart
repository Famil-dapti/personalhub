import 'package:flutter/material.dart';

import '../../data/models/category_model.dart';

// Maps preset icon identifiers (stored as strings in DB) to const IconData.
// Static map is required: Flutter tree-shakes icons, so dynamic lookup by name fails.
const Map<String, IconData> _iconByName = {
  'restaurant': Icons.restaurant,
  'shopping_cart': Icons.shopping_cart,
  'directions_car': Icons.directions_car,
  'receipt_long': Icons.receipt_long,
  'movie': Icons.movie,
  'medical_services': Icons.medical_services,
  'shopping_bag': Icons.shopping_bag,
  'home': Icons.home,
  'more_horiz': Icons.more_horiz,
  'payments': Icons.payments,
  'attach_money': Icons.attach_money,
  'card_giftcard': Icons.card_giftcard,
};

IconData categoryIcon(Category? category) {
  return _iconByName[category?.icon] ?? Icons.label_outline;
}

Color categoryColor(Category? category, Color fallback) {
  final hex = category?.color;
  if (hex == null) return fallback;
  return _parseHexColor(hex) ?? fallback;
}

Color? _parseHexColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  if (cleaned.length != 6) return null;
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}

// Picker options for creating custom categories (icon name + display glyph).
const List<String> selectableIconNames = [
  'restaurant',
  'shopping_cart',
  'directions_car',
  'receipt_long',
  'movie',
  'medical_services',
  'shopping_bag',
  'home',
  'payments',
  'attach_money',
  'card_giftcard',
  'more_horiz',
];

IconData iconForName(String name) => _iconByName[name] ?? Icons.label_outline;
