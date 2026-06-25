import 'package:flutter/material.dart';

import '../models/restaurant_menu_item.dart';

class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    required this.item,
    required this.onAvailabilityChanged,
    required this.onEdit,
    required this.onDelete,
    this.availabilityLoading = false,
    super.key,
  });

  final RestaurantMenuItem item;
  final ValueChanged<bool> onAvailabilityChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool availabilityLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    const availableColor = Color(0xFF64733E);

    return Opacity(
      opacity: item.available ? 1 : 0.72,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outline),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: theme.textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.category,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        'RM ${item.price.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  _AvailabilityBadge(
                    available: item.available,
                    availableColor: availableColor,
                    mutedColor: mutedColor,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (availabilityLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        Switch(
                          value: item.available,
                          onChanged: onAvailabilityChanged,
                        ),
                      IconButton(
                        onPressed: onEdit,
                        tooltip: 'Edit ${item.name}',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                      IconButton(
                        onPressed: onDelete,
                        tooltip: 'Delete ${item.name}',
                        color: theme.colorScheme.error,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.delete_outline, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({
    required this.available,
    required this.availableColor,
    required this.mutedColor,
  });

  final bool available;
  final Color availableColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: available
            ? availableColor.withValues(alpha: 0.12)
            : mutedColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        available ? 'Available' : 'Unavailable',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: available ? availableColor : mutedColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
