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

  const editedOrder = RestaurantOrder(
    id: 'order-1',
    tableNo: 5,
    status: OrderStatus.pending,
    total: 19.99,
  );

  const editedBurger = OrderLineItem(
    id: 'line-burger',
    orderId: 'order-1',
    menuItemId: 'menu-chicken',
    nameSnapshot: 'Old Burger Snapshot',
    priceSnapshot: 9.99,
    quantity: 2,
  );

  Widget buildScreen({
    FakeOrderService? orderService,
    String? orderId,
    List<RestaurantOrder> orders = const [],
    List<RestaurantMenuItem> menuItems = const [chickenBurger, icedTea],
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: NewOrderScreen(
        orderId: orderId,
        orderService:
            orderService ??
            FakeOrderService(ordersStream: Stream.value(orders)),
        menuService: FakeMenuService(menuItemsStream: Stream.value(menuItems)),
      ),
    );
  }

  Future<void> scrollToFinder(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
  }

  Future<void> openMenuTab(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('new-order-tab-menu')));
    await tester.pumpAndSettle();
  }

  Future<void> openCartTab(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('new-order-tab-cart')));
    await tester.pumpAndSettle();
  }

  Future<void> selectTableAndAddBurger(WidgetTester tester) async {
    await scrollToFinder(tester, find.text('08'));
    await tester.tap(find.text('08'));
    await tester.pumpAndSettle();
    await scrollToFinder(
      tester,
      find.byKey(const ValueKey('add-menu-menu-chicken')),
    );
    await tester.tap(find.byKey(const ValueKey('add-menu-menu-chicken')));
    await tester.pump();
  }

  FakeOrderService editOrderService({
    Object? updateError,
    List<OrderLineItem> items = const [editedBurger],
    List<RestaurantOrder> orders = const [editedOrder],
  }) {
    return FakeOrderService(
      ordersStream: Stream.value(orders),
      orderStream: Stream.value(editedOrder),
      orderItemsStream: Stream.value(items),
      order: editedOrder,
      orderItems: items,
      updatePendingOrderError: updateError,
    );
  }

  testWidgets('edit mode preloads table number, items, quantities, and total', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildScreen(orderId: 'order-1', orderService: editOrderService()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Order'), findsWidgets);
    expect(find.text('Review Changes'), findsOneWidget);

    await openCartTab(tester);
    await scrollToFinder(tester, find.text('Old Burger Snapshot'));

    expect(find.text('Old Burger Snapshot'), findsOneWidget);
    expect(find.text('RM 9.99 × 2'), findsOneWidget);
    expect(find.text('RM 19.98'), findsWidgets);
  });

  testWidgets(
    'edit mode preserves existing snapshot price when quantity changes',
    (tester) async {
      await tester.pumpWidget(
        buildScreen(orderId: 'order-1', orderService: editOrderService()),
      );
      await tester.pumpAndSettle();

      await openCartTab(tester);
      await scrollToFinder(
        tester,
        find.byKey(const ValueKey('cart-increment-menu-chicken')),
      );
      await tester.tap(
        find.byKey(const ValueKey('cart-increment-menu-chicken')),
      );
      await tester.pump();

      expect(find.text('RM 9.99 × 3'), findsOneWidget);
      expect(find.text('RM 29.97'), findsWidgets);
    },
  );

  testWidgets('edit mode adds a new item using current menu data', (
    tester,
  ) async {
    final orderService = editOrderService();

    await tester.pumpWidget(
      buildScreen(orderId: 'order-1', orderService: orderService),
    );
    await tester.pumpAndSettle();

    await openMenuTab(tester);
    await scrollToFinder(
      tester,
      find.byKey(const ValueKey('add-menu-menu-tea')),
    );
    await tester.tap(find.byKey(const ValueKey('add-menu-menu-tea')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('review-place-order-button')));
    await tester.pumpAndSettle();

    expect(find.text('Confirm Changes'), findsOneWidget);
    expect(find.text('Updated total: RM 24.48'), findsOneWidget);

    await tester.tap(find.text('Update Order'));
    await tester.pumpAndSettle();

    expect(orderService.updatePendingOrderCallCount, 1);
    expect(orderService.lastEditedOrderId, 'order-1');
    expect(orderService.lastEditedTableNo, 5);
    final addedTea = orderService.lastUpdatedItems!.firstWhere(
      (item) => item.menuItemId == 'menu-tea',
    );
    expect(addedTea.id, isEmpty);
    expect(addedTea.nameSnapshot, 'Iced Lemon Tea');
    expect(addedTea.priceSnapshot, 4.5);
  });

  testWidgets(
    'existing unavailable item cannot be increased but can be removed',
    (tester) async {
      await tester.pumpWidget(
        buildScreen(
          orderId: 'order-1',
          orderService: editOrderService(),
          menuItems: const [icedTea],
        ),
      );
      await tester.pumpAndSettle();

      await openCartTab(tester);
      await scrollToFinder(
        tester,
        find.byKey(const ValueKey('cart-increment-menu-chicken')),
      );

      expect(find.text('This item is no longer available'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('cart-increment-menu-chicken')),
      );
      await tester.pump();
      expect(find.text('RM 9.99 × 2'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('cart-decrement-menu-chicken')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('cart-decrement-menu-chicken')),
      );
      await tester.pump();

      expect(find.text('No items selected yet.'), findsOneWidget);
      final reviewButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('review-place-order-button')),
      );
      expect(reviewButton.onPressed, isNull);
    },
  );

  testWidgets(
    'another occupied table cannot be selected while current table remains selectable',
    (tester) async {
      const otherOrder = RestaurantOrder(
        id: 'order-2',
        tableNo: 8,
        status: OrderStatus.pending,
        total: 10,
      );

      await tester.pumpWidget(
        buildScreen(
          orderId: 'order-1',
          orderService: editOrderService(
            orders: const [editedOrder, otherOrder],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Busy'), findsOneWidget);
      await tester.tap(find.text('05').hitTestable());
      await tester.pump();

      expect(
        find.text('This table already has an active order.'),
        findsNothing,
      );
    },
  );

  testWidgets('failed edit update preserves the cart', (tester) async {
    final orderService = editOrderService(
      updateError: const OrderServiceException(
        OrderServiceFailure.statusChanged,
        'Changed',
      ),
    );

    await tester.pumpWidget(
      buildScreen(orderId: 'order-1', orderService: orderService),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('review-place-order-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update Order'));
    await tester.pumpAndSettle();

    expect(
      find.text('This order has already changed and can no longer be edited.'),
      findsOneWidget,
    );
    await openCartTab(tester);
    await scrollToFinder(tester, find.text('Old Burger Snapshot'));
    expect(find.text('Old Burger Snapshot'), findsOneWidget);
  });

  testWidgets('selects a table and shows it in the confirmation dialog', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await selectTableAndAddBurger(tester);
    await tester.tap(find.byKey(const ValueKey('review-place-order-button')));
    await tester.pumpAndSettle();

    expect(find.text('Confirm Order'), findsOneWidget);
    expect(find.text('Table 08'), findsWidgets);
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

    await scrollToFinder(tester, find.text('08'));
    await tester.tap(find.text('08'), warnIfMissed: false);
    await tester.pump();
    await openMenuTab(tester);
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

    await openMenuTab(tester);
    await scrollToFinder(
      tester,
      find.byKey(const ValueKey('add-menu-menu-chicken')),
    );
    await tester.tap(find.byKey(const ValueKey('add-menu-menu-chicken')));
    await tester.pump();

    await openCartTab(tester);
    expect(find.text('RM 12.90 × 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cart-increment-menu-chicken')));
    await tester.pump();

    expect(find.text('RM 12.90 × 2'), findsOneWidget);
    expect(find.text('RM 25.80'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('cart-decrement-menu-chicken')));
    await tester.pump();

    expect(find.text('RM 12.90 × 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cart-decrement-menu-chicken')));
    await tester.pump();

    expect(find.text('No items selected yet.'), findsOneWidget);
  });

  testWidgets('search filters menu items locally', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await openMenuTab(tester);
    await scrollToFinder(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'tea');
    await tester.pump();

    expect(find.text('Iced Lemon Tea'), findsOneWidget);
    expect(find.text('Chicken Burger'), findsNothing);
  });

  testWidgets('category chips filter menu items locally', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await openMenuTab(tester);
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

    await openMenuTab(tester);
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

    await scrollToFinder(tester, find.text('08'));
    await tester.tap(find.text('08'));
    await tester.pumpAndSettle();

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
    await openCartTab(tester);
    expect(find.text('RM 12.90 × 1'), findsOneWidget);
    expect(find.text('Chicken Burger'), findsWidgets);
  });

  testWidgets('shows no matching menu items when filters remove all results', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await openMenuTab(tester);
    await scrollToFinder(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'rendang');
    await tester.pump();

    expect(find.text('No matching menu items'), findsOneWidget);
  });
}
