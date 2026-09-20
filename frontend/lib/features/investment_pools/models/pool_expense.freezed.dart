// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pool_expense.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PoolExpense {

 int get id;@JsonKey(name: 'investor_deal_id') int get investorDealId;@JsonKey(name: 'investment_period_id') int? get investmentPeriodId; String get kind;@JsonKey(name: 'kind_label') String get kindLabel; String get name; String get amount;/// Recorded and **not** subtracted — «محسوبة مسبقاً».
@JsonKey(name: 'is_landed') bool get isLanded;/// Whether the close actually takes this off the period's profit.
@JsonKey(name: 'is_deducted') bool get isDeducted;@JsonKey(name: 'incurred_on') String? get incurredOn;/// A correction undoes by a further row; neither side is deducted afterwards.
@JsonKey(name: 'reverses_expense_id') int? get reversesExpenseId;@JsonKey(name: 'is_reversed') bool get isReversed; String? get notes;@JsonKey(name: 'recorded_at') String? get recordedAt;
/// Create a copy of PoolExpense
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PoolExpenseCopyWith<PoolExpense> get copyWith => _$PoolExpenseCopyWithImpl<PoolExpense>(this as PoolExpense, _$identity);

  /// Serializes this PoolExpense to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PoolExpense&&(identical(other.id, id) || other.id == id)&&(identical(other.investorDealId, investorDealId) || other.investorDealId == investorDealId)&&(identical(other.investmentPeriodId, investmentPeriodId) || other.investmentPeriodId == investmentPeriodId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.kindLabel, kindLabel) || other.kindLabel == kindLabel)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.isLanded, isLanded) || other.isLanded == isLanded)&&(identical(other.isDeducted, isDeducted) || other.isDeducted == isDeducted)&&(identical(other.incurredOn, incurredOn) || other.incurredOn == incurredOn)&&(identical(other.reversesExpenseId, reversesExpenseId) || other.reversesExpenseId == reversesExpenseId)&&(identical(other.isReversed, isReversed) || other.isReversed == isReversed)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,investorDealId,investmentPeriodId,kind,kindLabel,name,amount,isLanded,isDeducted,incurredOn,reversesExpenseId,isReversed,notes,recordedAt);

@override
String toString() {
  return 'PoolExpense(id: $id, investorDealId: $investorDealId, investmentPeriodId: $investmentPeriodId, kind: $kind, kindLabel: $kindLabel, name: $name, amount: $amount, isLanded: $isLanded, isDeducted: $isDeducted, incurredOn: $incurredOn, reversesExpenseId: $reversesExpenseId, isReversed: $isReversed, notes: $notes, recordedAt: $recordedAt)';
}


}

/// @nodoc
abstract mixin class $PoolExpenseCopyWith<$Res>  {
  factory $PoolExpenseCopyWith(PoolExpense value, $Res Function(PoolExpense) _then) = _$PoolExpenseCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'investor_deal_id') int investorDealId,@JsonKey(name: 'investment_period_id') int? investmentPeriodId, String kind,@JsonKey(name: 'kind_label') String kindLabel, String name, String amount,@JsonKey(name: 'is_landed') bool isLanded,@JsonKey(name: 'is_deducted') bool isDeducted,@JsonKey(name: 'incurred_on') String? incurredOn,@JsonKey(name: 'reverses_expense_id') int? reversesExpenseId,@JsonKey(name: 'is_reversed') bool isReversed, String? notes,@JsonKey(name: 'recorded_at') String? recordedAt
});




}
/// @nodoc
class _$PoolExpenseCopyWithImpl<$Res>
    implements $PoolExpenseCopyWith<$Res> {
  _$PoolExpenseCopyWithImpl(this._self, this._then);

  final PoolExpense _self;
  final $Res Function(PoolExpense) _then;

/// Create a copy of PoolExpense
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? investorDealId = null,Object? investmentPeriodId = freezed,Object? kind = null,Object? kindLabel = null,Object? name = null,Object? amount = null,Object? isLanded = null,Object? isDeducted = null,Object? incurredOn = freezed,Object? reversesExpenseId = freezed,Object? isReversed = null,Object? notes = freezed,Object? recordedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,investorDealId: null == investorDealId ? _self.investorDealId : investorDealId // ignore: cast_nullable_to_non_nullable
as int,investmentPeriodId: freezed == investmentPeriodId ? _self.investmentPeriodId : investmentPeriodId // ignore: cast_nullable_to_non_nullable
as int?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,kindLabel: null == kindLabel ? _self.kindLabel : kindLabel // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,isLanded: null == isLanded ? _self.isLanded : isLanded // ignore: cast_nullable_to_non_nullable
as bool,isDeducted: null == isDeducted ? _self.isDeducted : isDeducted // ignore: cast_nullable_to_non_nullable
as bool,incurredOn: freezed == incurredOn ? _self.incurredOn : incurredOn // ignore: cast_nullable_to_non_nullable
as String?,reversesExpenseId: freezed == reversesExpenseId ? _self.reversesExpenseId : reversesExpenseId // ignore: cast_nullable_to_non_nullable
as int?,isReversed: null == isReversed ? _self.isReversed : isReversed // ignore: cast_nullable_to_non_nullable
as bool,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,recordedAt: freezed == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PoolExpense].
extension PoolExpensePatterns on PoolExpense {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PoolExpense value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PoolExpense() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PoolExpense value)  $default,){
final _that = this;
switch (_that) {
case _PoolExpense():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PoolExpense value)?  $default,){
final _that = this;
switch (_that) {
case _PoolExpense() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'investor_deal_id')  int investorDealId, @JsonKey(name: 'investment_period_id')  int? investmentPeriodId,  String kind, @JsonKey(name: 'kind_label')  String kindLabel,  String name,  String amount, @JsonKey(name: 'is_landed')  bool isLanded, @JsonKey(name: 'is_deducted')  bool isDeducted, @JsonKey(name: 'incurred_on')  String? incurredOn, @JsonKey(name: 'reverses_expense_id')  int? reversesExpenseId, @JsonKey(name: 'is_reversed')  bool isReversed,  String? notes, @JsonKey(name: 'recorded_at')  String? recordedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PoolExpense() when $default != null:
return $default(_that.id,_that.investorDealId,_that.investmentPeriodId,_that.kind,_that.kindLabel,_that.name,_that.amount,_that.isLanded,_that.isDeducted,_that.incurredOn,_that.reversesExpenseId,_that.isReversed,_that.notes,_that.recordedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'investor_deal_id')  int investorDealId, @JsonKey(name: 'investment_period_id')  int? investmentPeriodId,  String kind, @JsonKey(name: 'kind_label')  String kindLabel,  String name,  String amount, @JsonKey(name: 'is_landed')  bool isLanded, @JsonKey(name: 'is_deducted')  bool isDeducted, @JsonKey(name: 'incurred_on')  String? incurredOn, @JsonKey(name: 'reverses_expense_id')  int? reversesExpenseId, @JsonKey(name: 'is_reversed')  bool isReversed,  String? notes, @JsonKey(name: 'recorded_at')  String? recordedAt)  $default,) {final _that = this;
switch (_that) {
case _PoolExpense():
return $default(_that.id,_that.investorDealId,_that.investmentPeriodId,_that.kind,_that.kindLabel,_that.name,_that.amount,_that.isLanded,_that.isDeducted,_that.incurredOn,_that.reversesExpenseId,_that.isReversed,_that.notes,_that.recordedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'investor_deal_id')  int investorDealId, @JsonKey(name: 'investment_period_id')  int? investmentPeriodId,  String kind, @JsonKey(name: 'kind_label')  String kindLabel,  String name,  String amount, @JsonKey(name: 'is_landed')  bool isLanded, @JsonKey(name: 'is_deducted')  bool isDeducted, @JsonKey(name: 'incurred_on')  String? incurredOn, @JsonKey(name: 'reverses_expense_id')  int? reversesExpenseId, @JsonKey(name: 'is_reversed')  bool isReversed,  String? notes, @JsonKey(name: 'recorded_at')  String? recordedAt)?  $default,) {final _that = this;
switch (_that) {
case _PoolExpense() when $default != null:
return $default(_that.id,_that.investorDealId,_that.investmentPeriodId,_that.kind,_that.kindLabel,_that.name,_that.amount,_that.isLanded,_that.isDeducted,_that.incurredOn,_that.reversesExpenseId,_that.isReversed,_that.notes,_that.recordedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PoolExpense implements PoolExpense {
  const _PoolExpense({required this.id, @JsonKey(name: 'investor_deal_id') required this.investorDealId, @JsonKey(name: 'investment_period_id') this.investmentPeriodId, required this.kind, @JsonKey(name: 'kind_label') required this.kindLabel, required this.name, required this.amount, @JsonKey(name: 'is_landed') this.isLanded = false, @JsonKey(name: 'is_deducted') this.isDeducted = true, @JsonKey(name: 'incurred_on') this.incurredOn, @JsonKey(name: 'reverses_expense_id') this.reversesExpenseId, @JsonKey(name: 'is_reversed') this.isReversed = false, this.notes, @JsonKey(name: 'recorded_at') this.recordedAt});
  factory _PoolExpense.fromJson(Map<String, dynamic> json) => _$PoolExpenseFromJson(json);

@override final  int id;
@override@JsonKey(name: 'investor_deal_id') final  int investorDealId;
@override@JsonKey(name: 'investment_period_id') final  int? investmentPeriodId;
@override final  String kind;
@override@JsonKey(name: 'kind_label') final  String kindLabel;
@override final  String name;
@override final  String amount;
/// Recorded and **not** subtracted — «محسوبة مسبقاً».
@override@JsonKey(name: 'is_landed') final  bool isLanded;
/// Whether the close actually takes this off the period's profit.
@override@JsonKey(name: 'is_deducted') final  bool isDeducted;
@override@JsonKey(name: 'incurred_on') final  String? incurredOn;
/// A correction undoes by a further row; neither side is deducted afterwards.
@override@JsonKey(name: 'reverses_expense_id') final  int? reversesExpenseId;
@override@JsonKey(name: 'is_reversed') final  bool isReversed;
@override final  String? notes;
@override@JsonKey(name: 'recorded_at') final  String? recordedAt;

/// Create a copy of PoolExpense
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PoolExpenseCopyWith<_PoolExpense> get copyWith => __$PoolExpenseCopyWithImpl<_PoolExpense>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PoolExpenseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PoolExpense&&(identical(other.id, id) || other.id == id)&&(identical(other.investorDealId, investorDealId) || other.investorDealId == investorDealId)&&(identical(other.investmentPeriodId, investmentPeriodId) || other.investmentPeriodId == investmentPeriodId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.kindLabel, kindLabel) || other.kindLabel == kindLabel)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.isLanded, isLanded) || other.isLanded == isLanded)&&(identical(other.isDeducted, isDeducted) || other.isDeducted == isDeducted)&&(identical(other.incurredOn, incurredOn) || other.incurredOn == incurredOn)&&(identical(other.reversesExpenseId, reversesExpenseId) || other.reversesExpenseId == reversesExpenseId)&&(identical(other.isReversed, isReversed) || other.isReversed == isReversed)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,investorDealId,investmentPeriodId,kind,kindLabel,name,amount,isLanded,isDeducted,incurredOn,reversesExpenseId,isReversed,notes,recordedAt);

@override
String toString() {
  return 'PoolExpense(id: $id, investorDealId: $investorDealId, investmentPeriodId: $investmentPeriodId, kind: $kind, kindLabel: $kindLabel, name: $name, amount: $amount, isLanded: $isLanded, isDeducted: $isDeducted, incurredOn: $incurredOn, reversesExpenseId: $reversesExpenseId, isReversed: $isReversed, notes: $notes, recordedAt: $recordedAt)';
}


}

/// @nodoc
abstract mixin class _$PoolExpenseCopyWith<$Res> implements $PoolExpenseCopyWith<$Res> {
  factory _$PoolExpenseCopyWith(_PoolExpense value, $Res Function(_PoolExpense) _then) = __$PoolExpenseCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'investor_deal_id') int investorDealId,@JsonKey(name: 'investment_period_id') int? investmentPeriodId, String kind,@JsonKey(name: 'kind_label') String kindLabel, String name, String amount,@JsonKey(name: 'is_landed') bool isLanded,@JsonKey(name: 'is_deducted') bool isDeducted,@JsonKey(name: 'incurred_on') String? incurredOn,@JsonKey(name: 'reverses_expense_id') int? reversesExpenseId,@JsonKey(name: 'is_reversed') bool isReversed, String? notes,@JsonKey(name: 'recorded_at') String? recordedAt
});




}
/// @nodoc
class __$PoolExpenseCopyWithImpl<$Res>
    implements _$PoolExpenseCopyWith<$Res> {
  __$PoolExpenseCopyWithImpl(this._self, this._then);

  final _PoolExpense _self;
  final $Res Function(_PoolExpense) _then;

/// Create a copy of PoolExpense
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? investorDealId = null,Object? investmentPeriodId = freezed,Object? kind = null,Object? kindLabel = null,Object? name = null,Object? amount = null,Object? isLanded = null,Object? isDeducted = null,Object? incurredOn = freezed,Object? reversesExpenseId = freezed,Object? isReversed = null,Object? notes = freezed,Object? recordedAt = freezed,}) {
  return _then(_PoolExpense(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,investorDealId: null == investorDealId ? _self.investorDealId : investorDealId // ignore: cast_nullable_to_non_nullable
as int,investmentPeriodId: freezed == investmentPeriodId ? _self.investmentPeriodId : investmentPeriodId // ignore: cast_nullable_to_non_nullable
as int?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,kindLabel: null == kindLabel ? _self.kindLabel : kindLabel // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,isLanded: null == isLanded ? _self.isLanded : isLanded // ignore: cast_nullable_to_non_nullable
as bool,isDeducted: null == isDeducted ? _self.isDeducted : isDeducted // ignore: cast_nullable_to_non_nullable
as bool,incurredOn: freezed == incurredOn ? _self.incurredOn : incurredOn // ignore: cast_nullable_to_non_nullable
as String?,reversesExpenseId: freezed == reversesExpenseId ? _self.reversesExpenseId : reversesExpenseId // ignore: cast_nullable_to_non_nullable
as int?,isReversed: null == isReversed ? _self.isReversed : isReversed // ignore: cast_nullable_to_non_nullable
as bool,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,recordedAt: freezed == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
