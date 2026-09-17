// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_ticket.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TicketCustomer _$TicketCustomerFromJson(Map<String, dynamic> json) =>
    _TicketCustomer(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String?,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
    );

Map<String, dynamic> _$TicketCustomerToJson(_TicketCustomer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'phone': instance.phone,
    };

_TicketOrderRef _$TicketOrderRefFromJson(Map<String, dynamic> json) =>
    _TicketOrderRef(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
    );

Map<String, dynamic> _$TicketOrderRefToJson(_TicketOrderRef instance) =>
    <String, dynamic>{'id': instance.id, 'code': instance.code};

_TicketAssignee _$TicketAssigneeFromJson(Map<String, dynamic> json) =>
    _TicketAssignee(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
    );

Map<String, dynamic> _$TicketAssigneeToJson(_TicketAssignee instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

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
      authorName: json['author_name'] as String?,
      body: json['body'] as String,
      sentAt: json['sent_at'] == null
          ? null
          : DateTime.parse(json['sent_at'] as String),
    );

Map<String, dynamic> _$TicketMessageToJson(_TicketMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'from': _$MessageAuthorEnumMap[instance.from]!,
      'author_name': instance.authorName,
      'body': instance.body,
      'sent_at': instance.sentAt?.toIso8601String(),
    };

const _$MessageAuthorEnumMap = {
  MessageAuthor.customer: 'customer',
  MessageAuthor.staff: 'staff',
  MessageAuthor.unknown: 'unknown',
};

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
      customer: json['customer'] == null
          ? null
          : TicketCustomer.fromJson(json['customer'] as Map<String, dynamic>),
      order: json['order'] == null
          ? null
          : TicketOrderRef.fromJson(json['order'] as Map<String, dynamic>),
      assignedTo: (json['assigned_to'] as num?)?.toInt(),
      assignee: json['assignee'] == null
          ? null
          : TicketAssignee.fromJson(json['assignee'] as Map<String, dynamic>),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((e) => TicketMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <TicketMessage>[],
      lastMessageAt: json['last_message_at'] == null
          ? null
          : DateTime.parse(json['last_message_at'] as String),
      closedAt: json['closed_at'] == null
          ? null
          : DateTime.parse(json['closed_at'] as String),
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
      'customer': instance.customer?.toJson(),
      'order': instance.order?.toJson(),
      'assigned_to': instance.assignedTo,
      'assignee': instance.assignee?.toJson(),
      'unread_count': instance.unreadCount,
      'messages': instance.messages.map((e) => e.toJson()).toList(),
      'last_message_at': instance.lastMessageAt?.toIso8601String(),
      'closed_at': instance.closedAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$TicketStatusEnumMap = {
  TicketStatus.open: 'open',
  TicketStatus.inProgress: 'in_progress',
  TicketStatus.closed: 'closed',
  TicketStatus.unknown: 'unknown',
};
