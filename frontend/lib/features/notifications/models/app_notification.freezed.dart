// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppNotification {

 int get id;/// The stable dotted string the server publishes — `order.shortage`, `announcement.manual`.
/// Read it, never branch on it to build the UI. See the class docblock.
 String get type;/// What this kind is called, for a screen that groups or filters. Server-supplied, so a new
/// type is legible without an app release.
@JsonKey(name: 'type_label') String get typeLabel; String get title; String get body;/// A key from the server's small, stable vocabulary — `warning`, `announcement`, … — and
/// **not** an icon name from any particular toolkit. An unrecognised key is a newer backend,
/// not an error: the tile falls back to a plain bell and still draws.
 String get icon;/// Where tapping goes, and **nullable by design**. An announcement («اجتماع الساعة ٤») has
/// nothing to open, and that is the common case rather than an edge one — see
/// [opensSomewhere].
 String? get route;/// What the notification is about, when it is about anything. Both null together.
@JsonKey(name: 'subject_type') String? get subjectType;@JsonKey(name: 'subject_id') int? get subjectId;@JsonKey(name: 'is_read') bool get isRead;/// When this account read it — null while unread. Separate from [isRead] because the server
/// publishes both, and a list that sorts or groups by "read this morning" needs the instant.
@JsonKey(name: 'read_at') DateTime? get readAt;@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppNotificationCopyWith<AppNotification> get copyWith => _$AppNotificationCopyWithImpl<AppNotification>(this as AppNotification, _$identity);

  /// Serializes this AppNotification to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.typeLabel, typeLabel) || other.typeLabel == typeLabel)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.route, route) || other.route == route)&&(identical(other.subjectType, subjectType) || other.subjectType == subjectType)&&(identical(other.subjectId, subjectId) || other.subjectId == subjectId)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,typeLabel,title,body,icon,route,subjectType,subjectId,isRead,readAt,createdAt);

@override
String toString() {
  return 'AppNotification(id: $id, type: $type, typeLabel: $typeLabel, title: $title, body: $body, icon: $icon, route: $route, subjectType: $subjectType, subjectId: $subjectId, isRead: $isRead, readAt: $readAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $AppNotificationCopyWith<$Res>  {
  factory $AppNotificationCopyWith(AppNotification value, $Res Function(AppNotification) _then) = _$AppNotificationCopyWithImpl;
@useResult
$Res call({
 int id, String type,@JsonKey(name: 'type_label') String typeLabel, String title, String body, String icon, String? route,@JsonKey(name: 'subject_type') String? subjectType,@JsonKey(name: 'subject_id') int? subjectId,@JsonKey(name: 'is_read') bool isRead,@JsonKey(name: 'read_at') DateTime? readAt,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$AppNotificationCopyWithImpl<$Res>
    implements $AppNotificationCopyWith<$Res> {
  _$AppNotificationCopyWithImpl(this._self, this._then);

  final AppNotification _self;
  final $Res Function(AppNotification) _then;

/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? typeLabel = null,Object? title = null,Object? body = null,Object? icon = null,Object? route = freezed,Object? subjectType = freezed,Object? subjectId = freezed,Object? isRead = null,Object? readAt = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,typeLabel: null == typeLabel ? _self.typeLabel : typeLabel // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,route: freezed == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String?,subjectType: freezed == subjectType ? _self.subjectType : subjectType // ignore: cast_nullable_to_non_nullable
as String?,subjectId: freezed == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as int?,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AppNotification].
extension AppNotificationPatterns on AppNotification {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppNotification value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppNotification value)  $default,){
final _that = this;
switch (_that) {
case _AppNotification():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppNotification value)?  $default,){
final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String type, @JsonKey(name: 'type_label')  String typeLabel,  String title,  String body,  String icon,  String? route, @JsonKey(name: 'subject_type')  String? subjectType, @JsonKey(name: 'subject_id')  int? subjectId, @JsonKey(name: 'is_read')  bool isRead, @JsonKey(name: 'read_at')  DateTime? readAt, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
return $default(_that.id,_that.type,_that.typeLabel,_that.title,_that.body,_that.icon,_that.route,_that.subjectType,_that.subjectId,_that.isRead,_that.readAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String type, @JsonKey(name: 'type_label')  String typeLabel,  String title,  String body,  String icon,  String? route, @JsonKey(name: 'subject_type')  String? subjectType, @JsonKey(name: 'subject_id')  int? subjectId, @JsonKey(name: 'is_read')  bool isRead, @JsonKey(name: 'read_at')  DateTime? readAt, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _AppNotification():
return $default(_that.id,_that.type,_that.typeLabel,_that.title,_that.body,_that.icon,_that.route,_that.subjectType,_that.subjectId,_that.isRead,_that.readAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String type, @JsonKey(name: 'type_label')  String typeLabel,  String title,  String body,  String icon,  String? route, @JsonKey(name: 'subject_type')  String? subjectType, @JsonKey(name: 'subject_id')  int? subjectId, @JsonKey(name: 'is_read')  bool isRead, @JsonKey(name: 'read_at')  DateTime? readAt, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
return $default(_that.id,_that.type,_that.typeLabel,_that.title,_that.body,_that.icon,_that.route,_that.subjectType,_that.subjectId,_that.isRead,_that.readAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppNotification extends AppNotification {
  const _AppNotification({required this.id, required this.type, @JsonKey(name: 'type_label') required this.typeLabel, required this.title, required this.body, required this.icon, this.route, @JsonKey(name: 'subject_type') this.subjectType, @JsonKey(name: 'subject_id') this.subjectId, @JsonKey(name: 'is_read') required this.isRead, @JsonKey(name: 'read_at') this.readAt, @JsonKey(name: 'created_at') required this.createdAt}): super._();
  factory _AppNotification.fromJson(Map<String, dynamic> json) => _$AppNotificationFromJson(json);

@override final  int id;
/// The stable dotted string the server publishes — `order.shortage`, `announcement.manual`.
/// Read it, never branch on it to build the UI. See the class docblock.
@override final  String type;
/// What this kind is called, for a screen that groups or filters. Server-supplied, so a new
/// type is legible without an app release.
@override@JsonKey(name: 'type_label') final  String typeLabel;
@override final  String title;
@override final  String body;
/// A key from the server's small, stable vocabulary — `warning`, `announcement`, … — and
/// **not** an icon name from any particular toolkit. An unrecognised key is a newer backend,
/// not an error: the tile falls back to a plain bell and still draws.
@override final  String icon;
/// Where tapping goes, and **nullable by design**. An announcement («اجتماع الساعة ٤») has
/// nothing to open, and that is the common case rather than an edge one — see
/// [opensSomewhere].
@override final  String? route;
/// What the notification is about, when it is about anything. Both null together.
@override@JsonKey(name: 'subject_type') final  String? subjectType;
@override@JsonKey(name: 'subject_id') final  int? subjectId;
@override@JsonKey(name: 'is_read') final  bool isRead;
/// When this account read it — null while unread. Separate from [isRead] because the server
/// publishes both, and a list that sorts or groups by "read this morning" needs the instant.
@override@JsonKey(name: 'read_at') final  DateTime? readAt;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppNotificationCopyWith<_AppNotification> get copyWith => __$AppNotificationCopyWithImpl<_AppNotification>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppNotificationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.typeLabel, typeLabel) || other.typeLabel == typeLabel)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.route, route) || other.route == route)&&(identical(other.subjectType, subjectType) || other.subjectType == subjectType)&&(identical(other.subjectId, subjectId) || other.subjectId == subjectId)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,typeLabel,title,body,icon,route,subjectType,subjectId,isRead,readAt,createdAt);

@override
String toString() {
  return 'AppNotification(id: $id, type: $type, typeLabel: $typeLabel, title: $title, body: $body, icon: $icon, route: $route, subjectType: $subjectType, subjectId: $subjectId, isRead: $isRead, readAt: $readAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AppNotificationCopyWith<$Res> implements $AppNotificationCopyWith<$Res> {
  factory _$AppNotificationCopyWith(_AppNotification value, $Res Function(_AppNotification) _then) = __$AppNotificationCopyWithImpl;
@override @useResult
$Res call({
 int id, String type,@JsonKey(name: 'type_label') String typeLabel, String title, String body, String icon, String? route,@JsonKey(name: 'subject_type') String? subjectType,@JsonKey(name: 'subject_id') int? subjectId,@JsonKey(name: 'is_read') bool isRead,@JsonKey(name: 'read_at') DateTime? readAt,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$AppNotificationCopyWithImpl<$Res>
    implements _$AppNotificationCopyWith<$Res> {
  __$AppNotificationCopyWithImpl(this._self, this._then);

  final _AppNotification _self;
  final $Res Function(_AppNotification) _then;

/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? typeLabel = null,Object? title = null,Object? body = null,Object? icon = null,Object? route = freezed,Object? subjectType = freezed,Object? subjectId = freezed,Object? isRead = null,Object? readAt = freezed,Object? createdAt = null,}) {
  return _then(_AppNotification(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,typeLabel: null == typeLabel ? _self.typeLabel : typeLabel // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,route: freezed == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String?,subjectType: freezed == subjectType ? _self.subjectType : subjectType // ignore: cast_nullable_to_non_nullable
as String?,subjectId: freezed == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as int?,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
