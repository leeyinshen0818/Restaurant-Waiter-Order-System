import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resto_order/models/order_status.dart';
import 'package:resto_order/models/restaurant_menu_item.dart';
import 'package:resto_order/models/restaurant_order.dart';
import 'package:resto_order/screens/menu/menu_form_screen.dart';
import 'package:resto_order/theme/app_theme.dart';
import 'package:resto_order/widgets/menu_item_card.dart';
import 'package:resto_order/widgets/order_card.dart';
import 'package:resto_order/widgets/order_status_progress.dart';
import 'package:resto_order/widgets/table_selection_grid.dart';

import 'fakes/fake_menu_service.dart';

void main() {
  const longMenuItem = RestaurantMenuItem(
    id: 'menu-long',
    name: 'Extra Crispy Double Chicken Burger with Spicy Homemade Sauce',
    price: 1288.9,
    category: 'Main Dish',
    available: true,
  );

  Widget frame(Widget child, {double width = 320, double height = 640}) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );
  }

  testWidgets('menu item card remains usable on a narrow screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      frame(
        MenuItemCard(
          item: longMenuItem,
          onAvailabilityChanged: (_) {},
          onEdit: () {},
          onDelete: () {},
        ),
        width: 280,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Extra Crispy'), findsOneWidget);
    expect(find.byTooltip('Edit ${longMenuItem.name}'), findsOneWidget);
    expect(find.byTooltip('Delete ${longMenuItem.name}'), findsOneWidget);
  });

  testWidgets('order card remains usable on a narrow screen', (tester) async {
    await tester.pumpWidget(
      frame(
        OrderCard(
          order: RestaurantOrder(
            id: 'order-1',
            tableNo: 12,
            status: OrderStatus.preparing,
            total: 12345.67,
            createdAt: DateTime(2026, 6, 25, 19, 42),
          ),
          onTap: () {},
        ),
        width: 280,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('TABLE 12'), findsOneWidget);
    expect(find.text('Preparing'), findsOneWidget);
  });

  testWidgets('status progress renders every lifecycle label', (tester) async {
    await tester.pumpWidget(
      frame(const OrderStatusProgress(currentStatus: OrderStatus.preparing)),
    );

    for (final status in OrderStatus.values) {
      expect(find.text(status.displayLabel), findsOneWidget);
    }
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
  });

  testWidgets('table grid renders all 20 tables on narrow width', (
    tester,
  ) async {
    await tester.pumpWidget(
      frame(
        SingleChildScrollView(
          child: TableSelectionGrid(
            tables: List.generate(20, (index) => index + 1),
            occupiedTables: const {3, 8},
            selectedTable: 5,
            onTableSelected: (_) {},
          ),
        ),
        width: 280,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('01'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('Busy'), findsNWidgets(2));
  });

  testWidgets('menu form scrolls on small height and keeps action reachable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SizedBox(
          width: 320,
          height: 420,
          child: MenuFormScreen(menuService: FakeMenuService()),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -360));
    await tester.pump();
    expect(find.text('Save Menu Item'), findsOneWidget);
  });
}
