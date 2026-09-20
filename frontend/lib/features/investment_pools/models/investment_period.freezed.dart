// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'investment_period.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InvestmentPeriod {

 int get id;@JsonKey(name: 'investment_pool_id') int get investmentPoolId;@JsonKey(name: 'starts_on') String? get startsOn;/// The admin may move an **open** period's end date. A closed one cannot be reached from the
/// settings screen at all, by construction rather than by a guard somebody remembers.
@JsonKey(name: 'ends_on') String? get endsOn; String get status;@JsonKey(name: 'status_label') String get statusLabel;@JsonKey(name: 'is_open') bool get isOpen;/// Still open after the day it was meant to end.
///
/// **Reported, never enforced.** Nothing closes a period but a person: a close divides profit
/// and releases money into wallets it can be withdrawn from that afternoon, and it is
/// legitimately refused while a returned-goods question is unanswered. A schedule doing that
/// at three in the morning — or failing silently every night because of one question — is
/// worse than a mark on a screen somebody looks at.
///
/// A period that runs long keeps accruing perfectly correctly. What stops being true is only
/// that its dates describe its contents.
@JsonKey(name: 'is_overdue') bool get isOverdue;@JsonKey(name: 'days_overdue') int get daysOverdue;/// What would refuse the close if somebody pressed it now. Carried on the open period alone.
@JsonKey(name: 'blocked_by_returned_goods') bool get blockedByReturnedGoods;@JsonKey(name: 'closed_at') String? get closedAt;/// Null while the period is open — there is nothing to freeze until it closes.
 PeriodSnapshot? get snapshot; String? get notes;
/// Create a copy of InvestmentPeriod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestmentPeriodCopyWith<InvestmentPeriod> get copyWith => _$InvestmentPeriodCopyWithImpl<InvestmentPeriod>(this as InvestmentPeriod, _$identity);

  /// Serializes this InvestmentPeriod to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestmentPeriod&&(identical(other.id, id) || other.id == id)&&(identical(other.investmentPoolId, investmentPoolId) || other.investmentPoolId == investmentPoolId)&&(identical(other.startsOn, startsOn) || other.startsOn == startsOn)&&(identical(other.endsOn, endsOn) || other.endsOn == endsOn)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.isOverdue, isOverdue) || other.isOverdue == isOverdue)&&(identical(other.daysOverdue, daysOverdue) || other.daysOverdue == daysOverdue)&&(identical(other.blockedByReturnedGoods, blockedByReturnedGoods) || other.blockedByReturnedGoods == blockedByReturnedGoods)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,investmentPoolId,startsOn,endsOn,status,statusLabel,isOpen,isOverdue,daysOverdue,blockedByReturnedGoods,closedAt,snapshot,notes);

@override
String toString() {
  return 'InvestmentPeriod(id: $id, investmentPoolId: $investmentPoolId, startsOn: $startsOn, endsOn: $endsOn, status: $status, statusLabel: $statusLabel, isOpen: $isOpen, isOverdue: $isOverdue, daysOverdue: $daysOverdue, blockedByReturnedGoods: $blockedByReturnedGoods, closedAt: $closedAt, snapshot: $snapshot, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $InvestmentPeriodCopyWith<$Res>  {
  factory $InvestmentPeriodCopyWith(InvestmentPeriod value, $Res Function(InvestmentPeriod) _then) = _$InvestmentPeriodCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'investment_pool_id') int investmentPoolId,@JsonKey(name: 'starts_on') String? startsOn,@JsonKey(name: 'ends_on') String? endsOn, String status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'is_open') bool isOpen,@JsonKey(name: 'is_overdue') bool isOverdue,@JsonKey(name: 'days_overdue') int daysOverdue,@JsonKey(name: 'blocked_by_returned_goods') bool blockedByReturnedGoods,@JsonKey(name: 'closed_at') String? closedAt, PeriodSnapshot? snapshot, String? notes
});


$PeriodSnapshotCopyWith<$Res>? get snapshot;

}
/// @nodoc
class _$InvestmentPeriodCopyWithImpl<$Res>
    implements $InvestmentPeriodCopyWith<$Res> {
  _$InvestmentPeriodCopyWithImpl(this._self, this._then);

  final InvestmentPeriod _self;
  final $Res Function(InvestmentPeriod) _then;

/// Create a copy of InvestmentPeriod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? investmentPoolId = null,Object? startsOn = freezed,Object? endsOn = freezed,Object? status = null,Object? statusLabel = null,Object? isOpen = null,Object? isOverdue = null,Object? daysOverdue = null,Object? blockedByReturnedGoods = null,Object? closedAt = freezed,Object? snapshot = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,investmentPoolId: null == investmentPoolId ? _self.investmentPoolId : investmentPoolId // ignore: cast_nullable_to_non_nullable
as int,startsOn: freezed == startsOn ? _self.startsOn : startsOn // ignore: cast_nullable_to_non_nullable
as String?,endsOn: freezed == endsOn ? _self.endsOn : endsOn // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,isOverdue: null == isOverdue ? _self.isOverdue : isOverdue // ignore: cast_nullable_to_non_nullable
as bool,daysOverdue: null == daysOverdue ? _self.daysOverdue : daysOverdue // ignore: cast_nullable_to_non_nullable
as int,blockedByReturnedGoods: null == blockedByReturnedGoods ? _self.blockedByReturnedGoods : blockedByReturnedGoods // ignore: cast_nullable_to_non_nullable
as bool,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as String?,snapshot: freezed == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as PeriodSnapshot?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of InvestmentPeriod
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodSnapshotCopyWith<$Res>? get snapshot {
    if (_self.snapshot == null) {
    return null;
  }

  return $PeriodSnapshotCopyWith<$Res>(_self.snapshot!, (value) {
    return _then(_self.copyWith(snapshot: value));
  });
}
}


/// Adds pattern-matching-related methods to [InvestmentPeriod].
extension InvestmentPeriodPatterns on InvestmentPeriod {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvestmentPeriod value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvestmentPeriod() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvestmentPeriod value)  $default,){
final _that = this;
switch (_that) {
case _InvestmentPeriod():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvestmentPeriod value)?  $default,){
final _that = this;
switch (_that) {
case _InvestmentPeriod() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'investment_pool_id')  int investmentPoolId, @JsonKey(name: 'starts_on')  String? startsOn, @JsonKey(name: 'ends_on')  String? endsOn,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'is_overdue')  bool isOverdue, @JsonKey(name: 'days_overdue')  int daysOverdue, @JsonKey(name: 'blocked_by_returned_goods')  bool blockedByReturnedGoods, @JsonKey(name: 'closed_at')  String? closedAt,  PeriodSnapshot? snapshot,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvestmentPeriod() when $default != null:
return $default(_that.id,_that.investmentPoolId,_that.startsOn,_that.endsOn,_that.status,_that.statusLabel,_that.isOpen,_that.isOverdue,_that.daysOverdue,_that.blockedByReturnedGoods,_that.closedAt,_that.snapshot,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'investment_pool_id')  int investmentPoolId, @JsonKey(name: 'starts_on')  String? startsOn, @JsonKey(name: 'ends_on')  String? endsOn,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'is_overdue')  bool isOverdue, @JsonKey(name: 'days_overdue')  int daysOverdue, @JsonKey(name: 'blocked_by_returned_goods')  bool blockedByReturnedGoods, @JsonKey(name: 'closed_at')  String? closedAt,  PeriodSnapshot? snapshot,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _InvestmentPeriod():
return $default(_that.id,_that.investmentPoolId,_that.startsOn,_that.endsOn,_that.status,_that.statusLabel,_that.isOpen,_that.isOverdue,_that.daysOverdue,_that.blockedByReturnedGoods,_that.closedAt,_that.snapshot,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'investment_pool_id')  int investmentPoolId, @JsonKey(name: 'starts_on')  String? startsOn, @JsonKey(name: 'ends_on')  String? endsOn,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'is_overdue')  bool isOverdue, @JsonKey(name: 'days_overdue')  int daysOverdue, @JsonKey(name: 'blocked_by_returned_goods')  bool blockedByReturnedGoods, @JsonKey(name: 'closed_at')  String? closedAt,  PeriodSnapshot? snapshot,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _InvestmentPeriod() when $default != null:
return $default(_that.id,_that.investmentPoolId,_that.startsOn,_that.endsOn,_that.status,_that.statusLabel,_that.isOpen,_that.isOverdue,_that.daysOverdue,_that.blockedByReturnedGoods,_that.closedAt,_that.snapshot,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvestmentPeriod implements InvestmentPeriod {
  const _InvestmentPeriod({required this.id, @JsonKey(name: 'investment_pool_id') required this.investmentPoolId, @JsonKey(name: 'starts_on') this.startsOn, @JsonKey(name: 'ends_on') this.endsOn, required this.status, @JsonKey(name: 'status_label') required this.statusLabel, @JsonKey(name: 'is_open') this.isOpen = true, @JsonKey(name: 'is_overdue') this.isOverdue = false, @JsonKey(name: 'days_overdue') this.daysOverdue = 0, @JsonKey(name: 'blocked_by_returned_goods') this.blockedByReturnedGoods = false, @JsonKey(name: 'closed_at') this.closedAt, this.snapshot, this.notes});
  factory _InvestmentPeriod.fromJson(Map<String, dynamic> json) => _$InvestmentPeriodFromJson(json);

@override final  int id;
@override@JsonKey(name: 'investment_pool_id') final  int investmentPoolId;
@override@JsonKey(name: 'starts_on') final  String? startsOn;
/// The admin may move an **open** period's end date. A closed one cannot be reached from the
/// settings screen at all, by construction rather than by a guard somebody remembers.
@override@JsonKey(name: 'ends_on') final  String? endsOn;
@override final  String status;
@override@JsonKey(name: 'status_label') final  String statusLabel;
@override@JsonKey(name: 'is_open') final  bool isOpen;
/// Still open after the day it was meant to end.
///
/// **Reported, never enforced.** Nothing closes a period but a person: a close divides profit
/// and releases money into wallets it can be withdrawn from that afternoon, and it is
/// legitimately refused while a returned-goods question is unanswered. A schedule doing that
/// at three in the morning — or failing silently every night because of one question — is
/// worse than a mark on a screen somebody looks at.
///
/// A period that runs long keeps accruing perfectly correctly. What stops being true is only
/// that its dates describe its contents.
@override@JsonKey(name: 'is_overdue') final  bool isOverdue;
@override@JsonKey(name: 'days_overdue') final  int daysOverdue;
/// What would refuse the close if somebody pressed it now. Carried on the open period alone.
@override@JsonKey(name: 'blocked_by_returned_goods') final  bool blockedByReturnedGoods;
@override@JsonKey(name: 'closed_at') final  String? closedAt;
/// Null while the period is open — there is nothing to freeze until it closes.
@override final  PeriodSnapshot? snapshot;
@override final  String? notes;

/// Create a copy of InvestmentPeriod
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvestmentPeriodCopyWith<_InvestmentPeriod> get copyWith => __$InvestmentPeriodCopyWithImpl<_InvestmentPeriod>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvestmentPeriodToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvestmentPeriod&&(identical(other.id, id) || other.id == id)&&(identical(other.investmentPoolId, investmentPoolId) || other.investmentPoolId == investmentPoolId)&&(identical(other.startsOn, startsOn) || other.startsOn == startsOn)&&(identical(other.endsOn, endsOn) || other.endsOn == endsOn)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.isOverdue, isOverdue) || other.isOverdue == isOverdue)&&(identical(other.daysOverdue, daysOverdue) || other.daysOverdue == daysOverdue)&&(identical(other.blockedByReturnedGoods, blockedByReturnedGoods) || other.blockedByReturnedGoods == blockedByReturnedGoods)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,investmentPoolId,startsOn,endsOn,status,statusLabel,isOpen,isOverdue,daysOverdue,blockedByReturnedGoods,closedAt,snapshot,notes);

@override
String toString() {
  return 'InvestmentPeriod(id: $id, investmentPoolId: $investmentPoolId, startsOn: $startsOn, endsOn: $endsOn, status: $status, statusLabel: $statusLabel, isOpen: $isOpen, isOverdue: $isOverdue, daysOverdue: $daysOverdue, blockedByReturnedGoods: $blockedByReturnedGoods, closedAt: $closedAt, snapshot: $snapshot, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$InvestmentPeriodCopyWith<$Res> implements $InvestmentPeriodCopyWith<$Res> {
  factory _$InvestmentPeriodCopyWith(_InvestmentPeriod value, $Res Function(_InvestmentPeriod) _then) = __$InvestmentPeriodCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'investment_pool_id') int investmentPoolId,@JsonKey(name: 'starts_on') String? startsOn,@JsonKey(name: 'ends_on') String? endsOn, String status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'is_open') bool isOpen,@JsonKey(name: 'is_overdue') bool isOverdue,@JsonKey(name: 'days_overdue') int daysOverdue,@JsonKey(name: 'blocked_by_returned_goods') bool blockedByReturnedGoods,@JsonKey(name: 'closed_at') String? closedAt, PeriodSnapshot? snapshot, String? notes
});


@override $PeriodSnapshotCopyWith<$Res>? get snapshot;

}
/// @nodoc
class __$InvestmentPeriodCopyWithImpl<$Res>
    implements _$InvestmentPeriodCopyWith<$Res> {
  __$InvestmentPeriodCopyWithImpl(this._self, this._then);

  final _InvestmentPeriod _self;
  final $Res Function(_InvestmentPeriod) _then;

/// Create a copy of InvestmentPeriod
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? investmentPoolId = null,Object? startsOn = freezed,Object? endsOn = freezed,Object? status = null,Object? statusLabel = null,Object? isOpen = null,Object? isOverdue = null,Object? daysOverdue = null,Object? blockedByReturnedGoods = null,Object? closedAt = freezed,Object? snapshot = freezed,Object? notes = freezed,}) {
  return _then(_InvestmentPeriod(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,investmentPoolId: null == investmentPoolId ? _self.investmentPoolId : investmentPoolId // ignore: cast_nullable_to_non_nullable
as int,startsOn: freezed == startsOn ? _self.startsOn : startsOn // ignore: cast_nullable_to_non_nullable
as String?,endsOn: freezed == endsOn ? _self.endsOn : endsOn // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,isOverdue: null == isOverdue ? _self.isOverdue : isOverdue // ignore: cast_nullable_to_non_nullable
as bool,daysOverdue: null == daysOverdue ? _self.daysOverdue : daysOverdue // ignore: cast_nullable_to_non_nullable
as int,blockedByReturnedGoods: null == blockedByReturnedGoods ? _self.blockedByReturnedGoods : blockedByReturnedGoods // ignore: cast_nullable_to_non_nullable
as bool,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as String?,snapshot: freezed == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as PeriodSnapshot?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of InvestmentPeriod
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodSnapshotCopyWith<$Res>? get snapshot {
    if (_self.snapshot == null) {
    return null;
  }

  return $PeriodSnapshotCopyWith<$Res>(_self.snapshot!, (value) {
    return _then(_self.copyWith(snapshot: value));
  });
}
}


/// @nodoc
mixin _$PeriodSnapshot {

@JsonKey(name: 'opening_cash') String get openingCash;@JsonKey(name: 'closing_cash') String get closingCash;@JsonKey(name: 'opening_stock_cost') String get openingStockCost;@JsonKey(name: 'closing_stock_cost') String get closingStockCost;@JsonKey(name: 'realized_margin') String get realizedMargin;@JsonKey(name: 'deductible_expenses') String get deductibleExpenses;@JsonKey(name: 'damage_cost') String get damageCost;@JsonKey(name: 'shortage_cost') String get shortageCost;@JsonKey(name: 'net_profit') String get netProfit;/// The terms actually applied, so a period read next year explains itself without anybody
/// having to know what the settings said that month.
@JsonKey(name: 'investor_share_percent_applied') String get investorSharePercentApplied;@JsonKey(name: 'investor_capital_weight_applied') String get investorCapitalWeightApplied;@JsonKey(name: 'total_pool_capital') String get totalPoolCapital;@JsonKey(name: 'total_investor_capital') String get totalInvestorCapital;
/// Create a copy of PeriodSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodSnapshotCopyWith<PeriodSnapshot> get copyWith => _$PeriodSnapshotCopyWithImpl<PeriodSnapshot>(this as PeriodSnapshot, _$identity);

  /// Serializes this PeriodSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodSnapshot&&(identical(other.openingCash, openingCash) || other.openingCash == openingCash)&&(identical(other.closingCash, closingCash) || other.closingCash == closingCash)&&(identical(other.openingStockCost, openingStockCost) || other.openingStockCost == openingStockCost)&&(identical(other.closingStockCost, closingStockCost) || other.closingStockCost == closingStockCost)&&(identical(other.realizedMargin, realizedMargin) || other.realizedMargin == realizedMargin)&&(identical(other.deductibleExpenses, deductibleExpenses) || other.deductibleExpenses == deductibleExpenses)&&(identical(other.damageCost, damageCost) || other.damageCost == damageCost)&&(identical(other.shortageCost, shortageCost) || other.shortageCost == shortageCost)&&(identical(other.netProfit, netProfit) || other.netProfit == netProfit)&&(identical(other.investorSharePercentApplied, investorSharePercentApplied) || other.investorSharePercentApplied == investorSharePercentApplied)&&(identical(other.investorCapitalWeightApplied, investorCapitalWeightApplied) || other.investorCapitalWeightApplied == investorCapitalWeightApplied)&&(identical(other.totalPoolCapital, totalPoolCapital) || other.totalPoolCapital == totalPoolCapital)&&(identical(other.totalInvestorCapital, totalInvestorCapital) || other.totalInvestorCapital == totalInvestorCapital));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,openingCash,closingCash,openingStockCost,closingStockCost,realizedMargin,deductibleExpenses,damageCost,shortageCost,netProfit,investorSharePercentApplied,investorCapitalWeightApplied,totalPoolCapital,totalInvestorCapital);

@override
String toString() {
  return 'PeriodSnapshot(openingCash: $openingCash, closingCash: $closingCash, openingStockCost: $openingStockCost, closingStockCost: $closingStockCost, realizedMargin: $realizedMargin, deductibleExpenses: $deductibleExpenses, damageCost: $damageCost, shortageCost: $shortageCost, netProfit: $netProfit, investorSharePercentApplied: $investorSharePercentApplied, investorCapitalWeightApplied: $investorCapitalWeightApplied, totalPoolCapital: $totalPoolCapital, totalInvestorCapital: $totalInvestorCapital)';
}


}

/// @nodoc
abstract mixin class $PeriodSnapshotCopyWith<$Res>  {
  factory $PeriodSnapshotCopyWith(PeriodSnapshot value, $Res Function(PeriodSnapshot) _then) = _$PeriodSnapshotCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'opening_cash') String openingCash,@JsonKey(name: 'closing_cash') String closingCash,@JsonKey(name: 'opening_stock_cost') String openingStockCost,@JsonKey(name: 'closing_stock_cost') String closingStockCost,@JsonKey(name: 'realized_margin') String realizedMargin,@JsonKey(name: 'deductible_expenses') String deductibleExpenses,@JsonKey(name: 'damage_cost') String damageCost,@JsonKey(name: 'shortage_cost') String shortageCost,@JsonKey(name: 'net_profit') String netProfit,@JsonKey(name: 'investor_share_percent_applied') String investorSharePercentApplied,@JsonKey(name: 'investor_capital_weight_applied') String investorCapitalWeightApplied,@JsonKey(name: 'total_pool_capital') String totalPoolCapital,@JsonKey(name: 'total_investor_capital') String totalInvestorCapital
});




}
/// @nodoc
class _$PeriodSnapshotCopyWithImpl<$Res>
    implements $PeriodSnapshotCopyWith<$Res> {
  _$PeriodSnapshotCopyWithImpl(this._self, this._then);

  final PeriodSnapshot _self;
  final $Res Function(PeriodSnapshot) _then;

/// Create a copy of PeriodSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? openingCash = null,Object? closingCash = null,Object? openingStockCost = null,Object? closingStockCost = null,Object? realizedMargin = null,Object? deductibleExpenses = null,Object? damageCost = null,Object? shortageCost = null,Object? netProfit = null,Object? investorSharePercentApplied = null,Object? investorCapitalWeightApplied = null,Object? totalPoolCapital = null,Object? totalInvestorCapital = null,}) {
  return _then(_self.copyWith(
openingCash: null == openingCash ? _self.openingCash : openingCash // ignore: cast_nullable_to_non_nullable
as String,closingCash: null == closingCash ? _self.closingCash : closingCash // ignore: cast_nullable_to_non_nullable
as String,openingStockCost: null == openingStockCost ? _self.openingStockCost : openingStockCost // ignore: cast_nullable_to_non_nullable
as String,closingStockCost: null == closingStockCost ? _self.closingStockCost : closingStockCost // ignore: cast_nullable_to_non_nullable
as String,realizedMargin: null == realizedMargin ? _self.realizedMargin : realizedMargin // ignore: cast_nullable_to_non_nullable
as String,deductibleExpenses: null == deductibleExpenses ? _self.deductibleExpenses : deductibleExpenses // ignore: cast_nullable_to_non_nullable
as String,damageCost: null == damageCost ? _self.damageCost : damageCost // ignore: cast_nullable_to_non_nullable
as String,shortageCost: null == shortageCost ? _self.shortageCost : shortageCost // ignore: cast_nullable_to_non_nullable
as String,netProfit: null == netProfit ? _self.netProfit : netProfit // ignore: cast_nullable_to_non_nullable
as String,investorSharePercentApplied: null == investorSharePercentApplied ? _self.investorSharePercentApplied : investorSharePercentApplied // ignore: cast_nullable_to_non_nullable
as String,investorCapitalWeightApplied: null == investorCapitalWeightApplied ? _self.investorCapitalWeightApplied : investorCapitalWeightApplied // ignore: cast_nullable_to_non_nullable
as String,totalPoolCapital: null == totalPoolCapital ? _self.totalPoolCapital : totalPoolCapital // ignore: cast_nullable_to_non_nullable
as String,totalInvestorCapital: null == totalInvestorCapital ? _self.totalInvestorCapital : totalInvestorCapital // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PeriodSnapshot].
extension PeriodSnapshotPatterns on PeriodSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PeriodSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PeriodSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PeriodSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _PeriodSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PeriodSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _PeriodSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'opening_cash')  String openingCash, @JsonKey(name: 'closing_cash')  String closingCash, @JsonKey(name: 'opening_stock_cost')  String openingStockCost, @JsonKey(name: 'closing_stock_cost')  String closingStockCost, @JsonKey(name: 'realized_margin')  String realizedMargin, @JsonKey(name: 'deductible_expenses')  String deductibleExpenses, @JsonKey(name: 'damage_cost')  String damageCost, @JsonKey(name: 'shortage_cost')  String shortageCost, @JsonKey(name: 'net_profit')  String netProfit, @JsonKey(name: 'investor_share_percent_applied')  String investorSharePercentApplied, @JsonKey(name: 'investor_capital_weight_applied')  String investorCapitalWeightApplied, @JsonKey(name: 'total_pool_capital')  String totalPoolCapital, @JsonKey(name: 'total_investor_capital')  String totalInvestorCapital)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodSnapshot() when $default != null:
return $default(_that.openingCash,_that.closingCash,_that.openingStockCost,_that.closingStockCost,_that.realizedMargin,_that.deductibleExpenses,_that.damageCost,_that.shortageCost,_that.netProfit,_that.investorSharePercentApplied,_that.investorCapitalWeightApplied,_that.totalPoolCapital,_that.totalInvestorCapital);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'opening_cash')  String openingCash, @JsonKey(name: 'closing_cash')  String closingCash, @JsonKey(name: 'opening_stock_cost')  String openingStockCost, @JsonKey(name: 'closing_stock_cost')  String closingStockCost, @JsonKey(name: 'realized_margin')  String realizedMargin, @JsonKey(name: 'deductible_expenses')  String deductibleExpenses, @JsonKey(name: 'damage_cost')  String damageCost, @JsonKey(name: 'shortage_cost')  String shortageCost, @JsonKey(name: 'net_profit')  String netProfit, @JsonKey(name: 'investor_share_percent_applied')  String investorSharePercentApplied, @JsonKey(name: 'investor_capital_weight_applied')  String investorCapitalWeightApplied, @JsonKey(name: 'total_pool_capital')  String totalPoolCapital, @JsonKey(name: 'total_investor_capital')  String totalInvestorCapital)  $default,) {final _that = this;
switch (_that) {
case _PeriodSnapshot():
return $default(_that.openingCash,_that.closingCash,_that.openingStockCost,_that.closingStockCost,_that.realizedMargin,_that.deductibleExpenses,_that.damageCost,_that.shortageCost,_that.netProfit,_that.investorSharePercentApplied,_that.investorCapitalWeightApplied,_that.totalPoolCapital,_that.totalInvestorCapital);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'opening_cash')  String openingCash, @JsonKey(name: 'closing_cash')  String closingCash, @JsonKey(name: 'opening_stock_cost')  String openingStockCost, @JsonKey(name: 'closing_stock_cost')  String closingStockCost, @JsonKey(name: 'realized_margin')  String realizedMargin, @JsonKey(name: 'deductible_expenses')  String deductibleExpenses, @JsonKey(name: 'damage_cost')  String damageCost, @JsonKey(name: 'shortage_cost')  String shortageCost, @JsonKey(name: 'net_profit')  String netProfit, @JsonKey(name: 'investor_share_percent_applied')  String investorSharePercentApplied, @JsonKey(name: 'investor_capital_weight_applied')  String investorCapitalWeightApplied, @JsonKey(name: 'total_pool_capital')  String totalPoolCapital, @JsonKey(name: 'total_investor_capital')  String totalInvestorCapital)?  $default,) {final _that = this;
switch (_that) {
case _PeriodSnapshot() when $default != null:
return $default(_that.openingCash,_that.closingCash,_that.openingStockCost,_that.closingStockCost,_that.realizedMargin,_that.deductibleExpenses,_that.damageCost,_that.shortageCost,_that.netProfit,_that.investorSharePercentApplied,_that.investorCapitalWeightApplied,_that.totalPoolCapital,_that.totalInvestorCapital);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodSnapshot implements PeriodSnapshot {
  const _PeriodSnapshot({@JsonKey(name: 'opening_cash') required this.openingCash, @JsonKey(name: 'closing_cash') required this.closingCash, @JsonKey(name: 'opening_stock_cost') required this.openingStockCost, @JsonKey(name: 'closing_stock_cost') required this.closingStockCost, @JsonKey(name: 'realized_margin') required this.realizedMargin, @JsonKey(name: 'deductible_expenses') required this.deductibleExpenses, @JsonKey(name: 'damage_cost') required this.damageCost, @JsonKey(name: 'shortage_cost') required this.shortageCost, @JsonKey(name: 'net_profit') required this.netProfit, @JsonKey(name: 'investor_share_percent_applied') required this.investorSharePercentApplied, @JsonKey(name: 'investor_capital_weight_applied') required this.investorCapitalWeightApplied, @JsonKey(name: 'total_pool_capital') required this.totalPoolCapital, @JsonKey(name: 'total_investor_capital') required this.totalInvestorCapital});
  factory _PeriodSnapshot.fromJson(Map<String, dynamic> json) => _$PeriodSnapshotFromJson(json);

@override@JsonKey(name: 'opening_cash') final  String openingCash;
@override@JsonKey(name: 'closing_cash') final  String closingCash;
@override@JsonKey(name: 'opening_stock_cost') final  String openingStockCost;
@override@JsonKey(name: 'closing_stock_cost') final  String closingStockCost;
@override@JsonKey(name: 'realized_margin') final  String realizedMargin;
@override@JsonKey(name: 'deductible_expenses') final  String deductibleExpenses;
@override@JsonKey(name: 'damage_cost') final  String damageCost;
@override@JsonKey(name: 'shortage_cost') final  String shortageCost;
@override@JsonKey(name: 'net_profit') final  String netProfit;
/// The terms actually applied, so a period read next year explains itself without anybody
/// having to know what the settings said that month.
@override@JsonKey(name: 'investor_share_percent_applied') final  String investorSharePercentApplied;
@override@JsonKey(name: 'investor_capital_weight_applied') final  String investorCapitalWeightApplied;
@override@JsonKey(name: 'total_pool_capital') final  String totalPoolCapital;
@override@JsonKey(name: 'total_investor_capital') final  String totalInvestorCapital;

/// Create a copy of PeriodSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodSnapshotCopyWith<_PeriodSnapshot> get copyWith => __$PeriodSnapshotCopyWithImpl<_PeriodSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodSnapshot&&(identical(other.openingCash, openingCash) || other.openingCash == openingCash)&&(identical(other.closingCash, closingCash) || other.closingCash == closingCash)&&(identical(other.openingStockCost, openingStockCost) || other.openingStockCost == openingStockCost)&&(identical(other.closingStockCost, closingStockCost) || other.closingStockCost == closingStockCost)&&(identical(other.realizedMargin, realizedMargin) || other.realizedMargin == realizedMargin)&&(identical(other.deductibleExpenses, deductibleExpenses) || other.deductibleExpenses == deductibleExpenses)&&(identical(other.damageCost, damageCost) || other.damageCost == damageCost)&&(identical(other.shortageCost, shortageCost) || other.shortageCost == shortageCost)&&(identical(other.netProfit, netProfit) || other.netProfit == netProfit)&&(identical(other.investorSharePercentApplied, investorSharePercentApplied) || other.investorSharePercentApplied == investorSharePercentApplied)&&(identical(other.investorCapitalWeightApplied, investorCapitalWeightApplied) || other.investorCapitalWeightApplied == investorCapitalWeightApplied)&&(identical(other.totalPoolCapital, totalPoolCapital) || other.totalPoolCapital == totalPoolCapital)&&(identical(other.totalInvestorCapital, totalInvestorCapital) || other.totalInvestorCapital == totalInvestorCapital));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,openingCash,closingCash,openingStockCost,closingStockCost,realizedMargin,deductibleExpenses,damageCost,shortageCost,netProfit,investorSharePercentApplied,investorCapitalWeightApplied,totalPoolCapital,totalInvestorCapital);

@override
String toString() {
  return 'PeriodSnapshot(openingCash: $openingCash, closingCash: $closingCash, openingStockCost: $openingStockCost, closingStockCost: $closingStockCost, realizedMargin: $realizedMargin, deductibleExpenses: $deductibleExpenses, damageCost: $damageCost, shortageCost: $shortageCost, netProfit: $netProfit, investorSharePercentApplied: $investorSharePercentApplied, investorCapitalWeightApplied: $investorCapitalWeightApplied, totalPoolCapital: $totalPoolCapital, totalInvestorCapital: $totalInvestorCapital)';
}


}

/// @nodoc
abstract mixin class _$PeriodSnapshotCopyWith<$Res> implements $PeriodSnapshotCopyWith<$Res> {
  factory _$PeriodSnapshotCopyWith(_PeriodSnapshot value, $Res Function(_PeriodSnapshot) _then) = __$PeriodSnapshotCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'opening_cash') String openingCash,@JsonKey(name: 'closing_cash') String closingCash,@JsonKey(name: 'opening_stock_cost') String openingStockCost,@JsonKey(name: 'closing_stock_cost') String closingStockCost,@JsonKey(name: 'realized_margin') String realizedMargin,@JsonKey(name: 'deductible_expenses') String deductibleExpenses,@JsonKey(name: 'damage_cost') String damageCost,@JsonKey(name: 'shortage_cost') String shortageCost,@JsonKey(name: 'net_profit') String netProfit,@JsonKey(name: 'investor_share_percent_applied') String investorSharePercentApplied,@JsonKey(name: 'investor_capital_weight_applied') String investorCapitalWeightApplied,@JsonKey(name: 'total_pool_capital') String totalPoolCapital,@JsonKey(name: 'total_investor_capital') String totalInvestorCapital
});




}
/// @nodoc
class __$PeriodSnapshotCopyWithImpl<$Res>
    implements _$PeriodSnapshotCopyWith<$Res> {
  __$PeriodSnapshotCopyWithImpl(this._self, this._then);

  final _PeriodSnapshot _self;
  final $Res Function(_PeriodSnapshot) _then;

/// Create a copy of PeriodSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? openingCash = null,Object? closingCash = null,Object? openingStockCost = null,Object? closingStockCost = null,Object? realizedMargin = null,Object? deductibleExpenses = null,Object? damageCost = null,Object? shortageCost = null,Object? netProfit = null,Object? investorSharePercentApplied = null,Object? investorCapitalWeightApplied = null,Object? totalPoolCapital = null,Object? totalInvestorCapital = null,}) {
  return _then(_PeriodSnapshot(
openingCash: null == openingCash ? _self.openingCash : openingCash // ignore: cast_nullable_to_non_nullable
as String,closingCash: null == closingCash ? _self.closingCash : closingCash // ignore: cast_nullable_to_non_nullable
as String,openingStockCost: null == openingStockCost ? _self.openingStockCost : openingStockCost // ignore: cast_nullable_to_non_nullable
as String,closingStockCost: null == closingStockCost ? _self.closingStockCost : closingStockCost // ignore: cast_nullable_to_non_nullable
as String,realizedMargin: null == realizedMargin ? _self.realizedMargin : realizedMargin // ignore: cast_nullable_to_non_nullable
as String,deductibleExpenses: null == deductibleExpenses ? _self.deductibleExpenses : deductibleExpenses // ignore: cast_nullable_to_non_nullable
as String,damageCost: null == damageCost ? _self.damageCost : damageCost // ignore: cast_nullable_to_non_nullable
as String,shortageCost: null == shortageCost ? _self.shortageCost : shortageCost // ignore: cast_nullable_to_non_nullable
as String,netProfit: null == netProfit ? _self.netProfit : netProfit // ignore: cast_nullable_to_non_nullable
as String,investorSharePercentApplied: null == investorSharePercentApplied ? _self.investorSharePercentApplied : investorSharePercentApplied // ignore: cast_nullable_to_non_nullable
as String,investorCapitalWeightApplied: null == investorCapitalWeightApplied ? _self.investorCapitalWeightApplied : investorCapitalWeightApplied // ignore: cast_nullable_to_non_nullable
as String,totalPoolCapital: null == totalPoolCapital ? _self.totalPoolCapital : totalPoolCapital // ignore: cast_nullable_to_non_nullable
as String,totalInvestorCapital: null == totalInvestorCapital ? _self.totalInvestorCapital : totalInvestorCapital // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PeriodFigures {

@JsonKey(name: 'realized_margin') String get realizedMargin;@JsonKey(name: 'deductible_expenses') String get deductibleExpenses;/// «محسوبة مسبقاً» — shipping and customs typed on a purchase order. They are **already
/// inside the cost of the layers that arrived**, so subtracting them again would charge the
/// investors for one customs invoice twice.
///
/// Shown beside the sum and never part of it. §6.2.4.
@JsonKey(name: 'recorded_only_expenses') String get recordedOnlyExpenses;@JsonKey(name: 'damage_cost') String get damageCost;@JsonKey(name: 'shortage_cost') String get shortageCost;@JsonKey(name: 'net_profit') String get netProfit;/// **The close is refused while this is true.** A cancelled printed order credits its material
/// back to the shelf as good stock, and closing over that divides profit the pool did not earn
/// on goods it does not have.
@JsonKey(name: 'has_unanswered_returns') bool get hasUnansweredReturns; InvestmentPeriod? get period;
/// Create a copy of PeriodFigures
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodFiguresCopyWith<PeriodFigures> get copyWith => _$PeriodFiguresCopyWithImpl<PeriodFigures>(this as PeriodFigures, _$identity);

  /// Serializes this PeriodFigures to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodFigures&&(identical(other.realizedMargin, realizedMargin) || other.realizedMargin == realizedMargin)&&(identical(other.deductibleExpenses, deductibleExpenses) || other.deductibleExpenses == deductibleExpenses)&&(identical(other.recordedOnlyExpenses, recordedOnlyExpenses) || other.recordedOnlyExpenses == recordedOnlyExpenses)&&(identical(other.damageCost, damageCost) || other.damageCost == damageCost)&&(identical(other.shortageCost, shortageCost) || other.shortageCost == shortageCost)&&(identical(other.netProfit, netProfit) || other.netProfit == netProfit)&&(identical(other.hasUnansweredReturns, hasUnansweredReturns) || other.hasUnansweredReturns == hasUnansweredReturns)&&(identical(other.period, period) || other.period == period));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,realizedMargin,deductibleExpenses,recordedOnlyExpenses,damageCost,shortageCost,netProfit,hasUnansweredReturns,period);

@override
String toString() {
  return 'PeriodFigures(realizedMargin: $realizedMargin, deductibleExpenses: $deductibleExpenses, recordedOnlyExpenses: $recordedOnlyExpenses, damageCost: $damageCost, shortageCost: $shortageCost, netProfit: $netProfit, hasUnansweredReturns: $hasUnansweredReturns, period: $period)';
}


}

/// @nodoc
abstract mixin class $PeriodFiguresCopyWith<$Res>  {
  factory $PeriodFiguresCopyWith(PeriodFigures value, $Res Function(PeriodFigures) _then) = _$PeriodFiguresCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'realized_margin') String realizedMargin,@JsonKey(name: 'deductible_expenses') String deductibleExpenses,@JsonKey(name: 'recorded_only_expenses') String recordedOnlyExpenses,@JsonKey(name: 'damage_cost') String damageCost,@JsonKey(name: 'shortage_cost') String shortageCost,@JsonKey(name: 'net_profit') String netProfit,@JsonKey(name: 'has_unanswered_returns') bool hasUnansweredReturns, InvestmentPeriod? period
});


$InvestmentPeriodCopyWith<$Res>? get period;

}
/// @nodoc
class _$PeriodFiguresCopyWithImpl<$Res>
    implements $PeriodFiguresCopyWith<$Res> {
  _$PeriodFiguresCopyWithImpl(this._self, this._then);

  final PeriodFigures _self;
  final $Res Function(PeriodFigures) _then;

/// Create a copy of PeriodFigures
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? realizedMargin = null,Object? deductibleExpenses = null,Object? recordedOnlyExpenses = null,Object? damageCost = null,Object? shortageCost = null,Object? netProfit = null,Object? hasUnansweredReturns = null,Object? period = freezed,}) {
  return _then(_self.copyWith(
realizedMargin: null == realizedMargin ? _self.realizedMargin : realizedMargin // ignore: cast_nullable_to_non_nullable
as String,deductibleExpenses: null == deductibleExpenses ? _self.deductibleExpenses : deductibleExpenses // ignore: cast_nullable_to_non_nullable
as String,recordedOnlyExpenses: null == recordedOnlyExpenses ? _self.recordedOnlyExpenses : recordedOnlyExpenses // ignore: cast_nullable_to_non_nullable
as String,damageCost: null == damageCost ? _self.damageCost : damageCost // ignore: cast_nullable_to_non_nullable
as String,shortageCost: null == shortageCost ? _self.shortageCost : shortageCost // ignore: cast_nullable_to_non_nullable
as String,netProfit: null == netProfit ? _self.netProfit : netProfit // ignore: cast_nullable_to_non_nullable
as String,hasUnansweredReturns: null == hasUnansweredReturns ? _self.hasUnansweredReturns : hasUnansweredReturns // ignore: cast_nullable_to_non_nullable
as bool,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as InvestmentPeriod?,
  ));
}
/// Create a copy of PeriodFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvestmentPeriodCopyWith<$Res>? get period {
    if (_self.period == null) {
    return null;
  }

  return $InvestmentPeriodCopyWith<$Res>(_self.period!, (value) {
    return _then(_self.copyWith(period: value));
  });
}
}


/// Adds pattern-matching-related methods to [PeriodFigures].
extension PeriodFiguresPatterns on PeriodFigures {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PeriodFigures value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PeriodFigures() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PeriodFigures value)  $default,){
final _that = this;
switch (_that) {
case _PeriodFigures():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PeriodFigures value)?  $default,){
final _that = this;
switch (_that) {
case _PeriodFigures() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'realized_margin')  String realizedMargin, @JsonKey(name: 'deductible_expenses')  String deductibleExpenses, @JsonKey(name: 'recorded_only_expenses')  String recordedOnlyExpenses, @JsonKey(name: 'damage_cost')  String damageCost, @JsonKey(name: 'shortage_cost')  String shortageCost, @JsonKey(name: 'net_profit')  String netProfit, @JsonKey(name: 'has_unanswered_returns')  bool hasUnansweredReturns,  InvestmentPeriod? period)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodFigures() when $default != null:
return $default(_that.realizedMargin,_that.deductibleExpenses,_that.recordedOnlyExpenses,_that.damageCost,_that.shortageCost,_that.netProfit,_that.hasUnansweredReturns,_that.period);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'realized_margin')  String realizedMargin, @JsonKey(name: 'deductible_expenses')  String deductibleExpenses, @JsonKey(name: 'recorded_only_expenses')  String recordedOnlyExpenses, @JsonKey(name: 'damage_cost')  String damageCost, @JsonKey(name: 'shortage_cost')  String shortageCost, @JsonKey(name: 'net_profit')  String netProfit, @JsonKey(name: 'has_unanswered_returns')  bool hasUnansweredReturns,  InvestmentPeriod? period)  $default,) {final _that = this;
switch (_that) {
case _PeriodFigures():
return $default(_that.realizedMargin,_that.deductibleExpenses,_that.recordedOnlyExpenses,_that.damageCost,_that.shortageCost,_that.netProfit,_that.hasUnansweredReturns,_that.period);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'realized_margin')  String realizedMargin, @JsonKey(name: 'deductible_expenses')  String deductibleExpenses, @JsonKey(name: 'recorded_only_expenses')  String recordedOnlyExpenses, @JsonKey(name: 'damage_cost')  String damageCost, @JsonKey(name: 'shortage_cost')  String shortageCost, @JsonKey(name: 'net_profit')  String netProfit, @JsonKey(name: 'has_unanswered_returns')  bool hasUnansweredReturns,  InvestmentPeriod? period)?  $default,) {final _that = this;
switch (_that) {
case _PeriodFigures() when $default != null:
return $default(_that.realizedMargin,_that.deductibleExpenses,_that.recordedOnlyExpenses,_that.damageCost,_that.shortageCost,_that.netProfit,_that.hasUnansweredReturns,_that.period);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodFigures implements PeriodFigures {
  const _PeriodFigures({@JsonKey(name: 'realized_margin') required this.realizedMargin, @JsonKey(name: 'deductible_expenses') required this.deductibleExpenses, @JsonKey(name: 'recorded_only_expenses') this.recordedOnlyExpenses = '0.00', @JsonKey(name: 'damage_cost') required this.damageCost, @JsonKey(name: 'shortage_cost') required this.shortageCost, @JsonKey(name: 'net_profit') required this.netProfit, @JsonKey(name: 'has_unanswered_returns') this.hasUnansweredReturns = false, this.period});
  factory _PeriodFigures.fromJson(Map<String, dynamic> json) => _$PeriodFiguresFromJson(json);

@override@JsonKey(name: 'realized_margin') final  String realizedMargin;
@override@JsonKey(name: 'deductible_expenses') final  String deductibleExpenses;
/// «محسوبة مسبقاً» — shipping and customs typed on a purchase order. They are **already
/// inside the cost of the layers that arrived**, so subtracting them again would charge the
/// investors for one customs invoice twice.
///
/// Shown beside the sum and never part of it. §6.2.4.
@override@JsonKey(name: 'recorded_only_expenses') final  String recordedOnlyExpenses;
@override@JsonKey(name: 'damage_cost') final  String damageCost;
@override@JsonKey(name: 'shortage_cost') final  String shortageCost;
@override@JsonKey(name: 'net_profit') final  String netProfit;
/// **The close is refused while this is true.** A cancelled printed order credits its material
/// back to the shelf as good stock, and closing over that divides profit the pool did not earn
/// on goods it does not have.
@override@JsonKey(name: 'has_unanswered_returns') final  bool hasUnansweredReturns;
@override final  InvestmentPeriod? period;

/// Create a copy of PeriodFigures
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodFiguresCopyWith<_PeriodFigures> get copyWith => __$PeriodFiguresCopyWithImpl<_PeriodFigures>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodFiguresToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodFigures&&(identical(other.realizedMargin, realizedMargin) || other.realizedMargin == realizedMargin)&&(identical(other.deductibleExpenses, deductibleExpenses) || other.deductibleExpenses == deductibleExpenses)&&(identical(other.recordedOnlyExpenses, recordedOnlyExpenses) || other.recordedOnlyExpenses == recordedOnlyExpenses)&&(identical(other.damageCost, damageCost) || other.damageCost == damageCost)&&(identical(other.shortageCost, shortageCost) || other.shortageCost == shortageCost)&&(identical(other.netProfit, netProfit) || other.netProfit == netProfit)&&(identical(other.hasUnansweredReturns, hasUnansweredReturns) || other.hasUnansweredReturns == hasUnansweredReturns)&&(identical(other.period, period) || other.period == period));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,realizedMargin,deductibleExpenses,recordedOnlyExpenses,damageCost,shortageCost,netProfit,hasUnansweredReturns,period);

@override
String toString() {
  return 'PeriodFigures(realizedMargin: $realizedMargin, deductibleExpenses: $deductibleExpenses, recordedOnlyExpenses: $recordedOnlyExpenses, damageCost: $damageCost, shortageCost: $shortageCost, netProfit: $netProfit, hasUnansweredReturns: $hasUnansweredReturns, period: $period)';
}


}

/// @nodoc
abstract mixin class _$PeriodFiguresCopyWith<$Res> implements $PeriodFiguresCopyWith<$Res> {
  factory _$PeriodFiguresCopyWith(_PeriodFigures value, $Res Function(_PeriodFigures) _then) = __$PeriodFiguresCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'realized_margin') String realizedMargin,@JsonKey(name: 'deductible_expenses') String deductibleExpenses,@JsonKey(name: 'recorded_only_expenses') String recordedOnlyExpenses,@JsonKey(name: 'damage_cost') String damageCost,@JsonKey(name: 'shortage_cost') String shortageCost,@JsonKey(name: 'net_profit') String netProfit,@JsonKey(name: 'has_unanswered_returns') bool hasUnansweredReturns, InvestmentPeriod? period
});


@override $InvestmentPeriodCopyWith<$Res>? get period;

}
/// @nodoc
class __$PeriodFiguresCopyWithImpl<$Res>
    implements _$PeriodFiguresCopyWith<$Res> {
  __$PeriodFiguresCopyWithImpl(this._self, this._then);

  final _PeriodFigures _self;
  final $Res Function(_PeriodFigures) _then;

/// Create a copy of PeriodFigures
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? realizedMargin = null,Object? deductibleExpenses = null,Object? recordedOnlyExpenses = null,Object? damageCost = null,Object? shortageCost = null,Object? netProfit = null,Object? hasUnansweredReturns = null,Object? period = freezed,}) {
  return _then(_PeriodFigures(
realizedMargin: null == realizedMargin ? _self.realizedMargin : realizedMargin // ignore: cast_nullable_to_non_nullable
as String,deductibleExpenses: null == deductibleExpenses ? _self.deductibleExpenses : deductibleExpenses // ignore: cast_nullable_to_non_nullable
as String,recordedOnlyExpenses: null == recordedOnlyExpenses ? _self.recordedOnlyExpenses : recordedOnlyExpenses // ignore: cast_nullable_to_non_nullable
as String,damageCost: null == damageCost ? _self.damageCost : damageCost // ignore: cast_nullable_to_non_nullable
as String,shortageCost: null == shortageCost ? _self.shortageCost : shortageCost // ignore: cast_nullable_to_non_nullable
as String,netProfit: null == netProfit ? _self.netProfit : netProfit // ignore: cast_nullable_to_non_nullable
as String,hasUnansweredReturns: null == hasUnansweredReturns ? _self.hasUnansweredReturns : hasUnansweredReturns // ignore: cast_nullable_to_non_nullable
as bool,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as InvestmentPeriod?,
  ));
}

/// Create a copy of PeriodFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvestmentPeriodCopyWith<$Res>? get period {
    if (_self.period == null) {
    return null;
  }

  return $InvestmentPeriodCopyWith<$Res>(_self.period!, (value) {
    return _then(_self.copyWith(period: value));
  });
}
}

// dart format on
