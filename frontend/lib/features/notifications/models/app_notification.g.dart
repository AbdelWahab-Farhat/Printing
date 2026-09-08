// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    _AppNotification(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String,
      typeLabel: json['type_label'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      icon: json['icon'] as String,
      route: json['route'] as String?,
      subjectType: json['subject_type'] as String?,
      subjectId: (json['subject_id'] as num?)?.toInt(),
      isRead: json['is_read'] as bool,
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$AppNotificationToJson(_AppNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'type_label': instance.typeLabel,
      'title': instance.title,
      'body': instance.body,
      'icon': instance.icon,
      'route': instance.route,
      'subject_type': instance.subjectType,
      'subject_id': instance.subjectId,
      'is_read': instance.isRead,
      'read_at': instance.readAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };
