import 'package:flutter/material.dart';

import '../services/menu_service.dart';
import '../services/order_service.dart';
import 'menu/menu_list_screen.dart';
import 'orders/orders_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({this.menuService, this.orderService, super.key});

  final MenuService? menuService;
  final OrderService? orderService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      OrdersListScreen(
        orderService: widget.orderService,
        menuService: widget.menuService,
        onGoToMenu: () {
          setState(() {
            _selectedIndex = 1;
          });
        },
      ),
      MenuListScreen(menuService: widget.menuService),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu),
              label: 'Menu',
            ),
          ],
        ),
      ),
    );
  }
}
