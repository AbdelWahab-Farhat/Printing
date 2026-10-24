// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CustomerOrder _$CustomerOrderFromJson(Map<String, dynamic> json) =>
    _CustomerOrder(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      stage:
          $enumDecodeNullable(
            _$OrderStageEnumMap,
            json['stage'],
            unknownValue: OrderStage.unknown,
          ) ??
          OrderStage.unknown,
      stageLabel: json['stage_label'] as String,
      isOpen: json['is_open'] as bool? ?? true,
      stageHint: json['stage_hint'] as String?,
      summary: json['summary'] as String?,
      itemsCount: (json['items_count'] as num?)?.toInt(),
      total: json['total'] as String?,
      isAwaitingQuote: json['is_awaiting_quote'] as bool? ?? false,
      paidAmount: json['paid_amount'] as String?,
      balance: json['balance'] as String?,
      cityName: json['city_name'] as String?,
      recipientPhone: json['recipient_phone'] as String?,
      fulfilmentType: json['fulfilment_type'] as String?,
      fulfilmentTypeLabel: json['fulfilment_type_label'] as String?,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => OrderLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <OrderLine>[],
      placedAt: json['placed_at'] == null
          ? null
          : DateTime.parse(json['placed_at'] as String),
    );

Map<String, dynamic> _$CustomerOrderToJson(_CustomerOrder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'stage': _$OrderStageEnumMap[instance.stage]!,
      'stage_label': instance.stageLabel,
      'is_open': instance.isOpen,
      'stage_hint': instance.stageHint,
      'summary': instance.summary,
      'items_count': instance.itemsCount,
      'total': instance.total,
      'is_awaiting_quote': instance.isAwaitingQuote,
      'paid_amount': instance.paidAmount,
      'balance': instance.balance,
      'city_name': instance.cityName,
      'recipient_phone': instance.recipientPhone,
      'fulfilment_type': instance.fulfilmentType,
      'fulfilment_type_label': instance.fulfilmentTypeLabel,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'placed_at': instance.placedAt?.toIso8601String(),
    };

const _$OrderStageEnumMap = {
  OrderStage.underReview: 'under_review',
  OrderStage.awaitingDeposit: 'awaiting_deposit',
  OrderStage.preparing: 'preparing',
  OrderStage.shortage: 'shortage',
  OrderStage.designing: 'designing',
  OrderStage.producing: 'producing',
  OrderStage.ready: 'ready',
  OrderStage.officePickup: 'office_pickup',
  OrderStage.onTheWay: 'on_the_way',
  OrderStage.delivered: 'delivered',
  OrderStage.returned: 'returned',
  OrderStage.cancelled: 'cancelled',
  OrderStage.rejected: 'rejected',
  OrderStage.unknown: 'unknown',
};

_OrderLine _$OrderLineFromJson(Map<String, dynamic> json) => _OrderLine(
  id: (json['id'] as num).toInt(),
  productName: json['product_name'] as String,
  variantLabel: json['variant_label'] as String?,
  quantity: json['quantity'] as String,
  pricingUnitLabel: json['pricing_unit_label'] as String?,
  unitPrice: json['unit_price'] as String?,
  lineTotal: json['line_total'] as String?,
  productImageUrl: json['product_image_url'] as String?,
);

Map<String, dynamic> _$OrderLineToJson(_OrderLine instance) =>
    <String, dynamic>{
      'id': instance.id,
      'product_name': instance.productName,
      'variant_label': instance.variantLabel,
      'quantity': instance.quantity,
      'pricing_unit_label': instance.pricingUnitLabel,
      'unit_price': instance.unitPrice,
      'line_total': instance.lineTotal,
      'product_image_url': instance.productImageUrl,
    };

_OrderTimelineEntry _$OrderTimelineEntryFromJson(Map<String, dynamic> json) =>
    _OrderTimelineEntry(
      stage: json['stage'] as String,
      stageLabel: json['stage_label'] as String,
      reachedAt: json['reached_at'] == null
          ? null
          : DateTime.parse(json['reached_at'] as String),
    );

Map<String, dynamic> _$OrderTimelineEntryToJson(_OrderTimelineEntry instance) =>
    <String, dynamic>{
      'stage': instance.stage,
      'stage_label': instance.stageLabel,
      'reached_at': instance.reachedAt?.toIso8601String(),
    };

_CustomerOrderDetail _$CustomerOrderDetailFromJson(
  Map<String, dynamic> json,
) => _CustomerOrderDetail(
  id: (json['id'] as num).toInt(),
  code: json['code'] as String,
  stage:
      $enumDecodeNullable(
        _$OrderStageEnumMap,
        json['stage'],
        unknownValue: OrderStage.unknown,
      ) ??
      OrderStage.unknown,
  stageLabel: json['stage_label'] as String,
  isOpen: json['is_open'] as bool? ?? true,
  stageHint: json['stage_hint'] as String?,
  isReviewed: json['is_reviewed'] as bool?,
  rejectionReason: json['rejection_reason'] as String?,
  cityName: json['city_name'] as String?,
  regionName: json['region_name'] as String?,
  addressDetails: json['address_details'] as String?,
  recipientName: json['recipient_name'] as String?,
  recipientPhone: json['recipient_phone'] as String?,
  fulfilmentType: json['fulfilment_type'] as String?,
  fulfilmentTypeLabel: json['fulfilment_type_label'] as String?,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => OrderLine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <OrderLine>[],
  itemsTotal: json['items_total'] as String?,
  deliveryPrice: json['delivery_price'] as String?,
  designFee: json['design_fee'] as String?,
  discount: json['discount'] as String?,
  total: json['total'] as String?,
  paidAmount: json['paid_amount'] as String?,
  balance: json['balance'] as String?,
  depositDue: json['deposit_due'] as String?,
  depositExpected: json['deposit_expected'] as String?,
  depositAtOffice: json['deposit_at_office'] as bool? ?? false,
  depositOffer: json['deposit_offer'] == null
      ? null
      : DepositOffer.fromJson(json['deposit_offer'] as Map<String, dynamic>),
  isAwaitingQuote: json['is_awaiting_quote'] as bool? ?? false,
  timeline:
      (json['timeline'] as List<dynamic>?)
          ?.map((e) => OrderTimelineEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <OrderTimelineEntry>[],
  placedAt: json['placed_at'] == null
      ? null
      : DateTime.parse(json['placed_at'] as String),
  unreadNotesCount: (json['unread_notes_count'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$CustomerOrderDetailToJson(
  _CustomerOrderDetail instance,
) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'stage': _$OrderStageEnumMap[instance.stage]!,
  'stage_label': instance.stageLabel,
  'is_open': instance.isOpen,
  'stage_hint': instance.stageHint,
  'is_reviewed': instance.isReviewed,
  'rejection_reason': instance.rejectionReason,
  'city_name': instance.cityName,
  'region_name': instance.regionName,
  'address_details': instance.addressDetails,
  'recipient_name': instance.recipientName,
  'recipient_phone': instance.recipientPhone,
  'fulfilment_type': instance.fulfilmentType,
  'fulfilment_type_label': instance.fulfilmentTypeLabel,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'items_total': instance.itemsTotal,
  'delivery_price': instance.deliveryPrice,
  'design_fee': instance.designFee,
  'discount': instance.discount,
  'total': instance.total,
  'paid_amount': instance.paidAmount,
  'balance': instance.balance,
  'deposit_due': instance.depositDue,
  'deposit_expected': instance.depositExpected,
  'deposit_at_office': instance.depositAtOffice,
  'deposit_offer': instance.depositOffer?.toJson(),
  'is_awaiting_quote': instance.isAwaitingQuote,
  'timeline': instance.timeline.map((e) => e.toJson()).toList(),
  'placed_at': instance.placedAt?.toIso8601String(),
  'unread_notes_count': instance.unreadNotesCount,
};

_NewOrderLine _$NewOrderLineFromJson(Map<String, dynamic> json) =>
    _NewOrderLine(
      productId: (json['product_id'] as num).toInt(),
      productVariantId: (json['product_variant_id'] as num).toInt(),
      quantity: json['quantity'] as String,
    );

Map<String, dynamic> _$NewOrderLineToJson(_NewOrderLine instance) =>
    <String, dynamic>{
      'product_id': instance.productId,
      'product_variant_id': instance.productVariantId,
      'quantity': instance.quantity,
    };

_NewOrder _$NewOrderFromJson(Map<String, dynamic> json) => _NewOrder(
  cityId: (json['city_id'] as num).toInt(),
  items: (json['items'] as List<dynamic>)
      .map((e) => NewOrderLine.fromJson(e as Map<String, dynamic>))
      .toList(),
  regionId: (json['region_id'] as num?)?.toInt(),
  customerShopId: (json['customer_shop_id'] as num?)?.toInt(),
  recipientPhone: json['recipient_phone'] as String?,
  designIds:
      (json['design_ids'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[],
  customerNote: json['customer_note'] as String?,
  deposit: json['deposit'] == null
      ? null
      : CheckoutDeposit.fromJson(json['deposit'] as Map<String, dynamic>),
  clientToken: json['client_token'] as String?,
);

Map<String, dynamic> _$NewOrderToJson(_NewOrder instance) => <String, dynamic>{
  'city_id': instance.cityId,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'region_id': instance.regionId,
  'customer_shop_id': instance.customerShopId,
  'recipient_phone': instance.recipientPhone,
  'design_ids': instance.designIds,
  'customer_note': instance.customerNote,
  'deposit': ?instance.deposit?.toJson(),
  'client_token': ?instance.clientToken,
};

_CheckoutDeposit _$CheckoutDepositFromJson(Map<String, dynamic> json) =>
    _CheckoutDeposit(
      payment: $enumDecode(_$CheckoutPaymentEnumMap, json['payment']),
      amount: json['amount'] as String,
      clientToken: json['client_token'] as String?,
    );

Map<String, dynamic> _$CheckoutDepositToJson(_CheckoutDeposit instance) =>
    <String, dynamic>{
      'payment': _$CheckoutPaymentEnumMap[instance.payment]!,
      'amount': instance.amount,
      'client_token': ?instance.clientToken,
    };

const _$CheckoutPaymentEnumMap = {
  CheckoutPayment.office: 'office',
  CheckoutPayment.wallet: 'wallet',
  CheckoutPayment.online: 'online',
};
