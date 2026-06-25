import 'package:resto_order/models/order_line_item.dart';
import 'package:resto_order/models/order_status.dart';
import 'package:resto_order/models/restaurant_order.dart';
import 'package:resto_order/services/order_service.dart';

class FakeOrderService implements OrderService {
  FakeOrderService({
    Stream<List<RestaurantOrder>>? ordersStream,
    this.activeTables = const <int>{},
    this.createdOrderId = 'created-order-id',
    this.createOrderError,
    this.createOrderFuture,
  }) : _ordersStream = (ordersStream ?? Stream.value(const <RestaurantOrder>[]))
           .asBroadcastStream();

  final Stream<List<RestaurantOrder>> _ordersStream;
  final Set<int> activeTables;
  final String createdOrderId;
  final Object? createOrderError;
  final Future<String>? createOrderFuture;

  int createOrderCallCount = 0;
  int hasActiveOrderCallCount = 0;
  int? lastTableNo;
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
  }) async {}

  @override
  Stream<RestaurantOrder?> watchOrder(String orderId) => Stream.value(null);

  @override
  Stream<List<OrderLineItem>> watchOrderItems(String orderId) =>
      Stream.value(const <OrderLineItem>[]);

  @override
  Stream<List<RestaurantOrder>> watchOrders() => _ordersStream;
}
