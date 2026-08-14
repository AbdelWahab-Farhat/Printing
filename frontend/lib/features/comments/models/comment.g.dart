// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Comment _$CommentFromJson(Map<String, dynamic> json) => _Comment(
  id: (json['id'] as num).toInt(),
  commentableType: json['commentable_type'] as String,
  commentableId: (json['commentable_id'] as num).toInt(),
  body: json['body'] as String,
  author: CommentAuthor.fromJson(json['author'] as Map<String, dynamic>),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  editedAt: json['edited_at'] == null
      ? null
      : DateTime.parse(json['edited_at'] as String),
  canEdit: json['can_edit'] as bool? ?? false,
  canDelete: json['can_delete'] as bool? ?? false,
);

Map<String, dynamic> _$CommentToJson(_Comment instance) => <String, dynamic>{
  'id': instance.id,
  'commentable_type': instance.commentableType,
  'commentable_id': instance.commentableId,
  'body': instance.body,
  'author': instance.author.toJson(),
  'created_at': instance.createdAt?.toIso8601String(),
  'edited_at': instance.editedAt?.toIso8601String(),
  'can_edit': instance.canEdit,
  'can_delete': instance.canDelete,
};

_CommentAuthor _$CommentAuthorFromJson(Map<String, dynamic> json) =>
    _CommentAuthor(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
    );

Map<String, dynamic> _$CommentAuthorToJson(_CommentAuthor instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};
