// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'investor_portfolio.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InvestorPortfolio {

 InvestorIdentity get investor;/// His money with the company, committed to nothing.
@JsonKey(name: 'capital_in_wallet') String get capitalInWallet;/// His money currently financing goods on a shelf.
@JsonKey(name: 'capital_in_deals') String get capitalInDeals;@JsonKey(name: 'capital_total') String get capitalTotal;/// Earned by deals still running. His, but not yet his to take.
@JsonKey(name: 'profit_in_deals') String get profitInDeals;/// Released by a closed deal, and withdrawable.
@JsonKey(name: 'profit_available') String get profitAvailable;@JsonKey(name: 'profit_withdrawn') String get profitWithdrawn; List<InvestorDealLine> get deals;/// **موقفُه من الصندوق المستمرّ** — وهو اليوم الطريقُ الذي يدخل منه شريكٌ جديد.
///
/// `null` لمن لا وحداتِ له: شريكٌ قديم في صفقاتٍ وحدها. ولا يُعرض صفراً عندها، لأن «لا
/// شيء بعد» و«صفر» جوابان مختلفان.
 FundShare? get fund;
/// Create a copy of InvestorPortfolio
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestorPortfolioCopyWith<InvestorPortfolio> get copyWith => _$InvestorPortfolioCopyWithImpl<InvestorPortfolio>(this as InvestorPortfolio, _$identity);

  /// Serializes this InvestorPortfolio to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestorPortfolio&&(identical(other.investor, investor) || other.investor == investor)&&(identical(other.capitalInWallet, capitalInWallet) || other.capitalInWallet == capitalInWallet)&&(identical(other.capitalInDeals, capitalInDeals) || other.capitalInDeals == capitalInDeals)&&(identical(other.capitalTotal, capitalTotal) || other.capitalTotal == capitalTotal)&&(identical(other.profitInDeals, profitInDeals) || other.profitInDeals == profitInDeals)&&(identical(other.profitAvailable, profitAvailable) || other.profitAvailable == profitAvailable)&&(identical(other.profitWithdrawn, profitWithdrawn) || other.profitWithdrawn == profitWithdrawn)&&const DeepCollectionEquality().equals(other.deals, deals)&&(identical(other.fund, fund) || other.fund == fund));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,investor,capitalInWallet,capitalInDeals,capitalTotal,profitInDeals,profitAvailable,profitWithdrawn,const DeepCollectionEquality().hash(deals),fund);

@override
String toString() {
  return 'InvestorPortfolio(investor: $investor, capitalInWallet: $capitalInWallet, capitalInDeals: $capitalInDeals, capitalTotal: $capitalTotal, profitInDeals: $profitInDeals, profitAvailable: $profitAvailable, profitWithdrawn: $profitWithdrawn, deals: $deals, fund: $fund)';
}


}

/// @nodoc
abstract mixin class $InvestorPortfolioCopyWith<$Res>  {
  factory $InvestorPortfolioCopyWith(InvestorPortfolio value, $Res Function(InvestorPortfolio) _then) = _$InvestorPortfolioCopyWithImpl;
@useResult
$Res call({
 InvestorIdentity investor,@JsonKey(name: 'capital_in_wallet') String capitalInWallet,@JsonKey(name: 'capital_in_deals') String capitalInDeals,@JsonKey(name: 'capital_total') String capitalTotal,@JsonKey(name: 'profit_in_deals') String profitInDeals,@JsonKey(name: 'profit_available') String profitAvailable,@JsonKey(name: 'profit_withdrawn') String profitWithdrawn, List<InvestorDealLine> deals, FundShare? fund
});


$InvestorIdentityCopyWith<$Res> get investor;$FundShareCopyWith<$Res>? get fund;

}
/// @nodoc
class _$InvestorPortfolioCopyWithImpl<$Res>
    implements $InvestorPortfolioCopyWith<$Res> {
  _$InvestorPortfolioCopyWithImpl(this._self, this._then);

  final InvestorPortfolio _self;
  final $Res Function(InvestorPortfolio) _then;

/// Create a copy of InvestorPortfolio
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? investor = null,Object? capitalInWallet = null,Object? capitalInDeals = null,Object? capitalTotal = null,Object? profitInDeals = null,Object? profitAvailable = null,Object? profitWithdrawn = null,Object? deals = null,Object? fund = freezed,}) {
  return _then(_self.copyWith(
investor: null == investor ? _self.investor : investor // ignore: cast_nullable_to_non_nullable
as InvestorIdentity,capitalInWallet: null == capitalInWallet ? _self.capitalInWallet : capitalInWallet // ignore: cast_nullable_to_non_nullable
as String,capitalInDeals: null == capitalInDeals ? _self.capitalInDeals : capitalInDeals // ignore: cast_nullable_to_non_nullable
as String,capitalTotal: null == capitalTotal ? _self.capitalTotal : capitalTotal // ignore: cast_nullable_to_non_nullable
as String,profitInDeals: null == profitInDeals ? _self.profitInDeals : profitInDeals // ignore: cast_nullable_to_non_nullable
as String,profitAvailable: null == profitAvailable ? _self.profitAvailable : profitAvailable // ignore: cast_nullable_to_non_nullable
as String,profitWithdrawn: null == profitWithdrawn ? _self.profitWithdrawn : profitWithdrawn // ignore: cast_nullable_to_non_nullable
as String,deals: null == deals ? _self.deals : deals // ignore: cast_nullable_to_non_nullable
as List<InvestorDealLine>,fund: freezed == fund ? _self.fund : fund // ignore: cast_nullable_to_non_nullable
as FundShare?,
  ));
}
/// Create a copy of InvestorPortfolio
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvestorIdentityCopyWith<$Res> get investor {
  
  return $InvestorIdentityCopyWith<$Res>(_self.investor, (value) {
    return _then(_self.copyWith(investor: value));
  });
}/// Create a copy of InvestorPortfolio
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


/// Adds pattern-matching-related methods to [InvestorPortfolio].
extension InvestorPortfolioPatterns on InvestorPortfolio {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvestorPortfolio value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvestorPortfolio() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvestorPortfolio value)  $default,){
final _that = this;
switch (_that) {
case _InvestorPortfolio():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvestorPortfolio value)?  $default,){
final _that = this;
switch (_that) {
case _InvestorPortfolio() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( InvestorIdentity investor, @JsonKey(name: 'capital_in_wallet')  String capitalInWallet, @JsonKey(name: 'capital_in_deals')  String capitalInDeals, @JsonKey(name: 'capital_total')  String capitalTotal, @JsonKey(name: 'profit_in_deals')  String profitInDeals, @JsonKey(name: 'profit_available')  String profitAvailable, @JsonKey(name: 'profit_withdrawn')  String profitWithdrawn,  List<InvestorDealLine> deals,  FundShare? fund)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvestorPortfolio() when $default != null:
return $default(_that.investor,_that.capitalInWallet,_that.capitalInDeals,_that.capitalTotal,_that.profitInDeals,_that.profitAvailable,_that.profitWithdrawn,_that.deals,_that.fund);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( InvestorIdentity investor, @JsonKey(name: 'capital_in_wallet')  String capitalInWallet, @JsonKey(name: 'capital_in_deals')  String capitalInDeals, @JsonKey(name: 'capital_total')  String capitalTotal, @JsonKey(name: 'profit_in_deals')  String profitInDeals, @JsonKey(name: 'profit_available')  String profitAvailable, @JsonKey(name: 'profit_withdrawn')  String profitWithdrawn,  List<InvestorDealLine> deals,  FundShare? fund)  $default,) {final _that = this;
switch (_that) {
case _InvestorPortfolio():
return $default(_that.investor,_that.capitalInWallet,_that.capitalInDeals,_that.capitalTotal,_that.profitInDeals,_that.profitAvailable,_that.profitWithdrawn,_that.deals,_that.fund);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( InvestorIdentity investor, @JsonKey(name: 'capital_in_wallet')  String capitalInWallet, @JsonKey(name: 'capital_in_deals')  String capitalInDeals, @JsonKey(name: 'capital_total')  String capitalTotal, @JsonKey(name: 'profit_in_deals')  String profitInDeals, @JsonKey(name: 'profit_available')  String profitAvailable, @JsonKey(name: 'profit_withdrawn')  String profitWithdrawn,  List<InvestorDealLine> deals,  FundShare? fund)?  $default,) {final _that = this;
switch (_that) {
case _InvestorPortfolio() when $default != null:
return $default(_that.investor,_that.capitalInWallet,_that.capitalInDeals,_that.capitalTotal,_that.profitInDeals,_that.profitAvailable,_that.profitWithdrawn,_that.deals,_that.fund);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvestorPortfolio implements InvestorPortfolio {
  const _InvestorPortfolio({required this.investor, @JsonKey(name: 'capital_in_wallet') required this.capitalInWallet, @JsonKey(name: 'capital_in_deals') required this.capitalInDeals, @JsonKey(name: 'capital_total') required this.capitalTotal, @JsonKey(name: 'profit_in_deals') required this.profitInDeals, @JsonKey(name: 'profit_available') required this.profitAvailable, @JsonKey(name: 'profit_withdrawn') required this.profitWithdrawn, final  List<InvestorDealLine> deals = const <InvestorDealLine>[], this.fund}): _deals = deals;
  factory _InvestorPortfolio.fromJson(Map<String, dynamic> json) => _$InvestorPortfolioFromJson(json);

@override final  InvestorIdentity investor;
/// His money with the company, committed to nothing.
@override@JsonKey(name: 'capital_in_wallet') final  String capitalInWallet;
/// His money currently financing goods on a shelf.
@override@JsonKey(name: 'capital_in_deals') final  String capitalInDeals;
@override@JsonKey(name: 'capital_total') final  String capitalTotal;
/// Earned by deals still running. His, but not yet his to take.
@override@JsonKey(name: 'profit_in_deals') final  String profitInDeals;
/// Released by a closed deal, and withdrawable.
@override@JsonKey(name: 'profit_available') final  String profitAvailable;
@override@JsonKey(name: 'profit_withdrawn') final  String profitWithdrawn;
 final  List<InvestorDealLine> _deals;
@override@JsonKey() List<InvestorDealLine> get deals {
  if (_deals is EqualUnmodifiableListView) return _deals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deals);
}

/// **موقفُه من الصندوق المستمرّ** — وهو اليوم الطريقُ الذي يدخل منه شريكٌ جديد.
///
/// `null` لمن لا وحداتِ له: شريكٌ قديم في صفقاتٍ وحدها. ولا يُعرض صفراً عندها، لأن «لا
/// شيء بعد» و«صفر» جوابان مختلفان.
@override final  FundShare? fund;

/// Create a copy of InvestorPortfolio
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvestorPortfolioCopyWith<_InvestorPortfolio> get copyWith => __$InvestorPortfolioCopyWithImpl<_InvestorPortfolio>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvestorPortfolioToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvestorPortfolio&&(identical(other.investor, investor) || other.investor == investor)&&(identical(other.capitalInWallet, capitalInWallet) || other.capitalInWallet == capitalInWallet)&&(identical(other.capitalInDeals, capitalInDeals) || other.capitalInDeals == capitalInDeals)&&(identical(other.capitalTotal, capitalTotal) || other.capitalTotal == capitalTotal)&&(identical(other.profitInDeals, profitInDeals) || other.profitInDeals == profitInDeals)&&(identical(other.profitAvailable, profitAvailable) || other.profitAvailable == profitAvailable)&&(identical(other.profitWithdrawn, profitWithdrawn) || other.profitWithdrawn == profitWithdrawn)&&const DeepCollectionEquality().equals(other._deals, _deals)&&(identical(other.fund, fund) || other.fund == fund));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,investor,capitalInWallet,capitalInDeals,capitalTotal,profitInDeals,profitAvailable,profitWithdrawn,const DeepCollectionEquality().hash(_deals),fund);

@override
String toString() {
  return 'InvestorPortfolio(investor: $investor, capitalInWallet: $capitalInWallet, capitalInDeals: $capitalInDeals, capitalTotal: $capitalTotal, profitInDeals: $profitInDeals, profitAvailable: $profitAvailable, profitWithdrawn: $profitWithdrawn, deals: $deals, fund: $fund)';
}


}

/// @nodoc
abstract mixin class _$InvestorPortfolioCopyWith<$Res> implements $InvestorPortfolioCopyWith<$Res> {
  factory _$InvestorPortfolioCopyWith(_InvestorPortfolio value, $Res Function(_InvestorPortfolio) _then) = __$InvestorPortfolioCopyWithImpl;
@override @useResult
$Res call({
 InvestorIdentity investor,@JsonKey(name: 'capital_in_wallet') String capitalInWallet,@JsonKey(name: 'capital_in_deals') String capitalInDeals,@JsonKey(name: 'capital_total') String capitalTotal,@JsonKey(name: 'profit_in_deals') String profitInDeals,@JsonKey(name: 'profit_available') String profitAvailable,@JsonKey(name: 'profit_withdrawn') String profitWithdrawn, List<InvestorDealLine> deals, FundShare? fund
});


@override $InvestorIdentityCopyWith<$Res> get investor;@override $FundShareCopyWith<$Res>? get fund;

}
/// @nodoc
class __$InvestorPortfolioCopyWithImpl<$Res>
    implements _$InvestorPortfolioCopyWith<$Res> {
  __$InvestorPortfolioCopyWithImpl(this._self, this._then);

  final _InvestorPortfolio _self;
  final $Res Function(_InvestorPortfolio) _then;

/// Create a copy of InvestorPortfolio
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? investor = null,Object? capitalInWallet = null,Object? capitalInDeals = null,Object? capitalTotal = null,Object? profitInDeals = null,Object? profitAvailable = null,Object? profitWithdrawn = null,Object? deals = null,Object? fund = freezed,}) {
  return _then(_InvestorPortfolio(
investor: null == investor ? _self.investor : investor // ignore: cast_nullable_to_non_nullable
as InvestorIdentity,capitalInWallet: null == capitalInWallet ? _self.capitalInWallet : capitalInWallet // ignore: cast_nullable_to_non_nullable
as String,capitalInDeals: null == capitalInDeals ? _self.capitalInDeals : capitalInDeals // ignore: cast_nullable_to_non_nullable
as String,capitalTotal: null == capitalTotal ? _self.capitalTotal : capitalTotal // ignore: cast_nullable_to_non_nullable
as String,profitInDeals: null == profitInDeals ? _self.profitInDeals : profitInDeals // ignore: cast_nullable_to_non_nullable
as String,profitAvailable: null == profitAvailable ? _self.profitAvailable : profitAvailable // ignore: cast_nullable_to_non_nullable
as String,profitWithdrawn: null == profitWithdrawn ? _self.profitWithdrawn : profitWithdrawn // ignore: cast_nullable_to_non_nullable
as String,deals: null == deals ? _self._deals : deals // ignore: cast_nullable_to_non_nullable
as List<InvestorDealLine>,fund: freezed == fund ? _self.fund : fund // ignore: cast_nullable_to_non_nullable
as FundShare?,
  ));
}

/// Create a copy of InvestorPortfolio
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvestorIdentityCopyWith<$Res> get investor {
  
  return $InvestorIdentityCopyWith<$Res>(_self.investor, (value) {
    return _then(_self.copyWith(investor: value));
  });
}/// Create a copy of InvestorPortfolio
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
mixin _$InvestorIdentity {

 int get id;/// «I7» — what staff say out loud, and what he quotes when he calls.
 String get code; String get name;
/// Create a copy of InvestorIdentity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestorIdentityCopyWith<InvestorIdentity> get copyWith => _$InvestorIdentityCopyWithImpl<InvestorIdentity>(this as InvestorIdentity, _$identity);

  /// Serializes this InvestorIdentity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestorIdentity&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name);

@override
String toString() {
  return 'InvestorIdentity(id: $id, code: $code, name: $name)';
}


}

/// @nodoc
abstract mixin class $InvestorIdentityCopyWith<$Res>  {
  factory $InvestorIdentityCopyWith(InvestorIdentity value, $Res Function(InvestorIdentity) _then) = _$InvestorIdentityCopyWithImpl;
@useResult
$Res call({
 int id, String code, String name
});




}
/// @nodoc
class _$InvestorIdentityCopyWithImpl<$Res>
    implements $InvestorIdentityCopyWith<$Res> {
  _$InvestorIdentityCopyWithImpl(this._self, this._then);

  final InvestorIdentity _self;
  final $Res Function(InvestorIdentity) _then;

/// Create a copy of InvestorIdentity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [InvestorIdentity].
extension InvestorIdentityPatterns on InvestorIdentity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvestorIdentity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvestorIdentity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvestorIdentity value)  $default,){
final _that = this;
switch (_that) {
case _InvestorIdentity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvestorIdentity value)?  $default,){
final _that = this;
switch (_that) {
case _InvestorIdentity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvestorIdentity() when $default != null:
return $default(_that.id,_that.code,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String name)  $default,) {final _that = this;
switch (_that) {
case _InvestorIdentity():
return $default(_that.id,_that.code,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String name)?  $default,) {final _that = this;
switch (_that) {
case _InvestorIdentity() when $default != null:
return $default(_that.id,_that.code,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvestorIdentity implements InvestorIdentity {
  const _InvestorIdentity({required this.id, required this.code, required this.name});
  factory _InvestorIdentity.fromJson(Map<String, dynamic> json) => _$InvestorIdentityFromJson(json);

@override final  int id;
/// «I7» — what staff say out loud, and what he quotes when he calls.
@override final  String code;
@override final  String name;

/// Create a copy of InvestorIdentity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvestorIdentityCopyWith<_InvestorIdentity> get copyWith => __$InvestorIdentityCopyWithImpl<_InvestorIdentity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvestorIdentityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvestorIdentity&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name);

@override
String toString() {
  return 'InvestorIdentity(id: $id, code: $code, name: $name)';
}


}

/// @nodoc
abstract mixin class _$InvestorIdentityCopyWith<$Res> implements $InvestorIdentityCopyWith<$Res> {
  factory _$InvestorIdentityCopyWith(_InvestorIdentity value, $Res Function(_InvestorIdentity) _then) = __$InvestorIdentityCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String name
});




}
/// @nodoc
class __$InvestorIdentityCopyWithImpl<$Res>
    implements _$InvestorIdentityCopyWith<$Res> {
  __$InvestorIdentityCopyWithImpl(this._self, this._then);

  final _InvestorIdentity _self;
  final $Res Function(_InvestorIdentity) _then;

/// Create a copy of InvestorIdentity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,}) {
  return _then(_InvestorIdentity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$InvestorDealLine {

 int get id; String? get code; String? get status;/// The Arabic to print. Sent by the server so the app keeps no translation table in step.
@JsonKey(name: 'status_label') String? get statusLabel;/// His slice **of the investors' share** of this deal — not of its whole profit.
@JsonKey(name: 'share_percent') String get sharePercent; String get capital; String get profit;
/// Create a copy of InvestorDealLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestorDealLineCopyWith<InvestorDealLine> get copyWith => _$InvestorDealLineCopyWithImpl<InvestorDealLine>(this as InvestorDealLine, _$identity);

  /// Serializes this InvestorDealLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestorDealLine&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.sharePercent, sharePercent) || other.sharePercent == sharePercent)&&(identical(other.capital, capital) || other.capital == capital)&&(identical(other.profit, profit) || other.profit == profit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,status,statusLabel,sharePercent,capital,profit);

@override
String toString() {
  return 'InvestorDealLine(id: $id, code: $code, status: $status, statusLabel: $statusLabel, sharePercent: $sharePercent, capital: $capital, profit: $profit)';
}


}

/// @nodoc
abstract mixin class $InvestorDealLineCopyWith<$Res>  {
  factory $InvestorDealLineCopyWith(InvestorDealLine value, $Res Function(InvestorDealLine) _then) = _$InvestorDealLineCopyWithImpl;
@useResult
$Res call({
 int id, String? code, String? status,@JsonKey(name: 'status_label') String? statusLabel,@JsonKey(name: 'share_percent') String sharePercent, String capital, String profit
});




}
/// @nodoc
class _$InvestorDealLineCopyWithImpl<$Res>
    implements $InvestorDealLineCopyWith<$Res> {
  _$InvestorDealLineCopyWithImpl(this._self, this._then);

  final InvestorDealLine _self;
  final $Res Function(InvestorDealLine) _then;

/// Create a copy of InvestorDealLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = freezed,Object? status = freezed,Object? statusLabel = freezed,Object? sharePercent = null,Object? capital = null,Object? profit = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,statusLabel: freezed == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String?,sharePercent: null == sharePercent ? _self.sharePercent : sharePercent // ignore: cast_nullable_to_non_nullable
as String,capital: null == capital ? _self.capital : capital // ignore: cast_nullable_to_non_nullable
as String,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [InvestorDealLine].
extension InvestorDealLinePatterns on InvestorDealLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvestorDealLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvestorDealLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvestorDealLine value)  $default,){
final _that = this;
switch (_that) {
case _InvestorDealLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvestorDealLine value)?  $default,){
final _that = this;
switch (_that) {
case _InvestorDealLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? code,  String? status, @JsonKey(name: 'status_label')  String? statusLabel, @JsonKey(name: 'share_percent')  String sharePercent,  String capital,  String profit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvestorDealLine() when $default != null:
return $default(_that.id,_that.code,_that.status,_that.statusLabel,_that.sharePercent,_that.capital,_that.profit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? code,  String? status, @JsonKey(name: 'status_label')  String? statusLabel, @JsonKey(name: 'share_percent')  String sharePercent,  String capital,  String profit)  $default,) {final _that = this;
switch (_that) {
case _InvestorDealLine():
return $default(_that.id,_that.code,_that.status,_that.statusLabel,_that.sharePercent,_that.capital,_that.profit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? code,  String? status, @JsonKey(name: 'status_label')  String? statusLabel, @JsonKey(name: 'share_percent')  String sharePercent,  String capital,  String profit)?  $default,) {final _that = this;
switch (_that) {
case _InvestorDealLine() when $default != null:
return $default(_that.id,_that.code,_that.status,_that.statusLabel,_that.sharePercent,_that.capital,_that.profit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvestorDealLine implements InvestorDealLine {
  const _InvestorDealLine({required this.id, this.code, this.status, @JsonKey(name: 'status_label') this.statusLabel, @JsonKey(name: 'share_percent') required this.sharePercent, required this.capital, required this.profit});
  factory _InvestorDealLine.fromJson(Map<String, dynamic> json) => _$InvestorDealLineFromJson(json);

@override final  int id;
@override final  String? code;
@override final  String? status;
/// The Arabic to print. Sent by the server so the app keeps no translation table in step.
@override@JsonKey(name: 'status_label') final  String? statusLabel;
/// His slice **of the investors' share** of this deal — not of its whole profit.
@override@JsonKey(name: 'share_percent') final  String sharePercent;
@override final  String capital;
@override final  String profit;

/// Create a copy of InvestorDealLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvestorDealLineCopyWith<_InvestorDealLine> get copyWith => __$InvestorDealLineCopyWithImpl<_InvestorDealLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvestorDealLineToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvestorDealLine&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.sharePercent, sharePercent) || other.sharePercent == sharePercent)&&(identical(other.capital, capital) || other.capital == capital)&&(identical(other.profit, profit) || other.profit == profit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,status,statusLabel,sharePercent,capital,profit);

@override
String toString() {
  return 'InvestorDealLine(id: $id, code: $code, status: $status, statusLabel: $statusLabel, sharePercent: $sharePercent, capital: $capital, profit: $profit)';
}


}

/// @nodoc
abstract mixin class _$InvestorDealLineCopyWith<$Res> implements $InvestorDealLineCopyWith<$Res> {
  factory _$InvestorDealLineCopyWith(_InvestorDealLine value, $Res Function(_InvestorDealLine) _then) = __$InvestorDealLineCopyWithImpl;
@override @useResult
$Res call({
 int id, String? code, String? status,@JsonKey(name: 'status_label') String? statusLabel,@JsonKey(name: 'share_percent') String sharePercent, String capital, String profit
});




}
/// @nodoc
class __$InvestorDealLineCopyWithImpl<$Res>
    implements _$InvestorDealLineCopyWith<$Res> {
  __$InvestorDealLineCopyWithImpl(this._self, this._then);

  final _InvestorDealLine _self;
  final $Res Function(_InvestorDealLine) _then;

/// Create a copy of InvestorDealLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = freezed,Object? status = freezed,Object? statusLabel = freezed,Object? sharePercent = null,Object? capital = null,Object? profit = null,}) {
  return _then(_InvestorDealLine(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,statusLabel: freezed == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String?,sharePercent: null == sharePercent ? _self.sharePercent : sharePercent // ignore: cast_nullable_to_non_nullable
as String,capital: null == capital ? _self.capital : capital // ignore: cast_nullable_to_non_nullable
as String,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$FundShare {

 String get units;@JsonKey(name: 'unit_price') String get unitPrice;/// وحداتُه × السعر — ما يساويه نصيبُه لو قُوِّم اليوم.
 String get value;/// نسبتُه من ربح هذه الفترة. مربوطةٌ بالفترة لا بالحاضر: من دخل بعد إغلاق النافذة نسبتُه
/// في التالية.
@JsonKey(name: 'share_percent') String get sharePercent;/// ما انقضت مدةُ حبسه من وحداته — وحده ما يمكن أن يخرج.
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundShare&&(identical(other.units, units) || other.units == units)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.value, value) || other.value == value)&&(identical(other.sharePercent, sharePercent) || other.sharePercent == sharePercent)&&(identical(other.unlockedUnits, unlockedUnits) || other.unlockedUnits == unlockedUnits)&&(identical(other.period, period) || other.period == period)&&const DeepCollectionEquality().equals(other.deposits, deposits));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,units,unitPrice,value,sharePercent,unlockedUnits,period,const DeepCollectionEquality().hash(deposits));

@override
String toString() {
  return 'FundShare(units: $units, unitPrice: $unitPrice, value: $value, sharePercent: $sharePercent, unlockedUnits: $unlockedUnits, period: $period, deposits: $deposits)';
}


}

/// @nodoc
abstract mixin class $FundShareCopyWith<$Res>  {
  factory $FundShareCopyWith(FundShare value, $Res Function(FundShare) _then) = _$FundShareCopyWithImpl;
@useResult
$Res call({
 String units,@JsonKey(name: 'unit_price') String unitPrice, String value,@JsonKey(name: 'share_percent') String sharePercent,@JsonKey(name: 'unlocked_units') String unlockedUnits, FundPeriodBrief? period, List<FundDeposit> deposits
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
@pragma('vm:prefer-inline') @override $Res call({Object? units = null,Object? unitPrice = null,Object? value = null,Object? sharePercent = null,Object? unlockedUnits = null,Object? period = freezed,Object? deposits = null,}) {
  return _then(_self.copyWith(
units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,sharePercent: null == sharePercent ? _self.sharePercent : sharePercent // ignore: cast_nullable_to_non_nullable
as String,unlockedUnits: null == unlockedUnits ? _self.unlockedUnits : unlockedUnits // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String units, @JsonKey(name: 'unit_price')  String unitPrice,  String value, @JsonKey(name: 'share_percent')  String sharePercent, @JsonKey(name: 'unlocked_units')  String unlockedUnits,  FundPeriodBrief? period,  List<FundDeposit> deposits)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundShare() when $default != null:
return $default(_that.units,_that.unitPrice,_that.value,_that.sharePercent,_that.unlockedUnits,_that.period,_that.deposits);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String units, @JsonKey(name: 'unit_price')  String unitPrice,  String value, @JsonKey(name: 'share_percent')  String sharePercent, @JsonKey(name: 'unlocked_units')  String unlockedUnits,  FundPeriodBrief? period,  List<FundDeposit> deposits)  $default,) {final _that = this;
switch (_that) {
case _FundShare():
return $default(_that.units,_that.unitPrice,_that.value,_that.sharePercent,_that.unlockedUnits,_that.period,_that.deposits);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String units, @JsonKey(name: 'unit_price')  String unitPrice,  String value, @JsonKey(name: 'share_percent')  String sharePercent, @JsonKey(name: 'unlocked_units')  String unlockedUnits,  FundPeriodBrief? period,  List<FundDeposit> deposits)?  $default,) {final _that = this;
switch (_that) {
case _FundShare() when $default != null:
return $default(_that.units,_that.unitPrice,_that.value,_that.sharePercent,_that.unlockedUnits,_that.period,_that.deposits);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundShare implements FundShare {
  const _FundShare({required this.units, @JsonKey(name: 'unit_price') required this.unitPrice, required this.value, @JsonKey(name: 'share_percent') required this.sharePercent, @JsonKey(name: 'unlocked_units') this.unlockedUnits = '0.000000', this.period, final  List<FundDeposit> deposits = const <FundDeposit>[]}): _deposits = deposits;
  factory _FundShare.fromJson(Map<String, dynamic> json) => _$FundShareFromJson(json);

@override final  String units;
@override@JsonKey(name: 'unit_price') final  String unitPrice;
/// وحداتُه × السعر — ما يساويه نصيبُه لو قُوِّم اليوم.
@override final  String value;
/// نسبتُه من ربح هذه الفترة. مربوطةٌ بالفترة لا بالحاضر: من دخل بعد إغلاق النافذة نسبتُه
/// في التالية.
@override@JsonKey(name: 'share_percent') final  String sharePercent;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundShare&&(identical(other.units, units) || other.units == units)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.value, value) || other.value == value)&&(identical(other.sharePercent, sharePercent) || other.sharePercent == sharePercent)&&(identical(other.unlockedUnits, unlockedUnits) || other.unlockedUnits == unlockedUnits)&&(identical(other.period, period) || other.period == period)&&const DeepCollectionEquality().equals(other._deposits, _deposits));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,units,unitPrice,value,sharePercent,unlockedUnits,period,const DeepCollectionEquality().hash(_deposits));

@override
String toString() {
  return 'FundShare(units: $units, unitPrice: $unitPrice, value: $value, sharePercent: $sharePercent, unlockedUnits: $unlockedUnits, period: $period, deposits: $deposits)';
}


}

/// @nodoc
abstract mixin class _$FundShareCopyWith<$Res> implements $FundShareCopyWith<$Res> {
  factory _$FundShareCopyWith(_FundShare value, $Res Function(_FundShare) _then) = __$FundShareCopyWithImpl;
@override @useResult
$Res call({
 String units,@JsonKey(name: 'unit_price') String unitPrice, String value,@JsonKey(name: 'share_percent') String sharePercent,@JsonKey(name: 'unlocked_units') String unlockedUnits, FundPeriodBrief? period, List<FundDeposit> deposits
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
@override @pragma('vm:prefer-inline') $Res call({Object? units = null,Object? unitPrice = null,Object? value = null,Object? sharePercent = null,Object? unlockedUnits = null,Object? period = freezed,Object? deposits = null,}) {
  return _then(_FundShare(
units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,sharePercent: null == sharePercent ? _self.sharePercent : sharePercent // ignore: cast_nullable_to_non_nullable
as String,unlockedUnits: null == unlockedUnits ? _self.unlockedUnits : unlockedUnits // ignore: cast_nullable_to_non_nullable
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
