// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'investor_deal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InvestorDeal {

 int get id; String get code; String get status;@JsonKey(name: 'status_label') String get statusLabel;/// Whether its terms may still be rewritten — true only while it is a draft.
@JsonKey(name: 'can_be_edited') bool get canBeEdited;/// The investors' share of **this** deal's profit, copied from the company default when it
/// was created and frozen when it opened.
@JsonKey(name: 'investor_profit_share_percent') String get investorProfitSharePercent;/// The company as a partner: what it put in beside the investors — «الباقي على الشركة» —
/// derived at funding from the lines' landed cost and frozen. Zero on a deal built by hand.
@JsonKey(name: 'company_stake') String get companyStake;/// The fraction of the goods the investors' money actually bought, frozen with the terms.
/// Every profit, loss and expense is multiplied by it before their share is taken. A deal
/// built by hand owns all of its goods, hence 100.
@JsonKey(name: 'investor_funded_percent') String get investorFundedPercent;@JsonKey(name: 'opened_on') String? get openedOn;@JsonKey(name: 'closed_at') String? get closedAt; String? get notes; List<DealParticipant> get investors; List<DealItem> get items; DealBalances? get balances; DealStock? get stock;
/// Create a copy of InvestorDeal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestorDealCopyWith<InvestorDeal> get copyWith => _$InvestorDealCopyWithImpl<InvestorDeal>(this as InvestorDeal, _$identity);

  /// Serializes this InvestorDeal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestorDeal&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.canBeEdited, canBeEdited) || other.canBeEdited == canBeEdited)&&(identical(other.investorProfitSharePercent, investorProfitSharePercent) || other.investorProfitSharePercent == investorProfitSharePercent)&&(identical(other.companyStake, companyStake) || other.companyStake == companyStake)&&(identical(other.investorFundedPercent, investorFundedPercent) || other.investorFundedPercent == investorFundedPercent)&&(identical(other.openedOn, openedOn) || other.openedOn == openedOn)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other.investors, investors)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.balances, balances) || other.balances == balances)&&(identical(other.stock, stock) || other.stock == stock));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,status,statusLabel,canBeEdited,investorProfitSharePercent,companyStake,investorFundedPercent,openedOn,closedAt,notes,const DeepCollectionEquality().hash(investors),const DeepCollectionEquality().hash(items),balances,stock);

@override
String toString() {
  return 'InvestorDeal(id: $id, code: $code, status: $status, statusLabel: $statusLabel, canBeEdited: $canBeEdited, investorProfitSharePercent: $investorProfitSharePercent, companyStake: $companyStake, investorFundedPercent: $investorFundedPercent, openedOn: $openedOn, closedAt: $closedAt, notes: $notes, investors: $investors, items: $items, balances: $balances, stock: $stock)';
}


}

/// @nodoc
abstract mixin class $InvestorDealCopyWith<$Res>  {
  factory $InvestorDealCopyWith(InvestorDeal value, $Res Function(InvestorDeal) _then) = _$InvestorDealCopyWithImpl;
@useResult
$Res call({
 int id, String code, String status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'can_be_edited') bool canBeEdited,@JsonKey(name: 'investor_profit_share_percent') String investorProfitSharePercent,@JsonKey(name: 'company_stake') String companyStake,@JsonKey(name: 'investor_funded_percent') String investorFundedPercent,@JsonKey(name: 'opened_on') String? openedOn,@JsonKey(name: 'closed_at') String? closedAt, String? notes, List<DealParticipant> investors, List<DealItem> items, DealBalances? balances, DealStock? stock
});


$DealBalancesCopyWith<$Res>? get balances;$DealStockCopyWith<$Res>? get stock;

}
/// @nodoc
class _$InvestorDealCopyWithImpl<$Res>
    implements $InvestorDealCopyWith<$Res> {
  _$InvestorDealCopyWithImpl(this._self, this._then);

  final InvestorDeal _self;
  final $Res Function(InvestorDeal) _then;

/// Create a copy of InvestorDeal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? status = null,Object? statusLabel = null,Object? canBeEdited = null,Object? investorProfitSharePercent = null,Object? companyStake = null,Object? investorFundedPercent = null,Object? openedOn = freezed,Object? closedAt = freezed,Object? notes = freezed,Object? investors = null,Object? items = null,Object? balances = freezed,Object? stock = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,canBeEdited: null == canBeEdited ? _self.canBeEdited : canBeEdited // ignore: cast_nullable_to_non_nullable
as bool,investorProfitSharePercent: null == investorProfitSharePercent ? _self.investorProfitSharePercent : investorProfitSharePercent // ignore: cast_nullable_to_non_nullable
as String,companyStake: null == companyStake ? _self.companyStake : companyStake // ignore: cast_nullable_to_non_nullable
as String,investorFundedPercent: null == investorFundedPercent ? _self.investorFundedPercent : investorFundedPercent // ignore: cast_nullable_to_non_nullable
as String,openedOn: freezed == openedOn ? _self.openedOn : openedOn // ignore: cast_nullable_to_non_nullable
as String?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,investors: null == investors ? _self.investors : investors // ignore: cast_nullable_to_non_nullable
as List<DealParticipant>,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<DealItem>,balances: freezed == balances ? _self.balances : balances // ignore: cast_nullable_to_non_nullable
as DealBalances?,stock: freezed == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as DealStock?,
  ));
}
/// Create a copy of InvestorDeal
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DealBalancesCopyWith<$Res>? get balances {
    if (_self.balances == null) {
    return null;
  }

  return $DealBalancesCopyWith<$Res>(_self.balances!, (value) {
    return _then(_self.copyWith(balances: value));
  });
}/// Create a copy of InvestorDeal
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DealStockCopyWith<$Res>? get stock {
    if (_self.stock == null) {
    return null;
  }

  return $DealStockCopyWith<$Res>(_self.stock!, (value) {
    return _then(_self.copyWith(stock: value));
  });
}
}


/// Adds pattern-matching-related methods to [InvestorDeal].
extension InvestorDealPatterns on InvestorDeal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvestorDeal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvestorDeal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvestorDeal value)  $default,){
final _that = this;
switch (_that) {
case _InvestorDeal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvestorDeal value)?  $default,){
final _that = this;
switch (_that) {
case _InvestorDeal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'can_be_edited')  bool canBeEdited, @JsonKey(name: 'investor_profit_share_percent')  String investorProfitSharePercent, @JsonKey(name: 'company_stake')  String companyStake, @JsonKey(name: 'investor_funded_percent')  String investorFundedPercent, @JsonKey(name: 'opened_on')  String? openedOn, @JsonKey(name: 'closed_at')  String? closedAt,  String? notes,  List<DealParticipant> investors,  List<DealItem> items,  DealBalances? balances,  DealStock? stock)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvestorDeal() when $default != null:
return $default(_that.id,_that.code,_that.status,_that.statusLabel,_that.canBeEdited,_that.investorProfitSharePercent,_that.companyStake,_that.investorFundedPercent,_that.openedOn,_that.closedAt,_that.notes,_that.investors,_that.items,_that.balances,_that.stock);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'can_be_edited')  bool canBeEdited, @JsonKey(name: 'investor_profit_share_percent')  String investorProfitSharePercent, @JsonKey(name: 'company_stake')  String companyStake, @JsonKey(name: 'investor_funded_percent')  String investorFundedPercent, @JsonKey(name: 'opened_on')  String? openedOn, @JsonKey(name: 'closed_at')  String? closedAt,  String? notes,  List<DealParticipant> investors,  List<DealItem> items,  DealBalances? balances,  DealStock? stock)  $default,) {final _that = this;
switch (_that) {
case _InvestorDeal():
return $default(_that.id,_that.code,_that.status,_that.statusLabel,_that.canBeEdited,_that.investorProfitSharePercent,_that.companyStake,_that.investorFundedPercent,_that.openedOn,_that.closedAt,_that.notes,_that.investors,_that.items,_that.balances,_that.stock);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'can_be_edited')  bool canBeEdited, @JsonKey(name: 'investor_profit_share_percent')  String investorProfitSharePercent, @JsonKey(name: 'company_stake')  String companyStake, @JsonKey(name: 'investor_funded_percent')  String investorFundedPercent, @JsonKey(name: 'opened_on')  String? openedOn, @JsonKey(name: 'closed_at')  String? closedAt,  String? notes,  List<DealParticipant> investors,  List<DealItem> items,  DealBalances? balances,  DealStock? stock)?  $default,) {final _that = this;
switch (_that) {
case _InvestorDeal() when $default != null:
return $default(_that.id,_that.code,_that.status,_that.statusLabel,_that.canBeEdited,_that.investorProfitSharePercent,_that.companyStake,_that.investorFundedPercent,_that.openedOn,_that.closedAt,_that.notes,_that.investors,_that.items,_that.balances,_that.stock);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvestorDeal implements InvestorDeal {
  const _InvestorDeal({required this.id, required this.code, required this.status, @JsonKey(name: 'status_label') required this.statusLabel, @JsonKey(name: 'can_be_edited') this.canBeEdited = false, @JsonKey(name: 'investor_profit_share_percent') required this.investorProfitSharePercent, @JsonKey(name: 'company_stake') this.companyStake = '0.00', @JsonKey(name: 'investor_funded_percent') this.investorFundedPercent = '100.0000', @JsonKey(name: 'opened_on') this.openedOn, @JsonKey(name: 'closed_at') this.closedAt, this.notes, final  List<DealParticipant> investors = const <DealParticipant>[], final  List<DealItem> items = const <DealItem>[], this.balances, this.stock}): _investors = investors,_items = items;
  factory _InvestorDeal.fromJson(Map<String, dynamic> json) => _$InvestorDealFromJson(json);

@override final  int id;
@override final  String code;
@override final  String status;
@override@JsonKey(name: 'status_label') final  String statusLabel;
/// Whether its terms may still be rewritten — true only while it is a draft.
@override@JsonKey(name: 'can_be_edited') final  bool canBeEdited;
/// The investors' share of **this** deal's profit, copied from the company default when it
/// was created and frozen when it opened.
@override@JsonKey(name: 'investor_profit_share_percent') final  String investorProfitSharePercent;
/// The company as a partner: what it put in beside the investors — «الباقي على الشركة» —
/// derived at funding from the lines' landed cost and frozen. Zero on a deal built by hand.
@override@JsonKey(name: 'company_stake') final  String companyStake;
/// The fraction of the goods the investors' money actually bought, frozen with the terms.
/// Every profit, loss and expense is multiplied by it before their share is taken. A deal
/// built by hand owns all of its goods, hence 100.
@override@JsonKey(name: 'investor_funded_percent') final  String investorFundedPercent;
@override@JsonKey(name: 'opened_on') final  String? openedOn;
@override@JsonKey(name: 'closed_at') final  String? closedAt;
@override final  String? notes;
 final  List<DealParticipant> _investors;
@override@JsonKey() List<DealParticipant> get investors {
  if (_investors is EqualUnmodifiableListView) return _investors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_investors);
}

 final  List<DealItem> _items;
@override@JsonKey() List<DealItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  DealBalances? balances;
@override final  DealStock? stock;

/// Create a copy of InvestorDeal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvestorDealCopyWith<_InvestorDeal> get copyWith => __$InvestorDealCopyWithImpl<_InvestorDeal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvestorDealToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvestorDeal&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.canBeEdited, canBeEdited) || other.canBeEdited == canBeEdited)&&(identical(other.investorProfitSharePercent, investorProfitSharePercent) || other.investorProfitSharePercent == investorProfitSharePercent)&&(identical(other.companyStake, companyStake) || other.companyStake == companyStake)&&(identical(other.investorFundedPercent, investorFundedPercent) || other.investorFundedPercent == investorFundedPercent)&&(identical(other.openedOn, openedOn) || other.openedOn == openedOn)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other._investors, _investors)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.balances, balances) || other.balances == balances)&&(identical(other.stock, stock) || other.stock == stock));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,status,statusLabel,canBeEdited,investorProfitSharePercent,companyStake,investorFundedPercent,openedOn,closedAt,notes,const DeepCollectionEquality().hash(_investors),const DeepCollectionEquality().hash(_items),balances,stock);

@override
String toString() {
  return 'InvestorDeal(id: $id, code: $code, status: $status, statusLabel: $statusLabel, canBeEdited: $canBeEdited, investorProfitSharePercent: $investorProfitSharePercent, companyStake: $companyStake, investorFundedPercent: $investorFundedPercent, openedOn: $openedOn, closedAt: $closedAt, notes: $notes, investors: $investors, items: $items, balances: $balances, stock: $stock)';
}


}

/// @nodoc
abstract mixin class _$InvestorDealCopyWith<$Res> implements $InvestorDealCopyWith<$Res> {
  factory _$InvestorDealCopyWith(_InvestorDeal value, $Res Function(_InvestorDeal) _then) = __$InvestorDealCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'can_be_edited') bool canBeEdited,@JsonKey(name: 'investor_profit_share_percent') String investorProfitSharePercent,@JsonKey(name: 'company_stake') String companyStake,@JsonKey(name: 'investor_funded_percent') String investorFundedPercent,@JsonKey(name: 'opened_on') String? openedOn,@JsonKey(name: 'closed_at') String? closedAt, String? notes, List<DealParticipant> investors, List<DealItem> items, DealBalances? balances, DealStock? stock
});


@override $DealBalancesCopyWith<$Res>? get balances;@override $DealStockCopyWith<$Res>? get stock;

}
/// @nodoc
class __$InvestorDealCopyWithImpl<$Res>
    implements _$InvestorDealCopyWith<$Res> {
  __$InvestorDealCopyWithImpl(this._self, this._then);

  final _InvestorDeal _self;
  final $Res Function(_InvestorDeal) _then;

/// Create a copy of InvestorDeal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? status = null,Object? statusLabel = null,Object? canBeEdited = null,Object? investorProfitSharePercent = null,Object? companyStake = null,Object? investorFundedPercent = null,Object? openedOn = freezed,Object? closedAt = freezed,Object? notes = freezed,Object? investors = null,Object? items = null,Object? balances = freezed,Object? stock = freezed,}) {
  return _then(_InvestorDeal(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,canBeEdited: null == canBeEdited ? _self.canBeEdited : canBeEdited // ignore: cast_nullable_to_non_nullable
as bool,investorProfitSharePercent: null == investorProfitSharePercent ? _self.investorProfitSharePercent : investorProfitSharePercent // ignore: cast_nullable_to_non_nullable
as String,companyStake: null == companyStake ? _self.companyStake : companyStake // ignore: cast_nullable_to_non_nullable
as String,investorFundedPercent: null == investorFundedPercent ? _self.investorFundedPercent : investorFundedPercent // ignore: cast_nullable_to_non_nullable
as String,openedOn: freezed == openedOn ? _self.openedOn : openedOn // ignore: cast_nullable_to_non_nullable
as String?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,investors: null == investors ? _self._investors : investors // ignore: cast_nullable_to_non_nullable
as List<DealParticipant>,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<DealItem>,balances: freezed == balances ? _self.balances : balances // ignore: cast_nullable_to_non_nullable
as DealBalances?,stock: freezed == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as DealStock?,
  ));
}

/// Create a copy of InvestorDeal
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DealBalancesCopyWith<$Res>? get balances {
    if (_self.balances == null) {
    return null;
  }

  return $DealBalancesCopyWith<$Res>(_self.balances!, (value) {
    return _then(_self.copyWith(balances: value));
  });
}/// Create a copy of InvestorDeal
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DealStockCopyWith<$Res>? get stock {
    if (_self.stock == null) {
    return null;
  }

  return $DealStockCopyWith<$Res>(_self.stock!, (value) {
    return _then(_self.copyWith(stock: value));
  });
}
}


/// @nodoc
mixin _$DealParticipant {

 int get id;@JsonKey(name: 'investor_id') int get investorId; DealInvestorRef? get investor;/// The pledge the percentage was agreed against — **not** what actually arrived, which is a
/// walk of his wallet and is shown beside it rather than merged with it.
@JsonKey(name: 'committed_amount') String get committedAmount;/// His slice of the investors' share, not of the whole profit.
@JsonKey(name: 'share_percent') String get sharePercent;
/// Create a copy of DealParticipant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DealParticipantCopyWith<DealParticipant> get copyWith => _$DealParticipantCopyWithImpl<DealParticipant>(this as DealParticipant, _$identity);

  /// Serializes this DealParticipant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DealParticipant&&(identical(other.id, id) || other.id == id)&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.investor, investor) || other.investor == investor)&&(identical(other.committedAmount, committedAmount) || other.committedAmount == committedAmount)&&(identical(other.sharePercent, sharePercent) || other.sharePercent == sharePercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,investorId,investor,committedAmount,sharePercent);

@override
String toString() {
  return 'DealParticipant(id: $id, investorId: $investorId, investor: $investor, committedAmount: $committedAmount, sharePercent: $sharePercent)';
}


}

/// @nodoc
abstract mixin class $DealParticipantCopyWith<$Res>  {
  factory $DealParticipantCopyWith(DealParticipant value, $Res Function(DealParticipant) _then) = _$DealParticipantCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'investor_id') int investorId, DealInvestorRef? investor,@JsonKey(name: 'committed_amount') String committedAmount,@JsonKey(name: 'share_percent') String sharePercent
});


$DealInvestorRefCopyWith<$Res>? get investor;

}
/// @nodoc
class _$DealParticipantCopyWithImpl<$Res>
    implements $DealParticipantCopyWith<$Res> {
  _$DealParticipantCopyWithImpl(this._self, this._then);

  final DealParticipant _self;
  final $Res Function(DealParticipant) _then;

/// Create a copy of DealParticipant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? investorId = null,Object? investor = freezed,Object? committedAmount = null,Object? sharePercent = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as int,investor: freezed == investor ? _self.investor : investor // ignore: cast_nullable_to_non_nullable
as DealInvestorRef?,committedAmount: null == committedAmount ? _self.committedAmount : committedAmount // ignore: cast_nullable_to_non_nullable
as String,sharePercent: null == sharePercent ? _self.sharePercent : sharePercent // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of DealParticipant
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DealInvestorRefCopyWith<$Res>? get investor {
    if (_self.investor == null) {
    return null;
  }

  return $DealInvestorRefCopyWith<$Res>(_self.investor!, (value) {
    return _then(_self.copyWith(investor: value));
  });
}
}


/// Adds pattern-matching-related methods to [DealParticipant].
extension DealParticipantPatterns on DealParticipant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DealParticipant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DealParticipant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DealParticipant value)  $default,){
final _that = this;
switch (_that) {
case _DealParticipant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DealParticipant value)?  $default,){
final _that = this;
switch (_that) {
case _DealParticipant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'investor_id')  int investorId,  DealInvestorRef? investor, @JsonKey(name: 'committed_amount')  String committedAmount, @JsonKey(name: 'share_percent')  String sharePercent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DealParticipant() when $default != null:
return $default(_that.id,_that.investorId,_that.investor,_that.committedAmount,_that.sharePercent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'investor_id')  int investorId,  DealInvestorRef? investor, @JsonKey(name: 'committed_amount')  String committedAmount, @JsonKey(name: 'share_percent')  String sharePercent)  $default,) {final _that = this;
switch (_that) {
case _DealParticipant():
return $default(_that.id,_that.investorId,_that.investor,_that.committedAmount,_that.sharePercent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'investor_id')  int investorId,  DealInvestorRef? investor, @JsonKey(name: 'committed_amount')  String committedAmount, @JsonKey(name: 'share_percent')  String sharePercent)?  $default,) {final _that = this;
switch (_that) {
case _DealParticipant() when $default != null:
return $default(_that.id,_that.investorId,_that.investor,_that.committedAmount,_that.sharePercent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DealParticipant implements DealParticipant {
  const _DealParticipant({required this.id, @JsonKey(name: 'investor_id') required this.investorId, this.investor, @JsonKey(name: 'committed_amount') required this.committedAmount, @JsonKey(name: 'share_percent') required this.sharePercent});
  factory _DealParticipant.fromJson(Map<String, dynamic> json) => _$DealParticipantFromJson(json);

@override final  int id;
@override@JsonKey(name: 'investor_id') final  int investorId;
@override final  DealInvestorRef? investor;
/// The pledge the percentage was agreed against — **not** what actually arrived, which is a
/// walk of his wallet and is shown beside it rather than merged with it.
@override@JsonKey(name: 'committed_amount') final  String committedAmount;
/// His slice of the investors' share, not of the whole profit.
@override@JsonKey(name: 'share_percent') final  String sharePercent;

/// Create a copy of DealParticipant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DealParticipantCopyWith<_DealParticipant> get copyWith => __$DealParticipantCopyWithImpl<_DealParticipant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DealParticipantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DealParticipant&&(identical(other.id, id) || other.id == id)&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.investor, investor) || other.investor == investor)&&(identical(other.committedAmount, committedAmount) || other.committedAmount == committedAmount)&&(identical(other.sharePercent, sharePercent) || other.sharePercent == sharePercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,investorId,investor,committedAmount,sharePercent);

@override
String toString() {
  return 'DealParticipant(id: $id, investorId: $investorId, investor: $investor, committedAmount: $committedAmount, sharePercent: $sharePercent)';
}


}

/// @nodoc
abstract mixin class _$DealParticipantCopyWith<$Res> implements $DealParticipantCopyWith<$Res> {
  factory _$DealParticipantCopyWith(_DealParticipant value, $Res Function(_DealParticipant) _then) = __$DealParticipantCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'investor_id') int investorId, DealInvestorRef? investor,@JsonKey(name: 'committed_amount') String committedAmount,@JsonKey(name: 'share_percent') String sharePercent
});


@override $DealInvestorRefCopyWith<$Res>? get investor;

}
/// @nodoc
class __$DealParticipantCopyWithImpl<$Res>
    implements _$DealParticipantCopyWith<$Res> {
  __$DealParticipantCopyWithImpl(this._self, this._then);

  final _DealParticipant _self;
  final $Res Function(_DealParticipant) _then;

/// Create a copy of DealParticipant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? investorId = null,Object? investor = freezed,Object? committedAmount = null,Object? sharePercent = null,}) {
  return _then(_DealParticipant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as int,investor: freezed == investor ? _self.investor : investor // ignore: cast_nullable_to_non_nullable
as DealInvestorRef?,committedAmount: null == committedAmount ? _self.committedAmount : committedAmount // ignore: cast_nullable_to_non_nullable
as String,sharePercent: null == sharePercent ? _self.sharePercent : sharePercent // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of DealParticipant
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DealInvestorRefCopyWith<$Res>? get investor {
    if (_self.investor == null) {
    return null;
  }

  return $DealInvestorRefCopyWith<$Res>(_self.investor!, (value) {
    return _then(_self.copyWith(investor: value));
  });
}
}


/// @nodoc
mixin _$DealInvestorRef {

 int get id; String get code; String get name;
/// Create a copy of DealInvestorRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DealInvestorRefCopyWith<DealInvestorRef> get copyWith => _$DealInvestorRefCopyWithImpl<DealInvestorRef>(this as DealInvestorRef, _$identity);

  /// Serializes this DealInvestorRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DealInvestorRef&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name);

@override
String toString() {
  return 'DealInvestorRef(id: $id, code: $code, name: $name)';
}


}

/// @nodoc
abstract mixin class $DealInvestorRefCopyWith<$Res>  {
  factory $DealInvestorRefCopyWith(DealInvestorRef value, $Res Function(DealInvestorRef) _then) = _$DealInvestorRefCopyWithImpl;
@useResult
$Res call({
 int id, String code, String name
});




}
/// @nodoc
class _$DealInvestorRefCopyWithImpl<$Res>
    implements $DealInvestorRefCopyWith<$Res> {
  _$DealInvestorRefCopyWithImpl(this._self, this._then);

  final DealInvestorRef _self;
  final $Res Function(DealInvestorRef) _then;

/// Create a copy of DealInvestorRef
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


/// Adds pattern-matching-related methods to [DealInvestorRef].
extension DealInvestorRefPatterns on DealInvestorRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DealInvestorRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DealInvestorRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DealInvestorRef value)  $default,){
final _that = this;
switch (_that) {
case _DealInvestorRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DealInvestorRef value)?  $default,){
final _that = this;
switch (_that) {
case _DealInvestorRef() when $default != null:
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
case _DealInvestorRef() when $default != null:
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
case _DealInvestorRef():
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
case _DealInvestorRef() when $default != null:
return $default(_that.id,_that.code,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DealInvestorRef implements DealInvestorRef {
  const _DealInvestorRef({required this.id, required this.code, required this.name});
  factory _DealInvestorRef.fromJson(Map<String, dynamic> json) => _$DealInvestorRefFromJson(json);

@override final  int id;
@override final  String code;
@override final  String name;

/// Create a copy of DealInvestorRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DealInvestorRefCopyWith<_DealInvestorRef> get copyWith => __$DealInvestorRefCopyWithImpl<_DealInvestorRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DealInvestorRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DealInvestorRef&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name);

@override
String toString() {
  return 'DealInvestorRef(id: $id, code: $code, name: $name)';
}


}

/// @nodoc
abstract mixin class _$DealInvestorRefCopyWith<$Res> implements $DealInvestorRefCopyWith<$Res> {
  factory _$DealInvestorRefCopyWith(_DealInvestorRef value, $Res Function(_DealInvestorRef) _then) = __$DealInvestorRefCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String name
});




}
/// @nodoc
class __$DealInvestorRefCopyWithImpl<$Res>
    implements _$DealInvestorRefCopyWith<$Res> {
  __$DealInvestorRefCopyWithImpl(this._self, this._then);

  final _DealInvestorRef _self;
  final $Res Function(_DealInvestorRef) _then;

/// Create a copy of DealInvestorRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,}) {
  return _then(_DealInvestorRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DealItem {

 int get id;@JsonKey(name: 'stock_item_id') int get stockItemId;@JsonKey(name: 'stock_item') DealStockItemRef? get stockItem;@JsonKey(name: 'quantity_expected') String? get quantityExpected;@JsonKey(name: 'expected_unit_cost') String? get expectedUnitCost;@JsonKey(name: 'expected_unit_price') String? get expectedUnitPrice;
/// Create a copy of DealItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DealItemCopyWith<DealItem> get copyWith => _$DealItemCopyWithImpl<DealItem>(this as DealItem, _$identity);

  /// Serializes this DealItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DealItem&&(identical(other.id, id) || other.id == id)&&(identical(other.stockItemId, stockItemId) || other.stockItemId == stockItemId)&&(identical(other.stockItem, stockItem) || other.stockItem == stockItem)&&(identical(other.quantityExpected, quantityExpected) || other.quantityExpected == quantityExpected)&&(identical(other.expectedUnitCost, expectedUnitCost) || other.expectedUnitCost == expectedUnitCost)&&(identical(other.expectedUnitPrice, expectedUnitPrice) || other.expectedUnitPrice == expectedUnitPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,stockItemId,stockItem,quantityExpected,expectedUnitCost,expectedUnitPrice);

@override
String toString() {
  return 'DealItem(id: $id, stockItemId: $stockItemId, stockItem: $stockItem, quantityExpected: $quantityExpected, expectedUnitCost: $expectedUnitCost, expectedUnitPrice: $expectedUnitPrice)';
}


}

/// @nodoc
abstract mixin class $DealItemCopyWith<$Res>  {
  factory $DealItemCopyWith(DealItem value, $Res Function(DealItem) _then) = _$DealItemCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'stock_item_id') int stockItemId,@JsonKey(name: 'stock_item') DealStockItemRef? stockItem,@JsonKey(name: 'quantity_expected') String? quantityExpected,@JsonKey(name: 'expected_unit_cost') String? expectedUnitCost,@JsonKey(name: 'expected_unit_price') String? expectedUnitPrice
});


$DealStockItemRefCopyWith<$Res>? get stockItem;

}
/// @nodoc
class _$DealItemCopyWithImpl<$Res>
    implements $DealItemCopyWith<$Res> {
  _$DealItemCopyWithImpl(this._self, this._then);

  final DealItem _self;
  final $Res Function(DealItem) _then;

/// Create a copy of DealItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? stockItemId = null,Object? stockItem = freezed,Object? quantityExpected = freezed,Object? expectedUnitCost = freezed,Object? expectedUnitPrice = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,stockItemId: null == stockItemId ? _self.stockItemId : stockItemId // ignore: cast_nullable_to_non_nullable
as int,stockItem: freezed == stockItem ? _self.stockItem : stockItem // ignore: cast_nullable_to_non_nullable
as DealStockItemRef?,quantityExpected: freezed == quantityExpected ? _self.quantityExpected : quantityExpected // ignore: cast_nullable_to_non_nullable
as String?,expectedUnitCost: freezed == expectedUnitCost ? _self.expectedUnitCost : expectedUnitCost // ignore: cast_nullable_to_non_nullable
as String?,expectedUnitPrice: freezed == expectedUnitPrice ? _self.expectedUnitPrice : expectedUnitPrice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of DealItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DealStockItemRefCopyWith<$Res>? get stockItem {
    if (_self.stockItem == null) {
    return null;
  }

  return $DealStockItemRefCopyWith<$Res>(_self.stockItem!, (value) {
    return _then(_self.copyWith(stockItem: value));
  });
}
}


/// Adds pattern-matching-related methods to [DealItem].
extension DealItemPatterns on DealItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DealItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DealItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DealItem value)  $default,){
final _that = this;
switch (_that) {
case _DealItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DealItem value)?  $default,){
final _that = this;
switch (_that) {
case _DealItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'stock_item_id')  int stockItemId, @JsonKey(name: 'stock_item')  DealStockItemRef? stockItem, @JsonKey(name: 'quantity_expected')  String? quantityExpected, @JsonKey(name: 'expected_unit_cost')  String? expectedUnitCost, @JsonKey(name: 'expected_unit_price')  String? expectedUnitPrice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DealItem() when $default != null:
return $default(_that.id,_that.stockItemId,_that.stockItem,_that.quantityExpected,_that.expectedUnitCost,_that.expectedUnitPrice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'stock_item_id')  int stockItemId, @JsonKey(name: 'stock_item')  DealStockItemRef? stockItem, @JsonKey(name: 'quantity_expected')  String? quantityExpected, @JsonKey(name: 'expected_unit_cost')  String? expectedUnitCost, @JsonKey(name: 'expected_unit_price')  String? expectedUnitPrice)  $default,) {final _that = this;
switch (_that) {
case _DealItem():
return $default(_that.id,_that.stockItemId,_that.stockItem,_that.quantityExpected,_that.expectedUnitCost,_that.expectedUnitPrice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'stock_item_id')  int stockItemId, @JsonKey(name: 'stock_item')  DealStockItemRef? stockItem, @JsonKey(name: 'quantity_expected')  String? quantityExpected, @JsonKey(name: 'expected_unit_cost')  String? expectedUnitCost, @JsonKey(name: 'expected_unit_price')  String? expectedUnitPrice)?  $default,) {final _that = this;
switch (_that) {
case _DealItem() when $default != null:
return $default(_that.id,_that.stockItemId,_that.stockItem,_that.quantityExpected,_that.expectedUnitCost,_that.expectedUnitPrice);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DealItem implements DealItem {
  const _DealItem({required this.id, @JsonKey(name: 'stock_item_id') required this.stockItemId, @JsonKey(name: 'stock_item') this.stockItem, @JsonKey(name: 'quantity_expected') this.quantityExpected, @JsonKey(name: 'expected_unit_cost') this.expectedUnitCost, @JsonKey(name: 'expected_unit_price') this.expectedUnitPrice});
  factory _DealItem.fromJson(Map<String, dynamic> json) => _$DealItemFromJson(json);

@override final  int id;
@override@JsonKey(name: 'stock_item_id') final  int stockItemId;
@override@JsonKey(name: 'stock_item') final  DealStockItemRef? stockItem;
@override@JsonKey(name: 'quantity_expected') final  String? quantityExpected;
@override@JsonKey(name: 'expected_unit_cost') final  String? expectedUnitCost;
@override@JsonKey(name: 'expected_unit_price') final  String? expectedUnitPrice;

/// Create a copy of DealItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DealItemCopyWith<_DealItem> get copyWith => __$DealItemCopyWithImpl<_DealItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DealItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DealItem&&(identical(other.id, id) || other.id == id)&&(identical(other.stockItemId, stockItemId) || other.stockItemId == stockItemId)&&(identical(other.stockItem, stockItem) || other.stockItem == stockItem)&&(identical(other.quantityExpected, quantityExpected) || other.quantityExpected == quantityExpected)&&(identical(other.expectedUnitCost, expectedUnitCost) || other.expectedUnitCost == expectedUnitCost)&&(identical(other.expectedUnitPrice, expectedUnitPrice) || other.expectedUnitPrice == expectedUnitPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,stockItemId,stockItem,quantityExpected,expectedUnitCost,expectedUnitPrice);

@override
String toString() {
  return 'DealItem(id: $id, stockItemId: $stockItemId, stockItem: $stockItem, quantityExpected: $quantityExpected, expectedUnitCost: $expectedUnitCost, expectedUnitPrice: $expectedUnitPrice)';
}


}

/// @nodoc
abstract mixin class _$DealItemCopyWith<$Res> implements $DealItemCopyWith<$Res> {
  factory _$DealItemCopyWith(_DealItem value, $Res Function(_DealItem) _then) = __$DealItemCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'stock_item_id') int stockItemId,@JsonKey(name: 'stock_item') DealStockItemRef? stockItem,@JsonKey(name: 'quantity_expected') String? quantityExpected,@JsonKey(name: 'expected_unit_cost') String? expectedUnitCost,@JsonKey(name: 'expected_unit_price') String? expectedUnitPrice
});


@override $DealStockItemRefCopyWith<$Res>? get stockItem;

}
/// @nodoc
class __$DealItemCopyWithImpl<$Res>
    implements _$DealItemCopyWith<$Res> {
  __$DealItemCopyWithImpl(this._self, this._then);

  final _DealItem _self;
  final $Res Function(_DealItem) _then;

/// Create a copy of DealItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? stockItemId = null,Object? stockItem = freezed,Object? quantityExpected = freezed,Object? expectedUnitCost = freezed,Object? expectedUnitPrice = freezed,}) {
  return _then(_DealItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,stockItemId: null == stockItemId ? _self.stockItemId : stockItemId // ignore: cast_nullable_to_non_nullable
as int,stockItem: freezed == stockItem ? _self.stockItem : stockItem // ignore: cast_nullable_to_non_nullable
as DealStockItemRef?,quantityExpected: freezed == quantityExpected ? _self.quantityExpected : quantityExpected // ignore: cast_nullable_to_non_nullable
as String?,expectedUnitCost: freezed == expectedUnitCost ? _self.expectedUnitCost : expectedUnitCost // ignore: cast_nullable_to_non_nullable
as String?,expectedUnitPrice: freezed == expectedUnitPrice ? _self.expectedUnitPrice : expectedUnitPrice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of DealItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DealStockItemRefCopyWith<$Res>? get stockItem {
    if (_self.stockItem == null) {
    return null;
  }

  return $DealStockItemRefCopyWith<$Res>(_self.stockItem!, (value) {
    return _then(_self.copyWith(stockItem: value));
  });
}
}


/// @nodoc
mixin _$DealStockItemRef {

 int get id; String? get code;@JsonKey(name: 'display_name') String? get displayName;
/// Create a copy of DealStockItemRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DealStockItemRefCopyWith<DealStockItemRef> get copyWith => _$DealStockItemRefCopyWithImpl<DealStockItemRef>(this as DealStockItemRef, _$identity);

  /// Serializes this DealStockItemRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DealStockItemRef&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,displayName);

@override
String toString() {
  return 'DealStockItemRef(id: $id, code: $code, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class $DealStockItemRefCopyWith<$Res>  {
  factory $DealStockItemRefCopyWith(DealStockItemRef value, $Res Function(DealStockItemRef) _then) = _$DealStockItemRefCopyWithImpl;
@useResult
$Res call({
 int id, String? code,@JsonKey(name: 'display_name') String? displayName
});




}
/// @nodoc
class _$DealStockItemRefCopyWithImpl<$Res>
    implements $DealStockItemRefCopyWith<$Res> {
  _$DealStockItemRefCopyWithImpl(this._self, this._then);

  final DealStockItemRef _self;
  final $Res Function(DealStockItemRef) _then;

/// Create a copy of DealStockItemRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = freezed,Object? displayName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DealStockItemRef].
extension DealStockItemRefPatterns on DealStockItemRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DealStockItemRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DealStockItemRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DealStockItemRef value)  $default,){
final _that = this;
switch (_that) {
case _DealStockItemRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DealStockItemRef value)?  $default,){
final _that = this;
switch (_that) {
case _DealStockItemRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? code, @JsonKey(name: 'display_name')  String? displayName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DealStockItemRef() when $default != null:
return $default(_that.id,_that.code,_that.displayName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? code, @JsonKey(name: 'display_name')  String? displayName)  $default,) {final _that = this;
switch (_that) {
case _DealStockItemRef():
return $default(_that.id,_that.code,_that.displayName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? code, @JsonKey(name: 'display_name')  String? displayName)?  $default,) {final _that = this;
switch (_that) {
case _DealStockItemRef() when $default != null:
return $default(_that.id,_that.code,_that.displayName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DealStockItemRef implements DealStockItemRef {
  const _DealStockItemRef({required this.id, this.code, @JsonKey(name: 'display_name') this.displayName});
  factory _DealStockItemRef.fromJson(Map<String, dynamic> json) => _$DealStockItemRefFromJson(json);

@override final  int id;
@override final  String? code;
@override@JsonKey(name: 'display_name') final  String? displayName;

/// Create a copy of DealStockItemRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DealStockItemRefCopyWith<_DealStockItemRef> get copyWith => __$DealStockItemRefCopyWithImpl<_DealStockItemRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DealStockItemRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DealStockItemRef&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,displayName);

@override
String toString() {
  return 'DealStockItemRef(id: $id, code: $code, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class _$DealStockItemRefCopyWith<$Res> implements $DealStockItemRefCopyWith<$Res> {
  factory _$DealStockItemRefCopyWith(_DealStockItemRef value, $Res Function(_DealStockItemRef) _then) = __$DealStockItemRefCopyWithImpl;
@override @useResult
$Res call({
 int id, String? code,@JsonKey(name: 'display_name') String? displayName
});




}
/// @nodoc
class __$DealStockItemRefCopyWithImpl<$Res>
    implements _$DealStockItemRefCopyWith<$Res> {
  __$DealStockItemRefCopyWithImpl(this._self, this._then);

  final _DealStockItemRef _self;
  final $Res Function(_DealStockItemRef) _then;

/// Create a copy of DealStockItemRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = freezed,Object? displayName = freezed,}) {
  return _then(_DealStockItemRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$DealBalances {

 String get capital; String get profit;@JsonKey(name: 'per_investor') List<DealInvestorStanding> get perInvestor;
/// Create a copy of DealBalances
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DealBalancesCopyWith<DealBalances> get copyWith => _$DealBalancesCopyWithImpl<DealBalances>(this as DealBalances, _$identity);

  /// Serializes this DealBalances to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DealBalances&&(identical(other.capital, capital) || other.capital == capital)&&(identical(other.profit, profit) || other.profit == profit)&&const DeepCollectionEquality().equals(other.perInvestor, perInvestor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,capital,profit,const DeepCollectionEquality().hash(perInvestor));

@override
String toString() {
  return 'DealBalances(capital: $capital, profit: $profit, perInvestor: $perInvestor)';
}


}

/// @nodoc
abstract mixin class $DealBalancesCopyWith<$Res>  {
  factory $DealBalancesCopyWith(DealBalances value, $Res Function(DealBalances) _then) = _$DealBalancesCopyWithImpl;
@useResult
$Res call({
 String capital, String profit,@JsonKey(name: 'per_investor') List<DealInvestorStanding> perInvestor
});




}
/// @nodoc
class _$DealBalancesCopyWithImpl<$Res>
    implements $DealBalancesCopyWith<$Res> {
  _$DealBalancesCopyWithImpl(this._self, this._then);

  final DealBalances _self;
  final $Res Function(DealBalances) _then;

/// Create a copy of DealBalances
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? capital = null,Object? profit = null,Object? perInvestor = null,}) {
  return _then(_self.copyWith(
capital: null == capital ? _self.capital : capital // ignore: cast_nullable_to_non_nullable
as String,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as String,perInvestor: null == perInvestor ? _self.perInvestor : perInvestor // ignore: cast_nullable_to_non_nullable
as List<DealInvestorStanding>,
  ));
}

}


/// Adds pattern-matching-related methods to [DealBalances].
extension DealBalancesPatterns on DealBalances {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DealBalances value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DealBalances() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DealBalances value)  $default,){
final _that = this;
switch (_that) {
case _DealBalances():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DealBalances value)?  $default,){
final _that = this;
switch (_that) {
case _DealBalances() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String capital,  String profit, @JsonKey(name: 'per_investor')  List<DealInvestorStanding> perInvestor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DealBalances() when $default != null:
return $default(_that.capital,_that.profit,_that.perInvestor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String capital,  String profit, @JsonKey(name: 'per_investor')  List<DealInvestorStanding> perInvestor)  $default,) {final _that = this;
switch (_that) {
case _DealBalances():
return $default(_that.capital,_that.profit,_that.perInvestor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String capital,  String profit, @JsonKey(name: 'per_investor')  List<DealInvestorStanding> perInvestor)?  $default,) {final _that = this;
switch (_that) {
case _DealBalances() when $default != null:
return $default(_that.capital,_that.profit,_that.perInvestor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DealBalances implements DealBalances {
  const _DealBalances({required this.capital, required this.profit, @JsonKey(name: 'per_investor') final  List<DealInvestorStanding> perInvestor = const <DealInvestorStanding>[]}): _perInvestor = perInvestor;
  factory _DealBalances.fromJson(Map<String, dynamic> json) => _$DealBalancesFromJson(json);

@override final  String capital;
@override final  String profit;
 final  List<DealInvestorStanding> _perInvestor;
@override@JsonKey(name: 'per_investor') List<DealInvestorStanding> get perInvestor {
  if (_perInvestor is EqualUnmodifiableListView) return _perInvestor;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_perInvestor);
}


/// Create a copy of DealBalances
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DealBalancesCopyWith<_DealBalances> get copyWith => __$DealBalancesCopyWithImpl<_DealBalances>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DealBalancesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DealBalances&&(identical(other.capital, capital) || other.capital == capital)&&(identical(other.profit, profit) || other.profit == profit)&&const DeepCollectionEquality().equals(other._perInvestor, _perInvestor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,capital,profit,const DeepCollectionEquality().hash(_perInvestor));

@override
String toString() {
  return 'DealBalances(capital: $capital, profit: $profit, perInvestor: $perInvestor)';
}


}

/// @nodoc
abstract mixin class _$DealBalancesCopyWith<$Res> implements $DealBalancesCopyWith<$Res> {
  factory _$DealBalancesCopyWith(_DealBalances value, $Res Function(_DealBalances) _then) = __$DealBalancesCopyWithImpl;
@override @useResult
$Res call({
 String capital, String profit,@JsonKey(name: 'per_investor') List<DealInvestorStanding> perInvestor
});




}
/// @nodoc
class __$DealBalancesCopyWithImpl<$Res>
    implements _$DealBalancesCopyWith<$Res> {
  __$DealBalancesCopyWithImpl(this._self, this._then);

  final _DealBalances _self;
  final $Res Function(_DealBalances) _then;

/// Create a copy of DealBalances
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? capital = null,Object? profit = null,Object? perInvestor = null,}) {
  return _then(_DealBalances(
capital: null == capital ? _self.capital : capital // ignore: cast_nullable_to_non_nullable
as String,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as String,perInvestor: null == perInvestor ? _self._perInvestor : perInvestor // ignore: cast_nullable_to_non_nullable
as List<DealInvestorStanding>,
  ));
}


}


/// @nodoc
mixin _$DealInvestorStanding {

@JsonKey(name: 'investor_id') int get investorId; String get capital; String get profit;
/// Create a copy of DealInvestorStanding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DealInvestorStandingCopyWith<DealInvestorStanding> get copyWith => _$DealInvestorStandingCopyWithImpl<DealInvestorStanding>(this as DealInvestorStanding, _$identity);

  /// Serializes this DealInvestorStanding to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DealInvestorStanding&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.capital, capital) || other.capital == capital)&&(identical(other.profit, profit) || other.profit == profit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,investorId,capital,profit);

@override
String toString() {
  return 'DealInvestorStanding(investorId: $investorId, capital: $capital, profit: $profit)';
}


}

/// @nodoc
abstract mixin class $DealInvestorStandingCopyWith<$Res>  {
  factory $DealInvestorStandingCopyWith(DealInvestorStanding value, $Res Function(DealInvestorStanding) _then) = _$DealInvestorStandingCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'investor_id') int investorId, String capital, String profit
});




}
/// @nodoc
class _$DealInvestorStandingCopyWithImpl<$Res>
    implements $DealInvestorStandingCopyWith<$Res> {
  _$DealInvestorStandingCopyWithImpl(this._self, this._then);

  final DealInvestorStanding _self;
  final $Res Function(DealInvestorStanding) _then;

/// Create a copy of DealInvestorStanding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? investorId = null,Object? capital = null,Object? profit = null,}) {
  return _then(_self.copyWith(
investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as int,capital: null == capital ? _self.capital : capital // ignore: cast_nullable_to_non_nullable
as String,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DealInvestorStanding].
extension DealInvestorStandingPatterns on DealInvestorStanding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DealInvestorStanding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DealInvestorStanding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DealInvestorStanding value)  $default,){
final _that = this;
switch (_that) {
case _DealInvestorStanding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DealInvestorStanding value)?  $default,){
final _that = this;
switch (_that) {
case _DealInvestorStanding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'investor_id')  int investorId,  String capital,  String profit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DealInvestorStanding() when $default != null:
return $default(_that.investorId,_that.capital,_that.profit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'investor_id')  int investorId,  String capital,  String profit)  $default,) {final _that = this;
switch (_that) {
case _DealInvestorStanding():
return $default(_that.investorId,_that.capital,_that.profit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'investor_id')  int investorId,  String capital,  String profit)?  $default,) {final _that = this;
switch (_that) {
case _DealInvestorStanding() when $default != null:
return $default(_that.investorId,_that.capital,_that.profit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DealInvestorStanding implements DealInvestorStanding {
  const _DealInvestorStanding({@JsonKey(name: 'investor_id') required this.investorId, required this.capital, required this.profit});
  factory _DealInvestorStanding.fromJson(Map<String, dynamic> json) => _$DealInvestorStandingFromJson(json);

@override@JsonKey(name: 'investor_id') final  int investorId;
@override final  String capital;
@override final  String profit;

/// Create a copy of DealInvestorStanding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DealInvestorStandingCopyWith<_DealInvestorStanding> get copyWith => __$DealInvestorStandingCopyWithImpl<_DealInvestorStanding>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DealInvestorStandingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DealInvestorStanding&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.capital, capital) || other.capital == capital)&&(identical(other.profit, profit) || other.profit == profit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,investorId,capital,profit);

@override
String toString() {
  return 'DealInvestorStanding(investorId: $investorId, capital: $capital, profit: $profit)';
}


}

/// @nodoc
abstract mixin class _$DealInvestorStandingCopyWith<$Res> implements $DealInvestorStandingCopyWith<$Res> {
  factory _$DealInvestorStandingCopyWith(_DealInvestorStanding value, $Res Function(_DealInvestorStanding) _then) = __$DealInvestorStandingCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'investor_id') int investorId, String capital, String profit
});




}
/// @nodoc
class __$DealInvestorStandingCopyWithImpl<$Res>
    implements _$DealInvestorStandingCopyWith<$Res> {
  __$DealInvestorStandingCopyWithImpl(this._self, this._then);

  final _DealInvestorStanding _self;
  final $Res Function(_DealInvestorStanding) _then;

/// Create a copy of DealInvestorStanding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? investorId = null,Object? capital = null,Object? profit = null,}) {
  return _then(_DealInvestorStanding(
investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as int,capital: null == capital ? _self.capital : capital // ignore: cast_nullable_to_non_nullable
as String,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DealStock {

@JsonKey(name: 'quantity_received') String get quantityReceived;@JsonKey(name: 'quantity_remaining') String get quantityRemaining;@JsonKey(name: 'quantity_sold') String get quantitySold;@JsonKey(name: 'quantity_damaged') String get quantityDamaged;@JsonKey(name: 'quantity_short') String get quantityShort;@JsonKey(name: 'cost_remaining') String get costRemaining;@JsonKey(name: 'cost_sold') String get costSold;@JsonKey(name: 'cost_damaged') String get costDamaged;@JsonKey(name: 'cost_short') String get costShort;
/// Create a copy of DealStock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DealStockCopyWith<DealStock> get copyWith => _$DealStockCopyWithImpl<DealStock>(this as DealStock, _$identity);

  /// Serializes this DealStock to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DealStock&&(identical(other.quantityReceived, quantityReceived) || other.quantityReceived == quantityReceived)&&(identical(other.quantityRemaining, quantityRemaining) || other.quantityRemaining == quantityRemaining)&&(identical(other.quantitySold, quantitySold) || other.quantitySold == quantitySold)&&(identical(other.quantityDamaged, quantityDamaged) || other.quantityDamaged == quantityDamaged)&&(identical(other.quantityShort, quantityShort) || other.quantityShort == quantityShort)&&(identical(other.costRemaining, costRemaining) || other.costRemaining == costRemaining)&&(identical(other.costSold, costSold) || other.costSold == costSold)&&(identical(other.costDamaged, costDamaged) || other.costDamaged == costDamaged)&&(identical(other.costShort, costShort) || other.costShort == costShort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quantityReceived,quantityRemaining,quantitySold,quantityDamaged,quantityShort,costRemaining,costSold,costDamaged,costShort);

@override
String toString() {
  return 'DealStock(quantityReceived: $quantityReceived, quantityRemaining: $quantityRemaining, quantitySold: $quantitySold, quantityDamaged: $quantityDamaged, quantityShort: $quantityShort, costRemaining: $costRemaining, costSold: $costSold, costDamaged: $costDamaged, costShort: $costShort)';
}


}

/// @nodoc
abstract mixin class $DealStockCopyWith<$Res>  {
  factory $DealStockCopyWith(DealStock value, $Res Function(DealStock) _then) = _$DealStockCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'quantity_received') String quantityReceived,@JsonKey(name: 'quantity_remaining') String quantityRemaining,@JsonKey(name: 'quantity_sold') String quantitySold,@JsonKey(name: 'quantity_damaged') String quantityDamaged,@JsonKey(name: 'quantity_short') String quantityShort,@JsonKey(name: 'cost_remaining') String costRemaining,@JsonKey(name: 'cost_sold') String costSold,@JsonKey(name: 'cost_damaged') String costDamaged,@JsonKey(name: 'cost_short') String costShort
});




}
/// @nodoc
class _$DealStockCopyWithImpl<$Res>
    implements $DealStockCopyWith<$Res> {
  _$DealStockCopyWithImpl(this._self, this._then);

  final DealStock _self;
  final $Res Function(DealStock) _then;

/// Create a copy of DealStock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? quantityReceived = null,Object? quantityRemaining = null,Object? quantitySold = null,Object? quantityDamaged = null,Object? quantityShort = null,Object? costRemaining = null,Object? costSold = null,Object? costDamaged = null,Object? costShort = null,}) {
  return _then(_self.copyWith(
quantityReceived: null == quantityReceived ? _self.quantityReceived : quantityReceived // ignore: cast_nullable_to_non_nullable
as String,quantityRemaining: null == quantityRemaining ? _self.quantityRemaining : quantityRemaining // ignore: cast_nullable_to_non_nullable
as String,quantitySold: null == quantitySold ? _self.quantitySold : quantitySold // ignore: cast_nullable_to_non_nullable
as String,quantityDamaged: null == quantityDamaged ? _self.quantityDamaged : quantityDamaged // ignore: cast_nullable_to_non_nullable
as String,quantityShort: null == quantityShort ? _self.quantityShort : quantityShort // ignore: cast_nullable_to_non_nullable
as String,costRemaining: null == costRemaining ? _self.costRemaining : costRemaining // ignore: cast_nullable_to_non_nullable
as String,costSold: null == costSold ? _self.costSold : costSold // ignore: cast_nullable_to_non_nullable
as String,costDamaged: null == costDamaged ? _self.costDamaged : costDamaged // ignore: cast_nullable_to_non_nullable
as String,costShort: null == costShort ? _self.costShort : costShort // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DealStock].
extension DealStockPatterns on DealStock {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DealStock value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DealStock() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DealStock value)  $default,){
final _that = this;
switch (_that) {
case _DealStock():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DealStock value)?  $default,){
final _that = this;
switch (_that) {
case _DealStock() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'quantity_received')  String quantityReceived, @JsonKey(name: 'quantity_remaining')  String quantityRemaining, @JsonKey(name: 'quantity_sold')  String quantitySold, @JsonKey(name: 'quantity_damaged')  String quantityDamaged, @JsonKey(name: 'quantity_short')  String quantityShort, @JsonKey(name: 'cost_remaining')  String costRemaining, @JsonKey(name: 'cost_sold')  String costSold, @JsonKey(name: 'cost_damaged')  String costDamaged, @JsonKey(name: 'cost_short')  String costShort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DealStock() when $default != null:
return $default(_that.quantityReceived,_that.quantityRemaining,_that.quantitySold,_that.quantityDamaged,_that.quantityShort,_that.costRemaining,_that.costSold,_that.costDamaged,_that.costShort);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'quantity_received')  String quantityReceived, @JsonKey(name: 'quantity_remaining')  String quantityRemaining, @JsonKey(name: 'quantity_sold')  String quantitySold, @JsonKey(name: 'quantity_damaged')  String quantityDamaged, @JsonKey(name: 'quantity_short')  String quantityShort, @JsonKey(name: 'cost_remaining')  String costRemaining, @JsonKey(name: 'cost_sold')  String costSold, @JsonKey(name: 'cost_damaged')  String costDamaged, @JsonKey(name: 'cost_short')  String costShort)  $default,) {final _that = this;
switch (_that) {
case _DealStock():
return $default(_that.quantityReceived,_that.quantityRemaining,_that.quantitySold,_that.quantityDamaged,_that.quantityShort,_that.costRemaining,_that.costSold,_that.costDamaged,_that.costShort);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'quantity_received')  String quantityReceived, @JsonKey(name: 'quantity_remaining')  String quantityRemaining, @JsonKey(name: 'quantity_sold')  String quantitySold, @JsonKey(name: 'quantity_damaged')  String quantityDamaged, @JsonKey(name: 'quantity_short')  String quantityShort, @JsonKey(name: 'cost_remaining')  String costRemaining, @JsonKey(name: 'cost_sold')  String costSold, @JsonKey(name: 'cost_damaged')  String costDamaged, @JsonKey(name: 'cost_short')  String costShort)?  $default,) {final _that = this;
switch (_that) {
case _DealStock() when $default != null:
return $default(_that.quantityReceived,_that.quantityRemaining,_that.quantitySold,_that.quantityDamaged,_that.quantityShort,_that.costRemaining,_that.costSold,_that.costDamaged,_that.costShort);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DealStock implements DealStock {
  const _DealStock({@JsonKey(name: 'quantity_received') required this.quantityReceived, @JsonKey(name: 'quantity_remaining') required this.quantityRemaining, @JsonKey(name: 'quantity_sold') required this.quantitySold, @JsonKey(name: 'quantity_damaged') required this.quantityDamaged, @JsonKey(name: 'quantity_short') required this.quantityShort, @JsonKey(name: 'cost_remaining') required this.costRemaining, @JsonKey(name: 'cost_sold') required this.costSold, @JsonKey(name: 'cost_damaged') required this.costDamaged, @JsonKey(name: 'cost_short') required this.costShort});
  factory _DealStock.fromJson(Map<String, dynamic> json) => _$DealStockFromJson(json);

@override@JsonKey(name: 'quantity_received') final  String quantityReceived;
@override@JsonKey(name: 'quantity_remaining') final  String quantityRemaining;
@override@JsonKey(name: 'quantity_sold') final  String quantitySold;
@override@JsonKey(name: 'quantity_damaged') final  String quantityDamaged;
@override@JsonKey(name: 'quantity_short') final  String quantityShort;
@override@JsonKey(name: 'cost_remaining') final  String costRemaining;
@override@JsonKey(name: 'cost_sold') final  String costSold;
@override@JsonKey(name: 'cost_damaged') final  String costDamaged;
@override@JsonKey(name: 'cost_short') final  String costShort;

/// Create a copy of DealStock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DealStockCopyWith<_DealStock> get copyWith => __$DealStockCopyWithImpl<_DealStock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DealStockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DealStock&&(identical(other.quantityReceived, quantityReceived) || other.quantityReceived == quantityReceived)&&(identical(other.quantityRemaining, quantityRemaining) || other.quantityRemaining == quantityRemaining)&&(identical(other.quantitySold, quantitySold) || other.quantitySold == quantitySold)&&(identical(other.quantityDamaged, quantityDamaged) || other.quantityDamaged == quantityDamaged)&&(identical(other.quantityShort, quantityShort) || other.quantityShort == quantityShort)&&(identical(other.costRemaining, costRemaining) || other.costRemaining == costRemaining)&&(identical(other.costSold, costSold) || other.costSold == costSold)&&(identical(other.costDamaged, costDamaged) || other.costDamaged == costDamaged)&&(identical(other.costShort, costShort) || other.costShort == costShort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quantityReceived,quantityRemaining,quantitySold,quantityDamaged,quantityShort,costRemaining,costSold,costDamaged,costShort);

@override
String toString() {
  return 'DealStock(quantityReceived: $quantityReceived, quantityRemaining: $quantityRemaining, quantitySold: $quantitySold, quantityDamaged: $quantityDamaged, quantityShort: $quantityShort, costRemaining: $costRemaining, costSold: $costSold, costDamaged: $costDamaged, costShort: $costShort)';
}


}

/// @nodoc
abstract mixin class _$DealStockCopyWith<$Res> implements $DealStockCopyWith<$Res> {
  factory _$DealStockCopyWith(_DealStock value, $Res Function(_DealStock) _then) = __$DealStockCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'quantity_received') String quantityReceived,@JsonKey(name: 'quantity_remaining') String quantityRemaining,@JsonKey(name: 'quantity_sold') String quantitySold,@JsonKey(name: 'quantity_damaged') String quantityDamaged,@JsonKey(name: 'quantity_short') String quantityShort,@JsonKey(name: 'cost_remaining') String costRemaining,@JsonKey(name: 'cost_sold') String costSold,@JsonKey(name: 'cost_damaged') String costDamaged,@JsonKey(name: 'cost_short') String costShort
});




}
/// @nodoc
class __$DealStockCopyWithImpl<$Res>
    implements _$DealStockCopyWith<$Res> {
  __$DealStockCopyWithImpl(this._self, this._then);

  final _DealStock _self;
  final $Res Function(_DealStock) _then;

/// Create a copy of DealStock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? quantityReceived = null,Object? quantityRemaining = null,Object? quantitySold = null,Object? quantityDamaged = null,Object? quantityShort = null,Object? costRemaining = null,Object? costSold = null,Object? costDamaged = null,Object? costShort = null,}) {
  return _then(_DealStock(
quantityReceived: null == quantityReceived ? _self.quantityReceived : quantityReceived // ignore: cast_nullable_to_non_nullable
as String,quantityRemaining: null == quantityRemaining ? _self.quantityRemaining : quantityRemaining // ignore: cast_nullable_to_non_nullable
as String,quantitySold: null == quantitySold ? _self.quantitySold : quantitySold // ignore: cast_nullable_to_non_nullable
as String,quantityDamaged: null == quantityDamaged ? _self.quantityDamaged : quantityDamaged // ignore: cast_nullable_to_non_nullable
as String,quantityShort: null == quantityShort ? _self.quantityShort : quantityShort // ignore: cast_nullable_to_non_nullable
as String,costRemaining: null == costRemaining ? _self.costRemaining : costRemaining // ignore: cast_nullable_to_non_nullable
as String,costSold: null == costSold ? _self.costSold : costSold // ignore: cast_nullable_to_non_nullable
as String,costDamaged: null == costDamaged ? _self.costDamaged : costDamaged // ignore: cast_nullable_to_non_nullable
as String,costShort: null == costShort ? _self.costShort : costShort // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
