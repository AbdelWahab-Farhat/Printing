// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_investor_share.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OrderInvestorShare {

@JsonKey(name: 'deal_id') int get dealId;@JsonKey(name: 'deal_code') String get dealCode; String get kind;@JsonKey(name: 'kind_label') String get kindLabel;/// What the press paid for the goods — `plain_sale` only, null on the other road.
@JsonKey(name: 'goods_amount') String? get goodsAmount;/// What the deal made on this order by this road: the margin, or its slice of the profit.
 String get profit;/// What the deal's terms give the partners of [profit] — and, once [isPaid], what the ledger
/// holds for them.
@JsonKey(name: 'investors_share') String get investorsShare;/// The rest of [profit]: the company's, whether as the second partner in the goods or as the
/// shop that did the work.
@JsonKey(name: 'company_share') String get companyShare;@JsonKey(name: 'is_paid') bool get isPaid;@JsonKey(name: 'paid_amount') String? get paidAmount;@JsonKey(name: 'paid_at') DateTime? get paidAt;
/// Create a copy of OrderInvestorShare
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderInvestorShareCopyWith<OrderInvestorShare> get copyWith => _$OrderInvestorShareCopyWithImpl<OrderInvestorShare>(this as OrderInvestorShare, _$identity);

  /// Serializes this OrderInvestorShare to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderInvestorShare&&(identical(other.dealId, dealId) || other.dealId == dealId)&&(identical(other.dealCode, dealCode) || other.dealCode == dealCode)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.kindLabel, kindLabel) || other.kindLabel == kindLabel)&&(identical(other.goodsAmount, goodsAmount) || other.goodsAmount == goodsAmount)&&(identical(other.profit, profit) || other.profit == profit)&&(identical(other.investorsShare, investorsShare) || other.investorsShare == investorsShare)&&(identical(other.companyShare, companyShare) || other.companyShare == companyShare)&&(identical(other.isPaid, isPaid) || other.isPaid == isPaid)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dealId,dealCode,kind,kindLabel,goodsAmount,profit,investorsShare,companyShare,isPaid,paidAmount,paidAt);

@override
String toString() {
  return 'OrderInvestorShare(dealId: $dealId, dealCode: $dealCode, kind: $kind, kindLabel: $kindLabel, goodsAmount: $goodsAmount, profit: $profit, investorsShare: $investorsShare, companyShare: $companyShare, isPaid: $isPaid, paidAmount: $paidAmount, paidAt: $paidAt)';
}


}

/// @nodoc
abstract mixin class $OrderInvestorShareCopyWith<$Res>  {
  factory $OrderInvestorShareCopyWith(OrderInvestorShare value, $Res Function(OrderInvestorShare) _then) = _$OrderInvestorShareCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'deal_id') int dealId,@JsonKey(name: 'deal_code') String dealCode, String kind,@JsonKey(name: 'kind_label') String kindLabel,@JsonKey(name: 'goods_amount') String? goodsAmount, String profit,@JsonKey(name: 'investors_share') String investorsShare,@JsonKey(name: 'company_share') String companyShare,@JsonKey(name: 'is_paid') bool isPaid,@JsonKey(name: 'paid_amount') String? paidAmount,@JsonKey(name: 'paid_at') DateTime? paidAt
});




}
/// @nodoc
class _$OrderInvestorShareCopyWithImpl<$Res>
    implements $OrderInvestorShareCopyWith<$Res> {
  _$OrderInvestorShareCopyWithImpl(this._self, this._then);

  final OrderInvestorShare _self;
  final $Res Function(OrderInvestorShare) _then;

/// Create a copy of OrderInvestorShare
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dealId = null,Object? dealCode = null,Object? kind = null,Object? kindLabel = null,Object? goodsAmount = freezed,Object? profit = null,Object? investorsShare = null,Object? companyShare = null,Object? isPaid = null,Object? paidAmount = freezed,Object? paidAt = freezed,}) {
  return _then(_self.copyWith(
dealId: null == dealId ? _self.dealId : dealId // ignore: cast_nullable_to_non_nullable
as int,dealCode: null == dealCode ? _self.dealCode : dealCode // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,kindLabel: null == kindLabel ? _self.kindLabel : kindLabel // ignore: cast_nullable_to_non_nullable
as String,goodsAmount: freezed == goodsAmount ? _self.goodsAmount : goodsAmount // ignore: cast_nullable_to_non_nullable
as String?,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as String,investorsShare: null == investorsShare ? _self.investorsShare : investorsShare // ignore: cast_nullable_to_non_nullable
as String,companyShare: null == companyShare ? _self.companyShare : companyShare // ignore: cast_nullable_to_non_nullable
as String,isPaid: null == isPaid ? _self.isPaid : isPaid // ignore: cast_nullable_to_non_nullable
as bool,paidAmount: freezed == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as String?,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderInvestorShare].
extension OrderInvestorSharePatterns on OrderInvestorShare {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderInvestorShare value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderInvestorShare() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderInvestorShare value)  $default,){
final _that = this;
switch (_that) {
case _OrderInvestorShare():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderInvestorShare value)?  $default,){
final _that = this;
switch (_that) {
case _OrderInvestorShare() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'deal_id')  int dealId, @JsonKey(name: 'deal_code')  String dealCode,  String kind, @JsonKey(name: 'kind_label')  String kindLabel, @JsonKey(name: 'goods_amount')  String? goodsAmount,  String profit, @JsonKey(name: 'investors_share')  String investorsShare, @JsonKey(name: 'company_share')  String companyShare, @JsonKey(name: 'is_paid')  bool isPaid, @JsonKey(name: 'paid_amount')  String? paidAmount, @JsonKey(name: 'paid_at')  DateTime? paidAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderInvestorShare() when $default != null:
return $default(_that.dealId,_that.dealCode,_that.kind,_that.kindLabel,_that.goodsAmount,_that.profit,_that.investorsShare,_that.companyShare,_that.isPaid,_that.paidAmount,_that.paidAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'deal_id')  int dealId, @JsonKey(name: 'deal_code')  String dealCode,  String kind, @JsonKey(name: 'kind_label')  String kindLabel, @JsonKey(name: 'goods_amount')  String? goodsAmount,  String profit, @JsonKey(name: 'investors_share')  String investorsShare, @JsonKey(name: 'company_share')  String companyShare, @JsonKey(name: 'is_paid')  bool isPaid, @JsonKey(name: 'paid_amount')  String? paidAmount, @JsonKey(name: 'paid_at')  DateTime? paidAt)  $default,) {final _that = this;
switch (_that) {
case _OrderInvestorShare():
return $default(_that.dealId,_that.dealCode,_that.kind,_that.kindLabel,_that.goodsAmount,_that.profit,_that.investorsShare,_that.companyShare,_that.isPaid,_that.paidAmount,_that.paidAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'deal_id')  int dealId, @JsonKey(name: 'deal_code')  String dealCode,  String kind, @JsonKey(name: 'kind_label')  String kindLabel, @JsonKey(name: 'goods_amount')  String? goodsAmount,  String profit, @JsonKey(name: 'investors_share')  String investorsShare, @JsonKey(name: 'company_share')  String companyShare, @JsonKey(name: 'is_paid')  bool isPaid, @JsonKey(name: 'paid_amount')  String? paidAmount, @JsonKey(name: 'paid_at')  DateTime? paidAt)?  $default,) {final _that = this;
switch (_that) {
case _OrderInvestorShare() when $default != null:
return $default(_that.dealId,_that.dealCode,_that.kind,_that.kindLabel,_that.goodsAmount,_that.profit,_that.investorsShare,_that.companyShare,_that.isPaid,_that.paidAmount,_that.paidAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderInvestorShare implements OrderInvestorShare {
  const _OrderInvestorShare({@JsonKey(name: 'deal_id') required this.dealId, @JsonKey(name: 'deal_code') required this.dealCode, required this.kind, @JsonKey(name: 'kind_label') required this.kindLabel, @JsonKey(name: 'goods_amount') this.goodsAmount, required this.profit, @JsonKey(name: 'investors_share') required this.investorsShare, @JsonKey(name: 'company_share') required this.companyShare, @JsonKey(name: 'is_paid') this.isPaid = false, @JsonKey(name: 'paid_amount') this.paidAmount, @JsonKey(name: 'paid_at') this.paidAt});
  factory _OrderInvestorShare.fromJson(Map<String, dynamic> json) => _$OrderInvestorShareFromJson(json);

@override@JsonKey(name: 'deal_id') final  int dealId;
@override@JsonKey(name: 'deal_code') final  String dealCode;
@override final  String kind;
@override@JsonKey(name: 'kind_label') final  String kindLabel;
/// What the press paid for the goods — `plain_sale` only, null on the other road.
@override@JsonKey(name: 'goods_amount') final  String? goodsAmount;
/// What the deal made on this order by this road: the margin, or its slice of the profit.
@override final  String profit;
/// What the deal's terms give the partners of [profit] — and, once [isPaid], what the ledger
/// holds for them.
@override@JsonKey(name: 'investors_share') final  String investorsShare;
/// The rest of [profit]: the company's, whether as the second partner in the goods or as the
/// shop that did the work.
@override@JsonKey(name: 'company_share') final  String companyShare;
@override@JsonKey(name: 'is_paid') final  bool isPaid;
@override@JsonKey(name: 'paid_amount') final  String? paidAmount;
@override@JsonKey(name: 'paid_at') final  DateTime? paidAt;

/// Create a copy of OrderInvestorShare
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderInvestorShareCopyWith<_OrderInvestorShare> get copyWith => __$OrderInvestorShareCopyWithImpl<_OrderInvestorShare>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderInvestorShareToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderInvestorShare&&(identical(other.dealId, dealId) || other.dealId == dealId)&&(identical(other.dealCode, dealCode) || other.dealCode == dealCode)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.kindLabel, kindLabel) || other.kindLabel == kindLabel)&&(identical(other.goodsAmount, goodsAmount) || other.goodsAmount == goodsAmount)&&(identical(other.profit, profit) || other.profit == profit)&&(identical(other.investorsShare, investorsShare) || other.investorsShare == investorsShare)&&(identical(other.companyShare, companyShare) || other.companyShare == companyShare)&&(identical(other.isPaid, isPaid) || other.isPaid == isPaid)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dealId,dealCode,kind,kindLabel,goodsAmount,profit,investorsShare,companyShare,isPaid,paidAmount,paidAt);

@override
String toString() {
  return 'OrderInvestorShare(dealId: $dealId, dealCode: $dealCode, kind: $kind, kindLabel: $kindLabel, goodsAmount: $goodsAmount, profit: $profit, investorsShare: $investorsShare, companyShare: $companyShare, isPaid: $isPaid, paidAmount: $paidAmount, paidAt: $paidAt)';
}


}

/// @nodoc
abstract mixin class _$OrderInvestorShareCopyWith<$Res> implements $OrderInvestorShareCopyWith<$Res> {
  factory _$OrderInvestorShareCopyWith(_OrderInvestorShare value, $Res Function(_OrderInvestorShare) _then) = __$OrderInvestorShareCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'deal_id') int dealId,@JsonKey(name: 'deal_code') String dealCode, String kind,@JsonKey(name: 'kind_label') String kindLabel,@JsonKey(name: 'goods_amount') String? goodsAmount, String profit,@JsonKey(name: 'investors_share') String investorsShare,@JsonKey(name: 'company_share') String companyShare,@JsonKey(name: 'is_paid') bool isPaid,@JsonKey(name: 'paid_amount') String? paidAmount,@JsonKey(name: 'paid_at') DateTime? paidAt
});




}
/// @nodoc
class __$OrderInvestorShareCopyWithImpl<$Res>
    implements _$OrderInvestorShareCopyWith<$Res> {
  __$OrderInvestorShareCopyWithImpl(this._self, this._then);

  final _OrderInvestorShare _self;
  final $Res Function(_OrderInvestorShare) _then;

/// Create a copy of OrderInvestorShare
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dealId = null,Object? dealCode = null,Object? kind = null,Object? kindLabel = null,Object? goodsAmount = freezed,Object? profit = null,Object? investorsShare = null,Object? companyShare = null,Object? isPaid = null,Object? paidAmount = freezed,Object? paidAt = freezed,}) {
  return _then(_OrderInvestorShare(
dealId: null == dealId ? _self.dealId : dealId // ignore: cast_nullable_to_non_nullable
as int,dealCode: null == dealCode ? _self.dealCode : dealCode // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,kindLabel: null == kindLabel ? _self.kindLabel : kindLabel // ignore: cast_nullable_to_non_nullable
as String,goodsAmount: freezed == goodsAmount ? _self.goodsAmount : goodsAmount // ignore: cast_nullable_to_non_nullable
as String?,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as String,investorsShare: null == investorsShare ? _self.investorsShare : investorsShare // ignore: cast_nullable_to_non_nullable
as String,companyShare: null == companyShare ? _self.companyShare : companyShare // ignore: cast_nullable_to_non_nullable
as String,isPaid: null == isPaid ? _self.isPaid : isPaid // ignore: cast_nullable_to_non_nullable
as bool,paidAmount: freezed == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as String?,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
