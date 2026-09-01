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
  productionFlowLabel: json['production_flow_label'] as String? ?? '',
  isFinal: json['is_final'] as bool,
  isClosed: json['is_closed'] as bool? ?? false,
  availableTransitions:
      (json['available_transitions'] as List<dynamic>?)
          ?.map((e) => OrderTransition.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <OrderTransition>[],
  customerId: (json['customer_id'] as num).toInt(),
  cityId: (json['city_id'] as num).toInt(),
  designSource: json['design_source'] as String,
  cityName: json['city_name'] as String,
  fulfilmentTypeLabel: json['fulfilment_type_label'] as String,
  isOfficePickup: json['is_office_pickup'] as bool,
  designSourceLabel: json['design_source_label'] as String,
  itemsTotal: json['items_total'] as String,
  designFee: json['design_fee'] as String,
  deliveryPrice: json['delivery_price'] as String,
  discount: json['discount'] as String,
  additionalCost: json['additional_cost'] as String? ?? '0.00',
  additionalCostReason: $enumDecodeNullable(
    _$AdditionalCostReasonEnumMap,
    json['additional_cost_reason'],
    unknownValue: AdditionalCostReason.unknown,
  ),
  additionalCostReasonLabel: json['additional_cost_reason_label'] as String?,
  additionalCostNote: json['additional_cost_note'] as String?,
  grandTotal: json['grand_total'] as String,
  paidAmount: json['paid_amount'] as String? ?? '0.00',
  writtenOffAmount: json['written_off_amount'] as String? ?? '0.00',
  remainingAmount: json['remaining_amount'] as String? ?? '0.00',
  paymentStatus:
      $enumDecodeNullable(
        _$PaymentStatusEnumMap,
        json['payment_status'],
        unknownValue: PaymentStatus.unknown,
      ) ??
      PaymentStatus.unpaid,
  paymentStatusLabel: json['payment_status_label'] as String? ?? '',
  hasUnrecordedMoney: json['has_unrecorded_money'] as bool? ?? false,
  collectedAmount: json['collected_amount'] as String?,
  customer: json['customer'] == null
      ? null
      : Customer.fromJson(json['customer'] as Map<String, dynamic>),
  regionId: (json['region_id'] as num?)?.toInt(),
  customerShopId: (json['customer_shop_id'] as num?)?.toInt(),
  regionName: json['region_name'] as String?,
  customerShopName: json['customer_shop_name'] as String?,
  recipientName: json['recipient_name'] as String?,
  recipientPhone: json['recipient_phone'] as String?,
  addressDetails: json['address_details'] as String?,
  notes: json['notes'] as String?,
  shippingCompany: json['shipping_company'] as String?,
  trackingNumber: json['tracking_number'] as String?,
  courierPhone: json['courier_phone'] as String?,
  cancellationReason: json['cancellation_reason'] as String?,
  progress: json['progress'] == null
      ? OrderProgress.unknown
      : OrderProgress.fromJson(json['progress'] as Map<String, dynamic>),
  itemsAreEditable: json['items_are_editable'] as bool? ?? false,
  designsAreEditable: json['designs_are_editable'] as bool? ?? false,
  destinationIsEditable: json['destination_is_editable'] as bool? ?? false,
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
  totalCogs: json['total_cogs'] as String?,
  grossProfit: json['gross_profit'] as String?,
  fulfillmentWarehouseId: (json['fulfillment_warehouse_id'] as num?)?.toInt(),
  stockDeductedAt: json['stock_deducted_at'] == null
      ? null
      : DateTime.parse(json['stock_deducted_at'] as String),
  placedAt: json['placed_at'] == null
      ? null
      : DateTime.parse(json['placed_at'] as String),
  deliveredAt: json['delivered_at'] == null
      ? null
      : DateTime.parse(json['delivered_at'] as String),
  settledAt: json['settled_at'] == null
      ? null
      : DateTime.parse(json['settled_at'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$OrderToJson(_Order instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'status': _$OrderStatusEnumMap[instance.status]!,
  'status_label': instance.statusLabel,
  'production_flow_label': instance.productionFlowLabel,
  'is_final': instance.isFinal,
  'is_closed': instance.isClosed,
  'available_transitions': instance.availableTransitions
      .map((e) => e.toJson())
      .toList(),
  'customer_id': instance.customerId,
  'city_id': instance.cityId,
  'design_source': instance.designSource,
  'city_name': instance.cityName,
  'fulfilment_type_label': instance.fulfilmentTypeLabel,
  'is_office_pickup': instance.isOfficePickup,
  'design_source_label': instance.designSourceLabel,
  'items_total': instance.itemsTotal,
  'design_fee': instance.designFee,
  'delivery_price': instance.deliveryPrice,
  'discount': instance.discount,
  'additional_cost': instance.additionalCost,
  'additional_cost_reason':
      _$AdditionalCostReasonEnumMap[instance.additionalCostReason],
  'additional_cost_reason_label': instance.additionalCostReasonLabel,
  'additional_cost_note': instance.additionalCostNote,
  'grand_total': instance.grandTotal,
  'paid_amount': instance.paidAmount,
  'written_off_amount': instance.writtenOffAmount,
  'remaining_amount': instance.remainingAmount,
  'payment_status': _$PaymentStatusEnumMap[instance.paymentStatus]!,
  'payment_status_label': instance.paymentStatusLabel,
  'has_unrecorded_money': instance.hasUnrecordedMoney,
  'collected_amount': instance.collectedAmount,
  'customer': instance.customer?.toJson(),
  'region_id': instance.regionId,
  'customer_shop_id': instance.customerShopId,
  'region_name': instance.regionName,
  'customer_shop_name': instance.customerShopName,
  'recipient_name': instance.recipientName,
  'recipient_phone': instance.recipientPhone,
  'address_details': instance.addressDetails,
  'notes': instance.notes,
  'shipping_company': instance.shippingCompany,
  'tracking_number': instance.trackingNumber,
  'courier_phone': instance.courierPhone,
  'cancellation_reason': instance.cancellationReason,
  'progress': instance.progress.toJson(),
  'items_are_editable': instance.itemsAreEditable,
  'designs_are_editable': instance.designsAreEditable,
  'destination_is_editable': instance.destinationIsEditable,
  'items_count': instance.itemsCount,
  'items': instance.items?.map((e) => e.toJson()).toList(),
  'designs': instance.designs?.map((e) => e.toJson()).toList(),
  'transitions': instance.transitions?.map((e) => e.toJson()).toList(),
  'total_cogs': instance.totalCogs,
  'gross_profit': instance.grossProfit,
  'fulfillment_warehouse_id': instance.fulfillmentWarehouseId,
  'stock_deducted_at': instance.stockDeductedAt?.toIso8601String(),
  'placed_at': instance.placedAt?.toIso8601String(),
  'delivered_at': instance.deliveredAt?.toIso8601String(),
  'settled_at': instance.settledAt?.toIso8601String(),
  'created_at': instance.createdAt?.toIso8601String(),
};

const _$OrderStatusEnumMap = {
  OrderStatus.taken: 'new',
  OrderStatus.readyToPrint: 'ready_to_print',
  OrderStatus.designing: 'designing',
  OrderStatus.printing: 'printing',
  OrderStatus.ready: 'ready',
  OrderStatus.shortage: 'shortage',
  OrderStatus.officePickup: 'office_pickup',
  OrderStatus.outForDelivery: 'out_for_delivery',
  OrderStatus.returnedCourier: 'returned_courier',
  OrderStatus.returnedCarrier: 'returned_carrier',
  OrderStatus.returnedOffice: 'returned_office',
  OrderStatus.resend: 'resend',
  OrderStatus.cancelled: 'cancelled',
  OrderStatus.delivered: 'delivered',
  OrderStatus.settled: 'settled',
  OrderStatus.unknown: 'unknown',
};

const _$AdditionalCostReasonEnumMap = {
  AdditionalCostReason.specialPackaging: 'special_packaging',
  AdditionalCostReason.extraService: 'extra_service',
  AdditionalCostReason.modification: 'modification',
  AdditionalCostReason.transport: 'transport',
  AdditionalCostReason.other: 'other',
  AdditionalCostReason.unknown: 'unknown',
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.unpaid: 'unpaid',
  PaymentStatus.partiallyPaid: 'partially_paid',
  PaymentStatus.paid: 'paid',
  PaymentStatus.overpaid: 'overpaid',
  PaymentStatus.writtenOff: 'written_off',
  PaymentStatus.unknown: 'unknown',
};

_OrderProgress _$OrderProgressFromJson(Map<String, dynamic> json) =>
    _OrderProgress(
      steps:
          (json['steps'] as List<dynamic>?)
              ?.map((e) => OrderStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <OrderStep>[],
      isDetour: json['is_detour'] as bool? ?? false,
    );

Map<String, dynamic> _$OrderProgressToJson(_OrderProgress instance) =>
    <String, dynamic>{
      'steps': instance.steps.map((e) => e.toJson()).toList(),
      'is_detour': instance.isDetour,
    };

_OrderStep _$OrderStepFromJson(Map<String, dynamic> json) => _OrderStep(
  status: json['status'] as String,
  label: json['label'] as String,
  state: json['state'] as String,
);

Map<String, dynamic> _$OrderStepToJson(_OrderStep instance) =>
    <String, dynamic>{
      'status': instance.status,
      'label': instance.label,
      'state': instance.state,
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
      fields:
          (json['fields'] as List<dynamic>?)
              ?.map((e) => TransitionField.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <TransitionField>[],
    );

Map<String, dynamic> _$OrderTransitionToJson(_OrderTransition instance) =>
    <String, dynamic>{
      'status': _$OrderStatusEnumMap[instance.status]!,
      'label': instance.label,
      'requires_reason': instance.requiresReason,
      'fields': instance.fields.map((e) => e.toJson()).toList(),
    };

_OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => _OrderItem(
  id: (json['id'] as num).toInt(),
  productId: (json['product_id'] as num).toInt(),
  productVariantId: (json['product_variant_id'] as num).toInt(),
  productName: json['product_name'] as String,
  variantLabel: json['variant_label'] as String,
  productCode: json['product_code'] as String?,
  productImage: json['product_image'] == null
      ? null
      : ProductImage.fromJson(json['product_image'] as Map<String, dynamic>),
  pricingUnitLabel: json['pricing_unit_label'] as String,
  quantity: json['quantity'] as String,
  shortageQuantity: json['shortage_quantity'] as String?,
  billableQuantity: json['billable_quantity'] as String?,
  warehouseQuantity: json['warehouse_quantity'] as String?,
  unitPrice: json['unit_price'] as String,
  lineTotal: json['line_total'] as String,
  materialCost: json['material_cost'] as String?,
  laborCost: json['labor_cost'] as String?,
  overheadCost: json['overhead_cost'] as String?,
  cogs: json['cogs'] as String?,
  unitMaterialCost: json['unit_material_cost'] as String?,
  stockUnitLabel: json['stock_unit_label'] as String?,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$OrderItemToJson(_OrderItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'product_id': instance.productId,
      'product_variant_id': instance.productVariantId,
      'product_name': instance.productName,
      'variant_label': instance.variantLabel,
      'product_code': instance.productCode,
      'product_image': instance.productImage?.toJson(),
      'pricing_unit_label': instance.pricingUnitLabel,
      'quantity': instance.quantity,
      'shortage_quantity': instance.shortageQuantity,
      'billable_quantity': instance.billableQuantity,
      'warehouse_quantity': instance.warehouseQuantity,
      'unit_price': instance.unitPrice,
      'line_total': instance.lineTotal,
      'material_cost': instance.materialCost,
      'labor_cost': instance.laborCost,
      'overhead_cost': instance.overheadCost,
      'cogs': instance.cogs,
      'unit_material_cost': instance.unitMaterialCost,
      'stock_unit_label': instance.stockUnitLabel,
      'notes': instance.notes,
    };

_OrderDesign _$OrderDesignFromJson(Map<String, dynamic> json) => _OrderDesign(
  id: (json['id'] as num).toInt(),
  version: (json['version'] as num).toInt(),
  status: json['status'] as String,
  statusLabel: json['status_label'] as String,
  isReviewed: json['is_reviewed'] as bool? ?? false,
  design: json['design'] == null
      ? null
      : CustomerDesign.fromJson(json['design'] as Map<String, dynamic>),
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
      'design': instance.design?.toJson(),
      'rejection_reason': instance.rejectionReason,
      'notes': instance.notes,
      'created_at': instance.createdAt?.toIso8601String(),
    };

_OrderActor _$OrderActorFromJson(Map<String, dynamic> json) =>
    _OrderActor(id: (json['id'] as num).toInt(), name: json['name'] as String);

Map<String, dynamic> _$OrderActorToJson(_OrderActor instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_OrderTransitionRecord _$OrderTransitionRecordFromJson(
  Map<String, dynamic> json,
) => _OrderTransitionRecord(
  id: (json['id'] as num).toInt(),
  fromStatusLabel: json['from_status_label'] as String?,
  toStatus:
      $enumDecodeNullable(
        _$OrderStatusEnumMap,
        json['to_status'],
        unknownValue: OrderStatus.unknown,
      ) ??
      OrderStatus.unknown,
  toStatusLabel: json['to_status_label'] as String,
  reason: json['reason'] as String?,
  user: json['user'] == null
      ? null
      : OrderActor.fromJson(json['user'] as Map<String, dynamic>),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$OrderTransitionRecordToJson(
  _OrderTransitionRecord instance,
) => <String, dynamic>{
  'id': instance.id,
  'from_status_label': instance.fromStatusLabel,
  'to_status': _$OrderStatusEnumMap[instance.toStatus]!,
  'to_status_label': instance.toStatusLabel,
  'reason': instance.reason,
  'user': instance.user?.toJson(),
  'created_at': instance.createdAt?.toIso8601String(),
};
