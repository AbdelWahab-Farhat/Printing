import 'package:freezed_annotation/freezed_annotation.dart';

part 'deal_order.freezed.dart';
part 'deal_order.g.dart';

/// One order that sold a deal's goods.
///
/// **[profit] and [investorsShare] are two different figures.** The first is what the deal made
/// on the order — its share of the money less the company's work on it less the exact cost of the
/// units drawn. The second is what was written into the investors' ledger for it, which is that
/// profit times the deal's percentage. Their difference is the company's own cut.
///
/// Neither is stored anywhere: the link is the FIFO draw ledger and the money is arithmetic over
/// figures frozen when the order was, so a row here can never disagree with what was paid.
@freezed
abstract class DealOrder with _$DealOrder {
  const factory DealOrder({
    @JsonKey(name: 'order_id') required int orderId,
    required String code,

    required String status,
    @JsonKey(name: 'status_label') required String statusLabel,

    @JsonKey(name: 'customer_name') String? customerName,

    /// When it reached the customer, or when it was placed for one still on the road.
    @JsonKey(name: 'occurred_at') DateTime? occurredAt,

    /// The order's whole money, so the deal's slice of it can be read against something.
    @JsonKey(name: 'grand_total') required String grandTotal,

    /// Units drawn off **this** deal's shelves — not the order's quantity, which may have come
    /// off several people's stock at once.
    required String quantity,

    @JsonKey(name: 'material_cost') required String materialCost,
    required String revenue,
    @JsonKey(name: 'conversion_cost') required String conversionCost,

    required String profit,

    /// Null until the order reached «تم الاستلام» and the ledger was written. Zero is a
    /// different answer: an order that broke exactly even.
    @JsonKey(name: 'investors_share') String? investorsShare,
    @JsonKey(name: 'company_share') String? companyShare,

    @JsonKey(name: 'is_posted') @Default(false) bool isPosted,
  }) = _DealOrder;

  factory DealOrder.fromJson(Map<String, dynamic> json) => _$DealOrderFromJson(json);
}
