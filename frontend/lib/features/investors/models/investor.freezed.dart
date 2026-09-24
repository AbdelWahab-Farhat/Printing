// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'investor.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Investor {

 int get id;/// «I7» — what staff say out loud and what he quotes on the phone.
 String get code; String get name; String? get phone; String? get notes;@JsonKey(name: 'is_active') bool get isActive;/// Whether he has an account he can sign in with.
@JsonKey(name: 'has_login') bool get hasLogin;/// What he has with us and what he has earned — sent with the list, so the register can draw
/// two numbers without opening anybody's screen.
 InvestorTotals? get totals;/// Present on the detail screen only — a list of fifty investors does not walk fifty
/// ledgers to draw a table.
 InvestorBalances? get balances;/// **الأرقامُ الثلاثة** — على صفحته وحدها، كما `balances`.
@JsonKey(name: 'profit_figures') ProfitFigures? get profitFigures;/// **مالُه في الصندوق** — على صفحته وحدها كذلك. الصندوقُ ليس من [InvestorBalances.deals]
/// عمداً، وهذا ما يقوله بدلاً منه.
 FundShare? get fund;/// **فتراتُه، الأحدثُ أوّلاً** — على صفحته وحدها، في مكان الصفقات: «عرض الفترات بدلا من
/// الصفقات» (2026-09-25).
 List<InvestorPeriod> get periods;
/// Create a copy of Investor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestorCopyWith<Investor> get copyWith => _$InvestorCopyWithImpl<Investor>(this as Investor, _$identity);

  /// Serializes this Investor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Investor&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.hasLogin, hasLogin) || other.hasLogin == hasLogin)&&(identical(other.totals, totals) || other.totals == totals)&&(identical(other.balances, balances) || other.balances == balances)&&(identical(other.profitFigures, profitFigures) || other.profitFigures == profitFigures)&&(identical(other.fund, fund) || other.fund == fund)&&const DeepCollectionEquality().equals(other.periods, periods));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,phone,notes,isActive,hasLogin,totals,balances,profitFigures,fund,const DeepCollectionEquality().hash(periods));

@override
String toString() {
  return 'Investor(id: $id, code: $code, name: $name, phone: $phone, notes: $notes, isActive: $isActive, hasLogin: $hasLogin, totals: $totals, balances: $balances, profitFigures: $profitFigures, fund: $fund, periods: $periods)';
}


}

/// @nodoc
abstract mixin class $InvestorCopyWith<$Res>  {
  factory $InvestorCopyWith(Investor value, $Res Function(Investor) _then) = _$InvestorCopyWithImpl;
@useResult
$Res call({
 int id, String code, String name, String? phone, String? notes,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'has_login') bool hasLogin, InvestorTotals? totals, InvestorBalances? balances,@JsonKey(name: 'profit_figures') ProfitFigures? profitFigures, FundShare? fund, List<InvestorPeriod> periods
});


$InvestorTotalsCopyWith<$Res>? get totals;$InvestorBalancesCopyWith<$Res>? get balances;$ProfitFiguresCopyWith<$Res>? get profitFigures;$FundShareCopyWith<$Res>? get fund;

}
/// @nodoc
class _$InvestorCopyWithImpl<$Res>
    implements $InvestorCopyWith<$Res> {
  _$InvestorCopyWithImpl(this._self, this._then);

  final Investor _self;
  final $Res Function(Investor) _then;

/// Create a copy of Investor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? name = null,Object? phone = freezed,Object? notes = freezed,Object? isActive = null,Object? hasLogin = null,Object? totals = freezed,Object? balances = freezed,Object? profitFigures = freezed,Object? fund = freezed,Object? periods = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,hasLogin: null == hasLogin ? _self.hasLogin : hasLogin // ignore: cast_nullable_to_non_nullable
as bool,totals: freezed == totals ? _self.totals : totals // ignore: cast_nullable_to_non_nullable
as InvestorTotals?,balances: freezed == balances ? _self.balances : balances // ignore: cast_nullable_to_non_nullable
as InvestorBalances?,profitFigures: freezed == profitFigures ? _self.profitFigures : profitFigures // ignore: cast_nullable_to_non_nullable
as ProfitFigures?,fund: freezed == fund ? _self.fund : fund // ignore: cast_nullable_to_non_nullable
as FundShare?,periods: null == periods ? _self.periods : periods // ignore: cast_nullable_to_non_nullable
as List<InvestorPeriod>,
  ));
}
/// Create a copy of Investor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvestorTotalsCopyWith<$Res>? get totals {
    if (_self.totals == null) {
    return null;
  }

  return $InvestorTotalsCopyWith<$Res>(_self.totals!, (value) {
    return _then(_self.copyWith(totals: value));
  });
}/// Create a copy of Investor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvestorBalancesCopyWith<$Res>? get balances {
    if (_self.balances == null) {
    return null;
  }

  return $InvestorBalancesCopyWith<$Res>(_self.balances!, (value) {
    return _then(_self.copyWith(balances: value));
  });
}/// Create a copy of Investor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfitFiguresCopyWith<$Res>? get profitFigures {
    if (_self.profitFigures == null) {
    return null;
  }

  return $ProfitFiguresCopyWith<$Res>(_self.profitFigures!, (value) {
    return _then(_self.copyWith(profitFigures: value));
  });
}/// Create a copy of Investor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundShareCopyWith<$Res>? get fund {
    if (_self.fund == null) {
    return null;
  }

  return $FundShareCopyWith<$Res>(_self.fund!, (value) {
    return _then(_self.copyWith(fund: value));
  });
}
}


/// Adds pattern-matching-related methods to [Investor].
extension InvestorPatterns on Investor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Investor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Investor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Investor value)  $default,){
final _that = this;
switch (_that) {
case _Investor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Investor value)?  $default,){
final _that = this;
switch (_that) {
case _Investor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String name,  String? phone,  String? notes, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'has_login')  bool hasLogin,  InvestorTotals? totals,  InvestorBalances? balances, @JsonKey(name: 'profit_figures')  ProfitFigures? profitFigures,  FundShare? fund,  List<InvestorPeriod> periods)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Investor() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.phone,_that.notes,_that.isActive,_that.hasLogin,_that.totals,_that.balances,_that.profitFigures,_that.fund,_that.periods);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String name,  String? phone,  String? notes, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'has_login')  bool hasLogin,  InvestorTotals? totals,  InvestorBalances? balances, @JsonKey(name: 'profit_figures')  ProfitFigures? profitFigures,  FundShare? fund,  List<InvestorPeriod> periods)  $default,) {final _that = this;
switch (_that) {
case _Investor():
return $default(_that.id,_that.code,_that.name,_that.phone,_that.notes,_that.isActive,_that.hasLogin,_that.totals,_that.balances,_that.profitFigures,_that.fund,_that.periods);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String name,  String? phone,  String? notes, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'has_login')  bool hasLogin,  InvestorTotals? totals,  InvestorBalances? balances, @JsonKey(name: 'profit_figures')  ProfitFigures? profitFigures,  FundShare? fund,  List<InvestorPeriod> periods)?  $default,) {final _that = this;
switch (_that) {
case _Investor() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.phone,_that.notes,_that.isActive,_that.hasLogin,_that.totals,_that.balances,_that.profitFigures,_that.fund,_that.periods);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Investor implements Investor {
  const _Investor({required this.id, required this.code, required this.name, this.phone, this.notes, @JsonKey(name: 'is_active') this.isActive = true, @JsonKey(name: 'has_login') this.hasLogin = false, this.totals, this.balances, @JsonKey(name: 'profit_figures') this.profitFigures, this.fund, final  List<InvestorPeriod> periods = const <InvestorPeriod>[]}): _periods = periods;
  factory _Investor.fromJson(Map<String, dynamic> json) => _$InvestorFromJson(json);

@override final  int id;
/// «I7» — what staff say out loud and what he quotes on the phone.
@override final  String code;
@override final  String name;
@override final  String? phone;
@override final  String? notes;
@override@JsonKey(name: 'is_active') final  bool isActive;
/// Whether he has an account he can sign in with.
@override@JsonKey(name: 'has_login') final  bool hasLogin;
/// What he has with us and what he has earned — sent with the list, so the register can draw
/// two numbers without opening anybody's screen.
@override final  InvestorTotals? totals;
/// Present on the detail screen only — a list of fifty investors does not walk fifty
/// ledgers to draw a table.
@override final  InvestorBalances? balances;
/// **الأرقامُ الثلاثة** — على صفحته وحدها، كما `balances`.
@override@JsonKey(name: 'profit_figures') final  ProfitFigures? profitFigures;
/// **مالُه في الصندوق** — على صفحته وحدها كذلك. الصندوقُ ليس من [InvestorBalances.deals]
/// عمداً، وهذا ما يقوله بدلاً منه.
@override final  FundShare? fund;
/// **فتراتُه، الأحدثُ أوّلاً** — على صفحته وحدها، في مكان الصفقات: «عرض الفترات بدلا من
/// الصفقات» (2026-09-25).
 final  List<InvestorPeriod> _periods;
/// **فتراتُه، الأحدثُ أوّلاً** — على صفحته وحدها، في مكان الصفقات: «عرض الفترات بدلا من
/// الصفقات» (2026-09-25).
@override@JsonKey() List<InvestorPeriod> get periods {
  if (_periods is EqualUnmodifiableListView) return _periods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_periods);
}


/// Create a copy of Investor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvestorCopyWith<_Investor> get copyWith => __$InvestorCopyWithImpl<_Investor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvestorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Investor&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.hasLogin, hasLogin) || other.hasLogin == hasLogin)&&(identical(other.totals, totals) || other.totals == totals)&&(identical(other.balances, balances) || other.balances == balances)&&(identical(other.profitFigures, profitFigures) || other.profitFigures == profitFigures)&&(identical(other.fund, fund) || other.fund == fund)&&const DeepCollectionEquality().equals(other._periods, _periods));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,phone,notes,isActive,hasLogin,totals,balances,profitFigures,fund,const DeepCollectionEquality().hash(_periods));

@override
String toString() {
  return 'Investor(id: $id, code: $code, name: $name, phone: $phone, notes: $notes, isActive: $isActive, hasLogin: $hasLogin, totals: $totals, balances: $balances, profitFigures: $profitFigures, fund: $fund, periods: $periods)';
}


}

/// @nodoc
abstract mixin class _$InvestorCopyWith<$Res> implements $InvestorCopyWith<$Res> {
  factory _$InvestorCopyWith(_Investor value, $Res Function(_Investor) _then) = __$InvestorCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String name, String? phone, String? notes,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'has_login') bool hasLogin, InvestorTotals? totals, InvestorBalances? balances,@JsonKey(name: 'profit_figures') ProfitFigures? profitFigures, FundShare? fund, List<InvestorPeriod> periods
});


@override $InvestorTotalsCopyWith<$Res>? get totals;@override $InvestorBalancesCopyWith<$Res>? get balances;@override $ProfitFiguresCopyWith<$Res>? get profitFigures;@override $FundShareCopyWith<$Res>? get fund;

}
/// @nodoc
class __$InvestorCopyWithImpl<$Res>
    implements _$InvestorCopyWith<$Res> {
  __$InvestorCopyWithImpl(this._self, this._then);

  final _Investor _self;
  final $Res Function(_Investor) _then;

/// Create a copy of Investor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,Object? phone = freezed,Object? notes = freezed,Object? isActive = null,Object? hasLogin = null,Object? totals = freezed,Object? balances = freezed,Object? profitFigures = freezed,Object? fund = freezed,Object? periods = null,}) {
  return _then(_Investor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,hasLogin: null == hasLogin ? _self.hasLogin : hasLogin // ignore: cast_nullable_to_non_nullable
as bool,totals: freezed == totals ? _self.totals : totals // ignore: cast_nullable_to_non_nullable
as InvestorTotals?,balances: freezed == balances ? _self.balances : balances // ignore: cast_nullable_to_non_nullable
as InvestorBalances?,profitFigures: freezed == profitFigures ? _self.profitFigures : profitFigures // ignore: cast_nullable_to_non_nullable
as ProfitFigures?,fund: freezed == fund ? _self.fund : fund // ignore: cast_nullable_to_non_nullable
as FundShare?,periods: null == periods ? _self._periods : periods // ignore: cast_nullable_to_non_nullable
as List<InvestorPeriod>,
  ));
}

/// Create a copy of Investor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvestorTotalsCopyWith<$Res>? get totals {
    if (_self.totals == null) {
    return null;
  }

  return $InvestorTotalsCopyWith<$Res>(_self.totals!, (value) {
    return _then(_self.copyWith(totals: value));
  });
}/// Create a copy of Investor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvestorBalancesCopyWith<$Res>? get balances {
    if (_self.balances == null) {
    return null;
  }

  return $InvestorBalancesCopyWith<$Res>(_self.balances!, (value) {
    return _then(_self.copyWith(balances: value));
  });
}/// Create a copy of Investor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfitFiguresCopyWith<$Res>? get profitFigures {
    if (_self.profitFigures == null) {
    return null;
  }

  return $ProfitFiguresCopyWith<$Res>(_self.profitFigures!, (value) {
    return _then(_self.copyWith(profitFigures: value));
  });
}/// Create a copy of Investor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundShareCopyWith<$Res>? get fund {
    if (_self.fund == null) {
    return null;
  }

  return $FundShareCopyWith<$Res>(_self.fund!, (value) {
    return _then(_self.copyWith(fund: value));
  });
}
}


/// @nodoc
mixin _$InvestorPeriod {

 int get id; String get code;/// سالبٌ في فترةٍ خسر فيها.
 String get profit;
/// Create a copy of InvestorPeriod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestorPeriodCopyWith<InvestorPeriod> get copyWith => _$InvestorPeriodCopyWithImpl<InvestorPeriod>(this as InvestorPeriod, _$identity);

  /// Serializes this InvestorPeriod to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestorPeriod&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.profit, profit) || other.profit == profit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,profit);

@override
String toString() {
  return 'InvestorPeriod(id: $id, code: $code, profit: $profit)';
}


}

/// @nodoc
abstract mixin class $InvestorPeriodCopyWith<$Res>  {
  factory $InvestorPeriodCopyWith(InvestorPeriod value, $Res Function(InvestorPeriod) _then) = _$InvestorPeriodCopyWithImpl;
@useResult
$Res call({
 int id, String code, String profit
});




}
/// @nodoc
class _$InvestorPeriodCopyWithImpl<$Res>
    implements $InvestorPeriodCopyWith<$Res> {
  _$InvestorPeriodCopyWithImpl(this._self, this._then);

  final InvestorPeriod _self;
  final $Res Function(InvestorPeriod) _then;

/// Create a copy of InvestorPeriod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? profit = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [InvestorPeriod].
extension InvestorPeriodPatterns on InvestorPeriod {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvestorPeriod value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvestorPeriod() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvestorPeriod value)  $default,){
final _that = this;
switch (_that) {
case _InvestorPeriod():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvestorPeriod value)?  $default,){
final _that = this;
switch (_that) {
case _InvestorPeriod() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String profit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvestorPeriod() when $default != null:
return $default(_that.id,_that.code,_that.profit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String profit)  $default,) {final _that = this;
switch (_that) {
case _InvestorPeriod():
return $default(_that.id,_that.code,_that.profit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String profit)?  $default,) {final _that = this;
switch (_that) {
case _InvestorPeriod() when $default != null:
return $default(_that.id,_that.code,_that.profit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvestorPeriod implements InvestorPeriod {
  const _InvestorPeriod({required this.id, required this.code, required this.profit});
  factory _InvestorPeriod.fromJson(Map<String, dynamic> json) => _$InvestorPeriodFromJson(json);

@override final  int id;
@override final  String code;
/// سالبٌ في فترةٍ خسر فيها.
@override final  String profit;

/// Create a copy of InvestorPeriod
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvestorPeriodCopyWith<_InvestorPeriod> get copyWith => __$InvestorPeriodCopyWithImpl<_InvestorPeriod>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvestorPeriodToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvestorPeriod&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.profit, profit) || other.profit == profit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,profit);

@override
String toString() {
  return 'InvestorPeriod(id: $id, code: $code, profit: $profit)';
}


}

/// @nodoc
abstract mixin class _$InvestorPeriodCopyWith<$Res> implements $InvestorPeriodCopyWith<$Res> {
  factory _$InvestorPeriodCopyWith(_InvestorPeriod value, $Res Function(_InvestorPeriod) _then) = __$InvestorPeriodCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String profit
});




}
/// @nodoc
class __$InvestorPeriodCopyWithImpl<$Res>
    implements _$InvestorPeriodCopyWith<$Res> {
  __$InvestorPeriodCopyWithImpl(this._self, this._then);

  final _InvestorPeriod _self;
  final $Res Function(_InvestorPeriod) _then;

/// Create a copy of InvestorPeriod
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? profit = null,}) {
  return _then(_InvestorPeriod(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$InvestorBalances {

 WalletPots get wallet;/// **A list whose rows name their own deal**, not a map keyed by id: an integer-keyed map
/// does not survive the trip through JSON as an object, and a silently re-indexed map puts
/// the right figures against the wrong deal.
 List<DealPots> get deals;
/// Create a copy of InvestorBalances
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestorBalancesCopyWith<InvestorBalances> get copyWith => _$InvestorBalancesCopyWithImpl<InvestorBalances>(this as InvestorBalances, _$identity);

  /// Serializes this InvestorBalances to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestorBalances&&(identical(other.wallet, wallet) || other.wallet == wallet)&&const DeepCollectionEquality().equals(other.deals, deals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,wallet,const DeepCollectionEquality().hash(deals));

@override
String toString() {
  return 'InvestorBalances(wallet: $wallet, deals: $deals)';
}


}

/// @nodoc
abstract mixin class $InvestorBalancesCopyWith<$Res>  {
  factory $InvestorBalancesCopyWith(InvestorBalances value, $Res Function(InvestorBalances) _then) = _$InvestorBalancesCopyWithImpl;
@useResult
$Res call({
 WalletPots wallet, List<DealPots> deals
});


$WalletPotsCopyWith<$Res> get wallet;

}
/// @nodoc
class _$InvestorBalancesCopyWithImpl<$Res>
    implements $InvestorBalancesCopyWith<$Res> {
  _$InvestorBalancesCopyWithImpl(this._self, this._then);

  final InvestorBalances _self;
  final $Res Function(InvestorBalances) _then;

/// Create a copy of InvestorBalances
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? wallet = null,Object? deals = null,}) {
  return _then(_self.copyWith(
wallet: null == wallet ? _self.wallet : wallet // ignore: cast_nullable_to_non_nullable
as WalletPots,deals: null == deals ? _self.deals : deals // ignore: cast_nullable_to_non_nullable
as List<DealPots>,
  ));
}
/// Create a copy of InvestorBalances
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletPotsCopyWith<$Res> get wallet {
  
  return $WalletPotsCopyWith<$Res>(_self.wallet, (value) {
    return _then(_self.copyWith(wallet: value));
  });
}
}


/// Adds pattern-matching-related methods to [InvestorBalances].
extension InvestorBalancesPatterns on InvestorBalances {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvestorBalances value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvestorBalances() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvestorBalances value)  $default,){
final _that = this;
switch (_that) {
case _InvestorBalances():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvestorBalances value)?  $default,){
final _that = this;
switch (_that) {
case _InvestorBalances() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WalletPots wallet,  List<DealPots> deals)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvestorBalances() when $default != null:
return $default(_that.wallet,_that.deals);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WalletPots wallet,  List<DealPots> deals)  $default,) {final _that = this;
switch (_that) {
case _InvestorBalances():
return $default(_that.wallet,_that.deals);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WalletPots wallet,  List<DealPots> deals)?  $default,) {final _that = this;
switch (_that) {
case _InvestorBalances() when $default != null:
return $default(_that.wallet,_that.deals);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvestorBalances implements InvestorBalances {
  const _InvestorBalances({required this.wallet, final  List<DealPots> deals = const <DealPots>[]}): _deals = deals;
  factory _InvestorBalances.fromJson(Map<String, dynamic> json) => _$InvestorBalancesFromJson(json);

@override final  WalletPots wallet;
/// **A list whose rows name their own deal**, not a map keyed by id: an integer-keyed map
/// does not survive the trip through JSON as an object, and a silently re-indexed map puts
/// the right figures against the wrong deal.
 final  List<DealPots> _deals;
/// **A list whose rows name their own deal**, not a map keyed by id: an integer-keyed map
/// does not survive the trip through JSON as an object, and a silently re-indexed map puts
/// the right figures against the wrong deal.
@override@JsonKey() List<DealPots> get deals {
  if (_deals is EqualUnmodifiableListView) return _deals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deals);
}


/// Create a copy of InvestorBalances
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvestorBalancesCopyWith<_InvestorBalances> get copyWith => __$InvestorBalancesCopyWithImpl<_InvestorBalances>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvestorBalancesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvestorBalances&&(identical(other.wallet, wallet) || other.wallet == wallet)&&const DeepCollectionEquality().equals(other._deals, _deals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,wallet,const DeepCollectionEquality().hash(_deals));

@override
String toString() {
  return 'InvestorBalances(wallet: $wallet, deals: $deals)';
}


}

/// @nodoc
abstract mixin class _$InvestorBalancesCopyWith<$Res> implements $InvestorBalancesCopyWith<$Res> {
  factory _$InvestorBalancesCopyWith(_InvestorBalances value, $Res Function(_InvestorBalances) _then) = __$InvestorBalancesCopyWithImpl;
@override @useResult
$Res call({
 WalletPots wallet, List<DealPots> deals
});


@override $WalletPotsCopyWith<$Res> get wallet;

}
/// @nodoc
class __$InvestorBalancesCopyWithImpl<$Res>
    implements _$InvestorBalancesCopyWith<$Res> {
  __$InvestorBalancesCopyWithImpl(this._self, this._then);

  final _InvestorBalances _self;
  final $Res Function(_InvestorBalances) _then;

/// Create a copy of InvestorBalances
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? wallet = null,Object? deals = null,}) {
  return _then(_InvestorBalances(
wallet: null == wallet ? _self.wallet : wallet // ignore: cast_nullable_to_non_nullable
as WalletPots,deals: null == deals ? _self._deals : deals // ignore: cast_nullable_to_non_nullable
as List<DealPots>,
  ));
}

/// Create a copy of InvestorBalances
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletPotsCopyWith<$Res> get wallet {
  
  return $WalletPotsCopyWith<$Res>(_self.wallet, (value) {
    return _then(_self.copyWith(wallet: value));
  });
}
}


/// @nodoc
mixin _$WalletPots {

/// Money with the company, committed to nothing.
 String get capital;/// Profit released by a closed deal — the only profit a withdrawal can draw on.
 String get profit;
/// Create a copy of WalletPots
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletPotsCopyWith<WalletPots> get copyWith => _$WalletPotsCopyWithImpl<WalletPots>(this as WalletPots, _$identity);

  /// Serializes this WalletPots to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletPots&&(identical(other.capital, capital) || other.capital == capital)&&(identical(other.profit, profit) || other.profit == profit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,capital,profit);

@override
String toString() {
  return 'WalletPots(capital: $capital, profit: $profit)';
}


}

/// @nodoc
abstract mixin class $WalletPotsCopyWith<$Res>  {
  factory $WalletPotsCopyWith(WalletPots value, $Res Function(WalletPots) _then) = _$WalletPotsCopyWithImpl;
@useResult
$Res call({
 String capital, String profit
});




}
/// @nodoc
class _$WalletPotsCopyWithImpl<$Res>
    implements $WalletPotsCopyWith<$Res> {
  _$WalletPotsCopyWithImpl(this._self, this._then);

  final WalletPots _self;
  final $Res Function(WalletPots) _then;

/// Create a copy of WalletPots
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? capital = null,Object? profit = null,}) {
  return _then(_self.copyWith(
capital: null == capital ? _self.capital : capital // ignore: cast_nullable_to_non_nullable
as String,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WalletPots].
extension WalletPotsPatterns on WalletPots {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletPots value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletPots() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletPots value)  $default,){
final _that = this;
switch (_that) {
case _WalletPots():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletPots value)?  $default,){
final _that = this;
switch (_that) {
case _WalletPots() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String capital,  String profit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletPots() when $default != null:
return $default(_that.capital,_that.profit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String capital,  String profit)  $default,) {final _that = this;
switch (_that) {
case _WalletPots():
return $default(_that.capital,_that.profit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String capital,  String profit)?  $default,) {final _that = this;
switch (_that) {
case _WalletPots() when $default != null:
return $default(_that.capital,_that.profit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WalletPots implements WalletPots {
  const _WalletPots({required this.capital, required this.profit});
  factory _WalletPots.fromJson(Map<String, dynamic> json) => _$WalletPotsFromJson(json);

/// Money with the company, committed to nothing.
@override final  String capital;
/// Profit released by a closed deal — the only profit a withdrawal can draw on.
@override final  String profit;

/// Create a copy of WalletPots
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletPotsCopyWith<_WalletPots> get copyWith => __$WalletPotsCopyWithImpl<_WalletPots>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WalletPotsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletPots&&(identical(other.capital, capital) || other.capital == capital)&&(identical(other.profit, profit) || other.profit == profit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,capital,profit);

@override
String toString() {
  return 'WalletPots(capital: $capital, profit: $profit)';
}


}

/// @nodoc
abstract mixin class _$WalletPotsCopyWith<$Res> implements $WalletPotsCopyWith<$Res> {
  factory _$WalletPotsCopyWith(_WalletPots value, $Res Function(_WalletPots) _then) = __$WalletPotsCopyWithImpl;
@override @useResult
$Res call({
 String capital, String profit
});




}
/// @nodoc
class __$WalletPotsCopyWithImpl<$Res>
    implements _$WalletPotsCopyWith<$Res> {
  __$WalletPotsCopyWithImpl(this._self, this._then);

  final _WalletPots _self;
  final $Res Function(_WalletPots) _then;

/// Create a copy of WalletPots
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? capital = null,Object? profit = null,}) {
  return _then(_WalletPots(
capital: null == capital ? _self.capital : capital // ignore: cast_nullable_to_non_nullable
as String,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DealPots {

@JsonKey(name: 'investor_deal_id') int get investorDealId;/// What he has financing goods in this deal.
 String get capital;/// What it has earned him so far. Not withdrawable until the deal closes.
 String get profit;
/// Create a copy of DealPots
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DealPotsCopyWith<DealPots> get copyWith => _$DealPotsCopyWithImpl<DealPots>(this as DealPots, _$identity);

  /// Serializes this DealPots to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DealPots&&(identical(other.investorDealId, investorDealId) || other.investorDealId == investorDealId)&&(identical(other.capital, capital) || other.capital == capital)&&(identical(other.profit, profit) || other.profit == profit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,investorDealId,capital,profit);

@override
String toString() {
  return 'DealPots(investorDealId: $investorDealId, capital: $capital, profit: $profit)';
}


}

/// @nodoc
abstract mixin class $DealPotsCopyWith<$Res>  {
  factory $DealPotsCopyWith(DealPots value, $Res Function(DealPots) _then) = _$DealPotsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'investor_deal_id') int investorDealId, String capital, String profit
});




}
/// @nodoc
class _$DealPotsCopyWithImpl<$Res>
    implements $DealPotsCopyWith<$Res> {
  _$DealPotsCopyWithImpl(this._self, this._then);

  final DealPots _self;
  final $Res Function(DealPots) _then;

/// Create a copy of DealPots
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? investorDealId = null,Object? capital = null,Object? profit = null,}) {
  return _then(_self.copyWith(
investorDealId: null == investorDealId ? _self.investorDealId : investorDealId // ignore: cast_nullable_to_non_nullable
as int,capital: null == capital ? _self.capital : capital // ignore: cast_nullable_to_non_nullable
as String,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DealPots].
extension DealPotsPatterns on DealPots {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DealPots value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DealPots() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DealPots value)  $default,){
final _that = this;
switch (_that) {
case _DealPots():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DealPots value)?  $default,){
final _that = this;
switch (_that) {
case _DealPots() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'investor_deal_id')  int investorDealId,  String capital,  String profit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DealPots() when $default != null:
return $default(_that.investorDealId,_that.capital,_that.profit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'investor_deal_id')  int investorDealId,  String capital,  String profit)  $default,) {final _that = this;
switch (_that) {
case _DealPots():
return $default(_that.investorDealId,_that.capital,_that.profit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'investor_deal_id')  int investorDealId,  String capital,  String profit)?  $default,) {final _that = this;
switch (_that) {
case _DealPots() when $default != null:
return $default(_that.investorDealId,_that.capital,_that.profit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DealPots implements DealPots {
  const _DealPots({@JsonKey(name: 'investor_deal_id') required this.investorDealId, required this.capital, required this.profit});
  factory _DealPots.fromJson(Map<String, dynamic> json) => _$DealPotsFromJson(json);

@override@JsonKey(name: 'investor_deal_id') final  int investorDealId;
/// What he has financing goods in this deal.
@override final  String capital;
/// What it has earned him so far. Not withdrawable until the deal closes.
@override final  String profit;

/// Create a copy of DealPots
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DealPotsCopyWith<_DealPots> get copyWith => __$DealPotsCopyWithImpl<_DealPots>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DealPotsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DealPots&&(identical(other.investorDealId, investorDealId) || other.investorDealId == investorDealId)&&(identical(other.capital, capital) || other.capital == capital)&&(identical(other.profit, profit) || other.profit == profit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,investorDealId,capital,profit);

@override
String toString() {
  return 'DealPots(investorDealId: $investorDealId, capital: $capital, profit: $profit)';
}


}

/// @nodoc
abstract mixin class _$DealPotsCopyWith<$Res> implements $DealPotsCopyWith<$Res> {
  factory _$DealPotsCopyWith(_DealPots value, $Res Function(_DealPots) _then) = __$DealPotsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'investor_deal_id') int investorDealId, String capital, String profit
});




}
/// @nodoc
class __$DealPotsCopyWithImpl<$Res>
    implements _$DealPotsCopyWith<$Res> {
  __$DealPotsCopyWithImpl(this._self, this._then);

  final _DealPots _self;
  final $Res Function(_DealPots) _then;

/// Create a copy of DealPots
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? investorDealId = null,Object? capital = null,Object? profit = null,}) {
  return _then(_DealPots(
investorDealId: null == investorDealId ? _self.investorDealId : investorDealId // ignore: cast_nullable_to_non_nullable
as int,capital: null == capital ? _self.capital : capital // ignore: cast_nullable_to_non_nullable
as String,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$InvestorTotals {

 String get capital; String get profit;@JsonKey(name: 'wallet_capital') String get walletCapital;@JsonKey(name: 'wallet_profit') String get walletProfit;
/// Create a copy of InvestorTotals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestorTotalsCopyWith<InvestorTotals> get copyWith => _$InvestorTotalsCopyWithImpl<InvestorTotals>(this as InvestorTotals, _$identity);

  /// Serializes this InvestorTotals to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestorTotals&&(identical(other.capital, capital) || other.capital == capital)&&(identical(other.profit, profit) || other.profit == profit)&&(identical(other.walletCapital, walletCapital) || other.walletCapital == walletCapital)&&(identical(other.walletProfit, walletProfit) || other.walletProfit == walletProfit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,capital,profit,walletCapital,walletProfit);

@override
String toString() {
  return 'InvestorTotals(capital: $capital, profit: $profit, walletCapital: $walletCapital, walletProfit: $walletProfit)';
}


}

/// @nodoc
abstract mixin class $InvestorTotalsCopyWith<$Res>  {
  factory $InvestorTotalsCopyWith(InvestorTotals value, $Res Function(InvestorTotals) _then) = _$InvestorTotalsCopyWithImpl;
@useResult
$Res call({
 String capital, String profit,@JsonKey(name: 'wallet_capital') String walletCapital,@JsonKey(name: 'wallet_profit') String walletProfit
});




}
/// @nodoc
class _$InvestorTotalsCopyWithImpl<$Res>
    implements $InvestorTotalsCopyWith<$Res> {
  _$InvestorTotalsCopyWithImpl(this._self, this._then);

  final InvestorTotals _self;
  final $Res Function(InvestorTotals) _then;

/// Create a copy of InvestorTotals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? capital = null,Object? profit = null,Object? walletCapital = null,Object? walletProfit = null,}) {
  return _then(_self.copyWith(
capital: null == capital ? _self.capital : capital // ignore: cast_nullable_to_non_nullable
as String,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as String,walletCapital: null == walletCapital ? _self.walletCapital : walletCapital // ignore: cast_nullable_to_non_nullable
as String,walletProfit: null == walletProfit ? _self.walletProfit : walletProfit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [InvestorTotals].
extension InvestorTotalsPatterns on InvestorTotals {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvestorTotals value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvestorTotals() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvestorTotals value)  $default,){
final _that = this;
switch (_that) {
case _InvestorTotals():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvestorTotals value)?  $default,){
final _that = this;
switch (_that) {
case _InvestorTotals() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String capital,  String profit, @JsonKey(name: 'wallet_capital')  String walletCapital, @JsonKey(name: 'wallet_profit')  String walletProfit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvestorTotals() when $default != null:
return $default(_that.capital,_that.profit,_that.walletCapital,_that.walletProfit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String capital,  String profit, @JsonKey(name: 'wallet_capital')  String walletCapital, @JsonKey(name: 'wallet_profit')  String walletProfit)  $default,) {final _that = this;
switch (_that) {
case _InvestorTotals():
return $default(_that.capital,_that.profit,_that.walletCapital,_that.walletProfit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String capital,  String profit, @JsonKey(name: 'wallet_capital')  String walletCapital, @JsonKey(name: 'wallet_profit')  String walletProfit)?  $default,) {final _that = this;
switch (_that) {
case _InvestorTotals() when $default != null:
return $default(_that.capital,_that.profit,_that.walletCapital,_that.walletProfit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvestorTotals extends InvestorTotals {
  const _InvestorTotals({required this.capital, required this.profit, @JsonKey(name: 'wallet_capital') required this.walletCapital, @JsonKey(name: 'wallet_profit') required this.walletProfit}): super._();
  factory _InvestorTotals.fromJson(Map<String, dynamic> json) => _$InvestorTotalsFromJson(json);

@override final  String capital;
@override final  String profit;
@override@JsonKey(name: 'wallet_capital') final  String walletCapital;
@override@JsonKey(name: 'wallet_profit') final  String walletProfit;

/// Create a copy of InvestorTotals
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvestorTotalsCopyWith<_InvestorTotals> get copyWith => __$InvestorTotalsCopyWithImpl<_InvestorTotals>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvestorTotalsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvestorTotals&&(identical(other.capital, capital) || other.capital == capital)&&(identical(other.profit, profit) || other.profit == profit)&&(identical(other.walletCapital, walletCapital) || other.walletCapital == walletCapital)&&(identical(other.walletProfit, walletProfit) || other.walletProfit == walletProfit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,capital,profit,walletCapital,walletProfit);

@override
String toString() {
  return 'InvestorTotals(capital: $capital, profit: $profit, walletCapital: $walletCapital, walletProfit: $walletProfit)';
}


}

/// @nodoc
abstract mixin class _$InvestorTotalsCopyWith<$Res> implements $InvestorTotalsCopyWith<$Res> {
  factory _$InvestorTotalsCopyWith(_InvestorTotals value, $Res Function(_InvestorTotals) _then) = __$InvestorTotalsCopyWithImpl;
@override @useResult
$Res call({
 String capital, String profit,@JsonKey(name: 'wallet_capital') String walletCapital,@JsonKey(name: 'wallet_profit') String walletProfit
});




}
/// @nodoc
class __$InvestorTotalsCopyWithImpl<$Res>
    implements _$InvestorTotalsCopyWith<$Res> {
  __$InvestorTotalsCopyWithImpl(this._self, this._then);

  final _InvestorTotals _self;
  final $Res Function(_InvestorTotals) _then;

/// Create a copy of InvestorTotals
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? capital = null,Object? profit = null,Object? walletCapital = null,Object? walletProfit = null,}) {
  return _then(_InvestorTotals(
capital: null == capital ? _self.capital : capital // ignore: cast_nullable_to_non_nullable
as String,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as String,walletCapital: null == walletCapital ? _self.walletCapital : walletCapital // ignore: cast_nullable_to_non_nullable
as String,walletProfit: null == walletProfit ? _self.walletProfit : walletProfit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProfitFigures {

@JsonKey(name: 'awaiting_delivery') String get awaitingDelivery;/// كم طلبيةً وراء «قيد التسليم».
@JsonKey(name: 'orders_awaiting_delivery') int get ordersAwaitingDelivery; String get pending; String get available;
/// Create a copy of ProfitFigures
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfitFiguresCopyWith<ProfitFigures> get copyWith => _$ProfitFiguresCopyWithImpl<ProfitFigures>(this as ProfitFigures, _$identity);

  /// Serializes this ProfitFigures to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfitFigures&&(identical(other.awaitingDelivery, awaitingDelivery) || other.awaitingDelivery == awaitingDelivery)&&(identical(other.ordersAwaitingDelivery, ordersAwaitingDelivery) || other.ordersAwaitingDelivery == ordersAwaitingDelivery)&&(identical(other.pending, pending) || other.pending == pending)&&(identical(other.available, available) || other.available == available));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,awaitingDelivery,ordersAwaitingDelivery,pending,available);

@override
String toString() {
  return 'ProfitFigures(awaitingDelivery: $awaitingDelivery, ordersAwaitingDelivery: $ordersAwaitingDelivery, pending: $pending, available: $available)';
}


}

/// @nodoc
abstract mixin class $ProfitFiguresCopyWith<$Res>  {
  factory $ProfitFiguresCopyWith(ProfitFigures value, $Res Function(ProfitFigures) _then) = _$ProfitFiguresCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'awaiting_delivery') String awaitingDelivery,@JsonKey(name: 'orders_awaiting_delivery') int ordersAwaitingDelivery, String pending, String available
});




}
/// @nodoc
class _$ProfitFiguresCopyWithImpl<$Res>
    implements $ProfitFiguresCopyWith<$Res> {
  _$ProfitFiguresCopyWithImpl(this._self, this._then);

  final ProfitFigures _self;
  final $Res Function(ProfitFigures) _then;

/// Create a copy of ProfitFigures
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? awaitingDelivery = null,Object? ordersAwaitingDelivery = null,Object? pending = null,Object? available = null,}) {
  return _then(_self.copyWith(
awaitingDelivery: null == awaitingDelivery ? _self.awaitingDelivery : awaitingDelivery // ignore: cast_nullable_to_non_nullable
as String,ordersAwaitingDelivery: null == ordersAwaitingDelivery ? _self.ordersAwaitingDelivery : ordersAwaitingDelivery // ignore: cast_nullable_to_non_nullable
as int,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as String,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfitFigures].
extension ProfitFiguresPatterns on ProfitFigures {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfitFigures value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfitFigures() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfitFigures value)  $default,){
final _that = this;
switch (_that) {
case _ProfitFigures():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfitFigures value)?  $default,){
final _that = this;
switch (_that) {
case _ProfitFigures() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'awaiting_delivery')  String awaitingDelivery, @JsonKey(name: 'orders_awaiting_delivery')  int ordersAwaitingDelivery,  String pending,  String available)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfitFigures() when $default != null:
return $default(_that.awaitingDelivery,_that.ordersAwaitingDelivery,_that.pending,_that.available);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'awaiting_delivery')  String awaitingDelivery, @JsonKey(name: 'orders_awaiting_delivery')  int ordersAwaitingDelivery,  String pending,  String available)  $default,) {final _that = this;
switch (_that) {
case _ProfitFigures():
return $default(_that.awaitingDelivery,_that.ordersAwaitingDelivery,_that.pending,_that.available);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'awaiting_delivery')  String awaitingDelivery, @JsonKey(name: 'orders_awaiting_delivery')  int ordersAwaitingDelivery,  String pending,  String available)?  $default,) {final _that = this;
switch (_that) {
case _ProfitFigures() when $default != null:
return $default(_that.awaitingDelivery,_that.ordersAwaitingDelivery,_that.pending,_that.available);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfitFigures implements ProfitFigures {
  const _ProfitFigures({@JsonKey(name: 'awaiting_delivery') required this.awaitingDelivery, @JsonKey(name: 'orders_awaiting_delivery') this.ordersAwaitingDelivery = 0, required this.pending, required this.available});
  factory _ProfitFigures.fromJson(Map<String, dynamic> json) => _$ProfitFiguresFromJson(json);

@override@JsonKey(name: 'awaiting_delivery') final  String awaitingDelivery;
/// كم طلبيةً وراء «قيد التسليم».
@override@JsonKey(name: 'orders_awaiting_delivery') final  int ordersAwaitingDelivery;
@override final  String pending;
@override final  String available;

/// Create a copy of ProfitFigures
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfitFiguresCopyWith<_ProfitFigures> get copyWith => __$ProfitFiguresCopyWithImpl<_ProfitFigures>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfitFiguresToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfitFigures&&(identical(other.awaitingDelivery, awaitingDelivery) || other.awaitingDelivery == awaitingDelivery)&&(identical(other.ordersAwaitingDelivery, ordersAwaitingDelivery) || other.ordersAwaitingDelivery == ordersAwaitingDelivery)&&(identical(other.pending, pending) || other.pending == pending)&&(identical(other.available, available) || other.available == available));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,awaitingDelivery,ordersAwaitingDelivery,pending,available);

@override
String toString() {
  return 'ProfitFigures(awaitingDelivery: $awaitingDelivery, ordersAwaitingDelivery: $ordersAwaitingDelivery, pending: $pending, available: $available)';
}


}

/// @nodoc
abstract mixin class _$ProfitFiguresCopyWith<$Res> implements $ProfitFiguresCopyWith<$Res> {
  factory _$ProfitFiguresCopyWith(_ProfitFigures value, $Res Function(_ProfitFigures) _then) = __$ProfitFiguresCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'awaiting_delivery') String awaitingDelivery,@JsonKey(name: 'orders_awaiting_delivery') int ordersAwaitingDelivery, String pending, String available
});




}
/// @nodoc
class __$ProfitFiguresCopyWithImpl<$Res>
    implements _$ProfitFiguresCopyWith<$Res> {
  __$ProfitFiguresCopyWithImpl(this._self, this._then);

  final _ProfitFigures _self;
  final $Res Function(_ProfitFigures) _then;

/// Create a copy of ProfitFigures
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? awaitingDelivery = null,Object? ordersAwaitingDelivery = null,Object? pending = null,Object? available = null,}) {
  return _then(_ProfitFigures(
awaitingDelivery: null == awaitingDelivery ? _self.awaitingDelivery : awaitingDelivery // ignore: cast_nullable_to_non_nullable
as String,ordersAwaitingDelivery: null == ordersAwaitingDelivery ? _self.ordersAwaitingDelivery : ordersAwaitingDelivery // ignore: cast_nullable_to_non_nullable
as int,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as String,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
