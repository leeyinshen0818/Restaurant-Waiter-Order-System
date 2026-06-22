import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resto_order/models/restaurant_menu_item.dart';
import 'package:resto_order/screens/menu/menu_form_screen.dart';
import 'package:resto_order/theme/app_theme.dart';

import 'fakes/fake_menu_service.dart';

void main() {
  Widget buildForm({RestaurantMenuItem? item, FakeMenuService? menuService}) {
    return MaterialApp(
      theme: AppTheme.light,
      home: MenuFormScreen(
        item: item,
        menuService: menuService ?? FakeMenuService(),
      ),
    );
  }

  testWidgets('validates required menu item fields', (tester) async {
    await tester.pumpWidget(buildForm());

    await tester.tap(find.text('Save Menu Item'));
    await tester.pump();

    expect(find.text('Please enter the item name.'), findsOneWidget);
    expect(find.text('Please enter the price.'), findsOneWidget);
    expect(find.text('Please select a category.'), findsOneWidget);
  });

  testWidgets('rejects an invalid price', (tester) async {
    await tester.pumpWidget(buildForm());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Item name'),
      'Chicken Burger',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Price'),
      '12.3.4',
    );
    await tester.tap(find.text('Save Menu Item'));
    await tester.pump();

    expect(find.text('Please enter a valid price.'), findsOneWidget);
  });

  testWidgets('edit mode pre-fills existing item values', (tester) async {
    final item = RestaurantMenuItem(
      id: 'menu-1',
      name: 'Chicken Burger',
      price: 12.5,
      category: 'Main Dish',
      available: false,
      createdAt: DateTime(2026),
    );

    await tester.pumpWidget(buildForm(item: item));

    expect(find.text('Edit Menu Item'), findsOneWidget);
    expect(find.text('Update Menu Item'), findsOneWidget);
    expect(find.text('Chicken Burger'), findsOneWidget);
    expect(find.text('12.50'), findsOneWidget);

    final availabilitySwitch = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect(availabilitySwitch.value, isFalse);
  });
}
