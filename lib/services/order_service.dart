import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order_line_item.dart';
import '../models/order_status.dart';
import '../models/restaurant_menu_item.dart';
import '../models/restaurant_order.dart';
import '../utils/firestore_collections.dart';

enum OrderServiceFailure {
  invalidInput,
  tableOccupied,
  itemUnavailable,
  statusChanged,
  databaseFailure,
}

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

  static const int minTableNo = 1;
  static const int maxTableNo = 20;
  static const int minQuantity = 1;
  static const int maxQuantity = 99;

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

  Future<bool> hasActiveOrderForTable(
    int tableNo, {
    String? excludingOrderId,
  }) async {
    validateTableNo(tableNo);

    try {
      final snapshot = await _orders
          .where('table_no', isEqualTo: tableNo)
          .get();

      return snapshot.docs.any((document) {
        if (excludingOrderId != null && document.id == excludingOrderId) {
          return false;
        }
        final status = OrderStatus.tryFromFirestore(
          document.data()['status'] as String?,
        );
        return isActiveStatus(status);
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

    try {
      final document = await _orders.doc(orderId).get();
      return document.exists ? RestaurantOrder.fromFirestore(document) : null;
    } on FirebaseException catch (_) {
      throw const OrderServiceException(
        OrderServiceFailure.databaseFailure,
        'Unable to load the order.',
      );
    }
  }

  Future<List<OrderLineItem>> getOrderItems(String orderId) async {
    _requireDocumentId(orderId, 'orderId');

    try {
      final snapshot = await _orderItems
          .where('order_id', isEqualTo: orderId)
          .get();
      return snapshot.docs.map(OrderLineItem.fromFirestore).toList();
    } on FirebaseException catch (_) {
      throw const OrderServiceException(
        OrderServiceFailure.databaseFailure,
        'Unable to load the ordered items.',
      );
    }
  }

  Future<String> createOrder({
    required int tableNo,
    required List<OrderLineItem> items,
  }) async {
    validateTableNo(tableNo);
    final normalizedItems = normalizeNewOrderItems(items);

    // This recheck prevents stale UI selections from creating obvious
    // duplicates. A fully atomic table reservation would require a separate
    // table/reservation document, which is intentionally outside this schema.
    final hasActiveOrder = await hasActiveOrderForTable(tableNo);
    if (hasActiveOrder) {
      throw OrderServiceException(
        OrderServiceFailure.tableOccupied,
        'Table $tableNo already has an active order.',
      );
    }

    final validatedItems = await _validatedLineItems(normalizedItems);
    final orderDocument = _orders.doc();
    final total = validatedItems.fold<double>(
      0,
      (runningTotal, item) => runningTotal + item.subtotal,
    );
    validateOrderTotal(total);
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

  Future<void> updatePendingOrder({
    required String orderId,
    required int tableNo,
    required List<OrderLineItem> items,
  }) async {
    _requireDocumentId(orderId, 'orderId');
    validateTableNo(tableNo);
    validateOrderItemsNotEmpty(items);

    try {
      final existingItemsSnapshot = await _orderItems
          .where('order_id', isEqualTo: orderId)
          .get();
      final orderDocument = _orders.doc(orderId);
      final orderSnapshot = await orderDocument.get();
      if (!orderSnapshot.exists) {
        throw const OrderServiceException(
          OrderServiceFailure.statusChanged,
          'This order can no longer be edited.',
        );
      }

      final order = RestaurantOrder.fromFirestore(orderSnapshot);
      if (order.status != OrderStatus.pending) {
        throw const OrderServiceException(
          OrderServiceFailure.statusChanged,
          'This order can no longer be edited.',
        );
      }

      // Recheck the destination table immediately before writing so a stale
      // edit screen cannot move into a table already active in Firestore.
      final hasAnotherActiveOrder = await hasActiveOrderForTable(
        tableNo,
        excludingOrderId: orderId,
      );
      if (hasAnotherActiveOrder) {
        throw OrderServiceException(
          OrderServiceFailure.tableOccupied,
          'Table $tableNo already has an active order.',
        );
      }

      final existingItemsById = {
        for (final document in existingItemsSnapshot.docs)
          document.id: OrderLineItem.fromFirestore(document),
      };
      final synchronizedItems = await _synchronizedPendingItems(
        items,
        existingItemsById,
      );
      final total = synchronizedItems.fold<double>(
        0,
        (runningTotal, item) => runningTotal + item.subtotal,
      );
      validateOrderTotal(total);

      final batch = _firestore.batch();
      for (final document in existingItemsSnapshot.docs) {
        batch.delete(document.reference);
      }
      for (final item in synchronizedItems) {
        final itemDocument = _orderItems.doc();
        batch.set(itemDocument, {
          'order_id': orderId,
          'menu_item_id': item.menuItemId,
          'name_snapshot': item.nameSnapshot,
          'price_snapshot': item.priceSnapshot,
          'quantity': item.quantity,
        });
      }
      batch.update(orderDocument, {
        'table_no': tableNo,
        'total': total,
        'updated_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } on OrderServiceException {
      rethrow;
    } on FirebaseException catch (_) {
      throw const OrderServiceException(
        OrderServiceFailure.databaseFailure,
        'Unable to update the order.',
      );
    }
  }

  Future<void> deletePendingOrder(String orderId) async {
    _requireDocumentId(orderId, 'orderId');

    try {
      final existingItemsSnapshot = await _orderItems
          .where('order_id', isEqualTo: orderId)
          .get();
      final orderDocument = _orders.doc(orderId);
      final orderSnapshot = await orderDocument.get();
      if (!orderSnapshot.exists) {
        throw const OrderServiceException(
          OrderServiceFailure.statusChanged,
          'This order can no longer be cancelled.',
        );
      }

      final order = RestaurantOrder.fromFirestore(orderSnapshot);
      if (order.status != OrderStatus.pending) {
        throw const OrderServiceException(
          OrderServiceFailure.statusChanged,
          'This order can no longer be cancelled.',
        );
      }

      final batch = _firestore.batch();
      for (final document in existingItemsSnapshot.docs) {
        batch.delete(document.reference);
      }
      batch.delete(orderDocument);
      await batch.commit();
    } on OrderServiceException {
      rethrow;
    } on FirebaseException catch (_) {
      throw const OrderServiceException(
        OrderServiceFailure.databaseFailure,
        'Unable to cancel the order.',
      );
    }
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus nextStatus,
  }) async {
    _requireDocumentId(orderId, 'orderId');
    final orderDocument = _orders.doc(orderId);

    try {
      // The transaction validates against the latest persisted status.
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(orderDocument);
        if (!snapshot.exists) {
          throw const OrderServiceException(
            OrderServiceFailure.statusChanged,
            'This order status has already changed.',
          );
        }

        final statusValue = snapshot.data()?['status'];
        final currentStatus = OrderStatus.tryFromFirestore(
          statusValue is String ? statusValue : null,
        );
        if (currentStatus == null) {
          throw const OrderServiceException(
            OrderServiceFailure.statusChanged,
            'This order status has already changed.',
          );
        }

        final validNextStatus = currentStatus.nextStatus;
        if (validNextStatus == null || nextStatus != validNextStatus) {
          throw const OrderServiceException(
            OrderServiceFailure.statusChanged,
            'This order status has already changed.',
          );
        }

        transaction.update(orderDocument, {
          'status': nextStatus.firestoreValue,
          'updated_at': FieldValue.serverTimestamp(),
        });
      });
    } on OrderServiceException {
      rethrow;
    } on FirebaseException catch (_) {
      throw const OrderServiceException(
        OrderServiceFailure.databaseFailure,
        'Unable to update the order status.',
      );
    }
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

  static void validateTableNo(int tableNo) {
    if (tableNo < minTableNo || tableNo > maxTableNo) {
      throw OrderServiceException(
        OrderServiceFailure.invalidInput,
        'Table number must be between $minTableNo and $maxTableNo.',
      );
    }
  }

  static void validateQuantity(int quantity) {
    if (quantity < minQuantity || quantity > maxQuantity) {
      throw OrderServiceException(
        OrderServiceFailure.invalidInput,
        'Quantity must be between $minQuantity and $maxQuantity.',
      );
    }
  }

  static void validateMoney(double value, String label) {
    if (!value.isFinite || value <= 0) {
      throw OrderServiceException(
        OrderServiceFailure.invalidInput,
        '$label must be greater than zero.',
      );
    }
  }

  static void validateOrderTotal(double total) {
    validateMoney(total, 'Order total');
  }

  static void validateOrderItemsNotEmpty(List<OrderLineItem> items) {
    if (items.isEmpty) {
      throw const OrderServiceException(
        OrderServiceFailure.invalidInput,
        'An order must contain at least one item.',
      );
    }
  }

  static List<OrderLineItem> normalizeNewOrderItems(List<OrderLineItem> items) {
    validateOrderItemsNotEmpty(items);

    final itemsByMenuId = <String, OrderLineItem>{};
    final quantitiesByMenuId = <String, int>{};

    for (final item in items) {
      _requireDocumentId(item.menuItemId, 'menuItemId');
      validateQuantity(item.quantity);

      final runningQuantity =
          (quantitiesByMenuId[item.menuItemId] ?? 0) + item.quantity;
      validateQuantity(runningQuantity);

      itemsByMenuId.putIfAbsent(item.menuItemId, () => item);
      quantitiesByMenuId[item.menuItemId] = runningQuantity;
    }

    return [
      for (final entry in itemsByMenuId.entries)
        entry.value.copyWith(quantity: quantitiesByMenuId[entry.key]),
    ];
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
        validateMoney(menuItem.price, 'Menu item price');

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

  Future<List<OrderLineItem>> _synchronizedPendingItems(
    List<OrderLineItem> items,
    Map<String, OrderLineItem> existingItemsById,
  ) async {
    final accumulators = <String, _PendingLineItemAccumulator>{};

    for (final item in items) {
      _requireDocumentId(item.menuItemId, 'menuItemId');
      validateQuantity(item.quantity);

      final accumulator = accumulators.putIfAbsent(
        item.menuItemId,
        () => _PendingLineItemAccumulator(item),
      );
      accumulator.add(item, existingItemsById[item.id]);
    }

    final synchronizedItems = <OrderLineItem>[];
    for (final accumulator in accumulators.values) {
      validateQuantity(accumulator.quantity);
      final existingItem = accumulator.existingItem;
      if (existingItem != null) {
        validateMoney(existingItem.priceSnapshot, 'Order item price');
        synchronizedItems.add(
          existingItem.copyWith(quantity: accumulator.quantity),
        );
      } else {
        final validatedItem = await _validatedLineItems([
          accumulator.prototype.copyWith(quantity: accumulator.quantity),
        ]);
        synchronizedItems.add(validatedItem.single);
      }
    }

    if (synchronizedItems.isEmpty) {
      validateOrderItemsNotEmpty(synchronizedItems);
    }

    return synchronizedItems;
  }

  static bool isActiveStatus(OrderStatus? status) {
    return switch (status) {
      OrderStatus.pending ||
      OrderStatus.preparing ||
      OrderStatus.served => true,
      OrderStatus.paid || null => false,
    };
  }
}

class _PendingLineItemAccumulator {
  _PendingLineItemAccumulator(this.prototype) : quantity = 0;

  final OrderLineItem prototype;
  int quantity;
  OrderLineItem? existingItem;

  void add(OrderLineItem item, OrderLineItem? matchingExistingItem) {
    quantity += item.quantity;
    existingItem ??= matchingExistingItem;
  }
}
