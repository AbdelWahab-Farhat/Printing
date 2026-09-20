// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'company_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CompanySettings {

/// The investors' half of each pool's net profit; the company keeps the rest as the
/// operator's cut. Seeded into a pool when it is opened and **frozen there** — changing it
/// here never rewrites a pool that already exists, because that was the term its partners
/// were shown.
@JsonKey(name: 'investor_profit_share_percent') String get investorProfitSharePercent;/// How long a profit period runs. A close divides that period and opens the next.
@JsonKey(name: 'profit_period_months') int get profitPeriodMonths;/// The longer review cycle — how often the books are asserted against the goods.
@JsonKey(name: 'settlement_period_months') int get settlementPeriodMonths;/// How many days into a period capital may still arrive and work the whole of it.
///
/// **Zero means a strict boundary**: money offered on day one of a period joins the next.
/// The window exists because ownership is a plain capital ratio, and a ratio is only exact
/// if capital does not move inside the period it is measured over.
@JsonKey(name: 'entry_grace_days') int get entryGraceDays;/// How many months an investor's capital must stay in a pool before he may ask for it back.
///
/// Measured from his **first** money into that pool, not the latest — otherwise topping up
/// would restart his clock, which is the opposite of what a minimum term means. **Zero is no
/// minimum**, and is how the system behaved before this existed.
///
/// The company's own capital is exempt: it is the operator, not a partner who might take a
/// month's profit and leave.
@JsonKey(name: 'minimum_term_months') int get minimumTermMonths;@JsonKey(name: 'updated_at') String? get updatedAt;
/// Create a copy of CompanySettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompanySettingsCopyWith<CompanySettings> get copyWith => _$CompanySettingsCopyWithImpl<CompanySettings>(this as CompanySettings, _$identity);

  /// Serializes this CompanySettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompanySettings&&(identical(other.investorProfitSharePercent, investorProfitSharePercent) || other.investorProfitSharePercent == investorProfitSharePercent)&&(identical(other.profitPeriodMonths, profitPeriodMonths) || other.profitPeriodMonths == profitPeriodMonths)&&(identical(other.settlementPeriodMonths, settlementPeriodMonths) || other.settlementPeriodMonths == settlementPeriodMonths)&&(identical(other.entryGraceDays, entryGraceDays) || other.entryGraceDays == entryGraceDays)&&(identical(other.minimumTermMonths, minimumTermMonths) || other.minimumTermMonths == minimumTermMonths)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,investorProfitSharePercent,profitPeriodMonths,settlementPeriodMonths,entryGraceDays,minimumTermMonths,updatedAt);

@override
String toString() {
  return 'CompanySettings(investorProfitSharePercent: $investorProfitSharePercent, profitPeriodMonths: $profitPeriodMonths, settlementPeriodMonths: $settlementPeriodMonths, entryGraceDays: $entryGraceDays, minimumTermMonths: $minimumTermMonths, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $CompanySettingsCopyWith<$Res>  {
  factory $CompanySettingsCopyWith(CompanySettings value, $Res Function(CompanySettings) _then) = _$CompanySettingsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'investor_profit_share_percent') String investorProfitSharePercent,@JsonKey(name: 'profit_period_months') int profitPeriodMonths,@JsonKey(name: 'settlement_period_months') int settlementPeriodMonths,@JsonKey(name: 'entry_grace_days') int entryGraceDays,@JsonKey(name: 'minimum_term_months') int minimumTermMonths,@JsonKey(name: 'updated_at') String? updatedAt
});




}
/// @nodoc
class _$CompanySettingsCopyWithImpl<$Res>
    implements $CompanySettingsCopyWith<$Res> {
  _$CompanySettingsCopyWithImpl(this._self, this._then);

  final CompanySettings _self;
  final $Res Function(CompanySettings) _then;

/// Create a copy of CompanySettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? investorProfitSharePercent = null,Object? profitPeriodMonths = null,Object? settlementPeriodMonths = null,Object? entryGraceDays = null,Object? minimumTermMonths = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
investorProfitSharePercent: null == investorProfitSharePercent ? _self.investorProfitSharePercent : investorProfitSharePercent // ignore: cast_nullable_to_non_nullable
as String,profitPeriodMonths: null == profitPeriodMonths ? _self.profitPeriodMonths : profitPeriodMonths // ignore: cast_nullable_to_non_nullable
as int,settlementPeriodMonths: null == settlementPeriodMonths ? _self.settlementPeriodMonths : settlementPeriodMonths // ignore: cast_nullable_to_non_nullable
as int,entryGraceDays: null == entryGraceDays ? _self.entryGraceDays : entryGraceDays // ignore: cast_nullable_to_non_nullable
as int,minimumTermMonths: null == minimumTermMonths ? _self.minimumTermMonths : minimumTermMonths // ignore: cast_nullable_to_non_nullable
as int,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CompanySettings].
extension CompanySettingsPatterns on CompanySettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompanySettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompanySettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompanySettings value)  $default,){
final _that = this;
switch (_that) {
case _CompanySettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompanySettings value)?  $default,){
final _that = this;
switch (_that) {
case _CompanySettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'investor_profit_share_percent')  String investorProfitSharePercent, @JsonKey(name: 'profit_period_months')  int profitPeriodMonths, @JsonKey(name: 'settlement_period_months')  int settlementPeriodMonths, @JsonKey(name: 'entry_grace_days')  int entryGraceDays, @JsonKey(name: 'minimum_term_months')  int minimumTermMonths, @JsonKey(name: 'updated_at')  String? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompanySettings() when $default != null:
return $default(_that.investorProfitSharePercent,_that.profitPeriodMonths,_that.settlementPeriodMonths,_that.entryGraceDays,_that.minimumTermMonths,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'investor_profit_share_percent')  String investorProfitSharePercent, @JsonKey(name: 'profit_period_months')  int profitPeriodMonths, @JsonKey(name: 'settlement_period_months')  int settlementPeriodMonths, @JsonKey(name: 'entry_grace_days')  int entryGraceDays, @JsonKey(name: 'minimum_term_months')  int minimumTermMonths, @JsonKey(name: 'updated_at')  String? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _CompanySettings():
return $default(_that.investorProfitSharePercent,_that.profitPeriodMonths,_that.settlementPeriodMonths,_that.entryGraceDays,_that.minimumTermMonths,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'investor_profit_share_percent')  String investorProfitSharePercent, @JsonKey(name: 'profit_period_months')  int profitPeriodMonths, @JsonKey(name: 'settlement_period_months')  int settlementPeriodMonths, @JsonKey(name: 'entry_grace_days')  int entryGraceDays, @JsonKey(name: 'minimum_term_months')  int minimumTermMonths, @JsonKey(name: 'updated_at')  String? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _CompanySettings() when $default != null:
return $default(_that.investorProfitSharePercent,_that.profitPeriodMonths,_that.settlementPeriodMonths,_that.entryGraceDays,_that.minimumTermMonths,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompanySettings implements CompanySettings {
  const _CompanySettings({@JsonKey(name: 'investor_profit_share_percent') this.investorProfitSharePercent = '50.00', @JsonKey(name: 'profit_period_months') this.profitPeriodMonths = 1, @JsonKey(name: 'settlement_period_months') this.settlementPeriodMonths = 6, @JsonKey(name: 'entry_grace_days') this.entryGraceDays = 3, @JsonKey(name: 'minimum_term_months') this.minimumTermMonths = 0, @JsonKey(name: 'updated_at') this.updatedAt});
  factory _CompanySettings.fromJson(Map<String, dynamic> json) => _$CompanySettingsFromJson(json);

/// The investors' half of each pool's net profit; the company keeps the rest as the
/// operator's cut. Seeded into a pool when it is opened and **frozen there** — changing it
/// here never rewrites a pool that already exists, because that was the term its partners
/// were shown.
@override@JsonKey(name: 'investor_profit_share_percent') final  String investorProfitSharePercent;
/// How long a profit period runs. A close divides that period and opens the next.
@override@JsonKey(name: 'profit_period_months') final  int profitPeriodMonths;
/// The longer review cycle — how often the books are asserted against the goods.
@override@JsonKey(name: 'settlement_period_months') final  int settlementPeriodMonths;
/// How many days into a period capital may still arrive and work the whole of it.
///
/// **Zero means a strict boundary**: money offered on day one of a period joins the next.
/// The window exists because ownership is a plain capital ratio, and a ratio is only exact
/// if capital does not move inside the period it is measured over.
@override@JsonKey(name: 'entry_grace_days') final  int entryGraceDays;
/// How many months an investor's capital must stay in a pool before he may ask for it back.
///
/// Measured from his **first** money into that pool, not the latest — otherwise topping up
/// would restart his clock, which is the opposite of what a minimum term means. **Zero is no
/// minimum**, and is how the system behaved before this existed.
///
/// The company's own capital is exempt: it is the operator, not a partner who might take a
/// month's profit and leave.
@override@JsonKey(name: 'minimum_term_months') final  int minimumTermMonths;
@override@JsonKey(name: 'updated_at') final  String? updatedAt;

/// Create a copy of CompanySettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompanySettingsCopyWith<_CompanySettings> get copyWith => __$CompanySettingsCopyWithImpl<_CompanySettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompanySettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompanySettings&&(identical(other.investorProfitSharePercent, investorProfitSharePercent) || other.investorProfitSharePercent == investorProfitSharePercent)&&(identical(other.profitPeriodMonths, profitPeriodMonths) || other.profitPeriodMonths == profitPeriodMonths)&&(identical(other.settlementPeriodMonths, settlementPeriodMonths) || other.settlementPeriodMonths == settlementPeriodMonths)&&(identical(other.entryGraceDays, entryGraceDays) || other.entryGraceDays == entryGraceDays)&&(identical(other.minimumTermMonths, minimumTermMonths) || other.minimumTermMonths == minimumTermMonths)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,investorProfitSharePercent,profitPeriodMonths,settlementPeriodMonths,entryGraceDays,minimumTermMonths,updatedAt);

@override
String toString() {
  return 'CompanySettings(investorProfitSharePercent: $investorProfitSharePercent, profitPeriodMonths: $profitPeriodMonths, settlementPeriodMonths: $settlementPeriodMonths, entryGraceDays: $entryGraceDays, minimumTermMonths: $minimumTermMonths, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CompanySettingsCopyWith<$Res> implements $CompanySettingsCopyWith<$Res> {
  factory _$CompanySettingsCopyWith(_CompanySettings value, $Res Function(_CompanySettings) _then) = __$CompanySettingsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'investor_profit_share_percent') String investorProfitSharePercent,@JsonKey(name: 'profit_period_months') int profitPeriodMonths,@JsonKey(name: 'settlement_period_months') int settlementPeriodMonths,@JsonKey(name: 'entry_grace_days') int entryGraceDays,@JsonKey(name: 'minimum_term_months') int minimumTermMonths,@JsonKey(name: 'updated_at') String? updatedAt
});




}
/// @nodoc
class __$CompanySettingsCopyWithImpl<$Res>
    implements _$CompanySettingsCopyWith<$Res> {
  __$CompanySettingsCopyWithImpl(this._self, this._then);

  final _CompanySettings _self;
  final $Res Function(_CompanySettings) _then;

/// Create a copy of CompanySettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? investorProfitSharePercent = null,Object? profitPeriodMonths = null,Object? settlementPeriodMonths = null,Object? entryGraceDays = null,Object? minimumTermMonths = null,Object? updatedAt = freezed,}) {
  return _then(_CompanySettings(
investorProfitSharePercent: null == investorProfitSharePercent ? _self.investorProfitSharePercent : investorProfitSharePercent // ignore: cast_nullable_to_non_nullable
as String,profitPeriodMonths: null == profitPeriodMonths ? _self.profitPeriodMonths : profitPeriodMonths // ignore: cast_nullable_to_non_nullable
as int,settlementPeriodMonths: null == settlementPeriodMonths ? _self.settlementPeriodMonths : settlementPeriodMonths // ignore: cast_nullable_to_non_nullable
as int,entryGraceDays: null == entryGraceDays ? _self.entryGraceDays : entryGraceDays // ignore: cast_nullable_to_non_nullable
as int,minimumTermMonths: null == minimumTermMonths ? _self.minimumTermMonths : minimumTermMonths // ignore: cast_nullable_to_non_nullable
as int,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
