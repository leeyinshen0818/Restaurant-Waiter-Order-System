import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order_line_item.dart';
import '../models/order_status.dart';
import '../models/restaurant_order.dart';
import '../utils/firestore_collections.dart';

class OrderService {
  OrderService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection(FirestoreCollections.orders);

  CollectionReference<Map<String, dynamic>> get _orderItems =>
      _firestore.collection(FirestoreCollections.orderItems);

  Stream<List<RestaurantOrder>> watchOrders() {
    return _orders
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(RestaurantOrder.fromFirestore).toList(),
        );
  }

  Stream<RestaurantOrder?> watchOrder(String orderId) {
    _requireDocumentId(orderId, 'orderId');

    return _orders
        .doc(orderId)
        .snapshots()
        .map(
          (document) =>
              document.exists ? RestaurantOrder.fromFirestore(document) : null,
        );
  }

  Stream<List<OrderLineItem>> watchOrderItems(String orderId) {
    _requireDocumentId(orderId, 'orderId');

    return _orderItems
        .where('order_id', isEqualTo: orderId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(OrderLineItem.fromFirestore).toList(),
        );
  }

  Future<RestaurantOrder?> getOrder(String orderId) async {
    _requireDocumentId(orderId, 'orderId');

    final document = await _orders.doc(orderId).get();
    return document.exists ? RestaurantOrder.fromFirestore(document) : null;
  }

  Future<List<OrderLineItem>> getOrderItems(String orderId) async {
    _requireDocumentId(orderId, 'orderId');

    final snapshot = await _orderItems
        .where('order_id', isEqualTo: orderId)
        .get();
    return snapshot.docs.map(OrderLineItem.fromFirestore).toList();
  }

  Future<String> createOrder({
    required int tableNo,
    required List<OrderLineItem> items,
  }) async {
    if (tableNo < 1) {
      throw ArgumentError.value(
        tableNo,
        'tableNo',
        'Table number must be at least 1.',
      );
    }
    if (items.isEmpty) {
      throw ArgumentError.value(
        items,
        'items',
        'An order must contain at least one item.',
      );
    }

    for (final item in items) {
      if (item.quantity < 1) {
        throw ArgumentError.value(
          item.quantity,
          'items',
          'Every order item quantity must be at least 1.',
        );
      }
    }

    final orderDocument = _orders.doc();
    final total = items.fold<double>(
      0,
      (runningTotal, item) => runningTotal + item.subtotal,
    );
    final batch = _firestore.batch();

    batch.set(orderDocument, {
      'table_no': tableNo,
      'status': OrderStatus.pending.firestoreValue,
      'total': total,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    // The order and all immutable line-item snapshots commit atomically.
    for (final item in items) {
      final itemDocument = _orderItems.doc();
      batch.set(itemDocument, {
        'order_id': orderDocument.id,
        'menu_item_id': item.menuItemId,
        'name_snapshot': item.nameSnapshot,
        'price_snapshot': item.priceSnapshot,
        'quantity': item.quantity,
      });
    }

    await batch.commit();
    return orderDocument.id;
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus nextStatus,
  }) async {
    _requireDocumentId(orderId, 'orderId');
    final orderDocument = _orders.doc(orderId);

    // The transaction validates against the latest persisted status.
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(orderDocument);
      if (!snapshot.exists) {
        throw StateError('Order "$orderId" does not exist.');
      }

      final statusValue = snapshot.data()?['status'];
      final currentStatus = OrderStatus.tryFromFirestore(
        statusValue is String ? statusValue : null,
      );
      if (currentStatus == null) {
        throw StateError(
          'Order "$orderId" has an unknown status: "$statusValue".',
        );
      }

      final validNextStatus = currentStatus.nextStatus;
      if (validNextStatus == null) {
        throw StateError('Order "$orderId" is already Paid.');
      }
      if (nextStatus != validNextStatus) {
        throw StateError(
          'Invalid order status transition from '
          '${currentStatus.displayLabel} to ${nextStatus.displayLabel}. '
          'The next status must be ${validNextStatus.displayLabel}.',
        );
      }

      transaction.update(orderDocument, {
        'status': nextStatus.firestoreValue,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  static void _requireDocumentId(String id, String parameterName) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(
        id,
        parameterName,
        'Document ID cannot be empty.',
      );
    }
  }
}
