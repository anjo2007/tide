import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String iconName; // 'work', 'personal', 'shopping', 'health', 'finance', 'ideas'
  final int colorValue; // ARGB int value
  final String? userId;
  final bool isDefault;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    this.userId,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'colorValue': colorValue,
      'userId': userId,
      'isDefault': isDefault,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      iconName: map['iconName'] ?? 'work',
      colorValue: map['colorValue'] ?? 0xFFC5A059,
      userId: map['userId'],
      isDefault: map['isDefault'] ?? false,
    );
  }

  Color get color => Color(colorValue);

  IconData get iconData {
    switch (iconName.toLowerCase()) {
      case 'work':
        return Icons.work_outline_rounded;
      case 'personal':
        return Icons.person_outline_rounded;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'health':
        return Icons.favorite_border_rounded;
      case 'finance':
        return Icons.account_balance_wallet_outlined;
      case 'ideas':
        return Icons.lightbulb_outline_rounded;
      default:
        return Icons.bookmark_border_rounded;
    }
  }

  static List<CategoryModel> get defaultCategories => [
    CategoryModel(id: 'work', name: 'Work', iconName: 'work', colorValue: 0xFFC5A059, isDefault: true),
    CategoryModel(id: 'personal', name: 'Personal', iconName: 'personal', colorValue: 0xFF8E9DB0, isDefault: true),
    CategoryModel(id: 'shopping', name: 'Shopping', iconName: 'shopping', colorValue: 0xFF8E9F8E, isDefault: true),
    CategoryModel(id: 'health', name: 'Health', iconName: 'health', colorValue: 0xFFD69E9E, isDefault: true),
    CategoryModel(id: 'ideas', name: 'Ideas', iconName: 'ideas', colorValue: 0xFFD4AF37, isDefault: true),
  ];
}
