// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profit_sources.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfitSources _$ProfitSourcesFromJson(Map<String, dynamic> json) =>
    _ProfitSources(
      gate: json['gate'] as String,
      total: json['total'] as String,
      groups:
          (json['groups'] as List<dynamic>?)
              ?.map(
                (e) => ProfitSourceGroup.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <ProfitSourceGroup>[],
    );

Map<String, dynamic> _$ProfitSourcesToJson(_ProfitSources instance) =>
    <String, dynamic>{
      'gate': instance.gate,
      'total': instance.total,
      'groups': instance.groups.map((e) => e.toJson()).toList(),
    };

_ProfitSourceGroup _$ProfitSourceGroupFromJson(Map<String, dynamic> json) =>
    _ProfitSourceGroup(
      key: json['key'] as String,
      title: json['title'] as String?,
      startsOn: json['starts_on'] as String?,
      endsOn: json['ends_on'] as String?,
      status: json['status'] as String?,
      statusLabel: json['status_label'] as String?,
      total: json['total'] as String,
      lines:
          (json['lines'] as List<dynamic>?)
              ?.map((e) => ProfitSourceLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ProfitSourceLine>[],
    );

Map<String, dynamic> _$ProfitSourceGroupToJson(_ProfitSourceGroup instance) =>
    <String, dynamic>{
      'key': instance.key,
      'title': instance.title,
      'starts_on': instance.startsOn,
      'ends_on': instance.endsOn,
      'status': instance.status,
      'status_label': instance.statusLabel,
      'total': instance.total,
      'lines': instance.lines.map((e) => e.toJson()).toList(),
    };

_ProfitSourceLine _$ProfitSourceLineFromJson(Map<String, dynamic> json) =>
    _ProfitSourceLine(
      kind: json['kind'] as String,
      key: json['key'] as String,
      amount: json['amount'] as String,
      label: json['label'] as String?,
      orderId: (json['order_id'] as num?)?.toInt(),
      code: json['code'] as String?,
      customerName: json['customer_name'] as String?,
      orderStatusLabel: json['order_status_label'] as String?,
      state: json['state'] as String?,
      stateLabel: json['state_label'] as String?,
      occurredAt: json['occurred_at'] as String?,
      children:
          (json['children'] as List<dynamic>?)
              ?.map((e) => ProfitSourceLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ProfitSourceLine>[],
    );

Map<String, dynamic> _$ProfitSourceLineToJson(_ProfitSourceLine instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'key': instance.key,
      'amount': instance.amount,
      'label': instance.label,
      'order_id': instance.orderId,
      'code': instance.code,
      'customer_name': instance.customerName,
      'order_status_label': instance.orderStatusLabel,
      'state': instance.state,
      'state_label': instance.stateLabel,
      'occurred_at': instance.occurredAt,
      'children': instance.children.map((e) => e.toJson()).toList(),
    };
