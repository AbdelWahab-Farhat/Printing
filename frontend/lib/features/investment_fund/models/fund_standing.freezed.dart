// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fund_standing.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FundValuation {

/// ما في الخزينة فعلاً — يتحرّك عند التحصيل لا عند التسليم.
 String get cash;/// البضاعةُ التي ما زالت على الرفّ، بتكلفتها المجمّدة يوم وصلت.
@JsonKey(name: 'stock_on_shelf') String get stockOnShelf;/// خرجت من الرفّ ولم تصل العميل بعد.
@JsonKey(name: 'goods_in_flight') String get goodsInFlight;/// سُلِّمت ولم تُحصَّل — بتكلفتها، لا بما ستُقبض به.
@JsonKey(name: 'receivables_at_cost') String get receivablesAtCost;/// ربحٌ يملكه مستثمرٌ ولم يصل جيبه — دَينٌ على الصندوق لا رأسُ مالٍ عامل، فيُطرح.
@JsonKey(name: 'profit_owed') String get profitOwed; String get total;
/// Create a copy of FundValuation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundValuationCopyWith<FundValuation> get copyWith => _$FundValuationCopyWithImpl<FundValuation>(this as FundValuation, _$identity);

  /// Serializes this FundValuation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundValuation&&(identical(other.cash, cash) || other.cash == cash)&&(identical(other.stockOnShelf, stockOnShelf) || other.stockOnShelf == stockOnShelf)&&(identical(other.goodsInFlight, goodsInFlight) || other.goodsInFlight == goodsInFlight)&&(identical(other.receivablesAtCost, receivablesAtCost) || other.receivablesAtCost == receivablesAtCost)&&(identical(other.profitOwed, profitOwed) || other.profitOwed == profitOwed)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cash,stockOnShelf,goodsInFlight,receivablesAtCost,profitOwed,total);

@override
String toString() {
  return 'FundValuation(cash: $cash, stockOnShelf: $stockOnShelf, goodsInFlight: $goodsInFlight, receivablesAtCost: $receivablesAtCost, profitOwed: $profitOwed, total: $total)';
}


}

/// @nodoc
abstract mixin class $FundValuationCopyWith<$Res>  {
  factory $FundValuationCopyWith(FundValuation value, $Res Function(FundValuation) _then) = _$FundValuationCopyWithImpl;
@useResult
$Res call({
 String cash,@JsonKey(name: 'stock_on_shelf') String stockOnShelf,@JsonKey(name: 'goods_in_flight') String goodsInFlight,@JsonKey(name: 'receivables_at_cost') String receivablesAtCost,@JsonKey(name: 'profit_owed') String profitOwed, String total
});




}
/// @nodoc
class _$FundValuationCopyWithImpl<$Res>
    implements $FundValuationCopyWith<$Res> {
  _$FundValuationCopyWithImpl(this._self, this._then);

  final FundValuation _self;
  final $Res Function(FundValuation) _then;

/// Create a copy of FundValuation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cash = null,Object? stockOnShelf = null,Object? goodsInFlight = null,Object? receivablesAtCost = null,Object? profitOwed = null,Object? total = null,}) {
  return _then(_self.copyWith(
cash: null == cash ? _self.cash : cash // ignore: cast_nullable_to_non_nullable
as String,stockOnShelf: null == stockOnShelf ? _self.stockOnShelf : stockOnShelf // ignore: cast_nullable_to_non_nullable
as String,goodsInFlight: null == goodsInFlight ? _self.goodsInFlight : goodsInFlight // ignore: cast_nullable_to_non_nullable
as String,receivablesAtCost: null == receivablesAtCost ? _self.receivablesAtCost : receivablesAtCost // ignore: cast_nullable_to_non_nullable
as String,profitOwed: null == profitOwed ? _self.profitOwed : profitOwed // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FundValuation].
extension FundValuationPatterns on FundValuation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundValuation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundValuation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundValuation value)  $default,){
final _that = this;
switch (_that) {
case _FundValuation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundValuation value)?  $default,){
final _that = this;
switch (_that) {
case _FundValuation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String cash, @JsonKey(name: 'stock_on_shelf')  String stockOnShelf, @JsonKey(name: 'goods_in_flight')  String goodsInFlight, @JsonKey(name: 'receivables_at_cost')  String receivablesAtCost, @JsonKey(name: 'profit_owed')  String profitOwed,  String total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundValuation() when $default != null:
return $default(_that.cash,_that.stockOnShelf,_that.goodsInFlight,_that.receivablesAtCost,_that.profitOwed,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String cash, @JsonKey(name: 'stock_on_shelf')  String stockOnShelf, @JsonKey(name: 'goods_in_flight')  String goodsInFlight, @JsonKey(name: 'receivables_at_cost')  String receivablesAtCost, @JsonKey(name: 'profit_owed')  String profitOwed,  String total)  $default,) {final _that = this;
switch (_that) {
case _FundValuation():
return $default(_that.cash,_that.stockOnShelf,_that.goodsInFlight,_that.receivablesAtCost,_that.profitOwed,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String cash, @JsonKey(name: 'stock_on_shelf')  String stockOnShelf, @JsonKey(name: 'goods_in_flight')  String goodsInFlight, @JsonKey(name: 'receivables_at_cost')  String receivablesAtCost, @JsonKey(name: 'profit_owed')  String profitOwed,  String total)?  $default,) {final _that = this;
switch (_that) {
case _FundValuation() when $default != null:
return $default(_that.cash,_that.stockOnShelf,_that.goodsInFlight,_that.receivablesAtCost,_that.profitOwed,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundValuation implements FundValuation {
  const _FundValuation({required this.cash, @JsonKey(name: 'stock_on_shelf') required this.stockOnShelf, @JsonKey(name: 'goods_in_flight') required this.goodsInFlight, @JsonKey(name: 'receivables_at_cost') required this.receivablesAtCost, @JsonKey(name: 'profit_owed') required this.profitOwed, required this.total});
  factory _FundValuation.fromJson(Map<String, dynamic> json) => _$FundValuationFromJson(json);

/// ما في الخزينة فعلاً — يتحرّك عند التحصيل لا عند التسليم.
@override final  String cash;
/// البضاعةُ التي ما زالت على الرفّ، بتكلفتها المجمّدة يوم وصلت.
@override@JsonKey(name: 'stock_on_shelf') final  String stockOnShelf;
/// خرجت من الرفّ ولم تصل العميل بعد.
@override@JsonKey(name: 'goods_in_flight') final  String goodsInFlight;
/// سُلِّمت ولم تُحصَّل — بتكلفتها، لا بما ستُقبض به.
@override@JsonKey(name: 'receivables_at_cost') final  String receivablesAtCost;
/// ربحٌ يملكه مستثمرٌ ولم يصل جيبه — دَينٌ على الصندوق لا رأسُ مالٍ عامل، فيُطرح.
@override@JsonKey(name: 'profit_owed') final  String profitOwed;
@override final  String total;

/// Create a copy of FundValuation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundValuationCopyWith<_FundValuation> get copyWith => __$FundValuationCopyWithImpl<_FundValuation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundValuationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundValuation&&(identical(other.cash, cash) || other.cash == cash)&&(identical(other.stockOnShelf, stockOnShelf) || other.stockOnShelf == stockOnShelf)&&(identical(other.goodsInFlight, goodsInFlight) || other.goodsInFlight == goodsInFlight)&&(identical(other.receivablesAtCost, receivablesAtCost) || other.receivablesAtCost == receivablesAtCost)&&(identical(other.profitOwed, profitOwed) || other.profitOwed == profitOwed)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cash,stockOnShelf,goodsInFlight,receivablesAtCost,profitOwed,total);

@override
String toString() {
  return 'FundValuation(cash: $cash, stockOnShelf: $stockOnShelf, goodsInFlight: $goodsInFlight, receivablesAtCost: $receivablesAtCost, profitOwed: $profitOwed, total: $total)';
}


}

/// @nodoc
abstract mixin class _$FundValuationCopyWith<$Res> implements $FundValuationCopyWith<$Res> {
  factory _$FundValuationCopyWith(_FundValuation value, $Res Function(_FundValuation) _then) = __$FundValuationCopyWithImpl;
@override @useResult
$Res call({
 String cash,@JsonKey(name: 'stock_on_shelf') String stockOnShelf,@JsonKey(name: 'goods_in_flight') String goodsInFlight,@JsonKey(name: 'receivables_at_cost') String receivablesAtCost,@JsonKey(name: 'profit_owed') String profitOwed, String total
});




}
/// @nodoc
class __$FundValuationCopyWithImpl<$Res>
    implements _$FundValuationCopyWith<$Res> {
  __$FundValuationCopyWithImpl(this._self, this._then);

  final _FundValuation _self;
  final $Res Function(_FundValuation) _then;

/// Create a copy of FundValuation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cash = null,Object? stockOnShelf = null,Object? goodsInFlight = null,Object? receivablesAtCost = null,Object? profitOwed = null,Object? total = null,}) {
  return _then(_FundValuation(
cash: null == cash ? _self.cash : cash // ignore: cast_nullable_to_non_nullable
as String,stockOnShelf: null == stockOnShelf ? _self.stockOnShelf : stockOnShelf // ignore: cast_nullable_to_non_nullable
as String,goodsInFlight: null == goodsInFlight ? _self.goodsInFlight : goodsInFlight // ignore: cast_nullable_to_non_nullable
as String,receivablesAtCost: null == receivablesAtCost ? _self.receivablesAtCost : receivablesAtCost // ignore: cast_nullable_to_non_nullable
as String,profitOwed: null == profitOwed ? _self.profitOwed : profitOwed // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$FundPeriod {

 int get id; String get code; String get status;@JsonKey(name: 'status_label') String get statusLabel;@JsonKey(name: 'starts_on') String get startsOn;@JsonKey(name: 'ends_on') String get endsOn;/// آخرُ يومٍ يُقبَل فيه إيداعُ رأس مال؛ ما بعده يُحتجز للفترة التالية.
@JsonKey(name: 'subscription_closes_on') String get subscriptionClosesOn;/// **حلّ موعدُها ولم تُقفَل.** الجدولةُ تُقفلها في ساعتها الأولى، فبقاءُ هذا صادقاً يعني
/// أنها صمتت — واللوحةُ تقوله ولا تسكت عنه.
@JsonKey(name: 'is_due_to_close') bool get isDueToClose;/// كم يوماً مرّ وهي مستحقّةٌ ولم تُقفَل — `null` ما لم تستحقّ، وصفرٌ يومَها.
@JsonKey(name: 'overdue_days') int? get overdueDays;/// **كم طلبيةً تحبسها «قيد الإغلاق».** `null` لغير المنتظِرة: المفتوحةُ لا تنتظر شيئاً بعد،
/// والمغلقةُ لم يبقَ لها شيء.
@JsonKey(name: 'owed_orders') int? get owedOrders;@JsonKey(name: 'period_months') int get periodMonths;@JsonKey(name: 'investor_profit_share_percent') String get investorProfitSharePercent;@JsonKey(name: 'opening_stock_cost') String get openingStockCost;@JsonKey(name: 'opening_cash') String get openingCash;/// **بابُ الاكتتاب.** الخادمُ يقرّر، لا الشاشةُ بمقارنة تواريخ: قاعدةٌ واحدة تُنفَّذ في موضعٍ
/// واحد، ولا تختلف نسخةٌ مثبَّتةٌ على هاتف عن الخادم يوم تتغيّر.
@JsonKey(name: 'accepts_capital') bool get acceptsCapital;/// **ولمن هذه النافذة؟** الداخلُ منها لا يقاسم شهراً بدأ بالفعل: نصيبُه يبدأ من الفترة
/// التالية. والاستثناءُ أوّلُ فتراتِ الصندوق — ولا تحسبه الشاشةُ، الخادمُ يقوله.
@JsonKey(name: 'subscription_serves_next_period') bool get subscriptionServesNextPeriod;/// مدةُ حبس رأس المال المجمَّدة على هذه الفترة — ما سيُنسَخ على كل دفعةٍ تدخل فيها.
@JsonKey(name: 'capital_lock_months') int get capitalLockMonths;/// أهذه آخرُ فتراتِ دورةِ تسوية؟
@JsonKey(name: 'ends_settlement_cycle') bool get endsSettlementCycle;/// ما كُتب عليها إن أُقفلت بتجاوز — يبقى على الشاشة ولا يُطوى.
@JsonKey(name: 'override_reason') String? get overrideReason;/// أرقامُ الإقفال — `null` ما دامت مفتوحة، فلا يُعرض صفرٌ مكان «لم يُحسب بعد».
@JsonKey(name: 'closed_at') String? get closedAt;@JsonKey(name: 'net_profit') String? get netProfit;@JsonKey(name: 'investors_pool') String? get investorsPool;@JsonKey(name: 'company_share') String? get companyShare;@JsonKey(name: 'sales_revenue') String? get salesRevenue;@JsonKey(name: 'closing_stock_cost') String? get closingStockCost;@JsonKey(name: 'closing_cash') String? get closingCash;
/// Create a copy of FundPeriod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundPeriodCopyWith<FundPeriod> get copyWith => _$FundPeriodCopyWithImpl<FundPeriod>(this as FundPeriod, _$identity);

  /// Serializes this FundPeriod to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundPeriod&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.startsOn, startsOn) || other.startsOn == startsOn)&&(identical(other.endsOn, endsOn) || other.endsOn == endsOn)&&(identical(other.subscriptionClosesOn, subscriptionClosesOn) || other.subscriptionClosesOn == subscriptionClosesOn)&&(identical(other.isDueToClose, isDueToClose) || other.isDueToClose == isDueToClose)&&(identical(other.overdueDays, overdueDays) || other.overdueDays == overdueDays)&&(identical(other.owedOrders, owedOrders) || other.owedOrders == owedOrders)&&(identical(other.periodMonths, periodMonths) || other.periodMonths == periodMonths)&&(identical(other.investorProfitSharePercent, investorProfitSharePercent) || other.investorProfitSharePercent == investorProfitSharePercent)&&(identical(other.openingStockCost, openingStockCost) || other.openingStockCost == openingStockCost)&&(identical(other.openingCash, openingCash) || other.openingCash == openingCash)&&(identical(other.acceptsCapital, acceptsCapital) || other.acceptsCapital == acceptsCapital)&&(identical(other.subscriptionServesNextPeriod, subscriptionServesNextPeriod) || other.subscriptionServesNextPeriod == subscriptionServesNextPeriod)&&(identical(other.capitalLockMonths, capitalLockMonths) || other.capitalLockMonths == capitalLockMonths)&&(identical(other.endsSettlementCycle, endsSettlementCycle) || other.endsSettlementCycle == endsSettlementCycle)&&(identical(other.overrideReason, overrideReason) || other.overrideReason == overrideReason)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.netProfit, netProfit) || other.netProfit == netProfit)&&(identical(other.investorsPool, investorsPool) || other.investorsPool == investorsPool)&&(identical(other.companyShare, companyShare) || other.companyShare == companyShare)&&(identical(other.salesRevenue, salesRevenue) || other.salesRevenue == salesRevenue)&&(identical(other.closingStockCost, closingStockCost) || other.closingStockCost == closingStockCost)&&(identical(other.closingCash, closingCash) || other.closingCash == closingCash));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,code,status,statusLabel,startsOn,endsOn,subscriptionClosesOn,isDueToClose,overdueDays,owedOrders,periodMonths,investorProfitSharePercent,openingStockCost,openingCash,acceptsCapital,subscriptionServesNextPeriod,capitalLockMonths,endsSettlementCycle,overrideReason,closedAt,netProfit,investorsPool,companyShare,salesRevenue,closingStockCost,closingCash]);

@override
String toString() {
  return 'FundPeriod(id: $id, code: $code, status: $status, statusLabel: $statusLabel, startsOn: $startsOn, endsOn: $endsOn, subscriptionClosesOn: $subscriptionClosesOn, isDueToClose: $isDueToClose, overdueDays: $overdueDays, owedOrders: $owedOrders, periodMonths: $periodMonths, investorProfitSharePercent: $investorProfitSharePercent, openingStockCost: $openingStockCost, openingCash: $openingCash, acceptsCapital: $acceptsCapital, subscriptionServesNextPeriod: $subscriptionServesNextPeriod, capitalLockMonths: $capitalLockMonths, endsSettlementCycle: $endsSettlementCycle, overrideReason: $overrideReason, closedAt: $closedAt, netProfit: $netProfit, investorsPool: $investorsPool, companyShare: $companyShare, salesRevenue: $salesRevenue, closingStockCost: $closingStockCost, closingCash: $closingCash)';
}


}

/// @nodoc
abstract mixin class $FundPeriodCopyWith<$Res>  {
  factory $FundPeriodCopyWith(FundPeriod value, $Res Function(FundPeriod) _then) = _$FundPeriodCopyWithImpl;
@useResult
$Res call({
 int id, String code, String status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'starts_on') String startsOn,@JsonKey(name: 'ends_on') String endsOn,@JsonKey(name: 'subscription_closes_on') String subscriptionClosesOn,@JsonKey(name: 'is_due_to_close') bool isDueToClose,@JsonKey(name: 'overdue_days') int? overdueDays,@JsonKey(name: 'owed_orders') int? owedOrders,@JsonKey(name: 'period_months') int periodMonths,@JsonKey(name: 'investor_profit_share_percent') String investorProfitSharePercent,@JsonKey(name: 'opening_stock_cost') String openingStockCost,@JsonKey(name: 'opening_cash') String openingCash,@JsonKey(name: 'accepts_capital') bool acceptsCapital,@JsonKey(name: 'subscription_serves_next_period') bool subscriptionServesNextPeriod,@JsonKey(name: 'capital_lock_months') int capitalLockMonths,@JsonKey(name: 'ends_settlement_cycle') bool endsSettlementCycle,@JsonKey(name: 'override_reason') String? overrideReason,@JsonKey(name: 'closed_at') String? closedAt,@JsonKey(name: 'net_profit') String? netProfit,@JsonKey(name: 'investors_pool') String? investorsPool,@JsonKey(name: 'company_share') String? companyShare,@JsonKey(name: 'sales_revenue') String? salesRevenue,@JsonKey(name: 'closing_stock_cost') String? closingStockCost,@JsonKey(name: 'closing_cash') String? closingCash
});




}
/// @nodoc
class _$FundPeriodCopyWithImpl<$Res>
    implements $FundPeriodCopyWith<$Res> {
  _$FundPeriodCopyWithImpl(this._self, this._then);

  final FundPeriod _self;
  final $Res Function(FundPeriod) _then;

/// Create a copy of FundPeriod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? status = null,Object? statusLabel = null,Object? startsOn = null,Object? endsOn = null,Object? subscriptionClosesOn = null,Object? isDueToClose = null,Object? overdueDays = freezed,Object? owedOrders = freezed,Object? periodMonths = null,Object? investorProfitSharePercent = null,Object? openingStockCost = null,Object? openingCash = null,Object? acceptsCapital = null,Object? subscriptionServesNextPeriod = null,Object? capitalLockMonths = null,Object? endsSettlementCycle = null,Object? overrideReason = freezed,Object? closedAt = freezed,Object? netProfit = freezed,Object? investorsPool = freezed,Object? companyShare = freezed,Object? salesRevenue = freezed,Object? closingStockCost = freezed,Object? closingCash = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,startsOn: null == startsOn ? _self.startsOn : startsOn // ignore: cast_nullable_to_non_nullable
as String,endsOn: null == endsOn ? _self.endsOn : endsOn // ignore: cast_nullable_to_non_nullable
as String,subscriptionClosesOn: null == subscriptionClosesOn ? _self.subscriptionClosesOn : subscriptionClosesOn // ignore: cast_nullable_to_non_nullable
as String,isDueToClose: null == isDueToClose ? _self.isDueToClose : isDueToClose // ignore: cast_nullable_to_non_nullable
as bool,overdueDays: freezed == overdueDays ? _self.overdueDays : overdueDays // ignore: cast_nullable_to_non_nullable
as int?,owedOrders: freezed == owedOrders ? _self.owedOrders : owedOrders // ignore: cast_nullable_to_non_nullable
as int?,periodMonths: null == periodMonths ? _self.periodMonths : periodMonths // ignore: cast_nullable_to_non_nullable
as int,investorProfitSharePercent: null == investorProfitSharePercent ? _self.investorProfitSharePercent : investorProfitSharePercent // ignore: cast_nullable_to_non_nullable
as String,openingStockCost: null == openingStockCost ? _self.openingStockCost : openingStockCost // ignore: cast_nullable_to_non_nullable
as String,openingCash: null == openingCash ? _self.openingCash : openingCash // ignore: cast_nullable_to_non_nullable
as String,acceptsCapital: null == acceptsCapital ? _self.acceptsCapital : acceptsCapital // ignore: cast_nullable_to_non_nullable
as bool,subscriptionServesNextPeriod: null == subscriptionServesNextPeriod ? _self.subscriptionServesNextPeriod : subscriptionServesNextPeriod // ignore: cast_nullable_to_non_nullable
as bool,capitalLockMonths: null == capitalLockMonths ? _self.capitalLockMonths : capitalLockMonths // ignore: cast_nullable_to_non_nullable
as int,endsSettlementCycle: null == endsSettlementCycle ? _self.endsSettlementCycle : endsSettlementCycle // ignore: cast_nullable_to_non_nullable
as bool,overrideReason: freezed == overrideReason ? _self.overrideReason : overrideReason // ignore: cast_nullable_to_non_nullable
as String?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as String?,netProfit: freezed == netProfit ? _self.netProfit : netProfit // ignore: cast_nullable_to_non_nullable
as String?,investorsPool: freezed == investorsPool ? _self.investorsPool : investorsPool // ignore: cast_nullable_to_non_nullable
as String?,companyShare: freezed == companyShare ? _self.companyShare : companyShare // ignore: cast_nullable_to_non_nullable
as String?,salesRevenue: freezed == salesRevenue ? _self.salesRevenue : salesRevenue // ignore: cast_nullable_to_non_nullable
as String?,closingStockCost: freezed == closingStockCost ? _self.closingStockCost : closingStockCost // ignore: cast_nullable_to_non_nullable
as String?,closingCash: freezed == closingCash ? _self.closingCash : closingCash // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FundPeriod].
extension FundPeriodPatterns on FundPeriod {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundPeriod value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundPeriod() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundPeriod value)  $default,){
final _that = this;
switch (_that) {
case _FundPeriod():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundPeriod value)?  $default,){
final _that = this;
switch (_that) {
case _FundPeriod() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'starts_on')  String startsOn, @JsonKey(name: 'ends_on')  String endsOn, @JsonKey(name: 'subscription_closes_on')  String subscriptionClosesOn, @JsonKey(name: 'is_due_to_close')  bool isDueToClose, @JsonKey(name: 'overdue_days')  int? overdueDays, @JsonKey(name: 'owed_orders')  int? owedOrders, @JsonKey(name: 'period_months')  int periodMonths, @JsonKey(name: 'investor_profit_share_percent')  String investorProfitSharePercent, @JsonKey(name: 'opening_stock_cost')  String openingStockCost, @JsonKey(name: 'opening_cash')  String openingCash, @JsonKey(name: 'accepts_capital')  bool acceptsCapital, @JsonKey(name: 'subscription_serves_next_period')  bool subscriptionServesNextPeriod, @JsonKey(name: 'capital_lock_months')  int capitalLockMonths, @JsonKey(name: 'ends_settlement_cycle')  bool endsSettlementCycle, @JsonKey(name: 'override_reason')  String? overrideReason, @JsonKey(name: 'closed_at')  String? closedAt, @JsonKey(name: 'net_profit')  String? netProfit, @JsonKey(name: 'investors_pool')  String? investorsPool, @JsonKey(name: 'company_share')  String? companyShare, @JsonKey(name: 'sales_revenue')  String? salesRevenue, @JsonKey(name: 'closing_stock_cost')  String? closingStockCost, @JsonKey(name: 'closing_cash')  String? closingCash)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundPeriod() when $default != null:
return $default(_that.id,_that.code,_that.status,_that.statusLabel,_that.startsOn,_that.endsOn,_that.subscriptionClosesOn,_that.isDueToClose,_that.overdueDays,_that.owedOrders,_that.periodMonths,_that.investorProfitSharePercent,_that.openingStockCost,_that.openingCash,_that.acceptsCapital,_that.subscriptionServesNextPeriod,_that.capitalLockMonths,_that.endsSettlementCycle,_that.overrideReason,_that.closedAt,_that.netProfit,_that.investorsPool,_that.companyShare,_that.salesRevenue,_that.closingStockCost,_that.closingCash);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'starts_on')  String startsOn, @JsonKey(name: 'ends_on')  String endsOn, @JsonKey(name: 'subscription_closes_on')  String subscriptionClosesOn, @JsonKey(name: 'is_due_to_close')  bool isDueToClose, @JsonKey(name: 'overdue_days')  int? overdueDays, @JsonKey(name: 'owed_orders')  int? owedOrders, @JsonKey(name: 'period_months')  int periodMonths, @JsonKey(name: 'investor_profit_share_percent')  String investorProfitSharePercent, @JsonKey(name: 'opening_stock_cost')  String openingStockCost, @JsonKey(name: 'opening_cash')  String openingCash, @JsonKey(name: 'accepts_capital')  bool acceptsCapital, @JsonKey(name: 'subscription_serves_next_period')  bool subscriptionServesNextPeriod, @JsonKey(name: 'capital_lock_months')  int capitalLockMonths, @JsonKey(name: 'ends_settlement_cycle')  bool endsSettlementCycle, @JsonKey(name: 'override_reason')  String? overrideReason, @JsonKey(name: 'closed_at')  String? closedAt, @JsonKey(name: 'net_profit')  String? netProfit, @JsonKey(name: 'investors_pool')  String? investorsPool, @JsonKey(name: 'company_share')  String? companyShare, @JsonKey(name: 'sales_revenue')  String? salesRevenue, @JsonKey(name: 'closing_stock_cost')  String? closingStockCost, @JsonKey(name: 'closing_cash')  String? closingCash)  $default,) {final _that = this;
switch (_that) {
case _FundPeriod():
return $default(_that.id,_that.code,_that.status,_that.statusLabel,_that.startsOn,_that.endsOn,_that.subscriptionClosesOn,_that.isDueToClose,_that.overdueDays,_that.owedOrders,_that.periodMonths,_that.investorProfitSharePercent,_that.openingStockCost,_that.openingCash,_that.acceptsCapital,_that.subscriptionServesNextPeriod,_that.capitalLockMonths,_that.endsSettlementCycle,_that.overrideReason,_that.closedAt,_that.netProfit,_that.investorsPool,_that.companyShare,_that.salesRevenue,_that.closingStockCost,_that.closingCash);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'starts_on')  String startsOn, @JsonKey(name: 'ends_on')  String endsOn, @JsonKey(name: 'subscription_closes_on')  String subscriptionClosesOn, @JsonKey(name: 'is_due_to_close')  bool isDueToClose, @JsonKey(name: 'overdue_days')  int? overdueDays, @JsonKey(name: 'owed_orders')  int? owedOrders, @JsonKey(name: 'period_months')  int periodMonths, @JsonKey(name: 'investor_profit_share_percent')  String investorProfitSharePercent, @JsonKey(name: 'opening_stock_cost')  String openingStockCost, @JsonKey(name: 'opening_cash')  String openingCash, @JsonKey(name: 'accepts_capital')  bool acceptsCapital, @JsonKey(name: 'subscription_serves_next_period')  bool subscriptionServesNextPeriod, @JsonKey(name: 'capital_lock_months')  int capitalLockMonths, @JsonKey(name: 'ends_settlement_cycle')  bool endsSettlementCycle, @JsonKey(name: 'override_reason')  String? overrideReason, @JsonKey(name: 'closed_at')  String? closedAt, @JsonKey(name: 'net_profit')  String? netProfit, @JsonKey(name: 'investors_pool')  String? investorsPool, @JsonKey(name: 'company_share')  String? companyShare, @JsonKey(name: 'sales_revenue')  String? salesRevenue, @JsonKey(name: 'closing_stock_cost')  String? closingStockCost, @JsonKey(name: 'closing_cash')  String? closingCash)?  $default,) {final _that = this;
switch (_that) {
case _FundPeriod() when $default != null:
return $default(_that.id,_that.code,_that.status,_that.statusLabel,_that.startsOn,_that.endsOn,_that.subscriptionClosesOn,_that.isDueToClose,_that.overdueDays,_that.owedOrders,_that.periodMonths,_that.investorProfitSharePercent,_that.openingStockCost,_that.openingCash,_that.acceptsCapital,_that.subscriptionServesNextPeriod,_that.capitalLockMonths,_that.endsSettlementCycle,_that.overrideReason,_that.closedAt,_that.netProfit,_that.investorsPool,_that.companyShare,_that.salesRevenue,_that.closingStockCost,_that.closingCash);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundPeriod implements FundPeriod {
  const _FundPeriod({required this.id, required this.code, required this.status, @JsonKey(name: 'status_label') required this.statusLabel, @JsonKey(name: 'starts_on') required this.startsOn, @JsonKey(name: 'ends_on') required this.endsOn, @JsonKey(name: 'subscription_closes_on') required this.subscriptionClosesOn, @JsonKey(name: 'is_due_to_close') required this.isDueToClose, @JsonKey(name: 'overdue_days') this.overdueDays, @JsonKey(name: 'owed_orders') this.owedOrders, @JsonKey(name: 'period_months') required this.periodMonths, @JsonKey(name: 'investor_profit_share_percent') required this.investorProfitSharePercent, @JsonKey(name: 'opening_stock_cost') required this.openingStockCost, @JsonKey(name: 'opening_cash') required this.openingCash, @JsonKey(name: 'accepts_capital') this.acceptsCapital = false, @JsonKey(name: 'subscription_serves_next_period') this.subscriptionServesNextPeriod = false, @JsonKey(name: 'capital_lock_months') this.capitalLockMonths = 12, @JsonKey(name: 'ends_settlement_cycle') this.endsSettlementCycle = false, @JsonKey(name: 'override_reason') this.overrideReason, @JsonKey(name: 'closed_at') this.closedAt, @JsonKey(name: 'net_profit') this.netProfit, @JsonKey(name: 'investors_pool') this.investorsPool, @JsonKey(name: 'company_share') this.companyShare, @JsonKey(name: 'sales_revenue') this.salesRevenue, @JsonKey(name: 'closing_stock_cost') this.closingStockCost, @JsonKey(name: 'closing_cash') this.closingCash});
  factory _FundPeriod.fromJson(Map<String, dynamic> json) => _$FundPeriodFromJson(json);

@override final  int id;
@override final  String code;
@override final  String status;
@override@JsonKey(name: 'status_label') final  String statusLabel;
@override@JsonKey(name: 'starts_on') final  String startsOn;
@override@JsonKey(name: 'ends_on') final  String endsOn;
/// آخرُ يومٍ يُقبَل فيه إيداعُ رأس مال؛ ما بعده يُحتجز للفترة التالية.
@override@JsonKey(name: 'subscription_closes_on') final  String subscriptionClosesOn;
/// **حلّ موعدُها ولم تُقفَل.** الجدولةُ تُقفلها في ساعتها الأولى، فبقاءُ هذا صادقاً يعني
/// أنها صمتت — واللوحةُ تقوله ولا تسكت عنه.
@override@JsonKey(name: 'is_due_to_close') final  bool isDueToClose;
/// كم يوماً مرّ وهي مستحقّةٌ ولم تُقفَل — `null` ما لم تستحقّ، وصفرٌ يومَها.
@override@JsonKey(name: 'overdue_days') final  int? overdueDays;
/// **كم طلبيةً تحبسها «قيد الإغلاق».** `null` لغير المنتظِرة: المفتوحةُ لا تنتظر شيئاً بعد،
/// والمغلقةُ لم يبقَ لها شيء.
@override@JsonKey(name: 'owed_orders') final  int? owedOrders;
@override@JsonKey(name: 'period_months') final  int periodMonths;
@override@JsonKey(name: 'investor_profit_share_percent') final  String investorProfitSharePercent;
@override@JsonKey(name: 'opening_stock_cost') final  String openingStockCost;
@override@JsonKey(name: 'opening_cash') final  String openingCash;
/// **بابُ الاكتتاب.** الخادمُ يقرّر، لا الشاشةُ بمقارنة تواريخ: قاعدةٌ واحدة تُنفَّذ في موضعٍ
/// واحد، ولا تختلف نسخةٌ مثبَّتةٌ على هاتف عن الخادم يوم تتغيّر.
@override@JsonKey(name: 'accepts_capital') final  bool acceptsCapital;
/// **ولمن هذه النافذة؟** الداخلُ منها لا يقاسم شهراً بدأ بالفعل: نصيبُه يبدأ من الفترة
/// التالية. والاستثناءُ أوّلُ فتراتِ الصندوق — ولا تحسبه الشاشةُ، الخادمُ يقوله.
@override@JsonKey(name: 'subscription_serves_next_period') final  bool subscriptionServesNextPeriod;
/// مدةُ حبس رأس المال المجمَّدة على هذه الفترة — ما سيُنسَخ على كل دفعةٍ تدخل فيها.
@override@JsonKey(name: 'capital_lock_months') final  int capitalLockMonths;
/// أهذه آخرُ فتراتِ دورةِ تسوية؟
@override@JsonKey(name: 'ends_settlement_cycle') final  bool endsSettlementCycle;
/// ما كُتب عليها إن أُقفلت بتجاوز — يبقى على الشاشة ولا يُطوى.
@override@JsonKey(name: 'override_reason') final  String? overrideReason;
/// أرقامُ الإقفال — `null` ما دامت مفتوحة، فلا يُعرض صفرٌ مكان «لم يُحسب بعد».
@override@JsonKey(name: 'closed_at') final  String? closedAt;
@override@JsonKey(name: 'net_profit') final  String? netProfit;
@override@JsonKey(name: 'investors_pool') final  String? investorsPool;
@override@JsonKey(name: 'company_share') final  String? companyShare;
@override@JsonKey(name: 'sales_revenue') final  String? salesRevenue;
@override@JsonKey(name: 'closing_stock_cost') final  String? closingStockCost;
@override@JsonKey(name: 'closing_cash') final  String? closingCash;

/// Create a copy of FundPeriod
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundPeriodCopyWith<_FundPeriod> get copyWith => __$FundPeriodCopyWithImpl<_FundPeriod>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundPeriodToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundPeriod&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.startsOn, startsOn) || other.startsOn == startsOn)&&(identical(other.endsOn, endsOn) || other.endsOn == endsOn)&&(identical(other.subscriptionClosesOn, subscriptionClosesOn) || other.subscriptionClosesOn == subscriptionClosesOn)&&(identical(other.isDueToClose, isDueToClose) || other.isDueToClose == isDueToClose)&&(identical(other.overdueDays, overdueDays) || other.overdueDays == overdueDays)&&(identical(other.owedOrders, owedOrders) || other.owedOrders == owedOrders)&&(identical(other.periodMonths, periodMonths) || other.periodMonths == periodMonths)&&(identical(other.investorProfitSharePercent, investorProfitSharePercent) || other.investorProfitSharePercent == investorProfitSharePercent)&&(identical(other.openingStockCost, openingStockCost) || other.openingStockCost == openingStockCost)&&(identical(other.openingCash, openingCash) || other.openingCash == openingCash)&&(identical(other.acceptsCapital, acceptsCapital) || other.acceptsCapital == acceptsCapital)&&(identical(other.subscriptionServesNextPeriod, subscriptionServesNextPeriod) || other.subscriptionServesNextPeriod == subscriptionServesNextPeriod)&&(identical(other.capitalLockMonths, capitalLockMonths) || other.capitalLockMonths == capitalLockMonths)&&(identical(other.endsSettlementCycle, endsSettlementCycle) || other.endsSettlementCycle == endsSettlementCycle)&&(identical(other.overrideReason, overrideReason) || other.overrideReason == overrideReason)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.netProfit, netProfit) || other.netProfit == netProfit)&&(identical(other.investorsPool, investorsPool) || other.investorsPool == investorsPool)&&(identical(other.companyShare, companyShare) || other.companyShare == companyShare)&&(identical(other.salesRevenue, salesRevenue) || other.salesRevenue == salesRevenue)&&(identical(other.closingStockCost, closingStockCost) || other.closingStockCost == closingStockCost)&&(identical(other.closingCash, closingCash) || other.closingCash == closingCash));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,code,status,statusLabel,startsOn,endsOn,subscriptionClosesOn,isDueToClose,overdueDays,owedOrders,periodMonths,investorProfitSharePercent,openingStockCost,openingCash,acceptsCapital,subscriptionServesNextPeriod,capitalLockMonths,endsSettlementCycle,overrideReason,closedAt,netProfit,investorsPool,companyShare,salesRevenue,closingStockCost,closingCash]);

@override
String toString() {
  return 'FundPeriod(id: $id, code: $code, status: $status, statusLabel: $statusLabel, startsOn: $startsOn, endsOn: $endsOn, subscriptionClosesOn: $subscriptionClosesOn, isDueToClose: $isDueToClose, overdueDays: $overdueDays, owedOrders: $owedOrders, periodMonths: $periodMonths, investorProfitSharePercent: $investorProfitSharePercent, openingStockCost: $openingStockCost, openingCash: $openingCash, acceptsCapital: $acceptsCapital, subscriptionServesNextPeriod: $subscriptionServesNextPeriod, capitalLockMonths: $capitalLockMonths, endsSettlementCycle: $endsSettlementCycle, overrideReason: $overrideReason, closedAt: $closedAt, netProfit: $netProfit, investorsPool: $investorsPool, companyShare: $companyShare, salesRevenue: $salesRevenue, closingStockCost: $closingStockCost, closingCash: $closingCash)';
}


}

/// @nodoc
abstract mixin class _$FundPeriodCopyWith<$Res> implements $FundPeriodCopyWith<$Res> {
  factory _$FundPeriodCopyWith(_FundPeriod value, $Res Function(_FundPeriod) _then) = __$FundPeriodCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'starts_on') String startsOn,@JsonKey(name: 'ends_on') String endsOn,@JsonKey(name: 'subscription_closes_on') String subscriptionClosesOn,@JsonKey(name: 'is_due_to_close') bool isDueToClose,@JsonKey(name: 'overdue_days') int? overdueDays,@JsonKey(name: 'owed_orders') int? owedOrders,@JsonKey(name: 'period_months') int periodMonths,@JsonKey(name: 'investor_profit_share_percent') String investorProfitSharePercent,@JsonKey(name: 'opening_stock_cost') String openingStockCost,@JsonKey(name: 'opening_cash') String openingCash,@JsonKey(name: 'accepts_capital') bool acceptsCapital,@JsonKey(name: 'subscription_serves_next_period') bool subscriptionServesNextPeriod,@JsonKey(name: 'capital_lock_months') int capitalLockMonths,@JsonKey(name: 'ends_settlement_cycle') bool endsSettlementCycle,@JsonKey(name: 'override_reason') String? overrideReason,@JsonKey(name: 'closed_at') String? closedAt,@JsonKey(name: 'net_profit') String? netProfit,@JsonKey(name: 'investors_pool') String? investorsPool,@JsonKey(name: 'company_share') String? companyShare,@JsonKey(name: 'sales_revenue') String? salesRevenue,@JsonKey(name: 'closing_stock_cost') String? closingStockCost,@JsonKey(name: 'closing_cash') String? closingCash
});




}
/// @nodoc
class __$FundPeriodCopyWithImpl<$Res>
    implements _$FundPeriodCopyWith<$Res> {
  __$FundPeriodCopyWithImpl(this._self, this._then);

  final _FundPeriod _self;
  final $Res Function(_FundPeriod) _then;

/// Create a copy of FundPeriod
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? status = null,Object? statusLabel = null,Object? startsOn = null,Object? endsOn = null,Object? subscriptionClosesOn = null,Object? isDueToClose = null,Object? overdueDays = freezed,Object? owedOrders = freezed,Object? periodMonths = null,Object? investorProfitSharePercent = null,Object? openingStockCost = null,Object? openingCash = null,Object? acceptsCapital = null,Object? subscriptionServesNextPeriod = null,Object? capitalLockMonths = null,Object? endsSettlementCycle = null,Object? overrideReason = freezed,Object? closedAt = freezed,Object? netProfit = freezed,Object? investorsPool = freezed,Object? companyShare = freezed,Object? salesRevenue = freezed,Object? closingStockCost = freezed,Object? closingCash = freezed,}) {
  return _then(_FundPeriod(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,startsOn: null == startsOn ? _self.startsOn : startsOn // ignore: cast_nullable_to_non_nullable
as String,endsOn: null == endsOn ? _self.endsOn : endsOn // ignore: cast_nullable_to_non_nullable
as String,subscriptionClosesOn: null == subscriptionClosesOn ? _self.subscriptionClosesOn : subscriptionClosesOn // ignore: cast_nullable_to_non_nullable
as String,isDueToClose: null == isDueToClose ? _self.isDueToClose : isDueToClose // ignore: cast_nullable_to_non_nullable
as bool,overdueDays: freezed == overdueDays ? _self.overdueDays : overdueDays // ignore: cast_nullable_to_non_nullable
as int?,owedOrders: freezed == owedOrders ? _self.owedOrders : owedOrders // ignore: cast_nullable_to_non_nullable
as int?,periodMonths: null == periodMonths ? _self.periodMonths : periodMonths // ignore: cast_nullable_to_non_nullable
as int,investorProfitSharePercent: null == investorProfitSharePercent ? _self.investorProfitSharePercent : investorProfitSharePercent // ignore: cast_nullable_to_non_nullable
as String,openingStockCost: null == openingStockCost ? _self.openingStockCost : openingStockCost // ignore: cast_nullable_to_non_nullable
as String,openingCash: null == openingCash ? _self.openingCash : openingCash // ignore: cast_nullable_to_non_nullable
as String,acceptsCapital: null == acceptsCapital ? _self.acceptsCapital : acceptsCapital // ignore: cast_nullable_to_non_nullable
as bool,subscriptionServesNextPeriod: null == subscriptionServesNextPeriod ? _self.subscriptionServesNextPeriod : subscriptionServesNextPeriod // ignore: cast_nullable_to_non_nullable
as bool,capitalLockMonths: null == capitalLockMonths ? _self.capitalLockMonths : capitalLockMonths // ignore: cast_nullable_to_non_nullable
as int,endsSettlementCycle: null == endsSettlementCycle ? _self.endsSettlementCycle : endsSettlementCycle // ignore: cast_nullable_to_non_nullable
as bool,overrideReason: freezed == overrideReason ? _self.overrideReason : overrideReason // ignore: cast_nullable_to_non_nullable
as String?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as String?,netProfit: freezed == netProfit ? _self.netProfit : netProfit // ignore: cast_nullable_to_non_nullable
as String?,investorsPool: freezed == investorsPool ? _self.investorsPool : investorsPool // ignore: cast_nullable_to_non_nullable
as String?,companyShare: freezed == companyShare ? _self.companyShare : companyShare // ignore: cast_nullable_to_non_nullable
as String?,salesRevenue: freezed == salesRevenue ? _self.salesRevenue : salesRevenue // ignore: cast_nullable_to_non_nullable
as String?,closingStockCost: freezed == closingStockCost ? _self.closingStockCost : closingStockCost // ignore: cast_nullable_to_non_nullable
as String?,closingCash: freezed == closingCash ? _self.closingCash : closingCash // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$FundHolder {

@JsonKey(name: 'investor_id') int get investorId; String get name; String get units;@JsonKey(name: 'share_percent') String get sharePercent; String get capital; String get profit;/// **اكتتب في نافذة هذه الفترة، فنصيبُه منها صفر ومن التالية كامل.** وصفرٌ بجانب اسمِ رجلٍ
/// وضع مالَه أمس يُقرأ عطباً، فيقولها السطرُ بلفظها.
@JsonKey(name: 'share_starts_next_period') bool get shareStartsNextPeriod;/// **نسبتُه في الفترة التالية لو فُتحت الليلة** — بكلّ وحداته، ومنها ما ينتظر. تقديرٌ لا
/// عهد: إيداعٌ أو سحبٌ قبل بدئها يغيّره. والخادمُ يحسبه، لا الشاشة.
@JsonKey(name: 'next_share_percent') String get nextSharePercent;
/// Create a copy of FundHolder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundHolderCopyWith<FundHolder> get copyWith => _$FundHolderCopyWithImpl<FundHolder>(this as FundHolder, _$identity);

  /// Serializes this FundHolder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundHolder&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.name, name) || other.name == name)&&(identical(other.units, units) || other.units == units)&&(identical(other.sharePercent, sharePercent) || other.sharePercent == sharePercent)&&(identical(other.capital, capital) || other.capital == capital)&&(identical(other.profit, profit) || other.profit == profit)&&(identical(other.shareStartsNextPeriod, shareStartsNextPeriod) || other.shareStartsNextPeriod == shareStartsNextPeriod)&&(identical(other.nextSharePercent, nextSharePercent) || other.nextSharePercent == nextSharePercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,investorId,name,units,sharePercent,capital,profit,shareStartsNextPeriod,nextSharePercent);

@override
String toString() {
  return 'FundHolder(investorId: $investorId, name: $name, units: $units, sharePercent: $sharePercent, capital: $capital, profit: $profit, shareStartsNextPeriod: $shareStartsNextPeriod, nextSharePercent: $nextSharePercent)';
}


}

/// @nodoc
abstract mixin class $FundHolderCopyWith<$Res>  {
  factory $FundHolderCopyWith(FundHolder value, $Res Function(FundHolder) _then) = _$FundHolderCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'investor_id') int investorId, String name, String units,@JsonKey(name: 'share_percent') String sharePercent, String capital, String profit,@JsonKey(name: 'share_starts_next_period') bool shareStartsNextPeriod,@JsonKey(name: 'next_share_percent') String nextSharePercent
});




}
/// @nodoc
class _$FundHolderCopyWithImpl<$Res>
    implements $FundHolderCopyWith<$Res> {
  _$FundHolderCopyWithImpl(this._self, this._then);

  final FundHolder _self;
  final $Res Function(FundHolder) _then;

/// Create a copy of FundHolder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? investorId = null,Object? name = null,Object? units = null,Object? sharePercent = null,Object? capital = null,Object? profit = null,Object? shareStartsNextPeriod = null,Object? nextSharePercent = null,}) {
  return _then(_self.copyWith(
investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as String,sharePercent: null == sharePercent ? _self.sharePercent : sharePercent // ignore: cast_nullable_to_non_nullable
as String,capital: null == capital ? _self.capital : capital // ignore: cast_nullable_to_non_nullable
as String,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as String,shareStartsNextPeriod: null == shareStartsNextPeriod ? _self.shareStartsNextPeriod : shareStartsNextPeriod // ignore: cast_nullable_to_non_nullable
as bool,nextSharePercent: null == nextSharePercent ? _self.nextSharePercent : nextSharePercent // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FundHolder].
extension FundHolderPatterns on FundHolder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundHolder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundHolder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundHolder value)  $default,){
final _that = this;
switch (_that) {
case _FundHolder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundHolder value)?  $default,){
final _that = this;
switch (_that) {
case _FundHolder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'investor_id')  int investorId,  String name,  String units, @JsonKey(name: 'share_percent')  String sharePercent,  String capital,  String profit, @JsonKey(name: 'share_starts_next_period')  bool shareStartsNextPeriod, @JsonKey(name: 'next_share_percent')  String nextSharePercent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundHolder() when $default != null:
return $default(_that.investorId,_that.name,_that.units,_that.sharePercent,_that.capital,_that.profit,_that.shareStartsNextPeriod,_that.nextSharePercent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'investor_id')  int investorId,  String name,  String units, @JsonKey(name: 'share_percent')  String sharePercent,  String capital,  String profit, @JsonKey(name: 'share_starts_next_period')  bool shareStartsNextPeriod, @JsonKey(name: 'next_share_percent')  String nextSharePercent)  $default,) {final _that = this;
switch (_that) {
case _FundHolder():
return $default(_that.investorId,_that.name,_that.units,_that.sharePercent,_that.capital,_that.profit,_that.shareStartsNextPeriod,_that.nextSharePercent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'investor_id')  int investorId,  String name,  String units, @JsonKey(name: 'share_percent')  String sharePercent,  String capital,  String profit, @JsonKey(name: 'share_starts_next_period')  bool shareStartsNextPeriod, @JsonKey(name: 'next_share_percent')  String nextSharePercent)?  $default,) {final _that = this;
switch (_that) {
case _FundHolder() when $default != null:
return $default(_that.investorId,_that.name,_that.units,_that.sharePercent,_that.capital,_that.profit,_that.shareStartsNextPeriod,_that.nextSharePercent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundHolder implements FundHolder {
  const _FundHolder({@JsonKey(name: 'investor_id') required this.investorId, required this.name, required this.units, @JsonKey(name: 'share_percent') required this.sharePercent, required this.capital, required this.profit, @JsonKey(name: 'share_starts_next_period') this.shareStartsNextPeriod = false, @JsonKey(name: 'next_share_percent') this.nextSharePercent = '0.000000'});
  factory _FundHolder.fromJson(Map<String, dynamic> json) => _$FundHolderFromJson(json);

@override@JsonKey(name: 'investor_id') final  int investorId;
@override final  String name;
@override final  String units;
@override@JsonKey(name: 'share_percent') final  String sharePercent;
@override final  String capital;
@override final  String profit;
/// **اكتتب في نافذة هذه الفترة، فنصيبُه منها صفر ومن التالية كامل.** وصفرٌ بجانب اسمِ رجلٍ
/// وضع مالَه أمس يُقرأ عطباً، فيقولها السطرُ بلفظها.
@override@JsonKey(name: 'share_starts_next_period') final  bool shareStartsNextPeriod;
/// **نسبتُه في الفترة التالية لو فُتحت الليلة** — بكلّ وحداته، ومنها ما ينتظر. تقديرٌ لا
/// عهد: إيداعٌ أو سحبٌ قبل بدئها يغيّره. والخادمُ يحسبه، لا الشاشة.
@override@JsonKey(name: 'next_share_percent') final  String nextSharePercent;

/// Create a copy of FundHolder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundHolderCopyWith<_FundHolder> get copyWith => __$FundHolderCopyWithImpl<_FundHolder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundHolderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundHolder&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.name, name) || other.name == name)&&(identical(other.units, units) || other.units == units)&&(identical(other.sharePercent, sharePercent) || other.sharePercent == sharePercent)&&(identical(other.capital, capital) || other.capital == capital)&&(identical(other.profit, profit) || other.profit == profit)&&(identical(other.shareStartsNextPeriod, shareStartsNextPeriod) || other.shareStartsNextPeriod == shareStartsNextPeriod)&&(identical(other.nextSharePercent, nextSharePercent) || other.nextSharePercent == nextSharePercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,investorId,name,units,sharePercent,capital,profit,shareStartsNextPeriod,nextSharePercent);

@override
String toString() {
  return 'FundHolder(investorId: $investorId, name: $name, units: $units, sharePercent: $sharePercent, capital: $capital, profit: $profit, shareStartsNextPeriod: $shareStartsNextPeriod, nextSharePercent: $nextSharePercent)';
}


}

/// @nodoc
abstract mixin class _$FundHolderCopyWith<$Res> implements $FundHolderCopyWith<$Res> {
  factory _$FundHolderCopyWith(_FundHolder value, $Res Function(_FundHolder) _then) = __$FundHolderCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'investor_id') int investorId, String name, String units,@JsonKey(name: 'share_percent') String sharePercent, String capital, String profit,@JsonKey(name: 'share_starts_next_period') bool shareStartsNextPeriod,@JsonKey(name: 'next_share_percent') String nextSharePercent
});




}
/// @nodoc
class __$FundHolderCopyWithImpl<$Res>
    implements _$FundHolderCopyWith<$Res> {
  __$FundHolderCopyWithImpl(this._self, this._then);

  final _FundHolder _self;
  final $Res Function(_FundHolder) _then;

/// Create a copy of FundHolder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? investorId = null,Object? name = null,Object? units = null,Object? sharePercent = null,Object? capital = null,Object? profit = null,Object? shareStartsNextPeriod = null,Object? nextSharePercent = null,}) {
  return _then(_FundHolder(
investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as String,sharePercent: null == sharePercent ? _self.sharePercent : sharePercent // ignore: cast_nullable_to_non_nullable
as String,capital: null == capital ? _self.capital : capital // ignore: cast_nullable_to_non_nullable
as String,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as String,shareStartsNextPeriod: null == shareStartsNextPeriod ? _self.shareStartsNextPeriod : shareStartsNextPeriod // ignore: cast_nullable_to_non_nullable
as bool,nextSharePercent: null == nextSharePercent ? _self.nextSharePercent : nextSharePercent // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$FundStanding {

 FundValuation get valuation;/// **بضاعة مشتراة لم تصل** — ثمنُها خرج من الخزينة ولم تصل الرفَّ بعد. بجانب القيمة لا
/// داخلها، قرارُ المالك 2026-09-24: «عرض لأن المال استُعمل بالفعل».
@JsonKey(name: 'goods_on_order') String get goodsOnOrder;/// `null` قبل أن تُفتح أوّلُ فترة — وهي حالةٌ تُقال صراحةً لا تُخترع لها فترةٌ وهمية.
 FundPeriod? get period;/// **سعرُ الوحدة اليوم** — ما يشتري به الداخلُ الجديد. يُحسب في الخادم ولا يُعاد حسابُه
/// هنا: تنفيذٌ ثانٍ للقاعدة هو الذي يخالفها يوم تتغيّر.
@JsonKey(name: 'unit_price') String get unitPrice;@JsonKey(name: 'units_outstanding') String get unitsOutstanding; List<FundHolder> get investors;/// **فتراتٌ «قيد الإغلاق»** — انتهت نافذتُها وبقيت لها طلبياتٌ لم تصل أو لم تُحصَّل. لا
/// تحبس أحداً، لكنها تبقى على اللوحة ما بقيت: «تبقى بلا حدّ، واللوحةُ تصرخ».
@JsonKey(name: 'waiting_periods') List<FundPeriod> get waitingPeriods;/// **سعرُ السادة الافتراضي** — يصل مع اللوحة لأن شاشةَ الشراء تقرأ اللوحةَ قبل أن تُملأ
/// حقولُها، وطلبٌ ثانٍ للإعدادات في اللحظة نفسها رحلةٌ زائدة لرقمٍ واحد. افتراضٌ يُعرض
/// ويُغيَّر، لا قاعدةٌ في حساب.
@JsonKey(name: 'default_plain_sale_price') String? get defaultPlainSalePrice;/// **سقفُ اشتراك كل مستثمر اليوم** — رصيدُ محفظته. يصل مع اللوحة لأن الورقة تحتاجه قبل أن
/// يُكتب رقم، ولأنه رصيدٌ لا يعرفه إلا الخادم: زميلٌ سجّل سحباً قبل ثانية.
 List<FundSubscriber> get subscribable;
/// Create a copy of FundStanding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundStandingCopyWith<FundStanding> get copyWith => _$FundStandingCopyWithImpl<FundStanding>(this as FundStanding, _$identity);

  /// Serializes this FundStanding to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundStanding&&(identical(other.valuation, valuation) || other.valuation == valuation)&&(identical(other.goodsOnOrder, goodsOnOrder) || other.goodsOnOrder == goodsOnOrder)&&(identical(other.period, period) || other.period == period)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.unitsOutstanding, unitsOutstanding) || other.unitsOutstanding == unitsOutstanding)&&const DeepCollectionEquality().equals(other.investors, investors)&&const DeepCollectionEquality().equals(other.waitingPeriods, waitingPeriods)&&(identical(other.defaultPlainSalePrice, defaultPlainSalePrice) || other.defaultPlainSalePrice == defaultPlainSalePrice)&&const DeepCollectionEquality().equals(other.subscribable, subscribable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,valuation,goodsOnOrder,period,unitPrice,unitsOutstanding,const DeepCollectionEquality().hash(investors),const DeepCollectionEquality().hash(waitingPeriods),defaultPlainSalePrice,const DeepCollectionEquality().hash(subscribable));

@override
String toString() {
  return 'FundStanding(valuation: $valuation, goodsOnOrder: $goodsOnOrder, period: $period, unitPrice: $unitPrice, unitsOutstanding: $unitsOutstanding, investors: $investors, waitingPeriods: $waitingPeriods, defaultPlainSalePrice: $defaultPlainSalePrice, subscribable: $subscribable)';
}


}

/// @nodoc
abstract mixin class $FundStandingCopyWith<$Res>  {
  factory $FundStandingCopyWith(FundStanding value, $Res Function(FundStanding) _then) = _$FundStandingCopyWithImpl;
@useResult
$Res call({
 FundValuation valuation,@JsonKey(name: 'goods_on_order') String goodsOnOrder, FundPeriod? period,@JsonKey(name: 'unit_price') String unitPrice,@JsonKey(name: 'units_outstanding') String unitsOutstanding, List<FundHolder> investors,@JsonKey(name: 'waiting_periods') List<FundPeriod> waitingPeriods,@JsonKey(name: 'default_plain_sale_price') String? defaultPlainSalePrice, List<FundSubscriber> subscribable
});


$FundValuationCopyWith<$Res> get valuation;$FundPeriodCopyWith<$Res>? get period;

}
/// @nodoc
class _$FundStandingCopyWithImpl<$Res>
    implements $FundStandingCopyWith<$Res> {
  _$FundStandingCopyWithImpl(this._self, this._then);

  final FundStanding _self;
  final $Res Function(FundStanding) _then;

/// Create a copy of FundStanding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? valuation = null,Object? goodsOnOrder = null,Object? period = freezed,Object? unitPrice = null,Object? unitsOutstanding = null,Object? investors = null,Object? waitingPeriods = null,Object? defaultPlainSalePrice = freezed,Object? subscribable = null,}) {
  return _then(_self.copyWith(
valuation: null == valuation ? _self.valuation : valuation // ignore: cast_nullable_to_non_nullable
as FundValuation,goodsOnOrder: null == goodsOnOrder ? _self.goodsOnOrder : goodsOnOrder // ignore: cast_nullable_to_non_nullable
as String,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as FundPeriod?,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,unitsOutstanding: null == unitsOutstanding ? _self.unitsOutstanding : unitsOutstanding // ignore: cast_nullable_to_non_nullable
as String,investors: null == investors ? _self.investors : investors // ignore: cast_nullable_to_non_nullable
as List<FundHolder>,waitingPeriods: null == waitingPeriods ? _self.waitingPeriods : waitingPeriods // ignore: cast_nullable_to_non_nullable
as List<FundPeriod>,defaultPlainSalePrice: freezed == defaultPlainSalePrice ? _self.defaultPlainSalePrice : defaultPlainSalePrice // ignore: cast_nullable_to_non_nullable
as String?,subscribable: null == subscribable ? _self.subscribable : subscribable // ignore: cast_nullable_to_non_nullable
as List<FundSubscriber>,
  ));
}
/// Create a copy of FundStanding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundValuationCopyWith<$Res> get valuation {
  
  return $FundValuationCopyWith<$Res>(_self.valuation, (value) {
    return _then(_self.copyWith(valuation: value));
  });
}/// Create a copy of FundStanding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundPeriodCopyWith<$Res>? get period {
    if (_self.period == null) {
    return null;
  }

  return $FundPeriodCopyWith<$Res>(_self.period!, (value) {
    return _then(_self.copyWith(period: value));
  });
}
}


/// Adds pattern-matching-related methods to [FundStanding].
extension FundStandingPatterns on FundStanding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundStanding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundStanding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundStanding value)  $default,){
final _that = this;
switch (_that) {
case _FundStanding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundStanding value)?  $default,){
final _that = this;
switch (_that) {
case _FundStanding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FundValuation valuation, @JsonKey(name: 'goods_on_order')  String goodsOnOrder,  FundPeriod? period, @JsonKey(name: 'unit_price')  String unitPrice, @JsonKey(name: 'units_outstanding')  String unitsOutstanding,  List<FundHolder> investors, @JsonKey(name: 'waiting_periods')  List<FundPeriod> waitingPeriods, @JsonKey(name: 'default_plain_sale_price')  String? defaultPlainSalePrice,  List<FundSubscriber> subscribable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundStanding() when $default != null:
return $default(_that.valuation,_that.goodsOnOrder,_that.period,_that.unitPrice,_that.unitsOutstanding,_that.investors,_that.waitingPeriods,_that.defaultPlainSalePrice,_that.subscribable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FundValuation valuation, @JsonKey(name: 'goods_on_order')  String goodsOnOrder,  FundPeriod? period, @JsonKey(name: 'unit_price')  String unitPrice, @JsonKey(name: 'units_outstanding')  String unitsOutstanding,  List<FundHolder> investors, @JsonKey(name: 'waiting_periods')  List<FundPeriod> waitingPeriods, @JsonKey(name: 'default_plain_sale_price')  String? defaultPlainSalePrice,  List<FundSubscriber> subscribable)  $default,) {final _that = this;
switch (_that) {
case _FundStanding():
return $default(_that.valuation,_that.goodsOnOrder,_that.period,_that.unitPrice,_that.unitsOutstanding,_that.investors,_that.waitingPeriods,_that.defaultPlainSalePrice,_that.subscribable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FundValuation valuation, @JsonKey(name: 'goods_on_order')  String goodsOnOrder,  FundPeriod? period, @JsonKey(name: 'unit_price')  String unitPrice, @JsonKey(name: 'units_outstanding')  String unitsOutstanding,  List<FundHolder> investors, @JsonKey(name: 'waiting_periods')  List<FundPeriod> waitingPeriods, @JsonKey(name: 'default_plain_sale_price')  String? defaultPlainSalePrice,  List<FundSubscriber> subscribable)?  $default,) {final _that = this;
switch (_that) {
case _FundStanding() when $default != null:
return $default(_that.valuation,_that.goodsOnOrder,_that.period,_that.unitPrice,_that.unitsOutstanding,_that.investors,_that.waitingPeriods,_that.defaultPlainSalePrice,_that.subscribable);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundStanding implements FundStanding {
  const _FundStanding({required this.valuation, @JsonKey(name: 'goods_on_order') this.goodsOnOrder = '0.00', this.period, @JsonKey(name: 'unit_price') this.unitPrice = '1.000000', @JsonKey(name: 'units_outstanding') this.unitsOutstanding = '0.000000', final  List<FundHolder> investors = const <FundHolder>[], @JsonKey(name: 'waiting_periods') final  List<FundPeriod> waitingPeriods = const <FundPeriod>[], @JsonKey(name: 'default_plain_sale_price') this.defaultPlainSalePrice, final  List<FundSubscriber> subscribable = const <FundSubscriber>[]}): _investors = investors,_waitingPeriods = waitingPeriods,_subscribable = subscribable;
  factory _FundStanding.fromJson(Map<String, dynamic> json) => _$FundStandingFromJson(json);

@override final  FundValuation valuation;
/// **بضاعة مشتراة لم تصل** — ثمنُها خرج من الخزينة ولم تصل الرفَّ بعد. بجانب القيمة لا
/// داخلها، قرارُ المالك 2026-09-24: «عرض لأن المال استُعمل بالفعل».
@override@JsonKey(name: 'goods_on_order') final  String goodsOnOrder;
/// `null` قبل أن تُفتح أوّلُ فترة — وهي حالةٌ تُقال صراحةً لا تُخترع لها فترةٌ وهمية.
@override final  FundPeriod? period;
/// **سعرُ الوحدة اليوم** — ما يشتري به الداخلُ الجديد. يُحسب في الخادم ولا يُعاد حسابُه
/// هنا: تنفيذٌ ثانٍ للقاعدة هو الذي يخالفها يوم تتغيّر.
@override@JsonKey(name: 'unit_price') final  String unitPrice;
@override@JsonKey(name: 'units_outstanding') final  String unitsOutstanding;
 final  List<FundHolder> _investors;
@override@JsonKey() List<FundHolder> get investors {
  if (_investors is EqualUnmodifiableListView) return _investors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_investors);
}

/// **فتراتٌ «قيد الإغلاق»** — انتهت نافذتُها وبقيت لها طلبياتٌ لم تصل أو لم تُحصَّل. لا
/// تحبس أحداً، لكنها تبقى على اللوحة ما بقيت: «تبقى بلا حدّ، واللوحةُ تصرخ».
 final  List<FundPeriod> _waitingPeriods;
/// **فتراتٌ «قيد الإغلاق»** — انتهت نافذتُها وبقيت لها طلبياتٌ لم تصل أو لم تُحصَّل. لا
/// تحبس أحداً، لكنها تبقى على اللوحة ما بقيت: «تبقى بلا حدّ، واللوحةُ تصرخ».
@override@JsonKey(name: 'waiting_periods') List<FundPeriod> get waitingPeriods {
  if (_waitingPeriods is EqualUnmodifiableListView) return _waitingPeriods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_waitingPeriods);
}

/// **سعرُ السادة الافتراضي** — يصل مع اللوحة لأن شاشةَ الشراء تقرأ اللوحةَ قبل أن تُملأ
/// حقولُها، وطلبٌ ثانٍ للإعدادات في اللحظة نفسها رحلةٌ زائدة لرقمٍ واحد. افتراضٌ يُعرض
/// ويُغيَّر، لا قاعدةٌ في حساب.
@override@JsonKey(name: 'default_plain_sale_price') final  String? defaultPlainSalePrice;
/// **سقفُ اشتراك كل مستثمر اليوم** — رصيدُ محفظته. يصل مع اللوحة لأن الورقة تحتاجه قبل أن
/// يُكتب رقم، ولأنه رصيدٌ لا يعرفه إلا الخادم: زميلٌ سجّل سحباً قبل ثانية.
 final  List<FundSubscriber> _subscribable;
/// **سقفُ اشتراك كل مستثمر اليوم** — رصيدُ محفظته. يصل مع اللوحة لأن الورقة تحتاجه قبل أن
/// يُكتب رقم، ولأنه رصيدٌ لا يعرفه إلا الخادم: زميلٌ سجّل سحباً قبل ثانية.
@override@JsonKey() List<FundSubscriber> get subscribable {
  if (_subscribable is EqualUnmodifiableListView) return _subscribable;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subscribable);
}


/// Create a copy of FundStanding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundStandingCopyWith<_FundStanding> get copyWith => __$FundStandingCopyWithImpl<_FundStanding>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundStandingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundStanding&&(identical(other.valuation, valuation) || other.valuation == valuation)&&(identical(other.goodsOnOrder, goodsOnOrder) || other.goodsOnOrder == goodsOnOrder)&&(identical(other.period, period) || other.period == period)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.unitsOutstanding, unitsOutstanding) || other.unitsOutstanding == unitsOutstanding)&&const DeepCollectionEquality().equals(other._investors, _investors)&&const DeepCollectionEquality().equals(other._waitingPeriods, _waitingPeriods)&&(identical(other.defaultPlainSalePrice, defaultPlainSalePrice) || other.defaultPlainSalePrice == defaultPlainSalePrice)&&const DeepCollectionEquality().equals(other._subscribable, _subscribable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,valuation,goodsOnOrder,period,unitPrice,unitsOutstanding,const DeepCollectionEquality().hash(_investors),const DeepCollectionEquality().hash(_waitingPeriods),defaultPlainSalePrice,const DeepCollectionEquality().hash(_subscribable));

@override
String toString() {
  return 'FundStanding(valuation: $valuation, goodsOnOrder: $goodsOnOrder, period: $period, unitPrice: $unitPrice, unitsOutstanding: $unitsOutstanding, investors: $investors, waitingPeriods: $waitingPeriods, defaultPlainSalePrice: $defaultPlainSalePrice, subscribable: $subscribable)';
}


}

/// @nodoc
abstract mixin class _$FundStandingCopyWith<$Res> implements $FundStandingCopyWith<$Res> {
  factory _$FundStandingCopyWith(_FundStanding value, $Res Function(_FundStanding) _then) = __$FundStandingCopyWithImpl;
@override @useResult
$Res call({
 FundValuation valuation,@JsonKey(name: 'goods_on_order') String goodsOnOrder, FundPeriod? period,@JsonKey(name: 'unit_price') String unitPrice,@JsonKey(name: 'units_outstanding') String unitsOutstanding, List<FundHolder> investors,@JsonKey(name: 'waiting_periods') List<FundPeriod> waitingPeriods,@JsonKey(name: 'default_plain_sale_price') String? defaultPlainSalePrice, List<FundSubscriber> subscribable
});


@override $FundValuationCopyWith<$Res> get valuation;@override $FundPeriodCopyWith<$Res>? get period;

}
/// @nodoc
class __$FundStandingCopyWithImpl<$Res>
    implements _$FundStandingCopyWith<$Res> {
  __$FundStandingCopyWithImpl(this._self, this._then);

  final _FundStanding _self;
  final $Res Function(_FundStanding) _then;

/// Create a copy of FundStanding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? valuation = null,Object? goodsOnOrder = null,Object? period = freezed,Object? unitPrice = null,Object? unitsOutstanding = null,Object? investors = null,Object? waitingPeriods = null,Object? defaultPlainSalePrice = freezed,Object? subscribable = null,}) {
  return _then(_FundStanding(
valuation: null == valuation ? _self.valuation : valuation // ignore: cast_nullable_to_non_nullable
as FundValuation,goodsOnOrder: null == goodsOnOrder ? _self.goodsOnOrder : goodsOnOrder // ignore: cast_nullable_to_non_nullable
as String,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as FundPeriod?,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,unitsOutstanding: null == unitsOutstanding ? _self.unitsOutstanding : unitsOutstanding // ignore: cast_nullable_to_non_nullable
as String,investors: null == investors ? _self._investors : investors // ignore: cast_nullable_to_non_nullable
as List<FundHolder>,waitingPeriods: null == waitingPeriods ? _self._waitingPeriods : waitingPeriods // ignore: cast_nullable_to_non_nullable
as List<FundPeriod>,defaultPlainSalePrice: freezed == defaultPlainSalePrice ? _self.defaultPlainSalePrice : defaultPlainSalePrice // ignore: cast_nullable_to_non_nullable
as String?,subscribable: null == subscribable ? _self._subscribable : subscribable // ignore: cast_nullable_to_non_nullable
as List<FundSubscriber>,
  ));
}

/// Create a copy of FundStanding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundValuationCopyWith<$Res> get valuation {
  
  return $FundValuationCopyWith<$Res>(_self.valuation, (value) {
    return _then(_self.copyWith(valuation: value));
  });
}/// Create a copy of FundStanding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundPeriodCopyWith<$Res>? get period {
    if (_self.period == null) {
    return null;
  }

  return $FundPeriodCopyWith<$Res>(_self.period!, (value) {
    return _then(_self.copyWith(period: value));
  });
}
}


/// @nodoc
mixin _$FundSubscriber {

@JsonKey(name: 'investor_id') int get investorId; String get name;/// رأسُ ماله الحرّ — سقفُ الاشتراك.
@JsonKey(name: 'wallet_capital') String get walletCapital;/// أرباحُه المتاحة — تصير رأسَ مالٍ بحركةٍ واحدة من شاشة محفظته، ثم تُشترك.
@JsonKey(name: 'wallet_profit') String get walletProfit;
/// Create a copy of FundSubscriber
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundSubscriberCopyWith<FundSubscriber> get copyWith => _$FundSubscriberCopyWithImpl<FundSubscriber>(this as FundSubscriber, _$identity);

  /// Serializes this FundSubscriber to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundSubscriber&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.name, name) || other.name == name)&&(identical(other.walletCapital, walletCapital) || other.walletCapital == walletCapital)&&(identical(other.walletProfit, walletProfit) || other.walletProfit == walletProfit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,investorId,name,walletCapital,walletProfit);

@override
String toString() {
  return 'FundSubscriber(investorId: $investorId, name: $name, walletCapital: $walletCapital, walletProfit: $walletProfit)';
}


}

/// @nodoc
abstract mixin class $FundSubscriberCopyWith<$Res>  {
  factory $FundSubscriberCopyWith(FundSubscriber value, $Res Function(FundSubscriber) _then) = _$FundSubscriberCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'investor_id') int investorId, String name,@JsonKey(name: 'wallet_capital') String walletCapital,@JsonKey(name: 'wallet_profit') String walletProfit
});




}
/// @nodoc
class _$FundSubscriberCopyWithImpl<$Res>
    implements $FundSubscriberCopyWith<$Res> {
  _$FundSubscriberCopyWithImpl(this._self, this._then);

  final FundSubscriber _self;
  final $Res Function(FundSubscriber) _then;

/// Create a copy of FundSubscriber
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? investorId = null,Object? name = null,Object? walletCapital = null,Object? walletProfit = null,}) {
  return _then(_self.copyWith(
investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,walletCapital: null == walletCapital ? _self.walletCapital : walletCapital // ignore: cast_nullable_to_non_nullable
as String,walletProfit: null == walletProfit ? _self.walletProfit : walletProfit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FundSubscriber].
extension FundSubscriberPatterns on FundSubscriber {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundSubscriber value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundSubscriber() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundSubscriber value)  $default,){
final _that = this;
switch (_that) {
case _FundSubscriber():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundSubscriber value)?  $default,){
final _that = this;
switch (_that) {
case _FundSubscriber() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'investor_id')  int investorId,  String name, @JsonKey(name: 'wallet_capital')  String walletCapital, @JsonKey(name: 'wallet_profit')  String walletProfit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundSubscriber() when $default != null:
return $default(_that.investorId,_that.name,_that.walletCapital,_that.walletProfit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'investor_id')  int investorId,  String name, @JsonKey(name: 'wallet_capital')  String walletCapital, @JsonKey(name: 'wallet_profit')  String walletProfit)  $default,) {final _that = this;
switch (_that) {
case _FundSubscriber():
return $default(_that.investorId,_that.name,_that.walletCapital,_that.walletProfit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'investor_id')  int investorId,  String name, @JsonKey(name: 'wallet_capital')  String walletCapital, @JsonKey(name: 'wallet_profit')  String walletProfit)?  $default,) {final _that = this;
switch (_that) {
case _FundSubscriber() when $default != null:
return $default(_that.investorId,_that.name,_that.walletCapital,_that.walletProfit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundSubscriber implements FundSubscriber {
  const _FundSubscriber({@JsonKey(name: 'investor_id') required this.investorId, required this.name, @JsonKey(name: 'wallet_capital') required this.walletCapital, @JsonKey(name: 'wallet_profit') required this.walletProfit});
  factory _FundSubscriber.fromJson(Map<String, dynamic> json) => _$FundSubscriberFromJson(json);

@override@JsonKey(name: 'investor_id') final  int investorId;
@override final  String name;
/// رأسُ ماله الحرّ — سقفُ الاشتراك.
@override@JsonKey(name: 'wallet_capital') final  String walletCapital;
/// أرباحُه المتاحة — تصير رأسَ مالٍ بحركةٍ واحدة من شاشة محفظته، ثم تُشترك.
@override@JsonKey(name: 'wallet_profit') final  String walletProfit;

/// Create a copy of FundSubscriber
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundSubscriberCopyWith<_FundSubscriber> get copyWith => __$FundSubscriberCopyWithImpl<_FundSubscriber>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundSubscriberToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundSubscriber&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.name, name) || other.name == name)&&(identical(other.walletCapital, walletCapital) || other.walletCapital == walletCapital)&&(identical(other.walletProfit, walletProfit) || other.walletProfit == walletProfit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,investorId,name,walletCapital,walletProfit);

@override
String toString() {
  return 'FundSubscriber(investorId: $investorId, name: $name, walletCapital: $walletCapital, walletProfit: $walletProfit)';
}


}

/// @nodoc
abstract mixin class _$FundSubscriberCopyWith<$Res> implements $FundSubscriberCopyWith<$Res> {
  factory _$FundSubscriberCopyWith(_FundSubscriber value, $Res Function(_FundSubscriber) _then) = __$FundSubscriberCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'investor_id') int investorId, String name,@JsonKey(name: 'wallet_capital') String walletCapital,@JsonKey(name: 'wallet_profit') String walletProfit
});




}
/// @nodoc
class __$FundSubscriberCopyWithImpl<$Res>
    implements _$FundSubscriberCopyWith<$Res> {
  __$FundSubscriberCopyWithImpl(this._self, this._then);

  final _FundSubscriber _self;
  final $Res Function(_FundSubscriber) _then;

/// Create a copy of FundSubscriber
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? investorId = null,Object? name = null,Object? walletCapital = null,Object? walletProfit = null,}) {
  return _then(_FundSubscriber(
investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,walletCapital: null == walletCapital ? _self.walletCapital : walletCapital // ignore: cast_nullable_to_non_nullable
as String,walletProfit: null == walletProfit ? _self.walletProfit : walletProfit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DepositReceipt {

 String get units;@JsonKey(name: 'unit_price') String get unitPrice;@JsonKey(name: 'locked_until') String? get lockedUntil;
/// Create a copy of DepositReceipt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DepositReceiptCopyWith<DepositReceipt> get copyWith => _$DepositReceiptCopyWithImpl<DepositReceipt>(this as DepositReceipt, _$identity);

  /// Serializes this DepositReceipt to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DepositReceipt&&(identical(other.units, units) || other.units == units)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.lockedUntil, lockedUntil) || other.lockedUntil == lockedUntil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,units,unitPrice,lockedUntil);

@override
String toString() {
  return 'DepositReceipt(units: $units, unitPrice: $unitPrice, lockedUntil: $lockedUntil)';
}


}

/// @nodoc
abstract mixin class $DepositReceiptCopyWith<$Res>  {
  factory $DepositReceiptCopyWith(DepositReceipt value, $Res Function(DepositReceipt) _then) = _$DepositReceiptCopyWithImpl;
@useResult
$Res call({
 String units,@JsonKey(name: 'unit_price') String unitPrice,@JsonKey(name: 'locked_until') String? lockedUntil
});




}
/// @nodoc
class _$DepositReceiptCopyWithImpl<$Res>
    implements $DepositReceiptCopyWith<$Res> {
  _$DepositReceiptCopyWithImpl(this._self, this._then);

  final DepositReceipt _self;
  final $Res Function(DepositReceipt) _then;

/// Create a copy of DepositReceipt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? units = null,Object? unitPrice = null,Object? lockedUntil = freezed,}) {
  return _then(_self.copyWith(
units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,lockedUntil: freezed == lockedUntil ? _self.lockedUntil : lockedUntil // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DepositReceipt].
extension DepositReceiptPatterns on DepositReceipt {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DepositReceipt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DepositReceipt() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DepositReceipt value)  $default,){
final _that = this;
switch (_that) {
case _DepositReceipt():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DepositReceipt value)?  $default,){
final _that = this;
switch (_that) {
case _DepositReceipt() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String units, @JsonKey(name: 'unit_price')  String unitPrice, @JsonKey(name: 'locked_until')  String? lockedUntil)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DepositReceipt() when $default != null:
return $default(_that.units,_that.unitPrice,_that.lockedUntil);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String units, @JsonKey(name: 'unit_price')  String unitPrice, @JsonKey(name: 'locked_until')  String? lockedUntil)  $default,) {final _that = this;
switch (_that) {
case _DepositReceipt():
return $default(_that.units,_that.unitPrice,_that.lockedUntil);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String units, @JsonKey(name: 'unit_price')  String unitPrice, @JsonKey(name: 'locked_until')  String? lockedUntil)?  $default,) {final _that = this;
switch (_that) {
case _DepositReceipt() when $default != null:
return $default(_that.units,_that.unitPrice,_that.lockedUntil);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DepositReceipt implements DepositReceipt {
  const _DepositReceipt({required this.units, @JsonKey(name: 'unit_price') required this.unitPrice, @JsonKey(name: 'locked_until') this.lockedUntil});
  factory _DepositReceipt.fromJson(Map<String, dynamic> json) => _$DepositReceiptFromJson(json);

@override final  String units;
@override@JsonKey(name: 'unit_price') final  String unitPrice;
@override@JsonKey(name: 'locked_until') final  String? lockedUntil;

/// Create a copy of DepositReceipt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DepositReceiptCopyWith<_DepositReceipt> get copyWith => __$DepositReceiptCopyWithImpl<_DepositReceipt>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DepositReceiptToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DepositReceipt&&(identical(other.units, units) || other.units == units)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.lockedUntil, lockedUntil) || other.lockedUntil == lockedUntil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,units,unitPrice,lockedUntil);

@override
String toString() {
  return 'DepositReceipt(units: $units, unitPrice: $unitPrice, lockedUntil: $lockedUntil)';
}


}

/// @nodoc
abstract mixin class _$DepositReceiptCopyWith<$Res> implements $DepositReceiptCopyWith<$Res> {
  factory _$DepositReceiptCopyWith(_DepositReceipt value, $Res Function(_DepositReceipt) _then) = __$DepositReceiptCopyWithImpl;
@override @useResult
$Res call({
 String units,@JsonKey(name: 'unit_price') String unitPrice,@JsonKey(name: 'locked_until') String? lockedUntil
});




}
/// @nodoc
class __$DepositReceiptCopyWithImpl<$Res>
    implements _$DepositReceiptCopyWith<$Res> {
  __$DepositReceiptCopyWithImpl(this._self, this._then);

  final _DepositReceipt _self;
  final $Res Function(_DepositReceipt) _then;

/// Create a copy of DepositReceipt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? units = null,Object? unitPrice = null,Object? lockedUntil = freezed,}) {
  return _then(_DepositReceipt(
units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,lockedUntil: freezed == lockedUntil ? _self.lockedUntil : lockedUntil // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
