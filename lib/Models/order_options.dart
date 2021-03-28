import 'package:flutter/material.dart';

@immutable
class OrderOptions {
  final String orderBy;
  final bool asc;

  OrderOptions({
    this.orderBy = 'Name',
    this.asc = true,
  });

  @override
  int get hashCode => hashValues(orderBy, asc);

  @override
  bool operator ==(dynamic o) => o is OrderOptions && o.hashCode == hashCode;
}
