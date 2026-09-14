// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shortage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShortageTransition _$ShortageTransitionFromJson(Map<String, dynamic> json) =>
    _ShortageTransition(
      value: json['value'] as String,
      label: json['label'] as String,
    );

Map<String, dynamic> _$ShortageTransitionToJson(_ShortageTransition instance) =>
    <String, dynamic>{'value': instance.value, 'label': instance.label};

_ShortageOrderRef _$ShortageOrderRefFromJson(Map<String, dynamic> json) =>
    _ShortageOrderRef(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      status: json['status'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
    );

Map<String, dynamic> _$ShortageOrderRefToJson(_ShortageOrderRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'status': instance.status,
      'is_archived': instance.isArchived,
    };

_ShortagePerson _$ShortagePersonFromJson(Map<String, dynamic> json) =>
    _ShortagePerson(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      employeeCode: json['employee_code'] as String?,
    );

Map<String, dynamic> _$ShortagePersonToJson(_ShortagePerson instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'employee_code': instance.employeeCode,
    };

_ShortageCustomerRef _$ShortageCustomerRefFromJson(Map<String, dynamic> json) =>
    _ShortageCustomerRef(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      phone: json['phone'] as String?,
    );

Map<String, dynamic> _$ShortageCustomerRefToJson(
  _ShortageCustomerRef instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'phone': instance.phone,
};

_ShortageProductRef _$ShortageProductRefFromJson(Map<String, dynamic> json) =>
    _ShortageProductRef(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$ShortageProductRefToJson(_ShortageProductRef instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_ShortageVariantRef _$ShortageVariantRefFromJson(Map<String, dynamic> json) =>
    _ShortageVariantRef(
      id: (json['id'] as num).toInt(),
      label: json['label'] as String,
    );

Map<String, dynamic> _$ShortageVariantRefToJson(_ShortageVariantRef instance) =>
    <String, dynamic>{'id': instance.id, 'label': instance.label};

_Shortage _$ShortageFromJson(Map<String, dynamic> json) => _Shortage(
  id: (json['id'] as num).toInt(),
  code: json['code'] as String,
  source: $enumDecode(
    _$ShortageSourceEnumMap,
    json['source'],
    unknownValue: ShortageSource.unknown,
  ),
  sourceLabel: json['source_label'] as String,
  name: json['name'] as String,
  unit: json['unit'] as String?,
  unitLabel: json['unit_label'] as String?,
  requiredQuantity: json['required_quantity'] as String,
  suppliedQuantity: json['supplied_quantity'] as String,
  remainingQuantity: json['remaining_quantity'] as String,
  totalPaid: json['total_paid'] as String,
  status: $enumDecode(
    _$ShortageStatusEnumMap,
    json['status'],
    unknownValue: ShortageStatus.unknown,
  ),
  statusLabel: json['status_label'] as String,
  isFinal: json['is_final'] as bool? ?? false,
  availableTransitions:
      (json['available_transitions'] as List<dynamic>?)
          ?.map((e) => ShortageTransition.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ShortageTransition>[],
  isEditable: json['is_editable'] as bool? ?? false,
  isStockable: json['is_stockable'] as bool? ?? false,
  orderId: (json['order_id'] as num?)?.toInt(),
  orderItemId: (json['order_item_id'] as num?)?.toInt(),
  order: json['order'] == null
      ? null
      : ShortageOrderRef.fromJson(json['order'] as Map<String, dynamic>),
  customerId: (json['customer_id'] as num?)?.toInt(),
  customer: json['customer'] == null
      ? null
      : ShortageCustomerRef.fromJson(json['customer'] as Map<String, dynamic>),
  productId: (json['product_id'] as num?)?.toInt(),
  productVariantId: (json['product_variant_id'] as num?)?.toInt(),
  product: json['product'] == null
      ? null
      : ShortageProductRef.fromJson(json['product'] as Map<String, dynamic>),
  variant: json['variant'] == null
      ? null
      : ShortageVariantRef.fromJson(json['variant'] as Map<String, dynamic>),
  assignedToUserId: (json['assigned_to_user_id'] as num?)?.toInt(),
  assignee: json['assignee'] == null
      ? null
      : ShortagePerson.fromJson(json['assignee'] as Map<String, dynamic>),
  createdByUserId: (json['created_by_user_id'] as num?)?.toInt(),
  creator: json['creator'] == null
      ? null
      : ShortagePerson.fromJson(json['creator'] as Map<String, dynamic>),
  description: json['description'] as String?,
  supplies:
      (json['supplies'] as List<dynamic>?)
          ?.map((e) => ShortageSupply.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ShortageSupply>[],
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ShortageToJson(_Shortage instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'source': _$ShortageSourceEnumMap[instance.source]!,
  'source_label': instance.sourceLabel,
  'name': instance.name,
  'unit': instance.unit,
  'unit_label': instance.unitLabel,
  'required_quantity': instance.requiredQuantity,
  'supplied_quantity': instance.suppliedQuantity,
  'remaining_quantity': instance.remainingQuantity,
  'total_paid': instance.totalPaid,
  'status': _$ShortageStatusEnumMap[instance.status]!,
  'status_label': instance.statusLabel,
  'is_final': instance.isFinal,
  'available_transitions': instance.availableTransitions
      .map((e) => e.toJson())
      .toList(),
  'is_editable': instance.isEditable,
  'is_stockable': instance.isStockable,
  'order_id': instance.orderId,
  'order_item_id': instance.orderItemId,
  'order': instance.order?.toJson(),
  'customer_id': instance.customerId,
  'customer': instance.customer?.toJson(),
  'product_id': instance.productId,
  'product_variant_id': instance.productVariantId,
  'product': instance.product?.toJson(),
  'variant': instance.variant?.toJson(),
  'assigned_to_user_id': instance.assignedToUserId,
  'assignee': instance.assignee?.toJson(),
  'created_by_user_id': instance.createdByUserId,
  'creator': instance.creator?.toJson(),
  'description': instance.description,
  'supplies': instance.supplies.map((e) => e.toJson()).toList(),
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

const _$ShortageSourceEnumMap = {
  ShortageSource.manual: 'manual',
  ShortageSource.order: 'order',
  ShortageSource.unknown: 'unknown',
};

const _$ShortageStatusEnumMap = {
  ShortageStatus.fresh: 'new',
  ShortageStatus.searching: 'searching',
  ShortageStatus.unavailable: 'unavailable',
  ShortageStatus.completed: 'completed',
  ShortageStatus.unknown: 'unknown',
};
