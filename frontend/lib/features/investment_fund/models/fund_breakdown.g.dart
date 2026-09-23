// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fund_breakdown.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FundCashEntry _$FundCashEntryFromJson(Map<String, dynamic> json) =>
    _FundCashEntry(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String,
      typeLabel: json['type_label'] as String,
      isInflow: json['is_inflow'] as bool,
      signedAmount: json['signed_amount'] as String,
      balanceAfter: json['balance_after'] as String,
      occurredAt: json['occurred_at'] == null
          ? null
          : DateTime.parse(json['occurred_at'] as String),
      description: json['description'] as String?,
      orderId: (json['order_id'] as num?)?.toInt(),
      purchaseOrderId: (json['purchase_order_id'] as num?)?.toInt(),
      investorId: (json['investor_id'] as num?)?.toInt(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$FundCashEntryToJson(_FundCashEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'type_label': instance.typeLabel,
      'is_inflow': instance.isInflow,
      'signed_amount': instance.signedAmount,
      'balance_after': instance.balanceAfter,
      'occurred_at': instance.occurredAt?.toIso8601String(),
      'description': instance.description,
      'order_id': instance.orderId,
      'purchase_order_id': instance.purchaseOrderId,
      'investor_id': instance.investorId,
      'notes': instance.notes,
    };

_FundShelfMaterial _$FundShelfMaterialFromJson(Map<String, dynamic> json) =>
    _FundShelfMaterial(
      stockItemId: (json['stock_item_id'] as num?)?.toInt(),
      code: json['code'] as String?,
      name: json['name'] as String?,
      unitLabel: json['unit_label'] as String?,
      quantity: json['quantity'] as String,
      value: json['value'] as String,
      batches: (json['batches'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$FundShelfMaterialToJson(_FundShelfMaterial instance) =>
    <String, dynamic>{
      'stock_item_id': instance.stockItemId,
      'code': instance.code,
      'name': instance.name,
      'unit_label': instance.unitLabel,
      'quantity': instance.quantity,
      'value': instance.value,
      'batches': instance.batches,
    };

_FundShelf _$FundShelfFromJson(Map<String, dynamic> json) => _FundShelf(
  total: json['total'] as String,
  materials:
      (json['materials'] as List<dynamic>?)
          ?.map((e) => FundShelfMaterial.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <FundShelfMaterial>[],
);

Map<String, dynamic> _$FundShelfToJson(_FundShelf instance) =>
    <String, dynamic>{
      'total': instance.total,
      'materials': instance.materials.map((e) => e.toJson()).toList(),
    };

_FundGoodsLine _$FundGoodsLineFromJson(Map<String, dynamic> json) =>
    _FundGoodsLine(
      stockItemId: (json['stock_item_id'] as num?)?.toInt(),
      code: json['code'] as String?,
      name: json['name'] as String?,
      unitLabel: json['unit_label'] as String?,
      quantity: json['quantity'] as String,
      cost: json['cost'] as String,
    );

Map<String, dynamic> _$FundGoodsLineToJson(_FundGoodsLine instance) =>
    <String, dynamic>{
      'stock_item_id': instance.stockItemId,
      'code': instance.code,
      'name': instance.name,
      'unit_label': instance.unitLabel,
      'quantity': instance.quantity,
      'cost': instance.cost,
    };

_FundGoodsOrder _$FundGoodsOrderFromJson(Map<String, dynamic> json) =>
    _FundGoodsOrder(
      orderId: (json['order_id'] as num).toInt(),
      code: json['code'] as String,
      status: json['status'] as String,
      statusLabel: json['status_label'] as String,
      customerName: json['customer_name'] as String?,
      placedAt: json['placed_at'] == null
          ? null
          : DateTime.parse(json['placed_at'] as String),
      deliveredAt: json['delivered_at'] == null
          ? null
          : DateTime.parse(json['delivered_at'] as String),
      grandTotal: json['grand_total'] as String,
      paidAmount: json['paid_amount'] as String,
      remaining: json['remaining'] as String,
      cost: json['cost'] as String,
      goods:
          (json['goods'] as List<dynamic>?)
              ?.map((e) => FundGoodsLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <FundGoodsLine>[],
    );

Map<String, dynamic> _$FundGoodsOrderToJson(_FundGoodsOrder instance) =>
    <String, dynamic>{
      'order_id': instance.orderId,
      'code': instance.code,
      'status': instance.status,
      'status_label': instance.statusLabel,
      'customer_name': instance.customerName,
      'placed_at': instance.placedAt?.toIso8601String(),
      'delivered_at': instance.deliveredAt?.toIso8601String(),
      'grand_total': instance.grandTotal,
      'paid_amount': instance.paidAmount,
      'remaining': instance.remaining,
      'cost': instance.cost,
      'goods': instance.goods.map((e) => e.toJson()).toList(),
    };

_FundGoodsOut _$FundGoodsOutFromJson(Map<String, dynamic> json) =>
    _FundGoodsOut(
      total: json['total'] as String,
      orders:
          (json['orders'] as List<dynamic>?)
              ?.map((e) => FundGoodsOrder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <FundGoodsOrder>[],
    );

Map<String, dynamic> _$FundGoodsOutToJson(_FundGoodsOut instance) =>
    <String, dynamic>{
      'total': instance.total,
      'orders': instance.orders.map((e) => e.toJson()).toList(),
    };

_FundProfitAdjustment _$FundProfitAdjustmentFromJson(
  Map<String, dynamic> json,
) => _FundProfitAdjustment(
  kind: json['kind'] as String,
  label: json['label'] as String,
  amount: json['amount'] as String,
);

Map<String, dynamic> _$FundProfitAdjustmentToJson(
  _FundProfitAdjustment instance,
) => <String, dynamic>{
  'kind': instance.kind,
  'label': instance.label,
  'amount': instance.amount,
};

_FundUnreleasedProfit _$FundUnreleasedProfitFromJson(
  Map<String, dynamic> json,
) => _FundUnreleasedProfit(
  total: json['total'] as String? ?? '0.00',
  orders:
      (json['orders'] as List<dynamic>?)
          ?.map((e) => PeriodOrder.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PeriodOrder>[],
  adjustments:
      (json['adjustments'] as List<dynamic>?)
          ?.map((e) => FundProfitAdjustment.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <FundProfitAdjustment>[],
);

Map<String, dynamic> _$FundUnreleasedProfitToJson(
  _FundUnreleasedProfit instance,
) => <String, dynamic>{
  'total': instance.total,
  'orders': instance.orders.map((e) => e.toJson()).toList(),
  'adjustments': instance.adjustments.map((e) => e.toJson()).toList(),
};

_FundWalletProfit _$FundWalletProfitFromJson(Map<String, dynamic> json) =>
    _FundWalletProfit(
      total: json['total'] as String? ?? '0.00',
      investors:
          (json['investors'] as List<dynamic>?)
              ?.map(
                (e) => PeriodInvestorShare.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <PeriodInvestorShare>[],
    );

Map<String, dynamic> _$FundWalletProfitToJson(_FundWalletProfit instance) =>
    <String, dynamic>{
      'total': instance.total,
      'investors': instance.investors.map((e) => e.toJson()).toList(),
    };

_FundProfitOwed _$FundProfitOwedFromJson(Map<String, dynamic> json) =>
    _FundProfitOwed(
      total: json['total'] as String,
      unreleased: json['unreleased'] == null
          ? const FundUnreleasedProfit()
          : FundUnreleasedProfit.fromJson(
              json['unreleased'] as Map<String, dynamic>,
            ),
      inWallets: json['in_wallets'] == null
          ? const FundWalletProfit()
          : FundWalletProfit.fromJson(
              json['in_wallets'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$FundProfitOwedToJson(_FundProfitOwed instance) =>
    <String, dynamic>{
      'total': instance.total,
      'unreleased': instance.unreleased.toJson(),
      'in_wallets': instance.inWallets.toJson(),
    };
