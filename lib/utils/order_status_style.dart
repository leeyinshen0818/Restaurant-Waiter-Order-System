import 'package:flutter/material.dart';

import '../models/order_status.dart';

abstract final class OrderStatusStyle {
  static Color foreground(OrderStatus status) => switch (status) {
    OrderStatus.pending => const Color(0xFF8A5A00),
    OrderStatus.preparing => const Color(0xFFB45309),
    OrderStatus.served => const Color(0xFF2563A6),
    OrderStatus.paid => const Color(0xFF49753A),
  };

  static Color background(OrderStatus status) =>
      foreground(status).withValues(alpha: 0.12);
}
