import 'package:flutter/material.dart';

import '../models/order_line_item.dart';

class OrderDetailItemCard extends StatelessWidget {
  const OrderDetailItemCard({
    required this.item,
    required this.formatPrice,
    super.key,
  });

  final OrderLineItem item;
  final String Function(double value) formatPrice;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nameSnapshot,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text('${formatPrice(item.priceSnapshot)} × ${item.quantity}'),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatPrice(item.subtotal),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}
