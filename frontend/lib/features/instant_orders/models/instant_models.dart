import 'package:dayaa/features/orders/models/order.dart';
import 'package:flutter/foundation.dart';

// What the instant-order screen reads from the server (INSTANT-ORDERS-PLAN.md §3). Plain
// classes rather than Freezed models: they are read once, shown, and thrown away — none is
// stored, compared or copied.

/// A branch this employee may sell from, with the warehouse its stock comes from.
@immutable
class SellingBranch {
  const SellingBranch({required this.id, required this.name, this.warehouseName});

  factory SellingBranch.fromJson(Map<String, dynamic> json) => SellingBranch(
    id: json['id'] as int,
    name: json['name'] as String,
    warehouseName: json['warehouse_name'] as String?,
  );

  final int id;
  final String name;
  final String? warehouseName;
}

/// A customer found by phone — only what the form shows.
@immutable
class FoundCustomer {
  const FoundCustomer({
    required this.id,
    required this.name,
    required this.phone,
    this.isActive = true,
    this.cityId,
    this.cityName,
    this.regionId,
    this.regionName,
  });

  factory FoundCustomer.fromJson(Map<String, dynamic> json) => FoundCustomer(
    id: json['id'] as int,
    name: json['name'] as String,
    phone: json['phone'] as String,
    isActive: json['is_active'] as bool? ?? true,
    cityId: json['city_id'] as int?,
    cityName: json['city_name'] as String?,
    regionId: json['region_id'] as int?,
    regionName: json['region_name'] as String?,
  );

  final int id;
  final String name;
  final String phone;
  final bool isActive;
  final int? cityId;
  final String? cityName;
  final int? regionId;
  final String? regionName;
}

/// One price break: from [minQuantity] on, each unit costs [unitPrice].
@immutable
class InstantPriceTier {
  const InstantPriceTier({required this.minQuantity, required this.unitPrice});

  factory InstantPriceTier.fromJson(Map<String, dynamic> json) => InstantPriceTier(
    minQuantity: double.parse(json['min_quantity'].toString()),
    unitPrice: double.parse(json['unit_price'].toString()),
  );

  final double minQuantity;
  final double unitPrice;
}

/// A size that may be sold at the counter, and what the branch's warehouse holds of it.
@immutable
class InstantVariant {
  const InstantVariant({
    required this.id,
    required this.label,
    required this.stockItemId,
    required this.available,
    this.priceTiers = const [],
  });

  factory InstantVariant.fromJson(Map<String, dynamic> json) => InstantVariant(
    id: json['id'] as int,
    label: json['label'] as String,
    stockItemId: json['stock_item_id'] as int,
    available: double.parse(json['available_quantity'].toString()),
    priceTiers: [
      for (final tier in (json['price_tiers'] as List<dynamic>? ?? const []))
        InstantPriceTier.fromJson(tier as Map<String, dynamic>),
    ],
  );

  final int id;
  final String label;
  final int stockItemId;

  /// On the shelf and free to sell, in the product's unit.
  final double available;
  final List<InstantPriceTier> priceTiers;

  /// The unit price at [quantity] — the last tier whose threshold it reaches. Null when no tier
  /// applies. An estimate for the screen: the server prices the order itself.
  double? unitPriceFor(double quantity) {
    InstantPriceTier? chosen;

    for (final tier in priceTiers) {
      if (quantity >= tier.minQuantity) chosen = tier;
    }

    return (chosen ?? (priceTiers.isEmpty ? null : priceTiers.first))?.unitPrice;
  }
}

/// A product the counter may sell, with only its eligible sizes.
@immutable
class InstantProduct {
  const InstantProduct({
    required this.id,
    required this.name,
    required this.unitLabel,
    required this.variants,
    this.minOrderQuantity = 0,
  });

  factory InstantProduct.fromJson(Map<String, dynamic> json) => InstantProduct(
    id: json['id'] as int,
    name: json['name'] as String,
    unitLabel: json['unit_label'] as String? ?? '',
    minOrderQuantity: double.tryParse('${json['min_order_quantity']}') ?? 0,
    variants: [
      for (final variant in (json['variants'] as List<dynamic>? ?? const []))
        InstantVariant.fromJson(variant as Map<String, dynamic>),
    ],
  );

  final int id;
  final String name;
  final String unitLabel;
  final double minOrderQuantity;
  final List<InstantVariant> variants;
}

/// What may be sold at one branch, and the warehouse it comes from.
@immutable
class InstantCatalogue {
  const InstantCatalogue({required this.products, this.warehouseName});

  final List<InstantProduct> products;
  final String? warehouseName;

  /// The size by id, wherever it is in the list.
  ({InstantProduct product, InstantVariant variant})? find(int variantId) {
    for (final product in products) {
      for (final variant in product.variants) {
        if (variant.id == variantId) return (product: product, variant: variant);
      }
    }

    return null;
  }
}

/// One line as the counter is typing it.
@immutable
class InstantLine {
  const InstantLine({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.variantLabel,
    required this.unitLabel,
    required this.quantity,
    this.lineId,
  });

  /// The order line this one keeps, on an edit. Null for a new line.
  final int? lineId;
  final int productId;
  final int variantId;
  final String productName;
  final String variantLabel;
  final String unitLabel;
  final double quantity;

  InstantLine withQuantity(double next) => InstantLine(
    lineId: lineId,
    productId: productId,
    variantId: variantId,
    productName: productName,
    variantLabel: variantLabel,
    unitLabel: unitLabel,
    quantity: next,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': ?lineId,
    'product_id': productId,
    'product_variant_id': variantId,
    'quantity': quantity,
  };
}

/// The order the server took, and anything it wants the employee told.
@immutable
class InstantOrderResult {
  const InstantOrderResult({required this.order, this.customerNotice});

  final Order order;

  /// The stored customer differed from what was typed; the stored details were kept.
  final String? customerNotice;
}
