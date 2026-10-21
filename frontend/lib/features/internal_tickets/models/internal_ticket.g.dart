// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'internal_ticket.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InternalPerson _$InternalPersonFromJson(Map<String, dynamic> json) =>
    _InternalPerson(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$InternalPersonToJson(_InternalPerson instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_InternalCustomerRef _$InternalCustomerRefFromJson(Map<String, dynamic> json) =>
    _InternalCustomerRef(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String?,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
    );

Map<String, dynamic> _$InternalCustomerRefToJson(
  _InternalCustomerRef instance,
) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
  'phone': instance.phone,
};

_InternalOrderRef _$InternalOrderRefFromJson(Map<String, dynamic> json) =>
    _InternalOrderRef(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
    );

Map<String, dynamic> _$InternalOrderRefToJson(_InternalOrderRef instance) =>
    <String, dynamic>{'id': instance.id, 'code': instance.code};

_InternalCategory _$InternalCategoryFromJson(Map<String, dynamic> json) =>
    _InternalCategory(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$InternalCategoryToJson(_InternalCategory instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_InternalAttachment _$InternalAttachmentFromJson(Map<String, dynamic> json) =>
    _InternalAttachment(
      id: (json['id'] as num).toInt(),
      kind:
          $enumDecodeNullable(
            _$InternalAttachmentKindEnumMap,
            json['kind'],
            unknownValue: InternalAttachmentKind.unknown,
          ) ??
          InternalAttachmentKind.unknown,
      name: json['name'] as String?,
      mimeType: json['mime_type'] as String?,
      sizeBytes: (json['size_bytes'] as num?)?.toInt(),
      widthPx: (json['width_px'] as num?)?.toInt(),
      heightPx: (json['height_px'] as num?)?.toInt(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      waveform: (json['waveform'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      url: json['url'] as String?,
    );

Map<String, dynamic> _$InternalAttachmentToJson(_InternalAttachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': _$InternalAttachmentKindEnumMap[instance.kind]!,
      'name': instance.name,
      'mime_type': instance.mimeType,
      'size_bytes': instance.sizeBytes,
      'width_px': instance.widthPx,
      'height_px': instance.heightPx,
      'duration_seconds': instance.durationSeconds,
      'waveform': instance.waveform,
      'url': instance.url,
    };

const _$InternalAttachmentKindEnumMap = {
  InternalAttachmentKind.image: 'image',
  InternalAttachmentKind.voice: 'voice',
  InternalAttachmentKind.unknown: 'unknown',
};

_InternalQuote _$InternalQuoteFromJson(Map<String, dynamic> json) =>
    _InternalQuote(
      id: (json['id'] as num).toInt(),
      authorName: json['author_name'] as String?,
      preview: json['preview'] as String? ?? '',
      isDeleted: json['is_deleted'] as bool? ?? false,
    );

Map<String, dynamic> _$InternalQuoteToJson(_InternalQuote instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author_name': instance.authorName,
      'preview': instance.preview,
      'is_deleted': instance.isDeleted,
    };

_InternalMessage _$InternalMessageFromJson(Map<String, dynamic> json) =>
    _InternalMessage(
      id: (json['id'] as num).toInt(),
      ticketId: (json['ticket_id'] as num?)?.toInt(),
      author: json['author'] == null
          ? null
          : InternalPerson.fromJson(json['author'] as Map<String, dynamic>),
      isMine: json['is_mine'] as bool? ?? false,
      body: json['body'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
      isEdited: json['is_edited'] as bool? ?? false,
      replyTo: json['reply_to'] == null
          ? null
          : InternalQuote.fromJson(json['reply_to'] as Map<String, dynamic>),
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map(
                (e) => InternalAttachment.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <InternalAttachment>[],
      clientToken: json['client_token'] as String?,
      sentAt: json['sent_at'] == null
          ? null
          : DateTime.parse(json['sent_at'] as String),
      canEdit: json['can_edit'] as bool? ?? false,
      canDelete: json['can_delete'] as bool? ?? false,
      mutationBlockReason: json['mutation_block_reason'] as String?,
      mutableUntil: json['mutable_until'] == null
          ? null
          : DateTime.parse(json['mutable_until'] as String),
    );

Map<String, dynamic> _$InternalMessageToJson(_InternalMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ticket_id': instance.ticketId,
      'author': instance.author?.toJson(),
      'is_mine': instance.isMine,
      'body': instance.body,
      'is_deleted': instance.isDeleted,
      'is_edited': instance.isEdited,
      'reply_to': instance.replyTo?.toJson(),
      'attachments': instance.attachments.map((e) => e.toJson()).toList(),
      'client_token': instance.clientToken,
      'sent_at': instance.sentAt?.toIso8601String(),
      'can_edit': instance.canEdit,
      'can_delete': instance.canDelete,
      'mutation_block_reason': instance.mutationBlockReason,
      'mutable_until': instance.mutableUntil?.toIso8601String(),
    };

_InternalLastMessage _$InternalLastMessageFromJson(Map<String, dynamic> json) =>
    _InternalLastMessage(
      id: (json['id'] as num).toInt(),
      authorId: (json['author_id'] as num?)?.toInt(),
      authorName: json['author_name'] as String?,
      preview: json['preview'] as String? ?? '',
      kind: json['kind'] as String? ?? 'text',
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      sentAt: json['sent_at'] == null
          ? null
          : DateTime.parse(json['sent_at'] as String),
    );

Map<String, dynamic> _$InternalLastMessageToJson(
  _InternalLastMessage instance,
) => <String, dynamic>{
  'id': instance.id,
  'author_id': instance.authorId,
  'author_name': instance.authorName,
  'preview': instance.preview,
  'kind': instance.kind,
  'duration_seconds': instance.durationSeconds,
  'sent_at': instance.sentAt?.toIso8601String(),
};

_InternalReadUpTo _$InternalReadUpToFromJson(Map<String, dynamic> json) =>
    _InternalReadUpTo(
      opener: (json['opener'] as num?)?.toInt(),
      assignee: (json['assignee'] as num?)?.toInt(),
    );

Map<String, dynamic> _$InternalReadUpToToJson(_InternalReadUpTo instance) =>
    <String, dynamic>{'opener': instance.opener, 'assignee': instance.assignee};

_InternalTicket _$InternalTicketFromJson(
  Map<String, dynamic> json,
) => _InternalTicket(
  id: (json['id'] as num).toInt(),
  code: json['code'] as String,
  title: json['title'] as String,
  status:
      $enumDecodeNullable(
        _$InternalTicketStatusEnumMap,
        json['status'],
        unknownValue: InternalTicketStatus.unknown,
      ) ??
      InternalTicketStatus.unknown,
  statusLabel: json['status_label'] as String? ?? '',
  priority:
      $enumDecodeNullable(
        _$InternalTicketPriorityEnumMap,
        json['priority'],
        unknownValue: InternalTicketPriority.unknown,
      ) ??
      InternalTicketPriority.medium,
  priorityLabel: json['priority_label'] as String? ?? '',
  category: json['category'] == null
      ? null
      : InternalCategory.fromJson(json['category'] as Map<String, dynamic>),
  opener: json['opener'] == null
      ? null
      : InternalPerson.fromJson(json['opener'] as Map<String, dynamic>),
  assignee: json['assignee'] == null
      ? null
      : InternalPerson.fromJson(json['assignee'] as Map<String, dynamic>),
  counterpart: json['counterpart'] == null
      ? null
      : InternalPerson.fromJson(json['counterpart'] as Map<String, dynamic>),
  iOpenedIt: json['i_opened_it'] as bool? ?? false,
  isParty: json['is_party'] as bool? ?? false,
  customer: json['customer'] == null
      ? null
      : InternalCustomerRef.fromJson(json['customer'] as Map<String, dynamic>),
  order: json['order'] == null
      ? null
      : InternalOrderRef.fromJson(json['order'] as Map<String, dynamic>),
  unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
  counterpartReadUpTo: (json['counterpart_read_up_to'] as num?)?.toInt(),
  readUpTo: json['read_up_to'] == null
      ? null
      : InternalReadUpTo.fromJson(json['read_up_to'] as Map<String, dynamic>),
  awaitingMyReply: json['awaiting_my_reply'] as bool? ?? false,
  lastMessage: json['last_message'] == null
      ? null
      : InternalLastMessage.fromJson(
          json['last_message'] as Map<String, dynamic>,
        ),
  messages:
      (json['messages'] as List<dynamic>?)
          ?.map((e) => InternalMessage.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <InternalMessage>[],
  canReply: json['can_reply'] as bool? ?? false,
  canClose: json['can_close'] as bool? ?? false,
  canTransfer: json['can_transfer'] as bool? ?? false,
  lastMessageAt: json['last_message_at'] == null
      ? null
      : DateTime.parse(json['last_message_at'] as String),
  closedAt: json['closed_at'] == null
      ? null
      : DateTime.parse(json['closed_at'] as String),
  closedBy: json['closed_by'] == null
      ? null
      : InternalPerson.fromJson(json['closed_by'] as Map<String, dynamic>),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$InternalTicketToJson(_InternalTicket instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'title': instance.title,
      'status': _$InternalTicketStatusEnumMap[instance.status]!,
      'status_label': instance.statusLabel,
      'priority': _$InternalTicketPriorityEnumMap[instance.priority]!,
      'priority_label': instance.priorityLabel,
      'category': instance.category?.toJson(),
      'opener': instance.opener?.toJson(),
      'assignee': instance.assignee?.toJson(),
      'counterpart': instance.counterpart?.toJson(),
      'i_opened_it': instance.iOpenedIt,
      'is_party': instance.isParty,
      'customer': instance.customer?.toJson(),
      'order': instance.order?.toJson(),
      'unread_count': instance.unreadCount,
      'counterpart_read_up_to': instance.counterpartReadUpTo,
      'read_up_to': instance.readUpTo?.toJson(),
      'awaiting_my_reply': instance.awaitingMyReply,
      'last_message': instance.lastMessage?.toJson(),
      'messages': instance.messages.map((e) => e.toJson()).toList(),
      'can_reply': instance.canReply,
      'can_close': instance.canClose,
      'can_transfer': instance.canTransfer,
      'last_message_at': instance.lastMessageAt?.toIso8601String(),
      'closed_at': instance.closedAt?.toIso8601String(),
      'closed_by': instance.closedBy?.toJson(),
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$InternalTicketStatusEnumMap = {
  InternalTicketStatus.inProgress: 'in_progress',
  InternalTicketStatus.closed: 'closed',
  InternalTicketStatus.unknown: 'unknown',
};

const _$InternalTicketPriorityEnumMap = {
  InternalTicketPriority.low: 'low',
  InternalTicketPriority.medium: 'medium',
  InternalTicketPriority.high: 'high',
  InternalTicketPriority.unknown: 'unknown',
};

_InternalTicketsHome _$InternalTicketsHomeFromJson(Map<String, dynamic> json) =>
    _InternalTicketsHome(
      tickets:
          (json['tickets'] as List<dynamic>?)
              ?.map((e) => InternalTicket.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <InternalTicket>[],
      awaitingMyReply: (json['awaiting_my_reply'] as num?)?.toInt() ?? 0,
      hasMore: json['has_more'] as bool? ?? false,
      totalOpen: (json['total_open'] as num?)?.toInt() ?? 0,
      unreadTickets: (json['unread_tickets'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$InternalTicketsHomeToJson(
  _InternalTicketsHome instance,
) => <String, dynamic>{
  'tickets': instance.tickets.map((e) => e.toJson()).toList(),
  'awaiting_my_reply': instance.awaitingMyReply,
  'has_more': instance.hasMore,
  'total_open': instance.totalOpen,
  'unread_tickets': instance.unreadTickets,
};

_Colleague _$ColleagueFromJson(Map<String, dynamic> json) => _Colleague(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  employeeCode: json['employee_code'] as String?,
  roles:
      (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  openTicketsWithMe: (json['open_tickets_with_me'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ColleagueToJson(_Colleague instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'employee_code': instance.employeeCode,
      'roles': instance.roles,
      'open_tickets_with_me': instance.openTicketsWithMe,
    };

_InternalTicketChange _$InternalTicketChangeFromJson(
  Map<String, dynamic> json,
) => _InternalTicketChange(
  change: json['change'] as String,
  ticket: InternalTicket.fromJson(json['ticket'] as Map<String, dynamic>),
  message: json['message'] == null
      ? null
      : InternalMessage.fromJson(json['message'] as Map<String, dynamic>),
);

Map<String, dynamic> _$InternalTicketChangeToJson(
  _InternalTicketChange instance,
) => <String, dynamic>{
  'change': instance.change,
  'ticket': instance.ticket.toJson(),
  'message': instance.message?.toJson(),
};
