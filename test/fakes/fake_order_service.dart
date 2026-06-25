import 'package:resto_order/models/order_line_item.dart';
import 'package:resto_order/models/order_status.dart';
import 'package:resto_order/models/restaurant_order.dart';
import 'package:resto_order/services/order_service.dart';

class FakeOrderService implements OrderService {
  FakeOrderService({
    Stream<List<RestaurantOrder>>? ordersStream,
    Stream<RestaurantOrder?>? orderStream,
    Stream<List<OrderLineItem>>? orderItemsStream,
    this.order,
    this.orderItems = const <OrderLineItem>[],
    this.activeTables = const <int>{},
    this.createdOrderId = 'created-order-id',
    this.createOrderError,
    this.createOrderFuture,
    this.updateOrderStatusError,
    this.updateOrderStatusFuture,
    this.updatePendingOrderError,
    this.updatePendingOrderFuture,
    this.deletePendingOrderError,
    this.deletePendingOrderFuture,
  }) : _ordersStream = (ordersStream ?? Stream.value(const <RestaurantOrder>[]))
           .asBroadcastStream(),
       _orderStream = (orderStream ?? Stream.value(null)).asBroadcastStream(),
       _orderItemsStream =
           (orderItemsStream ?? Stream.value(const <OrderLineItem>[]))
               .asBroadcastStream();

  final Stream<List<RestaurantOrder>> _ordersStream;
  final Stream<RestaurantOrder?> _orderStream;
  final Stream<List<OrderLineItem>> _orderItemsStream;
  final RestaurantOrder? order;
  final List<OrderLineItem> orderItems;
  final Set<int> activeTables;
  final String createdOrderId;
  final Object? createOrderError;
  final Future<String>? createOrderFuture;
  final Object? updateOrderStatusError;
  final Future<void>? updateOrderStatusFuture;
  final Object? updatePendingOrderError;
  final Future<void>? updatePendingOrderFuture;
  final Object? deletePendingOrderError;
  final Future<void>? deletePendingOrderFuture;

  int createOrderCallCount = 0;
  int hasActiveOrderCallCount = 0;
  int updateOrderStatusCallCount = 0;
  int updatePendingOrderCallCount = 0;
  int deletePendingOrderCallCount = 0;
  int? lastTableNo;
  int? lastEditedTableNo;
  String? lastUpdatedOrderId;
  String? lastEditedOrderId;
  String? lastDeletedOrderId;
  String? lastExcludingOrderId;
  OrderStatus? lastNextStatus;
  List<OrderLineItem>? lastCreatedItems;
  List<OrderLineItem>? lastUpdatedItems;

  @override
  Future<bool> hasActiveOrderForTable(
    int tableNo, {
    String? excludingOrderId,
  }) async {
    hasActiveOrderCallCount += 1;
    lastExcludingOrderId = excludingOrderId;
    return activeTables.contains(tableNo);
  }

  @override
  Future<String> createOrder({
    required int tableNo,
    required List<OrderLineItem> items,
  }) {
    createOrderCallCount += 1;
    lastTableNo = tableNo;
    lastCreatedItems = items;

    final error = createOrderError;
    if (error != null) {
      throw error;
    }

    final future = createOrderFuture;
    if (future != null) {
      return future;
    }

    return Future.value(createdOrderId);
  }

  @override
  Future<RestaurantOrder?> getOrder(String orderId) async => order;

  @override
  Future<List<OrderLineItem>> getOrderItems(String orderId) async => orderItems;

  @override
  Future<void> updatePendingOrder({
    required String orderId,
    required int tableNo,
    required List<OrderLineItem> items,
  }) {
    updatePendingOrderCallCount += 1;
    lastEditedOrderId = orderId;
    lastEditedTableNo = tableNo;
    lastUpdatedItems = items;

    final error = updatePendingOrderError;
    if (error != null) {
      throw error;
    }

    final future = updatePendingOrderFuture;
    if (future != null) {
      return future;
    }

    return Future.value();
  }

  @override
  Future<void> deletePendingOrder(String orderId) {
    deletePendingOrderCallCount += 1;
    lastDeletedOrderId = orderId;

    final error = deletePendingOrderError;
    if (error != null) {
      throw error;
    }

    final future = deletePendingOrderFuture;
    if (future != null) {
      return future;
    }

    return Future.value();
  }

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus nextStatus,
  }) {
    updateOrderStatusCallCount += 1;
    lastUpdatedOrderId = orderId;
    lastNextStatus = nextStatus;

    final error = updateOrderStatusError;
    if (error != null) {
      throw error;
    }

    final future = updateOrderStatusFuture;
    if (future != null) {
      return future;
    }

    return Future.value();
  }

  @override
  Stream<RestaurantOrder?> watchOrder(String orderId) => _orderStream;

  @override
  Stream<List<OrderLineItem>> watchOrderItems(String orderId) =>
      _orderItemsStream;

  @override
  Stream<List<RestaurantOrder>> watchOrders() => _ordersStream;
}
