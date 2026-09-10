// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_effect.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StockEffectLine _$StockEffectLineFromJson(Map<String, dynamic> json) =>
    _StockEffectLine(
      label: json['label'] as String,
      quantity: json['quantity'] as String,
      unit: json['unit'] as String,
    );

Map<String, dynamic> _$StockEffectLineToJson(_StockEffectLine instance) =>
    <String, dynamic>{
      'label': instance.label,
      'quantity': instance.quantity,
      'unit': instance.unit,
    };

_StockEffect _$StockEffectFromJson(Map<String, dynamic> json) => _StockEffect(
  kind: $enumDecode(
    _$StockEffectKindEnumMap,
    json['kind'],
    unknownValue: StockEffectKind.unknown,
  ),
  warning: json['warning'] as String,
  lines:
      (json['lines'] as List<dynamic>?)
          ?.map((e) => StockEffectLine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <StockEffectLine>[],
  note: json['note'] as String?,
);

Map<String, dynamic> _$StockEffectToJson(_StockEffect instance) =>
    <String, dynamic>{
      'kind': _$StockEffectKindEnumMap[instance.kind]!,
      'warning': instance.warning,
      'lines': instance.lines.map((e) => e.toJson()).toList(),
      'note': instance.note,
    };

const _$StockEffectKindEnumMap = {
  StockEffectKind.returnToShelf: 'return',
  StockEffectKind.rededuct: 'rededuct',
  StockEffectKind.none: 'none',
  StockEffectKind.unknown: 'unknown',
};
