import 'package:cloud_firestore/cloud_firestore.dart';

class OrderLineItem {
  const OrderLineItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.nameSnapshot,
    required this.priceSnapshot,
    required this.quantity,
  });

  final String id;
  final String orderId;
  final String menuItemId;
  final String nameSnapshot;
  final double priceSnapshot;
  final int quantity;

  double get subtotal => priceSnapshot * quantity;

  OrderLineItem copyWith({
    String? id,
    String? orderId,
    String? menuItemId,
    String? nameSnapshot,
    double? priceSnapshot,
    int? quantity,
  }) {
    return OrderLineItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      menuItemId: menuItemId ?? this.menuItemId,
      nameSnapshot: nameSnapshot ?? this.nameSnapshot,
      priceSnapshot: priceSnapshot ?? this.priceSnapshot,
      quantity: quantity ?? this.quantity,
    );
  }

  factory OrderLineItem.fromMap(Map<String, dynamic> map, {String id = ''}) {
    return OrderLineItem(
      id: id,
      orderId: map['order_id'] as String? ?? '',
      menuItemId: map['menu_item_id'] as String? ?? '',
      nameSnapshot: map['name_snapshot'] as String? ?? '',
      priceSnapshot: (map['price_snapshot'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  factory OrderLineItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return OrderLineItem.fromMap(
      document.data() ?? const <String, dynamic>{},
      id: document.id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'menu_item_id': menuItemId,
      'name_snapshot': nameSnapshot,
      'price_snapshot': priceSnapshot,
      'quantity': quantity,
    };
  }
}
