// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_design.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CustomerDesign {

 int get id;@JsonKey(name: 'customer_id') int get customerId;/// What staff read to tell two designs apart. Never null: the server falls back to the
/// filename, because a row with no name is one nobody dares print from.
 String get label; String? get notes;@JsonKey(unknownEnumValue: DesignKind.unknown) DesignKind get kind;/// The kind in Arabic, as the server words it. Shown instead of a switch over [kind] so an
/// [DesignKind.unknown] still names itself.
@JsonKey(name: 'kind_label') String get kindLabel;@JsonKey(name: 'mime_type') String? get mimeType;@JsonKey(name: 'original_filename') String? get originalFilename;@JsonKey(name: 'size_bytes') int? get sizeBytes;@JsonKey(name: 'width_px') int? get widthPx;@JsonKey(name: 'height_px') int? get heightPx;/// Generated per request — see the note on the class.
@JsonKey(name: 'file_url') String? get fileUrl;/// A server-rendered first page for a PDF. Always null today; the key exists so that
/// feature can land without an app release.
@JsonKey(name: 'preview_url') String? get previewUrl;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of CustomerDesign
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerDesignCopyWith<CustomerDesign> get copyWith => _$CustomerDesignCopyWithImpl<CustomerDesign>(this as CustomerDesign, _$identity);

  /// Serializes this CustomerDesign to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerDesign&&(identical(other.id, id) || other.id == id)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.label, label) || other.label == label)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.kindLabel, kindLabel) || other.kindLabel == kindLabel)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.originalFilename, originalFilename) || other.originalFilename == originalFilename)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.widthPx, widthPx) || other.widthPx == widthPx)&&(identical(other.heightPx, heightPx) || other.heightPx == heightPx)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.previewUrl, previewUrl) || other.previewUrl == previewUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,customerId,label,notes,kind,kindLabel,mimeType,originalFilename,sizeBytes,widthPx,heightPx,fileUrl,previewUrl,createdAt);

@override
String toString() {
  return 'CustomerDesign(id: $id, customerId: $customerId, label: $label, notes: $notes, kind: $kind, kindLabel: $kindLabel, mimeType: $mimeType, originalFilename: $originalFilename, sizeBytes: $sizeBytes, widthPx: $widthPx, heightPx: $heightPx, fileUrl: $fileUrl, previewUrl: $previewUrl, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $CustomerDesignCopyWith<$Res>  {
  factory $CustomerDesignCopyWith(CustomerDesign value, $Res Function(CustomerDesign) _then) = _$CustomerDesignCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'customer_id') int customerId, String label, String? notes,@JsonKey(unknownEnumValue: DesignKind.unknown) DesignKind kind,@JsonKey(name: 'kind_label') String kindLabel,@JsonKey(name: 'mime_type') String? mimeType,@JsonKey(name: 'original_filename') String? originalFilename,@JsonKey(name: 'size_bytes') int? sizeBytes,@JsonKey(name: 'width_px') int? widthPx,@JsonKey(name: 'height_px') int? heightPx,@JsonKey(name: 'file_url') String? fileUrl,@JsonKey(name: 'preview_url') String? previewUrl,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$CustomerDesignCopyWithImpl<$Res>
    implements $CustomerDesignCopyWith<$Res> {
  _$CustomerDesignCopyWithImpl(this._self, this._then);

  final CustomerDesign _self;
  final $Res Function(CustomerDesign) _then;

/// Create a copy of CustomerDesign
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? customerId = null,Object? label = null,Object? notes = freezed,Object? kind = null,Object? kindLabel = null,Object? mimeType = freezed,Object? originalFilename = freezed,Object? sizeBytes = freezed,Object? widthPx = freezed,Object? heightPx = freezed,Object? fileUrl = freezed,Object? previewUrl = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as DesignKind,kindLabel: null == kindLabel ? _self.kindLabel : kindLabel // ignore: cast_nullable_to_non_nullable
as String,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,originalFilename: freezed == originalFilename ? _self.originalFilename : originalFilename // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,widthPx: freezed == widthPx ? _self.widthPx : widthPx // ignore: cast_nullable_to_non_nullable
as int?,heightPx: freezed == heightPx ? _self.heightPx : heightPx // ignore: cast_nullable_to_non_nullable
as int?,fileUrl: freezed == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String?,previewUrl: freezed == previewUrl ? _self.previewUrl : previewUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomerDesign].
extension CustomerDesignPatterns on CustomerDesign {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomerDesign value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomerDesign() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomerDesign value)  $default,){
final _that = this;
switch (_that) {
case _CustomerDesign():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomerDesign value)?  $default,){
final _that = this;
switch (_that) {
case _CustomerDesign() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'customer_id')  int customerId,  String label,  String? notes, @JsonKey(unknownEnumValue: DesignKind.unknown)  DesignKind kind, @JsonKey(name: 'kind_label')  String kindLabel, @JsonKey(name: 'mime_type')  String? mimeType, @JsonKey(name: 'original_filename')  String? originalFilename, @JsonKey(name: 'size_bytes')  int? sizeBytes, @JsonKey(name: 'width_px')  int? widthPx, @JsonKey(name: 'height_px')  int? heightPx, @JsonKey(name: 'file_url')  String? fileUrl, @JsonKey(name: 'preview_url')  String? previewUrl, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomerDesign() when $default != null:
return $default(_that.id,_that.customerId,_that.label,_that.notes,_that.kind,_that.kindLabel,_that.mimeType,_that.originalFilename,_that.sizeBytes,_that.widthPx,_that.heightPx,_that.fileUrl,_that.previewUrl,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'customer_id')  int customerId,  String label,  String? notes, @JsonKey(unknownEnumValue: DesignKind.unknown)  DesignKind kind, @JsonKey(name: 'kind_label')  String kindLabel, @JsonKey(name: 'mime_type')  String? mimeType, @JsonKey(name: 'original_filename')  String? originalFilename, @JsonKey(name: 'size_bytes')  int? sizeBytes, @JsonKey(name: 'width_px')  int? widthPx, @JsonKey(name: 'height_px')  int? heightPx, @JsonKey(name: 'file_url')  String? fileUrl, @JsonKey(name: 'preview_url')  String? previewUrl, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _CustomerDesign():
return $default(_that.id,_that.customerId,_that.label,_that.notes,_that.kind,_that.kindLabel,_that.mimeType,_that.originalFilename,_that.sizeBytes,_that.widthPx,_that.heightPx,_that.fileUrl,_that.previewUrl,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'customer_id')  int customerId,  String label,  String? notes, @JsonKey(unknownEnumValue: DesignKind.unknown)  DesignKind kind, @JsonKey(name: 'kind_label')  String kindLabel, @JsonKey(name: 'mime_type')  String? mimeType, @JsonKey(name: 'original_filename')  String? originalFilename, @JsonKey(name: 'size_bytes')  int? sizeBytes, @JsonKey(name: 'width_px')  int? widthPx, @JsonKey(name: 'height_px')  int? heightPx, @JsonKey(name: 'file_url')  String? fileUrl, @JsonKey(name: 'preview_url')  String? previewUrl, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _CustomerDesign() when $default != null:
return $default(_that.id,_that.customerId,_that.label,_that.notes,_that.kind,_that.kindLabel,_that.mimeType,_that.originalFilename,_that.sizeBytes,_that.widthPx,_that.heightPx,_that.fileUrl,_that.previewUrl,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CustomerDesign extends CustomerDesign {
  const _CustomerDesign({required this.id, @JsonKey(name: 'customer_id') required this.customerId, required this.label, this.notes, @JsonKey(unknownEnumValue: DesignKind.unknown) required this.kind, @JsonKey(name: 'kind_label') required this.kindLabel, @JsonKey(name: 'mime_type') this.mimeType, @JsonKey(name: 'original_filename') this.originalFilename, @JsonKey(name: 'size_bytes') this.sizeBytes, @JsonKey(name: 'width_px') this.widthPx, @JsonKey(name: 'height_px') this.heightPx, @JsonKey(name: 'file_url') this.fileUrl, @JsonKey(name: 'preview_url') this.previewUrl, @JsonKey(name: 'created_at') this.createdAt}): super._();
  factory _CustomerDesign.fromJson(Map<String, dynamic> json) => _$CustomerDesignFromJson(json);

@override final  int id;
@override@JsonKey(name: 'customer_id') final  int customerId;
/// What staff read to tell two designs apart. Never null: the server falls back to the
/// filename, because a row with no name is one nobody dares print from.
@override final  String label;
@override final  String? notes;
@override@JsonKey(unknownEnumValue: DesignKind.unknown) final  DesignKind kind;
/// The kind in Arabic, as the server words it. Shown instead of a switch over [kind] so an
/// [DesignKind.unknown] still names itself.
@override@JsonKey(name: 'kind_label') final  String kindLabel;
@override@JsonKey(name: 'mime_type') final  String? mimeType;
@override@JsonKey(name: 'original_filename') final  String? originalFilename;
@override@JsonKey(name: 'size_bytes') final  int? sizeBytes;
@override@JsonKey(name: 'width_px') final  int? widthPx;
@override@JsonKey(name: 'height_px') final  int? heightPx;
/// Generated per request — see the note on the class.
@override@JsonKey(name: 'file_url') final  String? fileUrl;
/// A server-rendered first page for a PDF. Always null today; the key exists so that
/// feature can land without an app release.
@override@JsonKey(name: 'preview_url') final  String? previewUrl;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of CustomerDesign
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerDesignCopyWith<_CustomerDesign> get copyWith => __$CustomerDesignCopyWithImpl<_CustomerDesign>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CustomerDesignToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerDesign&&(identical(other.id, id) || other.id == id)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.label, label) || other.label == label)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.kindLabel, kindLabel) || other.kindLabel == kindLabel)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.originalFilename, originalFilename) || other.originalFilename == originalFilename)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.widthPx, widthPx) || other.widthPx == widthPx)&&(identical(other.heightPx, heightPx) || other.heightPx == heightPx)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.previewUrl, previewUrl) || other.previewUrl == previewUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,customerId,label,notes,kind,kindLabel,mimeType,originalFilename,sizeBytes,widthPx,heightPx,fileUrl,previewUrl,createdAt);

@override
String toString() {
  return 'CustomerDesign(id: $id, customerId: $customerId, label: $label, notes: $notes, kind: $kind, kindLabel: $kindLabel, mimeType: $mimeType, originalFilename: $originalFilename, sizeBytes: $sizeBytes, widthPx: $widthPx, heightPx: $heightPx, fileUrl: $fileUrl, previewUrl: $previewUrl, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$CustomerDesignCopyWith<$Res> implements $CustomerDesignCopyWith<$Res> {
  factory _$CustomerDesignCopyWith(_CustomerDesign value, $Res Function(_CustomerDesign) _then) = __$CustomerDesignCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'customer_id') int customerId, String label, String? notes,@JsonKey(unknownEnumValue: DesignKind.unknown) DesignKind kind,@JsonKey(name: 'kind_label') String kindLabel,@JsonKey(name: 'mime_type') String? mimeType,@JsonKey(name: 'original_filename') String? originalFilename,@JsonKey(name: 'size_bytes') int? sizeBytes,@JsonKey(name: 'width_px') int? widthPx,@JsonKey(name: 'height_px') int? heightPx,@JsonKey(name: 'file_url') String? fileUrl,@JsonKey(name: 'preview_url') String? previewUrl,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$CustomerDesignCopyWithImpl<$Res>
    implements _$CustomerDesignCopyWith<$Res> {
  __$CustomerDesignCopyWithImpl(this._self, this._then);

  final _CustomerDesign _self;
  final $Res Function(_CustomerDesign) _then;

/// Create a copy of CustomerDesign
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? customerId = null,Object? label = null,Object? notes = freezed,Object? kind = null,Object? kindLabel = null,Object? mimeType = freezed,Object? originalFilename = freezed,Object? sizeBytes = freezed,Object? widthPx = freezed,Object? heightPx = freezed,Object? fileUrl = freezed,Object? previewUrl = freezed,Object? createdAt = freezed,}) {
  return _then(_CustomerDesign(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as DesignKind,kindLabel: null == kindLabel ? _self.kindLabel : kindLabel // ignore: cast_nullable_to_non_nullable
as String,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,originalFilename: freezed == originalFilename ? _self.originalFilename : originalFilename // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,widthPx: freezed == widthPx ? _self.widthPx : widthPx // ignore: cast_nullable_to_non_nullable
as int?,heightPx: freezed == heightPx ? _self.heightPx : heightPx // ignore: cast_nullable_to_non_nullable
as int?,fileUrl: freezed == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String?,previewUrl: freezed == previewUrl ? _self.previewUrl : previewUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
