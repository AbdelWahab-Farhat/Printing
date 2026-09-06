import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_investor_share.freezed.dart';
part 'order_investor_share.g.dart';

/// What one deal took out of one order, and by which road.
///
/// **[kind] is the field everything else hangs off**, because the two roads are two different
/// statements about the same order and adding their figures together would be a lie either way:
///
///   * `plain_sale` — the press *bought* this deal's plain bags at سعر السادة the moment they
///     left the shelf. [goodsAmount] is what it paid for them and [profit] is the margin inside
///     that. The money sits **above** the order's cost line — it is part of what this order paid
///     out, not a share of what it earned — and it was in the investor's ledger before the
///     parcel moved.
///   * `order_profit` — no price was agreed for this deal, so its partners ride the sale and
///     take their share **out of** the order's own profit, at «تم الاستلام». [goodsAmount] is
///     null: nothing was bought.
///
/// [isPaid] reads the ledger, never the order's status: an order can be delivered with a share
/// that rounded to nothing, and no row is written for a zero.
@freezed
abstract class OrderInvestorShare with _$OrderInvestorShare {
  const factory OrderInvestorShare({
    @JsonKey(name: 'deal_id') required int dealId,
    @JsonKey(name: 'deal_code') required String dealCode,

    required String kind,
    @JsonKey(name: 'kind_label') required String kindLabel,

    /// What the press paid for the goods — `plain_sale` only, null on the other road.
    @JsonKey(name: 'goods_amount') String? goodsAmount,

    /// What the deal made on this order by this road: the margin, or its slice of the profit.
    required String profit,

    /// What the deal's terms give the partners of [profit] — and, once [isPaid], what the ledger
    /// holds for them.
    @JsonKey(name: 'investors_share') required String investorsShare,

    /// The rest of [profit]: the company's, whether as the second partner in the goods or as the
    /// shop that did the work.
    @JsonKey(name: 'company_share') required String companyShare,

    @JsonKey(name: 'is_paid') @Default(false) bool isPaid,
    @JsonKey(name: 'paid_amount') String? paidAmount,
    @JsonKey(name: 'paid_at') DateTime? paidAt,
  }) = _OrderInvestorShare;

  factory OrderInvestorShare.fromJson(Map<String, dynamic> json) =>
      _$OrderInvestorShareFromJson(json);
}

/// Whether the press bought this deal's goods, rather than the deal riding the sale.
extension OrderInvestorShareKind on OrderInvestorShare {
  bool get isPlainSale => kind == 'plain_sale';
}
