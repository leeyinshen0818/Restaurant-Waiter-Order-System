import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/restaurant_menu_item.dart';
import '../utils/firestore_collections.dart';

enum MenuServiceFailure { invalidInput, databaseFailure }

class MenuServiceException implements Exception {
  const MenuServiceException(this.failure, this.message);

  final MenuServiceFailure failure;
  final String message;

  @override
  String toString() => message;
}

class MenuService {
  MenuService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _menuItems =>
      _firestore.collection(FirestoreCollections.menuItems);

  Stream<List<RestaurantMenuItem>> watchMenuItems() {
    return _menuItems
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(RestaurantMenuItem.fromFirestore).toList(),
        );
  }

  Stream<List<RestaurantMenuItem>> watchAvailableMenuItems() {
    return _menuItems.where('available', isEqualTo: true).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs
          .map(RestaurantMenuItem.fromFirestore)
          .toList();
      items.sort(_compareByName);
      return items;
    });
  }

  Future<RestaurantMenuItem?> getMenuItem(String id) async {
    _requireDocumentId(id);

    try {
      final document = await _menuItems.doc(id).get();
      return document.exists
          ? RestaurantMenuItem.fromFirestore(document)
          : null;
    } on FirebaseException catch (_) {
      throw const MenuServiceException(
        MenuServiceFailure.databaseFailure,
        'Unable to load the menu item.',
      );
    }
  }

  Future<String> addMenuItem(RestaurantMenuItem item) async {
    validateMenuItem(item, requireId: false);
    final document = _menuItems.doc();
    final data = item.toMap()
      ..['created_at'] = FieldValue.serverTimestamp()
      ..['updated_at'] = FieldValue.serverTimestamp();

    try {
      await document.set(data);
      return document.id;
    } on FirebaseException catch (_) {
      throw const MenuServiceException(
        MenuServiceFailure.databaseFailure,
        'Unable to add the menu item.',
      );
    }
  }

  Future<void> updateMenuItem(RestaurantMenuItem item) async {
    validateMenuItem(item, requireId: true);

    final data = item.toMap()
      ..remove('created_at')
      ..['updated_at'] = FieldValue.serverTimestamp();

    try {
      await _menuItems.doc(item.id).update(data);
    } on FirebaseException catch (_) {
      throw const MenuServiceException(
        MenuServiceFailure.databaseFailure,
        'Unable to update the menu item.',
      );
    }
  }

  Future<void> updateAvailability(String id, bool available) async {
    _requireDocumentId(id);

    try {
      await _menuItems.doc(id).update({
        'available': available,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (_) {
      throw const MenuServiceException(
        MenuServiceFailure.databaseFailure,
        'Unable to update item availability.',
      );
    }
  }

  Future<void> deleteMenuItem(String id) async {
    _requireDocumentId(id);
    try {
      await _menuItems.doc(id).delete();
    } on FirebaseException catch (_) {
      throw const MenuServiceException(
        MenuServiceFailure.databaseFailure,
        'Unable to delete the menu item.',
      );
    }
  }

  static int _compareByName(
    RestaurantMenuItem first,
    RestaurantMenuItem second,
  ) {
    return first.name.toLowerCase().compareTo(second.name.toLowerCase());
  }

  static void _requireDocumentId(String id) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Document ID cannot be empty.');
    }
  }

  static void validateMenuItem(
    RestaurantMenuItem item, {
    bool requireId = false,
  }) {
    if (requireId) {
      _requireDocumentId(item.id);
    }
    if (item.name.trim().isEmpty) {
      throw const MenuServiceException(
        MenuServiceFailure.invalidInput,
        'Menu item name is required.',
      );
    }
    if (item.category.trim().isEmpty) {
      throw const MenuServiceException(
        MenuServiceFailure.invalidInput,
        'Menu item category is required.',
      );
    }
    if (!item.price.isFinite || item.price <= 0) {
      throw const MenuServiceException(
        MenuServiceFailure.invalidInput,
        'Menu item price must be greater than zero.',
      );
    }
  }
}
