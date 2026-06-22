import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/menu_service.dart';
import 'services/order_service.dart';
import 'theme/app_theme.dart';

class RestaurantWaiterApp extends StatelessWidget {
  const RestaurantWaiterApp({this.menuService, this.orderService, super.key});

  final MenuService? menuService;
  final OrderService? orderService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant Waiter Order System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: HomeScreen(menuService: menuService, orderService: orderService),
    );
  }
}
