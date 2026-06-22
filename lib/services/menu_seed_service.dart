import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/restaurant_menu_item.dart';
import '../utils/firestore_collections.dart';

class MenuSeedSkippedException implements Exception {
  const MenuSeedSkippedException();

  @override
  String toString() => 'Menu seeding skipped because menu items already exist.';
}

class MenuSeedService {
  MenuSeedService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const List<RestaurantMenuItem> sampleMenuItems = [
    RestaurantMenuItem(
      id: '',
      name: 'Nasi Goreng Kampung',
      price: 10.90,
      category: 'Main Dish',
      available: true,
    ),
    RestaurantMenuItem(
      id: '',
      name: 'Chicken Chop',
      price: 16.90,
      category: 'Main Dish',
      available: true,
    ),
    RestaurantMenuItem(
      id: '',
      name: 'Mee Goreng Mamak',
      price: 9.90,
      category: 'Main Dish',
      available: true,
    ),
    RestaurantMenuItem(
      id: '',
      name: 'Fish and Chips',
      price: 18.90,
      category: 'Main Dish',
      available: false,
    ),
    RestaurantMenuItem(
      id: '',
      name: 'Chicken Burger',
      price: 12.90,
      category: 'Main Dish',
      available: true,
    ),
    RestaurantMenuItem(
      id: '',
      name: 'French Fries',
      price: 6.50,
      category: 'Side Dish',
      available: true,
    ),
    RestaurantMenuItem(
      id: '',
      name: 'Chicken Nuggets',
      price: 7.90,
      category: 'Side Dish',
      available: true,
    ),
    RestaurantMenuItem(
      id: '',
      name: 'Garlic Bread',
      price: 5.50,
      category: 'Side Dish',
      available: true,
    ),
    RestaurantMenuItem(
      id: '',
      name: 'Iced Lemon Tea',
      price: 4.50,
      category: 'Drink',
      available: true,
    ),
    RestaurantMenuItem(
      id: '',
      name: 'Teh Tarik',
      price: 3.50,
      category: 'Drink',
      available: true,
    ),
    RestaurantMenuItem(
      id: '',
      name: 'Iced Milo',
      price: 4.90,
      category: 'Drink',
      available: true,
    ),
    RestaurantMenuItem(
      id: '',
      name: 'Mineral Water',
      price: 2.00,
      category: 'Drink',
      available: true,
    ),
    RestaurantMenuItem(
      id: '',
      name: 'Chocolate Cake',
      price: 7.90,
      category: 'Dessert',
      available: true,
    ),
    RestaurantMenuItem(
      id: '',
      name: 'Ice Cream Sundae',
      price: 6.50,
      category: 'Dessert',
      available: true,
    ),
    RestaurantMenuItem(
      id: '',
      name: 'Caramel Pudding',
      price: 5.90,
      category: 'Dessert',
      available: true,
    ),
  ];

  Future<int> seedMenuIfEmpty() async {
    if (!kDebugMode) {
      throw UnsupportedError('Menu seeding is available only in debug mode.');
    }

    final menuItems = _firestore.collection(FirestoreCollections.menuItems);
    final existingItems = await menuItems.limit(1).get();
    if (existingItems.docs.isNotEmpty) {
      throw const MenuSeedSkippedException();
    }

    final batch = _firestore.batch();

    // All sample records are created together, or none are created.
    for (final item in sampleMenuItems) {
      batch.set(menuItems.doc(), {
        'name': item.name,
        'price': item.price,
        'category': item.category,
        'available': item.available,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    return sampleMenuItems.length;
  }
}
