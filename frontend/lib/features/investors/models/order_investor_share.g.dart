// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_investor_share.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OrderInvestorShare _$OrderInvestorShareFromJson(Map<String, dynamic> json) =>
    _OrderInvestorShare(
      dealId: (json['deal_id'] as num).toInt(),
      dealCode: json['deal_code'] as String,
      kind: json['kind'] as String,
      kindLabel: json['kind_label'] as String,
      goodsAmount: json['goods_amount'] as String?,
      profit: json['profit'] as String,
      investorsShare: json['investors_share'] as String,
      companyShare: json['company_share'] as String,
      isPaid: json['is_paid'] as bool? ?? false,
      paidAmount: json['paid_amount'] as String?,
      paidAt: json['paid_at'] == null
          ? null
          : DateTime.parse(json['paid_at'] as String),
    );

Map<String, dynamic> _$OrderInvestorShareToJson(_OrderInvestorShare instance) =>
    <String, dynamic>{
      'deal_id': instance.dealId,
      'deal_code': instance.dealCode,
      'kind': instance.kind,
      'kind_label': instance.kindLabel,
      'goods_amount': instance.goodsAmount,
      'profit': instance.profit,
      'investors_share': instance.investorsShare,
      'company_share': instance.companyShare,
      'is_paid': instance.isPaid,
      'paid_amount': instance.paidAmount,
      'paid_at': instance.paidAt?.toIso8601String(),
    };
