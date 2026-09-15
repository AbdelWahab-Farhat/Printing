// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'design_ticket_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DesignTicketFile _$DesignTicketFileFromJson(
  Map<String, dynamic> json,
) => _DesignTicketFile(
  id: (json['id'] as num).toInt(),
  designTicketId: (json['design_ticket_id'] as num).toInt(),
  kind: $enumDecode(
    _$DesignTicketFileKindEnumMap,
    json['kind'],
    unknownValue: DesignTicketFileKind.unknown,
  ),
  kindLabel: json['kind_label'] as String,
  label: json['label'] as String,
  note: json['note'] as String?,
  fileKind: $enumDecode(
    _$DesignKindEnumMap,
    json['file_kind'],
    unknownValue: DesignKind.unknown,
  ),
  fileKindLabel: json['file_kind_label'] as String,
  mimeType: json['mime_type'] as String?,
  originalFilename: json['original_filename'] as String?,
  sizeBytes: (json['size_bytes'] as num?)?.toInt(),
  widthPx: (json['width_px'] as num?)?.toInt(),
  heightPx: (json['height_px'] as num?)?.toInt(),
  fileUrl: json['file_url'] as String?,
  previewUrl: json['preview_url'] as String?,
  version: (json['version'] as num?)?.toInt(),
  status: $enumDecodeNullable(
    _$DesignSubmissionStatusEnumMap,
    json['status'],
    unknownValue: DesignSubmissionStatus.unknown,
  ),
  statusLabel: json['status_label'] as String?,
  isAwaitingReview: json['is_awaiting_review'] as bool? ?? false,
  reviewNote: json['review_note'] as String?,
  reviewedAt: json['reviewed_at'] == null
      ? null
      : DateTime.parse(json['reviewed_at'] as String),
  reviewer: json['reviewer'] == null
      ? null
      : DesignTicketActor.fromJson(json['reviewer'] as Map<String, dynamic>),
  uploader: json['uploader'] == null
      ? null
      : DesignTicketActor.fromJson(json['uploader'] as Map<String, dynamic>),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$DesignTicketFileToJson(_DesignTicketFile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'design_ticket_id': instance.designTicketId,
      'kind': _$DesignTicketFileKindEnumMap[instance.kind]!,
      'kind_label': instance.kindLabel,
      'label': instance.label,
      'note': instance.note,
      'file_kind': _$DesignKindEnumMap[instance.fileKind]!,
      'file_kind_label': instance.fileKindLabel,
      'mime_type': instance.mimeType,
      'original_filename': instance.originalFilename,
      'size_bytes': instance.sizeBytes,
      'width_px': instance.widthPx,
      'height_px': instance.heightPx,
      'file_url': instance.fileUrl,
      'preview_url': instance.previewUrl,
      'version': instance.version,
      'status': _$DesignSubmissionStatusEnumMap[instance.status],
      'status_label': instance.statusLabel,
      'is_awaiting_review': instance.isAwaitingReview,
      'review_note': instance.reviewNote,
      'reviewed_at': instance.reviewedAt?.toIso8601String(),
      'reviewer': instance.reviewer?.toJson(),
      'uploader': instance.uploader?.toJson(),
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$DesignTicketFileKindEnumMap = {
  DesignTicketFileKind.brief: 'brief',
  DesignTicketFileKind.submission: 'submission',
  DesignTicketFileKind.unknown: 'unknown',
};

const _$DesignKindEnumMap = {
  DesignKind.image: 'image',
  DesignKind.pdf: 'pdf',
  DesignKind.unknown: 'unknown',
};

const _$DesignSubmissionStatusEnumMap = {
  DesignSubmissionStatus.proposed: 'proposed',
  DesignSubmissionStatus.approved: 'approved',
  DesignSubmissionStatus.changesRequested: 'changes_requested',
  DesignSubmissionStatus.unknown: 'unknown',
};

_DesignTicketActor _$DesignTicketActorFromJson(Map<String, dynamic> json) =>
    _DesignTicketActor(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$DesignTicketActorToJson(_DesignTicketActor instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};
