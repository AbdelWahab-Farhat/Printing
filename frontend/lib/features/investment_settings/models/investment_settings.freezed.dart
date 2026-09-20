// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'investment_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InvestmentSettings {

/// حصة المستثمرين من ربح الفترة — والباقي للشركة.
@JsonKey(name: 'investor_profit_share_percent') String get investorProfitSharePercent;/// كم شهراً تدوم الفترة المحاسبية — وعليها يقع إقفال الأرباح.
@JsonKey(name: 'investment_period_months') int get periodMonths;/// أوّلُ الفترة الذي يُقبَل فيه إيداعُ رأس مال. ما يصل بعده يُحتجز ولا يُنفَق.
@JsonKey(name: 'investment_subscription_window_days') int get subscriptionWindowDays;/// دورةُ المراجعة الشاملة — أطول من دورة الأرباح ومستقلّةٌ عنها.
@JsonKey(name: 'investment_settlement_months') int get settlementMonths;/// كم يبقى رأسُ المال محجوزاً بعد إيداعه. **ولكلّ إيداعٍ ساعتُه**: من أودع في يناير وأودع
/// ثانيةً في يونيو يُفكّ الأول قبل الثاني بخمسة أشهر.
@JsonKey(name: 'investment_capital_lock_months') int get capitalLockMonths;
/// Create a copy of InvestmentSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestmentSettingsCopyWith<InvestmentSettings> get copyWith => _$InvestmentSettingsCopyWithImpl<InvestmentSettings>(this as InvestmentSettings, _$identity);

  /// Serializes this InvestmentSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestmentSettings&&(identical(other.investorProfitSharePercent, investorProfitSharePercent) || other.investorProfitSharePercent == investorProfitSharePercent)&&(identical(other.periodMonths, periodMonths) || other.periodMonths == periodMonths)&&(identical(other.subscriptionWindowDays, subscriptionWindowDays) || other.subscriptionWindowDays == subscriptionWindowDays)&&(identical(other.settlementMonths, settlementMonths) || other.settlementMonths == settlementMonths)&&(identical(other.capitalLockMonths, capitalLockMonths) || other.capitalLockMonths == capitalLockMonths));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,investorProfitSharePercent,periodMonths,subscriptionWindowDays,settlementMonths,capitalLockMonths);

@override
String toString() {
  return 'InvestmentSettings(investorProfitSharePercent: $investorProfitSharePercent, periodMonths: $periodMonths, subscriptionWindowDays: $subscriptionWindowDays, settlementMonths: $settlementMonths, capitalLockMonths: $capitalLockMonths)';
}


}

/// @nodoc
abstract mixin class $InvestmentSettingsCopyWith<$Res>  {
  factory $InvestmentSettingsCopyWith(InvestmentSettings value, $Res Function(InvestmentSettings) _then) = _$InvestmentSettingsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'investor_profit_share_percent') String investorProfitSharePercent,@JsonKey(name: 'investment_period_months') int periodMonths,@JsonKey(name: 'investment_subscription_window_days') int subscriptionWindowDays,@JsonKey(name: 'investment_settlement_months') int settlementMonths,@JsonKey(name: 'investment_capital_lock_months') int capitalLockMonths
});




}
/// @nodoc
class _$InvestmentSettingsCopyWithImpl<$Res>
    implements $InvestmentSettingsCopyWith<$Res> {
  _$InvestmentSettingsCopyWithImpl(this._self, this._then);

  final InvestmentSettings _self;
  final $Res Function(InvestmentSettings) _then;

/// Create a copy of InvestmentSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? investorProfitSharePercent = null,Object? periodMonths = null,Object? subscriptionWindowDays = null,Object? settlementMonths = null,Object? capitalLockMonths = null,}) {
  return _then(_self.copyWith(
investorProfitSharePercent: null == investorProfitSharePercent ? _self.investorProfitSharePercent : investorProfitSharePercent // ignore: cast_nullable_to_non_nullable
as String,periodMonths: null == periodMonths ? _self.periodMonths : periodMonths // ignore: cast_nullable_to_non_nullable
as int,subscriptionWindowDays: null == subscriptionWindowDays ? _self.subscriptionWindowDays : subscriptionWindowDays // ignore: cast_nullable_to_non_nullable
as int,settlementMonths: null == settlementMonths ? _self.settlementMonths : settlementMonths // ignore: cast_nullable_to_non_nullable
as int,capitalLockMonths: null == capitalLockMonths ? _self.capitalLockMonths : capitalLockMonths // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [InvestmentSettings].
extension InvestmentSettingsPatterns on InvestmentSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvestmentSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvestmentSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvestmentSettings value)  $default,){
final _that = this;
switch (_that) {
case _InvestmentSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvestmentSettings value)?  $default,){
final _that = this;
switch (_that) {
case _InvestmentSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'investor_profit_share_percent')  String investorProfitSharePercent, @JsonKey(name: 'investment_period_months')  int periodMonths, @JsonKey(name: 'investment_subscription_window_days')  int subscriptionWindowDays, @JsonKey(name: 'investment_settlement_months')  int settlementMonths, @JsonKey(name: 'investment_capital_lock_months')  int capitalLockMonths)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvestmentSettings() when $default != null:
return $default(_that.investorProfitSharePercent,_that.periodMonths,_that.subscriptionWindowDays,_that.settlementMonths,_that.capitalLockMonths);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'investor_profit_share_percent')  String investorProfitSharePercent, @JsonKey(name: 'investment_period_months')  int periodMonths, @JsonKey(name: 'investment_subscription_window_days')  int subscriptionWindowDays, @JsonKey(name: 'investment_settlement_months')  int settlementMonths, @JsonKey(name: 'investment_capital_lock_months')  int capitalLockMonths)  $default,) {final _that = this;
switch (_that) {
case _InvestmentSettings():
return $default(_that.investorProfitSharePercent,_that.periodMonths,_that.subscriptionWindowDays,_that.settlementMonths,_that.capitalLockMonths);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'investor_profit_share_percent')  String investorProfitSharePercent, @JsonKey(name: 'investment_period_months')  int periodMonths, @JsonKey(name: 'investment_subscription_window_days')  int subscriptionWindowDays, @JsonKey(name: 'investment_settlement_months')  int settlementMonths, @JsonKey(name: 'investment_capital_lock_months')  int capitalLockMonths)?  $default,) {final _that = this;
switch (_that) {
case _InvestmentSettings() when $default != null:
return $default(_that.investorProfitSharePercent,_that.periodMonths,_that.subscriptionWindowDays,_that.settlementMonths,_that.capitalLockMonths);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvestmentSettings implements InvestmentSettings {
  const _InvestmentSettings({@JsonKey(name: 'investor_profit_share_percent') required this.investorProfitSharePercent, @JsonKey(name: 'investment_period_months') required this.periodMonths, @JsonKey(name: 'investment_subscription_window_days') required this.subscriptionWindowDays, @JsonKey(name: 'investment_settlement_months') required this.settlementMonths, @JsonKey(name: 'investment_capital_lock_months') required this.capitalLockMonths});
  factory _InvestmentSettings.fromJson(Map<String, dynamic> json) => _$InvestmentSettingsFromJson(json);

/// حصة المستثمرين من ربح الفترة — والباقي للشركة.
@override@JsonKey(name: 'investor_profit_share_percent') final  String investorProfitSharePercent;
/// كم شهراً تدوم الفترة المحاسبية — وعليها يقع إقفال الأرباح.
@override@JsonKey(name: 'investment_period_months') final  int periodMonths;
/// أوّلُ الفترة الذي يُقبَل فيه إيداعُ رأس مال. ما يصل بعده يُحتجز ولا يُنفَق.
@override@JsonKey(name: 'investment_subscription_window_days') final  int subscriptionWindowDays;
/// دورةُ المراجعة الشاملة — أطول من دورة الأرباح ومستقلّةٌ عنها.
@override@JsonKey(name: 'investment_settlement_months') final  int settlementMonths;
/// كم يبقى رأسُ المال محجوزاً بعد إيداعه. **ولكلّ إيداعٍ ساعتُه**: من أودع في يناير وأودع
/// ثانيةً في يونيو يُفكّ الأول قبل الثاني بخمسة أشهر.
@override@JsonKey(name: 'investment_capital_lock_months') final  int capitalLockMonths;

/// Create a copy of InvestmentSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvestmentSettingsCopyWith<_InvestmentSettings> get copyWith => __$InvestmentSettingsCopyWithImpl<_InvestmentSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvestmentSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvestmentSettings&&(identical(other.investorProfitSharePercent, investorProfitSharePercent) || other.investorProfitSharePercent == investorProfitSharePercent)&&(identical(other.periodMonths, periodMonths) || other.periodMonths == periodMonths)&&(identical(other.subscriptionWindowDays, subscriptionWindowDays) || other.subscriptionWindowDays == subscriptionWindowDays)&&(identical(other.settlementMonths, settlementMonths) || other.settlementMonths == settlementMonths)&&(identical(other.capitalLockMonths, capitalLockMonths) || other.capitalLockMonths == capitalLockMonths));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,investorProfitSharePercent,periodMonths,subscriptionWindowDays,settlementMonths,capitalLockMonths);

@override
String toString() {
  return 'InvestmentSettings(investorProfitSharePercent: $investorProfitSharePercent, periodMonths: $periodMonths, subscriptionWindowDays: $subscriptionWindowDays, settlementMonths: $settlementMonths, capitalLockMonths: $capitalLockMonths)';
}


}

/// @nodoc
abstract mixin class _$InvestmentSettingsCopyWith<$Res> implements $InvestmentSettingsCopyWith<$Res> {
  factory _$InvestmentSettingsCopyWith(_InvestmentSettings value, $Res Function(_InvestmentSettings) _then) = __$InvestmentSettingsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'investor_profit_share_percent') String investorProfitSharePercent,@JsonKey(name: 'investment_period_months') int periodMonths,@JsonKey(name: 'investment_subscription_window_days') int subscriptionWindowDays,@JsonKey(name: 'investment_settlement_months') int settlementMonths,@JsonKey(name: 'investment_capital_lock_months') int capitalLockMonths
});




}
/// @nodoc
class __$InvestmentSettingsCopyWithImpl<$Res>
    implements _$InvestmentSettingsCopyWith<$Res> {
  __$InvestmentSettingsCopyWithImpl(this._self, this._then);

  final _InvestmentSettings _self;
  final $Res Function(_InvestmentSettings) _then;

/// Create a copy of InvestmentSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? investorProfitSharePercent = null,Object? periodMonths = null,Object? subscriptionWindowDays = null,Object? settlementMonths = null,Object? capitalLockMonths = null,}) {
  return _then(_InvestmentSettings(
investorProfitSharePercent: null == investorProfitSharePercent ? _self.investorProfitSharePercent : investorProfitSharePercent // ignore: cast_nullable_to_non_nullable
as String,periodMonths: null == periodMonths ? _self.periodMonths : periodMonths // ignore: cast_nullable_to_non_nullable
as int,subscriptionWindowDays: null == subscriptionWindowDays ? _self.subscriptionWindowDays : subscriptionWindowDays // ignore: cast_nullable_to_non_nullable
as int,settlementMonths: null == settlementMonths ? _self.settlementMonths : settlementMonths // ignore: cast_nullable_to_non_nullable
as int,capitalLockMonths: null == capitalLockMonths ? _self.capitalLockMonths : capitalLockMonths // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
