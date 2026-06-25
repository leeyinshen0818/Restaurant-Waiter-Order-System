import 'package:flutter/material.dart';

import '../models/order_status.dart';
import '../utils/order_status_style.dart';

class OrderStatusProgress extends StatelessWidget {
  const OrderStatusProgress({required this.currentStatus, super.key});

  final OrderStatus currentStatus;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final status in OrderStatus.values)
          _StatusProgressRow(status: status, currentStatus: currentStatus),
      ],
    );
  }
}

class _StatusProgressRow extends StatelessWidget {
  const _StatusProgressRow({required this.status, required this.currentStatus});

  final OrderStatus status;
  final OrderStatus currentStatus;

  @override
  Widget build(BuildContext context) {
    final statusIndex = status.index;
    final currentIndex = currentStatus.index;
    final isCompleted = statusIndex < currentIndex;
    final isCurrent = statusIndex == currentIndex;
    final foreground = isCompleted || isCurrent
        ? OrderStatusStyle.foreground(status)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final icon = isCompleted
        ? Icons.check_circle
        : isCurrent
        ? Icons.radio_button_checked
        : Icons.radio_button_unchecked;
    final stateLabel = isCompleted
        ? 'Completed'
        : isCurrent
        ? 'Current'
        : 'Next';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status.displayLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: foreground,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            stateLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: foreground,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
