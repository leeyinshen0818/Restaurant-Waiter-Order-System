import 'package:resto_order/models/order_line_item.dart';
import 'package:resto_order/models/order_status.dart';
import 'package:resto_order/models/restaurant_order.dart';
import 'package:resto_order/services/order_service.dart';

class FakeOrderService implements OrderService {
  FakeOrderService({Stream<List<RestaurantOrder>>? ordersStream})
    : _ordersStream = ordersStream ?? Stream.value(const <RestaurantOrder>[]);

  final Stream<List<RestaurantOrder>> _ordersStream;

  @override
  Future<String> createOrder({
    required int tableNo,
    required List<OrderLineItem> items,
  }) {
    throw UnimplementedError();
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
