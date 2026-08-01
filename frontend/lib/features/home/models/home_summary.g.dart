// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HomeSummary _$HomeSummaryFromJson(Map<String, dynamic> json) => _HomeSummary(
  totalOrders: (json['total_orders'] as num).toInt(),
  customersCount: (json['customers_count'] as num).toInt(),
  dailyOrders: (json['daily_orders'] as num).toInt(),
  monthlyOrders: (json['monthly_orders'] as num).toInt(),
  statuses:
      (json['statuses'] as List<dynamic>?)
          ?.map((e) => OrderStatusCount.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <OrderStatusCount>[],
);

Map<String, dynamic> _$HomeSummaryToJson(_HomeSummary instance) =>
    <String, dynamic>{
      'total_orders': instance.totalOrders,
      'customers_count': instance.customersCount,
      'daily_orders': instance.dailyOrders,
      'monthly_orders': instance.monthlyOrders,
      'statuses': instance.statuses.map((e) => e.toJson()).toList(),
    };

_OrderStatusCount _$OrderStatusCountFromJson(Map<String, dynamic> json) =>
    _OrderStatusCount(
      status: json['status'] as String,
      label: json['label'] as String,
      count: (json['count'] as num).toInt(),
      needsAttention: json['needs_attention'] as bool? ?? false,
    );

Map<String, dynamic> _$OrderStatusCountToJson(_OrderStatusCount instance) =>
    <String, dynamic>{
      'status': instance.status,
      'label': instance.label,
      'count': instance.count,
      'needs_attention': instance.needsAttention,
    };
