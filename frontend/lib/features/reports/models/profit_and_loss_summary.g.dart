// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profit_and_loss_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfitAndLossSummary _$ProfitAndLossSummaryFromJson(
  Map<String, dynamic> json,
) => _ProfitAndLossSummary(
  period: PnlPeriod.fromJson(json['period'] as Map<String, dynamic>),
  revenue: PnlRevenue.fromJson(json['revenue'] as Map<String, dynamic>),
  costOfGoodsSold: PnlCostOfGoodsSold.fromJson(
    json['cost_of_goods_sold'] as Map<String, dynamic>,
  ),
  grossProfit: json['gross_profit'] as String,
  cashCollected: json['cash_collected'] as String,
  ordersRecognized: (json['orders_recognized'] as num).toInt(),
);

Map<String, dynamic> _$ProfitAndLossSummaryToJson(
  _ProfitAndLossSummary instance,
) => <String, dynamic>{
  'period': instance.period.toJson(),
  'revenue': instance.revenue.toJson(),
  'cost_of_goods_sold': instance.costOfGoodsSold.toJson(),
  'gross_profit': instance.grossProfit,
  'cash_collected': instance.cashCollected,
  'orders_recognized': instance.ordersRecognized,
};

_PnlPeriod _$PnlPeriodFromJson(Map<String, dynamic> json) =>
    _PnlPeriod(from: json['from'] as String, to: json['to'] as String);

Map<String, dynamic> _$PnlPeriodToJson(_PnlPeriod instance) =>
    <String, dynamic>{'from': instance.from, 'to': instance.to};

_PnlRevenue _$PnlRevenueFromJson(Map<String, dynamic> json) => _PnlRevenue(
  product: json['product'] as String,
  service: json['service'] as String,
  total: json['total'] as String,
);

Map<String, dynamic> _$PnlRevenueToJson(_PnlRevenue instance) =>
    <String, dynamic>{
      'product': instance.product,
      'service': instance.service,
      'total': instance.total,
    };

_PnlCostOfGoodsSold _$PnlCostOfGoodsSoldFromJson(Map<String, dynamic> json) =>
    _PnlCostOfGoodsSold(
      material: json['material'] as String,
      labor: json['labor'] as String,
      overhead: json['overhead'] as String,
      total: json['total'] as String,
    );

Map<String, dynamic> _$PnlCostOfGoodsSoldToJson(_PnlCostOfGoodsSold instance) =>
    <String, dynamic>{
      'material': instance.material,
      'labor': instance.labor,
      'overhead': instance.overhead,
      'total': instance.total,
    };
