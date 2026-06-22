enum OrderStatus {
  pending,
  preparing,
  served,
  paid;

  String get firestoreValue => switch (this) {
    OrderStatus.pending => 'Pending',
    OrderStatus.preparing => 'Preparing',
    OrderStatus.served => 'Served',
    OrderStatus.paid => 'Paid',
  };

  String get displayLabel => firestoreValue;

  OrderStatus? get nextStatus => switch (this) {
    OrderStatus.pending => OrderStatus.preparing,
    OrderStatus.preparing => OrderStatus.served,
    OrderStatus.served => OrderStatus.paid,
    OrderStatus.paid => null,
  };

  static OrderStatus? tryFromFirestore(String? value) {
    final normalizedValue = value?.trim().toLowerCase();

    return switch (normalizedValue) {
      'pending' => OrderStatus.pending,
      'preparing' => OrderStatus.preparing,
      'served' => OrderStatus.served,
      'paid' => OrderStatus.paid,
      _ => null,
    };
  }

  static OrderStatus fromFirestore(
    String? value, {
    OrderStatus fallback = OrderStatus.pending,
  }) {
    return tryFromFirestore(value) ?? fallback;
  }
}
