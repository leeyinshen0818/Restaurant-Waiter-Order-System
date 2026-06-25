import 'package:flutter/material.dart';

import '../models/restaurant_menu_item.dart';

class OrderMenuItemCard extends StatelessWidget {
  const OrderMenuItemCard({
    required this.item,
    required this.quantity,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    required this.formatPrice,
    super.key,
  });

  final RestaurantMenuItem item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final String Function(double value) formatPrice;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useVerticalLayout = constraints.maxWidth < 320;

            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.category,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  formatPrice(item.price),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: colorScheme.primary),
                ),
              ],
            );

            final controls = quantity == 0
                ? IconButton.filled(
                    key: ValueKey('add-menu-${item.id}'),
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    tooltip: 'Add ${item.name}',
                  )
                : _QuantityControls(
                    itemId: item.id,
                    quantity: quantity,
                    onIncrement: onIncrement,
                    onDecrement: onDecrement,
                  );

            if (useVerticalLayout) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  details,
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: controls),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: details),
                const SizedBox(width: 12),
                controls,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QuantityControls extends StatelessWidget {
  const _QuantityControls({
    required this.itemId,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String itemId;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          key: ValueKey('decrement-menu-$itemId'),
          onPressed: onDecrement,
          icon: const Icon(Icons.remove),
          tooltip: 'Decrease quantity',
        ),
        SizedBox(
          width: 34,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton.filled(
          key: ValueKey('increment-menu-$itemId'),
          onPressed: quantity >= 99 ? null : onIncrement,
          icon: const Icon(Icons.add),
          tooltip: 'Increase quantity',
        ),
      ],
    );
  }
}
