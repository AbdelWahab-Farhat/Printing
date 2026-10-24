// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatPerson _$ChatPersonFromJson(Map<String, dynamic> json) =>
    _ChatPerson(id: (json['id'] as num).toInt(), name: json['name'] as String);

Map<String, dynamic> _$ChatPersonToJson(_ChatPerson instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_ChatAttachment _$ChatAttachmentFromJson(Map<String, dynamic> json) =>
    _ChatAttachment(
      id: (json['id'] as num).toInt(),
      kind:
          $enumDecodeNullable(
            _$ChatAttachmentKindEnumMap,
            json['kind'],
            unknownValue: ChatAttachmentKind.unknown,
          ) ??
          ChatAttachmentKind.unknown,
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

Map<String, dynamic> _$ChatAttachmentToJson(_ChatAttachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': _$ChatAttachmentKindEnumMap[instance.kind]!,
      'name': instance.name,
      'mime_type': instance.mimeType,
      'size_bytes': instance.sizeBytes,
      'width_px': instance.widthPx,
      'height_px': instance.heightPx,
      'duration_seconds': instance.durationSeconds,
      'waveform': instance.waveform,
      'url': instance.url,
    };

const _$ChatAttachmentKindEnumMap = {
  ChatAttachmentKind.image: 'image',
  ChatAttachmentKind.voice: 'voice',
  ChatAttachmentKind.unknown: 'unknown',
};

_ChatQuote _$ChatQuoteFromJson(Map<String, dynamic> json) => _ChatQuote(
  id: (json['id'] as num).toInt(),
  authorName: json['author_name'] as String?,
  preview: json['preview'] as String? ?? '',
  isDeleted: json['is_deleted'] as bool? ?? false,
);

Map<String, dynamic> _$ChatQuoteToJson(_ChatQuote instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author_name': instance.authorName,
      'preview': instance.preview,
      'is_deleted': instance.isDeleted,
    };

_ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => _ChatMessage(
  id: (json['id'] as num).toInt(),
  ticketId: (json['ticket_id'] as num?)?.toInt(),
  author: json['author'] == null
      ? null
      : ChatPerson.fromJson(json['author'] as Map<String, dynamic>),
  isMine: json['is_mine'] as bool? ?? false,
  body: json['body'] as String?,
  isDeleted: json['is_deleted'] as bool? ?? false,
  isEdited: json['is_edited'] as bool? ?? false,
  replyTo: json['reply_to'] == null
      ? null
      : ChatQuote.fromJson(json['reply_to'] as Map<String, dynamic>),
  attachments:
      (json['attachments'] as List<dynamic>?)
          ?.map((e) => ChatAttachment.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ChatAttachment>[],
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

Map<String, dynamic> _$ChatMessageToJson(_ChatMessage instance) =>
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
