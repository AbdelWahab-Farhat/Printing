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

_MoneyEffectLine _$MoneyEffectLineFromJson(Map<String, dynamic> json) =>
    _MoneyEffectLine(
      label: json['label'] as String,
      amount: json['amount'] as String,
      currency: json['currency'] as String,
    );

Map<String, dynamic> _$MoneyEffectLineToJson(_MoneyEffectLine instance) =>
    <String, dynamic>{
      'label': instance.label,
      'amount': instance.amount,
      'currency': instance.currency,
    };

_MoneyEffect _$MoneyEffectFromJson(Map<String, dynamic> json) => _MoneyEffect(
  kind: $enumDecode(
    _$MoneyEffectKindEnumMap,
    json['kind'],
    unknownValue: MoneyEffectKind.unknown,
  ),
  warning: json['warning'] as String,
  lines:
      (json['lines'] as List<dynamic>?)
          ?.map((e) => MoneyEffectLine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MoneyEffectLine>[],
  note: json['note'] as String?,
);

Map<String, dynamic> _$MoneyEffectToJson(_MoneyEffect instance) =>
    <String, dynamic>{
      'kind': _$MoneyEffectKindEnumMap[instance.kind]!,
      'warning': instance.warning,
      'lines': instance.lines.map((e) => e.toJson()).toList(),
      'note': instance.note,
    };

const _$MoneyEffectKindEnumMap = {
  MoneyEffectKind.reverse: 'reverse',
  MoneyEffectKind.reversed: 'reversed',
  MoneyEffectKind.unknown: 'unknown',
};

_WarehouseEffect _$WarehouseEffectFromJson(Map<String, dynamic> json) =>
    _WarehouseEffect(
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

Map<String, dynamic> _$WarehouseEffectToJson(_WarehouseEffect instance) =>
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

_StockEffect _$StockEffectFromJson(Map<String, dynamic> json) => _StockEffect(
  stock: WarehouseEffect.fromJson(json['stock'] as Map<String, dynamic>),
  money: json['money'] == null
      ? null
      : MoneyEffect.fromJson(json['money'] as Map<String, dynamic>),
);

Map<String, dynamic> _$StockEffectToJson(_StockEffect instance) =>
    <String, dynamic>{
      'stock': instance.stock.toJson(),
      'money': instance.money?.toJson(),
    };
