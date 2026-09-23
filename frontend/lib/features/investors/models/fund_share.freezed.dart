// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fund_share.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FundShare {

/// ما وضعه في الصندوق ولم يستردّه — سطرُه في لوحة الصندوق، وسقفُ ما يستردّه.
 String get capital; String get units;@JsonKey(name: 'unit_price') String get unitPrice;/// وحداتُه × السعر — ما يساويه نصيبُه لو قُوِّم اليوم.
 String get value;/// نسبتُه من ربح هذه الفترة. مربوطةٌ بالفترة لا بالحاضر: نافذةُ الاكتتاب في أوّلها بابُ
/// الفترة **التالية**، فمن اكتتب فيها لا يقاسم شهراً بدأ قبل أن يصل مالُه.
@JsonKey(name: 'share_percent') String get sharePercent;/// **صفرٌ بجانب مالٍ في الصندوق سؤالٌ لا خبر.** هذه هي إجابتُه: نصيبُه يبدأ من الفترة
/// القادمة، فلا يحسب أن مالَه ضاع.
@JsonKey(name: 'share_starts_next_period') bool get shareStartsNextPeriod;/// ما انقضت مدةُ حبسه من وحداته — وحده ما يمكن أن يخرج.
@JsonKey(name: 'unlocked_units') String get unlockedUnits; FundPeriodBrief? get period;/// **دفعةً دفعة**، لأن الحبس كذلك: لكل إيداعٍ مدّتُه. رقمٌ واحد كان سيقول «محبوسٌ إلى
/// ٢٠٢٨» لمن نصفُ ماله يخرج في ٢٠٢٧.
 List<FundDeposit> get deposits;
/// Create a copy of FundShare
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundShareCopyWith<FundShare> get copyWith => _$FundShareCopyWithImpl<FundShare>(this as FundShare, _$identity);

  /// Serializes this FundShare to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundShare&&(identical(other.capital, capital) || other.capital == capital)&&(identical(other.units, units) || other.units == units)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.value, value) || other.value == value)&&(identical(other.sharePercent, sharePercent) || other.sharePercent == sharePercent)&&(identical(other.shareStartsNextPeriod, shareStartsNextPeriod) || other.shareStartsNextPeriod == shareStartsNextPeriod)&&(identical(other.unlockedUnits, unlockedUnits) || other.unlockedUnits == unlockedUnits)&&(identical(other.period, period) || other.period == period)&&const DeepCollectionEquality().equals(other.deposits, deposits));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,capital,units,unitPrice,value,sharePercent,shareStartsNextPeriod,unlockedUnits,period,const DeepCollectionEquality().hash(deposits));

@override
String toString() {
  return 'FundShare(capital: $capital, units: $units, unitPrice: $unitPrice, value: $value, sharePercent: $sharePercent, shareStartsNextPeriod: $shareStartsNextPeriod, unlockedUnits: $unlockedUnits, period: $period, deposits: $deposits)';
}


}

/// @nodoc
abstract mixin class $FundShareCopyWith<$Res>  {
  factory $FundShareCopyWith(FundShare value, $Res Function(FundShare) _then) = _$FundShareCopyWithImpl;
@useResult
$Res call({
 String capital, String units,@JsonKey(name: 'unit_price') String unitPrice, String value,@JsonKey(name: 'share_percent') String sharePercent,@JsonKey(name: 'share_starts_next_period') bool shareStartsNextPeriod,@JsonKey(name: 'unlocked_units') String unlockedUnits, FundPeriodBrief? period, List<FundDeposit> deposits
});


$FundPeriodBriefCopyWith<$Res>? get period;

}
/// @nodoc
class _$FundShareCopyWithImpl<$Res>
    implements $FundShareCopyWith<$Res> {
  _$FundShareCopyWithImpl(this._self, this._then);

  final FundShare _self;
  final $Res Function(FundShare) _then;

/// Create a copy of FundShare
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? capital = null,Object? units = null,Object? unitPrice = null,Object? value = null,Object? sharePercent = null,Object? shareStartsNextPeriod = null,Object? unlockedUnits = null,Object? period = freezed,Object? deposits = null,}) {
  return _then(_self.copyWith(
capital: null == capital ? _self.capital : capital // ignore: cast_nullable_to_non_nullable
as String,units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,sharePercent: null == sharePercent ? _self.sharePercent : sharePercent // ignore: cast_nullable_to_non_nullable
as String,shareStartsNextPeriod: null == shareStartsNextPeriod ? _self.shareStartsNextPeriod : shareStartsNextPeriod // ignore: cast_nullable_to_non_nullable
as bool,unlockedUnits: null == unlockedUnits ? _self.unlockedUnits : unlockedUnits // ignore: cast_nullable_to_non_nullable
as String,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as FundPeriodBrief?,deposits: null == deposits ? _self.deposits : deposits // ignore: cast_nullable_to_non_nullable
as List<FundDeposit>,
  ));
}
/// Create a copy of FundShare
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundPeriodBriefCopyWith<$Res>? get period {
    if (_self.period == null) {
    return null;
  }

  return $FundPeriodBriefCopyWith<$Res>(_self.period!, (value) {
    return _then(_self.copyWith(period: value));
  });
}
}


/// Adds pattern-matching-related methods to [FundShare].
extension FundSharePatterns on FundShare {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundShare value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundShare() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundShare value)  $default,){
final _that = this;
switch (_that) {
case _FundShare():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundShare value)?  $default,){
final _that = this;
switch (_that) {
case _FundShare() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String capital,  String units, @JsonKey(name: 'unit_price')  String unitPrice,  String value, @JsonKey(name: 'share_percent')  String sharePercent, @JsonKey(name: 'share_starts_next_period')  bool shareStartsNextPeriod, @JsonKey(name: 'unlocked_units')  String unlockedUnits,  FundPeriodBrief? period,  List<FundDeposit> deposits)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundShare() when $default != null:
return $default(_that.capital,_that.units,_that.unitPrice,_that.value,_that.sharePercent,_that.shareStartsNextPeriod,_that.unlockedUnits,_that.period,_that.deposits);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String capital,  String units, @JsonKey(name: 'unit_price')  String unitPrice,  String value, @JsonKey(name: 'share_percent')  String sharePercent, @JsonKey(name: 'share_starts_next_period')  bool shareStartsNextPeriod, @JsonKey(name: 'unlocked_units')  String unlockedUnits,  FundPeriodBrief? period,  List<FundDeposit> deposits)  $default,) {final _that = this;
switch (_that) {
case _FundShare():
return $default(_that.capital,_that.units,_that.unitPrice,_that.value,_that.sharePercent,_that.shareStartsNextPeriod,_that.unlockedUnits,_that.period,_that.deposits);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String capital,  String units, @JsonKey(name: 'unit_price')  String unitPrice,  String value, @JsonKey(name: 'share_percent')  String sharePercent, @JsonKey(name: 'share_starts_next_period')  bool shareStartsNextPeriod, @JsonKey(name: 'unlocked_units')  String unlockedUnits,  FundPeriodBrief? period,  List<FundDeposit> deposits)?  $default,) {final _that = this;
switch (_that) {
case _FundShare() when $default != null:
return $default(_that.capital,_that.units,_that.unitPrice,_that.value,_that.sharePercent,_that.shareStartsNextPeriod,_that.unlockedUnits,_that.period,_that.deposits);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundShare implements FundShare {
  const _FundShare({this.capital = '0.00', required this.units, @JsonKey(name: 'unit_price') required this.unitPrice, required this.value, @JsonKey(name: 'share_percent') required this.sharePercent, @JsonKey(name: 'share_starts_next_period') this.shareStartsNextPeriod = false, @JsonKey(name: 'unlocked_units') this.unlockedUnits = '0.000000', this.period, final  List<FundDeposit> deposits = const <FundDeposit>[]}): _deposits = deposits;
  factory _FundShare.fromJson(Map<String, dynamic> json) => _$FundShareFromJson(json);

/// ما وضعه في الصندوق ولم يستردّه — سطرُه في لوحة الصندوق، وسقفُ ما يستردّه.
@override@JsonKey() final  String capital;
@override final  String units;
@override@JsonKey(name: 'unit_price') final  String unitPrice;
/// وحداتُه × السعر — ما يساويه نصيبُه لو قُوِّم اليوم.
@override final  String value;
/// نسبتُه من ربح هذه الفترة. مربوطةٌ بالفترة لا بالحاضر: نافذةُ الاكتتاب في أوّلها بابُ
/// الفترة **التالية**، فمن اكتتب فيها لا يقاسم شهراً بدأ قبل أن يصل مالُه.
@override@JsonKey(name: 'share_percent') final  String sharePercent;
/// **صفرٌ بجانب مالٍ في الصندوق سؤالٌ لا خبر.** هذه هي إجابتُه: نصيبُه يبدأ من الفترة
/// القادمة، فلا يحسب أن مالَه ضاع.
@override@JsonKey(name: 'share_starts_next_period') final  bool shareStartsNextPeriod;
/// ما انقضت مدةُ حبسه من وحداته — وحده ما يمكن أن يخرج.
@override@JsonKey(name: 'unlocked_units') final  String unlockedUnits;
@override final  FundPeriodBrief? period;
/// **دفعةً دفعة**، لأن الحبس كذلك: لكل إيداعٍ مدّتُه. رقمٌ واحد كان سيقول «محبوسٌ إلى
/// ٢٠٢٨» لمن نصفُ ماله يخرج في ٢٠٢٧.
 final  List<FundDeposit> _deposits;
/// **دفعةً دفعة**، لأن الحبس كذلك: لكل إيداعٍ مدّتُه. رقمٌ واحد كان سيقول «محبوسٌ إلى
/// ٢٠٢٨» لمن نصفُ ماله يخرج في ٢٠٢٧.
@override@JsonKey() List<FundDeposit> get deposits {
  if (_deposits is EqualUnmodifiableListView) return _deposits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deposits);
}


/// Create a copy of FundShare
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundShareCopyWith<_FundShare> get copyWith => __$FundShareCopyWithImpl<_FundShare>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundShareToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundShare&&(identical(other.capital, capital) || other.capital == capital)&&(identical(other.units, units) || other.units == units)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.value, value) || other.value == value)&&(identical(other.sharePercent, sharePercent) || other.sharePercent == sharePercent)&&(identical(other.shareStartsNextPeriod, shareStartsNextPeriod) || other.shareStartsNextPeriod == shareStartsNextPeriod)&&(identical(other.unlockedUnits, unlockedUnits) || other.unlockedUnits == unlockedUnits)&&(identical(other.period, period) || other.period == period)&&const DeepCollectionEquality().equals(other._deposits, _deposits));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,capital,units,unitPrice,value,sharePercent,shareStartsNextPeriod,unlockedUnits,period,const DeepCollectionEquality().hash(_deposits));

@override
String toString() {
  return 'FundShare(capital: $capital, units: $units, unitPrice: $unitPrice, value: $value, sharePercent: $sharePercent, shareStartsNextPeriod: $shareStartsNextPeriod, unlockedUnits: $unlockedUnits, period: $period, deposits: $deposits)';
}


}

/// @nodoc
abstract mixin class _$FundShareCopyWith<$Res> implements $FundShareCopyWith<$Res> {
  factory _$FundShareCopyWith(_FundShare value, $Res Function(_FundShare) _then) = __$FundShareCopyWithImpl;
@override @useResult
$Res call({
 String capital, String units,@JsonKey(name: 'unit_price') String unitPrice, String value,@JsonKey(name: 'share_percent') String sharePercent,@JsonKey(name: 'share_starts_next_period') bool shareStartsNextPeriod,@JsonKey(name: 'unlocked_units') String unlockedUnits, FundPeriodBrief? period, List<FundDeposit> deposits
});


@override $FundPeriodBriefCopyWith<$Res>? get period;

}
/// @nodoc
class __$FundShareCopyWithImpl<$Res>
    implements _$FundShareCopyWith<$Res> {
  __$FundShareCopyWithImpl(this._self, this._then);

  final _FundShare _self;
  final $Res Function(_FundShare) _then;

/// Create a copy of FundShare
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? capital = null,Object? units = null,Object? unitPrice = null,Object? value = null,Object? sharePercent = null,Object? shareStartsNextPeriod = null,Object? unlockedUnits = null,Object? period = freezed,Object? deposits = null,}) {
  return _then(_FundShare(
capital: null == capital ? _self.capital : capital // ignore: cast_nullable_to_non_nullable
as String,units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,sharePercent: null == sharePercent ? _self.sharePercent : sharePercent // ignore: cast_nullable_to_non_nullable
as String,shareStartsNextPeriod: null == shareStartsNextPeriod ? _self.shareStartsNextPeriod : shareStartsNextPeriod // ignore: cast_nullable_to_non_nullable
as bool,unlockedUnits: null == unlockedUnits ? _self.unlockedUnits : unlockedUnits // ignore: cast_nullable_to_non_nullable
as String,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as FundPeriodBrief?,deposits: null == deposits ? _self._deposits : deposits // ignore: cast_nullable_to_non_nullable
as List<FundDeposit>,
  ));
}

/// Create a copy of FundShare
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundPeriodBriefCopyWith<$Res>? get period {
    if (_self.period == null) {
    return null;
  }

  return $FundPeriodBriefCopyWith<$Res>(_self.period!, (value) {
    return _then(_self.copyWith(period: value));
  });
}
}


/// @nodoc
mixin _$FundPeriodBrief {

 String get code;@JsonKey(name: 'starts_on') String get startsOn;@JsonKey(name: 'ends_on') String get endsOn;@JsonKey(name: 'accepts_capital') bool get acceptsCapital;
/// Create a copy of FundPeriodBrief
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundPeriodBriefCopyWith<FundPeriodBrief> get copyWith => _$FundPeriodBriefCopyWithImpl<FundPeriodBrief>(this as FundPeriodBrief, _$identity);

  /// Serializes this FundPeriodBrief to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundPeriodBrief&&(identical(other.code, code) || other.code == code)&&(identical(other.startsOn, startsOn) || other.startsOn == startsOn)&&(identical(other.endsOn, endsOn) || other.endsOn == endsOn)&&(identical(other.acceptsCapital, acceptsCapital) || other.acceptsCapital == acceptsCapital));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,startsOn,endsOn,acceptsCapital);

@override
String toString() {
  return 'FundPeriodBrief(code: $code, startsOn: $startsOn, endsOn: $endsOn, acceptsCapital: $acceptsCapital)';
}


}

/// @nodoc
abstract mixin class $FundPeriodBriefCopyWith<$Res>  {
  factory $FundPeriodBriefCopyWith(FundPeriodBrief value, $Res Function(FundPeriodBrief) _then) = _$FundPeriodBriefCopyWithImpl;
@useResult
$Res call({
 String code,@JsonKey(name: 'starts_on') String startsOn,@JsonKey(name: 'ends_on') String endsOn,@JsonKey(name: 'accepts_capital') bool acceptsCapital
});




}
/// @nodoc
class _$FundPeriodBriefCopyWithImpl<$Res>
    implements $FundPeriodBriefCopyWith<$Res> {
  _$FundPeriodBriefCopyWithImpl(this._self, this._then);

  final FundPeriodBrief _self;
  final $Res Function(FundPeriodBrief) _then;

/// Create a copy of FundPeriodBrief
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? startsOn = null,Object? endsOn = null,Object? acceptsCapital = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,startsOn: null == startsOn ? _self.startsOn : startsOn // ignore: cast_nullable_to_non_nullable
as String,endsOn: null == endsOn ? _self.endsOn : endsOn // ignore: cast_nullable_to_non_nullable
as String,acceptsCapital: null == acceptsCapital ? _self.acceptsCapital : acceptsCapital // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FundPeriodBrief].
extension FundPeriodBriefPatterns on FundPeriodBrief {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundPeriodBrief value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundPeriodBrief() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundPeriodBrief value)  $default,){
final _that = this;
switch (_that) {
case _FundPeriodBrief():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundPeriodBrief value)?  $default,){
final _that = this;
switch (_that) {
case _FundPeriodBrief() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code, @JsonKey(name: 'starts_on')  String startsOn, @JsonKey(name: 'ends_on')  String endsOn, @JsonKey(name: 'accepts_capital')  bool acceptsCapital)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundPeriodBrief() when $default != null:
return $default(_that.code,_that.startsOn,_that.endsOn,_that.acceptsCapital);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code, @JsonKey(name: 'starts_on')  String startsOn, @JsonKey(name: 'ends_on')  String endsOn, @JsonKey(name: 'accepts_capital')  bool acceptsCapital)  $default,) {final _that = this;
switch (_that) {
case _FundPeriodBrief():
return $default(_that.code,_that.startsOn,_that.endsOn,_that.acceptsCapital);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code, @JsonKey(name: 'starts_on')  String startsOn, @JsonKey(name: 'ends_on')  String endsOn, @JsonKey(name: 'accepts_capital')  bool acceptsCapital)?  $default,) {final _that = this;
switch (_that) {
case _FundPeriodBrief() when $default != null:
return $default(_that.code,_that.startsOn,_that.endsOn,_that.acceptsCapital);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundPeriodBrief implements FundPeriodBrief {
  const _FundPeriodBrief({required this.code, @JsonKey(name: 'starts_on') required this.startsOn, @JsonKey(name: 'ends_on') required this.endsOn, @JsonKey(name: 'accepts_capital') this.acceptsCapital = false});
  factory _FundPeriodBrief.fromJson(Map<String, dynamic> json) => _$FundPeriodBriefFromJson(json);

@override final  String code;
@override@JsonKey(name: 'starts_on') final  String startsOn;
@override@JsonKey(name: 'ends_on') final  String endsOn;
@override@JsonKey(name: 'accepts_capital') final  bool acceptsCapital;

/// Create a copy of FundPeriodBrief
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundPeriodBriefCopyWith<_FundPeriodBrief> get copyWith => __$FundPeriodBriefCopyWithImpl<_FundPeriodBrief>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundPeriodBriefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundPeriodBrief&&(identical(other.code, code) || other.code == code)&&(identical(other.startsOn, startsOn) || other.startsOn == startsOn)&&(identical(other.endsOn, endsOn) || other.endsOn == endsOn)&&(identical(other.acceptsCapital, acceptsCapital) || other.acceptsCapital == acceptsCapital));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,startsOn,endsOn,acceptsCapital);

@override
String toString() {
  return 'FundPeriodBrief(code: $code, startsOn: $startsOn, endsOn: $endsOn, acceptsCapital: $acceptsCapital)';
}


}

/// @nodoc
abstract mixin class _$FundPeriodBriefCopyWith<$Res> implements $FundPeriodBriefCopyWith<$Res> {
  factory _$FundPeriodBriefCopyWith(_FundPeriodBrief value, $Res Function(_FundPeriodBrief) _then) = __$FundPeriodBriefCopyWithImpl;
@override @useResult
$Res call({
 String code,@JsonKey(name: 'starts_on') String startsOn,@JsonKey(name: 'ends_on') String endsOn,@JsonKey(name: 'accepts_capital') bool acceptsCapital
});




}
/// @nodoc
class __$FundPeriodBriefCopyWithImpl<$Res>
    implements _$FundPeriodBriefCopyWith<$Res> {
  __$FundPeriodBriefCopyWithImpl(this._self, this._then);

  final _FundPeriodBrief _self;
  final $Res Function(_FundPeriodBrief) _then;

/// Create a copy of FundPeriodBrief
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? startsOn = null,Object? endsOn = null,Object? acceptsCapital = null,}) {
  return _then(_FundPeriodBrief(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,startsOn: null == startsOn ? _self.startsOn : startsOn // ignore: cast_nullable_to_non_nullable
as String,endsOn: null == endsOn ? _self.endsOn : endsOn // ignore: cast_nullable_to_non_nullable
as String,acceptsCapital: null == acceptsCapital ? _self.acceptsCapital : acceptsCapital // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$FundDeposit {

 String get units; String get amount;@JsonKey(name: 'locked_until') String? get lockedUntil;@JsonKey(name: 'is_locked') bool get isLocked;
/// Create a copy of FundDeposit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundDepositCopyWith<FundDeposit> get copyWith => _$FundDepositCopyWithImpl<FundDeposit>(this as FundDeposit, _$identity);

  /// Serializes this FundDeposit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundDeposit&&(identical(other.units, units) || other.units == units)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.lockedUntil, lockedUntil) || other.lockedUntil == lockedUntil)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,units,amount,lockedUntil,isLocked);

@override
String toString() {
  return 'FundDeposit(units: $units, amount: $amount, lockedUntil: $lockedUntil, isLocked: $isLocked)';
}


}

/// @nodoc
abstract mixin class $FundDepositCopyWith<$Res>  {
  factory $FundDepositCopyWith(FundDeposit value, $Res Function(FundDeposit) _then) = _$FundDepositCopyWithImpl;
@useResult
$Res call({
 String units, String amount,@JsonKey(name: 'locked_until') String? lockedUntil,@JsonKey(name: 'is_locked') bool isLocked
});




}
/// @nodoc
class _$FundDepositCopyWithImpl<$Res>
    implements $FundDepositCopyWith<$Res> {
  _$FundDepositCopyWithImpl(this._self, this._then);

  final FundDeposit _self;
  final $Res Function(FundDeposit) _then;

/// Create a copy of FundDeposit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? units = null,Object? amount = null,Object? lockedUntil = freezed,Object? isLocked = null,}) {
  return _then(_self.copyWith(
units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,lockedUntil: freezed == lockedUntil ? _self.lockedUntil : lockedUntil // ignore: cast_nullable_to_non_nullable
as String?,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FundDeposit].
extension FundDepositPatterns on FundDeposit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundDeposit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundDeposit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundDeposit value)  $default,){
final _that = this;
switch (_that) {
case _FundDeposit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundDeposit value)?  $default,){
final _that = this;
switch (_that) {
case _FundDeposit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String units,  String amount, @JsonKey(name: 'locked_until')  String? lockedUntil, @JsonKey(name: 'is_locked')  bool isLocked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundDeposit() when $default != null:
return $default(_that.units,_that.amount,_that.lockedUntil,_that.isLocked);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String units,  String amount, @JsonKey(name: 'locked_until')  String? lockedUntil, @JsonKey(name: 'is_locked')  bool isLocked)  $default,) {final _that = this;
switch (_that) {
case _FundDeposit():
return $default(_that.units,_that.amount,_that.lockedUntil,_that.isLocked);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String units,  String amount, @JsonKey(name: 'locked_until')  String? lockedUntil, @JsonKey(name: 'is_locked')  bool isLocked)?  $default,) {final _that = this;
switch (_that) {
case _FundDeposit() when $default != null:
return $default(_that.units,_that.amount,_that.lockedUntil,_that.isLocked);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundDeposit implements FundDeposit {
  const _FundDeposit({required this.units, required this.amount, @JsonKey(name: 'locked_until') this.lockedUntil, @JsonKey(name: 'is_locked') this.isLocked = true});
  factory _FundDeposit.fromJson(Map<String, dynamic> json) => _$FundDepositFromJson(json);

@override final  String units;
@override final  String amount;
@override@JsonKey(name: 'locked_until') final  String? lockedUntil;
@override@JsonKey(name: 'is_locked') final  bool isLocked;

/// Create a copy of FundDeposit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundDepositCopyWith<_FundDeposit> get copyWith => __$FundDepositCopyWithImpl<_FundDeposit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundDepositToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundDeposit&&(identical(other.units, units) || other.units == units)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.lockedUntil, lockedUntil) || other.lockedUntil == lockedUntil)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,units,amount,lockedUntil,isLocked);

@override
String toString() {
  return 'FundDeposit(units: $units, amount: $amount, lockedUntil: $lockedUntil, isLocked: $isLocked)';
}


}

/// @nodoc
abstract mixin class _$FundDepositCopyWith<$Res> implements $FundDepositCopyWith<$Res> {
  factory _$FundDepositCopyWith(_FundDeposit value, $Res Function(_FundDeposit) _then) = __$FundDepositCopyWithImpl;
@override @useResult
$Res call({
 String units, String amount,@JsonKey(name: 'locked_until') String? lockedUntil,@JsonKey(name: 'is_locked') bool isLocked
});




}
/// @nodoc
class __$FundDepositCopyWithImpl<$Res>
    implements _$FundDepositCopyWith<$Res> {
  __$FundDepositCopyWithImpl(this._self, this._then);

  final _FundDeposit _self;
  final $Res Function(_FundDeposit) _then;

/// Create a copy of FundDeposit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? units = null,Object? amount = null,Object? lockedUntil = freezed,Object? isLocked = null,}) {
  return _then(_FundDeposit(
units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,lockedUntil: freezed == lockedUntil ? _self.lockedUntil : lockedUntil // ignore: cast_nullable_to_non_nullable
as String?,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
