import 'package:flutter/foundation.dart';

/// One line as «إدارة الطلبية» sends it: the line, its quantity and its price.
///
/// **[unitPrice] is always sent**, because the screen opens every line on the price it carries:
/// whatever arrives is the price the person saving confirmed, and the server bills the line at it
/// whatever the catalogue says.
///
/// [warehouseQuantity] only for a line stocked in another unit whose quantity moved after the
/// stock left — the same question «جاهزة للطباعة» asked the first time.
@immutable
class ManagedLine {
  const ManagedLine({
    required this.id,
    required this.quantity,
    required this.unitPrice,
    this.warehouseQuantity,
  });

  final int id;
  final String quantity;
  final String unitPrice;
  final String? warehouseQuantity;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'quantity': quantity,
    'unit_price': unitPrice,
    'warehouse_quantity': ?warehouseQuantity,
  };
}
