import 'package:resto_order/models/order_line_item.dart';
import 'package:resto_order/models/order_status.dart';
import 'package:resto_order/models/restaurant_order.dart';
import 'package:resto_order/services/order_service.dart';

class FakeOrderService implements OrderService {
  FakeOrderService({
    Stream<List<RestaurantOrder>>? ordersStream,
    Stream<RestaurantOrder?>? orderStream,
    Stream<List<OrderLineItem>>? orderItemsStream,
    this.activeTables = const <int>{},
    this.createdOrderId = 'created-order-id',
    this.createOrderError,
    this.createOrderFuture,
    this.updateOrderStatusError,
    this.updateOrderStatusFuture,
  }) : _ordersStream = (ordersStream ?? Stream.value(const <RestaurantOrder>[]))
           .asBroadcastStream(),
       _orderStream = (orderStream ?? Stream.value(null)).asBroadcastStream(),
       _orderItemsStream =
           (orderItemsStream ?? Stream.value(const <OrderLineItem>[]))
               .asBroadcastStream();

  final Stream<List<RestaurantOrder>> _ordersStream;
  final Stream<RestaurantOrder?> _orderStream;
  final Stream<List<OrderLineItem>> _orderItemsStream;
  final Set<int> activeTables;
  final String createdOrderId;
  final Object? createOrderError;
  final Future<String>? createOrderFuture;
  final Object? updateOrderStatusError;
  final Future<void>? updateOrderStatusFuture;

  int createOrderCallCount = 0;
  int hasActiveOrderCallCount = 0;
  int updateOrderStatusCallCount = 0;
  int? lastTableNo;
  String? lastUpdatedOrderId;
  OrderStatus? lastNextStatus;
  List<OrderLineItem>? lastCreatedItems;

  @override
  Future<bool> hasActiveOrderForTable(int tableNo) async {
    hasActiveOrderCallCount += 1;
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
  Future<RestaurantOrder?> getOrder(String orderId) async => null;

  @override
  Future<List<OrderLineItem>> getOrderItems(String orderId) async => [];

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
