import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resto_order/models/order_status.dart';
import 'package:resto_order/models/restaurant_menu_item.dart';
import 'package:resto_order/models/restaurant_order.dart';
import 'package:resto_order/screens/orders/orders_list_screen.dart';
import 'package:resto_order/theme/app_theme.dart';

import 'fakes/fake_menu_service.dart';
import 'fakes/fake_order_service.dart';

void main() {
  const availableItem = RestaurantMenuItem(
    id: 'menu-1',
    name: 'Chicken Burger',
    price: 12.9,
    category: 'Main Dish',
    available: true,
  );

  Widget buildScreen({
    List<RestaurantOrder> orders = const [],
    List<RestaurantMenuItem> availableItems = const [availableItem],
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: OrdersListScreen(
        orderService: FakeOrderService(ordersStream: Stream.value(orders)),
        menuService: FakeMenuService(
          menuItemsStream: Stream.value(availableItems),
        ),
      ),
    );
  }

  final orders = [
    RestaurantOrder(
      id: 'pending-1',
      tableNo: 8,
      status: OrderStatus.pending,
      total: 38.5,
      createdAt: DateTime(2026, 6, 23, 19, 42),
    ),
    RestaurantOrder(
      id: 'preparing-1',
      tableNo: 3,
      status: OrderStatus.preparing,
      total: 22,
      createdAt: DateTime(2026, 6, 23, 20),
    ),
  ];

  testWidgets('shows the empty orders state', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('No orders yet'), findsOneWidget);
    expect(
      find.text('Create a new order when a customer is ready.'),
      findsOneWidget,
    );
  });

  testWidgets('shows status labels, table number, and total', (tester) async {
    await tester.pumpWidget(buildScreen(orders: orders));
    await tester.pumpAndSettle();

    expect(find.text('TABLE 08'), findsOneWidget);
    expect(find.text('RM 38.50'), findsOneWidget);
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Preparing'), findsWidgets);
    expect(find.text('All 2'), findsOneWidget);
    expect(find.text('Pending 1'), findsOneWidget);
    expect(find.text('Preparing 1'), findsOneWidget);
    expect(find.text('Served 0'), findsOneWidget);
    expect(find.text('History 0'), findsOneWidget);
  });

  testWidgets('filters orders by status', (tester) async {
    await tester.pumpWidget(buildScreen(orders: orders));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Preparing 1'));
    await tester.pump();

    expect(find.text('TABLE 03'), findsOneWidget);
    expect(find.text('TABLE 08'), findsNothing);
  });

  testWidgets('shows a filtered empty state', (tester) async {
    await tester.pumpWidget(buildScreen(orders: orders));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Served 0'));
    await tester.pump();

    expect(find.text('No Served orders'), findsOneWidget);
    expect(
      find.text('There are no orders with this status right now.'),
      findsOneWidget,
    );
  });

  testWidgets('opens New Order when menu items are available', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('New Order'));
    await tester.pumpAndSettle();

    expect(find.text('Select a table and add menu items'), findsOneWidget);
  });

  testWidgets('opens Order Detail from an order card', (tester) async {
    final order = orders.first;
    final orderService = FakeOrderService(
      ordersStream: Stream.value([order]),
      orderStream: Stream.value(order),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: OrdersListScreen(
          orderService: orderService,
          menuService: FakeMenuService(
            menuItemsStream: Stream.value(const [availableItem]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('TABLE 08'));
    await tester.pumpAndSettle();

    expect(find.text('Order Detail'), findsOneWidget);
    expect(find.text('TABLE 08'), findsOneWidget);
  });

  testWidgets('blocks New Order when no menu items are available', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen(availableItems: const []));
    await tester.pumpAndSettle();

    expect(find.text('No available menu items'), findsOneWidget);

    await tester.tap(find.text('New Order'));
    await tester.pump();

    expect(
      find.text('Add or enable menu items before creating an order.'),
      findsNWidgets(2),
    );
    expect(find.text('Select a table and add menu items'), findsNothing);
  });

  testWidgets('moves paid orders out of All and into History', (tester) async {
    final paidOrder = RestaurantOrder(
      id: 'paid-1',
      tableNo: 9,
      status: OrderStatus.paid,
      total: 18.9,
      createdAt: DateTime(2026, 6, 23, 21),
    );

    await tester.pumpWidget(buildScreen(orders: [...orders, paidOrder]));
    await tester.pumpAndSettle();

    expect(find.text('All 2'), findsOneWidget);
    expect(find.text('History 1'), findsOneWidget);
    expect(find.text('TABLE 09'), findsNothing);

    await tester.tap(find.text('History 1'));
    await tester.pump();

    expect(find.text('TABLE 09'), findsOneWidget);
    expect(find.text('TABLE 08'), findsNothing);
  });
}
