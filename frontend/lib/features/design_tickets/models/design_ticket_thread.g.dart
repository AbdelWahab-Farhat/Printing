// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'design_ticket_thread.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DesignThreadTicket _$DesignThreadTicketFromJson(Map<String, dynamic> json) =>
    _DesignThreadTicket(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      title: json['title'] as String? ?? '',
      status:
          $enumDecodeNullable(
            _$DesignTicketStatusEnumMap,
            json['status'],
            unknownValue: DesignTicketStatus.unknown,
          ) ??
          DesignTicketStatus.unknown,
      statusLabel: json['status_label'] as String? ?? '',
      isOpen: json['is_open'] as bool? ?? true,
      customerName: json['customer_name'] as String?,
      requester: json['requester'] == null
          ? null
          : ChatPerson.fromJson(json['requester'] as Map<String, dynamic>),
      designer: json['designer'] == null
          ? null
          : ChatPerson.fromJson(json['designer'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DesignThreadTicketToJson(_DesignThreadTicket instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'title': instance.title,
      'status': _$DesignTicketStatusEnumMap[instance.status]!,
      'status_label': instance.statusLabel,
      'is_open': instance.isOpen,
      'customer_name': instance.customerName,
      'requester': instance.requester?.toJson(),
      'designer': instance.designer?.toJson(),
    };

const _$DesignTicketStatusEnumMap = {
  DesignTicketStatus.fresh: 'new',
  DesignTicketStatus.inProgress: 'in_progress',
  DesignTicketStatus.underReview: 'under_review',
  DesignTicketStatus.changesRequested: 'changes_requested',
  DesignTicketStatus.completed: 'completed',
  DesignTicketStatus.cancelled: 'cancelled',
  DesignTicketStatus.unknown: 'unknown',
};

_DesignThreadReadUpTo _$DesignThreadReadUpToFromJson(
  Map<String, dynamic> json,
) => _DesignThreadReadUpTo(
  requester: (json['requester'] as num?)?.toInt(),
  designer: (json['designer'] as num?)?.toInt(),
);

Map<String, dynamic> _$DesignThreadReadUpToToJson(
  _DesignThreadReadUpTo instance,
) => <String, dynamic>{
  'requester': instance.requester,
  'designer': instance.designer,
};

_DesignTicketThread _$DesignTicketThreadFromJson(Map<String, dynamic> json) =>
    _DesignTicketThread(
      ticket: DesignThreadTicket.fromJson(
        json['ticket'] as Map<String, dynamic>,
      ),
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ChatMessage>[],
      isParty: json['is_party'] as bool? ?? false,
      canReply: json['can_reply'] as bool? ?? false,
      closedNote: json['closed_note'] as String?,
      readUpTo: json['read_up_to'] == null
          ? null
          : DesignThreadReadUpTo.fromJson(
              json['read_up_to'] as Map<String, dynamic>,
            ),
      counterpartReadUpTo: (json['counterpart_read_up_to'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DesignTicketThreadToJson(_DesignTicketThread instance) =>
    <String, dynamic>{
      'ticket': instance.ticket.toJson(),
      'messages': instance.messages.map((e) => e.toJson()).toList(),
      'is_party': instance.isParty,
      'can_reply': instance.canReply,
      'closed_note': instance.closedNote,
      'read_up_to': instance.readUpTo?.toJson(),
      'counterpart_read_up_to': instance.counterpartReadUpTo,
    };

_DesignTicketThreadChange _$DesignTicketThreadChangeFromJson(
  Map<String, dynamic> json,
) => _DesignTicketThreadChange(
  change: json['change'] as String,
  thread: DesignTicketThread.fromJson(json['thread'] as Map<String, dynamic>),
  message: json['message'] == null
      ? null
      : ChatMessage.fromJson(json['message'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DesignTicketThreadChangeToJson(
  _DesignTicketThreadChange instance,
) => <String, dynamic>{
  'change': instance.change,
  'thread': instance.thread.toJson(),
  'message': instance.message?.toJson(),
};
