import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resto_order/models/order_line_item.dart';
import 'package:resto_order/models/order_status.dart';
import 'package:resto_order/models/restaurant_order.dart';
import 'package:resto_order/screens/orders/order_detail_screen.dart';
import 'package:resto_order/services/order_service.dart';
import 'package:resto_order/theme/app_theme.dart';

import 'fakes/fake_order_service.dart';

void main() {
  RestaurantOrder orderWithStatus(OrderStatus status) {
    return RestaurantOrder(
      id: 'order-1',
      tableNo: 8,
      status: status,
      total: 34.8,
      createdAt: DateTime(2026, 6, 25, 19, 42),
    );
  }

  const orderItems = [
    OrderLineItem(
      id: 'line-1',
      orderId: 'order-1',
      menuItemId: 'menu-burger',
      nameSnapshot: 'Chicken Burger',
      priceSnapshot: 12.9,
      quantity: 2,
    ),
    OrderLineItem(
      id: 'line-2',
      orderId: 'order-1',
      menuItemId: 'menu-tea',
      nameSnapshot: 'Iced Lemon Tea',
      priceSnapshot: 4.5,
      quantity: 2,
    ),
  ];

  Widget buildScreen(FakeOrderService orderService) {
    return MaterialApp(
      theme: AppTheme.light,
      home: OrderDetailScreen(orderId: 'order-1', orderService: orderService),
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

  FakeOrderService fakeForStatus(OrderStatus status) {
    return FakeOrderService(
      orderStream: Stream.value(orderWithStatus(status)),
      orderItemsStream: Stream.value(orderItems),
    );
  }

  final statusCases = [
    (OrderStatus.pending, 'Start Preparing'),
    (OrderStatus.preparing, 'Mark as Served'),
    (OrderStatus.served, 'Mark as Paid'),
  ];

  for (final (status, actionLabel) in statusCases) {
    testWidgets('${status.displayLabel} order displays $actionLabel', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen(fakeForStatus(status)));
      await tester.pumpAndSettle();

      await scrollToFinder(tester, find.text(actionLabel));
      expect(find.text(actionLabel), findsOneWidget);
      expect(find.text(status.displayLabel), findsWidgets);
    });
  }

  testWidgets('Paid order displays Payment Completed', (tester) async {
    await tester.pumpWidget(buildScreen(fakeForStatus(OrderStatus.paid)));
    await tester.pumpAndSettle();

    await scrollToFinder(tester, find.text('Payment Completed'));
    expect(find.text('Payment Completed'), findsOneWidget);
    expect(find.byKey(const ValueKey('advance-status-button')), findsNothing);
  });

  testWidgets('shows table number, total, date, and snapshot items', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen(fakeForStatus(OrderStatus.preparing)));
    await tester.pumpAndSettle();

    expect(find.text('TABLE 08'), findsOneWidget);
    expect(find.text('Total: RM 34.80'), findsOneWidget);
    expect(find.text('Created at Jun 25, 2026 7:42 PM'), findsOneWidget);
    expect(find.text('Chicken Burger'), findsOneWidget);
    expect(find.text('RM 12.90 × 2'), findsOneWidget);
    expect(find.text('RM 25.80'), findsOneWidget);
    expect(find.text('Iced Lemon Tea'), findsOneWidget);
    expect(find.text('RM 4.50 × 2'), findsOneWidget);
    expect(find.text('RM 9.00'), findsOneWidget);
  });

  testWidgets('confirmation dialog appears and status service is called once', (
    tester,
  ) async {
    final orderService = fakeForStatus(OrderStatus.pending);

    await tester.pumpWidget(buildScreen(orderService));
    await tester.pumpAndSettle();

    await scrollToFinder(
      tester,
      find.byKey(const ValueKey('advance-status-button')),
    );
    await tester.tap(find.byKey(const ValueKey('advance-status-button')));
    await tester.pumpAndSettle();

    expect(find.text('Start Preparing?'), findsOneWidget);
    expect(
      find.text('Move the order for Table 8 to Preparing?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Start Preparing').last);
    await tester.pumpAndSettle();

    expect(orderService.updateOrderStatusCallCount, 1);
    expect(orderService.lastUpdatedOrderId, 'order-1');
    expect(orderService.lastNextStatus, OrderStatus.preparing);
    expect(find.text('Order moved to Preparing.'), findsOneWidget);
  });

  testWidgets('status button is disabled during update', (tester) async {
    final completer = Completer<void>();
    final orderService = FakeOrderService(
      orderStream: Stream.value(orderWithStatus(OrderStatus.served)),
      orderItemsStream: Stream.value(orderItems),
      updateOrderStatusFuture: completer.future,
    );

    await tester.pumpWidget(buildScreen(orderService));
    await tester.pumpAndSettle();

    await scrollToFinder(
      tester,
      find.byKey(const ValueKey('advance-status-button')),
    );
    await tester.tap(find.byKey(const ValueKey('advance-status-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark as Paid').last);
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('advance-status-button')),
    );
    expect(button.onPressed, isNull);
    expect(orderService.updateOrderStatusCallCount, 1);

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('stale transition shows friendly feedback', (tester) async {
    final orderService = FakeOrderService(
      orderStream: Stream.value(orderWithStatus(OrderStatus.pending)),
      orderItemsStream: Stream.value(orderItems),
      updateOrderStatusError: const OrderServiceException(
        OrderServiceFailure.statusChanged,
        'Changed',
      ),
    );

    await tester.pumpWidget(buildScreen(orderService));
    await tester.pumpAndSettle();

    await scrollToFinder(
      tester,
      find.byKey(const ValueKey('advance-status-button')),
    );
    await tester.tap(find.byKey(const ValueKey('advance-status-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Preparing').last);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This order status has already changed. '
        'The latest information is now displayed.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows missing order state', (tester) async {
    await tester.pumpWidget(
      buildScreen(
        FakeOrderService(
          orderStream: Stream.value(null),
          orderItemsStream: Stream.value(orderItems),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Order not found'), findsOneWidget);
    expect(find.text('This order may have been removed.'), findsOneWidget);
    expect(find.text('Back to Orders'), findsOneWidget);
  });

  testWidgets('shows empty order-items state', (tester) async {
    await tester.pumpWidget(
      buildScreen(
        FakeOrderService(
          orderStream: Stream.value(orderWithStatus(OrderStatus.pending)),
          orderItemsStream: Stream.value(const <OrderLineItem>[]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No order items found'), findsOneWidget);
    expect(find.text('The order data may be incomplete.'), findsOneWidget);
  });

  testWidgets('shows order stream error state', (tester) async {
    await tester.pumpWidget(
      buildScreen(
        FakeOrderService(
          orderStream: Stream<RestaurantOrder?>.error(Exception('network')),
          orderItemsStream: Stream.value(orderItems),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load the order'), findsOneWidget);
    expect(find.text('Check your connection and try again.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('shows item stream error state', (tester) async {
    await tester.pumpWidget(
      buildScreen(
        FakeOrderService(
          orderStream: Stream.value(orderWithStatus(OrderStatus.pending)),
          orderItemsStream: Stream<List<OrderLineItem>>.error(
            Exception('network'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TABLE 08'), findsOneWidget);
    expect(find.text('Unable to load the ordered items.'), findsOneWidget);
  });
}
