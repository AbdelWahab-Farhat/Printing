// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'activity_log_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ActivityLogEntry {

 int get id;/// `created`, `updated`, `deleted` … with the Arabic beside it, so the app keeps no
/// translation table in step with the server's.
 String get event;@JsonKey(name: 'event_label') String? get eventLabel;/// The sentence written when it happened — not one composed now. History that rewords
/// itself when the code changes is not history.
 String? get description;/// A stable alias like `customer_shop`, never a PHP class name.
@JsonKey(name: 'subject_type') String? get subjectType;@JsonKey(name: 'subject_type_label') String? get subjectTypeLabel;@JsonKey(name: 'subject_id') int? get subjectId;/// Absent for anything no person did — a seeder, a console command, a queued job.
 AuditCauser? get causer; AuditChanges? get changes;/// What to call each column that moved — `page_url` → «رابط الصفحة».
///
/// **Sent by the server, never kept here.** The screen used to show raw column names, and
/// the alternative to this was a dictionary in the app — which is wrong the first morning
/// somebody adds a column, with no build failing to say so. Carrying only the columns this
/// entry touched keeps a page of fifteen entries small.
@JsonKey(name: 'attribute_labels') Map<String, String>? get attributeLabels;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of ActivityLogEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityLogEntryCopyWith<ActivityLogEntry> get copyWith => _$ActivityLogEntryCopyWithImpl<ActivityLogEntry>(this as ActivityLogEntry, _$identity);

  /// Serializes this ActivityLogEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivityLogEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.event, event) || other.event == event)&&(identical(other.eventLabel, eventLabel) || other.eventLabel == eventLabel)&&(identical(other.description, description) || other.description == description)&&(identical(other.subjectType, subjectType) || other.subjectType == subjectType)&&(identical(other.subjectTypeLabel, subjectTypeLabel) || other.subjectTypeLabel == subjectTypeLabel)&&(identical(other.subjectId, subjectId) || other.subjectId == subjectId)&&(identical(other.causer, causer) || other.causer == causer)&&(identical(other.changes, changes) || other.changes == changes)&&const DeepCollectionEquality().equals(other.attributeLabels, attributeLabels)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,event,eventLabel,description,subjectType,subjectTypeLabel,subjectId,causer,changes,const DeepCollectionEquality().hash(attributeLabels),createdAt);

@override
String toString() {
  return 'ActivityLogEntry(id: $id, event: $event, eventLabel: $eventLabel, description: $description, subjectType: $subjectType, subjectTypeLabel: $subjectTypeLabel, subjectId: $subjectId, causer: $causer, changes: $changes, attributeLabels: $attributeLabels, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ActivityLogEntryCopyWith<$Res>  {
  factory $ActivityLogEntryCopyWith(ActivityLogEntry value, $Res Function(ActivityLogEntry) _then) = _$ActivityLogEntryCopyWithImpl;
@useResult
$Res call({
 int id, String event,@JsonKey(name: 'event_label') String? eventLabel, String? description,@JsonKey(name: 'subject_type') String? subjectType,@JsonKey(name: 'subject_type_label') String? subjectTypeLabel,@JsonKey(name: 'subject_id') int? subjectId, AuditCauser? causer, AuditChanges? changes,@JsonKey(name: 'attribute_labels') Map<String, String>? attributeLabels,@JsonKey(name: 'created_at') DateTime? createdAt
});


$AuditCauserCopyWith<$Res>? get causer;$AuditChangesCopyWith<$Res>? get changes;

}
/// @nodoc
class _$ActivityLogEntryCopyWithImpl<$Res>
    implements $ActivityLogEntryCopyWith<$Res> {
  _$ActivityLogEntryCopyWithImpl(this._self, this._then);

  final ActivityLogEntry _self;
  final $Res Function(ActivityLogEntry) _then;

/// Create a copy of ActivityLogEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? event = null,Object? eventLabel = freezed,Object? description = freezed,Object? subjectType = freezed,Object? subjectTypeLabel = freezed,Object? subjectId = freezed,Object? causer = freezed,Object? changes = freezed,Object? attributeLabels = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,event: null == event ? _self.event : event // ignore: cast_nullable_to_non_nullable
as String,eventLabel: freezed == eventLabel ? _self.eventLabel : eventLabel // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,subjectType: freezed == subjectType ? _self.subjectType : subjectType // ignore: cast_nullable_to_non_nullable
as String?,subjectTypeLabel: freezed == subjectTypeLabel ? _self.subjectTypeLabel : subjectTypeLabel // ignore: cast_nullable_to_non_nullable
as String?,subjectId: freezed == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as int?,causer: freezed == causer ? _self.causer : causer // ignore: cast_nullable_to_non_nullable
as AuditCauser?,changes: freezed == changes ? _self.changes : changes // ignore: cast_nullable_to_non_nullable
as AuditChanges?,attributeLabels: freezed == attributeLabels ? _self.attributeLabels : attributeLabels // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of ActivityLogEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuditCauserCopyWith<$Res>? get causer {
    if (_self.causer == null) {
    return null;
  }

  return $AuditCauserCopyWith<$Res>(_self.causer!, (value) {
    return _then(_self.copyWith(causer: value));
  });
}/// Create a copy of ActivityLogEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuditChangesCopyWith<$Res>? get changes {
    if (_self.changes == null) {
    return null;
  }

  return $AuditChangesCopyWith<$Res>(_self.changes!, (value) {
    return _then(_self.copyWith(changes: value));
  });
}
}


/// Adds pattern-matching-related methods to [ActivityLogEntry].
extension ActivityLogEntryPatterns on ActivityLogEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivityLogEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivityLogEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivityLogEntry value)  $default,){
final _that = this;
switch (_that) {
case _ActivityLogEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivityLogEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ActivityLogEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String event, @JsonKey(name: 'event_label')  String? eventLabel,  String? description, @JsonKey(name: 'subject_type')  String? subjectType, @JsonKey(name: 'subject_type_label')  String? subjectTypeLabel, @JsonKey(name: 'subject_id')  int? subjectId,  AuditCauser? causer,  AuditChanges? changes, @JsonKey(name: 'attribute_labels')  Map<String, String>? attributeLabels, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivityLogEntry() when $default != null:
return $default(_that.id,_that.event,_that.eventLabel,_that.description,_that.subjectType,_that.subjectTypeLabel,_that.subjectId,_that.causer,_that.changes,_that.attributeLabels,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String event, @JsonKey(name: 'event_label')  String? eventLabel,  String? description, @JsonKey(name: 'subject_type')  String? subjectType, @JsonKey(name: 'subject_type_label')  String? subjectTypeLabel, @JsonKey(name: 'subject_id')  int? subjectId,  AuditCauser? causer,  AuditChanges? changes, @JsonKey(name: 'attribute_labels')  Map<String, String>? attributeLabels, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _ActivityLogEntry():
return $default(_that.id,_that.event,_that.eventLabel,_that.description,_that.subjectType,_that.subjectTypeLabel,_that.subjectId,_that.causer,_that.changes,_that.attributeLabels,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String event, @JsonKey(name: 'event_label')  String? eventLabel,  String? description, @JsonKey(name: 'subject_type')  String? subjectType, @JsonKey(name: 'subject_type_label')  String? subjectTypeLabel, @JsonKey(name: 'subject_id')  int? subjectId,  AuditCauser? causer,  AuditChanges? changes, @JsonKey(name: 'attribute_labels')  Map<String, String>? attributeLabels, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ActivityLogEntry() when $default != null:
return $default(_that.id,_that.event,_that.eventLabel,_that.description,_that.subjectType,_that.subjectTypeLabel,_that.subjectId,_that.causer,_that.changes,_that.attributeLabels,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActivityLogEntry extends ActivityLogEntry {
  const _ActivityLogEntry({required this.id, required this.event, @JsonKey(name: 'event_label') this.eventLabel, this.description, @JsonKey(name: 'subject_type') this.subjectType, @JsonKey(name: 'subject_type_label') this.subjectTypeLabel, @JsonKey(name: 'subject_id') this.subjectId, this.causer, this.changes, @JsonKey(name: 'attribute_labels') final  Map<String, String>? attributeLabels, @JsonKey(name: 'created_at') this.createdAt}): _attributeLabels = attributeLabels,super._();
  factory _ActivityLogEntry.fromJson(Map<String, dynamic> json) => _$ActivityLogEntryFromJson(json);

@override final  int id;
/// `created`, `updated`, `deleted` … with the Arabic beside it, so the app keeps no
/// translation table in step with the server's.
@override final  String event;
@override@JsonKey(name: 'event_label') final  String? eventLabel;
/// The sentence written when it happened — not one composed now. History that rewords
/// itself when the code changes is not history.
@override final  String? description;
/// A stable alias like `customer_shop`, never a PHP class name.
@override@JsonKey(name: 'subject_type') final  String? subjectType;
@override@JsonKey(name: 'subject_type_label') final  String? subjectTypeLabel;
@override@JsonKey(name: 'subject_id') final  int? subjectId;
/// Absent for anything no person did — a seeder, a console command, a queued job.
@override final  AuditCauser? causer;
@override final  AuditChanges? changes;
/// What to call each column that moved — `page_url` → «رابط الصفحة».
///
/// **Sent by the server, never kept here.** The screen used to show raw column names, and
/// the alternative to this was a dictionary in the app — which is wrong the first morning
/// somebody adds a column, with no build failing to say so. Carrying only the columns this
/// entry touched keeps a page of fifteen entries small.
 final  Map<String, String>? _attributeLabels;
/// What to call each column that moved — `page_url` → «رابط الصفحة».
///
/// **Sent by the server, never kept here.** The screen used to show raw column names, and
/// the alternative to this was a dictionary in the app — which is wrong the first morning
/// somebody adds a column, with no build failing to say so. Carrying only the columns this
/// entry touched keeps a page of fifteen entries small.
@override@JsonKey(name: 'attribute_labels') Map<String, String>? get attributeLabels {
  final value = _attributeLabels;
  if (value == null) return null;
  if (_attributeLabels is EqualUnmodifiableMapView) return _attributeLabels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of ActivityLogEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivityLogEntryCopyWith<_ActivityLogEntry> get copyWith => __$ActivityLogEntryCopyWithImpl<_ActivityLogEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActivityLogEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivityLogEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.event, event) || other.event == event)&&(identical(other.eventLabel, eventLabel) || other.eventLabel == eventLabel)&&(identical(other.description, description) || other.description == description)&&(identical(other.subjectType, subjectType) || other.subjectType == subjectType)&&(identical(other.subjectTypeLabel, subjectTypeLabel) || other.subjectTypeLabel == subjectTypeLabel)&&(identical(other.subjectId, subjectId) || other.subjectId == subjectId)&&(identical(other.causer, causer) || other.causer == causer)&&(identical(other.changes, changes) || other.changes == changes)&&const DeepCollectionEquality().equals(other._attributeLabels, _attributeLabels)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,event,eventLabel,description,subjectType,subjectTypeLabel,subjectId,causer,changes,const DeepCollectionEquality().hash(_attributeLabels),createdAt);

@override
String toString() {
  return 'ActivityLogEntry(id: $id, event: $event, eventLabel: $eventLabel, description: $description, subjectType: $subjectType, subjectTypeLabel: $subjectTypeLabel, subjectId: $subjectId, causer: $causer, changes: $changes, attributeLabels: $attributeLabels, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ActivityLogEntryCopyWith<$Res> implements $ActivityLogEntryCopyWith<$Res> {
  factory _$ActivityLogEntryCopyWith(_ActivityLogEntry value, $Res Function(_ActivityLogEntry) _then) = __$ActivityLogEntryCopyWithImpl;
@override @useResult
$Res call({
 int id, String event,@JsonKey(name: 'event_label') String? eventLabel, String? description,@JsonKey(name: 'subject_type') String? subjectType,@JsonKey(name: 'subject_type_label') String? subjectTypeLabel,@JsonKey(name: 'subject_id') int? subjectId, AuditCauser? causer, AuditChanges? changes,@JsonKey(name: 'attribute_labels') Map<String, String>? attributeLabels,@JsonKey(name: 'created_at') DateTime? createdAt
});


@override $AuditCauserCopyWith<$Res>? get causer;@override $AuditChangesCopyWith<$Res>? get changes;

}
/// @nodoc
class __$ActivityLogEntryCopyWithImpl<$Res>
    implements _$ActivityLogEntryCopyWith<$Res> {
  __$ActivityLogEntryCopyWithImpl(this._self, this._then);

  final _ActivityLogEntry _self;
  final $Res Function(_ActivityLogEntry) _then;

/// Create a copy of ActivityLogEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? event = null,Object? eventLabel = freezed,Object? description = freezed,Object? subjectType = freezed,Object? subjectTypeLabel = freezed,Object? subjectId = freezed,Object? causer = freezed,Object? changes = freezed,Object? attributeLabels = freezed,Object? createdAt = freezed,}) {
  return _then(_ActivityLogEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,event: null == event ? _self.event : event // ignore: cast_nullable_to_non_nullable
as String,eventLabel: freezed == eventLabel ? _self.eventLabel : eventLabel // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,subjectType: freezed == subjectType ? _self.subjectType : subjectType // ignore: cast_nullable_to_non_nullable
as String?,subjectTypeLabel: freezed == subjectTypeLabel ? _self.subjectTypeLabel : subjectTypeLabel // ignore: cast_nullable_to_non_nullable
as String?,subjectId: freezed == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as int?,causer: freezed == causer ? _self.causer : causer // ignore: cast_nullable_to_non_nullable
as AuditCauser?,changes: freezed == changes ? _self.changes : changes // ignore: cast_nullable_to_non_nullable
as AuditChanges?,attributeLabels: freezed == attributeLabels ? _self._attributeLabels : attributeLabels // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of ActivityLogEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuditCauserCopyWith<$Res>? get causer {
    if (_self.causer == null) {
    return null;
  }

  return $AuditCauserCopyWith<$Res>(_self.causer!, (value) {
    return _then(_self.copyWith(causer: value));
  });
}/// Create a copy of ActivityLogEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuditChangesCopyWith<$Res>? get changes {
    if (_self.changes == null) {
    return null;
  }

  return $AuditChangesCopyWith<$Res>(_self.changes!, (value) {
    return _then(_self.copyWith(changes: value));
  });
}
}


/// @nodoc
mixin _$AuditCauser {

 int? get id; String get name;@JsonKey(name: 'employee_code') String? get employeeCode;
/// Create a copy of AuditCauser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuditCauserCopyWith<AuditCauser> get copyWith => _$AuditCauserCopyWithImpl<AuditCauser>(this as AuditCauser, _$identity);

  /// Serializes this AuditCauser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuditCauser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.employeeCode, employeeCode) || other.employeeCode == employeeCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,employeeCode);

@override
String toString() {
  return 'AuditCauser(id: $id, name: $name, employeeCode: $employeeCode)';
}


}

/// @nodoc
abstract mixin class $AuditCauserCopyWith<$Res>  {
  factory $AuditCauserCopyWith(AuditCauser value, $Res Function(AuditCauser) _then) = _$AuditCauserCopyWithImpl;
@useResult
$Res call({
 int? id, String name,@JsonKey(name: 'employee_code') String? employeeCode
});




}
/// @nodoc
class _$AuditCauserCopyWithImpl<$Res>
    implements $AuditCauserCopyWith<$Res> {
  _$AuditCauserCopyWithImpl(this._self, this._then);

  final AuditCauser _self;
  final $Res Function(AuditCauser) _then;

/// Create a copy of AuditCauser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = null,Object? employeeCode = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,employeeCode: freezed == employeeCode ? _self.employeeCode : employeeCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuditCauser].
extension AuditCauserPatterns on AuditCauser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuditCauser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuditCauser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuditCauser value)  $default,){
final _that = this;
switch (_that) {
case _AuditCauser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuditCauser value)?  $default,){
final _that = this;
switch (_that) {
case _AuditCauser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String name, @JsonKey(name: 'employee_code')  String? employeeCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuditCauser() when $default != null:
return $default(_that.id,_that.name,_that.employeeCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String name, @JsonKey(name: 'employee_code')  String? employeeCode)  $default,) {final _that = this;
switch (_that) {
case _AuditCauser():
return $default(_that.id,_that.name,_that.employeeCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String name, @JsonKey(name: 'employee_code')  String? employeeCode)?  $default,) {final _that = this;
switch (_that) {
case _AuditCauser() when $default != null:
return $default(_that.id,_that.name,_that.employeeCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuditCauser implements AuditCauser {
  const _AuditCauser({this.id, required this.name, @JsonKey(name: 'employee_code') this.employeeCode});
  factory _AuditCauser.fromJson(Map<String, dynamic> json) => _$AuditCauserFromJson(json);

@override final  int? id;
@override final  String name;
@override@JsonKey(name: 'employee_code') final  String? employeeCode;

/// Create a copy of AuditCauser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuditCauserCopyWith<_AuditCauser> get copyWith => __$AuditCauserCopyWithImpl<_AuditCauser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuditCauserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuditCauser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.employeeCode, employeeCode) || other.employeeCode == employeeCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,employeeCode);

@override
String toString() {
  return 'AuditCauser(id: $id, name: $name, employeeCode: $employeeCode)';
}


}

/// @nodoc
abstract mixin class _$AuditCauserCopyWith<$Res> implements $AuditCauserCopyWith<$Res> {
  factory _$AuditCauserCopyWith(_AuditCauser value, $Res Function(_AuditCauser) _then) = __$AuditCauserCopyWithImpl;
@override @useResult
$Res call({
 int? id, String name,@JsonKey(name: 'employee_code') String? employeeCode
});




}
/// @nodoc
class __$AuditCauserCopyWithImpl<$Res>
    implements _$AuditCauserCopyWith<$Res> {
  __$AuditCauserCopyWithImpl(this._self, this._then);

  final _AuditCauser _self;
  final $Res Function(_AuditCauser) _then;

/// Create a copy of AuditCauser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = null,Object? employeeCode = freezed,}) {
  return _then(_AuditCauser(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,employeeCode: freezed == employeeCode ? _self.employeeCode : employeeCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AuditChanges {

 Map<String, dynamic>? get old; Map<String, dynamic>? get attributes;
/// Create a copy of AuditChanges
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuditChangesCopyWith<AuditChanges> get copyWith => _$AuditChangesCopyWithImpl<AuditChanges>(this as AuditChanges, _$identity);

  /// Serializes this AuditChanges to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuditChanges&&const DeepCollectionEquality().equals(other.old, old)&&const DeepCollectionEquality().equals(other.attributes, attributes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(old),const DeepCollectionEquality().hash(attributes));

@override
String toString() {
  return 'AuditChanges(old: $old, attributes: $attributes)';
}


}

/// @nodoc
abstract mixin class $AuditChangesCopyWith<$Res>  {
  factory $AuditChangesCopyWith(AuditChanges value, $Res Function(AuditChanges) _then) = _$AuditChangesCopyWithImpl;
@useResult
$Res call({
 Map<String, dynamic>? old, Map<String, dynamic>? attributes
});




}
/// @nodoc
class _$AuditChangesCopyWithImpl<$Res>
    implements $AuditChangesCopyWith<$Res> {
  _$AuditChangesCopyWithImpl(this._self, this._then);

  final AuditChanges _self;
  final $Res Function(AuditChanges) _then;

/// Create a copy of AuditChanges
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? old = freezed,Object? attributes = freezed,}) {
  return _then(_self.copyWith(
old: freezed == old ? _self.old : old // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,attributes: freezed == attributes ? _self.attributes : attributes // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuditChanges].
extension AuditChangesPatterns on AuditChanges {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuditChanges value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuditChanges() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuditChanges value)  $default,){
final _that = this;
switch (_that) {
case _AuditChanges():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuditChanges value)?  $default,){
final _that = this;
switch (_that) {
case _AuditChanges() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, dynamic>? old,  Map<String, dynamic>? attributes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuditChanges() when $default != null:
return $default(_that.old,_that.attributes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, dynamic>? old,  Map<String, dynamic>? attributes)  $default,) {final _that = this;
switch (_that) {
case _AuditChanges():
return $default(_that.old,_that.attributes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, dynamic>? old,  Map<String, dynamic>? attributes)?  $default,) {final _that = this;
switch (_that) {
case _AuditChanges() when $default != null:
return $default(_that.old,_that.attributes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuditChanges extends AuditChanges {
  const _AuditChanges({final  Map<String, dynamic>? old, final  Map<String, dynamic>? attributes}): _old = old,_attributes = attributes,super._();
  factory _AuditChanges.fromJson(Map<String, dynamic> json) => _$AuditChangesFromJson(json);

 final  Map<String, dynamic>? _old;
@override Map<String, dynamic>? get old {
  final value = _old;
  if (value == null) return null;
  if (_old is EqualUnmodifiableMapView) return _old;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _attributes;
@override Map<String, dynamic>? get attributes {
  final value = _attributes;
  if (value == null) return null;
  if (_attributes is EqualUnmodifiableMapView) return _attributes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of AuditChanges
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuditChangesCopyWith<_AuditChanges> get copyWith => __$AuditChangesCopyWithImpl<_AuditChanges>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuditChangesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuditChanges&&const DeepCollectionEquality().equals(other._old, _old)&&const DeepCollectionEquality().equals(other._attributes, _attributes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_old),const DeepCollectionEquality().hash(_attributes));

@override
String toString() {
  return 'AuditChanges(old: $old, attributes: $attributes)';
}


}

/// @nodoc
abstract mixin class _$AuditChangesCopyWith<$Res> implements $AuditChangesCopyWith<$Res> {
  factory _$AuditChangesCopyWith(_AuditChanges value, $Res Function(_AuditChanges) _then) = __$AuditChangesCopyWithImpl;
@override @useResult
$Res call({
 Map<String, dynamic>? old, Map<String, dynamic>? attributes
});




}
/// @nodoc
class __$AuditChangesCopyWithImpl<$Res>
    implements _$AuditChangesCopyWith<$Res> {
  __$AuditChangesCopyWithImpl(this._self, this._then);

  final _AuditChanges _self;
  final $Res Function(_AuditChanges) _then;

/// Create a copy of AuditChanges
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? old = freezed,Object? attributes = freezed,}) {
  return _then(_AuditChanges(
old: freezed == old ? _self._old : old // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,attributes: freezed == attributes ? _self._attributes : attributes // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
