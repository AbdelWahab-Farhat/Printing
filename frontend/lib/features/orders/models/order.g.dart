// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Order _$OrderFromJson(Map<String, dynamic> json) => _Order(
  id: (json['id'] as num).toInt(),
  code: json['code'] as String,
  status: $enumDecode(
    _$OrderStatusEnumMap,
    json['status'],
    unknownValue: OrderStatus.unknown,
  ),
  statusLabel: json['status_label'] as String,
  isFinal: json['is_final'] as bool,
  availableTransitions:
      (json['available_transitions'] as List<dynamic>?)
          ?.map((e) => OrderTransition.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <OrderTransition>[],
  customerId: (json['customer_id'] as num).toInt(),
  cityName: json['city_name'] as String,
  fulfilmentTypeLabel: json['fulfilment_type_label'] as String,
  isOfficePickup: json['is_office_pickup'] as bool,
  designSourceLabel: json['design_source_label'] as String,
  itemsTotal: json['items_total'] as String,
  designFee: json['design_fee'] as String,
  deliveryPrice: json['delivery_price'] as String,
  discount: json['discount'] as String,
  grandTotal: json['grand_total'] as String,
  customer: json['customer'] == null
      ? null
      : Customer.fromJson(json['customer'] as Map<String, dynamic>),
  regionName: json['region_name'] as String?,
  customerShopName: json['customer_shop_name'] as String?,
  recipientName: json['recipient_name'] as String?,
  recipientPhone: json['recipient_phone'] as String?,
  addressDetails: json['address_details'] as String?,
  notes: json['notes'] as String?,
  shippingCompany: json['shipping_company'] as String?,
  trackingNumber: json['tracking_number'] as String?,
  courierName: json['courier_name'] as String?,
  cancellationReason: json['cancellation_reason'] as String?,
  itemsAreEditable: json['items_are_editable'] as bool? ?? false,
  itemsCount: (json['items_count'] as num?)?.toInt(),
  items: (json['items'] as List<dynamic>?)
      ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  designs: (json['designs'] as List<dynamic>?)
      ?.map((e) => OrderDesign.fromJson(e as Map<String, dynamic>))
      .toList(),
  transitions: (json['transitions'] as List<dynamic>?)
      ?.map((e) => OrderTransitionRecord.fromJson(e as Map<String, dynamic>))
      .toList(),
  placedAt: json['placed_at'] == null
      ? null
      : DateTime.parse(json['placed_at'] as String),
  deliveredAt: json['delivered_at'] == null
      ? null
      : DateTime.parse(json['delivered_at'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$OrderToJson(_Order instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'status': _$OrderStatusEnumMap[instance.status]!,
  'status_label': instance.statusLabel,
  'is_final': instance.isFinal,
  'available_transitions': instance.availableTransitions
      .map((e) => e.toJson())
      .toList(),
  'customer_id': instance.customerId,
  'city_name': instance.cityName,
  'fulfilment_type_label': instance.fulfilmentTypeLabel,
  'is_office_pickup': instance.isOfficePickup,
  'design_source_label': instance.designSourceLabel,
  'items_total': instance.itemsTotal,
  'design_fee': instance.designFee,
  'delivery_price': instance.deliveryPrice,
  'discount': instance.discount,
  'grand_total': instance.grandTotal,
  'customer': instance.customer?.toJson(),
  'region_name': instance.regionName,
  'customer_shop_name': instance.customerShopName,
  'recipient_name': instance.recipientName,
  'recipient_phone': instance.recipientPhone,
  'address_details': instance.addressDetails,
  'notes': instance.notes,
  'shipping_company': instance.shippingCompany,
  'tracking_number': instance.trackingNumber,
  'courier_name': instance.courierName,
  'cancellation_reason': instance.cancellationReason,
  'items_are_editable': instance.itemsAreEditable,
  'items_count': instance.itemsCount,
  'items': instance.items?.map((e) => e.toJson()).toList(),
  'designs': instance.designs?.map((e) => e.toJson()).toList(),
  'transitions': instance.transitions?.map((e) => e.toJson()).toList(),
  'placed_at': instance.placedAt?.toIso8601String(),
  'delivered_at': instance.deliveredAt?.toIso8601String(),
  'created_at': instance.createdAt?.toIso8601String(),
};

const _$OrderStatusEnumMap = {
  OrderStatus.taken: 'new',
  OrderStatus.designing: 'designing',
  OrderStatus.printing: 'printing',
  OrderStatus.ready: 'ready',
  OrderStatus.shortage: 'shortage',
  OrderStatus.officePickup: 'office_pickup',
  OrderStatus.outForDelivery: 'out_for_delivery',
  OrderStatus.delivered: 'delivered',
  OrderStatus.returnedCourier: 'returned_courier',
  OrderStatus.returnedCarrier: 'returned_carrier',
  OrderStatus.returnedOffice: 'returned_office',
  OrderStatus.cancelled: 'cancelled',
  OrderStatus.unknown: 'unknown',
};

_OrderTransition _$OrderTransitionFromJson(Map<String, dynamic> json) =>
    _OrderTransition(
      status: $enumDecode(
        _$OrderStatusEnumMap,
        json['status'],
        unknownValue: OrderStatus.unknown,
      ),
      label: json['label'] as String,
      requiresReason: json['requires_reason'] as bool? ?? false,
    );

Map<String, dynamic> _$OrderTransitionToJson(_OrderTransition instance) =>
    <String, dynamic>{
      'status': _$OrderStatusEnumMap[instance.status]!,
      'label': instance.label,
      'requires_reason': instance.requiresReason,
    };

_OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => _OrderItem(
  id: (json['id'] as num).toInt(),
  productName: json['product_name'] as String,
  variantLabel: json['variant_label'] as String,
  pricingUnitLabel: json['pricing_unit_label'] as String,
  quantity: json['quantity'] as String,
  unitPrice: json['unit_price'] as String,
  lineTotal: json['line_total'] as String,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$OrderItemToJson(_OrderItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'product_name': instance.productName,
      'variant_label': instance.variantLabel,
      'pricing_unit_label': instance.pricingUnitLabel,
      'quantity': instance.quantity,
      'unit_price': instance.unitPrice,
      'line_total': instance.lineTotal,
      'notes': instance.notes,
    };

_OrderDesign _$OrderDesignFromJson(Map<String, dynamic> json) => _OrderDesign(
  id: (json['id'] as num).toInt(),
  version: (json['version'] as num).toInt(),
  status: json['status'] as String,
  statusLabel: json['status_label'] as String,
  isReviewed: json['is_reviewed'] as bool? ?? false,
  rejectionReason: json['rejection_reason'] as String?,
  notes: json['notes'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$OrderDesignToJson(_OrderDesign instance) =>
    <String, dynamic>{
      'id': instance.id,
      'version': instance.version,
      'status': instance.status,
      'status_label': instance.statusLabel,
      'is_reviewed': instance.isReviewed,
      'rejection_reason': instance.rejectionReason,
      'notes': instance.notes,
      'created_at': instance.createdAt?.toIso8601String(),
    };

_OrderTransitionRecord _$OrderTransitionRecordFromJson(
  Map<String, dynamic> json,
) => _OrderTransitionRecord(
  id: (json['id'] as num).toInt(),
  fromStatusLabel: json['from_status_label'] as String?,
  toStatusLabel: json['to_status_label'] as String,
  reason: json['reason'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$OrderTransitionRecordToJson(
  _OrderTransitionRecord instance,
) => <String, dynamic>{
  'id': instance.id,
  'from_status_label': instance.fromStatusLabel,
  'to_status_label': instance.toStatusLabel,
  'reason': instance.reason,
  'created_at': instance.createdAt?.toIso8601String(),
};
