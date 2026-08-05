// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_log_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ActivityLogEntry _$ActivityLogEntryFromJson(Map<String, dynamic> json) =>
    _ActivityLogEntry(
      id: (json['id'] as num).toInt(),
      event: json['event'] as String,
      eventLabel: json['event_label'] as String?,
      description: json['description'] as String?,
      subjectType: json['subject_type'] as String?,
      subjectTypeLabel: json['subject_type_label'] as String?,
      subjectId: (json['subject_id'] as num?)?.toInt(),
      causer: json['causer'] == null
          ? null
          : AuditCauser.fromJson(json['causer'] as Map<String, dynamic>),
      changes: json['changes'] == null
          ? null
          : AuditChanges.fromJson(json['changes'] as Map<String, dynamic>),
      attributeLabels: (json['attribute_labels'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ActivityLogEntryToJson(_ActivityLogEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'event': instance.event,
      'event_label': instance.eventLabel,
      'description': instance.description,
      'subject_type': instance.subjectType,
      'subject_type_label': instance.subjectTypeLabel,
      'subject_id': instance.subjectId,
      'causer': instance.causer?.toJson(),
      'changes': instance.changes?.toJson(),
      'attribute_labels': instance.attributeLabels,
      'created_at': instance.createdAt?.toIso8601String(),
    };

_AuditCauser _$AuditCauserFromJson(Map<String, dynamic> json) => _AuditCauser(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String,
  employeeCode: json['employee_code'] as String?,
);

Map<String, dynamic> _$AuditCauserToJson(_AuditCauser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'employee_code': instance.employeeCode,
    };

_AuditChanges _$AuditChangesFromJson(Map<String, dynamic> json) =>
    _AuditChanges(
      old: json['old'] as Map<String, dynamic>?,
      attributes: json['attributes'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AuditChangesToJson(_AuditChanges instance) =>
    <String, dynamic>{'old': instance.old, 'attributes': instance.attributes};
