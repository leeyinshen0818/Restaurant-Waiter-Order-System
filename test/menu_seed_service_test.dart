import 'package:flutter_test/flutter_test.dart';
import 'package:resto_order/services/menu_seed_service.dart';

void main() {
  group('sample menu definition', () {
    final items = MenuSeedService.sampleMenuItems;

    test('contains the required item and category counts', () {
      expect(items, hasLength(15));
      expect(items.where((item) => item.category == 'Main Dish'), hasLength(5));
      expect(items.where((item) => item.category == 'Side Dish'), hasLength(3));
      expect(items.where((item) => item.category == 'Drink'), hasLength(4));
      expect(items.where((item) => item.category == 'Dessert'), hasLength(3));
    });

    test('contains exactly one unavailable Fish and Chips item', () {
      final unavailableItems = items.where((item) => !item.available).toList();

      expect(unavailableItems, hasLength(1));
      expect(unavailableItems.single.name, 'Fish and Chips');
    });

    test('contains valid names and positive numeric prices', () {
      expect(items.every((item) => item.name.trim().isNotEmpty), isTrue);
      expect(items.every((item) => item.price > 0), isTrue);
    });
  });
}
