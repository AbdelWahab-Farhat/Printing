// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shortage_supply.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShortageSupply _$ShortageSupplyFromJson(Map<String, dynamic> json) =>
    _ShortageSupply(
      id: (json['id'] as num).toInt(),
      shortageId: (json['shortage_id'] as num).toInt(),
      kind: $enumDecode(
        _$SupplyKindEnumMap,
        json['kind'],
        unknownValue: SupplyKind.unknown,
      ),
      kindLabel: json['kind_label'] as String,
      quantity: json['quantity'] as String,
      amount: json['amount'] as String?,
      method: json['method'] as String?,
      methodLabel: json['method_label'] as String?,
      reference: json['reference'] as String?,
      occurredOn: json['occurred_on'] as String?,
      notes: json['notes'] as String?,
      warehouseId: (json['warehouse_id'] as num?)?.toInt(),
      warehouse: json['warehouse'] == null
          ? null
          : ShortageSupplyWarehouseRef.fromJson(
              json['warehouse'] as Map<String, dynamic>,
            ),
      stockMovementId: (json['stock_movement_id'] as num?)?.toInt(),
      movedStock: json['moved_stock'] as bool? ?? false,
      isReversal: json['is_reversal'] as bool? ?? false,
      isReversed: json['is_reversed'] as bool? ?? false,
      isReversible: json['is_reversible'] as bool? ?? false,
      hasReceipt: json['has_receipt'] as bool? ?? false,
      receiptIsImage: json['receipt_is_image'] as bool? ?? false,
      receiptUrl: json['receipt_url'] as String?,
      receiptFilename: json['receipt_filename'] as String?,
      reversesSupplyId: (json['reverses_supply_id'] as num?)?.toInt(),
      recordedByUserId: (json['recorded_by_user_id'] as num?)?.toInt(),
      recorder: json['recorder'] == null
          ? null
          : ShortageSupplyPersonRef.fromJson(
              json['recorder'] as Map<String, dynamic>,
            ),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ShortageSupplyToJson(_ShortageSupply instance) =>
    <String, dynamic>{
      'id': instance.id,
      'shortage_id': instance.shortageId,
      'kind': _$SupplyKindEnumMap[instance.kind]!,
      'kind_label': instance.kindLabel,
      'quantity': instance.quantity,
      'amount': instance.amount,
      'method': instance.method,
      'method_label': instance.methodLabel,
      'reference': instance.reference,
      'occurred_on': instance.occurredOn,
      'notes': instance.notes,
      'warehouse_id': instance.warehouseId,
      'warehouse': instance.warehouse?.toJson(),
      'stock_movement_id': instance.stockMovementId,
      'moved_stock': instance.movedStock,
      'is_reversal': instance.isReversal,
      'is_reversed': instance.isReversed,
      'is_reversible': instance.isReversible,
      'has_receipt': instance.hasReceipt,
      'receipt_is_image': instance.receiptIsImage,
      'receipt_url': instance.receiptUrl,
      'receipt_filename': instance.receiptFilename,
      'reverses_supply_id': instance.reversesSupplyId,
      'recorded_by_user_id': instance.recordedByUserId,
      'recorder': instance.recorder?.toJson(),
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$SupplyKindEnumMap = {
  SupplyKind.purchased: 'purchased',
  SupplyKind.resolvedExternally: 'resolved_externally',
  SupplyKind.reversal: 'reversal',
  SupplyKind.unknown: 'unknown',
};

_ShortageSupplyWarehouseRef _$ShortageSupplyWarehouseRefFromJson(
  Map<String, dynamic> json,
) => _ShortageSupplyWarehouseRef(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
);

Map<String, dynamic> _$ShortageSupplyWarehouseRefToJson(
  _ShortageSupplyWarehouseRef instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};

_ShortageSupplyPersonRef _$ShortageSupplyPersonRefFromJson(
  Map<String, dynamic> json,
) => _ShortageSupplyPersonRef(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  employeeCode: json['employee_code'] as String?,
);

Map<String, dynamic> _$ShortageSupplyPersonRefToJson(
  _ShortageSupplyPersonRef instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'employee_code': instance.employeeCode,
};
