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
  payments:
      (json['payments'] as List<dynamic>?)
          ?.map((e) => OrderStatusCount.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <OrderStatusCount>[],
  readyMessage: json['ready_message'] == null
      ? null
      : ReadyMessageQueue.fromJson(
          json['ready_message'] as Map<String, dynamic>,
        ),
  returnMessage: json['return_message'] == null
      ? null
      : ReadyMessageQueue.fromJson(
          json['return_message'] as Map<String, dynamic>,
        ),
  instant: json['instant'] == null
      ? null
      : InstantBoard.fromJson(json['instant'] as Map<String, dynamic>),
);

Map<String, dynamic> _$HomeSummaryToJson(_HomeSummary instance) =>
    <String, dynamic>{
      'total_orders': instance.totalOrders,
      'customers_count': instance.customersCount,
      'daily_orders': instance.dailyOrders,
      'monthly_orders': instance.monthlyOrders,
      'statuses': instance.statuses.map((e) => e.toJson()).toList(),
      'payments': instance.payments.map((e) => e.toJson()).toList(),
      'ready_message': instance.readyMessage?.toJson(),
      'return_message': instance.returnMessage?.toJson(),
      'instant': instance.instant?.toJson(),
    };

_ReadyMessageQueue _$ReadyMessageQueueFromJson(Map<String, dynamic> json) =>
    _ReadyMessageQueue(
      count: (json['count'] as num).toInt(),
      label: json['label'] as String,
    );

Map<String, dynamic> _$ReadyMessageQueueToJson(_ReadyMessageQueue instance) =>
    <String, dynamic>{'count': instance.count, 'label': instance.label};

_InstantBoard _$InstantBoardFromJson(Map<String, dynamic> json) =>
    _InstantBoard(
      canCreate: json['can_create'] as bool? ?? false,
      branches:
          (json['branches'] as List<dynamic>?)
              ?.map((e) => BranchRef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <BranchRef>[],
      statuses:
          (json['statuses'] as List<dynamic>?)
              ?.map((e) => OrderStatusCount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <OrderStatusCount>[],
      lateCount: (json['late_count'] as num?)?.toInt() ?? 0,
      lateAfterHours: (json['late_after_hours'] as num?)?.toInt() ?? 24,
      pickupCount: (json['pickup_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$InstantBoardToJson(_InstantBoard instance) =>
    <String, dynamic>{
      'can_create': instance.canCreate,
      'branches': instance.branches.map((e) => e.toJson()).toList(),
      'statuses': instance.statuses.map((e) => e.toJson()).toList(),
      'late_count': instance.lateCount,
      'late_after_hours': instance.lateAfterHours,
      'pickup_count': instance.pickupCount,
    };

_BranchRef _$BranchRefFromJson(Map<String, dynamic> json) =>
    _BranchRef(id: (json['id'] as num).toInt(), name: json['name'] as String);

Map<String, dynamic> _$BranchRefToJson(_BranchRef instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_OrderStatusCount _$OrderStatusCountFromJson(Map<String, dynamic> json) =>
    _OrderStatusCount(
      status: json['status'] as String,
      label: json['label'] as String,
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$OrderStatusCountToJson(_OrderStatusCount instance) =>
    <String, dynamic>{
      'status': instance.status,
      'label': instance.label,
      'count': instance.count,
    };
