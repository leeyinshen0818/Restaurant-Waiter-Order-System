import 'package:flutter/material.dart';

import '../../models/order_status.dart';
import '../../models/restaurant_menu_item.dart';
import '../../models/restaurant_order.dart';
import '../../services/menu_service.dart';
import '../../services/order_service.dart';
import '../../widgets/order_card.dart';
import '../../widgets/screen_header.dart';
import 'new_order_screen.dart';
import 'order_detail_screen.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({
    this.orderService,
    this.menuService,
    this.onGoToMenu,
    super.key,
  });

  final OrderService? orderService;
  final MenuService? menuService;
  final VoidCallback? onGoToMenu;

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  late final OrderService _orderService;
  late final MenuService _menuService;
  late Stream<List<RestaurantOrder>> _ordersStream;
  late Stream<List<RestaurantMenuItem>> _availableMenuItemsStream;
  OrderStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _orderService = widget.orderService ?? OrderService();
    _menuService = widget.menuService ?? MenuService();
    _ordersStream = _orderService.watchOrders();
    _availableMenuItemsStream = _menuService.watchAvailableMenuItems();
  }

  void _retryOrders() {
    setState(() {
      _ordersStream = _orderService.watchOrders();
    });
  }

  void _openNewOrder(bool? hasAvailableMenuItems) {
    if (hasAvailableMenuItems != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasAvailableMenuItems == null
                ? 'Unable to verify available menu items right now.'
                : 'Add or enable menu items before creating an order.',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => NewOrderScreen(
          orderService: _orderService,
          menuService: _menuService,
          onGoToMenu: widget.onGoToMenu,
        ),
      ),
    );
  }

  void _openOrderDetail(RestaurantOrder order) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) =>
            OrderDetailScreen(orderId: order.id, orderService: _orderService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RestaurantMenuItem>>(
      stream: _availableMenuItemsStream,
      builder: (context, menuSnapshot) {
        final hasAvailableMenuItems = menuSnapshot.hasError
            ? null
            : menuSnapshot.hasData
            ? menuSnapshot.data!.isNotEmpty
            : null;

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ScreenHeader(
                    title: 'Restaurant Orders',
                    subtitle: 'Manage today’s table orders',
                  ),
                  if (hasAvailableMenuItems == false) ...[
                    const SizedBox(height: 16),
                    _NoMenuItemsWarning(onGoToMenu: widget.onGoToMenu),
                  ],
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<List<RestaurantOrder>>(
                      stream: _ordersStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _OrdersErrorState(onRetry: _retryOrders);
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const _OrdersLoadingState();
                        }

                        final orders = List<RestaurantOrder>.from(
                          snapshot.data ?? const <RestaurantOrder>[],
                        )..sort(_compareOrders);

                        if (orders.isEmpty) {
                          return _NoOrdersState(
                            onCreateOrder: () =>
                                _openNewOrder(hasAvailableMenuItems),
                          );
                        }

                        final counts = _OrderCounts.fromOrders(orders);
                        final filteredOrders = _selectedStatus == null
                            ? orders
                            : orders
                                  .where(
                                    (order) => order.status == _selectedStatus,
                                  )
                                  .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _OrderSummary(counts: counts),
                            const SizedBox(height: 14),
                            _OrderFilters(
                              counts: counts,
                              selectedStatus: _selectedStatus,
                              onSelected: (status) {
                                setState(() {
                                  _selectedStatus = status;
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            Expanded(
                              child: filteredOrders.isEmpty
                                  ? _NoFilteredOrdersState(
                                      status: _selectedStatus!,
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      itemCount: filteredOrders.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final order = filteredOrders[index];
                                        return OrderCard(
                                          order: order,
                                          onTap: () => _openOrderDetail(order),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openNewOrder(hasAvailableMenuItems),
            icon: const Icon(Icons.add),
            label: const Text('New Order'),
          ),
        );
      },
    );
  }

  static int _compareOrders(RestaurantOrder first, RestaurantOrder second) {
    final statusComparison = first.status.index.compareTo(second.status.index);
    if (statusComparison != 0) {
      return statusComparison;
    }

    final firstDate = first.createdAt;
    final secondDate = second.createdAt;
    if (firstDate == null && secondDate == null) {
      return 0;
    }
    if (firstDate == null) {
      return 1;
    }
    if (secondDate == null) {
      return -1;
    }

    return first.status == OrderStatus.paid
        ? secondDate.compareTo(firstDate)
        : firstDate.compareTo(secondDate);
  }
}

class _OrderCounts {
  const _OrderCounts({
    required this.all,
    required this.pending,
    required this.preparing,
    required this.served,
    required this.paid,
  });

  factory _OrderCounts.fromOrders(List<RestaurantOrder> orders) {
    int count(OrderStatus status) =>
        orders.where((order) => order.status == status).length;

    return _OrderCounts(
      all: orders.length,
      pending: count(OrderStatus.pending),
      preparing: count(OrderStatus.preparing),
      served: count(OrderStatus.served),
      paid: count(OrderStatus.paid),
    );
  }

  final int all;
  final int pending;
  final int preparing;
  final int served;
  final int paid;

  int get active => pending + preparing + served;

  int forStatus(OrderStatus status) => switch (status) {
    OrderStatus.pending => pending,
    OrderStatus.preparing => preparing,
    OrderStatus.served => served,
    OrderStatus.paid => paid,
  };
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.counts});

  final _OrderCounts counts;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryItem(label: 'Active', count: counts.active),
        const SizedBox(width: 8),
        _SummaryItem(label: 'Pending', count: counts.pending),
        const SizedBox(width: 8),
        _SummaryItem(label: 'Preparing', count: counts.preparing),
        const SizedBox(width: 8),
        _SummaryItem(label: 'Served', count: counts.served),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderFilters extends StatelessWidget {
  const _OrderFilters({
    required this.counts,
    required this.selectedStatus,
    required this.onSelected,
  });

  final _OrderCounts counts;
  final OrderStatus? selectedStatus;
  final ValueChanged<OrderStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All ${counts.all}',
            selected: selectedStatus == null,
            onSelected: () => onSelected(null),
          ),
          for (final status in OrderStatus.values) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: '${status.displayLabel} ${counts.forStatus(status)}',
              selected: selectedStatus == status,
              onSelected: () => onSelected(status),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      checkmarkColor: colorScheme.onPrimary,
      labelStyle: TextStyle(
        color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: selected ? colorScheme.primary : colorScheme.outline,
      ),
    );
  }
}

class _NoMenuItemsWarning extends StatelessWidget {
  const _NoMenuItemsWarning({this.onGoToMenu});

  final VoidCallback? onGoToMenu;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No available menu items',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 3),
                  Text('Add or enable menu items before creating an order.'),
                ],
              ),
            ),
            if (onGoToMenu != null)
              TextButton(
                onPressed: onGoToMenu,
                child: const Text('Go to Menu'),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrdersLoadingState extends StatelessWidget {
  const _OrdersLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading orders...'),
        ],
      ),
    );
  }
}

class _NoOrdersState extends StatelessWidget {
  const _NoOrdersState({required this.onCreateOrder});

  final VoidCallback onCreateOrder;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 42,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No orders yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a new order when a customer is ready.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onCreateOrder,
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Order'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NoFilteredOrdersState extends StatelessWidget {
  const _NoFilteredOrdersState({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_alt_off_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            'No ${status.displayLabel} orders',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'There are no orders with this status right now.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OrdersErrorState extends StatelessWidget {
  const _OrdersErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 42,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load orders',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Check your connection and try again.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
