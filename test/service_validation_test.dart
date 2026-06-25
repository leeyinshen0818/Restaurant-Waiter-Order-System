import 'package:flutter_test/flutter_test.dart';
import 'package:resto_order/models/order_line_item.dart';
import 'package:resto_order/models/order_status.dart';
import 'package:resto_order/models/restaurant_menu_item.dart';
import 'package:resto_order/services/menu_service.dart';
import 'package:resto_order/services/order_service.dart';

void main() {
  OrderLineItem lineItem({
    String id = '',
    String menuItemId = 'menu-1',
    double price = 10,
    int quantity = 1,
  }) {
    return OrderLineItem(
      id: id,
      orderId: '',
      menuItemId: menuItemId,
      nameSnapshot: 'Menu Item',
      priceSnapshot: price,
      quantity: quantity,
    );
  }

  group('OrderService validation', () {
    test('rejects table numbers outside 1 to 20', () {
      expect(
        () => OrderService.validateTableNo(0),
        throwsA(isA<OrderServiceException>()),
      );
      expect(
        () => OrderService.validateTableNo(21),
        throwsA(isA<OrderServiceException>()),
      );
      expect(() => OrderService.validateTableNo(1), returnsNormally);
      expect(() => OrderService.validateTableNo(20), returnsNormally);
    });

    test('rejects invalid quantities', () {
      for (final quantity in [0, -1, 100]) {
        expect(
          () => OrderService.validateQuantity(quantity),
          throwsA(isA<OrderServiceException>()),
        );
      }
      expect(() => OrderService.validateQuantity(1), returnsNormally);
      expect(() => OrderService.validateQuantity(99), returnsNormally);
    });

    test('rejects empty orders', () {
      expect(
        () => OrderService.normalizeNewOrderItems(const []),
        throwsA(isA<OrderServiceException>()),
      );
    });

    test('merges duplicate line items by menu item ID', () {
      final normalized = OrderService.normalizeNewOrderItems([
        lineItem(menuItemId: 'menu-1', quantity: 1),
        lineItem(menuItemId: 'menu-1', quantity: 2),
        lineItem(menuItemId: 'menu-2', quantity: 4),
      ]);

      expect(normalized, hasLength(2));
      expect(
        normalized.singleWhere((item) => item.menuItemId == 'menu-1').quantity,
        3,
      );
      expect(
        normalized.singleWhere((item) => item.menuItemId == 'menu-2').quantity,
        4,
      );
    });

    test('rejects merged quantities above 99', () {
      expect(
        () => OrderService.normalizeNewOrderItems([
          lineItem(menuItemId: 'menu-1', quantity: 60),
          lineItem(menuItemId: 'menu-1', quantity: 40),
        ]),
        throwsA(isA<OrderServiceException>()),
      );
    });

    test('rejects invalid monetary values', () {
      for (final price in [0.0, -1.0, double.nan, double.infinity]) {
        expect(
          () => OrderService.validateMoney(price, 'Order item price'),
          throwsA(isA<OrderServiceException>()),
        );
      }
      expect(
        () => OrderService.validateMoney(0.01, 'Order item price'),
        returnsNormally,
      );
    });

    test('active status helper treats Paid as inactive', () {
      expect(OrderService.isActiveStatus(OrderStatus.pending), isTrue);
      expect(OrderService.isActiveStatus(OrderStatus.preparing), isTrue);
      expect(OrderService.isActiveStatus(OrderStatus.served), isTrue);
      expect(OrderService.isActiveStatus(OrderStatus.paid), isFalse);
      expect(OrderService.isActiveStatus(null), isFalse);
    });

    test('unknown status is handled safely', () {
      expect(OrderStatus.tryFromFirestore('Ready'), isNull);
      expect(OrderStatus.fromFirestore('Ready'), OrderStatus.pending);
    });

    test('lifecycle only exposes the next valid status', () {
      expect(OrderStatus.pending.nextStatus, OrderStatus.preparing);
      expect(OrderStatus.preparing.nextStatus, OrderStatus.served);
      expect(OrderStatus.served.nextStatus, OrderStatus.paid);
      expect(OrderStatus.paid.nextStatus, isNull);
    });
  });

  group('MenuService validation', () {
    RestaurantMenuItem menuItem({double price = 10}) {
      return RestaurantMenuItem(
        id: 'menu-1',
        name: 'Chicken Burger',
        price: price,
        category: 'Main Dish',
        available: true,
      );
    }

    test('rejects invalid menu prices', () {
      for (final price in [0.0, -5.0, double.nan, double.infinity]) {
        expect(
          () => MenuService.validateMenuItem(menuItem(price: price)),
          throwsA(isA<MenuServiceException>()),
        );
      }
    });

    test('accepts valid menu item data', () {
      expect(
        () => MenuService.validateMenuItem(menuItem(price: 12.9)),
        returnsNormally,
      );
    });
  });
}
