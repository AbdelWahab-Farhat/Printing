// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'period_share.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PeriodShare {

 int get id;@JsonKey(name: 'investment_period_id') int get investmentPeriodId;@JsonKey(name: 'investor_id') int get investorId;@JsonKey(name: 'investor_name') String? get investorName;/// The company's row. `sharePercent` on it is 100 of its own side, which is what it is — the
/// figure that means something for the company is [netShare], because its take is the residual
/// of the division rather than a slice of the investors' half.
@JsonKey(name: 'is_company') bool get isCompany;/// What he had in the pool when the period closed.
 String get capital;/// His weight of the investors' half, as applied.
@JsonKey(name: 'share_percent') String get sharePercent;/// What the division actually gave him — **negative in a losing period**.
@JsonKey(name: 'net_share') String get netShare;
/// Create a copy of PeriodShare
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodShareCopyWith<PeriodShare> get copyWith => _$PeriodShareCopyWithImpl<PeriodShare>(this as PeriodShare, _$identity);

  /// Serializes this PeriodShare to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodShare&&(identical(other.id, id) || other.id == id)&&(identical(other.investmentPeriodId, investmentPeriodId) || other.investmentPeriodId == investmentPeriodId)&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.investorName, investorName) || other.investorName == investorName)&&(identical(other.isCompany, isCompany) || other.isCompany == isCompany)&&(identical(other.capital, capital) || other.capital == capital)&&(identical(other.sharePercent, sharePercent) || other.sharePercent == sharePercent)&&(identical(other.netShare, netShare) || other.netShare == netShare));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,investmentPeriodId,investorId,investorName,isCompany,capital,sharePercent,netShare);

@override
String toString() {
  return 'PeriodShare(id: $id, investmentPeriodId: $investmentPeriodId, investorId: $investorId, investorName: $investorName, isCompany: $isCompany, capital: $capital, sharePercent: $sharePercent, netShare: $netShare)';
}


}

/// @nodoc
abstract mixin class $PeriodShareCopyWith<$Res>  {
  factory $PeriodShareCopyWith(PeriodShare value, $Res Function(PeriodShare) _then) = _$PeriodShareCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'investment_period_id') int investmentPeriodId,@JsonKey(name: 'investor_id') int investorId,@JsonKey(name: 'investor_name') String? investorName,@JsonKey(name: 'is_company') bool isCompany, String capital,@JsonKey(name: 'share_percent') String sharePercent,@JsonKey(name: 'net_share') String netShare
});




}
/// @nodoc
class _$PeriodShareCopyWithImpl<$Res>
    implements $PeriodShareCopyWith<$Res> {
  _$PeriodShareCopyWithImpl(this._self, this._then);

  final PeriodShare _self;
  final $Res Function(PeriodShare) _then;

/// Create a copy of PeriodShare
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? investmentPeriodId = null,Object? investorId = null,Object? investorName = freezed,Object? isCompany = null,Object? capital = null,Object? sharePercent = null,Object? netShare = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,investmentPeriodId: null == investmentPeriodId ? _self.investmentPeriodId : investmentPeriodId // ignore: cast_nullable_to_non_nullable
as int,investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as int,investorName: freezed == investorName ? _self.investorName : investorName // ignore: cast_nullable_to_non_nullable
as String?,isCompany: null == isCompany ? _self.isCompany : isCompany // ignore: cast_nullable_to_non_nullable
as bool,capital: null == capital ? _self.capital : capital // ignore: cast_nullable_to_non_nullable
as String,sharePercent: null == sharePercent ? _self.sharePercent : sharePercent // ignore: cast_nullable_to_non_nullable
as String,netShare: null == netShare ? _self.netShare : netShare // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PeriodShare].
extension PeriodSharePatterns on PeriodShare {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PeriodShare value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PeriodShare() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PeriodShare value)  $default,){
final _that = this;
switch (_that) {
case _PeriodShare():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PeriodShare value)?  $default,){
final _that = this;
switch (_that) {
case _PeriodShare() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'investment_period_id')  int investmentPeriodId, @JsonKey(name: 'investor_id')  int investorId, @JsonKey(name: 'investor_name')  String? investorName, @JsonKey(name: 'is_company')  bool isCompany,  String capital, @JsonKey(name: 'share_percent')  String sharePercent, @JsonKey(name: 'net_share')  String netShare)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodShare() when $default != null:
return $default(_that.id,_that.investmentPeriodId,_that.investorId,_that.investorName,_that.isCompany,_that.capital,_that.sharePercent,_that.netShare);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'investment_period_id')  int investmentPeriodId, @JsonKey(name: 'investor_id')  int investorId, @JsonKey(name: 'investor_name')  String? investorName, @JsonKey(name: 'is_company')  bool isCompany,  String capital, @JsonKey(name: 'share_percent')  String sharePercent, @JsonKey(name: 'net_share')  String netShare)  $default,) {final _that = this;
switch (_that) {
case _PeriodShare():
return $default(_that.id,_that.investmentPeriodId,_that.investorId,_that.investorName,_that.isCompany,_that.capital,_that.sharePercent,_that.netShare);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'investment_period_id')  int investmentPeriodId, @JsonKey(name: 'investor_id')  int investorId, @JsonKey(name: 'investor_name')  String? investorName, @JsonKey(name: 'is_company')  bool isCompany,  String capital, @JsonKey(name: 'share_percent')  String sharePercent, @JsonKey(name: 'net_share')  String netShare)?  $default,) {final _that = this;
switch (_that) {
case _PeriodShare() when $default != null:
return $default(_that.id,_that.investmentPeriodId,_that.investorId,_that.investorName,_that.isCompany,_that.capital,_that.sharePercent,_that.netShare);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodShare implements PeriodShare {
  const _PeriodShare({required this.id, @JsonKey(name: 'investment_period_id') required this.investmentPeriodId, @JsonKey(name: 'investor_id') required this.investorId, @JsonKey(name: 'investor_name') this.investorName, @JsonKey(name: 'is_company') this.isCompany = false, this.capital = '0.00', @JsonKey(name: 'share_percent') this.sharePercent = '0.0000', @JsonKey(name: 'net_share') this.netShare = '0.00'});
  factory _PeriodShare.fromJson(Map<String, dynamic> json) => _$PeriodShareFromJson(json);

@override final  int id;
@override@JsonKey(name: 'investment_period_id') final  int investmentPeriodId;
@override@JsonKey(name: 'investor_id') final  int investorId;
@override@JsonKey(name: 'investor_name') final  String? investorName;
/// The company's row. `sharePercent` on it is 100 of its own side, which is what it is — the
/// figure that means something for the company is [netShare], because its take is the residual
/// of the division rather than a slice of the investors' half.
@override@JsonKey(name: 'is_company') final  bool isCompany;
/// What he had in the pool when the period closed.
@override@JsonKey() final  String capital;
/// His weight of the investors' half, as applied.
@override@JsonKey(name: 'share_percent') final  String sharePercent;
/// What the division actually gave him — **negative in a losing period**.
@override@JsonKey(name: 'net_share') final  String netShare;

/// Create a copy of PeriodShare
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodShareCopyWith<_PeriodShare> get copyWith => __$PeriodShareCopyWithImpl<_PeriodShare>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodShareToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodShare&&(identical(other.id, id) || other.id == id)&&(identical(other.investmentPeriodId, investmentPeriodId) || other.investmentPeriodId == investmentPeriodId)&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.investorName, investorName) || other.investorName == investorName)&&(identical(other.isCompany, isCompany) || other.isCompany == isCompany)&&(identical(other.capital, capital) || other.capital == capital)&&(identical(other.sharePercent, sharePercent) || other.sharePercent == sharePercent)&&(identical(other.netShare, netShare) || other.netShare == netShare));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,investmentPeriodId,investorId,investorName,isCompany,capital,sharePercent,netShare);

@override
String toString() {
  return 'PeriodShare(id: $id, investmentPeriodId: $investmentPeriodId, investorId: $investorId, investorName: $investorName, isCompany: $isCompany, capital: $capital, sharePercent: $sharePercent, netShare: $netShare)';
}


}

/// @nodoc
abstract mixin class _$PeriodShareCopyWith<$Res> implements $PeriodShareCopyWith<$Res> {
  factory _$PeriodShareCopyWith(_PeriodShare value, $Res Function(_PeriodShare) _then) = __$PeriodShareCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'investment_period_id') int investmentPeriodId,@JsonKey(name: 'investor_id') int investorId,@JsonKey(name: 'investor_name') String? investorName,@JsonKey(name: 'is_company') bool isCompany, String capital,@JsonKey(name: 'share_percent') String sharePercent,@JsonKey(name: 'net_share') String netShare
});




}
/// @nodoc
class __$PeriodShareCopyWithImpl<$Res>
    implements _$PeriodShareCopyWith<$Res> {
  __$PeriodShareCopyWithImpl(this._self, this._then);

  final _PeriodShare _self;
  final $Res Function(_PeriodShare) _then;

/// Create a copy of PeriodShare
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? investmentPeriodId = null,Object? investorId = null,Object? investorName = freezed,Object? isCompany = null,Object? capital = null,Object? sharePercent = null,Object? netShare = null,}) {
  return _then(_PeriodShare(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,investmentPeriodId: null == investmentPeriodId ? _self.investmentPeriodId : investmentPeriodId // ignore: cast_nullable_to_non_nullable
as int,investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as int,investorName: freezed == investorName ? _self.investorName : investorName // ignore: cast_nullable_to_non_nullable
as String?,isCompany: null == isCompany ? _self.isCompany : isCompany // ignore: cast_nullable_to_non_nullable
as bool,capital: null == capital ? _self.capital : capital // ignore: cast_nullable_to_non_nullable
as String,sharePercent: null == sharePercent ? _self.sharePercent : sharePercent // ignore: cast_nullable_to_non_nullable
as String,netShare: null == netShare ? _self.netShare : netShare // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
