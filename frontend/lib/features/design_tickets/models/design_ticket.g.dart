// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'design_ticket.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DesignTicketTransition _$DesignTicketTransitionFromJson(
  Map<String, dynamic> json,
) => _DesignTicketTransition(
  value: json['value'] as String,
  label: json['label'] as String,
);

Map<String, dynamic> _$DesignTicketTransitionToJson(
  _DesignTicketTransition instance,
) => <String, dynamic>{'value': instance.value, 'label': instance.label};

_DesignTicketOrder _$DesignTicketOrderFromJson(Map<String, dynamic> json) =>
    _DesignTicketOrder(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      isArchived: json['is_archived'] as bool? ?? false,
    );

Map<String, dynamic> _$DesignTicketOrderToJson(_DesignTicketOrder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'is_archived': instance.isArchived,
    };

_DesignTicket _$DesignTicketFromJson(
  Map<String, dynamic> json,
) => _DesignTicket(
  id: (json['id'] as num).toInt(),
  code: json['code'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  instructions: json['instructions'] as String?,
  status: $enumDecode(
    _$DesignTicketStatusEnumMap,
    json['status'],
    unknownValue: DesignTicketStatus.unknown,
  ),
  statusLabel: json['status_label'] as String,
  isOpen: json['is_open'] as bool? ?? true,
  isClosed: json['is_closed'] as bool? ?? false,
  availableTransitions:
      (json['available_transitions'] as List<dynamic>?)
          ?.map(
            (e) => DesignTicketTransition.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <DesignTicketTransition>[],
  customerId: (json['customer_id'] as num).toInt(),
  customerName: json['customer_name'] as String,
  orderId: (json['order_id'] as num?)?.toInt(),
  order: json['order'] == null
      ? null
      : DesignTicketOrder.fromJson(json['order'] as Map<String, dynamic>),
  requester: json['requester'] == null
      ? null
      : DesignTicketActor.fromJson(json['requester'] as Map<String, dynamic>),
  designer: json['designer'] == null
      ? null
      : DesignTicketActor.fromJson(json['designer'] as Map<String, dynamic>),
  acceptedBy: json['accepted_by'] == null
      ? null
      : DesignTicketActor.fromJson(json['accepted_by'] as Map<String, dynamic>),
  acceptedAt: json['accepted_at'] == null
      ? null
      : DateTime.parse(json['accepted_at'] as String),
  isInSharedPool: json['is_in_shared_pool'] as bool? ?? false,
  approvedBy: json['approved_by'] == null
      ? null
      : DesignTicketActor.fromJson(json['approved_by'] as Map<String, dynamic>),
  completedAt: json['completed_at'] == null
      ? null
      : DateTime.parse(json['completed_at'] as String),
  approvedCustomerDesignId: (json['approved_customer_design_id'] as num?)
      ?.toInt(),
  approvedDesign: json['approved_design'] == null
      ? null
      : CustomerDesign.fromJson(
          json['approved_design'] as Map<String, dynamic>,
        ),
  cancellationReason: json['cancellation_reason'] as String?,
  versionsCount: (json['versions_count'] as num?)?.toInt(),
  attachments:
      (json['attachments'] as List<dynamic>?)
          ?.map((e) => DesignTicketFile.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <DesignTicketFile>[],
  versions:
      (json['versions'] as List<dynamic>?)
          ?.map((e) => DesignTicketFile.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <DesignTicketFile>[],
  canAccept: json['can_accept'] as bool? ?? false,
  canSubmit: json['can_submit'] as bool? ?? false,
  canReview: json['can_review'] as bool? ?? false,
  canAssign: json['can_assign'] as bool? ?? false,
  canManage: json['can_manage'] as bool? ?? false,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$DesignTicketToJson(_DesignTicket instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'title': instance.title,
      'description': instance.description,
      'instructions': instance.instructions,
      'status': _$DesignTicketStatusEnumMap[instance.status]!,
      'status_label': instance.statusLabel,
      'is_open': instance.isOpen,
      'is_closed': instance.isClosed,
      'available_transitions': instance.availableTransitions
          .map((e) => e.toJson())
          .toList(),
      'customer_id': instance.customerId,
      'customer_name': instance.customerName,
      'order_id': instance.orderId,
      'order': instance.order?.toJson(),
      'requester': instance.requester?.toJson(),
      'designer': instance.designer?.toJson(),
      'accepted_by': instance.acceptedBy?.toJson(),
      'accepted_at': instance.acceptedAt?.toIso8601String(),
      'is_in_shared_pool': instance.isInSharedPool,
      'approved_by': instance.approvedBy?.toJson(),
      'completed_at': instance.completedAt?.toIso8601String(),
      'approved_customer_design_id': instance.approvedCustomerDesignId,
      'approved_design': instance.approvedDesign?.toJson(),
      'cancellation_reason': instance.cancellationReason,
      'versions_count': instance.versionsCount,
      'attachments': instance.attachments.map((e) => e.toJson()).toList(),
      'versions': instance.versions.map((e) => e.toJson()).toList(),
      'can_accept': instance.canAccept,
      'can_submit': instance.canSubmit,
      'can_review': instance.canReview,
      'can_assign': instance.canAssign,
      'can_manage': instance.canManage,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
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
