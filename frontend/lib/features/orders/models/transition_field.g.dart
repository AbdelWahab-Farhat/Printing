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
      options:
          (json['options'] as List<dynamic>?)
              ?.map(
                (e) =>
                    TransitionFieldOption.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <TransitionFieldOption>[],
      requiredWith: json['required_with'] as String?,
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
      'options': instance.options.map((e) => e.toJson()).toList(),
      'required_with': instance.requiredWith,
      'value': instance.value,
    };

const _$TransitionFieldTypeEnumMap = {
  TransitionFieldType.text: 'text',
  TransitionFieldType.number: 'number',
  TransitionFieldType.customerDesigns: 'customer_designs',
  TransitionFieldType.shippingCompany: 'shipping_company',
  TransitionFieldType.warehouse: 'warehouse',
  TransitionFieldType.paymentMethod: 'payment_method',
  TransitionFieldType.unknown: 'unknown',
};

_TransitionFieldOption _$TransitionFieldOptionFromJson(
  Map<String, dynamic> json,
) => _TransitionFieldOption(
  value: json['value'] as String,
  label: json['label'] as String,
);

Map<String, dynamic> _$TransitionFieldOptionToJson(
  _TransitionFieldOption instance,
) => <String, dynamic>{'value': instance.value, 'label': instance.label};
