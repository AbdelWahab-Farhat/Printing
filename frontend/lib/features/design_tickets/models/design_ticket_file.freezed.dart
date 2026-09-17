// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'design_ticket_file.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DesignTicketFile {

 int get id;@JsonKey(name: 'design_ticket_id') int get designTicketId;@JsonKey(unknownEnumValue: DesignTicketFileKind.unknown) DesignTicketFileKind get kind;/// The kind in Arabic, as the server words it — shown instead of a switch over [kind], so a
/// value this build has never heard of still names itself.
@JsonKey(name: 'kind_label') String get kindLabel;/// «النسخة ٣» for a submission, the filename for a brief. Never null: the server falls back.
 String get label;/// What the designer said when they sent it.
 String? get note;/// `image` or `pdf` — whether the app can draw this itself or must hand it to the system
/// viewer. The same key and the same meaning as `CustomerDesign.kind`.
@JsonKey(name: 'file_kind', unknownEnumValue: DesignKind.unknown) DesignKind get fileKind;@JsonKey(name: 'file_kind_label') String get fileKindLabel;@JsonKey(name: 'mime_type') String? get mimeType;@JsonKey(name: 'original_filename') String? get originalFilename;@JsonKey(name: 'size_bytes') int? get sizeBytes;@JsonKey(name: 'width_px') int? get widthPx;@JsonKey(name: 'height_px') int? get heightPx;/// Generated per request — see the note on the class.
@JsonKey(name: 'file_url') String? get fileUrl;/// Reserved. The server renders no first page for a PDF yet; the key is here so that it can
/// start doing so without an app release.
@JsonKey(name: 'preview_url') String? get previewUrl;/// 1, 2, 3 … within the ticket. Null on a brief.
 int? get version;@JsonKey(unknownEnumValue: DesignSubmissionStatus.unknown) DesignSubmissionStatus? get status;@JsonKey(name: 'status_label') String? get statusLabel;@JsonKey(name: 'is_awaiting_review') bool get isAwaitingReview;/// **What has to change.** The whole reason a revision round exists, and the first thing the
/// designer reads when a ticket comes back to them.
@JsonKey(name: 'review_note') String? get reviewNote;@JsonKey(name: 'reviewed_at') DateTime? get reviewedAt; DesignTicketActor? get reviewer; DesignTicketActor? get uploader;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of DesignTicketFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignTicketFileCopyWith<DesignTicketFile> get copyWith => _$DesignTicketFileCopyWithImpl<DesignTicketFile>(this as DesignTicketFile, _$identity);

  /// Serializes this DesignTicketFile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignTicketFile&&(identical(other.id, id) || other.id == id)&&(identical(other.designTicketId, designTicketId) || other.designTicketId == designTicketId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.kindLabel, kindLabel) || other.kindLabel == kindLabel)&&(identical(other.label, label) || other.label == label)&&(identical(other.note, note) || other.note == note)&&(identical(other.fileKind, fileKind) || other.fileKind == fileKind)&&(identical(other.fileKindLabel, fileKindLabel) || other.fileKindLabel == fileKindLabel)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.originalFilename, originalFilename) || other.originalFilename == originalFilename)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.widthPx, widthPx) || other.widthPx == widthPx)&&(identical(other.heightPx, heightPx) || other.heightPx == heightPx)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.previewUrl, previewUrl) || other.previewUrl == previewUrl)&&(identical(other.version, version) || other.version == version)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.isAwaitingReview, isAwaitingReview) || other.isAwaitingReview == isAwaitingReview)&&(identical(other.reviewNote, reviewNote) || other.reviewNote == reviewNote)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.reviewer, reviewer) || other.reviewer == reviewer)&&(identical(other.uploader, uploader) || other.uploader == uploader)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,designTicketId,kind,kindLabel,label,note,fileKind,fileKindLabel,mimeType,originalFilename,sizeBytes,widthPx,heightPx,fileUrl,previewUrl,version,status,statusLabel,isAwaitingReview,reviewNote,reviewedAt,reviewer,uploader,createdAt]);

@override
String toString() {
  return 'DesignTicketFile(id: $id, designTicketId: $designTicketId, kind: $kind, kindLabel: $kindLabel, label: $label, note: $note, fileKind: $fileKind, fileKindLabel: $fileKindLabel, mimeType: $mimeType, originalFilename: $originalFilename, sizeBytes: $sizeBytes, widthPx: $widthPx, heightPx: $heightPx, fileUrl: $fileUrl, previewUrl: $previewUrl, version: $version, status: $status, statusLabel: $statusLabel, isAwaitingReview: $isAwaitingReview, reviewNote: $reviewNote, reviewedAt: $reviewedAt, reviewer: $reviewer, uploader: $uploader, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $DesignTicketFileCopyWith<$Res>  {
  factory $DesignTicketFileCopyWith(DesignTicketFile value, $Res Function(DesignTicketFile) _then) = _$DesignTicketFileCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'design_ticket_id') int designTicketId,@JsonKey(unknownEnumValue: DesignTicketFileKind.unknown) DesignTicketFileKind kind,@JsonKey(name: 'kind_label') String kindLabel, String label, String? note,@JsonKey(name: 'file_kind', unknownEnumValue: DesignKind.unknown) DesignKind fileKind,@JsonKey(name: 'file_kind_label') String fileKindLabel,@JsonKey(name: 'mime_type') String? mimeType,@JsonKey(name: 'original_filename') String? originalFilename,@JsonKey(name: 'size_bytes') int? sizeBytes,@JsonKey(name: 'width_px') int? widthPx,@JsonKey(name: 'height_px') int? heightPx,@JsonKey(name: 'file_url') String? fileUrl,@JsonKey(name: 'preview_url') String? previewUrl, int? version,@JsonKey(unknownEnumValue: DesignSubmissionStatus.unknown) DesignSubmissionStatus? status,@JsonKey(name: 'status_label') String? statusLabel,@JsonKey(name: 'is_awaiting_review') bool isAwaitingReview,@JsonKey(name: 'review_note') String? reviewNote,@JsonKey(name: 'reviewed_at') DateTime? reviewedAt, DesignTicketActor? reviewer, DesignTicketActor? uploader,@JsonKey(name: 'created_at') DateTime? createdAt
});


$DesignTicketActorCopyWith<$Res>? get reviewer;$DesignTicketActorCopyWith<$Res>? get uploader;

}
/// @nodoc
class _$DesignTicketFileCopyWithImpl<$Res>
    implements $DesignTicketFileCopyWith<$Res> {
  _$DesignTicketFileCopyWithImpl(this._self, this._then);

  final DesignTicketFile _self;
  final $Res Function(DesignTicketFile) _then;

/// Create a copy of DesignTicketFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? designTicketId = null,Object? kind = null,Object? kindLabel = null,Object? label = null,Object? note = freezed,Object? fileKind = null,Object? fileKindLabel = null,Object? mimeType = freezed,Object? originalFilename = freezed,Object? sizeBytes = freezed,Object? widthPx = freezed,Object? heightPx = freezed,Object? fileUrl = freezed,Object? previewUrl = freezed,Object? version = freezed,Object? status = freezed,Object? statusLabel = freezed,Object? isAwaitingReview = null,Object? reviewNote = freezed,Object? reviewedAt = freezed,Object? reviewer = freezed,Object? uploader = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,designTicketId: null == designTicketId ? _self.designTicketId : designTicketId // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as DesignTicketFileKind,kindLabel: null == kindLabel ? _self.kindLabel : kindLabel // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,fileKind: null == fileKind ? _self.fileKind : fileKind // ignore: cast_nullable_to_non_nullable
as DesignKind,fileKindLabel: null == fileKindLabel ? _self.fileKindLabel : fileKindLabel // ignore: cast_nullable_to_non_nullable
as String,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,originalFilename: freezed == originalFilename ? _self.originalFilename : originalFilename // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,widthPx: freezed == widthPx ? _self.widthPx : widthPx // ignore: cast_nullable_to_non_nullable
as int?,heightPx: freezed == heightPx ? _self.heightPx : heightPx // ignore: cast_nullable_to_non_nullable
as int?,fileUrl: freezed == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String?,previewUrl: freezed == previewUrl ? _self.previewUrl : previewUrl // ignore: cast_nullable_to_non_nullable
as String?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DesignSubmissionStatus?,statusLabel: freezed == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String?,isAwaitingReview: null == isAwaitingReview ? _self.isAwaitingReview : isAwaitingReview // ignore: cast_nullable_to_non_nullable
as bool,reviewNote: freezed == reviewNote ? _self.reviewNote : reviewNote // ignore: cast_nullable_to_non_nullable
as String?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewer: freezed == reviewer ? _self.reviewer : reviewer // ignore: cast_nullable_to_non_nullable
as DesignTicketActor?,uploader: freezed == uploader ? _self.uploader : uploader // ignore: cast_nullable_to_non_nullable
as DesignTicketActor?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of DesignTicketFile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketActorCopyWith<$Res>? get reviewer {
    if (_self.reviewer == null) {
    return null;
  }

  return $DesignTicketActorCopyWith<$Res>(_self.reviewer!, (value) {
    return _then(_self.copyWith(reviewer: value));
  });
}/// Create a copy of DesignTicketFile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketActorCopyWith<$Res>? get uploader {
    if (_self.uploader == null) {
    return null;
  }

  return $DesignTicketActorCopyWith<$Res>(_self.uploader!, (value) {
    return _then(_self.copyWith(uploader: value));
  });
}
}


/// Adds pattern-matching-related methods to [DesignTicketFile].
extension DesignTicketFilePatterns on DesignTicketFile {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesignTicketFile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesignTicketFile() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesignTicketFile value)  $default,){
final _that = this;
switch (_that) {
case _DesignTicketFile():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesignTicketFile value)?  $default,){
final _that = this;
switch (_that) {
case _DesignTicketFile() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'design_ticket_id')  int designTicketId, @JsonKey(unknownEnumValue: DesignTicketFileKind.unknown)  DesignTicketFileKind kind, @JsonKey(name: 'kind_label')  String kindLabel,  String label,  String? note, @JsonKey(name: 'file_kind', unknownEnumValue: DesignKind.unknown)  DesignKind fileKind, @JsonKey(name: 'file_kind_label')  String fileKindLabel, @JsonKey(name: 'mime_type')  String? mimeType, @JsonKey(name: 'original_filename')  String? originalFilename, @JsonKey(name: 'size_bytes')  int? sizeBytes, @JsonKey(name: 'width_px')  int? widthPx, @JsonKey(name: 'height_px')  int? heightPx, @JsonKey(name: 'file_url')  String? fileUrl, @JsonKey(name: 'preview_url')  String? previewUrl,  int? version, @JsonKey(unknownEnumValue: DesignSubmissionStatus.unknown)  DesignSubmissionStatus? status, @JsonKey(name: 'status_label')  String? statusLabel, @JsonKey(name: 'is_awaiting_review')  bool isAwaitingReview, @JsonKey(name: 'review_note')  String? reviewNote, @JsonKey(name: 'reviewed_at')  DateTime? reviewedAt,  DesignTicketActor? reviewer,  DesignTicketActor? uploader, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DesignTicketFile() when $default != null:
return $default(_that.id,_that.designTicketId,_that.kind,_that.kindLabel,_that.label,_that.note,_that.fileKind,_that.fileKindLabel,_that.mimeType,_that.originalFilename,_that.sizeBytes,_that.widthPx,_that.heightPx,_that.fileUrl,_that.previewUrl,_that.version,_that.status,_that.statusLabel,_that.isAwaitingReview,_that.reviewNote,_that.reviewedAt,_that.reviewer,_that.uploader,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'design_ticket_id')  int designTicketId, @JsonKey(unknownEnumValue: DesignTicketFileKind.unknown)  DesignTicketFileKind kind, @JsonKey(name: 'kind_label')  String kindLabel,  String label,  String? note, @JsonKey(name: 'file_kind', unknownEnumValue: DesignKind.unknown)  DesignKind fileKind, @JsonKey(name: 'file_kind_label')  String fileKindLabel, @JsonKey(name: 'mime_type')  String? mimeType, @JsonKey(name: 'original_filename')  String? originalFilename, @JsonKey(name: 'size_bytes')  int? sizeBytes, @JsonKey(name: 'width_px')  int? widthPx, @JsonKey(name: 'height_px')  int? heightPx, @JsonKey(name: 'file_url')  String? fileUrl, @JsonKey(name: 'preview_url')  String? previewUrl,  int? version, @JsonKey(unknownEnumValue: DesignSubmissionStatus.unknown)  DesignSubmissionStatus? status, @JsonKey(name: 'status_label')  String? statusLabel, @JsonKey(name: 'is_awaiting_review')  bool isAwaitingReview, @JsonKey(name: 'review_note')  String? reviewNote, @JsonKey(name: 'reviewed_at')  DateTime? reviewedAt,  DesignTicketActor? reviewer,  DesignTicketActor? uploader, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _DesignTicketFile():
return $default(_that.id,_that.designTicketId,_that.kind,_that.kindLabel,_that.label,_that.note,_that.fileKind,_that.fileKindLabel,_that.mimeType,_that.originalFilename,_that.sizeBytes,_that.widthPx,_that.heightPx,_that.fileUrl,_that.previewUrl,_that.version,_that.status,_that.statusLabel,_that.isAwaitingReview,_that.reviewNote,_that.reviewedAt,_that.reviewer,_that.uploader,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'design_ticket_id')  int designTicketId, @JsonKey(unknownEnumValue: DesignTicketFileKind.unknown)  DesignTicketFileKind kind, @JsonKey(name: 'kind_label')  String kindLabel,  String label,  String? note, @JsonKey(name: 'file_kind', unknownEnumValue: DesignKind.unknown)  DesignKind fileKind, @JsonKey(name: 'file_kind_label')  String fileKindLabel, @JsonKey(name: 'mime_type')  String? mimeType, @JsonKey(name: 'original_filename')  String? originalFilename, @JsonKey(name: 'size_bytes')  int? sizeBytes, @JsonKey(name: 'width_px')  int? widthPx, @JsonKey(name: 'height_px')  int? heightPx, @JsonKey(name: 'file_url')  String? fileUrl, @JsonKey(name: 'preview_url')  String? previewUrl,  int? version, @JsonKey(unknownEnumValue: DesignSubmissionStatus.unknown)  DesignSubmissionStatus? status, @JsonKey(name: 'status_label')  String? statusLabel, @JsonKey(name: 'is_awaiting_review')  bool isAwaitingReview, @JsonKey(name: 'review_note')  String? reviewNote, @JsonKey(name: 'reviewed_at')  DateTime? reviewedAt,  DesignTicketActor? reviewer,  DesignTicketActor? uploader, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _DesignTicketFile() when $default != null:
return $default(_that.id,_that.designTicketId,_that.kind,_that.kindLabel,_that.label,_that.note,_that.fileKind,_that.fileKindLabel,_that.mimeType,_that.originalFilename,_that.sizeBytes,_that.widthPx,_that.heightPx,_that.fileUrl,_that.previewUrl,_that.version,_that.status,_that.statusLabel,_that.isAwaitingReview,_that.reviewNote,_that.reviewedAt,_that.reviewer,_that.uploader,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DesignTicketFile extends DesignTicketFile {
  const _DesignTicketFile({required this.id, @JsonKey(name: 'design_ticket_id') required this.designTicketId, @JsonKey(unknownEnumValue: DesignTicketFileKind.unknown) required this.kind, @JsonKey(name: 'kind_label') required this.kindLabel, required this.label, this.note, @JsonKey(name: 'file_kind', unknownEnumValue: DesignKind.unknown) required this.fileKind, @JsonKey(name: 'file_kind_label') required this.fileKindLabel, @JsonKey(name: 'mime_type') this.mimeType, @JsonKey(name: 'original_filename') this.originalFilename, @JsonKey(name: 'size_bytes') this.sizeBytes, @JsonKey(name: 'width_px') this.widthPx, @JsonKey(name: 'height_px') this.heightPx, @JsonKey(name: 'file_url') this.fileUrl, @JsonKey(name: 'preview_url') this.previewUrl, this.version, @JsonKey(unknownEnumValue: DesignSubmissionStatus.unknown) this.status, @JsonKey(name: 'status_label') this.statusLabel, @JsonKey(name: 'is_awaiting_review') this.isAwaitingReview = false, @JsonKey(name: 'review_note') this.reviewNote, @JsonKey(name: 'reviewed_at') this.reviewedAt, this.reviewer, this.uploader, @JsonKey(name: 'created_at') this.createdAt}): super._();
  factory _DesignTicketFile.fromJson(Map<String, dynamic> json) => _$DesignTicketFileFromJson(json);

@override final  int id;
@override@JsonKey(name: 'design_ticket_id') final  int designTicketId;
@override@JsonKey(unknownEnumValue: DesignTicketFileKind.unknown) final  DesignTicketFileKind kind;
/// The kind in Arabic, as the server words it — shown instead of a switch over [kind], so a
/// value this build has never heard of still names itself.
@override@JsonKey(name: 'kind_label') final  String kindLabel;
/// «النسخة ٣» for a submission, the filename for a brief. Never null: the server falls back.
@override final  String label;
/// What the designer said when they sent it.
@override final  String? note;
/// `image` or `pdf` — whether the app can draw this itself or must hand it to the system
/// viewer. The same key and the same meaning as `CustomerDesign.kind`.
@override@JsonKey(name: 'file_kind', unknownEnumValue: DesignKind.unknown) final  DesignKind fileKind;
@override@JsonKey(name: 'file_kind_label') final  String fileKindLabel;
@override@JsonKey(name: 'mime_type') final  String? mimeType;
@override@JsonKey(name: 'original_filename') final  String? originalFilename;
@override@JsonKey(name: 'size_bytes') final  int? sizeBytes;
@override@JsonKey(name: 'width_px') final  int? widthPx;
@override@JsonKey(name: 'height_px') final  int? heightPx;
/// Generated per request — see the note on the class.
@override@JsonKey(name: 'file_url') final  String? fileUrl;
/// Reserved. The server renders no first page for a PDF yet; the key is here so that it can
/// start doing so without an app release.
@override@JsonKey(name: 'preview_url') final  String? previewUrl;
/// 1, 2, 3 … within the ticket. Null on a brief.
@override final  int? version;
@override@JsonKey(unknownEnumValue: DesignSubmissionStatus.unknown) final  DesignSubmissionStatus? status;
@override@JsonKey(name: 'status_label') final  String? statusLabel;
@override@JsonKey(name: 'is_awaiting_review') final  bool isAwaitingReview;
/// **What has to change.** The whole reason a revision round exists, and the first thing the
/// designer reads when a ticket comes back to them.
@override@JsonKey(name: 'review_note') final  String? reviewNote;
@override@JsonKey(name: 'reviewed_at') final  DateTime? reviewedAt;
@override final  DesignTicketActor? reviewer;
@override final  DesignTicketActor? uploader;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of DesignTicketFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesignTicketFileCopyWith<_DesignTicketFile> get copyWith => __$DesignTicketFileCopyWithImpl<_DesignTicketFile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DesignTicketFileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesignTicketFile&&(identical(other.id, id) || other.id == id)&&(identical(other.designTicketId, designTicketId) || other.designTicketId == designTicketId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.kindLabel, kindLabel) || other.kindLabel == kindLabel)&&(identical(other.label, label) || other.label == label)&&(identical(other.note, note) || other.note == note)&&(identical(other.fileKind, fileKind) || other.fileKind == fileKind)&&(identical(other.fileKindLabel, fileKindLabel) || other.fileKindLabel == fileKindLabel)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.originalFilename, originalFilename) || other.originalFilename == originalFilename)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.widthPx, widthPx) || other.widthPx == widthPx)&&(identical(other.heightPx, heightPx) || other.heightPx == heightPx)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.previewUrl, previewUrl) || other.previewUrl == previewUrl)&&(identical(other.version, version) || other.version == version)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.isAwaitingReview, isAwaitingReview) || other.isAwaitingReview == isAwaitingReview)&&(identical(other.reviewNote, reviewNote) || other.reviewNote == reviewNote)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.reviewer, reviewer) || other.reviewer == reviewer)&&(identical(other.uploader, uploader) || other.uploader == uploader)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,designTicketId,kind,kindLabel,label,note,fileKind,fileKindLabel,mimeType,originalFilename,sizeBytes,widthPx,heightPx,fileUrl,previewUrl,version,status,statusLabel,isAwaitingReview,reviewNote,reviewedAt,reviewer,uploader,createdAt]);

@override
String toString() {
  return 'DesignTicketFile(id: $id, designTicketId: $designTicketId, kind: $kind, kindLabel: $kindLabel, label: $label, note: $note, fileKind: $fileKind, fileKindLabel: $fileKindLabel, mimeType: $mimeType, originalFilename: $originalFilename, sizeBytes: $sizeBytes, widthPx: $widthPx, heightPx: $heightPx, fileUrl: $fileUrl, previewUrl: $previewUrl, version: $version, status: $status, statusLabel: $statusLabel, isAwaitingReview: $isAwaitingReview, reviewNote: $reviewNote, reviewedAt: $reviewedAt, reviewer: $reviewer, uploader: $uploader, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$DesignTicketFileCopyWith<$Res> implements $DesignTicketFileCopyWith<$Res> {
  factory _$DesignTicketFileCopyWith(_DesignTicketFile value, $Res Function(_DesignTicketFile) _then) = __$DesignTicketFileCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'design_ticket_id') int designTicketId,@JsonKey(unknownEnumValue: DesignTicketFileKind.unknown) DesignTicketFileKind kind,@JsonKey(name: 'kind_label') String kindLabel, String label, String? note,@JsonKey(name: 'file_kind', unknownEnumValue: DesignKind.unknown) DesignKind fileKind,@JsonKey(name: 'file_kind_label') String fileKindLabel,@JsonKey(name: 'mime_type') String? mimeType,@JsonKey(name: 'original_filename') String? originalFilename,@JsonKey(name: 'size_bytes') int? sizeBytes,@JsonKey(name: 'width_px') int? widthPx,@JsonKey(name: 'height_px') int? heightPx,@JsonKey(name: 'file_url') String? fileUrl,@JsonKey(name: 'preview_url') String? previewUrl, int? version,@JsonKey(unknownEnumValue: DesignSubmissionStatus.unknown) DesignSubmissionStatus? status,@JsonKey(name: 'status_label') String? statusLabel,@JsonKey(name: 'is_awaiting_review') bool isAwaitingReview,@JsonKey(name: 'review_note') String? reviewNote,@JsonKey(name: 'reviewed_at') DateTime? reviewedAt, DesignTicketActor? reviewer, DesignTicketActor? uploader,@JsonKey(name: 'created_at') DateTime? createdAt
});


@override $DesignTicketActorCopyWith<$Res>? get reviewer;@override $DesignTicketActorCopyWith<$Res>? get uploader;

}
/// @nodoc
class __$DesignTicketFileCopyWithImpl<$Res>
    implements _$DesignTicketFileCopyWith<$Res> {
  __$DesignTicketFileCopyWithImpl(this._self, this._then);

  final _DesignTicketFile _self;
  final $Res Function(_DesignTicketFile) _then;

/// Create a copy of DesignTicketFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? designTicketId = null,Object? kind = null,Object? kindLabel = null,Object? label = null,Object? note = freezed,Object? fileKind = null,Object? fileKindLabel = null,Object? mimeType = freezed,Object? originalFilename = freezed,Object? sizeBytes = freezed,Object? widthPx = freezed,Object? heightPx = freezed,Object? fileUrl = freezed,Object? previewUrl = freezed,Object? version = freezed,Object? status = freezed,Object? statusLabel = freezed,Object? isAwaitingReview = null,Object? reviewNote = freezed,Object? reviewedAt = freezed,Object? reviewer = freezed,Object? uploader = freezed,Object? createdAt = freezed,}) {
  return _then(_DesignTicketFile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,designTicketId: null == designTicketId ? _self.designTicketId : designTicketId // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as DesignTicketFileKind,kindLabel: null == kindLabel ? _self.kindLabel : kindLabel // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,fileKind: null == fileKind ? _self.fileKind : fileKind // ignore: cast_nullable_to_non_nullable
as DesignKind,fileKindLabel: null == fileKindLabel ? _self.fileKindLabel : fileKindLabel // ignore: cast_nullable_to_non_nullable
as String,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,originalFilename: freezed == originalFilename ? _self.originalFilename : originalFilename // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,widthPx: freezed == widthPx ? _self.widthPx : widthPx // ignore: cast_nullable_to_non_nullable
as int?,heightPx: freezed == heightPx ? _self.heightPx : heightPx // ignore: cast_nullable_to_non_nullable
as int?,fileUrl: freezed == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String?,previewUrl: freezed == previewUrl ? _self.previewUrl : previewUrl // ignore: cast_nullable_to_non_nullable
as String?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DesignSubmissionStatus?,statusLabel: freezed == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String?,isAwaitingReview: null == isAwaitingReview ? _self.isAwaitingReview : isAwaitingReview // ignore: cast_nullable_to_non_nullable
as bool,reviewNote: freezed == reviewNote ? _self.reviewNote : reviewNote // ignore: cast_nullable_to_non_nullable
as String?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewer: freezed == reviewer ? _self.reviewer : reviewer // ignore: cast_nullable_to_non_nullable
as DesignTicketActor?,uploader: freezed == uploader ? _self.uploader : uploader // ignore: cast_nullable_to_non_nullable
as DesignTicketActor?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of DesignTicketFile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketActorCopyWith<$Res>? get reviewer {
    if (_self.reviewer == null) {
    return null;
  }

  return $DesignTicketActorCopyWith<$Res>(_self.reviewer!, (value) {
    return _then(_self.copyWith(reviewer: value));
  });
}/// Create a copy of DesignTicketFile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketActorCopyWith<$Res>? get uploader {
    if (_self.uploader == null) {
    return null;
  }

  return $DesignTicketActorCopyWith<$Res>(_self.uploader!, (value) {
    return _then(_self.copyWith(uploader: value));
  });
}
}


/// @nodoc
mixin _$DesignTicketActor {

 int get id; String get name;
/// Create a copy of DesignTicketActor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignTicketActorCopyWith<DesignTicketActor> get copyWith => _$DesignTicketActorCopyWithImpl<DesignTicketActor>(this as DesignTicketActor, _$identity);

  /// Serializes this DesignTicketActor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignTicketActor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'DesignTicketActor(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $DesignTicketActorCopyWith<$Res>  {
  factory $DesignTicketActorCopyWith(DesignTicketActor value, $Res Function(DesignTicketActor) _then) = _$DesignTicketActorCopyWithImpl;
@useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class _$DesignTicketActorCopyWithImpl<$Res>
    implements $DesignTicketActorCopyWith<$Res> {
  _$DesignTicketActorCopyWithImpl(this._self, this._then);

  final DesignTicketActor _self;
  final $Res Function(DesignTicketActor) _then;

/// Create a copy of DesignTicketActor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DesignTicketActor].
extension DesignTicketActorPatterns on DesignTicketActor {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesignTicketActor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesignTicketActor() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesignTicketActor value)  $default,){
final _that = this;
switch (_that) {
case _DesignTicketActor():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesignTicketActor value)?  $default,){
final _that = this;
switch (_that) {
case _DesignTicketActor() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DesignTicketActor() when $default != null:
return $default(_that.id,_that.name);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name)  $default,) {final _that = this;
switch (_that) {
case _DesignTicketActor():
return $default(_that.id,_that.name);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _DesignTicketActor() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DesignTicketActor implements DesignTicketActor {
  const _DesignTicketActor({required this.id, required this.name});
  factory _DesignTicketActor.fromJson(Map<String, dynamic> json) => _$DesignTicketActorFromJson(json);

@override final  int id;
@override final  String name;

/// Create a copy of DesignTicketActor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesignTicketActorCopyWith<_DesignTicketActor> get copyWith => __$DesignTicketActorCopyWithImpl<_DesignTicketActor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DesignTicketActorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesignTicketActor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'DesignTicketActor(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$DesignTicketActorCopyWith<$Res> implements $DesignTicketActorCopyWith<$Res> {
  factory _$DesignTicketActorCopyWith(_DesignTicketActor value, $Res Function(_DesignTicketActor) _then) = __$DesignTicketActorCopyWithImpl;
@override @useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class __$DesignTicketActorCopyWithImpl<$Res>
    implements _$DesignTicketActorCopyWith<$Res> {
  __$DesignTicketActorCopyWithImpl(this._self, this._then);

  final _DesignTicketActor _self;
  final $Res Function(_DesignTicketActor) _then;

/// Create a copy of DesignTicketActor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_DesignTicketActor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
