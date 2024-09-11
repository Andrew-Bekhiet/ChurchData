import 'package:flutter/material.dart';

@immutable
class OrderOptions {
  final String orderBy;
  final bool asc;

  const OrderOptions({
    this.orderBy = 'Name',
    this.asc = true,
  });

  @override
  int get hashCode => Object.hash(orderBy, asc);

  @override
  bool operator ==(Object other) =>
      other is OrderOptions && other.hashCode == hashCode;
}
