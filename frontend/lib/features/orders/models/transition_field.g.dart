// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transition_field.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TransitionField _$TransitionFieldFromJson(Map<String, dynamic> json) =>
    _TransitionField(
      key: json['key'] as String,
      type: $enumDecode(
        _$TransitionFieldTypeEnumMap,
        json['type'],
        unknownValue: TransitionFieldType.unknown,
      ),
      label: json['label'] as String,
      isRequired: json['required'] as bool? ?? false,
      multiple: json['multiple'] as bool? ?? false,
      multiline: json['multiline'] as bool? ?? false,
      hint: json['hint'] as String?,
      min: json['min'] as num?,
      max: json['max'] as num?,
      value: json['value'] as String?,
    );

Map<String, dynamic> _$TransitionFieldToJson(_TransitionField instance) =>
    <String, dynamic>{
      'key': instance.key,
      'type': _$TransitionFieldTypeEnumMap[instance.type]!,
      'label': instance.label,
      'required': instance.isRequired,
      'multiple': instance.multiple,
      'multiline': instance.multiline,
      'hint': instance.hint,
      'min': instance.min,
      'max': instance.max,
      'value': instance.value,
    };

const _$TransitionFieldTypeEnumMap = {
  TransitionFieldType.text: 'text',
  TransitionFieldType.number: 'number',
  TransitionFieldType.customerDesigns: 'customer_designs',
  TransitionFieldType.shippingCompany: 'shipping_company',
  TransitionFieldType.unknown: 'unknown',
};
