// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'investment_settlement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InvestmentSettlement {

 int get id; String? get code;@JsonKey(name: 'investment_pool_id') int get investmentPoolId;@JsonKey(name: 'period_from_id') int? get periodFromId;@JsonKey(name: 'period_to_id') int? get periodToId;@JsonKey(name: 'settled_on') String? get settledOn;@JsonKey(name: 'approved_by') int? get approvedBy;@JsonKey(name: 'approved_by_name') String? get approvedByName;@JsonKey(name: 'total_capital') String get totalCapital;@JsonKey(name: 'investor_capital') String get investorCapital;@JsonKey(name: 'company_capital') String get companyCapital;@JsonKey(name: 'deployable_cash') String get deployableCash;@JsonKey(name: 'stock_at_cost') String get stockAtCost;/// Real money the company is holding that [deployableCash] does **not** count as spendable —
/// the open period's profit, which belongs to nobody yet.
///
/// Printed beside [deployableCash] and **never added to it**.
@JsonKey(name: 'undeployed_current_profit') String get undeployedCurrentProfit;/// Booked as earned, not yet collected. Profit is recognised at delivery, so an order sold on
/// credit counts as cash in hand everywhere else; this is the size of that assumption.
 String get receivables;/// Undrawn profit sitting in wallets — money the company holds and does not own, and never
/// working capital.
 String get liabilities;@JsonKey(name: 'distributed_profit_to_date') String get distributedProfitToDate;@JsonKey(name: 'damage_to_date') String get damageToDate;@JsonKey(name: 'shortage_to_date') String get shortageToDate;/// What the pool's cash *should* be, walked from the movements alone.
@JsonKey(name: 'reconstructed_cash') String get reconstructedCash;/// **A finding, not an error.** Nothing corrects it and nothing absorbs it: it stands on the
/// record until somebody explains it, which is the only treatment that does not eventually
/// teach people to ignore it.
 String get drift;@JsonKey(name: 'has_drift') bool get hasDrift; String? get notes;@JsonKey(name: 'created_at') String? get createdAt;
/// Create a copy of InvestmentSettlement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestmentSettlementCopyWith<InvestmentSettlement> get copyWith => _$InvestmentSettlementCopyWithImpl<InvestmentSettlement>(this as InvestmentSettlement, _$identity);

  /// Serializes this InvestmentSettlement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestmentSettlement&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.investmentPoolId, investmentPoolId) || other.investmentPoolId == investmentPoolId)&&(identical(other.periodFromId, periodFromId) || other.periodFromId == periodFromId)&&(identical(other.periodToId, periodToId) || other.periodToId == periodToId)&&(identical(other.settledOn, settledOn) || other.settledOn == settledOn)&&(identical(other.approvedBy, approvedBy) || other.approvedBy == approvedBy)&&(identical(other.approvedByName, approvedByName) || other.approvedByName == approvedByName)&&(identical(other.totalCapital, totalCapital) || other.totalCapital == totalCapital)&&(identical(other.investorCapital, investorCapital) || other.investorCapital == investorCapital)&&(identical(other.companyCapital, companyCapital) || other.companyCapital == companyCapital)&&(identical(other.deployableCash, deployableCash) || other.deployableCash == deployableCash)&&(identical(other.stockAtCost, stockAtCost) || other.stockAtCost == stockAtCost)&&(identical(other.undeployedCurrentProfit, undeployedCurrentProfit) || other.undeployedCurrentProfit == undeployedCurrentProfit)&&(identical(other.receivables, receivables) || other.receivables == receivables)&&(identical(other.liabilities, liabilities) || other.liabilities == liabilities)&&(identical(other.distributedProfitToDate, distributedProfitToDate) || other.distributedProfitToDate == distributedProfitToDate)&&(identical(other.damageToDate, damageToDate) || other.damageToDate == damageToDate)&&(identical(other.shortageToDate, shortageToDate) || other.shortageToDate == shortageToDate)&&(identical(other.reconstructedCash, reconstructedCash) || other.reconstructedCash == reconstructedCash)&&(identical(other.drift, drift) || other.drift == drift)&&(identical(other.hasDrift, hasDrift) || other.hasDrift == hasDrift)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,code,investmentPoolId,periodFromId,periodToId,settledOn,approvedBy,approvedByName,totalCapital,investorCapital,companyCapital,deployableCash,stockAtCost,undeployedCurrentProfit,receivables,liabilities,distributedProfitToDate,damageToDate,shortageToDate,reconstructedCash,drift,hasDrift,notes,createdAt]);

@override
String toString() {
  return 'InvestmentSettlement(id: $id, code: $code, investmentPoolId: $investmentPoolId, periodFromId: $periodFromId, periodToId: $periodToId, settledOn: $settledOn, approvedBy: $approvedBy, approvedByName: $approvedByName, totalCapital: $totalCapital, investorCapital: $investorCapital, companyCapital: $companyCapital, deployableCash: $deployableCash, stockAtCost: $stockAtCost, undeployedCurrentProfit: $undeployedCurrentProfit, receivables: $receivables, liabilities: $liabilities, distributedProfitToDate: $distributedProfitToDate, damageToDate: $damageToDate, shortageToDate: $shortageToDate, reconstructedCash: $reconstructedCash, drift: $drift, hasDrift: $hasDrift, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $InvestmentSettlementCopyWith<$Res>  {
  factory $InvestmentSettlementCopyWith(InvestmentSettlement value, $Res Function(InvestmentSettlement) _then) = _$InvestmentSettlementCopyWithImpl;
@useResult
$Res call({
 int id, String? code,@JsonKey(name: 'investment_pool_id') int investmentPoolId,@JsonKey(name: 'period_from_id') int? periodFromId,@JsonKey(name: 'period_to_id') int? periodToId,@JsonKey(name: 'settled_on') String? settledOn,@JsonKey(name: 'approved_by') int? approvedBy,@JsonKey(name: 'approved_by_name') String? approvedByName,@JsonKey(name: 'total_capital') String totalCapital,@JsonKey(name: 'investor_capital') String investorCapital,@JsonKey(name: 'company_capital') String companyCapital,@JsonKey(name: 'deployable_cash') String deployableCash,@JsonKey(name: 'stock_at_cost') String stockAtCost,@JsonKey(name: 'undeployed_current_profit') String undeployedCurrentProfit, String receivables, String liabilities,@JsonKey(name: 'distributed_profit_to_date') String distributedProfitToDate,@JsonKey(name: 'damage_to_date') String damageToDate,@JsonKey(name: 'shortage_to_date') String shortageToDate,@JsonKey(name: 'reconstructed_cash') String reconstructedCash, String drift,@JsonKey(name: 'has_drift') bool hasDrift, String? notes,@JsonKey(name: 'created_at') String? createdAt
});




}
/// @nodoc
class _$InvestmentSettlementCopyWithImpl<$Res>
    implements $InvestmentSettlementCopyWith<$Res> {
  _$InvestmentSettlementCopyWithImpl(this._self, this._then);

  final InvestmentSettlement _self;
  final $Res Function(InvestmentSettlement) _then;

/// Create a copy of InvestmentSettlement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = freezed,Object? investmentPoolId = null,Object? periodFromId = freezed,Object? periodToId = freezed,Object? settledOn = freezed,Object? approvedBy = freezed,Object? approvedByName = freezed,Object? totalCapital = null,Object? investorCapital = null,Object? companyCapital = null,Object? deployableCash = null,Object? stockAtCost = null,Object? undeployedCurrentProfit = null,Object? receivables = null,Object? liabilities = null,Object? distributedProfitToDate = null,Object? damageToDate = null,Object? shortageToDate = null,Object? reconstructedCash = null,Object? drift = null,Object? hasDrift = null,Object? notes = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,investmentPoolId: null == investmentPoolId ? _self.investmentPoolId : investmentPoolId // ignore: cast_nullable_to_non_nullable
as int,periodFromId: freezed == periodFromId ? _self.periodFromId : periodFromId // ignore: cast_nullable_to_non_nullable
as int?,periodToId: freezed == periodToId ? _self.periodToId : periodToId // ignore: cast_nullable_to_non_nullable
as int?,settledOn: freezed == settledOn ? _self.settledOn : settledOn // ignore: cast_nullable_to_non_nullable
as String?,approvedBy: freezed == approvedBy ? _self.approvedBy : approvedBy // ignore: cast_nullable_to_non_nullable
as int?,approvedByName: freezed == approvedByName ? _self.approvedByName : approvedByName // ignore: cast_nullable_to_non_nullable
as String?,totalCapital: null == totalCapital ? _self.totalCapital : totalCapital // ignore: cast_nullable_to_non_nullable
as String,investorCapital: null == investorCapital ? _self.investorCapital : investorCapital // ignore: cast_nullable_to_non_nullable
as String,companyCapital: null == companyCapital ? _self.companyCapital : companyCapital // ignore: cast_nullable_to_non_nullable
as String,deployableCash: null == deployableCash ? _self.deployableCash : deployableCash // ignore: cast_nullable_to_non_nullable
as String,stockAtCost: null == stockAtCost ? _self.stockAtCost : stockAtCost // ignore: cast_nullable_to_non_nullable
as String,undeployedCurrentProfit: null == undeployedCurrentProfit ? _self.undeployedCurrentProfit : undeployedCurrentProfit // ignore: cast_nullable_to_non_nullable
as String,receivables: null == receivables ? _self.receivables : receivables // ignore: cast_nullable_to_non_nullable
as String,liabilities: null == liabilities ? _self.liabilities : liabilities // ignore: cast_nullable_to_non_nullable
as String,distributedProfitToDate: null == distributedProfitToDate ? _self.distributedProfitToDate : distributedProfitToDate // ignore: cast_nullable_to_non_nullable
as String,damageToDate: null == damageToDate ? _self.damageToDate : damageToDate // ignore: cast_nullable_to_non_nullable
as String,shortageToDate: null == shortageToDate ? _self.shortageToDate : shortageToDate // ignore: cast_nullable_to_non_nullable
as String,reconstructedCash: null == reconstructedCash ? _self.reconstructedCash : reconstructedCash // ignore: cast_nullable_to_non_nullable
as String,drift: null == drift ? _self.drift : drift // ignore: cast_nullable_to_non_nullable
as String,hasDrift: null == hasDrift ? _self.hasDrift : hasDrift // ignore: cast_nullable_to_non_nullable
as bool,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InvestmentSettlement].
extension InvestmentSettlementPatterns on InvestmentSettlement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvestmentSettlement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvestmentSettlement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvestmentSettlement value)  $default,){
final _that = this;
switch (_that) {
case _InvestmentSettlement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvestmentSettlement value)?  $default,){
final _that = this;
switch (_that) {
case _InvestmentSettlement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? code, @JsonKey(name: 'investment_pool_id')  int investmentPoolId, @JsonKey(name: 'period_from_id')  int? periodFromId, @JsonKey(name: 'period_to_id')  int? periodToId, @JsonKey(name: 'settled_on')  String? settledOn, @JsonKey(name: 'approved_by')  int? approvedBy, @JsonKey(name: 'approved_by_name')  String? approvedByName, @JsonKey(name: 'total_capital')  String totalCapital, @JsonKey(name: 'investor_capital')  String investorCapital, @JsonKey(name: 'company_capital')  String companyCapital, @JsonKey(name: 'deployable_cash')  String deployableCash, @JsonKey(name: 'stock_at_cost')  String stockAtCost, @JsonKey(name: 'undeployed_current_profit')  String undeployedCurrentProfit,  String receivables,  String liabilities, @JsonKey(name: 'distributed_profit_to_date')  String distributedProfitToDate, @JsonKey(name: 'damage_to_date')  String damageToDate, @JsonKey(name: 'shortage_to_date')  String shortageToDate, @JsonKey(name: 'reconstructed_cash')  String reconstructedCash,  String drift, @JsonKey(name: 'has_drift')  bool hasDrift,  String? notes, @JsonKey(name: 'created_at')  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvestmentSettlement() when $default != null:
return $default(_that.id,_that.code,_that.investmentPoolId,_that.periodFromId,_that.periodToId,_that.settledOn,_that.approvedBy,_that.approvedByName,_that.totalCapital,_that.investorCapital,_that.companyCapital,_that.deployableCash,_that.stockAtCost,_that.undeployedCurrentProfit,_that.receivables,_that.liabilities,_that.distributedProfitToDate,_that.damageToDate,_that.shortageToDate,_that.reconstructedCash,_that.drift,_that.hasDrift,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? code, @JsonKey(name: 'investment_pool_id')  int investmentPoolId, @JsonKey(name: 'period_from_id')  int? periodFromId, @JsonKey(name: 'period_to_id')  int? periodToId, @JsonKey(name: 'settled_on')  String? settledOn, @JsonKey(name: 'approved_by')  int? approvedBy, @JsonKey(name: 'approved_by_name')  String? approvedByName, @JsonKey(name: 'total_capital')  String totalCapital, @JsonKey(name: 'investor_capital')  String investorCapital, @JsonKey(name: 'company_capital')  String companyCapital, @JsonKey(name: 'deployable_cash')  String deployableCash, @JsonKey(name: 'stock_at_cost')  String stockAtCost, @JsonKey(name: 'undeployed_current_profit')  String undeployedCurrentProfit,  String receivables,  String liabilities, @JsonKey(name: 'distributed_profit_to_date')  String distributedProfitToDate, @JsonKey(name: 'damage_to_date')  String damageToDate, @JsonKey(name: 'shortage_to_date')  String shortageToDate, @JsonKey(name: 'reconstructed_cash')  String reconstructedCash,  String drift, @JsonKey(name: 'has_drift')  bool hasDrift,  String? notes, @JsonKey(name: 'created_at')  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _InvestmentSettlement():
return $default(_that.id,_that.code,_that.investmentPoolId,_that.periodFromId,_that.periodToId,_that.settledOn,_that.approvedBy,_that.approvedByName,_that.totalCapital,_that.investorCapital,_that.companyCapital,_that.deployableCash,_that.stockAtCost,_that.undeployedCurrentProfit,_that.receivables,_that.liabilities,_that.distributedProfitToDate,_that.damageToDate,_that.shortageToDate,_that.reconstructedCash,_that.drift,_that.hasDrift,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? code, @JsonKey(name: 'investment_pool_id')  int investmentPoolId, @JsonKey(name: 'period_from_id')  int? periodFromId, @JsonKey(name: 'period_to_id')  int? periodToId, @JsonKey(name: 'settled_on')  String? settledOn, @JsonKey(name: 'approved_by')  int? approvedBy, @JsonKey(name: 'approved_by_name')  String? approvedByName, @JsonKey(name: 'total_capital')  String totalCapital, @JsonKey(name: 'investor_capital')  String investorCapital, @JsonKey(name: 'company_capital')  String companyCapital, @JsonKey(name: 'deployable_cash')  String deployableCash, @JsonKey(name: 'stock_at_cost')  String stockAtCost, @JsonKey(name: 'undeployed_current_profit')  String undeployedCurrentProfit,  String receivables,  String liabilities, @JsonKey(name: 'distributed_profit_to_date')  String distributedProfitToDate, @JsonKey(name: 'damage_to_date')  String damageToDate, @JsonKey(name: 'shortage_to_date')  String shortageToDate, @JsonKey(name: 'reconstructed_cash')  String reconstructedCash,  String drift, @JsonKey(name: 'has_drift')  bool hasDrift,  String? notes, @JsonKey(name: 'created_at')  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _InvestmentSettlement() when $default != null:
return $default(_that.id,_that.code,_that.investmentPoolId,_that.periodFromId,_that.periodToId,_that.settledOn,_that.approvedBy,_that.approvedByName,_that.totalCapital,_that.investorCapital,_that.companyCapital,_that.deployableCash,_that.stockAtCost,_that.undeployedCurrentProfit,_that.receivables,_that.liabilities,_that.distributedProfitToDate,_that.damageToDate,_that.shortageToDate,_that.reconstructedCash,_that.drift,_that.hasDrift,_that.notes,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvestmentSettlement implements InvestmentSettlement {
  const _InvestmentSettlement({required this.id, this.code, @JsonKey(name: 'investment_pool_id') required this.investmentPoolId, @JsonKey(name: 'period_from_id') this.periodFromId, @JsonKey(name: 'period_to_id') this.periodToId, @JsonKey(name: 'settled_on') this.settledOn, @JsonKey(name: 'approved_by') this.approvedBy, @JsonKey(name: 'approved_by_name') this.approvedByName, @JsonKey(name: 'total_capital') this.totalCapital = '0.00', @JsonKey(name: 'investor_capital') this.investorCapital = '0.00', @JsonKey(name: 'company_capital') this.companyCapital = '0.00', @JsonKey(name: 'deployable_cash') this.deployableCash = '0.00', @JsonKey(name: 'stock_at_cost') this.stockAtCost = '0.00', @JsonKey(name: 'undeployed_current_profit') this.undeployedCurrentProfit = '0.00', this.receivables = '0.00', this.liabilities = '0.00', @JsonKey(name: 'distributed_profit_to_date') this.distributedProfitToDate = '0.00', @JsonKey(name: 'damage_to_date') this.damageToDate = '0.00', @JsonKey(name: 'shortage_to_date') this.shortageToDate = '0.00', @JsonKey(name: 'reconstructed_cash') this.reconstructedCash = '0.00', this.drift = '0.00', @JsonKey(name: 'has_drift') this.hasDrift = false, this.notes, @JsonKey(name: 'created_at') this.createdAt});
  factory _InvestmentSettlement.fromJson(Map<String, dynamic> json) => _$InvestmentSettlementFromJson(json);

@override final  int id;
@override final  String? code;
@override@JsonKey(name: 'investment_pool_id') final  int investmentPoolId;
@override@JsonKey(name: 'period_from_id') final  int? periodFromId;
@override@JsonKey(name: 'period_to_id') final  int? periodToId;
@override@JsonKey(name: 'settled_on') final  String? settledOn;
@override@JsonKey(name: 'approved_by') final  int? approvedBy;
@override@JsonKey(name: 'approved_by_name') final  String? approvedByName;
@override@JsonKey(name: 'total_capital') final  String totalCapital;
@override@JsonKey(name: 'investor_capital') final  String investorCapital;
@override@JsonKey(name: 'company_capital') final  String companyCapital;
@override@JsonKey(name: 'deployable_cash') final  String deployableCash;
@override@JsonKey(name: 'stock_at_cost') final  String stockAtCost;
/// Real money the company is holding that [deployableCash] does **not** count as spendable —
/// the open period's profit, which belongs to nobody yet.
///
/// Printed beside [deployableCash] and **never added to it**.
@override@JsonKey(name: 'undeployed_current_profit') final  String undeployedCurrentProfit;
/// Booked as earned, not yet collected. Profit is recognised at delivery, so an order sold on
/// credit counts as cash in hand everywhere else; this is the size of that assumption.
@override@JsonKey() final  String receivables;
/// Undrawn profit sitting in wallets — money the company holds and does not own, and never
/// working capital.
@override@JsonKey() final  String liabilities;
@override@JsonKey(name: 'distributed_profit_to_date') final  String distributedProfitToDate;
@override@JsonKey(name: 'damage_to_date') final  String damageToDate;
@override@JsonKey(name: 'shortage_to_date') final  String shortageToDate;
/// What the pool's cash *should* be, walked from the movements alone.
@override@JsonKey(name: 'reconstructed_cash') final  String reconstructedCash;
/// **A finding, not an error.** Nothing corrects it and nothing absorbs it: it stands on the
/// record until somebody explains it, which is the only treatment that does not eventually
/// teach people to ignore it.
@override@JsonKey() final  String drift;
@override@JsonKey(name: 'has_drift') final  bool hasDrift;
@override final  String? notes;
@override@JsonKey(name: 'created_at') final  String? createdAt;

/// Create a copy of InvestmentSettlement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvestmentSettlementCopyWith<_InvestmentSettlement> get copyWith => __$InvestmentSettlementCopyWithImpl<_InvestmentSettlement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvestmentSettlementToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvestmentSettlement&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.investmentPoolId, investmentPoolId) || other.investmentPoolId == investmentPoolId)&&(identical(other.periodFromId, periodFromId) || other.periodFromId == periodFromId)&&(identical(other.periodToId, periodToId) || other.periodToId == periodToId)&&(identical(other.settledOn, settledOn) || other.settledOn == settledOn)&&(identical(other.approvedBy, approvedBy) || other.approvedBy == approvedBy)&&(identical(other.approvedByName, approvedByName) || other.approvedByName == approvedByName)&&(identical(other.totalCapital, totalCapital) || other.totalCapital == totalCapital)&&(identical(other.investorCapital, investorCapital) || other.investorCapital == investorCapital)&&(identical(other.companyCapital, companyCapital) || other.companyCapital == companyCapital)&&(identical(other.deployableCash, deployableCash) || other.deployableCash == deployableCash)&&(identical(other.stockAtCost, stockAtCost) || other.stockAtCost == stockAtCost)&&(identical(other.undeployedCurrentProfit, undeployedCurrentProfit) || other.undeployedCurrentProfit == undeployedCurrentProfit)&&(identical(other.receivables, receivables) || other.receivables == receivables)&&(identical(other.liabilities, liabilities) || other.liabilities == liabilities)&&(identical(other.distributedProfitToDate, distributedProfitToDate) || other.distributedProfitToDate == distributedProfitToDate)&&(identical(other.damageToDate, damageToDate) || other.damageToDate == damageToDate)&&(identical(other.shortageToDate, shortageToDate) || other.shortageToDate == shortageToDate)&&(identical(other.reconstructedCash, reconstructedCash) || other.reconstructedCash == reconstructedCash)&&(identical(other.drift, drift) || other.drift == drift)&&(identical(other.hasDrift, hasDrift) || other.hasDrift == hasDrift)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,code,investmentPoolId,periodFromId,periodToId,settledOn,approvedBy,approvedByName,totalCapital,investorCapital,companyCapital,deployableCash,stockAtCost,undeployedCurrentProfit,receivables,liabilities,distributedProfitToDate,damageToDate,shortageToDate,reconstructedCash,drift,hasDrift,notes,createdAt]);

@override
String toString() {
  return 'InvestmentSettlement(id: $id, code: $code, investmentPoolId: $investmentPoolId, periodFromId: $periodFromId, periodToId: $periodToId, settledOn: $settledOn, approvedBy: $approvedBy, approvedByName: $approvedByName, totalCapital: $totalCapital, investorCapital: $investorCapital, companyCapital: $companyCapital, deployableCash: $deployableCash, stockAtCost: $stockAtCost, undeployedCurrentProfit: $undeployedCurrentProfit, receivables: $receivables, liabilities: $liabilities, distributedProfitToDate: $distributedProfitToDate, damageToDate: $damageToDate, shortageToDate: $shortageToDate, reconstructedCash: $reconstructedCash, drift: $drift, hasDrift: $hasDrift, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$InvestmentSettlementCopyWith<$Res> implements $InvestmentSettlementCopyWith<$Res> {
  factory _$InvestmentSettlementCopyWith(_InvestmentSettlement value, $Res Function(_InvestmentSettlement) _then) = __$InvestmentSettlementCopyWithImpl;
@override @useResult
$Res call({
 int id, String? code,@JsonKey(name: 'investment_pool_id') int investmentPoolId,@JsonKey(name: 'period_from_id') int? periodFromId,@JsonKey(name: 'period_to_id') int? periodToId,@JsonKey(name: 'settled_on') String? settledOn,@JsonKey(name: 'approved_by') int? approvedBy,@JsonKey(name: 'approved_by_name') String? approvedByName,@JsonKey(name: 'total_capital') String totalCapital,@JsonKey(name: 'investor_capital') String investorCapital,@JsonKey(name: 'company_capital') String companyCapital,@JsonKey(name: 'deployable_cash') String deployableCash,@JsonKey(name: 'stock_at_cost') String stockAtCost,@JsonKey(name: 'undeployed_current_profit') String undeployedCurrentProfit, String receivables, String liabilities,@JsonKey(name: 'distributed_profit_to_date') String distributedProfitToDate,@JsonKey(name: 'damage_to_date') String damageToDate,@JsonKey(name: 'shortage_to_date') String shortageToDate,@JsonKey(name: 'reconstructed_cash') String reconstructedCash, String drift,@JsonKey(name: 'has_drift') bool hasDrift, String? notes,@JsonKey(name: 'created_at') String? createdAt
});




}
/// @nodoc
class __$InvestmentSettlementCopyWithImpl<$Res>
    implements _$InvestmentSettlementCopyWith<$Res> {
  __$InvestmentSettlementCopyWithImpl(this._self, this._then);

  final _InvestmentSettlement _self;
  final $Res Function(_InvestmentSettlement) _then;

/// Create a copy of InvestmentSettlement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = freezed,Object? investmentPoolId = null,Object? periodFromId = freezed,Object? periodToId = freezed,Object? settledOn = freezed,Object? approvedBy = freezed,Object? approvedByName = freezed,Object? totalCapital = null,Object? investorCapital = null,Object? companyCapital = null,Object? deployableCash = null,Object? stockAtCost = null,Object? undeployedCurrentProfit = null,Object? receivables = null,Object? liabilities = null,Object? distributedProfitToDate = null,Object? damageToDate = null,Object? shortageToDate = null,Object? reconstructedCash = null,Object? drift = null,Object? hasDrift = null,Object? notes = freezed,Object? createdAt = freezed,}) {
  return _then(_InvestmentSettlement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,investmentPoolId: null == investmentPoolId ? _self.investmentPoolId : investmentPoolId // ignore: cast_nullable_to_non_nullable
as int,periodFromId: freezed == periodFromId ? _self.periodFromId : periodFromId // ignore: cast_nullable_to_non_nullable
as int?,periodToId: freezed == periodToId ? _self.periodToId : periodToId // ignore: cast_nullable_to_non_nullable
as int?,settledOn: freezed == settledOn ? _self.settledOn : settledOn // ignore: cast_nullable_to_non_nullable
as String?,approvedBy: freezed == approvedBy ? _self.approvedBy : approvedBy // ignore: cast_nullable_to_non_nullable
as int?,approvedByName: freezed == approvedByName ? _self.approvedByName : approvedByName // ignore: cast_nullable_to_non_nullable
as String?,totalCapital: null == totalCapital ? _self.totalCapital : totalCapital // ignore: cast_nullable_to_non_nullable
as String,investorCapital: null == investorCapital ? _self.investorCapital : investorCapital // ignore: cast_nullable_to_non_nullable
as String,companyCapital: null == companyCapital ? _self.companyCapital : companyCapital // ignore: cast_nullable_to_non_nullable
as String,deployableCash: null == deployableCash ? _self.deployableCash : deployableCash // ignore: cast_nullable_to_non_nullable
as String,stockAtCost: null == stockAtCost ? _self.stockAtCost : stockAtCost // ignore: cast_nullable_to_non_nullable
as String,undeployedCurrentProfit: null == undeployedCurrentProfit ? _self.undeployedCurrentProfit : undeployedCurrentProfit // ignore: cast_nullable_to_non_nullable
as String,receivables: null == receivables ? _self.receivables : receivables // ignore: cast_nullable_to_non_nullable
as String,liabilities: null == liabilities ? _self.liabilities : liabilities // ignore: cast_nullable_to_non_nullable
as String,distributedProfitToDate: null == distributedProfitToDate ? _self.distributedProfitToDate : distributedProfitToDate // ignore: cast_nullable_to_non_nullable
as String,damageToDate: null == damageToDate ? _self.damageToDate : damageToDate // ignore: cast_nullable_to_non_nullable
as String,shortageToDate: null == shortageToDate ? _self.shortageToDate : shortageToDate // ignore: cast_nullable_to_non_nullable
as String,reconstructedCash: null == reconstructedCash ? _self.reconstructedCash : reconstructedCash // ignore: cast_nullable_to_non_nullable
as String,drift: null == drift ? _self.drift : drift // ignore: cast_nullable_to_non_nullable
as String,hasDrift: null == hasDrift ? _self.hasDrift : hasDrift // ignore: cast_nullable_to_non_nullable
as bool,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SettlementSnapshot {

@JsonKey(name: 'total_capital') String get totalCapital;@JsonKey(name: 'investor_capital') String get investorCapital;@JsonKey(name: 'company_capital') String get companyCapital;@JsonKey(name: 'deployable_cash') String get deployableCash;@JsonKey(name: 'stock_at_cost') String get stockAtCost;@JsonKey(name: 'undeployed_current_profit') String get undeployedCurrentProfit; String get receivables; String get liabilities;@JsonKey(name: 'distributed_profit_to_date') String get distributedProfitToDate;/// A loss that ran past what an investor had in the pool, written off to the company. It moves
/// no cash across a counter, but the pool really does go on holding goods it could not
/// otherwise have paid for — so it is an inflow in the walk, and named rather than drifting.
@JsonKey(name: 'company_absorbed_loss') String get companyAbsorbedLoss;@JsonKey(name: 'damage_to_date') String get damageToDate;@JsonKey(name: 'shortage_to_date') String get shortageToDate;@JsonKey(name: 'book_value') String get bookValue;@JsonKey(name: 'reconstructed_cash') String get reconstructedCash;@JsonKey(name: 'reconstructed_value') String get reconstructedValue; String get drift;@JsonKey(name: 'period_from_id') int? get periodFromId;@JsonKey(name: 'period_to_id') int? get periodToId;/// When this pool was last signed off, and when the next review falls due.
///
/// **Derived from the last settlement plus «مدة التسوية», never stored** — shorten the cycle
/// and the next date moves; a settlement already signed keeps the date it was signed on.
///
/// A pool nobody has ever settled is **not** overdue: it has no last settlement to count
/// from, and inventing one would put a red mark on every new pool from the day it opened,
/// which is how people learn to ignore a red mark.
@JsonKey(name: 'last_settled_on') String? get lastSettledOn;@JsonKey(name: 'next_settlement_due_on') String? get nextSettlementDueOn;@JsonKey(name: 'settlement_is_overdue') bool get settlementIsOverdue;@JsonKey(name: 'settlement_period_months') int get settlementPeriodMonths;
/// Create a copy of SettlementSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettlementSnapshotCopyWith<SettlementSnapshot> get copyWith => _$SettlementSnapshotCopyWithImpl<SettlementSnapshot>(this as SettlementSnapshot, _$identity);

  /// Serializes this SettlementSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettlementSnapshot&&(identical(other.totalCapital, totalCapital) || other.totalCapital == totalCapital)&&(identical(other.investorCapital, investorCapital) || other.investorCapital == investorCapital)&&(identical(other.companyCapital, companyCapital) || other.companyCapital == companyCapital)&&(identical(other.deployableCash, deployableCash) || other.deployableCash == deployableCash)&&(identical(other.stockAtCost, stockAtCost) || other.stockAtCost == stockAtCost)&&(identical(other.undeployedCurrentProfit, undeployedCurrentProfit) || other.undeployedCurrentProfit == undeployedCurrentProfit)&&(identical(other.receivables, receivables) || other.receivables == receivables)&&(identical(other.liabilities, liabilities) || other.liabilities == liabilities)&&(identical(other.distributedProfitToDate, distributedProfitToDate) || other.distributedProfitToDate == distributedProfitToDate)&&(identical(other.companyAbsorbedLoss, companyAbsorbedLoss) || other.companyAbsorbedLoss == companyAbsorbedLoss)&&(identical(other.damageToDate, damageToDate) || other.damageToDate == damageToDate)&&(identical(other.shortageToDate, shortageToDate) || other.shortageToDate == shortageToDate)&&(identical(other.bookValue, bookValue) || other.bookValue == bookValue)&&(identical(other.reconstructedCash, reconstructedCash) || other.reconstructedCash == reconstructedCash)&&(identical(other.reconstructedValue, reconstructedValue) || other.reconstructedValue == reconstructedValue)&&(identical(other.drift, drift) || other.drift == drift)&&(identical(other.periodFromId, periodFromId) || other.periodFromId == periodFromId)&&(identical(other.periodToId, periodToId) || other.periodToId == periodToId)&&(identical(other.lastSettledOn, lastSettledOn) || other.lastSettledOn == lastSettledOn)&&(identical(other.nextSettlementDueOn, nextSettlementDueOn) || other.nextSettlementDueOn == nextSettlementDueOn)&&(identical(other.settlementIsOverdue, settlementIsOverdue) || other.settlementIsOverdue == settlementIsOverdue)&&(identical(other.settlementPeriodMonths, settlementPeriodMonths) || other.settlementPeriodMonths == settlementPeriodMonths));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,totalCapital,investorCapital,companyCapital,deployableCash,stockAtCost,undeployedCurrentProfit,receivables,liabilities,distributedProfitToDate,companyAbsorbedLoss,damageToDate,shortageToDate,bookValue,reconstructedCash,reconstructedValue,drift,periodFromId,periodToId,lastSettledOn,nextSettlementDueOn,settlementIsOverdue,settlementPeriodMonths]);

@override
String toString() {
  return 'SettlementSnapshot(totalCapital: $totalCapital, investorCapital: $investorCapital, companyCapital: $companyCapital, deployableCash: $deployableCash, stockAtCost: $stockAtCost, undeployedCurrentProfit: $undeployedCurrentProfit, receivables: $receivables, liabilities: $liabilities, distributedProfitToDate: $distributedProfitToDate, companyAbsorbedLoss: $companyAbsorbedLoss, damageToDate: $damageToDate, shortageToDate: $shortageToDate, bookValue: $bookValue, reconstructedCash: $reconstructedCash, reconstructedValue: $reconstructedValue, drift: $drift, periodFromId: $periodFromId, periodToId: $periodToId, lastSettledOn: $lastSettledOn, nextSettlementDueOn: $nextSettlementDueOn, settlementIsOverdue: $settlementIsOverdue, settlementPeriodMonths: $settlementPeriodMonths)';
}


}

/// @nodoc
abstract mixin class $SettlementSnapshotCopyWith<$Res>  {
  factory $SettlementSnapshotCopyWith(SettlementSnapshot value, $Res Function(SettlementSnapshot) _then) = _$SettlementSnapshotCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'total_capital') String totalCapital,@JsonKey(name: 'investor_capital') String investorCapital,@JsonKey(name: 'company_capital') String companyCapital,@JsonKey(name: 'deployable_cash') String deployableCash,@JsonKey(name: 'stock_at_cost') String stockAtCost,@JsonKey(name: 'undeployed_current_profit') String undeployedCurrentProfit, String receivables, String liabilities,@JsonKey(name: 'distributed_profit_to_date') String distributedProfitToDate,@JsonKey(name: 'company_absorbed_loss') String companyAbsorbedLoss,@JsonKey(name: 'damage_to_date') String damageToDate,@JsonKey(name: 'shortage_to_date') String shortageToDate,@JsonKey(name: 'book_value') String bookValue,@JsonKey(name: 'reconstructed_cash') String reconstructedCash,@JsonKey(name: 'reconstructed_value') String reconstructedValue, String drift,@JsonKey(name: 'period_from_id') int? periodFromId,@JsonKey(name: 'period_to_id') int? periodToId,@JsonKey(name: 'last_settled_on') String? lastSettledOn,@JsonKey(name: 'next_settlement_due_on') String? nextSettlementDueOn,@JsonKey(name: 'settlement_is_overdue') bool settlementIsOverdue,@JsonKey(name: 'settlement_period_months') int settlementPeriodMonths
});




}
/// @nodoc
class _$SettlementSnapshotCopyWithImpl<$Res>
    implements $SettlementSnapshotCopyWith<$Res> {
  _$SettlementSnapshotCopyWithImpl(this._self, this._then);

  final SettlementSnapshot _self;
  final $Res Function(SettlementSnapshot) _then;

/// Create a copy of SettlementSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalCapital = null,Object? investorCapital = null,Object? companyCapital = null,Object? deployableCash = null,Object? stockAtCost = null,Object? undeployedCurrentProfit = null,Object? receivables = null,Object? liabilities = null,Object? distributedProfitToDate = null,Object? companyAbsorbedLoss = null,Object? damageToDate = null,Object? shortageToDate = null,Object? bookValue = null,Object? reconstructedCash = null,Object? reconstructedValue = null,Object? drift = null,Object? periodFromId = freezed,Object? periodToId = freezed,Object? lastSettledOn = freezed,Object? nextSettlementDueOn = freezed,Object? settlementIsOverdue = null,Object? settlementPeriodMonths = null,}) {
  return _then(_self.copyWith(
totalCapital: null == totalCapital ? _self.totalCapital : totalCapital // ignore: cast_nullable_to_non_nullable
as String,investorCapital: null == investorCapital ? _self.investorCapital : investorCapital // ignore: cast_nullable_to_non_nullable
as String,companyCapital: null == companyCapital ? _self.companyCapital : companyCapital // ignore: cast_nullable_to_non_nullable
as String,deployableCash: null == deployableCash ? _self.deployableCash : deployableCash // ignore: cast_nullable_to_non_nullable
as String,stockAtCost: null == stockAtCost ? _self.stockAtCost : stockAtCost // ignore: cast_nullable_to_non_nullable
as String,undeployedCurrentProfit: null == undeployedCurrentProfit ? _self.undeployedCurrentProfit : undeployedCurrentProfit // ignore: cast_nullable_to_non_nullable
as String,receivables: null == receivables ? _self.receivables : receivables // ignore: cast_nullable_to_non_nullable
as String,liabilities: null == liabilities ? _self.liabilities : liabilities // ignore: cast_nullable_to_non_nullable
as String,distributedProfitToDate: null == distributedProfitToDate ? _self.distributedProfitToDate : distributedProfitToDate // ignore: cast_nullable_to_non_nullable
as String,companyAbsorbedLoss: null == companyAbsorbedLoss ? _self.companyAbsorbedLoss : companyAbsorbedLoss // ignore: cast_nullable_to_non_nullable
as String,damageToDate: null == damageToDate ? _self.damageToDate : damageToDate // ignore: cast_nullable_to_non_nullable
as String,shortageToDate: null == shortageToDate ? _self.shortageToDate : shortageToDate // ignore: cast_nullable_to_non_nullable
as String,bookValue: null == bookValue ? _self.bookValue : bookValue // ignore: cast_nullable_to_non_nullable
as String,reconstructedCash: null == reconstructedCash ? _self.reconstructedCash : reconstructedCash // ignore: cast_nullable_to_non_nullable
as String,reconstructedValue: null == reconstructedValue ? _self.reconstructedValue : reconstructedValue // ignore: cast_nullable_to_non_nullable
as String,drift: null == drift ? _self.drift : drift // ignore: cast_nullable_to_non_nullable
as String,periodFromId: freezed == periodFromId ? _self.periodFromId : periodFromId // ignore: cast_nullable_to_non_nullable
as int?,periodToId: freezed == periodToId ? _self.periodToId : periodToId // ignore: cast_nullable_to_non_nullable
as int?,lastSettledOn: freezed == lastSettledOn ? _self.lastSettledOn : lastSettledOn // ignore: cast_nullable_to_non_nullable
as String?,nextSettlementDueOn: freezed == nextSettlementDueOn ? _self.nextSettlementDueOn : nextSettlementDueOn // ignore: cast_nullable_to_non_nullable
as String?,settlementIsOverdue: null == settlementIsOverdue ? _self.settlementIsOverdue : settlementIsOverdue // ignore: cast_nullable_to_non_nullable
as bool,settlementPeriodMonths: null == settlementPeriodMonths ? _self.settlementPeriodMonths : settlementPeriodMonths // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SettlementSnapshot].
extension SettlementSnapshotPatterns on SettlementSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SettlementSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SettlementSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SettlementSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _SettlementSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SettlementSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _SettlementSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_capital')  String totalCapital, @JsonKey(name: 'investor_capital')  String investorCapital, @JsonKey(name: 'company_capital')  String companyCapital, @JsonKey(name: 'deployable_cash')  String deployableCash, @JsonKey(name: 'stock_at_cost')  String stockAtCost, @JsonKey(name: 'undeployed_current_profit')  String undeployedCurrentProfit,  String receivables,  String liabilities, @JsonKey(name: 'distributed_profit_to_date')  String distributedProfitToDate, @JsonKey(name: 'company_absorbed_loss')  String companyAbsorbedLoss, @JsonKey(name: 'damage_to_date')  String damageToDate, @JsonKey(name: 'shortage_to_date')  String shortageToDate, @JsonKey(name: 'book_value')  String bookValue, @JsonKey(name: 'reconstructed_cash')  String reconstructedCash, @JsonKey(name: 'reconstructed_value')  String reconstructedValue,  String drift, @JsonKey(name: 'period_from_id')  int? periodFromId, @JsonKey(name: 'period_to_id')  int? periodToId, @JsonKey(name: 'last_settled_on')  String? lastSettledOn, @JsonKey(name: 'next_settlement_due_on')  String? nextSettlementDueOn, @JsonKey(name: 'settlement_is_overdue')  bool settlementIsOverdue, @JsonKey(name: 'settlement_period_months')  int settlementPeriodMonths)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettlementSnapshot() when $default != null:
return $default(_that.totalCapital,_that.investorCapital,_that.companyCapital,_that.deployableCash,_that.stockAtCost,_that.undeployedCurrentProfit,_that.receivables,_that.liabilities,_that.distributedProfitToDate,_that.companyAbsorbedLoss,_that.damageToDate,_that.shortageToDate,_that.bookValue,_that.reconstructedCash,_that.reconstructedValue,_that.drift,_that.periodFromId,_that.periodToId,_that.lastSettledOn,_that.nextSettlementDueOn,_that.settlementIsOverdue,_that.settlementPeriodMonths);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_capital')  String totalCapital, @JsonKey(name: 'investor_capital')  String investorCapital, @JsonKey(name: 'company_capital')  String companyCapital, @JsonKey(name: 'deployable_cash')  String deployableCash, @JsonKey(name: 'stock_at_cost')  String stockAtCost, @JsonKey(name: 'undeployed_current_profit')  String undeployedCurrentProfit,  String receivables,  String liabilities, @JsonKey(name: 'distributed_profit_to_date')  String distributedProfitToDate, @JsonKey(name: 'company_absorbed_loss')  String companyAbsorbedLoss, @JsonKey(name: 'damage_to_date')  String damageToDate, @JsonKey(name: 'shortage_to_date')  String shortageToDate, @JsonKey(name: 'book_value')  String bookValue, @JsonKey(name: 'reconstructed_cash')  String reconstructedCash, @JsonKey(name: 'reconstructed_value')  String reconstructedValue,  String drift, @JsonKey(name: 'period_from_id')  int? periodFromId, @JsonKey(name: 'period_to_id')  int? periodToId, @JsonKey(name: 'last_settled_on')  String? lastSettledOn, @JsonKey(name: 'next_settlement_due_on')  String? nextSettlementDueOn, @JsonKey(name: 'settlement_is_overdue')  bool settlementIsOverdue, @JsonKey(name: 'settlement_period_months')  int settlementPeriodMonths)  $default,) {final _that = this;
switch (_that) {
case _SettlementSnapshot():
return $default(_that.totalCapital,_that.investorCapital,_that.companyCapital,_that.deployableCash,_that.stockAtCost,_that.undeployedCurrentProfit,_that.receivables,_that.liabilities,_that.distributedProfitToDate,_that.companyAbsorbedLoss,_that.damageToDate,_that.shortageToDate,_that.bookValue,_that.reconstructedCash,_that.reconstructedValue,_that.drift,_that.periodFromId,_that.periodToId,_that.lastSettledOn,_that.nextSettlementDueOn,_that.settlementIsOverdue,_that.settlementPeriodMonths);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'total_capital')  String totalCapital, @JsonKey(name: 'investor_capital')  String investorCapital, @JsonKey(name: 'company_capital')  String companyCapital, @JsonKey(name: 'deployable_cash')  String deployableCash, @JsonKey(name: 'stock_at_cost')  String stockAtCost, @JsonKey(name: 'undeployed_current_profit')  String undeployedCurrentProfit,  String receivables,  String liabilities, @JsonKey(name: 'distributed_profit_to_date')  String distributedProfitToDate, @JsonKey(name: 'company_absorbed_loss')  String companyAbsorbedLoss, @JsonKey(name: 'damage_to_date')  String damageToDate, @JsonKey(name: 'shortage_to_date')  String shortageToDate, @JsonKey(name: 'book_value')  String bookValue, @JsonKey(name: 'reconstructed_cash')  String reconstructedCash, @JsonKey(name: 'reconstructed_value')  String reconstructedValue,  String drift, @JsonKey(name: 'period_from_id')  int? periodFromId, @JsonKey(name: 'period_to_id')  int? periodToId, @JsonKey(name: 'last_settled_on')  String? lastSettledOn, @JsonKey(name: 'next_settlement_due_on')  String? nextSettlementDueOn, @JsonKey(name: 'settlement_is_overdue')  bool settlementIsOverdue, @JsonKey(name: 'settlement_period_months')  int settlementPeriodMonths)?  $default,) {final _that = this;
switch (_that) {
case _SettlementSnapshot() when $default != null:
return $default(_that.totalCapital,_that.investorCapital,_that.companyCapital,_that.deployableCash,_that.stockAtCost,_that.undeployedCurrentProfit,_that.receivables,_that.liabilities,_that.distributedProfitToDate,_that.companyAbsorbedLoss,_that.damageToDate,_that.shortageToDate,_that.bookValue,_that.reconstructedCash,_that.reconstructedValue,_that.drift,_that.periodFromId,_that.periodToId,_that.lastSettledOn,_that.nextSettlementDueOn,_that.settlementIsOverdue,_that.settlementPeriodMonths);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SettlementSnapshot implements SettlementSnapshot {
  const _SettlementSnapshot({@JsonKey(name: 'total_capital') this.totalCapital = '0.00', @JsonKey(name: 'investor_capital') this.investorCapital = '0.00', @JsonKey(name: 'company_capital') this.companyCapital = '0.00', @JsonKey(name: 'deployable_cash') this.deployableCash = '0.00', @JsonKey(name: 'stock_at_cost') this.stockAtCost = '0.00', @JsonKey(name: 'undeployed_current_profit') this.undeployedCurrentProfit = '0.00', this.receivables = '0.00', this.liabilities = '0.00', @JsonKey(name: 'distributed_profit_to_date') this.distributedProfitToDate = '0.00', @JsonKey(name: 'company_absorbed_loss') this.companyAbsorbedLoss = '0.00', @JsonKey(name: 'damage_to_date') this.damageToDate = '0.00', @JsonKey(name: 'shortage_to_date') this.shortageToDate = '0.00', @JsonKey(name: 'book_value') this.bookValue = '0.00', @JsonKey(name: 'reconstructed_cash') this.reconstructedCash = '0.00', @JsonKey(name: 'reconstructed_value') this.reconstructedValue = '0.00', this.drift = '0.00', @JsonKey(name: 'period_from_id') this.periodFromId, @JsonKey(name: 'period_to_id') this.periodToId, @JsonKey(name: 'last_settled_on') this.lastSettledOn, @JsonKey(name: 'next_settlement_due_on') this.nextSettlementDueOn, @JsonKey(name: 'settlement_is_overdue') this.settlementIsOverdue = false, @JsonKey(name: 'settlement_period_months') this.settlementPeriodMonths = 6});
  factory _SettlementSnapshot.fromJson(Map<String, dynamic> json) => _$SettlementSnapshotFromJson(json);

@override@JsonKey(name: 'total_capital') final  String totalCapital;
@override@JsonKey(name: 'investor_capital') final  String investorCapital;
@override@JsonKey(name: 'company_capital') final  String companyCapital;
@override@JsonKey(name: 'deployable_cash') final  String deployableCash;
@override@JsonKey(name: 'stock_at_cost') final  String stockAtCost;
@override@JsonKey(name: 'undeployed_current_profit') final  String undeployedCurrentProfit;
@override@JsonKey() final  String receivables;
@override@JsonKey() final  String liabilities;
@override@JsonKey(name: 'distributed_profit_to_date') final  String distributedProfitToDate;
/// A loss that ran past what an investor had in the pool, written off to the company. It moves
/// no cash across a counter, but the pool really does go on holding goods it could not
/// otherwise have paid for — so it is an inflow in the walk, and named rather than drifting.
@override@JsonKey(name: 'company_absorbed_loss') final  String companyAbsorbedLoss;
@override@JsonKey(name: 'damage_to_date') final  String damageToDate;
@override@JsonKey(name: 'shortage_to_date') final  String shortageToDate;
@override@JsonKey(name: 'book_value') final  String bookValue;
@override@JsonKey(name: 'reconstructed_cash') final  String reconstructedCash;
@override@JsonKey(name: 'reconstructed_value') final  String reconstructedValue;
@override@JsonKey() final  String drift;
@override@JsonKey(name: 'period_from_id') final  int? periodFromId;
@override@JsonKey(name: 'period_to_id') final  int? periodToId;
/// When this pool was last signed off, and when the next review falls due.
///
/// **Derived from the last settlement plus «مدة التسوية», never stored** — shorten the cycle
/// and the next date moves; a settlement already signed keeps the date it was signed on.
///
/// A pool nobody has ever settled is **not** overdue: it has no last settlement to count
/// from, and inventing one would put a red mark on every new pool from the day it opened,
/// which is how people learn to ignore a red mark.
@override@JsonKey(name: 'last_settled_on') final  String? lastSettledOn;
@override@JsonKey(name: 'next_settlement_due_on') final  String? nextSettlementDueOn;
@override@JsonKey(name: 'settlement_is_overdue') final  bool settlementIsOverdue;
@override@JsonKey(name: 'settlement_period_months') final  int settlementPeriodMonths;

/// Create a copy of SettlementSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettlementSnapshotCopyWith<_SettlementSnapshot> get copyWith => __$SettlementSnapshotCopyWithImpl<_SettlementSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SettlementSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettlementSnapshot&&(identical(other.totalCapital, totalCapital) || other.totalCapital == totalCapital)&&(identical(other.investorCapital, investorCapital) || other.investorCapital == investorCapital)&&(identical(other.companyCapital, companyCapital) || other.companyCapital == companyCapital)&&(identical(other.deployableCash, deployableCash) || other.deployableCash == deployableCash)&&(identical(other.stockAtCost, stockAtCost) || other.stockAtCost == stockAtCost)&&(identical(other.undeployedCurrentProfit, undeployedCurrentProfit) || other.undeployedCurrentProfit == undeployedCurrentProfit)&&(identical(other.receivables, receivables) || other.receivables == receivables)&&(identical(other.liabilities, liabilities) || other.liabilities == liabilities)&&(identical(other.distributedProfitToDate, distributedProfitToDate) || other.distributedProfitToDate == distributedProfitToDate)&&(identical(other.companyAbsorbedLoss, companyAbsorbedLoss) || other.companyAbsorbedLoss == companyAbsorbedLoss)&&(identical(other.damageToDate, damageToDate) || other.damageToDate == damageToDate)&&(identical(other.shortageToDate, shortageToDate) || other.shortageToDate == shortageToDate)&&(identical(other.bookValue, bookValue) || other.bookValue == bookValue)&&(identical(other.reconstructedCash, reconstructedCash) || other.reconstructedCash == reconstructedCash)&&(identical(other.reconstructedValue, reconstructedValue) || other.reconstructedValue == reconstructedValue)&&(identical(other.drift, drift) || other.drift == drift)&&(identical(other.periodFromId, periodFromId) || other.periodFromId == periodFromId)&&(identical(other.periodToId, periodToId) || other.periodToId == periodToId)&&(identical(other.lastSettledOn, lastSettledOn) || other.lastSettledOn == lastSettledOn)&&(identical(other.nextSettlementDueOn, nextSettlementDueOn) || other.nextSettlementDueOn == nextSettlementDueOn)&&(identical(other.settlementIsOverdue, settlementIsOverdue) || other.settlementIsOverdue == settlementIsOverdue)&&(identical(other.settlementPeriodMonths, settlementPeriodMonths) || other.settlementPeriodMonths == settlementPeriodMonths));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,totalCapital,investorCapital,companyCapital,deployableCash,stockAtCost,undeployedCurrentProfit,receivables,liabilities,distributedProfitToDate,companyAbsorbedLoss,damageToDate,shortageToDate,bookValue,reconstructedCash,reconstructedValue,drift,periodFromId,periodToId,lastSettledOn,nextSettlementDueOn,settlementIsOverdue,settlementPeriodMonths]);

@override
String toString() {
  return 'SettlementSnapshot(totalCapital: $totalCapital, investorCapital: $investorCapital, companyCapital: $companyCapital, deployableCash: $deployableCash, stockAtCost: $stockAtCost, undeployedCurrentProfit: $undeployedCurrentProfit, receivables: $receivables, liabilities: $liabilities, distributedProfitToDate: $distributedProfitToDate, companyAbsorbedLoss: $companyAbsorbedLoss, damageToDate: $damageToDate, shortageToDate: $shortageToDate, bookValue: $bookValue, reconstructedCash: $reconstructedCash, reconstructedValue: $reconstructedValue, drift: $drift, periodFromId: $periodFromId, periodToId: $periodToId, lastSettledOn: $lastSettledOn, nextSettlementDueOn: $nextSettlementDueOn, settlementIsOverdue: $settlementIsOverdue, settlementPeriodMonths: $settlementPeriodMonths)';
}


}

/// @nodoc
abstract mixin class _$SettlementSnapshotCopyWith<$Res> implements $SettlementSnapshotCopyWith<$Res> {
  factory _$SettlementSnapshotCopyWith(_SettlementSnapshot value, $Res Function(_SettlementSnapshot) _then) = __$SettlementSnapshotCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'total_capital') String totalCapital,@JsonKey(name: 'investor_capital') String investorCapital,@JsonKey(name: 'company_capital') String companyCapital,@JsonKey(name: 'deployable_cash') String deployableCash,@JsonKey(name: 'stock_at_cost') String stockAtCost,@JsonKey(name: 'undeployed_current_profit') String undeployedCurrentProfit, String receivables, String liabilities,@JsonKey(name: 'distributed_profit_to_date') String distributedProfitToDate,@JsonKey(name: 'company_absorbed_loss') String companyAbsorbedLoss,@JsonKey(name: 'damage_to_date') String damageToDate,@JsonKey(name: 'shortage_to_date') String shortageToDate,@JsonKey(name: 'book_value') String bookValue,@JsonKey(name: 'reconstructed_cash') String reconstructedCash,@JsonKey(name: 'reconstructed_value') String reconstructedValue, String drift,@JsonKey(name: 'period_from_id') int? periodFromId,@JsonKey(name: 'period_to_id') int? periodToId,@JsonKey(name: 'last_settled_on') String? lastSettledOn,@JsonKey(name: 'next_settlement_due_on') String? nextSettlementDueOn,@JsonKey(name: 'settlement_is_overdue') bool settlementIsOverdue,@JsonKey(name: 'settlement_period_months') int settlementPeriodMonths
});




}
/// @nodoc
class __$SettlementSnapshotCopyWithImpl<$Res>
    implements _$SettlementSnapshotCopyWith<$Res> {
  __$SettlementSnapshotCopyWithImpl(this._self, this._then);

  final _SettlementSnapshot _self;
  final $Res Function(_SettlementSnapshot) _then;

/// Create a copy of SettlementSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalCapital = null,Object? investorCapital = null,Object? companyCapital = null,Object? deployableCash = null,Object? stockAtCost = null,Object? undeployedCurrentProfit = null,Object? receivables = null,Object? liabilities = null,Object? distributedProfitToDate = null,Object? companyAbsorbedLoss = null,Object? damageToDate = null,Object? shortageToDate = null,Object? bookValue = null,Object? reconstructedCash = null,Object? reconstructedValue = null,Object? drift = null,Object? periodFromId = freezed,Object? periodToId = freezed,Object? lastSettledOn = freezed,Object? nextSettlementDueOn = freezed,Object? settlementIsOverdue = null,Object? settlementPeriodMonths = null,}) {
  return _then(_SettlementSnapshot(
totalCapital: null == totalCapital ? _self.totalCapital : totalCapital // ignore: cast_nullable_to_non_nullable
as String,investorCapital: null == investorCapital ? _self.investorCapital : investorCapital // ignore: cast_nullable_to_non_nullable
as String,companyCapital: null == companyCapital ? _self.companyCapital : companyCapital // ignore: cast_nullable_to_non_nullable
as String,deployableCash: null == deployableCash ? _self.deployableCash : deployableCash // ignore: cast_nullable_to_non_nullable
as String,stockAtCost: null == stockAtCost ? _self.stockAtCost : stockAtCost // ignore: cast_nullable_to_non_nullable
as String,undeployedCurrentProfit: null == undeployedCurrentProfit ? _self.undeployedCurrentProfit : undeployedCurrentProfit // ignore: cast_nullable_to_non_nullable
as String,receivables: null == receivables ? _self.receivables : receivables // ignore: cast_nullable_to_non_nullable
as String,liabilities: null == liabilities ? _self.liabilities : liabilities // ignore: cast_nullable_to_non_nullable
as String,distributedProfitToDate: null == distributedProfitToDate ? _self.distributedProfitToDate : distributedProfitToDate // ignore: cast_nullable_to_non_nullable
as String,companyAbsorbedLoss: null == companyAbsorbedLoss ? _self.companyAbsorbedLoss : companyAbsorbedLoss // ignore: cast_nullable_to_non_nullable
as String,damageToDate: null == damageToDate ? _self.damageToDate : damageToDate // ignore: cast_nullable_to_non_nullable
as String,shortageToDate: null == shortageToDate ? _self.shortageToDate : shortageToDate // ignore: cast_nullable_to_non_nullable
as String,bookValue: null == bookValue ? _self.bookValue : bookValue // ignore: cast_nullable_to_non_nullable
as String,reconstructedCash: null == reconstructedCash ? _self.reconstructedCash : reconstructedCash // ignore: cast_nullable_to_non_nullable
as String,reconstructedValue: null == reconstructedValue ? _self.reconstructedValue : reconstructedValue // ignore: cast_nullable_to_non_nullable
as String,drift: null == drift ? _self.drift : drift // ignore: cast_nullable_to_non_nullable
as String,periodFromId: freezed == periodFromId ? _self.periodFromId : periodFromId // ignore: cast_nullable_to_non_nullable
as int?,periodToId: freezed == periodToId ? _self.periodToId : periodToId // ignore: cast_nullable_to_non_nullable
as int?,lastSettledOn: freezed == lastSettledOn ? _self.lastSettledOn : lastSettledOn // ignore: cast_nullable_to_non_nullable
as String?,nextSettlementDueOn: freezed == nextSettlementDueOn ? _self.nextSettlementDueOn : nextSettlementDueOn // ignore: cast_nullable_to_non_nullable
as String?,settlementIsOverdue: null == settlementIsOverdue ? _self.settlementIsOverdue : settlementIsOverdue // ignore: cast_nullable_to_non_nullable
as bool,settlementPeriodMonths: null == settlementPeriodMonths ? _self.settlementPeriodMonths : settlementPeriodMonths // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
