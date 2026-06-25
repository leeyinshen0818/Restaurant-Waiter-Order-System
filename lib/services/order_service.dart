import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order_line_item.dart';
import '../models/order_status.dart';
import '../models/restaurant_menu_item.dart';
import '../models/restaurant_order.dart';
import '../utils/firestore_collections.dart';

enum OrderServiceFailure { tableOccupied, itemUnavailable, databaseFailure }

class OrderServiceException implements Exception {
  const OrderServiceException(this.failure, this.message);

  final OrderServiceFailure failure;
  final String message;

  @override
  String toString() => message;
}

class OrderService {
  OrderService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection(FirestoreCollections.orders);

  CollectionReference<Map<String, dynamic>> get _orderItems =>
      _firestore.collection(FirestoreCollections.orderItems);

  CollectionReference<Map<String, dynamic>> get _menuItems =>
      _firestore.collection(FirestoreCollections.menuItems);

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

  Future<bool> hasActiveOrderForTable(int tableNo) async {
    if (tableNo < 1) {
      throw ArgumentError.value(
        tableNo,
        'tableNo',
        'Table number must be at least 1.',
      );
    }

    try {
      final snapshot = await _orders
          .where('table_no', isEqualTo: tableNo)
          .get();

      return snapshot.docs.any((document) {
        final status = OrderStatus.tryFromFirestore(
          document.data()['status'] as String?,
        );
        return _isActiveStatus(status);
      });
    } on FirebaseException catch (_) {
      throw const OrderServiceException(
        OrderServiceFailure.databaseFailure,
        'Unable to verify table availability.',
      );
    }
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
      _requireDocumentId(item.menuItemId, 'menuItemId');
      if (item.quantity < 1) {
        throw ArgumentError.value(
          item.quantity,
          'items',
          'Every order item quantity must be at least 1.',
        );
      }
    }

    final hasActiveOrder = await hasActiveOrderForTable(tableNo);
    if (hasActiveOrder) {
      throw OrderServiceException(
        OrderServiceFailure.tableOccupied,
        'Table $tableNo already has an active order.',
      );
    }

    final validatedItems = await _validatedLineItems(items);
    final orderDocument = _orders.doc();
    final total = validatedItems.fold<double>(
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
    for (final item in validatedItems) {
      final itemDocument = _orderItems.doc();
      batch.set(itemDocument, {
        'order_id': orderDocument.id,
        'menu_item_id': item.menuItemId,
        'name_snapshot': item.nameSnapshot,
        'price_snapshot': item.priceSnapshot,
        'quantity': item.quantity,
      });
    }

    try {
      await batch.commit();
    } on FirebaseException catch (_) {
      throw const OrderServiceException(
        OrderServiceFailure.databaseFailure,
        'Unable to create the order.',
      );
    }
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

  Future<List<OrderLineItem>> _validatedLineItems(
    List<OrderLineItem> items,
  ) async {
    final validatedItems = <OrderLineItem>[];

    try {
      for (final item in items) {
        final document = await _menuItems.doc(item.menuItemId).get();
        if (!document.exists) {
          throw const OrderServiceException(
            OrderServiceFailure.itemUnavailable,
            'One or more selected items are no longer available.',
          );
        }

        final menuItem = RestaurantMenuItem.fromFirestore(document);
        if (!menuItem.available) {
          throw const OrderServiceException(
            OrderServiceFailure.itemUnavailable,
            'One or more selected items are no longer available.',
          );
        }

        validatedItems.add(
          item.copyWith(
            nameSnapshot: menuItem.name,
            priceSnapshot: menuItem.price,
          ),
        );
      }
    } on OrderServiceException {
      rethrow;
    } on FirebaseException catch (_) {
      throw const OrderServiceException(
        OrderServiceFailure.databaseFailure,
        'Unable to validate selected menu items.',
      );
    }

    return validatedItems;
  }

  static bool _isActiveStatus(OrderStatus? status) {
    return switch (status) {
      OrderStatus.pending ||
      OrderStatus.preparing ||
      OrderStatus.served => true,
      OrderStatus.paid || null => false,
    };
  }
}
