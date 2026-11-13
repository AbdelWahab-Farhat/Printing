// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_preference.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PushPreferenceGroup _$PushPreferenceGroupFromJson(Map<String, dynamic> json) =>
    _PushPreferenceGroup(
      type: json['type'] as String,
      label: json['label'] as String,
      icon: json['icon'] as String,
      switches: (json['switches'] as List<dynamic>)
          .map((e) => PushSwitch.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PushPreferenceGroupToJson(
  _PushPreferenceGroup instance,
) => <String, dynamic>{
  'type': instance.type,
  'label': instance.label,
  'icon': instance.icon,
  'switches': instance.switches.map((e) => e.toJson()).toList(),
};

_PushSwitch _$PushSwitchFromJson(Map<String, dynamic> json) => _PushSwitch(
  scope: json['scope'] as String,
  label: json['label'] as String,
  push: json['push'] as bool,
);

Map<String, dynamic> _$PushSwitchToJson(_PushSwitch instance) =>
    <String, dynamic>{
      'scope': instance.scope,
      'label': instance.label,
      'push': instance.push,
    };
