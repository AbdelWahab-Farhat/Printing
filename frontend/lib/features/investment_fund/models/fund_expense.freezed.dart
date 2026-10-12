// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fund_expense.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FundExpensePeriod {

 int get id; String get code; String get status;@JsonKey(name: 'status_label') String get statusLabel;
/// Create a copy of FundExpensePeriod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundExpensePeriodCopyWith<FundExpensePeriod> get copyWith => _$FundExpensePeriodCopyWithImpl<FundExpensePeriod>(this as FundExpensePeriod, _$identity);

  /// Serializes this FundExpensePeriod to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundExpensePeriod&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,status,statusLabel);

@override
String toString() {
  return 'FundExpensePeriod(id: $id, code: $code, status: $status, statusLabel: $statusLabel)';
}


}

/// @nodoc
abstract mixin class $FundExpensePeriodCopyWith<$Res>  {
  factory $FundExpensePeriodCopyWith(FundExpensePeriod value, $Res Function(FundExpensePeriod) _then) = _$FundExpensePeriodCopyWithImpl;
@useResult
$Res call({
 int id, String code, String status,@JsonKey(name: 'status_label') String statusLabel
});




}
/// @nodoc
class _$FundExpensePeriodCopyWithImpl<$Res>
    implements $FundExpensePeriodCopyWith<$Res> {
  _$FundExpensePeriodCopyWithImpl(this._self, this._then);

  final FundExpensePeriod _self;
  final $Res Function(FundExpensePeriod) _then;

/// Create a copy of FundExpensePeriod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? status = null,Object? statusLabel = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FundExpensePeriod].
extension FundExpensePeriodPatterns on FundExpensePeriod {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundExpensePeriod value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundExpensePeriod() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundExpensePeriod value)  $default,){
final _that = this;
switch (_that) {
case _FundExpensePeriod():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundExpensePeriod value)?  $default,){
final _that = this;
switch (_that) {
case _FundExpensePeriod() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundExpensePeriod() when $default != null:
return $default(_that.id,_that.code,_that.status,_that.statusLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel)  $default,) {final _that = this;
switch (_that) {
case _FundExpensePeriod():
return $default(_that.id,_that.code,_that.status,_that.statusLabel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel)?  $default,) {final _that = this;
switch (_that) {
case _FundExpensePeriod() when $default != null:
return $default(_that.id,_that.code,_that.status,_that.statusLabel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundExpensePeriod implements FundExpensePeriod {
  const _FundExpensePeriod({required this.id, required this.code, required this.status, @JsonKey(name: 'status_label') required this.statusLabel});
  factory _FundExpensePeriod.fromJson(Map<String, dynamic> json) => _$FundExpensePeriodFromJson(json);

@override final  int id;
@override final  String code;
@override final  String status;
@override@JsonKey(name: 'status_label') final  String statusLabel;

/// Create a copy of FundExpensePeriod
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundExpensePeriodCopyWith<_FundExpensePeriod> get copyWith => __$FundExpensePeriodCopyWithImpl<_FundExpensePeriod>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundExpensePeriodToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundExpensePeriod&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,status,statusLabel);

@override
String toString() {
  return 'FundExpensePeriod(id: $id, code: $code, status: $status, statusLabel: $statusLabel)';
}


}

/// @nodoc
abstract mixin class _$FundExpensePeriodCopyWith<$Res> implements $FundExpensePeriodCopyWith<$Res> {
  factory _$FundExpensePeriodCopyWith(_FundExpensePeriod value, $Res Function(_FundExpensePeriod) _then) = __$FundExpensePeriodCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String status,@JsonKey(name: 'status_label') String statusLabel
});




}
/// @nodoc
class __$FundExpensePeriodCopyWithImpl<$Res>
    implements _$FundExpensePeriodCopyWith<$Res> {
  __$FundExpensePeriodCopyWithImpl(this._self, this._then);

  final _FundExpensePeriod _self;
  final $Res Function(_FundExpensePeriod) _then;

/// Create a copy of FundExpensePeriod
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? status = null,Object? statusLabel = null,}) {
  return _then(_FundExpensePeriod(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$FundExpense {

 int get id; String get kind;@JsonKey(name: 'kind_label') String get kindLabel; String get name; String get amount;@JsonKey(name: 'incurred_on') String? get incurredOn; String? get notes;@JsonKey(name: 'treasury_account') PeriodExpenseRef? get treasuryAccount;@JsonKey(name: 'recorded_by') PeriodExpenseRef? get recordedBy;/// `null` لمصروفٍ بتاريخٍ قبل أوّل فترة.
 FundExpensePeriod? get period; bool get counted;/// مؤرّخٌ في فترةٍ أُقفلت وسُجِّل بعد إقفالها — فحُمِّل على المفتوحة يومَ سُجِّل.
@JsonKey(name: 'recorded_after_close') bool get recordedAfterClose;@JsonKey(name: 'is_reversed') bool get isReversed; PeriodExpenseReversal? get reversal;
/// Create a copy of FundExpense
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundExpenseCopyWith<FundExpense> get copyWith => _$FundExpenseCopyWithImpl<FundExpense>(this as FundExpense, _$identity);

  /// Serializes this FundExpense to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundExpense&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.kindLabel, kindLabel) || other.kindLabel == kindLabel)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.incurredOn, incurredOn) || other.incurredOn == incurredOn)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.treasuryAccount, treasuryAccount) || other.treasuryAccount == treasuryAccount)&&(identical(other.recordedBy, recordedBy) || other.recordedBy == recordedBy)&&(identical(other.period, period) || other.period == period)&&(identical(other.counted, counted) || other.counted == counted)&&(identical(other.recordedAfterClose, recordedAfterClose) || other.recordedAfterClose == recordedAfterClose)&&(identical(other.isReversed, isReversed) || other.isReversed == isReversed)&&(identical(other.reversal, reversal) || other.reversal == reversal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,kindLabel,name,amount,incurredOn,notes,treasuryAccount,recordedBy,period,counted,recordedAfterClose,isReversed,reversal);

@override
String toString() {
  return 'FundExpense(id: $id, kind: $kind, kindLabel: $kindLabel, name: $name, amount: $amount, incurredOn: $incurredOn, notes: $notes, treasuryAccount: $treasuryAccount, recordedBy: $recordedBy, period: $period, counted: $counted, recordedAfterClose: $recordedAfterClose, isReversed: $isReversed, reversal: $reversal)';
}


}

/// @nodoc
abstract mixin class $FundExpenseCopyWith<$Res>  {
  factory $FundExpenseCopyWith(FundExpense value, $Res Function(FundExpense) _then) = _$FundExpenseCopyWithImpl;
@useResult
$Res call({
 int id, String kind,@JsonKey(name: 'kind_label') String kindLabel, String name, String amount,@JsonKey(name: 'incurred_on') String? incurredOn, String? notes,@JsonKey(name: 'treasury_account') PeriodExpenseRef? treasuryAccount,@JsonKey(name: 'recorded_by') PeriodExpenseRef? recordedBy, FundExpensePeriod? period, bool counted,@JsonKey(name: 'recorded_after_close') bool recordedAfterClose,@JsonKey(name: 'is_reversed') bool isReversed, PeriodExpenseReversal? reversal
});


$PeriodExpenseRefCopyWith<$Res>? get treasuryAccount;$PeriodExpenseRefCopyWith<$Res>? get recordedBy;$FundExpensePeriodCopyWith<$Res>? get period;$PeriodExpenseReversalCopyWith<$Res>? get reversal;

}
/// @nodoc
class _$FundExpenseCopyWithImpl<$Res>
    implements $FundExpenseCopyWith<$Res> {
  _$FundExpenseCopyWithImpl(this._self, this._then);

  final FundExpense _self;
  final $Res Function(FundExpense) _then;

/// Create a copy of FundExpense
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? kindLabel = null,Object? name = null,Object? amount = null,Object? incurredOn = freezed,Object? notes = freezed,Object? treasuryAccount = freezed,Object? recordedBy = freezed,Object? period = freezed,Object? counted = null,Object? recordedAfterClose = null,Object? isReversed = null,Object? reversal = freezed,}) {
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
as PeriodExpenseRef?,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as FundExpensePeriod?,counted: null == counted ? _self.counted : counted // ignore: cast_nullable_to_non_nullable
as bool,recordedAfterClose: null == recordedAfterClose ? _self.recordedAfterClose : recordedAfterClose // ignore: cast_nullable_to_non_nullable
as bool,isReversed: null == isReversed ? _self.isReversed : isReversed // ignore: cast_nullable_to_non_nullable
as bool,reversal: freezed == reversal ? _self.reversal : reversal // ignore: cast_nullable_to_non_nullable
as PeriodExpenseReversal?,
  ));
}
/// Create a copy of FundExpense
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
}/// Create a copy of FundExpense
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
}/// Create a copy of FundExpense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundExpensePeriodCopyWith<$Res>? get period {
    if (_self.period == null) {
    return null;
  }

  return $FundExpensePeriodCopyWith<$Res>(_self.period!, (value) {
    return _then(_self.copyWith(period: value));
  });
}/// Create a copy of FundExpense
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


/// Adds pattern-matching-related methods to [FundExpense].
extension FundExpensePatterns on FundExpense {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundExpense value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundExpense() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundExpense value)  $default,){
final _that = this;
switch (_that) {
case _FundExpense():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundExpense value)?  $default,){
final _that = this;
switch (_that) {
case _FundExpense() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String kind, @JsonKey(name: 'kind_label')  String kindLabel,  String name,  String amount, @JsonKey(name: 'incurred_on')  String? incurredOn,  String? notes, @JsonKey(name: 'treasury_account')  PeriodExpenseRef? treasuryAccount, @JsonKey(name: 'recorded_by')  PeriodExpenseRef? recordedBy,  FundExpensePeriod? period,  bool counted, @JsonKey(name: 'recorded_after_close')  bool recordedAfterClose, @JsonKey(name: 'is_reversed')  bool isReversed,  PeriodExpenseReversal? reversal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundExpense() when $default != null:
return $default(_that.id,_that.kind,_that.kindLabel,_that.name,_that.amount,_that.incurredOn,_that.notes,_that.treasuryAccount,_that.recordedBy,_that.period,_that.counted,_that.recordedAfterClose,_that.isReversed,_that.reversal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String kind, @JsonKey(name: 'kind_label')  String kindLabel,  String name,  String amount, @JsonKey(name: 'incurred_on')  String? incurredOn,  String? notes, @JsonKey(name: 'treasury_account')  PeriodExpenseRef? treasuryAccount, @JsonKey(name: 'recorded_by')  PeriodExpenseRef? recordedBy,  FundExpensePeriod? period,  bool counted, @JsonKey(name: 'recorded_after_close')  bool recordedAfterClose, @JsonKey(name: 'is_reversed')  bool isReversed,  PeriodExpenseReversal? reversal)  $default,) {final _that = this;
switch (_that) {
case _FundExpense():
return $default(_that.id,_that.kind,_that.kindLabel,_that.name,_that.amount,_that.incurredOn,_that.notes,_that.treasuryAccount,_that.recordedBy,_that.period,_that.counted,_that.recordedAfterClose,_that.isReversed,_that.reversal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String kind, @JsonKey(name: 'kind_label')  String kindLabel,  String name,  String amount, @JsonKey(name: 'incurred_on')  String? incurredOn,  String? notes, @JsonKey(name: 'treasury_account')  PeriodExpenseRef? treasuryAccount, @JsonKey(name: 'recorded_by')  PeriodExpenseRef? recordedBy,  FundExpensePeriod? period,  bool counted, @JsonKey(name: 'recorded_after_close')  bool recordedAfterClose, @JsonKey(name: 'is_reversed')  bool isReversed,  PeriodExpenseReversal? reversal)?  $default,) {final _that = this;
switch (_that) {
case _FundExpense() when $default != null:
return $default(_that.id,_that.kind,_that.kindLabel,_that.name,_that.amount,_that.incurredOn,_that.notes,_that.treasuryAccount,_that.recordedBy,_that.period,_that.counted,_that.recordedAfterClose,_that.isReversed,_that.reversal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundExpense implements FundExpense {
  const _FundExpense({required this.id, required this.kind, @JsonKey(name: 'kind_label') required this.kindLabel, required this.name, required this.amount, @JsonKey(name: 'incurred_on') this.incurredOn, this.notes, @JsonKey(name: 'treasury_account') this.treasuryAccount, @JsonKey(name: 'recorded_by') this.recordedBy, this.period, this.counted = true, @JsonKey(name: 'recorded_after_close') this.recordedAfterClose = false, @JsonKey(name: 'is_reversed') this.isReversed = false, this.reversal});
  factory _FundExpense.fromJson(Map<String, dynamic> json) => _$FundExpenseFromJson(json);

@override final  int id;
@override final  String kind;
@override@JsonKey(name: 'kind_label') final  String kindLabel;
@override final  String name;
@override final  String amount;
@override@JsonKey(name: 'incurred_on') final  String? incurredOn;
@override final  String? notes;
@override@JsonKey(name: 'treasury_account') final  PeriodExpenseRef? treasuryAccount;
@override@JsonKey(name: 'recorded_by') final  PeriodExpenseRef? recordedBy;
/// `null` لمصروفٍ بتاريخٍ قبل أوّل فترة.
@override final  FundExpensePeriod? period;
@override@JsonKey() final  bool counted;
/// مؤرّخٌ في فترةٍ أُقفلت وسُجِّل بعد إقفالها — فحُمِّل على المفتوحة يومَ سُجِّل.
@override@JsonKey(name: 'recorded_after_close') final  bool recordedAfterClose;
@override@JsonKey(name: 'is_reversed') final  bool isReversed;
@override final  PeriodExpenseReversal? reversal;

/// Create a copy of FundExpense
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundExpenseCopyWith<_FundExpense> get copyWith => __$FundExpenseCopyWithImpl<_FundExpense>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundExpenseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundExpense&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.kindLabel, kindLabel) || other.kindLabel == kindLabel)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.incurredOn, incurredOn) || other.incurredOn == incurredOn)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.treasuryAccount, treasuryAccount) || other.treasuryAccount == treasuryAccount)&&(identical(other.recordedBy, recordedBy) || other.recordedBy == recordedBy)&&(identical(other.period, period) || other.period == period)&&(identical(other.counted, counted) || other.counted == counted)&&(identical(other.recordedAfterClose, recordedAfterClose) || other.recordedAfterClose == recordedAfterClose)&&(identical(other.isReversed, isReversed) || other.isReversed == isReversed)&&(identical(other.reversal, reversal) || other.reversal == reversal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,kindLabel,name,amount,incurredOn,notes,treasuryAccount,recordedBy,period,counted,recordedAfterClose,isReversed,reversal);

@override
String toString() {
  return 'FundExpense(id: $id, kind: $kind, kindLabel: $kindLabel, name: $name, amount: $amount, incurredOn: $incurredOn, notes: $notes, treasuryAccount: $treasuryAccount, recordedBy: $recordedBy, period: $period, counted: $counted, recordedAfterClose: $recordedAfterClose, isReversed: $isReversed, reversal: $reversal)';
}


}

/// @nodoc
abstract mixin class _$FundExpenseCopyWith<$Res> implements $FundExpenseCopyWith<$Res> {
  factory _$FundExpenseCopyWith(_FundExpense value, $Res Function(_FundExpense) _then) = __$FundExpenseCopyWithImpl;
@override @useResult
$Res call({
 int id, String kind,@JsonKey(name: 'kind_label') String kindLabel, String name, String amount,@JsonKey(name: 'incurred_on') String? incurredOn, String? notes,@JsonKey(name: 'treasury_account') PeriodExpenseRef? treasuryAccount,@JsonKey(name: 'recorded_by') PeriodExpenseRef? recordedBy, FundExpensePeriod? period, bool counted,@JsonKey(name: 'recorded_after_close') bool recordedAfterClose,@JsonKey(name: 'is_reversed') bool isReversed, PeriodExpenseReversal? reversal
});


@override $PeriodExpenseRefCopyWith<$Res>? get treasuryAccount;@override $PeriodExpenseRefCopyWith<$Res>? get recordedBy;@override $FundExpensePeriodCopyWith<$Res>? get period;@override $PeriodExpenseReversalCopyWith<$Res>? get reversal;

}
/// @nodoc
class __$FundExpenseCopyWithImpl<$Res>
    implements _$FundExpenseCopyWith<$Res> {
  __$FundExpenseCopyWithImpl(this._self, this._then);

  final _FundExpense _self;
  final $Res Function(_FundExpense) _then;

/// Create a copy of FundExpense
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? kindLabel = null,Object? name = null,Object? amount = null,Object? incurredOn = freezed,Object? notes = freezed,Object? treasuryAccount = freezed,Object? recordedBy = freezed,Object? period = freezed,Object? counted = null,Object? recordedAfterClose = null,Object? isReversed = null,Object? reversal = freezed,}) {
  return _then(_FundExpense(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,kindLabel: null == kindLabel ? _self.kindLabel : kindLabel // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,incurredOn: freezed == incurredOn ? _self.incurredOn : incurredOn // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,treasuryAccount: freezed == treasuryAccount ? _self.treasuryAccount : treasuryAccount // ignore: cast_nullable_to_non_nullable
as PeriodExpenseRef?,recordedBy: freezed == recordedBy ? _self.recordedBy : recordedBy // ignore: cast_nullable_to_non_nullable
as PeriodExpenseRef?,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as FundExpensePeriod?,counted: null == counted ? _self.counted : counted // ignore: cast_nullable_to_non_nullable
as bool,recordedAfterClose: null == recordedAfterClose ? _self.recordedAfterClose : recordedAfterClose // ignore: cast_nullable_to_non_nullable
as bool,isReversed: null == isReversed ? _self.isReversed : isReversed // ignore: cast_nullable_to_non_nullable
as bool,reversal: freezed == reversal ? _self.reversal : reversal // ignore: cast_nullable_to_non_nullable
as PeriodExpenseReversal?,
  ));
}

/// Create a copy of FundExpense
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
}/// Create a copy of FundExpense
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
}/// Create a copy of FundExpense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundExpensePeriodCopyWith<$Res>? get period {
    if (_self.period == null) {
    return null;
  }

  return $FundExpensePeriodCopyWith<$Res>(_self.period!, (value) {
    return _then(_self.copyWith(period: value));
  });
}/// Create a copy of FundExpense
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

// dart format on
