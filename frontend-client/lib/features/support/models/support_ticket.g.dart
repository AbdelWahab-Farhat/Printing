// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_ticket.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TicketMessage _$TicketMessageFromJson(Map<String, dynamic> json) =>
    _TicketMessage(
      id: (json['id'] as num).toInt(),
      from:
          $enumDecodeNullable(
            _$MessageAuthorEnumMap,
            json['from'],
            unknownValue: MessageAuthor.unknown,
          ) ??
          MessageAuthor.unknown,
      body: json['body'] as String,
      sentAt: json['sent_at'] == null
          ? null
          : DateTime.parse(json['sent_at'] as String),
    );

Map<String, dynamic> _$TicketMessageToJson(_TicketMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'from': _$MessageAuthorEnumMap[instance.from]!,
      'body': instance.body,
      'sent_at': instance.sentAt?.toIso8601String(),
    };

const _$MessageAuthorEnumMap = {
  MessageAuthor.me: 'me',
  MessageAuthor.support: 'support',
  MessageAuthor.unknown: 'unknown',
};

_TicketOrderRef _$TicketOrderRefFromJson(Map<String, dynamic> json) =>
    _TicketOrderRef(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
    );

Map<String, dynamic> _$TicketOrderRefToJson(_TicketOrderRef instance) =>
    <String, dynamic>{'id': instance.id, 'code': instance.code};

_SupportTicket _$SupportTicketFromJson(Map<String, dynamic> json) =>
    _SupportTicket(
      id: (json['id'] as num).toInt(),
      subject: json['subject'] as String,
      status:
          $enumDecodeNullable(
            _$TicketStatusEnumMap,
            json['status'],
            unknownValue: TicketStatus.unknown,
          ) ??
          TicketStatus.unknown,
      statusLabel: json['status_label'] as String,
      isOpen: json['is_open'] as bool? ?? true,
      order: json['order'] == null
          ? null
          : TicketOrderRef.fromJson(json['order'] as Map<String, dynamic>),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((e) => TicketMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <TicketMessage>[],
      messagesCount: (json['messages_count'] as num?)?.toInt(),
      preview: json['preview'] as String?,
      lastMessageAt: json['last_message_at'] == null
          ? null
          : DateTime.parse(json['last_message_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$SupportTicketToJson(_SupportTicket instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subject': instance.subject,
      'status': _$TicketStatusEnumMap[instance.status]!,
      'status_label': instance.statusLabel,
      'is_open': instance.isOpen,
      'order': instance.order?.toJson(),
      'unread_count': instance.unreadCount,
      'messages': instance.messages.map((e) => e.toJson()).toList(),
      'messages_count': instance.messagesCount,
      'preview': instance.preview,
      'last_message_at': instance.lastMessageAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$TicketStatusEnumMap = {
  TicketStatus.open: 'open',
  TicketStatus.inProgress: 'in_progress',
  TicketStatus.closed: 'closed',
  TicketStatus.unknown: 'unknown',
};
