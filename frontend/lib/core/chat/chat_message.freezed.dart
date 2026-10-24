// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatPerson {

 int get id; String get name;
/// Create a copy of ChatPerson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatPersonCopyWith<ChatPerson> get copyWith => _$ChatPersonCopyWithImpl<ChatPerson>(this as ChatPerson, _$identity);

  /// Serializes this ChatPerson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatPerson&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'ChatPerson(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $ChatPersonCopyWith<$Res>  {
  factory $ChatPersonCopyWith(ChatPerson value, $Res Function(ChatPerson) _then) = _$ChatPersonCopyWithImpl;
@useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class _$ChatPersonCopyWithImpl<$Res>
    implements $ChatPersonCopyWith<$Res> {
  _$ChatPersonCopyWithImpl(this._self, this._then);

  final ChatPerson _self;
  final $Res Function(ChatPerson) _then;

/// Create a copy of ChatPerson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatPerson].
extension ChatPersonPatterns on ChatPerson {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatPerson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatPerson() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatPerson value)  $default,){
final _that = this;
switch (_that) {
case _ChatPerson():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatPerson value)?  $default,){
final _that = this;
switch (_that) {
case _ChatPerson() when $default != null:
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
case _ChatPerson() when $default != null:
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
case _ChatPerson():
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
case _ChatPerson() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatPerson implements ChatPerson {
  const _ChatPerson({required this.id, required this.name});
  factory _ChatPerson.fromJson(Map<String, dynamic> json) => _$ChatPersonFromJson(json);

@override final  int id;
@override final  String name;

/// Create a copy of ChatPerson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatPersonCopyWith<_ChatPerson> get copyWith => __$ChatPersonCopyWithImpl<_ChatPerson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatPersonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatPerson&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'ChatPerson(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$ChatPersonCopyWith<$Res> implements $ChatPersonCopyWith<$Res> {
  factory _$ChatPersonCopyWith(_ChatPerson value, $Res Function(_ChatPerson) _then) = __$ChatPersonCopyWithImpl;
@override @useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class __$ChatPersonCopyWithImpl<$Res>
    implements _$ChatPersonCopyWith<$Res> {
  __$ChatPersonCopyWithImpl(this._self, this._then);

  final _ChatPerson _self;
  final $Res Function(_ChatPerson) _then;

/// Create a copy of ChatPerson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_ChatPerson(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ChatAttachment {

 int get id;@JsonKey(unknownEnumValue: ChatAttachmentKind.unknown) ChatAttachmentKind get kind; String? get name;@JsonKey(name: 'mime_type') String? get mimeType;@JsonKey(name: 'size_bytes') int? get sizeBytes;@JsonKey(name: 'width_px') int? get widthPx;@JsonKey(name: 'height_px') int? get heightPx;/// للصوت: كما قاسها الهاتف المرسِل، للعرض.
@JsonKey(name: 'duration_seconds') int? get durationSeconds;/// للصوت: ٤٨ رقماً من ٠ إلى ١٠٠، يحفظها الخادم فيرى المستقبِل موجةً حقيقية.
 List<int>? get waveform; String? get url;
/// Create a copy of ChatAttachment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatAttachmentCopyWith<ChatAttachment> get copyWith => _$ChatAttachmentCopyWithImpl<ChatAttachment>(this as ChatAttachment, _$identity);

  /// Serializes this ChatAttachment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatAttachment&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.name, name) || other.name == name)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.widthPx, widthPx) || other.widthPx == widthPx)&&(identical(other.heightPx, heightPx) || other.heightPx == heightPx)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&const DeepCollectionEquality().equals(other.waveform, waveform)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,name,mimeType,sizeBytes,widthPx,heightPx,durationSeconds,const DeepCollectionEquality().hash(waveform),url);

@override
String toString() {
  return 'ChatAttachment(id: $id, kind: $kind, name: $name, mimeType: $mimeType, sizeBytes: $sizeBytes, widthPx: $widthPx, heightPx: $heightPx, durationSeconds: $durationSeconds, waveform: $waveform, url: $url)';
}


}

/// @nodoc
abstract mixin class $ChatAttachmentCopyWith<$Res>  {
  factory $ChatAttachmentCopyWith(ChatAttachment value, $Res Function(ChatAttachment) _then) = _$ChatAttachmentCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(unknownEnumValue: ChatAttachmentKind.unknown) ChatAttachmentKind kind, String? name,@JsonKey(name: 'mime_type') String? mimeType,@JsonKey(name: 'size_bytes') int? sizeBytes,@JsonKey(name: 'width_px') int? widthPx,@JsonKey(name: 'height_px') int? heightPx,@JsonKey(name: 'duration_seconds') int? durationSeconds, List<int>? waveform, String? url
});




}
/// @nodoc
class _$ChatAttachmentCopyWithImpl<$Res>
    implements $ChatAttachmentCopyWith<$Res> {
  _$ChatAttachmentCopyWithImpl(this._self, this._then);

  final ChatAttachment _self;
  final $Res Function(ChatAttachment) _then;

/// Create a copy of ChatAttachment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? name = freezed,Object? mimeType = freezed,Object? sizeBytes = freezed,Object? widthPx = freezed,Object? heightPx = freezed,Object? durationSeconds = freezed,Object? waveform = freezed,Object? url = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ChatAttachmentKind,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,widthPx: freezed == widthPx ? _self.widthPx : widthPx // ignore: cast_nullable_to_non_nullable
as int?,heightPx: freezed == heightPx ? _self.heightPx : heightPx // ignore: cast_nullable_to_non_nullable
as int?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,waveform: freezed == waveform ? _self.waveform : waveform // ignore: cast_nullable_to_non_nullable
as List<int>?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatAttachment].
extension ChatAttachmentPatterns on ChatAttachment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatAttachment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatAttachment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatAttachment value)  $default,){
final _that = this;
switch (_that) {
case _ChatAttachment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatAttachment value)?  $default,){
final _that = this;
switch (_that) {
case _ChatAttachment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(unknownEnumValue: ChatAttachmentKind.unknown)  ChatAttachmentKind kind,  String? name, @JsonKey(name: 'mime_type')  String? mimeType, @JsonKey(name: 'size_bytes')  int? sizeBytes, @JsonKey(name: 'width_px')  int? widthPx, @JsonKey(name: 'height_px')  int? heightPx, @JsonKey(name: 'duration_seconds')  int? durationSeconds,  List<int>? waveform,  String? url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatAttachment() when $default != null:
return $default(_that.id,_that.kind,_that.name,_that.mimeType,_that.sizeBytes,_that.widthPx,_that.heightPx,_that.durationSeconds,_that.waveform,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(unknownEnumValue: ChatAttachmentKind.unknown)  ChatAttachmentKind kind,  String? name, @JsonKey(name: 'mime_type')  String? mimeType, @JsonKey(name: 'size_bytes')  int? sizeBytes, @JsonKey(name: 'width_px')  int? widthPx, @JsonKey(name: 'height_px')  int? heightPx, @JsonKey(name: 'duration_seconds')  int? durationSeconds,  List<int>? waveform,  String? url)  $default,) {final _that = this;
switch (_that) {
case _ChatAttachment():
return $default(_that.id,_that.kind,_that.name,_that.mimeType,_that.sizeBytes,_that.widthPx,_that.heightPx,_that.durationSeconds,_that.waveform,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(unknownEnumValue: ChatAttachmentKind.unknown)  ChatAttachmentKind kind,  String? name, @JsonKey(name: 'mime_type')  String? mimeType, @JsonKey(name: 'size_bytes')  int? sizeBytes, @JsonKey(name: 'width_px')  int? widthPx, @JsonKey(name: 'height_px')  int? heightPx, @JsonKey(name: 'duration_seconds')  int? durationSeconds,  List<int>? waveform,  String? url)?  $default,) {final _that = this;
switch (_that) {
case _ChatAttachment() when $default != null:
return $default(_that.id,_that.kind,_that.name,_that.mimeType,_that.sizeBytes,_that.widthPx,_that.heightPx,_that.durationSeconds,_that.waveform,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatAttachment implements ChatAttachment {
  const _ChatAttachment({required this.id, @JsonKey(unknownEnumValue: ChatAttachmentKind.unknown) this.kind = ChatAttachmentKind.unknown, this.name, @JsonKey(name: 'mime_type') this.mimeType, @JsonKey(name: 'size_bytes') this.sizeBytes, @JsonKey(name: 'width_px') this.widthPx, @JsonKey(name: 'height_px') this.heightPx, @JsonKey(name: 'duration_seconds') this.durationSeconds, final  List<int>? waveform, this.url}): _waveform = waveform;
  factory _ChatAttachment.fromJson(Map<String, dynamic> json) => _$ChatAttachmentFromJson(json);

@override final  int id;
@override@JsonKey(unknownEnumValue: ChatAttachmentKind.unknown) final  ChatAttachmentKind kind;
@override final  String? name;
@override@JsonKey(name: 'mime_type') final  String? mimeType;
@override@JsonKey(name: 'size_bytes') final  int? sizeBytes;
@override@JsonKey(name: 'width_px') final  int? widthPx;
@override@JsonKey(name: 'height_px') final  int? heightPx;
/// للصوت: كما قاسها الهاتف المرسِل، للعرض.
@override@JsonKey(name: 'duration_seconds') final  int? durationSeconds;
/// للصوت: ٤٨ رقماً من ٠ إلى ١٠٠، يحفظها الخادم فيرى المستقبِل موجةً حقيقية.
 final  List<int>? _waveform;
/// للصوت: ٤٨ رقماً من ٠ إلى ١٠٠، يحفظها الخادم فيرى المستقبِل موجةً حقيقية.
@override List<int>? get waveform {
  final value = _waveform;
  if (value == null) return null;
  if (_waveform is EqualUnmodifiableListView) return _waveform;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? url;

/// Create a copy of ChatAttachment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatAttachmentCopyWith<_ChatAttachment> get copyWith => __$ChatAttachmentCopyWithImpl<_ChatAttachment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatAttachmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatAttachment&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.name, name) || other.name == name)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.widthPx, widthPx) || other.widthPx == widthPx)&&(identical(other.heightPx, heightPx) || other.heightPx == heightPx)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&const DeepCollectionEquality().equals(other._waveform, _waveform)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,name,mimeType,sizeBytes,widthPx,heightPx,durationSeconds,const DeepCollectionEquality().hash(_waveform),url);

@override
String toString() {
  return 'ChatAttachment(id: $id, kind: $kind, name: $name, mimeType: $mimeType, sizeBytes: $sizeBytes, widthPx: $widthPx, heightPx: $heightPx, durationSeconds: $durationSeconds, waveform: $waveform, url: $url)';
}


}

/// @nodoc
abstract mixin class _$ChatAttachmentCopyWith<$Res> implements $ChatAttachmentCopyWith<$Res> {
  factory _$ChatAttachmentCopyWith(_ChatAttachment value, $Res Function(_ChatAttachment) _then) = __$ChatAttachmentCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(unknownEnumValue: ChatAttachmentKind.unknown) ChatAttachmentKind kind, String? name,@JsonKey(name: 'mime_type') String? mimeType,@JsonKey(name: 'size_bytes') int? sizeBytes,@JsonKey(name: 'width_px') int? widthPx,@JsonKey(name: 'height_px') int? heightPx,@JsonKey(name: 'duration_seconds') int? durationSeconds, List<int>? waveform, String? url
});




}
/// @nodoc
class __$ChatAttachmentCopyWithImpl<$Res>
    implements _$ChatAttachmentCopyWith<$Res> {
  __$ChatAttachmentCopyWithImpl(this._self, this._then);

  final _ChatAttachment _self;
  final $Res Function(_ChatAttachment) _then;

/// Create a copy of ChatAttachment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? name = freezed,Object? mimeType = freezed,Object? sizeBytes = freezed,Object? widthPx = freezed,Object? heightPx = freezed,Object? durationSeconds = freezed,Object? waveform = freezed,Object? url = freezed,}) {
  return _then(_ChatAttachment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ChatAttachmentKind,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,widthPx: freezed == widthPx ? _self.widthPx : widthPx // ignore: cast_nullable_to_non_nullable
as int?,heightPx: freezed == heightPx ? _self.heightPx : heightPx // ignore: cast_nullable_to_non_nullable
as int?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,waveform: freezed == waveform ? _self._waveform : waveform // ignore: cast_nullable_to_non_nullable
as List<int>?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ChatQuote {

 int get id;@JsonKey(name: 'author_name') String? get authorName; String get preview;@JsonKey(name: 'is_deleted') bool get isDeleted;
/// Create a copy of ChatQuote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatQuoteCopyWith<ChatQuote> get copyWith => _$ChatQuoteCopyWithImpl<ChatQuote>(this as ChatQuote, _$identity);

  /// Serializes this ChatQuote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatQuote&&(identical(other.id, id) || other.id == id)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.preview, preview) || other.preview == preview)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,authorName,preview,isDeleted);

@override
String toString() {
  return 'ChatQuote(id: $id, authorName: $authorName, preview: $preview, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class $ChatQuoteCopyWith<$Res>  {
  factory $ChatQuoteCopyWith(ChatQuote value, $Res Function(ChatQuote) _then) = _$ChatQuoteCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'author_name') String? authorName, String preview,@JsonKey(name: 'is_deleted') bool isDeleted
});




}
/// @nodoc
class _$ChatQuoteCopyWithImpl<$Res>
    implements $ChatQuoteCopyWith<$Res> {
  _$ChatQuoteCopyWithImpl(this._self, this._then);

  final ChatQuote _self;
  final $Res Function(ChatQuote) _then;

/// Create a copy of ChatQuote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? authorName = freezed,Object? preview = null,Object? isDeleted = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,preview: null == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as String,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatQuote].
extension ChatQuotePatterns on ChatQuote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatQuote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatQuote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatQuote value)  $default,){
final _that = this;
switch (_that) {
case _ChatQuote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatQuote value)?  $default,){
final _that = this;
switch (_that) {
case _ChatQuote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'author_name')  String? authorName,  String preview, @JsonKey(name: 'is_deleted')  bool isDeleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatQuote() when $default != null:
return $default(_that.id,_that.authorName,_that.preview,_that.isDeleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'author_name')  String? authorName,  String preview, @JsonKey(name: 'is_deleted')  bool isDeleted)  $default,) {final _that = this;
switch (_that) {
case _ChatQuote():
return $default(_that.id,_that.authorName,_that.preview,_that.isDeleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'author_name')  String? authorName,  String preview, @JsonKey(name: 'is_deleted')  bool isDeleted)?  $default,) {final _that = this;
switch (_that) {
case _ChatQuote() when $default != null:
return $default(_that.id,_that.authorName,_that.preview,_that.isDeleted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatQuote implements ChatQuote {
  const _ChatQuote({required this.id, @JsonKey(name: 'author_name') this.authorName, this.preview = '', @JsonKey(name: 'is_deleted') this.isDeleted = false});
  factory _ChatQuote.fromJson(Map<String, dynamic> json) => _$ChatQuoteFromJson(json);

@override final  int id;
@override@JsonKey(name: 'author_name') final  String? authorName;
@override@JsonKey() final  String preview;
@override@JsonKey(name: 'is_deleted') final  bool isDeleted;

/// Create a copy of ChatQuote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatQuoteCopyWith<_ChatQuote> get copyWith => __$ChatQuoteCopyWithImpl<_ChatQuote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatQuoteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatQuote&&(identical(other.id, id) || other.id == id)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.preview, preview) || other.preview == preview)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,authorName,preview,isDeleted);

@override
String toString() {
  return 'ChatQuote(id: $id, authorName: $authorName, preview: $preview, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class _$ChatQuoteCopyWith<$Res> implements $ChatQuoteCopyWith<$Res> {
  factory _$ChatQuoteCopyWith(_ChatQuote value, $Res Function(_ChatQuote) _then) = __$ChatQuoteCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'author_name') String? authorName, String preview,@JsonKey(name: 'is_deleted') bool isDeleted
});




}
/// @nodoc
class __$ChatQuoteCopyWithImpl<$Res>
    implements _$ChatQuoteCopyWith<$Res> {
  __$ChatQuoteCopyWithImpl(this._self, this._then);

  final _ChatQuote _self;
  final $Res Function(_ChatQuote) _then;

/// Create a copy of ChatQuote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? authorName = freezed,Object? preview = null,Object? isDeleted = null,}) {
  return _then(_ChatQuote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,preview: null == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as String,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ChatMessage {

 int get id;@JsonKey(name: 'ticket_id') int? get ticketId; ChatPerson? get author;@JsonKey(name: 'is_mine') bool get isMine;/// «تم حذف هذه الرسالة» حين [isDeleted] — نصٌّ لا `null`، كي تُرسم فقاعةً عادية.
 String? get body;@JsonKey(name: 'is_deleted') bool get isDeleted;@JsonKey(name: 'is_edited') bool get isEdited;@JsonKey(name: 'reply_to') ChatQuote? get replyTo; List<ChatAttachment> get attachments;@JsonKey(name: 'client_token') String? get clientToken;@JsonKey(name: 'sent_at') DateTime? get sentAt;@JsonKey(name: 'can_edit') bool get canEdit;@JsonKey(name: 'can_delete') bool get canDelete;/// لماذا الزرّ مطفأ — الجملةُ نفسها التي يرفض بها الخادم.
@JsonKey(name: 'mutation_block_reason') String? get mutationBlockReason;@JsonKey(name: 'mutable_until') DateTime? get mutableUntil;
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<ChatMessage> get copyWith => _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);

  /// Serializes this ChatMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId)&&(identical(other.author, author) || other.author == author)&&(identical(other.isMine, isMine) || other.isMine == isMine)&&(identical(other.body, body) || other.body == body)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.isEdited, isEdited) || other.isEdited == isEdited)&&(identical(other.replyTo, replyTo) || other.replyTo == replyTo)&&const DeepCollectionEquality().equals(other.attachments, attachments)&&(identical(other.clientToken, clientToken) || other.clientToken == clientToken)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.canEdit, canEdit) || other.canEdit == canEdit)&&(identical(other.canDelete, canDelete) || other.canDelete == canDelete)&&(identical(other.mutationBlockReason, mutationBlockReason) || other.mutationBlockReason == mutationBlockReason)&&(identical(other.mutableUntil, mutableUntil) || other.mutableUntil == mutableUntil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ticketId,author,isMine,body,isDeleted,isEdited,replyTo,const DeepCollectionEquality().hash(attachments),clientToken,sentAt,canEdit,canDelete,mutationBlockReason,mutableUntil);

@override
String toString() {
  return 'ChatMessage(id: $id, ticketId: $ticketId, author: $author, isMine: $isMine, body: $body, isDeleted: $isDeleted, isEdited: $isEdited, replyTo: $replyTo, attachments: $attachments, clientToken: $clientToken, sentAt: $sentAt, canEdit: $canEdit, canDelete: $canDelete, mutationBlockReason: $mutationBlockReason, mutableUntil: $mutableUntil)';
}


}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res>  {
  factory $ChatMessageCopyWith(ChatMessage value, $Res Function(ChatMessage) _then) = _$ChatMessageCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'ticket_id') int? ticketId, ChatPerson? author,@JsonKey(name: 'is_mine') bool isMine, String? body,@JsonKey(name: 'is_deleted') bool isDeleted,@JsonKey(name: 'is_edited') bool isEdited,@JsonKey(name: 'reply_to') ChatQuote? replyTo, List<ChatAttachment> attachments,@JsonKey(name: 'client_token') String? clientToken,@JsonKey(name: 'sent_at') DateTime? sentAt,@JsonKey(name: 'can_edit') bool canEdit,@JsonKey(name: 'can_delete') bool canDelete,@JsonKey(name: 'mutation_block_reason') String? mutationBlockReason,@JsonKey(name: 'mutable_until') DateTime? mutableUntil
});


$ChatPersonCopyWith<$Res>? get author;$ChatQuoteCopyWith<$Res>? get replyTo;

}
/// @nodoc
class _$ChatMessageCopyWithImpl<$Res>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._self, this._then);

  final ChatMessage _self;
  final $Res Function(ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ticketId = freezed,Object? author = freezed,Object? isMine = null,Object? body = freezed,Object? isDeleted = null,Object? isEdited = null,Object? replyTo = freezed,Object? attachments = null,Object? clientToken = freezed,Object? sentAt = freezed,Object? canEdit = null,Object? canDelete = null,Object? mutationBlockReason = freezed,Object? mutableUntil = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,ticketId: freezed == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as int?,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as ChatPerson?,isMine: null == isMine ? _self.isMine : isMine // ignore: cast_nullable_to_non_nullable
as bool,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,isEdited: null == isEdited ? _self.isEdited : isEdited // ignore: cast_nullable_to_non_nullable
as bool,replyTo: freezed == replyTo ? _self.replyTo : replyTo // ignore: cast_nullable_to_non_nullable
as ChatQuote?,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<ChatAttachment>,clientToken: freezed == clientToken ? _self.clientToken : clientToken // ignore: cast_nullable_to_non_nullable
as String?,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,canEdit: null == canEdit ? _self.canEdit : canEdit // ignore: cast_nullable_to_non_nullable
as bool,canDelete: null == canDelete ? _self.canDelete : canDelete // ignore: cast_nullable_to_non_nullable
as bool,mutationBlockReason: freezed == mutationBlockReason ? _self.mutationBlockReason : mutationBlockReason // ignore: cast_nullable_to_non_nullable
as String?,mutableUntil: freezed == mutableUntil ? _self.mutableUntil : mutableUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatPersonCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $ChatPersonCopyWith<$Res>(_self.author!, (value) {
    return _then(_self.copyWith(author: value));
  });
}/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatQuoteCopyWith<$Res>? get replyTo {
    if (_self.replyTo == null) {
    return null;
  }

  return $ChatQuoteCopyWith<$Res>(_self.replyTo!, (value) {
    return _then(_self.copyWith(replyTo: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatMessage].
extension ChatMessagePatterns on ChatMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessage value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'ticket_id')  int? ticketId,  ChatPerson? author, @JsonKey(name: 'is_mine')  bool isMine,  String? body, @JsonKey(name: 'is_deleted')  bool isDeleted, @JsonKey(name: 'is_edited')  bool isEdited, @JsonKey(name: 'reply_to')  ChatQuote? replyTo,  List<ChatAttachment> attachments, @JsonKey(name: 'client_token')  String? clientToken, @JsonKey(name: 'sent_at')  DateTime? sentAt, @JsonKey(name: 'can_edit')  bool canEdit, @JsonKey(name: 'can_delete')  bool canDelete, @JsonKey(name: 'mutation_block_reason')  String? mutationBlockReason, @JsonKey(name: 'mutable_until')  DateTime? mutableUntil)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.ticketId,_that.author,_that.isMine,_that.body,_that.isDeleted,_that.isEdited,_that.replyTo,_that.attachments,_that.clientToken,_that.sentAt,_that.canEdit,_that.canDelete,_that.mutationBlockReason,_that.mutableUntil);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'ticket_id')  int? ticketId,  ChatPerson? author, @JsonKey(name: 'is_mine')  bool isMine,  String? body, @JsonKey(name: 'is_deleted')  bool isDeleted, @JsonKey(name: 'is_edited')  bool isEdited, @JsonKey(name: 'reply_to')  ChatQuote? replyTo,  List<ChatAttachment> attachments, @JsonKey(name: 'client_token')  String? clientToken, @JsonKey(name: 'sent_at')  DateTime? sentAt, @JsonKey(name: 'can_edit')  bool canEdit, @JsonKey(name: 'can_delete')  bool canDelete, @JsonKey(name: 'mutation_block_reason')  String? mutationBlockReason, @JsonKey(name: 'mutable_until')  DateTime? mutableUntil)  $default,) {final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that.id,_that.ticketId,_that.author,_that.isMine,_that.body,_that.isDeleted,_that.isEdited,_that.replyTo,_that.attachments,_that.clientToken,_that.sentAt,_that.canEdit,_that.canDelete,_that.mutationBlockReason,_that.mutableUntil);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'ticket_id')  int? ticketId,  ChatPerson? author, @JsonKey(name: 'is_mine')  bool isMine,  String? body, @JsonKey(name: 'is_deleted')  bool isDeleted, @JsonKey(name: 'is_edited')  bool isEdited, @JsonKey(name: 'reply_to')  ChatQuote? replyTo,  List<ChatAttachment> attachments, @JsonKey(name: 'client_token')  String? clientToken, @JsonKey(name: 'sent_at')  DateTime? sentAt, @JsonKey(name: 'can_edit')  bool canEdit, @JsonKey(name: 'can_delete')  bool canDelete, @JsonKey(name: 'mutation_block_reason')  String? mutationBlockReason, @JsonKey(name: 'mutable_until')  DateTime? mutableUntil)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.ticketId,_that.author,_that.isMine,_that.body,_that.isDeleted,_that.isEdited,_that.replyTo,_that.attachments,_that.clientToken,_that.sentAt,_that.canEdit,_that.canDelete,_that.mutationBlockReason,_that.mutableUntil);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatMessage extends ChatMessage {
  const _ChatMessage({required this.id, @JsonKey(name: 'ticket_id') this.ticketId, this.author, @JsonKey(name: 'is_mine') this.isMine = false, this.body, @JsonKey(name: 'is_deleted') this.isDeleted = false, @JsonKey(name: 'is_edited') this.isEdited = false, @JsonKey(name: 'reply_to') this.replyTo, final  List<ChatAttachment> attachments = const <ChatAttachment>[], @JsonKey(name: 'client_token') this.clientToken, @JsonKey(name: 'sent_at') this.sentAt, @JsonKey(name: 'can_edit') this.canEdit = false, @JsonKey(name: 'can_delete') this.canDelete = false, @JsonKey(name: 'mutation_block_reason') this.mutationBlockReason, @JsonKey(name: 'mutable_until') this.mutableUntil}): _attachments = attachments,super._();
  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

@override final  int id;
@override@JsonKey(name: 'ticket_id') final  int? ticketId;
@override final  ChatPerson? author;
@override@JsonKey(name: 'is_mine') final  bool isMine;
/// «تم حذف هذه الرسالة» حين [isDeleted] — نصٌّ لا `null`، كي تُرسم فقاعةً عادية.
@override final  String? body;
@override@JsonKey(name: 'is_deleted') final  bool isDeleted;
@override@JsonKey(name: 'is_edited') final  bool isEdited;
@override@JsonKey(name: 'reply_to') final  ChatQuote? replyTo;
 final  List<ChatAttachment> _attachments;
@override@JsonKey() List<ChatAttachment> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}

@override@JsonKey(name: 'client_token') final  String? clientToken;
@override@JsonKey(name: 'sent_at') final  DateTime? sentAt;
@override@JsonKey(name: 'can_edit') final  bool canEdit;
@override@JsonKey(name: 'can_delete') final  bool canDelete;
/// لماذا الزرّ مطفأ — الجملةُ نفسها التي يرفض بها الخادم.
@override@JsonKey(name: 'mutation_block_reason') final  String? mutationBlockReason;
@override@JsonKey(name: 'mutable_until') final  DateTime? mutableUntil;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageCopyWith<_ChatMessage> get copyWith => __$ChatMessageCopyWithImpl<_ChatMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId)&&(identical(other.author, author) || other.author == author)&&(identical(other.isMine, isMine) || other.isMine == isMine)&&(identical(other.body, body) || other.body == body)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.isEdited, isEdited) || other.isEdited == isEdited)&&(identical(other.replyTo, replyTo) || other.replyTo == replyTo)&&const DeepCollectionEquality().equals(other._attachments, _attachments)&&(identical(other.clientToken, clientToken) || other.clientToken == clientToken)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.canEdit, canEdit) || other.canEdit == canEdit)&&(identical(other.canDelete, canDelete) || other.canDelete == canDelete)&&(identical(other.mutationBlockReason, mutationBlockReason) || other.mutationBlockReason == mutationBlockReason)&&(identical(other.mutableUntil, mutableUntil) || other.mutableUntil == mutableUntil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ticketId,author,isMine,body,isDeleted,isEdited,replyTo,const DeepCollectionEquality().hash(_attachments),clientToken,sentAt,canEdit,canDelete,mutationBlockReason,mutableUntil);

@override
String toString() {
  return 'ChatMessage(id: $id, ticketId: $ticketId, author: $author, isMine: $isMine, body: $body, isDeleted: $isDeleted, isEdited: $isEdited, replyTo: $replyTo, attachments: $attachments, clientToken: $clientToken, sentAt: $sentAt, canEdit: $canEdit, canDelete: $canDelete, mutationBlockReason: $mutationBlockReason, mutableUntil: $mutableUntil)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory _$ChatMessageCopyWith(_ChatMessage value, $Res Function(_ChatMessage) _then) = __$ChatMessageCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'ticket_id') int? ticketId, ChatPerson? author,@JsonKey(name: 'is_mine') bool isMine, String? body,@JsonKey(name: 'is_deleted') bool isDeleted,@JsonKey(name: 'is_edited') bool isEdited,@JsonKey(name: 'reply_to') ChatQuote? replyTo, List<ChatAttachment> attachments,@JsonKey(name: 'client_token') String? clientToken,@JsonKey(name: 'sent_at') DateTime? sentAt,@JsonKey(name: 'can_edit') bool canEdit,@JsonKey(name: 'can_delete') bool canDelete,@JsonKey(name: 'mutation_block_reason') String? mutationBlockReason,@JsonKey(name: 'mutable_until') DateTime? mutableUntil
});


@override $ChatPersonCopyWith<$Res>? get author;@override $ChatQuoteCopyWith<$Res>? get replyTo;

}
/// @nodoc
class __$ChatMessageCopyWithImpl<$Res>
    implements _$ChatMessageCopyWith<$Res> {
  __$ChatMessageCopyWithImpl(this._self, this._then);

  final _ChatMessage _self;
  final $Res Function(_ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ticketId = freezed,Object? author = freezed,Object? isMine = null,Object? body = freezed,Object? isDeleted = null,Object? isEdited = null,Object? replyTo = freezed,Object? attachments = null,Object? clientToken = freezed,Object? sentAt = freezed,Object? canEdit = null,Object? canDelete = null,Object? mutationBlockReason = freezed,Object? mutableUntil = freezed,}) {
  return _then(_ChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,ticketId: freezed == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as int?,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as ChatPerson?,isMine: null == isMine ? _self.isMine : isMine // ignore: cast_nullable_to_non_nullable
as bool,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,isEdited: null == isEdited ? _self.isEdited : isEdited // ignore: cast_nullable_to_non_nullable
as bool,replyTo: freezed == replyTo ? _self.replyTo : replyTo // ignore: cast_nullable_to_non_nullable
as ChatQuote?,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<ChatAttachment>,clientToken: freezed == clientToken ? _self.clientToken : clientToken // ignore: cast_nullable_to_non_nullable
as String?,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,canEdit: null == canEdit ? _self.canEdit : canEdit // ignore: cast_nullable_to_non_nullable
as bool,canDelete: null == canDelete ? _self.canDelete : canDelete // ignore: cast_nullable_to_non_nullable
as bool,mutationBlockReason: freezed == mutationBlockReason ? _self.mutationBlockReason : mutationBlockReason // ignore: cast_nullable_to_non_nullable
as String?,mutableUntil: freezed == mutableUntil ? _self.mutableUntil : mutableUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatPersonCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $ChatPersonCopyWith<$Res>(_self.author!, (value) {
    return _then(_self.copyWith(author: value));
  });
}/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatQuoteCopyWith<$Res>? get replyTo {
    if (_self.replyTo == null) {
    return null;
  }

  return $ChatQuoteCopyWith<$Res>(_self.replyTo!, (value) {
    return _then(_self.copyWith(replyTo: value));
  });
}
}

/// @nodoc
mixin _$PendingVoice {

 String get path; int get durationSeconds; List<int> get waveform; String get clientToken; int? get replyToMessageId;
/// Create a copy of PendingVoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingVoiceCopyWith<PendingVoice> get copyWith => _$PendingVoiceCopyWithImpl<PendingVoice>(this as PendingVoice, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingVoice&&(identical(other.path, path) || other.path == path)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&const DeepCollectionEquality().equals(other.waveform, waveform)&&(identical(other.clientToken, clientToken) || other.clientToken == clientToken)&&(identical(other.replyToMessageId, replyToMessageId) || other.replyToMessageId == replyToMessageId));
}


@override
int get hashCode => Object.hash(runtimeType,path,durationSeconds,const DeepCollectionEquality().hash(waveform),clientToken,replyToMessageId);

@override
String toString() {
  return 'PendingVoice(path: $path, durationSeconds: $durationSeconds, waveform: $waveform, clientToken: $clientToken, replyToMessageId: $replyToMessageId)';
}


}

/// @nodoc
abstract mixin class $PendingVoiceCopyWith<$Res>  {
  factory $PendingVoiceCopyWith(PendingVoice value, $Res Function(PendingVoice) _then) = _$PendingVoiceCopyWithImpl;
@useResult
$Res call({
 String path, int durationSeconds, List<int> waveform, String clientToken, int? replyToMessageId
});




}
/// @nodoc
class _$PendingVoiceCopyWithImpl<$Res>
    implements $PendingVoiceCopyWith<$Res> {
  _$PendingVoiceCopyWithImpl(this._self, this._then);

  final PendingVoice _self;
  final $Res Function(PendingVoice) _then;

/// Create a copy of PendingVoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? durationSeconds = null,Object? waveform = null,Object? clientToken = null,Object? replyToMessageId = freezed,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,waveform: null == waveform ? _self.waveform : waveform // ignore: cast_nullable_to_non_nullable
as List<int>,clientToken: null == clientToken ? _self.clientToken : clientToken // ignore: cast_nullable_to_non_nullable
as String,replyToMessageId: freezed == replyToMessageId ? _self.replyToMessageId : replyToMessageId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingVoice].
extension PendingVoicePatterns on PendingVoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingVoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingVoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingVoice value)  $default,){
final _that = this;
switch (_that) {
case _PendingVoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingVoice value)?  $default,){
final _that = this;
switch (_that) {
case _PendingVoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  int durationSeconds,  List<int> waveform,  String clientToken,  int? replyToMessageId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingVoice() when $default != null:
return $default(_that.path,_that.durationSeconds,_that.waveform,_that.clientToken,_that.replyToMessageId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  int durationSeconds,  List<int> waveform,  String clientToken,  int? replyToMessageId)  $default,) {final _that = this;
switch (_that) {
case _PendingVoice():
return $default(_that.path,_that.durationSeconds,_that.waveform,_that.clientToken,_that.replyToMessageId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  int durationSeconds,  List<int> waveform,  String clientToken,  int? replyToMessageId)?  $default,) {final _that = this;
switch (_that) {
case _PendingVoice() when $default != null:
return $default(_that.path,_that.durationSeconds,_that.waveform,_that.clientToken,_that.replyToMessageId);case _:
  return null;

}
}

}

/// @nodoc


class _PendingVoice implements PendingVoice {
  const _PendingVoice({required this.path, required this.durationSeconds, required final  List<int> waveform, required this.clientToken, this.replyToMessageId}): _waveform = waveform;
  

@override final  String path;
@override final  int durationSeconds;
 final  List<int> _waveform;
@override List<int> get waveform {
  if (_waveform is EqualUnmodifiableListView) return _waveform;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_waveform);
}

@override final  String clientToken;
@override final  int? replyToMessageId;

/// Create a copy of PendingVoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingVoiceCopyWith<_PendingVoice> get copyWith => __$PendingVoiceCopyWithImpl<_PendingVoice>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingVoice&&(identical(other.path, path) || other.path == path)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&const DeepCollectionEquality().equals(other._waveform, _waveform)&&(identical(other.clientToken, clientToken) || other.clientToken == clientToken)&&(identical(other.replyToMessageId, replyToMessageId) || other.replyToMessageId == replyToMessageId));
}


@override
int get hashCode => Object.hash(runtimeType,path,durationSeconds,const DeepCollectionEquality().hash(_waveform),clientToken,replyToMessageId);

@override
String toString() {
  return 'PendingVoice(path: $path, durationSeconds: $durationSeconds, waveform: $waveform, clientToken: $clientToken, replyToMessageId: $replyToMessageId)';
}


}

/// @nodoc
abstract mixin class _$PendingVoiceCopyWith<$Res> implements $PendingVoiceCopyWith<$Res> {
  factory _$PendingVoiceCopyWith(_PendingVoice value, $Res Function(_PendingVoice) _then) = __$PendingVoiceCopyWithImpl;
@override @useResult
$Res call({
 String path, int durationSeconds, List<int> waveform, String clientToken, int? replyToMessageId
});




}
/// @nodoc
class __$PendingVoiceCopyWithImpl<$Res>
    implements _$PendingVoiceCopyWith<$Res> {
  __$PendingVoiceCopyWithImpl(this._self, this._then);

  final _PendingVoice _self;
  final $Res Function(_PendingVoice) _then;

/// Create a copy of PendingVoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? durationSeconds = null,Object? waveform = null,Object? clientToken = null,Object? replyToMessageId = freezed,}) {
  return _then(_PendingVoice(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,waveform: null == waveform ? _self._waveform : waveform // ignore: cast_nullable_to_non_nullable
as List<int>,clientToken: null == clientToken ? _self.clientToken : clientToken // ignore: cast_nullable_to_non_nullable
as String,replyToMessageId: freezed == replyToMessageId ? _self.replyToMessageId : replyToMessageId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
