import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantMenuItem {
  const RestaurantMenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.available,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final double price;
  final String category;
  final bool available;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RestaurantMenuItem copyWith({
    String? id,
    String? name,
    double? price,
    String? category,
    bool? available,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RestaurantMenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      available: available ?? this.available,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory RestaurantMenuItem.fromMap(
    Map<String, dynamic> map, {
    String id = '',
  }) {
    return RestaurantMenuItem(
      id: id,
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      category: map['category'] as String? ?? '',
      available: map['available'] as bool? ?? false,
      createdAt: _dateTimeFromValue(map['created_at']),
      updatedAt: _dateTimeFromValue(map['updated_at']),
    );
  }

  factory RestaurantMenuItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return RestaurantMenuItem.fromMap(
      document.data() ?? const <String, dynamic>{},
      id: document.id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'available': available,
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
