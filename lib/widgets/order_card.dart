import 'package:flutter/material.dart';

import '../models/order_status.dart';
import '../models/restaurant_order.dart';
import '../utils/order_status_style.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({required this.order, required this.onTap, super.key});

  final RestaurantOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPaid = order.status == OrderStatus.paid;

    return Opacity(
      opacity: isPaid ? 0.88 : 1,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 5,
                  color: OrderStatusStyle.foreground(
                    order.status,
                  ).withValues(alpha: isPaid ? 0.45 : 0.85),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                'TABLE ${order.tableNo.toString().padLeft(2, '0')}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: 20,
                                  height: 1.05,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _OrderStatusBadge(status: order.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                'Created ${_formatTime(order.createdAt)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'RM ${order.total.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    height: 1.05,
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              color: theme.colorScheme.secondary,
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Unknown time';
    }

    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _OrderStatusBadge extends StatelessWidget {
  const _OrderStatusBadge({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final foreground = OrderStatusStyle.foreground(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: OrderStatusStyle.background(status),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: OrderStatusStyle.foreground(status).withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        status.displayLabel,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
