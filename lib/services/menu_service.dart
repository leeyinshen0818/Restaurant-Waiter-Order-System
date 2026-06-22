import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/restaurant_menu_item.dart';
import '../utils/firestore_collections.dart';

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

    final document = await _menuItems.doc(id).get();
    return document.exists ? RestaurantMenuItem.fromFirestore(document) : null;
  }

  Future<String> addMenuItem(RestaurantMenuItem item) async {
    final document = _menuItems.doc();
    final data = item.toMap()
      ..['created_at'] = FieldValue.serverTimestamp()
      ..['updated_at'] = FieldValue.serverTimestamp();

    await document.set(data);
    return document.id;
  }

  Future<void> updateMenuItem(RestaurantMenuItem item) async {
    _requireDocumentId(item.id);

    final data = item.toMap()
      ..remove('created_at')
      ..['updated_at'] = FieldValue.serverTimestamp();

    await _menuItems.doc(item.id).update(data);
  }

  Future<void> updateAvailability(String id, bool available) async {
    _requireDocumentId(id);

    await _menuItems.doc(id).update({
      'available': available,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMenuItem(String id) async {
    _requireDocumentId(id);
    await _menuItems.doc(id).delete();
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
}
