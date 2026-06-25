import 'package:flutter/material.dart';

import '../models/restaurant_menu_item.dart';

class OrderCartItem extends StatelessWidget {
  const OrderCartItem({
    required this.item,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.formatPrice,
    this.canIncrement = true,
    this.warning,
    super.key,
  });

  final RestaurantMenuItem item;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final String Function(double value) formatPrice;
  final bool canIncrement;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    final subtotal = item.price * quantity;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text('${formatPrice(item.price)} × $quantity'),
                if (warning != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    warning!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _CompactQuantityButton(
                      key: ValueKey('cart-decrement-${item.id}'),
                      icon: Icons.remove,
                      onPressed: onDecrement,
                      tooltip: 'Decrease ${item.name}',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '$quantity',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    _CompactQuantityButton(
                      key: ValueKey('cart-increment-${item.id}'),
                      icon: Icons.add,
                      onPressed: quantity >= 99 || !canIncrement
                          ? null
                          : onIncrement,
                      tooltip: 'Increase ${item.name}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatPrice(subtotal),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _CompactQuantityButton extends StatelessWidget {
  const _CompactQuantityButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 36,
      child: IconButton.outlined(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
