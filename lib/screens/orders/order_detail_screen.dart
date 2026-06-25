import 'package:flutter/material.dart';

import '../../models/order_line_item.dart';
import '../../models/order_status.dart';
import '../../models/restaurant_order.dart';
import '../../services/menu_service.dart';
import '../../services/order_service.dart';
import '../../utils/order_status_style.dart';
import '../../widgets/order_detail_item_card.dart';
import '../../widgets/order_status_progress.dart';
import 'new_order_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    required this.orderId,
    this.tableNo,
    this.orderService,
    this.menuService,
    super.key,
  });

  final String orderId;
  final int? tableNo;
  final OrderService? orderService;
  final MenuService? menuService;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late final OrderService _orderService;
  late final MenuService? _menuService;
  late Stream<RestaurantOrder?> _orderStream;
  late Stream<List<OrderLineItem>> _orderItemsStream;
  bool _isUpdatingStatus = false;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _orderService = widget.orderService ?? OrderService();
    _menuService = widget.menuService;
    _orderStream = _orderService.watchOrder(widget.orderId);
    _orderItemsStream = _orderService.watchOrderItems(widget.orderId);
  }

  void _retryOrder() {
    setState(() {
      _orderStream = _orderService.watchOrder(widget.orderId);
    });
  }

  void _retryItems() {
    setState(() {
      _orderItemsStream = _orderService.watchOrderItems(widget.orderId);
    });
  }

  Future<void> _confirmStatusUpdate(RestaurantOrder order) async {
    final nextStatus = order.status.nextStatus;
    if (nextStatus == null || _isUpdatingStatus || _isCancelling) {
      return;
    }

    final shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _StatusConfirmationDialog(order: order, nextStatus: nextStatus),
    );

    if (shouldUpdate == true && mounted) {
      await _updateStatus(nextStatus);
    }
  }

  Future<void> _updateStatus(OrderStatus nextStatus) async {
    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await _orderService.updateOrderStatus(
        orderId: widget.orderId,
        nextStatus: nextStatus,
      );

      if (!mounted) {
        return;
      }

      _showMessage(_successMessage(nextStatus));
    } on OrderServiceException catch (error) {
      if (!mounted) {
        return;
      }
      if (error.failure == OrderServiceFailure.statusChanged) {
        _showMessage(
          'This order status has already changed. '
          'The latest information is now displayed.',
        );
      } else {
        _showMessage('Unable to update the order status. Please try again.');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('Unable to update the order status. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  Future<void> _openEditOrder(RestaurantOrder order) async {
    if (order.status != OrderStatus.pending ||
        _isUpdatingStatus ||
        _isCancelling) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => NewOrderScreen(
          orderId: order.id,
          orderService: _orderService,
          menuService: _menuService ?? MenuService(),
        ),
      ),
    );
  }

  Future<void> _confirmCancelOrder(RestaurantOrder order) async {
    if (order.status != OrderStatus.pending ||
        _isUpdatingStatus ||
        _isCancelling) {
      return;
    }

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => _CancelOrderDialog(order: order),
    );

    if (shouldCancel == true && mounted) {
      await _cancelOrder(order);
    }
  }

  Future<void> _cancelOrder(RestaurantOrder order) async {
    setState(() {
      _isCancelling = true;
    });

    try {
      await _orderService.deletePendingOrder(order.id);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order for Table ${order.tableNo} cancelled successfully.',
          ),
        ),
      );
      Navigator.maybePop(context);
    } on OrderServiceException catch (error) {
      if (!mounted) {
        return;
      }
      if (error.failure == OrderServiceFailure.statusChanged) {
        _showMessage(
          'This order has already moved to another status and cannot be cancelled.',
        );
      } else {
        _showMessage('Unable to cancel the order. Please try again.');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('Unable to cancel the order. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _successMessage(OrderStatus nextStatus) {
    return switch (nextStatus) {
      OrderStatus.preparing => 'Order moved to Preparing.',
      OrderStatus.served => 'Order marked as Served.',
      OrderStatus.paid => 'Order marked as Paid.',
      OrderStatus.pending => 'Order status updated.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Detail')),
      body: SafeArea(
        child: StreamBuilder<RestaurantOrder?>(
          stream: _orderStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _CenteredMessage(
                icon: Icons.cloud_off_outlined,
                title: 'Unable to load the order',
                message: 'Check your connection and try again.',
                action: OutlinedButton.icon(
                  onPressed: _retryOrder,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingState(message: 'Loading order details...');
            }

            final order = snapshot.data;
            if (order == null) {
              return _CenteredMessage(
                icon: Icons.receipt_long_outlined,
                title: 'Order not found',
                message: 'This order may have been removed.',
                action: FilledButton.icon(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Orders'),
                ),
              );
            }

            return _OrderDetailContent(
              order: order,
              itemsStream: _orderItemsStream,
              isUpdatingStatus: _isUpdatingStatus,
              isCancelling: _isCancelling,
              onRetryItems: _retryItems,
              onEditOrder: () => _openEditOrder(order),
              onAdvanceStatus: () => _confirmStatusUpdate(order),
              onCancelOrder: () => _confirmCancelOrder(order),
            );
          },
        ),
      ),
    );
  }
}

class _OrderDetailContent extends StatelessWidget {
  const _OrderDetailContent({
    required this.order,
    required this.itemsStream,
    required this.isUpdatingStatus,
    required this.isCancelling,
    required this.onRetryItems,
    required this.onEditOrder,
    required this.onAdvanceStatus,
    required this.onCancelOrder,
  });

  final RestaurantOrder order;
  final Stream<List<OrderLineItem>> itemsStream;
  final bool isUpdatingStatus;
  final bool isCancelling;
  final VoidCallback onRetryItems;
  final VoidCallback onEditOrder;
  final VoidCallback onAdvanceStatus;
  final VoidCallback onCancelOrder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderLineItem>>(
      stream: itemsStream,
      builder: (context, itemsSnapshot) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            _OrderHeaderCard(order: order),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Order Lifecycle',
              child: OrderStatusProgress(currentStatus: order.status),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Ordered Items',
              child: _OrderItemsSection(
                snapshot: itemsSnapshot,
                onRetry: onRetryItems,
              ),
            ),
            const SizedBox(height: 16),
            _StoredTotalCard(total: order.total),
            const SizedBox(height: 16),
            _StatusActionCard(
              order: order,
              isUpdating: isUpdatingStatus,
              isCancelling: isCancelling,
              onEditOrder: onEditOrder,
              onAdvanceStatus: onAdvanceStatus,
              onCancelOrder: onCancelOrder,
            ),
          ],
        );
      },
    );
  }
}

class _OrderHeaderCard extends StatelessWidget {
  const _OrderHeaderCard({required this.order});

  final RestaurantOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TABLE ${order.tableNo.toString().padLeft(2, '0')}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            _StatusBadge(status: order.status),
            const SizedBox(height: 14),
            Text('Created at ${_formatDateTime(order.createdAt)}'),
            const SizedBox(height: 12),
            Text(
              'Total: ${_formatPrice(order.total)}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItemsSection extends StatelessWidget {
  const _OrderItemsSection({required this.snapshot, required this.onRetry});

  final AsyncSnapshot<List<OrderLineItem>> snapshot;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) {
      return _InlineMessage(
        icon: Icons.cloud_off_outlined,
        title: 'Unable to load the ordered items.',
        action: OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      );
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const _InlineLoadingState(message: 'Loading ordered items...');
    }

    final items = snapshot.data ?? const <OrderLineItem>[];
    if (items.isEmpty) {
      return const _InlineMessage(
        icon: Icons.warning_amber_outlined,
        title: 'No order items found',
        message: 'The order data may be incomplete.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return OrderDetailItemCard(
          item: items[index],
          formatPrice: _formatPrice,
        );
      },
    );
  }
}

class _StatusActionCard extends StatelessWidget {
  const _StatusActionCard({
    required this.order,
    required this.isUpdating,
    required this.isCancelling,
    required this.onEditOrder,
    required this.onAdvanceStatus,
    required this.onCancelOrder,
  });

  final RestaurantOrder order;
  final bool isUpdating;
  final bool isCancelling;
  final VoidCallback onEditOrder;
  final VoidCallback onAdvanceStatus;
  final VoidCallback onCancelOrder;

  @override
  Widget build(BuildContext context) {
    final nextStatus = order.status.nextStatus;
    final isBusy = isUpdating || isCancelling;
    if (nextStatus == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: OrderStatusStyle.foreground(OrderStatus.paid),
              ),
              const SizedBox(width: 12),
              Text(
                'Payment Completed',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: OrderStatusStyle.foreground(OrderStatus.paid),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              key: const ValueKey('advance-status-button'),
              onPressed: isBusy ? null : onAdvanceStatus,
              icon: isUpdating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward),
              label: Text(
                isUpdating ? 'Updating...' : _actionLabel(order.status),
              ),
            ),
            if (order.status == OrderStatus.pending) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const ValueKey('edit-order-button'),
                onPressed: isBusy ? null : onEditOrder,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Order'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const ValueKey('cancel-order-button'),
                onPressed: isBusy ? null : onCancelOrder,
                icon: isCancelling
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline),
                label: Text(isCancelling ? 'Cancelling...' : 'Cancel Order'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CancelOrderDialog extends StatelessWidget {
  const _CancelOrderDialog({required this.order});

  final RestaurantOrder order;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Order?'),
      content: Text(
        'Are you sure you want to cancel the order for Table ${order.tableNo}?\n\n'
        'This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep Order'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: const Text('Cancel Order'),
        ),
      ],
    );
  }
}

class _StatusConfirmationDialog extends StatelessWidget {
  const _StatusConfirmationDialog({
    required this.order,
    required this.nextStatus,
  });

  final RestaurantOrder order;
  final OrderStatus nextStatus;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_dialogTitle(order.status)),
      content: Text(_dialogMessage(order.status, order.tableNo)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(_actionLabel(order.status)),
        ),
      ],
    );
  }
}

class _StoredTotalCard extends StatelessWidget {
  const _StoredTotalCard({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Order Total',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              _formatPrice(total),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final foreground = OrderStatusStyle.foreground(status);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: OrderStatusStyle.background(status),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          status.displayLabel,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }
}

class _InlineLoadingState extends StatelessWidget {
  const _InlineLoadingState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 14),
          Text(message),
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!, textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

String _actionLabel(OrderStatus status) {
  return switch (status) {
    OrderStatus.pending => 'Start Preparing',
    OrderStatus.preparing => 'Mark as Served',
    OrderStatus.served => 'Mark as Paid',
    OrderStatus.paid => 'Payment Completed',
  };
}

String _dialogTitle(OrderStatus status) {
  return switch (status) {
    OrderStatus.pending => 'Start Preparing?',
    OrderStatus.preparing => 'Mark as Served?',
    OrderStatus.served => 'Mark as Paid?',
    OrderStatus.paid => 'Payment Completed',
  };
}

String _dialogMessage(OrderStatus status, int tableNo) {
  return switch (status) {
    OrderStatus.pending => 'Move the order for Table $tableNo to Preparing?',
    OrderStatus.preparing =>
      'Confirm that the order has been delivered to Table $tableNo.',
    OrderStatus.served =>
      'Confirm that payment for Table $tableNo has been completed.',
    OrderStatus.paid => 'This order has already been paid.',
  };
}

String _formatPrice(double value) => 'RM ${value.toStringAsFixed(2)}';

String _formatDateTime(DateTime? dateTime) {
  if (dateTime == null) {
    return 'Unknown time';
  }

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[dateTime.month - 1];
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour >= 12 ? 'PM' : 'AM';

  return '$month ${dateTime.day}, ${dateTime.year} $hour:$minute $period';
}
