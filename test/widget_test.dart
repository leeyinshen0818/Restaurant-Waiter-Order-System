import 'package:flutter_test/flutter_test.dart';
import 'package:resto_order/app.dart';

import 'fakes/fake_menu_service.dart';
import 'fakes/fake_order_service.dart';

void main() {
  testWidgets('opens on the Orders screen', (tester) async {
    await tester.pumpWidget(
      RestaurantWaiterApp(
        menuService: FakeMenuService(),
        orderService: FakeOrderService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Restaurant Orders'), findsOneWidget);
    expect(find.text('No orders yet'), findsOneWidget);
    expect(find.text('New Order'), findsOneWidget);
  });

  testWidgets('switches to the Menu screen', (tester) async {
    await tester.pumpWidget(
      RestaurantWaiterApp(
        menuService: FakeMenuService(),
        orderService: FakeOrderService(),
      ),
    );

    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();

    expect(find.text('Restaurant Menu'), findsOneWidget);
    expect(find.text('No menu items yet'), findsOneWidget);
    expect(find.text('Add Menu Item'), findsNWidgets(2));
    expect(find.text('Load Sample Menu'), findsOneWidget);
  });
}
