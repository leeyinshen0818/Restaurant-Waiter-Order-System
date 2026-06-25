import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resto_order/models/restaurant_menu_item.dart';
import 'package:resto_order/screens/menu/menu_list_screen.dart';
import 'package:resto_order/theme/app_theme.dart';

import 'fakes/fake_menu_service.dart';

void main() {
  const burger = RestaurantMenuItem(
    id: 'menu-burger',
    name: 'Chicken Burger',
    price: 12.9,
    category: 'Main Dish',
    available: true,
  );

  const tea = RestaurantMenuItem(
    id: 'menu-tea',
    name: 'Iced Lemon Tea',
    price: 4.5,
    category: 'Drink',
    available: true,
  );

  Widget buildScreen() {
    return MaterialApp(
      theme: AppTheme.light,
      home: MenuListScreen(
        menuService: FakeMenuService(
          menuItemsStream: Stream.value(const [burger, tea]),
        ),
      ),
    );
  }

  testWidgets('filters menu items by category', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Chicken Burger'), findsOneWidget);
    expect(find.text('Iced Lemon Tea'), findsOneWidget);
    expect(find.text('Main Dish 1'), findsOneWidget);
    expect(find.text('Drink 1'), findsOneWidget);

    await tester.tap(find.text('Drink 1'));
    await tester.pump();

    expect(find.text('Iced Lemon Tea'), findsOneWidget);
    expect(find.text('Chicken Burger'), findsNothing);
  });

  testWidgets('add menu item preselects the current category filter', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Drink 1'));
    await tester.pump();
    await tester.tap(find.text('Add Menu Item'));
    await tester.pumpAndSettle();

    expect(find.text('Add Menu Item'), findsOneWidget);
    expect(find.text('Drink'), findsOneWidget);
  });
}
