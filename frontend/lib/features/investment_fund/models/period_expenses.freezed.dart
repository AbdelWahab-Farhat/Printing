// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'period_expenses.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PeriodExpenseRef {

 int get id; String get name;
/// Create a copy of PeriodExpenseRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodExpenseRefCopyWith<PeriodExpenseRef> get copyWith => _$PeriodExpenseRefCopyWithImpl<PeriodExpenseRef>(this as PeriodExpenseRef, _$identity);

  /// Serializes this PeriodExpenseRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodExpenseRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'PeriodExpenseRef(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $PeriodExpenseRefCopyWith<$Res>  {
  factory $PeriodExpenseRefCopyWith(PeriodExpenseRef value, $Res Function(PeriodExpenseRef) _then) = _$PeriodExpenseRefCopyWithImpl;
@useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class _$PeriodExpenseRefCopyWithImpl<$Res>
    implements $PeriodExpenseRefCopyWith<$Res> {
  _$PeriodExpenseRefCopyWithImpl(this._self, this._then);

  final PeriodExpenseRef _self;
  final $Res Function(PeriodExpenseRef) _then;

/// Create a copy of PeriodExpenseRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PeriodExpenseRef].
extension PeriodExpenseRefPatterns on PeriodExpenseRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PeriodExpenseRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PeriodExpenseRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PeriodExpenseRef value)  $default,){
final _that = this;
switch (_that) {
case _PeriodExpenseRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PeriodExpenseRef value)?  $default,){
final _that = this;
switch (_that) {
case _PeriodExpenseRef() when $default != null:
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
case _PeriodExpenseRef() when $default != null:
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
case _PeriodExpenseRef():
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
case _PeriodExpenseRef() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodExpenseRef implements PeriodExpenseRef {
  const _PeriodExpenseRef({required this.id, required this.name});
  factory _PeriodExpenseRef.fromJson(Map<String, dynamic> json) => _$PeriodExpenseRefFromJson(json);

@override final  int id;
@override final  String name;

/// Create a copy of PeriodExpenseRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodExpenseRefCopyWith<_PeriodExpenseRef> get copyWith => __$PeriodExpenseRefCopyWithImpl<_PeriodExpenseRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodExpenseRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodExpenseRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'PeriodExpenseRef(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$PeriodExpenseRefCopyWith<$Res> implements $PeriodExpenseRefCopyWith<$Res> {
  factory _$PeriodExpenseRefCopyWith(_PeriodExpenseRef value, $Res Function(_PeriodExpenseRef) _then) = __$PeriodExpenseRefCopyWithImpl;
@override @useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class __$PeriodExpenseRefCopyWithImpl<$Res>
    implements _$PeriodExpenseRefCopyWith<$Res> {
  __$PeriodExpenseRefCopyWithImpl(this._self, this._then);

  final _PeriodExpenseRef _self;
  final $Res Function(_PeriodExpenseRef) _then;

/// Create a copy of PeriodExpenseRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_PeriodExpenseRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PeriodExpenseReversal {

 int get id;@JsonKey(name: 'incurred_on') String? get incurredOn; String? get reason;/// الفترةُ التي رُدّ فيها ما حُمِّل للمستثمرين — غيرُ فترة المصروف إن عُكس بعد إقفالها.
@JsonKey(name: 'period_code') String? get periodCode;
/// Create a copy of PeriodExpenseReversal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodExpenseReversalCopyWith<PeriodExpenseReversal> get copyWith => _$PeriodExpenseReversalCopyWithImpl<PeriodExpenseReversal>(this as PeriodExpenseReversal, _$identity);

  /// Serializes this PeriodExpenseReversal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodExpenseReversal&&(identical(other.id, id) || other.id == id)&&(identical(other.incurredOn, incurredOn) || other.incurredOn == incurredOn)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.periodCode, periodCode) || other.periodCode == periodCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,incurredOn,reason,periodCode);

@override
String toString() {
  return 'PeriodExpenseReversal(id: $id, incurredOn: $incurredOn, reason: $reason, periodCode: $periodCode)';
}


}

/// @nodoc
abstract mixin class $PeriodExpenseReversalCopyWith<$Res>  {
  factory $PeriodExpenseReversalCopyWith(PeriodExpenseReversal value, $Res Function(PeriodExpenseReversal) _then) = _$PeriodExpenseReversalCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'incurred_on') String? incurredOn, String? reason,@JsonKey(name: 'period_code') String? periodCode
});




}
/// @nodoc
class _$PeriodExpenseReversalCopyWithImpl<$Res>
    implements $PeriodExpenseReversalCopyWith<$Res> {
  _$PeriodExpenseReversalCopyWithImpl(this._self, this._then);

  final PeriodExpenseReversal _self;
  final $Res Function(PeriodExpenseReversal) _then;

/// Create a copy of PeriodExpenseReversal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? incurredOn = freezed,Object? reason = freezed,Object? periodCode = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,incurredOn: freezed == incurredOn ? _self.incurredOn : incurredOn // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,periodCode: freezed == periodCode ? _self.periodCode : periodCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PeriodExpenseReversal].
extension PeriodExpenseReversalPatterns on PeriodExpenseReversal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PeriodExpenseReversal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PeriodExpenseReversal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PeriodExpenseReversal value)  $default,){
final _that = this;
switch (_that) {
case _PeriodExpenseReversal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PeriodExpenseReversal value)?  $default,){
final _that = this;
switch (_that) {
case _PeriodExpenseReversal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'incurred_on')  String? incurredOn,  String? reason, @JsonKey(name: 'period_code')  String? periodCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodExpenseReversal() when $default != null:
return $default(_that.id,_that.incurredOn,_that.reason,_that.periodCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'incurred_on')  String? incurredOn,  String? reason, @JsonKey(name: 'period_code')  String? periodCode)  $default,) {final _that = this;
switch (_that) {
case _PeriodExpenseReversal():
return $default(_that.id,_that.incurredOn,_that.reason,_that.periodCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'incurred_on')  String? incurredOn,  String? reason, @JsonKey(name: 'period_code')  String? periodCode)?  $default,) {final _that = this;
switch (_that) {
case _PeriodExpenseReversal() when $default != null:
return $default(_that.id,_that.incurredOn,_that.reason,_that.periodCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodExpenseReversal implements PeriodExpenseReversal {
  const _PeriodExpenseReversal({required this.id, @JsonKey(name: 'incurred_on') this.incurredOn, this.reason, @JsonKey(name: 'period_code') this.periodCode});
  factory _PeriodExpenseReversal.fromJson(Map<String, dynamic> json) => _$PeriodExpenseReversalFromJson(json);

@override final  int id;
@override@JsonKey(name: 'incurred_on') final  String? incurredOn;
@override final  String? reason;
/// الفترةُ التي رُدّ فيها ما حُمِّل للمستثمرين — غيرُ فترة المصروف إن عُكس بعد إقفالها.
@override@JsonKey(name: 'period_code') final  String? periodCode;

/// Create a copy of PeriodExpenseReversal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodExpenseReversalCopyWith<_PeriodExpenseReversal> get copyWith => __$PeriodExpenseReversalCopyWithImpl<_PeriodExpenseReversal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodExpenseReversalToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodExpenseReversal&&(identical(other.id, id) || other.id == id)&&(identical(other.incurredOn, incurredOn) || other.incurredOn == incurredOn)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.periodCode, periodCode) || other.periodCode == periodCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,incurredOn,reason,periodCode);

@override
String toString() {
  return 'PeriodExpenseReversal(id: $id, incurredOn: $incurredOn, reason: $reason, periodCode: $periodCode)';
}


}

/// @nodoc
abstract mixin class _$PeriodExpenseReversalCopyWith<$Res> implements $PeriodExpenseReversalCopyWith<$Res> {
  factory _$PeriodExpenseReversalCopyWith(_PeriodExpenseReversal value, $Res Function(_PeriodExpenseReversal) _then) = __$PeriodExpenseReversalCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'incurred_on') String? incurredOn, String? reason,@JsonKey(name: 'period_code') String? periodCode
});




}
/// @nodoc
class __$PeriodExpenseReversalCopyWithImpl<$Res>
    implements _$PeriodExpenseReversalCopyWith<$Res> {
  __$PeriodExpenseReversalCopyWithImpl(this._self, this._then);

  final _PeriodExpenseReversal _self;
  final $Res Function(_PeriodExpenseReversal) _then;

/// Create a copy of PeriodExpenseReversal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? incurredOn = freezed,Object? reason = freezed,Object? periodCode = freezed,}) {
  return _then(_PeriodExpenseReversal(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,incurredOn: freezed == incurredOn ? _self.incurredOn : incurredOn // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,periodCode: freezed == periodCode ? _self.periodCode : periodCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PeriodExpense {

 int get id; String get kind;@JsonKey(name: 'kind_label') String get kindLabel; String get name; String get amount;@JsonKey(name: 'incurred_on') String? get incurredOn; String? get notes;@JsonKey(name: 'treasury_account') PeriodExpenseRef? get treasuryAccount;@JsonKey(name: 'recorded_by') PeriodExpenseRef? get recordedBy; bool get counted;/// مؤرّخٌ في فترةٍ أُقفلت وسُجِّل بعد إقفالها — فحُمِّل على المفتوحة يومَ سُجِّل.
@JsonKey(name: 'recorded_after_close') bool get recordedAfterClose;@JsonKey(name: 'is_reversed') bool get isReversed;/// **الخادمُ يقول أيُعكس**: لا ما عُكس، ولا مصروفُ فترةٍ أُقفلت — أرقامُها أُعلنت.
@JsonKey(name: 'can_reverse') bool get canReverse; PeriodExpenseReversal? get reversal;/// ما تحمّله المستثمرون منه في هذه الفترة — **بإشارته**: السالبُ ردٌّ إليهم.
@JsonKey(name: 'investors_amount') String get investorsAmount; List<PeriodInvestorShare> get investors;
/// Create a copy of PeriodExpense
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodExpenseCopyWith<PeriodExpense> get copyWith => _$PeriodExpenseCopyWithImpl<PeriodExpense>(this as PeriodExpense, _$identity);

  /// Serializes this PeriodExpense to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodExpense&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.kindLabel, kindLabel) || other.kindLabel == kindLabel)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.incurredOn, incurredOn) || other.incurredOn == incurredOn)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.treasuryAccount, treasuryAccount) || other.treasuryAccount == treasuryAccount)&&(identical(other.recordedBy, recordedBy) || other.recordedBy == recordedBy)&&(identical(other.counted, counted) || other.counted == counted)&&(identical(other.recordedAfterClose, recordedAfterClose) || other.recordedAfterClose == recordedAfterClose)&&(identical(other.isReversed, isReversed) || other.isReversed == isReversed)&&(identical(other.canReverse, canReverse) || other.canReverse == canReverse)&&(identical(other.reversal, reversal) || other.reversal == reversal)&&(identical(other.investorsAmount, investorsAmount) || other.investorsAmount == investorsAmount)&&const DeepCollectionEquality().equals(other.investors, investors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,kindLabel,name,amount,incurredOn,notes,treasuryAccount,recordedBy,counted,recordedAfterClose,isReversed,canReverse,reversal,investorsAmount,const DeepCollectionEquality().hash(investors));

@override
String toString() {
  return 'PeriodExpense(id: $id, kind: $kind, kindLabel: $kindLabel, name: $name, amount: $amount, incurredOn: $incurredOn, notes: $notes, treasuryAccount: $treasuryAccount, recordedBy: $recordedBy, counted: $counted, recordedAfterClose: $recordedAfterClose, isReversed: $isReversed, canReverse: $canReverse, reversal: $reversal, investorsAmount: $investorsAmount, investors: $investors)';
}


}

/// @nodoc
abstract mixin class $PeriodExpenseCopyWith<$Res>  {
  factory $PeriodExpenseCopyWith(PeriodExpense value, $Res Function(PeriodExpense) _then) = _$PeriodExpenseCopyWithImpl;
@useResult
$Res call({
 int id, String kind,@JsonKey(name: 'kind_label') String kindLabel, String name, String amount,@JsonKey(name: 'incurred_on') String? incurredOn, String? notes,@JsonKey(name: 'treasury_account') PeriodExpenseRef? treasuryAccount,@JsonKey(name: 'recorded_by') PeriodExpenseRef? recordedBy, bool counted,@JsonKey(name: 'recorded_after_close') bool recordedAfterClose,@JsonKey(name: 'is_reversed') bool isReversed,@JsonKey(name: 'can_reverse') bool canReverse, PeriodExpenseReversal? reversal,@JsonKey(name: 'investors_amount') String investorsAmount, List<PeriodInvestorShare> investors
});


$PeriodExpenseRefCopyWith<$Res>? get treasuryAccount;$PeriodExpenseRefCopyWith<$Res>? get recordedBy;$PeriodExpenseReversalCopyWith<$Res>? get reversal;

}
/// @nodoc
class _$PeriodExpenseCopyWithImpl<$Res>
    implements $PeriodExpenseCopyWith<$Res> {
  _$PeriodExpenseCopyWithImpl(this._self, this._then);

  final PeriodExpense _self;
  final $Res Function(PeriodExpense) _then;

/// Create a copy of PeriodExpense
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? kindLabel = null,Object? name = null,Object? amount = null,Object? incurredOn = freezed,Object? notes = freezed,Object? treasuryAccount = freezed,Object? recordedBy = freezed,Object? counted = null,Object? recordedAfterClose = null,Object? isReversed = null,Object? canReverse = null,Object? reversal = freezed,Object? investorsAmount = null,Object? investors = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,kindLabel: null == kindLabel ? _self.kindLabel : kindLabel // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,incurredOn: freezed == incurredOn ? _self.incurredOn : incurredOn // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,treasuryAccount: freezed == treasuryAccount ? _self.treasuryAccount : treasuryAccount // ignore: cast_nullable_to_non_nullable
as PeriodExpenseRef?,recordedBy: freezed == recordedBy ? _self.recordedBy : recordedBy // ignore: cast_nullable_to_non_nullable
as PeriodExpenseRef?,counted: null == counted ? _self.counted : counted // ignore: cast_nullable_to_non_nullable
as bool,recordedAfterClose: null == recordedAfterClose ? _self.recordedAfterClose : recordedAfterClose // ignore: cast_nullable_to_non_nullable
as bool,isReversed: null == isReversed ? _self.isReversed : isReversed // ignore: cast_nullable_to_non_nullable
as bool,canReverse: null == canReverse ? _self.canReverse : canReverse // ignore: cast_nullable_to_non_nullable
as bool,reversal: freezed == reversal ? _self.reversal : reversal // ignore: cast_nullable_to_non_nullable
as PeriodExpenseReversal?,investorsAmount: null == investorsAmount ? _self.investorsAmount : investorsAmount // ignore: cast_nullable_to_non_nullable
as String,investors: null == investors ? _self.investors : investors // ignore: cast_nullable_to_non_nullable
as List<PeriodInvestorShare>,
  ));
}
/// Create a copy of PeriodExpense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodExpenseRefCopyWith<$Res>? get treasuryAccount {
    if (_self.treasuryAccount == null) {
    return null;
  }

  return $PeriodExpenseRefCopyWith<$Res>(_self.treasuryAccount!, (value) {
    return _then(_self.copyWith(treasuryAccount: value));
  });
}/// Create a copy of PeriodExpense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodExpenseRefCopyWith<$Res>? get recordedBy {
    if (_self.recordedBy == null) {
    return null;
  }

  return $PeriodExpenseRefCopyWith<$Res>(_self.recordedBy!, (value) {
    return _then(_self.copyWith(recordedBy: value));
  });
}/// Create a copy of PeriodExpense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodExpenseReversalCopyWith<$Res>? get reversal {
    if (_self.reversal == null) {
    return null;
  }

  return $PeriodExpenseReversalCopyWith<$Res>(_self.reversal!, (value) {
    return _then(_self.copyWith(reversal: value));
  });
}
}


/// Adds pattern-matching-related methods to [PeriodExpense].
extension PeriodExpensePatterns on PeriodExpense {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PeriodExpense value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PeriodExpense() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PeriodExpense value)  $default,){
final _that = this;
switch (_that) {
case _PeriodExpense():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PeriodExpense value)?  $default,){
final _that = this;
switch (_that) {
case _PeriodExpense() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String kind, @JsonKey(name: 'kind_label')  String kindLabel,  String name,  String amount, @JsonKey(name: 'incurred_on')  String? incurredOn,  String? notes, @JsonKey(name: 'treasury_account')  PeriodExpenseRef? treasuryAccount, @JsonKey(name: 'recorded_by')  PeriodExpenseRef? recordedBy,  bool counted, @JsonKey(name: 'recorded_after_close')  bool recordedAfterClose, @JsonKey(name: 'is_reversed')  bool isReversed, @JsonKey(name: 'can_reverse')  bool canReverse,  PeriodExpenseReversal? reversal, @JsonKey(name: 'investors_amount')  String investorsAmount,  List<PeriodInvestorShare> investors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodExpense() when $default != null:
return $default(_that.id,_that.kind,_that.kindLabel,_that.name,_that.amount,_that.incurredOn,_that.notes,_that.treasuryAccount,_that.recordedBy,_that.counted,_that.recordedAfterClose,_that.isReversed,_that.canReverse,_that.reversal,_that.investorsAmount,_that.investors);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String kind, @JsonKey(name: 'kind_label')  String kindLabel,  String name,  String amount, @JsonKey(name: 'incurred_on')  String? incurredOn,  String? notes, @JsonKey(name: 'treasury_account')  PeriodExpenseRef? treasuryAccount, @JsonKey(name: 'recorded_by')  PeriodExpenseRef? recordedBy,  bool counted, @JsonKey(name: 'recorded_after_close')  bool recordedAfterClose, @JsonKey(name: 'is_reversed')  bool isReversed, @JsonKey(name: 'can_reverse')  bool canReverse,  PeriodExpenseReversal? reversal, @JsonKey(name: 'investors_amount')  String investorsAmount,  List<PeriodInvestorShare> investors)  $default,) {final _that = this;
switch (_that) {
case _PeriodExpense():
return $default(_that.id,_that.kind,_that.kindLabel,_that.name,_that.amount,_that.incurredOn,_that.notes,_that.treasuryAccount,_that.recordedBy,_that.counted,_that.recordedAfterClose,_that.isReversed,_that.canReverse,_that.reversal,_that.investorsAmount,_that.investors);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String kind, @JsonKey(name: 'kind_label')  String kindLabel,  String name,  String amount, @JsonKey(name: 'incurred_on')  String? incurredOn,  String? notes, @JsonKey(name: 'treasury_account')  PeriodExpenseRef? treasuryAccount, @JsonKey(name: 'recorded_by')  PeriodExpenseRef? recordedBy,  bool counted, @JsonKey(name: 'recorded_after_close')  bool recordedAfterClose, @JsonKey(name: 'is_reversed')  bool isReversed, @JsonKey(name: 'can_reverse')  bool canReverse,  PeriodExpenseReversal? reversal, @JsonKey(name: 'investors_amount')  String investorsAmount,  List<PeriodInvestorShare> investors)?  $default,) {final _that = this;
switch (_that) {
case _PeriodExpense() when $default != null:
return $default(_that.id,_that.kind,_that.kindLabel,_that.name,_that.amount,_that.incurredOn,_that.notes,_that.treasuryAccount,_that.recordedBy,_that.counted,_that.recordedAfterClose,_that.isReversed,_that.canReverse,_that.reversal,_that.investorsAmount,_that.investors);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodExpense implements PeriodExpense {
  const _PeriodExpense({required this.id, required this.kind, @JsonKey(name: 'kind_label') required this.kindLabel, required this.name, required this.amount, @JsonKey(name: 'incurred_on') this.incurredOn, this.notes, @JsonKey(name: 'treasury_account') this.treasuryAccount, @JsonKey(name: 'recorded_by') this.recordedBy, this.counted = true, @JsonKey(name: 'recorded_after_close') this.recordedAfterClose = false, @JsonKey(name: 'is_reversed') this.isReversed = false, @JsonKey(name: 'can_reverse') this.canReverse = false, this.reversal, @JsonKey(name: 'investors_amount') this.investorsAmount = '0.00', final  List<PeriodInvestorShare> investors = const <PeriodInvestorShare>[]}): _investors = investors;
  factory _PeriodExpense.fromJson(Map<String, dynamic> json) => _$PeriodExpenseFromJson(json);

@override final  int id;
@override final  String kind;
@override@JsonKey(name: 'kind_label') final  String kindLabel;
@override final  String name;
@override final  String amount;
@override@JsonKey(name: 'incurred_on') final  String? incurredOn;
@override final  String? notes;
@override@JsonKey(name: 'treasury_account') final  PeriodExpenseRef? treasuryAccount;
@override@JsonKey(name: 'recorded_by') final  PeriodExpenseRef? recordedBy;
@override@JsonKey() final  bool counted;
/// مؤرّخٌ في فترةٍ أُقفلت وسُجِّل بعد إقفالها — فحُمِّل على المفتوحة يومَ سُجِّل.
@override@JsonKey(name: 'recorded_after_close') final  bool recordedAfterClose;
@override@JsonKey(name: 'is_reversed') final  bool isReversed;
/// **الخادمُ يقول أيُعكس**: لا ما عُكس، ولا مصروفُ فترةٍ أُقفلت — أرقامُها أُعلنت.
@override@JsonKey(name: 'can_reverse') final  bool canReverse;
@override final  PeriodExpenseReversal? reversal;
/// ما تحمّله المستثمرون منه في هذه الفترة — **بإشارته**: السالبُ ردٌّ إليهم.
@override@JsonKey(name: 'investors_amount') final  String investorsAmount;
 final  List<PeriodInvestorShare> _investors;
@override@JsonKey() List<PeriodInvestorShare> get investors {
  if (_investors is EqualUnmodifiableListView) return _investors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_investors);
}


/// Create a copy of PeriodExpense
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodExpenseCopyWith<_PeriodExpense> get copyWith => __$PeriodExpenseCopyWithImpl<_PeriodExpense>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodExpenseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodExpense&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.kindLabel, kindLabel) || other.kindLabel == kindLabel)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.incurredOn, incurredOn) || other.incurredOn == incurredOn)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.treasuryAccount, treasuryAccount) || other.treasuryAccount == treasuryAccount)&&(identical(other.recordedBy, recordedBy) || other.recordedBy == recordedBy)&&(identical(other.counted, counted) || other.counted == counted)&&(identical(other.recordedAfterClose, recordedAfterClose) || other.recordedAfterClose == recordedAfterClose)&&(identical(other.isReversed, isReversed) || other.isReversed == isReversed)&&(identical(other.canReverse, canReverse) || other.canReverse == canReverse)&&(identical(other.reversal, reversal) || other.reversal == reversal)&&(identical(other.investorsAmount, investorsAmount) || other.investorsAmount == investorsAmount)&&const DeepCollectionEquality().equals(other._investors, _investors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,kindLabel,name,amount,incurredOn,notes,treasuryAccount,recordedBy,counted,recordedAfterClose,isReversed,canReverse,reversal,investorsAmount,const DeepCollectionEquality().hash(_investors));

@override
String toString() {
  return 'PeriodExpense(id: $id, kind: $kind, kindLabel: $kindLabel, name: $name, amount: $amount, incurredOn: $incurredOn, notes: $notes, treasuryAccount: $treasuryAccount, recordedBy: $recordedBy, counted: $counted, recordedAfterClose: $recordedAfterClose, isReversed: $isReversed, canReverse: $canReverse, reversal: $reversal, investorsAmount: $investorsAmount, investors: $investors)';
}


}

/// @nodoc
abstract mixin class _$PeriodExpenseCopyWith<$Res> implements $PeriodExpenseCopyWith<$Res> {
  factory _$PeriodExpenseCopyWith(_PeriodExpense value, $Res Function(_PeriodExpense) _then) = __$PeriodExpenseCopyWithImpl;
@override @useResult
$Res call({
 int id, String kind,@JsonKey(name: 'kind_label') String kindLabel, String name, String amount,@JsonKey(name: 'incurred_on') String? incurredOn, String? notes,@JsonKey(name: 'treasury_account') PeriodExpenseRef? treasuryAccount,@JsonKey(name: 'recorded_by') PeriodExpenseRef? recordedBy, bool counted,@JsonKey(name: 'recorded_after_close') bool recordedAfterClose,@JsonKey(name: 'is_reversed') bool isReversed,@JsonKey(name: 'can_reverse') bool canReverse, PeriodExpenseReversal? reversal,@JsonKey(name: 'investors_amount') String investorsAmount, List<PeriodInvestorShare> investors
});


@override $PeriodExpenseRefCopyWith<$Res>? get treasuryAccount;@override $PeriodExpenseRefCopyWith<$Res>? get recordedBy;@override $PeriodExpenseReversalCopyWith<$Res>? get reversal;

}
/// @nodoc
class __$PeriodExpenseCopyWithImpl<$Res>
    implements _$PeriodExpenseCopyWith<$Res> {
  __$PeriodExpenseCopyWithImpl(this._self, this._then);

  final _PeriodExpense _self;
  final $Res Function(_PeriodExpense) _then;

/// Create a copy of PeriodExpense
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? kindLabel = null,Object? name = null,Object? amount = null,Object? incurredOn = freezed,Object? notes = freezed,Object? treasuryAccount = freezed,Object? recordedBy = freezed,Object? counted = null,Object? recordedAfterClose = null,Object? isReversed = null,Object? canReverse = null,Object? reversal = freezed,Object? investorsAmount = null,Object? investors = null,}) {
  return _then(_PeriodExpense(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,kindLabel: null == kindLabel ? _self.kindLabel : kindLabel // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,incurredOn: freezed == incurredOn ? _self.incurredOn : incurredOn // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,treasuryAccount: freezed == treasuryAccount ? _self.treasuryAccount : treasuryAccount // ignore: cast_nullable_to_non_nullable
as PeriodExpenseRef?,recordedBy: freezed == recordedBy ? _self.recordedBy : recordedBy // ignore: cast_nullable_to_non_nullable
as PeriodExpenseRef?,counted: null == counted ? _self.counted : counted // ignore: cast_nullable_to_non_nullable
as bool,recordedAfterClose: null == recordedAfterClose ? _self.recordedAfterClose : recordedAfterClose // ignore: cast_nullable_to_non_nullable
as bool,isReversed: null == isReversed ? _self.isReversed : isReversed // ignore: cast_nullable_to_non_nullable
as bool,canReverse: null == canReverse ? _self.canReverse : canReverse // ignore: cast_nullable_to_non_nullable
as bool,reversal: freezed == reversal ? _self.reversal : reversal // ignore: cast_nullable_to_non_nullable
as PeriodExpenseReversal?,investorsAmount: null == investorsAmount ? _self.investorsAmount : investorsAmount // ignore: cast_nullable_to_non_nullable
as String,investors: null == investors ? _self._investors : investors // ignore: cast_nullable_to_non_nullable
as List<PeriodInvestorShare>,
  ));
}

/// Create a copy of PeriodExpense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodExpenseRefCopyWith<$Res>? get treasuryAccount {
    if (_self.treasuryAccount == null) {
    return null;
  }

  return $PeriodExpenseRefCopyWith<$Res>(_self.treasuryAccount!, (value) {
    return _then(_self.copyWith(treasuryAccount: value));
  });
}/// Create a copy of PeriodExpense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodExpenseRefCopyWith<$Res>? get recordedBy {
    if (_self.recordedBy == null) {
    return null;
  }

  return $PeriodExpenseRefCopyWith<$Res>(_self.recordedBy!, (value) {
    return _then(_self.copyWith(recordedBy: value));
  });
}/// Create a copy of PeriodExpense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodExpenseReversalCopyWith<$Res>? get reversal {
    if (_self.reversal == null) {
    return null;
  }

  return $PeriodExpenseReversalCopyWith<$Res>(_self.reversal!, (value) {
    return _then(_self.copyWith(reversal: value));
  });
}
}


/// @nodoc
mixin _$PeriodExpensesTotals {

/// مجموعُ المعدود من مصاريف نافذتها.
@JsonKey(name: 'expenses_total') String get expensesTotal;/// ما تحمّله المستثمرون في هذه الفترة، التصحيحاتُ داخلة.
@JsonKey(name: 'investors_total') String get investorsTotal;/// المجمّدُ على الفترة يوم أُقفلت — `null` ما لم تُقفَل.
@JsonKey(name: 'frozen_total') String? get frozenTotal;
/// Create a copy of PeriodExpensesTotals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodExpensesTotalsCopyWith<PeriodExpensesTotals> get copyWith => _$PeriodExpensesTotalsCopyWithImpl<PeriodExpensesTotals>(this as PeriodExpensesTotals, _$identity);

  /// Serializes this PeriodExpensesTotals to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodExpensesTotals&&(identical(other.expensesTotal, expensesTotal) || other.expensesTotal == expensesTotal)&&(identical(other.investorsTotal, investorsTotal) || other.investorsTotal == investorsTotal)&&(identical(other.frozenTotal, frozenTotal) || other.frozenTotal == frozenTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,expensesTotal,investorsTotal,frozenTotal);

@override
String toString() {
  return 'PeriodExpensesTotals(expensesTotal: $expensesTotal, investorsTotal: $investorsTotal, frozenTotal: $frozenTotal)';
}


}

/// @nodoc
abstract mixin class $PeriodExpensesTotalsCopyWith<$Res>  {
  factory $PeriodExpensesTotalsCopyWith(PeriodExpensesTotals value, $Res Function(PeriodExpensesTotals) _then) = _$PeriodExpensesTotalsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'expenses_total') String expensesTotal,@JsonKey(name: 'investors_total') String investorsTotal,@JsonKey(name: 'frozen_total') String? frozenTotal
});




}
/// @nodoc
class _$PeriodExpensesTotalsCopyWithImpl<$Res>
    implements $PeriodExpensesTotalsCopyWith<$Res> {
  _$PeriodExpensesTotalsCopyWithImpl(this._self, this._then);

  final PeriodExpensesTotals _self;
  final $Res Function(PeriodExpensesTotals) _then;

/// Create a copy of PeriodExpensesTotals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? expensesTotal = null,Object? investorsTotal = null,Object? frozenTotal = freezed,}) {
  return _then(_self.copyWith(
expensesTotal: null == expensesTotal ? _self.expensesTotal : expensesTotal // ignore: cast_nullable_to_non_nullable
as String,investorsTotal: null == investorsTotal ? _self.investorsTotal : investorsTotal // ignore: cast_nullable_to_non_nullable
as String,frozenTotal: freezed == frozenTotal ? _self.frozenTotal : frozenTotal // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PeriodExpensesTotals].
extension PeriodExpensesTotalsPatterns on PeriodExpensesTotals {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PeriodExpensesTotals value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PeriodExpensesTotals() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PeriodExpensesTotals value)  $default,){
final _that = this;
switch (_that) {
case _PeriodExpensesTotals():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PeriodExpensesTotals value)?  $default,){
final _that = this;
switch (_that) {
case _PeriodExpensesTotals() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'expenses_total')  String expensesTotal, @JsonKey(name: 'investors_total')  String investorsTotal, @JsonKey(name: 'frozen_total')  String? frozenTotal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodExpensesTotals() when $default != null:
return $default(_that.expensesTotal,_that.investorsTotal,_that.frozenTotal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'expenses_total')  String expensesTotal, @JsonKey(name: 'investors_total')  String investorsTotal, @JsonKey(name: 'frozen_total')  String? frozenTotal)  $default,) {final _that = this;
switch (_that) {
case _PeriodExpensesTotals():
return $default(_that.expensesTotal,_that.investorsTotal,_that.frozenTotal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'expenses_total')  String expensesTotal, @JsonKey(name: 'investors_total')  String investorsTotal, @JsonKey(name: 'frozen_total')  String? frozenTotal)?  $default,) {final _that = this;
switch (_that) {
case _PeriodExpensesTotals() when $default != null:
return $default(_that.expensesTotal,_that.investorsTotal,_that.frozenTotal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodExpensesTotals implements PeriodExpensesTotals {
  const _PeriodExpensesTotals({@JsonKey(name: 'expenses_total') this.expensesTotal = '0.00', @JsonKey(name: 'investors_total') this.investorsTotal = '0.00', @JsonKey(name: 'frozen_total') this.frozenTotal});
  factory _PeriodExpensesTotals.fromJson(Map<String, dynamic> json) => _$PeriodExpensesTotalsFromJson(json);

/// مجموعُ المعدود من مصاريف نافذتها.
@override@JsonKey(name: 'expenses_total') final  String expensesTotal;
/// ما تحمّله المستثمرون في هذه الفترة، التصحيحاتُ داخلة.
@override@JsonKey(name: 'investors_total') final  String investorsTotal;
/// المجمّدُ على الفترة يوم أُقفلت — `null` ما لم تُقفَل.
@override@JsonKey(name: 'frozen_total') final  String? frozenTotal;

/// Create a copy of PeriodExpensesTotals
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodExpensesTotalsCopyWith<_PeriodExpensesTotals> get copyWith => __$PeriodExpensesTotalsCopyWithImpl<_PeriodExpensesTotals>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodExpensesTotalsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodExpensesTotals&&(identical(other.expensesTotal, expensesTotal) || other.expensesTotal == expensesTotal)&&(identical(other.investorsTotal, investorsTotal) || other.investorsTotal == investorsTotal)&&(identical(other.frozenTotal, frozenTotal) || other.frozenTotal == frozenTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,expensesTotal,investorsTotal,frozenTotal);

@override
String toString() {
  return 'PeriodExpensesTotals(expensesTotal: $expensesTotal, investorsTotal: $investorsTotal, frozenTotal: $frozenTotal)';
}


}

/// @nodoc
abstract mixin class _$PeriodExpensesTotalsCopyWith<$Res> implements $PeriodExpensesTotalsCopyWith<$Res> {
  factory _$PeriodExpensesTotalsCopyWith(_PeriodExpensesTotals value, $Res Function(_PeriodExpensesTotals) _then) = __$PeriodExpensesTotalsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'expenses_total') String expensesTotal,@JsonKey(name: 'investors_total') String investorsTotal,@JsonKey(name: 'frozen_total') String? frozenTotal
});




}
/// @nodoc
class __$PeriodExpensesTotalsCopyWithImpl<$Res>
    implements _$PeriodExpensesTotalsCopyWith<$Res> {
  __$PeriodExpensesTotalsCopyWithImpl(this._self, this._then);

  final _PeriodExpensesTotals _self;
  final $Res Function(_PeriodExpensesTotals) _then;

/// Create a copy of PeriodExpensesTotals
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? expensesTotal = null,Object? investorsTotal = null,Object? frozenTotal = freezed,}) {
  return _then(_PeriodExpensesTotals(
expensesTotal: null == expensesTotal ? _self.expensesTotal : expensesTotal // ignore: cast_nullable_to_non_nullable
as String,investorsTotal: null == investorsTotal ? _self.investorsTotal : investorsTotal // ignore: cast_nullable_to_non_nullable
as String,frozenTotal: freezed == frozenTotal ? _self.frozenTotal : frozenTotal // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PeriodExpenses {

 FundPeriod get period; List<PeriodExpense> get expenses;/// مصاريفُ من فتراتٍ أُقفلت مسّت محافظَ المستثمرين في هذه الفترة: عكسٌ أو تحميلٌ متأخّر.
 List<PeriodExpense> get corrections; PeriodExpensesTotals get totals;
/// Create a copy of PeriodExpenses
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodExpensesCopyWith<PeriodExpenses> get copyWith => _$PeriodExpensesCopyWithImpl<PeriodExpenses>(this as PeriodExpenses, _$identity);

  /// Serializes this PeriodExpenses to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodExpenses&&(identical(other.period, period) || other.period == period)&&const DeepCollectionEquality().equals(other.expenses, expenses)&&const DeepCollectionEquality().equals(other.corrections, corrections)&&(identical(other.totals, totals) || other.totals == totals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,period,const DeepCollectionEquality().hash(expenses),const DeepCollectionEquality().hash(corrections),totals);

@override
String toString() {
  return 'PeriodExpenses(period: $period, expenses: $expenses, corrections: $corrections, totals: $totals)';
}


}

/// @nodoc
abstract mixin class $PeriodExpensesCopyWith<$Res>  {
  factory $PeriodExpensesCopyWith(PeriodExpenses value, $Res Function(PeriodExpenses) _then) = _$PeriodExpensesCopyWithImpl;
@useResult
$Res call({
 FundPeriod period, List<PeriodExpense> expenses, List<PeriodExpense> corrections, PeriodExpensesTotals totals
});


$FundPeriodCopyWith<$Res> get period;$PeriodExpensesTotalsCopyWith<$Res> get totals;

}
/// @nodoc
class _$PeriodExpensesCopyWithImpl<$Res>
    implements $PeriodExpensesCopyWith<$Res> {
  _$PeriodExpensesCopyWithImpl(this._self, this._then);

  final PeriodExpenses _self;
  final $Res Function(PeriodExpenses) _then;

/// Create a copy of PeriodExpenses
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? period = null,Object? expenses = null,Object? corrections = null,Object? totals = null,}) {
  return _then(_self.copyWith(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as FundPeriod,expenses: null == expenses ? _self.expenses : expenses // ignore: cast_nullable_to_non_nullable
as List<PeriodExpense>,corrections: null == corrections ? _self.corrections : corrections // ignore: cast_nullable_to_non_nullable
as List<PeriodExpense>,totals: null == totals ? _self.totals : totals // ignore: cast_nullable_to_non_nullable
as PeriodExpensesTotals,
  ));
}
/// Create a copy of PeriodExpenses
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundPeriodCopyWith<$Res> get period {
  
  return $FundPeriodCopyWith<$Res>(_self.period, (value) {
    return _then(_self.copyWith(period: value));
  });
}/// Create a copy of PeriodExpenses
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodExpensesTotalsCopyWith<$Res> get totals {
  
  return $PeriodExpensesTotalsCopyWith<$Res>(_self.totals, (value) {
    return _then(_self.copyWith(totals: value));
  });
}
}


/// Adds pattern-matching-related methods to [PeriodExpenses].
extension PeriodExpensesPatterns on PeriodExpenses {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PeriodExpenses value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PeriodExpenses() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PeriodExpenses value)  $default,){
final _that = this;
switch (_that) {
case _PeriodExpenses():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PeriodExpenses value)?  $default,){
final _that = this;
switch (_that) {
case _PeriodExpenses() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FundPeriod period,  List<PeriodExpense> expenses,  List<PeriodExpense> corrections,  PeriodExpensesTotals totals)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodExpenses() when $default != null:
return $default(_that.period,_that.expenses,_that.corrections,_that.totals);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FundPeriod period,  List<PeriodExpense> expenses,  List<PeriodExpense> corrections,  PeriodExpensesTotals totals)  $default,) {final _that = this;
switch (_that) {
case _PeriodExpenses():
return $default(_that.period,_that.expenses,_that.corrections,_that.totals);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FundPeriod period,  List<PeriodExpense> expenses,  List<PeriodExpense> corrections,  PeriodExpensesTotals totals)?  $default,) {final _that = this;
switch (_that) {
case _PeriodExpenses() when $default != null:
return $default(_that.period,_that.expenses,_that.corrections,_that.totals);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodExpenses implements PeriodExpenses {
  const _PeriodExpenses({required this.period, final  List<PeriodExpense> expenses = const <PeriodExpense>[], final  List<PeriodExpense> corrections = const <PeriodExpense>[], this.totals = const PeriodExpensesTotals()}): _expenses = expenses,_corrections = corrections;
  factory _PeriodExpenses.fromJson(Map<String, dynamic> json) => _$PeriodExpensesFromJson(json);

@override final  FundPeriod period;
 final  List<PeriodExpense> _expenses;
@override@JsonKey() List<PeriodExpense> get expenses {
  if (_expenses is EqualUnmodifiableListView) return _expenses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_expenses);
}

/// مصاريفُ من فتراتٍ أُقفلت مسّت محافظَ المستثمرين في هذه الفترة: عكسٌ أو تحميلٌ متأخّر.
 final  List<PeriodExpense> _corrections;
/// مصاريفُ من فتراتٍ أُقفلت مسّت محافظَ المستثمرين في هذه الفترة: عكسٌ أو تحميلٌ متأخّر.
@override@JsonKey() List<PeriodExpense> get corrections {
  if (_corrections is EqualUnmodifiableListView) return _corrections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_corrections);
}

@override@JsonKey() final  PeriodExpensesTotals totals;

/// Create a copy of PeriodExpenses
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodExpensesCopyWith<_PeriodExpenses> get copyWith => __$PeriodExpensesCopyWithImpl<_PeriodExpenses>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodExpensesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodExpenses&&(identical(other.period, period) || other.period == period)&&const DeepCollectionEquality().equals(other._expenses, _expenses)&&const DeepCollectionEquality().equals(other._corrections, _corrections)&&(identical(other.totals, totals) || other.totals == totals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,period,const DeepCollectionEquality().hash(_expenses),const DeepCollectionEquality().hash(_corrections),totals);

@override
String toString() {
  return 'PeriodExpenses(period: $period, expenses: $expenses, corrections: $corrections, totals: $totals)';
}


}

/// @nodoc
abstract mixin class _$PeriodExpensesCopyWith<$Res> implements $PeriodExpensesCopyWith<$Res> {
  factory _$PeriodExpensesCopyWith(_PeriodExpenses value, $Res Function(_PeriodExpenses) _then) = __$PeriodExpensesCopyWithImpl;
@override @useResult
$Res call({
 FundPeriod period, List<PeriodExpense> expenses, List<PeriodExpense> corrections, PeriodExpensesTotals totals
});


@override $FundPeriodCopyWith<$Res> get period;@override $PeriodExpensesTotalsCopyWith<$Res> get totals;

}
/// @nodoc
class __$PeriodExpensesCopyWithImpl<$Res>
    implements _$PeriodExpensesCopyWith<$Res> {
  __$PeriodExpensesCopyWithImpl(this._self, this._then);

  final _PeriodExpenses _self;
  final $Res Function(_PeriodExpenses) _then;

/// Create a copy of PeriodExpenses
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? period = null,Object? expenses = null,Object? corrections = null,Object? totals = null,}) {
  return _then(_PeriodExpenses(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as FundPeriod,expenses: null == expenses ? _self._expenses : expenses // ignore: cast_nullable_to_non_nullable
as List<PeriodExpense>,corrections: null == corrections ? _self._corrections : corrections // ignore: cast_nullable_to_non_nullable
as List<PeriodExpense>,totals: null == totals ? _self.totals : totals // ignore: cast_nullable_to_non_nullable
as PeriodExpensesTotals,
  ));
}

/// Create a copy of PeriodExpenses
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundPeriodCopyWith<$Res> get period {
  
  return $FundPeriodCopyWith<$Res>(_self.period, (value) {
    return _then(_self.copyWith(period: value));
  });
}/// Create a copy of PeriodExpenses
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodExpensesTotalsCopyWith<$Res> get totals {
  
  return $PeriodExpensesTotalsCopyWith<$Res>(_self.totals, (value) {
    return _then(_self.copyWith(totals: value));
  });
}
}

// dart format on
