import 'package:flutter/material.dart';

import '../models/order_status.dart';

abstract final class OrderStatusStyle {
  static Color foreground(OrderStatus status) => switch (status) {
    OrderStatus.pending => const Color(0xFFD59A2D),
    OrderStatus.preparing => const Color(0xFFD56A32),
    OrderStatus.served => const Color(0xFF467DA8),
    OrderStatus.paid => const Color(0xFF648761),
  };

  static Color background(OrderStatus status) => switch (status) {
    OrderStatus.pending => const Color(0xFFFFF3D6),
    OrderStatus.preparing => const Color(0xFFFCE7DD),
    OrderStatus.served => const Color(0xFFE4EFF7),
    OrderStatus.paid => const Color(0xFFE8F0E6),
  };
}
