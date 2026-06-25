import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resto_order/models/order_line_item.dart';
import 'package:resto_order/models/order_status.dart';
import 'package:resto_order/models/restaurant_menu_item.dart';
import 'package:resto_order/models/restaurant_order.dart';
import 'package:resto_order/screens/orders/new_order_screen.dart';
import 'package:resto_order/services/order_service.dart';
import 'package:resto_order/theme/app_theme.dart';

import 'fakes/fake_menu_service.dart';
import 'fakes/fake_order_service.dart';

void main() {
  const chickenBurger = RestaurantMenuItem(
    id: 'menu-chicken',
    name: 'Chicken Burger',
    price: 12.9,
    category: 'Main Dish',
    available: true,
  );

  const icedTea = RestaurantMenuItem(
    id: 'menu-tea',
    name: 'Iced Lemon Tea',
    price: 4.5,
    category: 'Drink',
    available: true,
  );

  Widget buildScreen({
    FakeOrderService? orderService,
    List<RestaurantOrder> orders = const [],
    List<RestaurantMenuItem> menuItems = const [chickenBurger, icedTea],
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: NewOrderScreen(
        orderService:
            orderService ??
            FakeOrderService(ordersStream: Stream.value(orders)),
        menuService: FakeMenuService(menuItemsStream: Stream.value(menuItems)),
      ),
    );
  }

  Future<void> scrollToFinder(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
  }

  Future<void> selectTableAndAddBurger(WidgetTester tester) async {
    await tester.tap(find.text('08'));
    await tester.pump();
    await scrollToFinder(
      tester,
      find.byKey(const ValueKey('add-menu-menu-chicken')),
    );
    await tester.tap(find.byKey(const ValueKey('add-menu-menu-chicken')));
    await tester.pump();
  }

  testWidgets('selects a table and shows it in the confirmation dialog', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await selectTableAndAddBurger(tester);
    await tester.tap(find.byKey(const ValueKey('review-place-order-button')));
    await tester.pumpAndSettle();

    expect(find.text('Confirm Order'), findsOneWidget);
    expect(find.text('Table 08'), findsOneWidget);
  });

  testWidgets('occupied table cannot be selected or submitted', (tester) async {
    const activeOrder = RestaurantOrder(
      id: 'order-8',
      tableNo: 8,
      status: OrderStatus.pending,
      total: 18,
    );

    await tester.pumpWidget(buildScreen(orders: const [activeOrder]));
    await tester.pumpAndSettle();

    expect(find.text('Busy'), findsOneWidget);

    await tester.tap(find.text('08'));
    await tester.pump();
    await scrollToFinder(
      tester,
      find.byKey(const ValueKey('add-menu-menu-chicken')),
    );
    await tester.tap(find.byKey(const ValueKey('add-menu-menu-chicken')));
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('review-place-order-button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('adds, increases, decreases, and removes item quantities', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await scrollToFinder(
      tester,
      find.byKey(const ValueKey('add-menu-menu-chicken')),
    );
    await tester.tap(find.byKey(const ValueKey('add-menu-menu-chicken')));
    await tester.pump();

    expect(find.text('RM 12.90 × 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('increment-menu-menu-chicken')));
    await tester.pump();

    expect(find.text('RM 12.90 × 2'), findsOneWidget);
    expect(find.text('RM 25.80'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('decrement-menu-menu-chicken')));
    await tester.pump();

    expect(find.text('RM 12.90 × 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('decrement-menu-menu-chicken')));
    await tester.pump();

    expect(find.text('No items selected yet.'), findsOneWidget);
  });

  testWidgets('search filters menu items locally', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await scrollToFinder(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'tea');
    await tester.pump();

    expect(find.text('Iced Lemon Tea'), findsOneWidget);
    expect(find.text('Chicken Burger'), findsNothing);
  });

  testWidgets('category chips filter menu items locally', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    final drinkChip = find.widgetWithText(FilterChip, 'Drink');
    await scrollToFinder(tester, drinkChip);
    await tester.tap(drinkChip);
    await tester.pump();

    expect(find.text('Iced Lemon Tea'), findsOneWidget);
    expect(find.text('Chicken Burger'), findsNothing);
  });

  testWidgets('submission is blocked without a table', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await scrollToFinder(
      tester,
      find.byKey(const ValueKey('add-menu-menu-chicken')),
    );
    await tester.tap(find.byKey(const ValueKey('add-menu-menu-chicken')));
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('review-place-order-button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('submission is blocked without menu items', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('08'));
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('review-place-order-button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('saving state prevents double submission', (tester) async {
    final completer = Completer<String>();
    final orderService = FakeOrderService(createOrderFuture: completer.future);

    await tester.pumpWidget(buildScreen(orderService: orderService));
    await tester.pumpAndSettle();

    await selectTableAndAddBurger(tester);
    await tester.tap(find.byKey(const ValueKey('review-place-order-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Place Order'));
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('review-place-order-button')),
    );
    expect(button.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('review-place-order-button')));
    await tester.pump();
    expect(orderService.createOrderCallCount, 1);

    completer.complete('order-created');
    await tester.pumpAndSettle();
  });

  testWidgets('successful order creation calls service once and navigates', (
    tester,
  ) async {
    final orderService = FakeOrderService(
      orderStream: Stream.value(
        RestaurantOrder(
          id: 'created-order-id',
          tableNo: 8,
          status: OrderStatus.pending,
          total: 12.9,
          createdAt: DateTime(2026, 6, 25, 19, 42),
        ),
      ),
      orderItemsStream: Stream.value(const [
        OrderLineItem(
          id: 'line-1',
          orderId: 'created-order-id',
          menuItemId: 'menu-chicken',
          nameSnapshot: 'Chicken Burger',
          priceSnapshot: 12.9,
          quantity: 1,
        ),
      ]),
    );

    await tester.pumpWidget(buildScreen(orderService: orderService));
    await tester.pumpAndSettle();

    await selectTableAndAddBurger(tester);
    await tester.tap(find.byKey(const ValueKey('review-place-order-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Place Order'));
    await tester.pumpAndSettle();

    expect(orderService.hasActiveOrderCallCount, 1);
    expect(orderService.createOrderCallCount, 1);
    expect(orderService.lastTableNo, 8);
    expect(orderService.lastCreatedItems?.single.quantity, 1);
    expect(find.text('Order Detail'), findsWidgets);
    expect(find.text('TABLE 08'), findsOneWidget);
  });

  testWidgets('unavailable item error preserves the cart', (tester) async {
    final orderService = FakeOrderService(
      createOrderError: const OrderServiceException(
        OrderServiceFailure.itemUnavailable,
        'No longer available',
      ),
    );

    await tester.pumpWidget(buildScreen(orderService: orderService));
    await tester.pumpAndSettle();

    await selectTableAndAddBurger(tester);
    await tester.tap(find.byKey(const ValueKey('review-place-order-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Place Order'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'One or more selected items are no longer available. '
        'Please review the order.',
      ),
      findsOneWidget,
    );
    expect(find.text('RM 12.90 × 1'), findsOneWidget);
    expect(find.text('Chicken Burger'), findsWidgets);
  });

  testWidgets('shows no matching menu items when filters remove all results', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await scrollToFinder(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'rendang');
    await tester.pump();

    expect(find.text('No matching menu items'), findsOneWidget);
  });
}
