// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'push_preference.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PushPreferenceGroup {

 String get type; String get label; String get icon; List<PushSwitch> get switches;
/// Create a copy of PushPreferenceGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PushPreferenceGroupCopyWith<PushPreferenceGroup> get copyWith => _$PushPreferenceGroupCopyWithImpl<PushPreferenceGroup>(this as PushPreferenceGroup, _$identity);

  /// Serializes this PushPreferenceGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PushPreferenceGroup&&(identical(other.type, type) || other.type == type)&&(identical(other.label, label) || other.label == label)&&(identical(other.icon, icon) || other.icon == icon)&&const DeepCollectionEquality().equals(other.switches, switches));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,label,icon,const DeepCollectionEquality().hash(switches));

@override
String toString() {
  return 'PushPreferenceGroup(type: $type, label: $label, icon: $icon, switches: $switches)';
}


}

/// @nodoc
abstract mixin class $PushPreferenceGroupCopyWith<$Res>  {
  factory $PushPreferenceGroupCopyWith(PushPreferenceGroup value, $Res Function(PushPreferenceGroup) _then) = _$PushPreferenceGroupCopyWithImpl;
@useResult
$Res call({
 String type, String label, String icon, List<PushSwitch> switches
});




}
/// @nodoc
class _$PushPreferenceGroupCopyWithImpl<$Res>
    implements $PushPreferenceGroupCopyWith<$Res> {
  _$PushPreferenceGroupCopyWithImpl(this._self, this._then);

  final PushPreferenceGroup _self;
  final $Res Function(PushPreferenceGroup) _then;

/// Create a copy of PushPreferenceGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? label = null,Object? icon = null,Object? switches = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,switches: null == switches ? _self.switches : switches // ignore: cast_nullable_to_non_nullable
as List<PushSwitch>,
  ));
}

}


/// Adds pattern-matching-related methods to [PushPreferenceGroup].
extension PushPreferenceGroupPatterns on PushPreferenceGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PushPreferenceGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PushPreferenceGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PushPreferenceGroup value)  $default,){
final _that = this;
switch (_that) {
case _PushPreferenceGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PushPreferenceGroup value)?  $default,){
final _that = this;
switch (_that) {
case _PushPreferenceGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String label,  String icon,  List<PushSwitch> switches)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PushPreferenceGroup() when $default != null:
return $default(_that.type,_that.label,_that.icon,_that.switches);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String label,  String icon,  List<PushSwitch> switches)  $default,) {final _that = this;
switch (_that) {
case _PushPreferenceGroup():
return $default(_that.type,_that.label,_that.icon,_that.switches);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String label,  String icon,  List<PushSwitch> switches)?  $default,) {final _that = this;
switch (_that) {
case _PushPreferenceGroup() when $default != null:
return $default(_that.type,_that.label,_that.icon,_that.switches);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PushPreferenceGroup extends PushPreferenceGroup {
  const _PushPreferenceGroup({required this.type, required this.label, required this.icon, required final  List<PushSwitch> switches}): _switches = switches,super._();
  factory _PushPreferenceGroup.fromJson(Map<String, dynamic> json) => _$PushPreferenceGroupFromJson(json);

@override final  String type;
@override final  String label;
@override final  String icon;
 final  List<PushSwitch> _switches;
@override List<PushSwitch> get switches {
  if (_switches is EqualUnmodifiableListView) return _switches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_switches);
}


/// Create a copy of PushPreferenceGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PushPreferenceGroupCopyWith<_PushPreferenceGroup> get copyWith => __$PushPreferenceGroupCopyWithImpl<_PushPreferenceGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PushPreferenceGroupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PushPreferenceGroup&&(identical(other.type, type) || other.type == type)&&(identical(other.label, label) || other.label == label)&&(identical(other.icon, icon) || other.icon == icon)&&const DeepCollectionEquality().equals(other._switches, _switches));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,label,icon,const DeepCollectionEquality().hash(_switches));

@override
String toString() {
  return 'PushPreferenceGroup(type: $type, label: $label, icon: $icon, switches: $switches)';
}


}

/// @nodoc
abstract mixin class _$PushPreferenceGroupCopyWith<$Res> implements $PushPreferenceGroupCopyWith<$Res> {
  factory _$PushPreferenceGroupCopyWith(_PushPreferenceGroup value, $Res Function(_PushPreferenceGroup) _then) = __$PushPreferenceGroupCopyWithImpl;
@override @useResult
$Res call({
 String type, String label, String icon, List<PushSwitch> switches
});




}
/// @nodoc
class __$PushPreferenceGroupCopyWithImpl<$Res>
    implements _$PushPreferenceGroupCopyWith<$Res> {
  __$PushPreferenceGroupCopyWithImpl(this._self, this._then);

  final _PushPreferenceGroup _self;
  final $Res Function(_PushPreferenceGroup) _then;

/// Create a copy of PushPreferenceGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? label = null,Object? icon = null,Object? switches = null,}) {
  return _then(_PushPreferenceGroup(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,switches: null == switches ? _self._switches : switches // ignore: cast_nullable_to_non_nullable
as List<PushSwitch>,
  ));
}


}


/// @nodoc
mixin _$PushSwitch {

 String get scope; String get label; bool get push;
/// Create a copy of PushSwitch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PushSwitchCopyWith<PushSwitch> get copyWith => _$PushSwitchCopyWithImpl<PushSwitch>(this as PushSwitch, _$identity);

  /// Serializes this PushSwitch to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PushSwitch&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.label, label) || other.label == label)&&(identical(other.push, push) || other.push == push));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,scope,label,push);

@override
String toString() {
  return 'PushSwitch(scope: $scope, label: $label, push: $push)';
}


}

/// @nodoc
abstract mixin class $PushSwitchCopyWith<$Res>  {
  factory $PushSwitchCopyWith(PushSwitch value, $Res Function(PushSwitch) _then) = _$PushSwitchCopyWithImpl;
@useResult
$Res call({
 String scope, String label, bool push
});




}
/// @nodoc
class _$PushSwitchCopyWithImpl<$Res>
    implements $PushSwitchCopyWith<$Res> {
  _$PushSwitchCopyWithImpl(this._self, this._then);

  final PushSwitch _self;
  final $Res Function(PushSwitch) _then;

/// Create a copy of PushSwitch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? scope = null,Object? label = null,Object? push = null,}) {
  return _then(_self.copyWith(
scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,push: null == push ? _self.push : push // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PushSwitch].
extension PushSwitchPatterns on PushSwitch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PushSwitch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PushSwitch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PushSwitch value)  $default,){
final _that = this;
switch (_that) {
case _PushSwitch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PushSwitch value)?  $default,){
final _that = this;
switch (_that) {
case _PushSwitch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String scope,  String label,  bool push)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PushSwitch() when $default != null:
return $default(_that.scope,_that.label,_that.push);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String scope,  String label,  bool push)  $default,) {final _that = this;
switch (_that) {
case _PushSwitch():
return $default(_that.scope,_that.label,_that.push);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String scope,  String label,  bool push)?  $default,) {final _that = this;
switch (_that) {
case _PushSwitch() when $default != null:
return $default(_that.scope,_that.label,_that.push);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PushSwitch implements PushSwitch {
  const _PushSwitch({required this.scope, required this.label, required this.push});
  factory _PushSwitch.fromJson(Map<String, dynamic> json) => _$PushSwitchFromJson(json);

@override final  String scope;
@override final  String label;
@override final  bool push;

/// Create a copy of PushSwitch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PushSwitchCopyWith<_PushSwitch> get copyWith => __$PushSwitchCopyWithImpl<_PushSwitch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PushSwitchToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PushSwitch&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.label, label) || other.label == label)&&(identical(other.push, push) || other.push == push));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,scope,label,push);

@override
String toString() {
  return 'PushSwitch(scope: $scope, label: $label, push: $push)';
}


}

/// @nodoc
abstract mixin class _$PushSwitchCopyWith<$Res> implements $PushSwitchCopyWith<$Res> {
  factory _$PushSwitchCopyWith(_PushSwitch value, $Res Function(_PushSwitch) _then) = __$PushSwitchCopyWithImpl;
@override @useResult
$Res call({
 String scope, String label, bool push
});




}
/// @nodoc
class __$PushSwitchCopyWithImpl<$Res>
    implements _$PushSwitchCopyWith<$Res> {
  __$PushSwitchCopyWithImpl(this._self, this._then);

  final _PushSwitch _self;
  final $Res Function(_PushSwitch) _then;

/// Create a copy of PushSwitch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? scope = null,Object? label = null,Object? push = null,}) {
  return _then(_PushSwitch(
scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,push: null == push ? _self.push : push // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
