import 'package:cloud_firestore/cloud_firestore.dart';

import 'order_status.dart';

class RestaurantOrder {
  const RestaurantOrder({
    required this.id,
    required this.tableNo,
    required this.status,
    required this.total,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final int tableNo;
  final OrderStatus status;
  final double total;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RestaurantOrder copyWith({
    String? id,
    int? tableNo,
    OrderStatus? status,
    double? total,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RestaurantOrder(
      id: id ?? this.id,
      tableNo: tableNo ?? this.tableNo,
      status: status ?? this.status,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory RestaurantOrder.fromMap(Map<String, dynamic> map, {String id = ''}) {
    return RestaurantOrder(
      id: id,
      tableNo: (map['table_no'] as num?)?.toInt() ?? 0,
      status: OrderStatus.fromFirestore(map['status'] as String?),
      total: (map['total'] as num?)?.toDouble() ?? 0,
      createdAt: _dateTimeFromValue(map['created_at']),
      updatedAt: _dateTimeFromValue(map['updated_at']),
    );
  }

  factory RestaurantOrder.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return RestaurantOrder.fromMap(
      document.data() ?? const <String, dynamic>{},
      id: document.id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'table_no': tableNo,
      'status': status.firestoreValue,
      'total': total,
      'created_at': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updated_at': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  static DateTime? _dateTimeFromValue(Object? value) {
    return switch (value) {
      Timestamp timestamp => timestamp.toDate(),
      DateTime dateTime => dateTime,
      _ => null,
    };
  }
}
