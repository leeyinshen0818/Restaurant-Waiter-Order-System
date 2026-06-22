import 'package:resto_order/models/restaurant_menu_item.dart';
import 'package:resto_order/services/menu_service.dart';

class FakeMenuService implements MenuService {
  FakeMenuService({Stream<List<RestaurantMenuItem>>? menuItemsStream})
    : _menuItemsStream =
          (menuItemsStream ?? Stream.value(const <RestaurantMenuItem>[]))
              .asBroadcastStream();

  final Stream<List<RestaurantMenuItem>> _menuItemsStream;
  RestaurantMenuItem? addedItem;
  RestaurantMenuItem? updatedItem;

  @override
  Future<String> addMenuItem(RestaurantMenuItem item) async {
    addedItem = item;
    return 'new-item-id';
  }

  @override
  Future<void> deleteMenuItem(String id) async {}

  @override
  Future<RestaurantMenuItem?> getMenuItem(String id) async => null;

  @override
  Future<void> updateAvailability(String id, bool available) async {}

  @override
  Future<void> updateMenuItem(RestaurantMenuItem item) async {
    updatedItem = item;
  }

  @override
  Stream<List<RestaurantMenuItem>> watchAvailableMenuItems() =>
      _menuItemsStream;

  @override
  Stream<List<RestaurantMenuItem>> watchMenuItems() => _menuItemsStream;
}
