// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'employee_wallet_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EmployeeWalletEntry {

 int get id;/// `deposit` · `credit` · `withdrawal` · `adjustment_credit` · `adjustment_debit` · `reversal`.
/// نوعٌ لا يعرفه هذا الإصدار يُرسم بـ[typeLabel] الخادم.
 String get type;@JsonKey(name: 'type_label') String get typeLabel;/// `in` يزيد المحفظة، و`out` ينقصها. **الخادم يقرّره**: العكسُ عكسُ ما يعكسه.
 String get direction;/// موجبٌ دائماً — الاتجاه في [direction].
 String get amount;/// غائبٌ عن سطر صاحب المحفظة: محفظتُه هو.
@JsonKey(name: 'user_id') int? get userId;/// يُرسل في «المعاملات المالية» وحدها، فهي تجمع الموظفين كلهم.
 EmployeeWalletPerson? get user;/// الإيداع والسحب وحدهما.
@JsonKey(name: 'method_label') String? get methodLabel;/// المستحق وحده.
@JsonKey(name: 'category_name', readValue: _categoryName) String? get categoryName; String? get notes;@JsonKey(name: 'occurred_at', fromJson: _localDate) DateTime? get occurredAt;/// عُكس — يُرسم مشطوباً.
@JsonKey(name: 'is_reversed') bool get isReversed;/// **الخادم وحده يقول إن كان يُعكس من هنا**: الصلاحية، وأنه ليس محفظة القارئ نفسه.
@JsonKey(name: 'can_reverse') bool get canReverse;/// سببُ العكس، تحت السطر المشطوب.
@JsonKey(name: 'reversal_reason', readValue: _reversalReason) String? get reversalReason;@JsonKey(name: 'recorder_name', readValue: _recorderName) String? get recorderName;
/// Create a copy of EmployeeWalletEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeWalletEntryCopyWith<EmployeeWalletEntry> get copyWith => _$EmployeeWalletEntryCopyWithImpl<EmployeeWalletEntry>(this as EmployeeWalletEntry, _$identity);

  /// Serializes this EmployeeWalletEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeWalletEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.typeLabel, typeLabel) || other.typeLabel == typeLabel)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.user, user) || other.user == user)&&(identical(other.methodLabel, methodLabel) || other.methodLabel == methodLabel)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.isReversed, isReversed) || other.isReversed == isReversed)&&(identical(other.canReverse, canReverse) || other.canReverse == canReverse)&&(identical(other.reversalReason, reversalReason) || other.reversalReason == reversalReason)&&(identical(other.recorderName, recorderName) || other.recorderName == recorderName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,typeLabel,direction,amount,userId,user,methodLabel,categoryName,notes,occurredAt,isReversed,canReverse,reversalReason,recorderName);

@override
String toString() {
  return 'EmployeeWalletEntry(id: $id, type: $type, typeLabel: $typeLabel, direction: $direction, amount: $amount, userId: $userId, user: $user, methodLabel: $methodLabel, categoryName: $categoryName, notes: $notes, occurredAt: $occurredAt, isReversed: $isReversed, canReverse: $canReverse, reversalReason: $reversalReason, recorderName: $recorderName)';
}


}

/// @nodoc
abstract mixin class $EmployeeWalletEntryCopyWith<$Res>  {
  factory $EmployeeWalletEntryCopyWith(EmployeeWalletEntry value, $Res Function(EmployeeWalletEntry) _then) = _$EmployeeWalletEntryCopyWithImpl;
@useResult
$Res call({
 int id, String type,@JsonKey(name: 'type_label') String typeLabel, String direction, String amount,@JsonKey(name: 'user_id') int? userId, EmployeeWalletPerson? user,@JsonKey(name: 'method_label') String? methodLabel,@JsonKey(name: 'category_name', readValue: _categoryName) String? categoryName, String? notes,@JsonKey(name: 'occurred_at', fromJson: _localDate) DateTime? occurredAt,@JsonKey(name: 'is_reversed') bool isReversed,@JsonKey(name: 'can_reverse') bool canReverse,@JsonKey(name: 'reversal_reason', readValue: _reversalReason) String? reversalReason,@JsonKey(name: 'recorder_name', readValue: _recorderName) String? recorderName
});


$EmployeeWalletPersonCopyWith<$Res>? get user;

}
/// @nodoc
class _$EmployeeWalletEntryCopyWithImpl<$Res>
    implements $EmployeeWalletEntryCopyWith<$Res> {
  _$EmployeeWalletEntryCopyWithImpl(this._self, this._then);

  final EmployeeWalletEntry _self;
  final $Res Function(EmployeeWalletEntry) _then;

/// Create a copy of EmployeeWalletEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? typeLabel = null,Object? direction = null,Object? amount = null,Object? userId = freezed,Object? user = freezed,Object? methodLabel = freezed,Object? categoryName = freezed,Object? notes = freezed,Object? occurredAt = freezed,Object? isReversed = null,Object? canReverse = null,Object? reversalReason = freezed,Object? recorderName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,typeLabel: null == typeLabel ? _self.typeLabel : typeLabel // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as EmployeeWalletPerson?,methodLabel: freezed == methodLabel ? _self.methodLabel : methodLabel // ignore: cast_nullable_to_non_nullable
as String?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,occurredAt: freezed == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isReversed: null == isReversed ? _self.isReversed : isReversed // ignore: cast_nullable_to_non_nullable
as bool,canReverse: null == canReverse ? _self.canReverse : canReverse // ignore: cast_nullable_to_non_nullable
as bool,reversalReason: freezed == reversalReason ? _self.reversalReason : reversalReason // ignore: cast_nullable_to_non_nullable
as String?,recorderName: freezed == recorderName ? _self.recorderName : recorderName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of EmployeeWalletEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EmployeeWalletPersonCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $EmployeeWalletPersonCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [EmployeeWalletEntry].
extension EmployeeWalletEntryPatterns on EmployeeWalletEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmployeeWalletEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmployeeWalletEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmployeeWalletEntry value)  $default,){
final _that = this;
switch (_that) {
case _EmployeeWalletEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmployeeWalletEntry value)?  $default,){
final _that = this;
switch (_that) {
case _EmployeeWalletEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String type, @JsonKey(name: 'type_label')  String typeLabel,  String direction,  String amount, @JsonKey(name: 'user_id')  int? userId,  EmployeeWalletPerson? user, @JsonKey(name: 'method_label')  String? methodLabel, @JsonKey(name: 'category_name', readValue: _categoryName)  String? categoryName,  String? notes, @JsonKey(name: 'occurred_at', fromJson: _localDate)  DateTime? occurredAt, @JsonKey(name: 'is_reversed')  bool isReversed, @JsonKey(name: 'can_reverse')  bool canReverse, @JsonKey(name: 'reversal_reason', readValue: _reversalReason)  String? reversalReason, @JsonKey(name: 'recorder_name', readValue: _recorderName)  String? recorderName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmployeeWalletEntry() when $default != null:
return $default(_that.id,_that.type,_that.typeLabel,_that.direction,_that.amount,_that.userId,_that.user,_that.methodLabel,_that.categoryName,_that.notes,_that.occurredAt,_that.isReversed,_that.canReverse,_that.reversalReason,_that.recorderName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String type, @JsonKey(name: 'type_label')  String typeLabel,  String direction,  String amount, @JsonKey(name: 'user_id')  int? userId,  EmployeeWalletPerson? user, @JsonKey(name: 'method_label')  String? methodLabel, @JsonKey(name: 'category_name', readValue: _categoryName)  String? categoryName,  String? notes, @JsonKey(name: 'occurred_at', fromJson: _localDate)  DateTime? occurredAt, @JsonKey(name: 'is_reversed')  bool isReversed, @JsonKey(name: 'can_reverse')  bool canReverse, @JsonKey(name: 'reversal_reason', readValue: _reversalReason)  String? reversalReason, @JsonKey(name: 'recorder_name', readValue: _recorderName)  String? recorderName)  $default,) {final _that = this;
switch (_that) {
case _EmployeeWalletEntry():
return $default(_that.id,_that.type,_that.typeLabel,_that.direction,_that.amount,_that.userId,_that.user,_that.methodLabel,_that.categoryName,_that.notes,_that.occurredAt,_that.isReversed,_that.canReverse,_that.reversalReason,_that.recorderName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String type, @JsonKey(name: 'type_label')  String typeLabel,  String direction,  String amount, @JsonKey(name: 'user_id')  int? userId,  EmployeeWalletPerson? user, @JsonKey(name: 'method_label')  String? methodLabel, @JsonKey(name: 'category_name', readValue: _categoryName)  String? categoryName,  String? notes, @JsonKey(name: 'occurred_at', fromJson: _localDate)  DateTime? occurredAt, @JsonKey(name: 'is_reversed')  bool isReversed, @JsonKey(name: 'can_reverse')  bool canReverse, @JsonKey(name: 'reversal_reason', readValue: _reversalReason)  String? reversalReason, @JsonKey(name: 'recorder_name', readValue: _recorderName)  String? recorderName)?  $default,) {final _that = this;
switch (_that) {
case _EmployeeWalletEntry() when $default != null:
return $default(_that.id,_that.type,_that.typeLabel,_that.direction,_that.amount,_that.userId,_that.user,_that.methodLabel,_that.categoryName,_that.notes,_that.occurredAt,_that.isReversed,_that.canReverse,_that.reversalReason,_that.recorderName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmployeeWalletEntry extends EmployeeWalletEntry {
  const _EmployeeWalletEntry({required this.id, required this.type, @JsonKey(name: 'type_label') required this.typeLabel, required this.direction, required this.amount, @JsonKey(name: 'user_id') this.userId, this.user, @JsonKey(name: 'method_label') this.methodLabel, @JsonKey(name: 'category_name', readValue: _categoryName) this.categoryName, this.notes, @JsonKey(name: 'occurred_at', fromJson: _localDate) this.occurredAt, @JsonKey(name: 'is_reversed') this.isReversed = false, @JsonKey(name: 'can_reverse') this.canReverse = false, @JsonKey(name: 'reversal_reason', readValue: _reversalReason) this.reversalReason, @JsonKey(name: 'recorder_name', readValue: _recorderName) this.recorderName}): super._();
  factory _EmployeeWalletEntry.fromJson(Map<String, dynamic> json) => _$EmployeeWalletEntryFromJson(json);

@override final  int id;
/// `deposit` · `credit` · `withdrawal` · `adjustment_credit` · `adjustment_debit` · `reversal`.
/// نوعٌ لا يعرفه هذا الإصدار يُرسم بـ[typeLabel] الخادم.
@override final  String type;
@override@JsonKey(name: 'type_label') final  String typeLabel;
/// `in` يزيد المحفظة، و`out` ينقصها. **الخادم يقرّره**: العكسُ عكسُ ما يعكسه.
@override final  String direction;
/// موجبٌ دائماً — الاتجاه في [direction].
@override final  String amount;
/// غائبٌ عن سطر صاحب المحفظة: محفظتُه هو.
@override@JsonKey(name: 'user_id') final  int? userId;
/// يُرسل في «المعاملات المالية» وحدها، فهي تجمع الموظفين كلهم.
@override final  EmployeeWalletPerson? user;
/// الإيداع والسحب وحدهما.
@override@JsonKey(name: 'method_label') final  String? methodLabel;
/// المستحق وحده.
@override@JsonKey(name: 'category_name', readValue: _categoryName) final  String? categoryName;
@override final  String? notes;
@override@JsonKey(name: 'occurred_at', fromJson: _localDate) final  DateTime? occurredAt;
/// عُكس — يُرسم مشطوباً.
@override@JsonKey(name: 'is_reversed') final  bool isReversed;
/// **الخادم وحده يقول إن كان يُعكس من هنا**: الصلاحية، وأنه ليس محفظة القارئ نفسه.
@override@JsonKey(name: 'can_reverse') final  bool canReverse;
/// سببُ العكس، تحت السطر المشطوب.
@override@JsonKey(name: 'reversal_reason', readValue: _reversalReason) final  String? reversalReason;
@override@JsonKey(name: 'recorder_name', readValue: _recorderName) final  String? recorderName;

/// Create a copy of EmployeeWalletEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmployeeWalletEntryCopyWith<_EmployeeWalletEntry> get copyWith => __$EmployeeWalletEntryCopyWithImpl<_EmployeeWalletEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmployeeWalletEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmployeeWalletEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.typeLabel, typeLabel) || other.typeLabel == typeLabel)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.user, user) || other.user == user)&&(identical(other.methodLabel, methodLabel) || other.methodLabel == methodLabel)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.isReversed, isReversed) || other.isReversed == isReversed)&&(identical(other.canReverse, canReverse) || other.canReverse == canReverse)&&(identical(other.reversalReason, reversalReason) || other.reversalReason == reversalReason)&&(identical(other.recorderName, recorderName) || other.recorderName == recorderName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,typeLabel,direction,amount,userId,user,methodLabel,categoryName,notes,occurredAt,isReversed,canReverse,reversalReason,recorderName);

@override
String toString() {
  return 'EmployeeWalletEntry(id: $id, type: $type, typeLabel: $typeLabel, direction: $direction, amount: $amount, userId: $userId, user: $user, methodLabel: $methodLabel, categoryName: $categoryName, notes: $notes, occurredAt: $occurredAt, isReversed: $isReversed, canReverse: $canReverse, reversalReason: $reversalReason, recorderName: $recorderName)';
}


}

/// @nodoc
abstract mixin class _$EmployeeWalletEntryCopyWith<$Res> implements $EmployeeWalletEntryCopyWith<$Res> {
  factory _$EmployeeWalletEntryCopyWith(_EmployeeWalletEntry value, $Res Function(_EmployeeWalletEntry) _then) = __$EmployeeWalletEntryCopyWithImpl;
@override @useResult
$Res call({
 int id, String type,@JsonKey(name: 'type_label') String typeLabel, String direction, String amount,@JsonKey(name: 'user_id') int? userId, EmployeeWalletPerson? user,@JsonKey(name: 'method_label') String? methodLabel,@JsonKey(name: 'category_name', readValue: _categoryName) String? categoryName, String? notes,@JsonKey(name: 'occurred_at', fromJson: _localDate) DateTime? occurredAt,@JsonKey(name: 'is_reversed') bool isReversed,@JsonKey(name: 'can_reverse') bool canReverse,@JsonKey(name: 'reversal_reason', readValue: _reversalReason) String? reversalReason,@JsonKey(name: 'recorder_name', readValue: _recorderName) String? recorderName
});


@override $EmployeeWalletPersonCopyWith<$Res>? get user;

}
/// @nodoc
class __$EmployeeWalletEntryCopyWithImpl<$Res>
    implements _$EmployeeWalletEntryCopyWith<$Res> {
  __$EmployeeWalletEntryCopyWithImpl(this._self, this._then);

  final _EmployeeWalletEntry _self;
  final $Res Function(_EmployeeWalletEntry) _then;

/// Create a copy of EmployeeWalletEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? typeLabel = null,Object? direction = null,Object? amount = null,Object? userId = freezed,Object? user = freezed,Object? methodLabel = freezed,Object? categoryName = freezed,Object? notes = freezed,Object? occurredAt = freezed,Object? isReversed = null,Object? canReverse = null,Object? reversalReason = freezed,Object? recorderName = freezed,}) {
  return _then(_EmployeeWalletEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,typeLabel: null == typeLabel ? _self.typeLabel : typeLabel // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as EmployeeWalletPerson?,methodLabel: freezed == methodLabel ? _self.methodLabel : methodLabel // ignore: cast_nullable_to_non_nullable
as String?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,occurredAt: freezed == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isReversed: null == isReversed ? _self.isReversed : isReversed // ignore: cast_nullable_to_non_nullable
as bool,canReverse: null == canReverse ? _self.canReverse : canReverse // ignore: cast_nullable_to_non_nullable
as bool,reversalReason: freezed == reversalReason ? _self.reversalReason : reversalReason // ignore: cast_nullable_to_non_nullable
as String?,recorderName: freezed == recorderName ? _self.recorderName : recorderName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of EmployeeWalletEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EmployeeWalletPersonCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $EmployeeWalletPersonCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// @nodoc
mixin _$EmployeeWalletPerson {

 int get id; String get name; String? get code;
/// Create a copy of EmployeeWalletPerson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeWalletPersonCopyWith<EmployeeWalletPerson> get copyWith => _$EmployeeWalletPersonCopyWithImpl<EmployeeWalletPerson>(this as EmployeeWalletPerson, _$identity);

  /// Serializes this EmployeeWalletPerson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeWalletPerson&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,code);

@override
String toString() {
  return 'EmployeeWalletPerson(id: $id, name: $name, code: $code)';
}


}

/// @nodoc
abstract mixin class $EmployeeWalletPersonCopyWith<$Res>  {
  factory $EmployeeWalletPersonCopyWith(EmployeeWalletPerson value, $Res Function(EmployeeWalletPerson) _then) = _$EmployeeWalletPersonCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? code
});




}
/// @nodoc
class _$EmployeeWalletPersonCopyWithImpl<$Res>
    implements $EmployeeWalletPersonCopyWith<$Res> {
  _$EmployeeWalletPersonCopyWithImpl(this._self, this._then);

  final EmployeeWalletPerson _self;
  final $Res Function(EmployeeWalletPerson) _then;

/// Create a copy of EmployeeWalletPerson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? code = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EmployeeWalletPerson].
extension EmployeeWalletPersonPatterns on EmployeeWalletPerson {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmployeeWalletPerson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmployeeWalletPerson() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmployeeWalletPerson value)  $default,){
final _that = this;
switch (_that) {
case _EmployeeWalletPerson():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmployeeWalletPerson value)?  $default,){
final _that = this;
switch (_that) {
case _EmployeeWalletPerson() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? code)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmployeeWalletPerson() when $default != null:
return $default(_that.id,_that.name,_that.code);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? code)  $default,) {final _that = this;
switch (_that) {
case _EmployeeWalletPerson():
return $default(_that.id,_that.name,_that.code);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? code)?  $default,) {final _that = this;
switch (_that) {
case _EmployeeWalletPerson() when $default != null:
return $default(_that.id,_that.name,_that.code);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmployeeWalletPerson implements EmployeeWalletPerson {
  const _EmployeeWalletPerson({required this.id, required this.name, this.code});
  factory _EmployeeWalletPerson.fromJson(Map<String, dynamic> json) => _$EmployeeWalletPersonFromJson(json);

@override final  int id;
@override final  String name;
@override final  String? code;

/// Create a copy of EmployeeWalletPerson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmployeeWalletPersonCopyWith<_EmployeeWalletPerson> get copyWith => __$EmployeeWalletPersonCopyWithImpl<_EmployeeWalletPerson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmployeeWalletPersonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmployeeWalletPerson&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,code);

@override
String toString() {
  return 'EmployeeWalletPerson(id: $id, name: $name, code: $code)';
}


}

/// @nodoc
abstract mixin class _$EmployeeWalletPersonCopyWith<$Res> implements $EmployeeWalletPersonCopyWith<$Res> {
  factory _$EmployeeWalletPersonCopyWith(_EmployeeWalletPerson value, $Res Function(_EmployeeWalletPerson) _then) = __$EmployeeWalletPersonCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? code
});




}
/// @nodoc
class __$EmployeeWalletPersonCopyWithImpl<$Res>
    implements _$EmployeeWalletPersonCopyWith<$Res> {
  __$EmployeeWalletPersonCopyWithImpl(this._self, this._then);

  final _EmployeeWalletPerson _self;
  final $Res Function(_EmployeeWalletPerson) _then;

/// Create a copy of EmployeeWalletPerson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? code = freezed,}) {
  return _then(_EmployeeWalletPerson(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$EmployeeWallet {

 String get balance;/// هل يحرّكها هذا القارئ — كاذبٌ لصاحبها، والمدير مستثنى. غائبٌ عن «محفظتي»: قراءةٌ فقط.
@JsonKey(name: 'can_move') bool get canMove;/// راتب الموظف، **منه يُقترح مبلغ «رواتب»**. يصل لمن يملك `users.salary` وحده.
 String? get salary;
/// Create a copy of EmployeeWallet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeWalletCopyWith<EmployeeWallet> get copyWith => _$EmployeeWalletCopyWithImpl<EmployeeWallet>(this as EmployeeWallet, _$identity);

  /// Serializes this EmployeeWallet to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeWallet&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.canMove, canMove) || other.canMove == canMove)&&(identical(other.salary, salary) || other.salary == salary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,balance,canMove,salary);

@override
String toString() {
  return 'EmployeeWallet(balance: $balance, canMove: $canMove, salary: $salary)';
}


}

/// @nodoc
abstract mixin class $EmployeeWalletCopyWith<$Res>  {
  factory $EmployeeWalletCopyWith(EmployeeWallet value, $Res Function(EmployeeWallet) _then) = _$EmployeeWalletCopyWithImpl;
@useResult
$Res call({
 String balance,@JsonKey(name: 'can_move') bool canMove, String? salary
});




}
/// @nodoc
class _$EmployeeWalletCopyWithImpl<$Res>
    implements $EmployeeWalletCopyWith<$Res> {
  _$EmployeeWalletCopyWithImpl(this._self, this._then);

  final EmployeeWallet _self;
  final $Res Function(EmployeeWallet) _then;

/// Create a copy of EmployeeWallet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? balance = null,Object? canMove = null,Object? salary = freezed,}) {
  return _then(_self.copyWith(
balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as String,canMove: null == canMove ? _self.canMove : canMove // ignore: cast_nullable_to_non_nullable
as bool,salary: freezed == salary ? _self.salary : salary // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EmployeeWallet].
extension EmployeeWalletPatterns on EmployeeWallet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmployeeWallet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmployeeWallet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmployeeWallet value)  $default,){
final _that = this;
switch (_that) {
case _EmployeeWallet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmployeeWallet value)?  $default,){
final _that = this;
switch (_that) {
case _EmployeeWallet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String balance, @JsonKey(name: 'can_move')  bool canMove,  String? salary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmployeeWallet() when $default != null:
return $default(_that.balance,_that.canMove,_that.salary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String balance, @JsonKey(name: 'can_move')  bool canMove,  String? salary)  $default,) {final _that = this;
switch (_that) {
case _EmployeeWallet():
return $default(_that.balance,_that.canMove,_that.salary);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String balance, @JsonKey(name: 'can_move')  bool canMove,  String? salary)?  $default,) {final _that = this;
switch (_that) {
case _EmployeeWallet() when $default != null:
return $default(_that.balance,_that.canMove,_that.salary);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmployeeWallet implements EmployeeWallet {
  const _EmployeeWallet({required this.balance, @JsonKey(name: 'can_move') this.canMove = false, this.salary});
  factory _EmployeeWallet.fromJson(Map<String, dynamic> json) => _$EmployeeWalletFromJson(json);

@override final  String balance;
/// هل يحرّكها هذا القارئ — كاذبٌ لصاحبها، والمدير مستثنى. غائبٌ عن «محفظتي»: قراءةٌ فقط.
@override@JsonKey(name: 'can_move') final  bool canMove;
/// راتب الموظف، **منه يُقترح مبلغ «رواتب»**. يصل لمن يملك `users.salary` وحده.
@override final  String? salary;

/// Create a copy of EmployeeWallet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmployeeWalletCopyWith<_EmployeeWallet> get copyWith => __$EmployeeWalletCopyWithImpl<_EmployeeWallet>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmployeeWalletToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmployeeWallet&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.canMove, canMove) || other.canMove == canMove)&&(identical(other.salary, salary) || other.salary == salary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,balance,canMove,salary);

@override
String toString() {
  return 'EmployeeWallet(balance: $balance, canMove: $canMove, salary: $salary)';
}


}

/// @nodoc
abstract mixin class _$EmployeeWalletCopyWith<$Res> implements $EmployeeWalletCopyWith<$Res> {
  factory _$EmployeeWalletCopyWith(_EmployeeWallet value, $Res Function(_EmployeeWallet) _then) = __$EmployeeWalletCopyWithImpl;
@override @useResult
$Res call({
 String balance,@JsonKey(name: 'can_move') bool canMove, String? salary
});




}
/// @nodoc
class __$EmployeeWalletCopyWithImpl<$Res>
    implements _$EmployeeWalletCopyWith<$Res> {
  __$EmployeeWalletCopyWithImpl(this._self, this._then);

  final _EmployeeWallet _self;
  final $Res Function(_EmployeeWallet) _then;

/// Create a copy of EmployeeWallet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? balance = null,Object? canMove = null,Object? salary = freezed,}) {
  return _then(_EmployeeWallet(
balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as String,canMove: null == canMove ? _self.canMove : canMove // ignore: cast_nullable_to_non_nullable
as bool,salary: freezed == salary ? _self.salary : salary // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$EmployeeWalletWrite {

 EmployeeWalletEntry get entry; String get balance;
/// Create a copy of EmployeeWalletWrite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeWalletWriteCopyWith<EmployeeWalletWrite> get copyWith => _$EmployeeWalletWriteCopyWithImpl<EmployeeWalletWrite>(this as EmployeeWalletWrite, _$identity);

  /// Serializes this EmployeeWalletWrite to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeWalletWrite&&(identical(other.entry, entry) || other.entry == entry)&&(identical(other.balance, balance) || other.balance == balance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,entry,balance);

@override
String toString() {
  return 'EmployeeWalletWrite(entry: $entry, balance: $balance)';
}


}

/// @nodoc
abstract mixin class $EmployeeWalletWriteCopyWith<$Res>  {
  factory $EmployeeWalletWriteCopyWith(EmployeeWalletWrite value, $Res Function(EmployeeWalletWrite) _then) = _$EmployeeWalletWriteCopyWithImpl;
@useResult
$Res call({
 EmployeeWalletEntry entry, String balance
});


$EmployeeWalletEntryCopyWith<$Res> get entry;

}
/// @nodoc
class _$EmployeeWalletWriteCopyWithImpl<$Res>
    implements $EmployeeWalletWriteCopyWith<$Res> {
  _$EmployeeWalletWriteCopyWithImpl(this._self, this._then);

  final EmployeeWalletWrite _self;
  final $Res Function(EmployeeWalletWrite) _then;

/// Create a copy of EmployeeWalletWrite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entry = null,Object? balance = null,}) {
  return _then(_self.copyWith(
entry: null == entry ? _self.entry : entry // ignore: cast_nullable_to_non_nullable
as EmployeeWalletEntry,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of EmployeeWalletWrite
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EmployeeWalletEntryCopyWith<$Res> get entry {
  
  return $EmployeeWalletEntryCopyWith<$Res>(_self.entry, (value) {
    return _then(_self.copyWith(entry: value));
  });
}
}


/// Adds pattern-matching-related methods to [EmployeeWalletWrite].
extension EmployeeWalletWritePatterns on EmployeeWalletWrite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmployeeWalletWrite value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmployeeWalletWrite() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmployeeWalletWrite value)  $default,){
final _that = this;
switch (_that) {
case _EmployeeWalletWrite():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmployeeWalletWrite value)?  $default,){
final _that = this;
switch (_that) {
case _EmployeeWalletWrite() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EmployeeWalletEntry entry,  String balance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmployeeWalletWrite() when $default != null:
return $default(_that.entry,_that.balance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EmployeeWalletEntry entry,  String balance)  $default,) {final _that = this;
switch (_that) {
case _EmployeeWalletWrite():
return $default(_that.entry,_that.balance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EmployeeWalletEntry entry,  String balance)?  $default,) {final _that = this;
switch (_that) {
case _EmployeeWalletWrite() when $default != null:
return $default(_that.entry,_that.balance);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmployeeWalletWrite implements EmployeeWalletWrite {
  const _EmployeeWalletWrite({required this.entry, required this.balance});
  factory _EmployeeWalletWrite.fromJson(Map<String, dynamic> json) => _$EmployeeWalletWriteFromJson(json);

@override final  EmployeeWalletEntry entry;
@override final  String balance;

/// Create a copy of EmployeeWalletWrite
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmployeeWalletWriteCopyWith<_EmployeeWalletWrite> get copyWith => __$EmployeeWalletWriteCopyWithImpl<_EmployeeWalletWrite>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmployeeWalletWriteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmployeeWalletWrite&&(identical(other.entry, entry) || other.entry == entry)&&(identical(other.balance, balance) || other.balance == balance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,entry,balance);

@override
String toString() {
  return 'EmployeeWalletWrite(entry: $entry, balance: $balance)';
}


}

/// @nodoc
abstract mixin class _$EmployeeWalletWriteCopyWith<$Res> implements $EmployeeWalletWriteCopyWith<$Res> {
  factory _$EmployeeWalletWriteCopyWith(_EmployeeWalletWrite value, $Res Function(_EmployeeWalletWrite) _then) = __$EmployeeWalletWriteCopyWithImpl;
@override @useResult
$Res call({
 EmployeeWalletEntry entry, String balance
});


@override $EmployeeWalletEntryCopyWith<$Res> get entry;

}
/// @nodoc
class __$EmployeeWalletWriteCopyWithImpl<$Res>
    implements _$EmployeeWalletWriteCopyWith<$Res> {
  __$EmployeeWalletWriteCopyWithImpl(this._self, this._then);

  final _EmployeeWalletWrite _self;
  final $Res Function(_EmployeeWalletWrite) _then;

/// Create a copy of EmployeeWalletWrite
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entry = null,Object? balance = null,}) {
  return _then(_EmployeeWalletWrite(
entry: null == entry ? _self.entry : entry // ignore: cast_nullable_to_non_nullable
as EmployeeWalletEntry,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of EmployeeWalletWrite
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EmployeeWalletEntryCopyWith<$Res> get entry {
  
  return $EmployeeWalletEntryCopyWith<$Res>(_self.entry, (value) {
    return _then(_self.copyWith(entry: value));
  });
}
}

/// @nodoc
mixin _$EmployeeMoneyDraft {

 String get amount; EmployeeWalletMethod get method;/// `null` لـ«تلقائي»: الخادم يختار الحساب.
 int? get treasuryAccountId; String? get reference; String? get notes; String? get receiptPath; String? get receiptFilename;
/// Create a copy of EmployeeMoneyDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeMoneyDraftCopyWith<EmployeeMoneyDraft> get copyWith => _$EmployeeMoneyDraftCopyWithImpl<EmployeeMoneyDraft>(this as EmployeeMoneyDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeMoneyDraft&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.method, method) || other.method == method)&&(identical(other.treasuryAccountId, treasuryAccountId) || other.treasuryAccountId == treasuryAccountId)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.receiptPath, receiptPath) || other.receiptPath == receiptPath)&&(identical(other.receiptFilename, receiptFilename) || other.receiptFilename == receiptFilename));
}


@override
int get hashCode => Object.hash(runtimeType,amount,method,treasuryAccountId,reference,notes,receiptPath,receiptFilename);

@override
String toString() {
  return 'EmployeeMoneyDraft(amount: $amount, method: $method, treasuryAccountId: $treasuryAccountId, reference: $reference, notes: $notes, receiptPath: $receiptPath, receiptFilename: $receiptFilename)';
}


}

/// @nodoc
abstract mixin class $EmployeeMoneyDraftCopyWith<$Res>  {
  factory $EmployeeMoneyDraftCopyWith(EmployeeMoneyDraft value, $Res Function(EmployeeMoneyDraft) _then) = _$EmployeeMoneyDraftCopyWithImpl;
@useResult
$Res call({
 String amount, EmployeeWalletMethod method, int? treasuryAccountId, String? reference, String? notes, String? receiptPath, String? receiptFilename
});




}
/// @nodoc
class _$EmployeeMoneyDraftCopyWithImpl<$Res>
    implements $EmployeeMoneyDraftCopyWith<$Res> {
  _$EmployeeMoneyDraftCopyWithImpl(this._self, this._then);

  final EmployeeMoneyDraft _self;
  final $Res Function(EmployeeMoneyDraft) _then;

/// Create a copy of EmployeeMoneyDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = null,Object? method = null,Object? treasuryAccountId = freezed,Object? reference = freezed,Object? notes = freezed,Object? receiptPath = freezed,Object? receiptFilename = freezed,}) {
  return _then(_self.copyWith(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as EmployeeWalletMethod,treasuryAccountId: freezed == treasuryAccountId ? _self.treasuryAccountId : treasuryAccountId // ignore: cast_nullable_to_non_nullable
as int?,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,receiptPath: freezed == receiptPath ? _self.receiptPath : receiptPath // ignore: cast_nullable_to_non_nullable
as String?,receiptFilename: freezed == receiptFilename ? _self.receiptFilename : receiptFilename // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EmployeeMoneyDraft].
extension EmployeeMoneyDraftPatterns on EmployeeMoneyDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmployeeMoneyDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmployeeMoneyDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmployeeMoneyDraft value)  $default,){
final _that = this;
switch (_that) {
case _EmployeeMoneyDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmployeeMoneyDraft value)?  $default,){
final _that = this;
switch (_that) {
case _EmployeeMoneyDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String amount,  EmployeeWalletMethod method,  int? treasuryAccountId,  String? reference,  String? notes,  String? receiptPath,  String? receiptFilename)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmployeeMoneyDraft() when $default != null:
return $default(_that.amount,_that.method,_that.treasuryAccountId,_that.reference,_that.notes,_that.receiptPath,_that.receiptFilename);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String amount,  EmployeeWalletMethod method,  int? treasuryAccountId,  String? reference,  String? notes,  String? receiptPath,  String? receiptFilename)  $default,) {final _that = this;
switch (_that) {
case _EmployeeMoneyDraft():
return $default(_that.amount,_that.method,_that.treasuryAccountId,_that.reference,_that.notes,_that.receiptPath,_that.receiptFilename);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String amount,  EmployeeWalletMethod method,  int? treasuryAccountId,  String? reference,  String? notes,  String? receiptPath,  String? receiptFilename)?  $default,) {final _that = this;
switch (_that) {
case _EmployeeMoneyDraft() when $default != null:
return $default(_that.amount,_that.method,_that.treasuryAccountId,_that.reference,_that.notes,_that.receiptPath,_that.receiptFilename);case _:
  return null;

}
}

}

/// @nodoc


class _EmployeeMoneyDraft implements EmployeeMoneyDraft {
  const _EmployeeMoneyDraft({required this.amount, required this.method, this.treasuryAccountId, this.reference, this.notes, this.receiptPath, this.receiptFilename});
  

@override final  String amount;
@override final  EmployeeWalletMethod method;
/// `null` لـ«تلقائي»: الخادم يختار الحساب.
@override final  int? treasuryAccountId;
@override final  String? reference;
@override final  String? notes;
@override final  String? receiptPath;
@override final  String? receiptFilename;

/// Create a copy of EmployeeMoneyDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmployeeMoneyDraftCopyWith<_EmployeeMoneyDraft> get copyWith => __$EmployeeMoneyDraftCopyWithImpl<_EmployeeMoneyDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmployeeMoneyDraft&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.method, method) || other.method == method)&&(identical(other.treasuryAccountId, treasuryAccountId) || other.treasuryAccountId == treasuryAccountId)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.receiptPath, receiptPath) || other.receiptPath == receiptPath)&&(identical(other.receiptFilename, receiptFilename) || other.receiptFilename == receiptFilename));
}


@override
int get hashCode => Object.hash(runtimeType,amount,method,treasuryAccountId,reference,notes,receiptPath,receiptFilename);

@override
String toString() {
  return 'EmployeeMoneyDraft(amount: $amount, method: $method, treasuryAccountId: $treasuryAccountId, reference: $reference, notes: $notes, receiptPath: $receiptPath, receiptFilename: $receiptFilename)';
}


}

/// @nodoc
abstract mixin class _$EmployeeMoneyDraftCopyWith<$Res> implements $EmployeeMoneyDraftCopyWith<$Res> {
  factory _$EmployeeMoneyDraftCopyWith(_EmployeeMoneyDraft value, $Res Function(_EmployeeMoneyDraft) _then) = __$EmployeeMoneyDraftCopyWithImpl;
@override @useResult
$Res call({
 String amount, EmployeeWalletMethod method, int? treasuryAccountId, String? reference, String? notes, String? receiptPath, String? receiptFilename
});




}
/// @nodoc
class __$EmployeeMoneyDraftCopyWithImpl<$Res>
    implements _$EmployeeMoneyDraftCopyWith<$Res> {
  __$EmployeeMoneyDraftCopyWithImpl(this._self, this._then);

  final _EmployeeMoneyDraft _self;
  final $Res Function(_EmployeeMoneyDraft) _then;

/// Create a copy of EmployeeMoneyDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? method = null,Object? treasuryAccountId = freezed,Object? reference = freezed,Object? notes = freezed,Object? receiptPath = freezed,Object? receiptFilename = freezed,}) {
  return _then(_EmployeeMoneyDraft(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as EmployeeWalletMethod,treasuryAccountId: freezed == treasuryAccountId ? _self.treasuryAccountId : treasuryAccountId // ignore: cast_nullable_to_non_nullable
as int?,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,receiptPath: freezed == receiptPath ? _self.receiptPath : receiptPath // ignore: cast_nullable_to_non_nullable
as String?,receiptFilename: freezed == receiptFilename ? _self.receiptFilename : receiptFilename // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$EmployeeCreditDraft {

 String get amount; int get categoryId; String? get notes;
/// Create a copy of EmployeeCreditDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeCreditDraftCopyWith<EmployeeCreditDraft> get copyWith => _$EmployeeCreditDraftCopyWithImpl<EmployeeCreditDraft>(this as EmployeeCreditDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeCreditDraft&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,amount,categoryId,notes);

@override
String toString() {
  return 'EmployeeCreditDraft(amount: $amount, categoryId: $categoryId, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $EmployeeCreditDraftCopyWith<$Res>  {
  factory $EmployeeCreditDraftCopyWith(EmployeeCreditDraft value, $Res Function(EmployeeCreditDraft) _then) = _$EmployeeCreditDraftCopyWithImpl;
@useResult
$Res call({
 String amount, int categoryId, String? notes
});




}
/// @nodoc
class _$EmployeeCreditDraftCopyWithImpl<$Res>
    implements $EmployeeCreditDraftCopyWith<$Res> {
  _$EmployeeCreditDraftCopyWithImpl(this._self, this._then);

  final EmployeeCreditDraft _self;
  final $Res Function(EmployeeCreditDraft) _then;

/// Create a copy of EmployeeCreditDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = null,Object? categoryId = null,Object? notes = freezed,}) {
  return _then(_self.copyWith(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EmployeeCreditDraft].
extension EmployeeCreditDraftPatterns on EmployeeCreditDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmployeeCreditDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmployeeCreditDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmployeeCreditDraft value)  $default,){
final _that = this;
switch (_that) {
case _EmployeeCreditDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmployeeCreditDraft value)?  $default,){
final _that = this;
switch (_that) {
case _EmployeeCreditDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String amount,  int categoryId,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmployeeCreditDraft() when $default != null:
return $default(_that.amount,_that.categoryId,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String amount,  int categoryId,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _EmployeeCreditDraft():
return $default(_that.amount,_that.categoryId,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String amount,  int categoryId,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _EmployeeCreditDraft() when $default != null:
return $default(_that.amount,_that.categoryId,_that.notes);case _:
  return null;

}
}

}

/// @nodoc


class _EmployeeCreditDraft implements EmployeeCreditDraft {
  const _EmployeeCreditDraft({required this.amount, required this.categoryId, this.notes});
  

@override final  String amount;
@override final  int categoryId;
@override final  String? notes;

/// Create a copy of EmployeeCreditDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmployeeCreditDraftCopyWith<_EmployeeCreditDraft> get copyWith => __$EmployeeCreditDraftCopyWithImpl<_EmployeeCreditDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmployeeCreditDraft&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,amount,categoryId,notes);

@override
String toString() {
  return 'EmployeeCreditDraft(amount: $amount, categoryId: $categoryId, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$EmployeeCreditDraftCopyWith<$Res> implements $EmployeeCreditDraftCopyWith<$Res> {
  factory _$EmployeeCreditDraftCopyWith(_EmployeeCreditDraft value, $Res Function(_EmployeeCreditDraft) _then) = __$EmployeeCreditDraftCopyWithImpl;
@override @useResult
$Res call({
 String amount, int categoryId, String? notes
});




}
/// @nodoc
class __$EmployeeCreditDraftCopyWithImpl<$Res>
    implements _$EmployeeCreditDraftCopyWith<$Res> {
  __$EmployeeCreditDraftCopyWithImpl(this._self, this._then);

  final _EmployeeCreditDraft _self;
  final $Res Function(_EmployeeCreditDraft) _then;

/// Create a copy of EmployeeCreditDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? categoryId = null,Object? notes = freezed,}) {
  return _then(_EmployeeCreditDraft(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$EmployeeWalletLedger {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeWalletLedger);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EmployeeWalletLedger()';
}


}

/// @nodoc
class $EmployeeWalletLedgerCopyWith<$Res>  {
$EmployeeWalletLedgerCopyWith(EmployeeWalletLedger _, $Res Function(EmployeeWalletLedger) __);
}


/// Adds pattern-matching-related methods to [EmployeeWalletLedger].
extension EmployeeWalletLedgerPatterns on EmployeeWalletLedger {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EmployeeWalletLedgerOf value)?  of,TResult Function( EmployeeWalletLedgerAll value)?  all,TResult Function( EmployeeWalletLedgerMine value)?  mine,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EmployeeWalletLedgerOf() when of != null:
return of(_that);case EmployeeWalletLedgerAll() when all != null:
return all(_that);case EmployeeWalletLedgerMine() when mine != null:
return mine(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EmployeeWalletLedgerOf value)  of,required TResult Function( EmployeeWalletLedgerAll value)  all,required TResult Function( EmployeeWalletLedgerMine value)  mine,}){
final _that = this;
switch (_that) {
case EmployeeWalletLedgerOf():
return of(_that);case EmployeeWalletLedgerAll():
return all(_that);case EmployeeWalletLedgerMine():
return mine(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EmployeeWalletLedgerOf value)?  of,TResult? Function( EmployeeWalletLedgerAll value)?  all,TResult? Function( EmployeeWalletLedgerMine value)?  mine,}){
final _that = this;
switch (_that) {
case EmployeeWalletLedgerOf() when of != null:
return of(_that);case EmployeeWalletLedgerAll() when all != null:
return all(_that);case EmployeeWalletLedgerMine() when mine != null:
return mine(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int userId)?  of,TResult Function()?  all,TResult Function()?  mine,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EmployeeWalletLedgerOf() when of != null:
return of(_that.userId);case EmployeeWalletLedgerAll() when all != null:
return all();case EmployeeWalletLedgerMine() when mine != null:
return mine();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int userId)  of,required TResult Function()  all,required TResult Function()  mine,}) {final _that = this;
switch (_that) {
case EmployeeWalletLedgerOf():
return of(_that.userId);case EmployeeWalletLedgerAll():
return all();case EmployeeWalletLedgerMine():
return mine();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int userId)?  of,TResult? Function()?  all,TResult? Function()?  mine,}) {final _that = this;
switch (_that) {
case EmployeeWalletLedgerOf() when of != null:
return of(_that.userId);case EmployeeWalletLedgerAll() when all != null:
return all();case EmployeeWalletLedgerMine() when mine != null:
return mine();case _:
  return null;

}
}

}

/// @nodoc


class EmployeeWalletLedgerOf implements EmployeeWalletLedger {
  const EmployeeWalletLedgerOf(this.userId);
  

 final  int userId;

/// Create a copy of EmployeeWalletLedger
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeWalletLedgerOfCopyWith<EmployeeWalletLedgerOf> get copyWith => _$EmployeeWalletLedgerOfCopyWithImpl<EmployeeWalletLedgerOf>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeWalletLedgerOf&&(identical(other.userId, userId) || other.userId == userId));
}


@override
int get hashCode => Object.hash(runtimeType,userId);

@override
String toString() {
  return 'EmployeeWalletLedger.of(userId: $userId)';
}


}

/// @nodoc
abstract mixin class $EmployeeWalletLedgerOfCopyWith<$Res> implements $EmployeeWalletLedgerCopyWith<$Res> {
  factory $EmployeeWalletLedgerOfCopyWith(EmployeeWalletLedgerOf value, $Res Function(EmployeeWalletLedgerOf) _then) = _$EmployeeWalletLedgerOfCopyWithImpl;
@useResult
$Res call({
 int userId
});




}
/// @nodoc
class _$EmployeeWalletLedgerOfCopyWithImpl<$Res>
    implements $EmployeeWalletLedgerOfCopyWith<$Res> {
  _$EmployeeWalletLedgerOfCopyWithImpl(this._self, this._then);

  final EmployeeWalletLedgerOf _self;
  final $Res Function(EmployeeWalletLedgerOf) _then;

/// Create a copy of EmployeeWalletLedger
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? userId = null,}) {
  return _then(EmployeeWalletLedgerOf(
null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class EmployeeWalletLedgerAll implements EmployeeWalletLedger {
  const EmployeeWalletLedgerAll();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeWalletLedgerAll);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EmployeeWalletLedger.all()';
}


}




/// @nodoc


class EmployeeWalletLedgerMine implements EmployeeWalletLedger {
  const EmployeeWalletLedgerMine();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeWalletLedgerMine);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EmployeeWalletLedger.mine()';
}


}




// dart format on
