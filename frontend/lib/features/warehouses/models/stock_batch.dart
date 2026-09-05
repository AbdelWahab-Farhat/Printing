import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/fixed_point.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_batch.freezed.dart';
part 'stock_batch.g.dart';

/// One cost layer under a balance: stock that arrived together at one price, and how much of
/// it is still on the shelf.
///
/// The balance on a shelf is the sum of its layers' [quantityRemaining], and an issue draws the
/// layers down oldest first — so the list of them, in [receivedAt] order, is the answer to
/// «بكم ستُحسب الطلبية القادمة؟» before anybody asks.
///
/// **The three flags at the bottom come from the server and are never computed here.** Whether
/// a layer may be repriced, whether repricing it reaches only part of what arrived, and whether
/// anybody priced it at all are the domain's rules; a second copy in Dart would drift in the
/// direction that offers a button the server then refuses.
@freezed
abstract class StockBatch with _$StockBatch {
  const factory StockBatch({
    required int id,

    @JsonKey(name: 'warehouse_id') required int warehouseId,
    @JsonKey(name: 'stock_item_id') required int stockItemId,
    @JsonKey(name: 'stock_item') StockItemRef? item,

    /// Money, as a string: it is summed, and must reach the screen exactly as stored.
    @JsonKey(name: 'unit_cost') required String unitCost,
    @JsonKey(name: 'quantity_received') required String quantityReceived,
    @JsonKey(name: 'quantity_remaining') required String quantityRemaining,
    @JsonKey(name: 'quantity_consumed') required String quantityConsumed,

    required String unit,
    @JsonKey(name: 'unit_label') required String unitLabel,

    /// The deal whose money bought this layer, and its code — **null on the ordinary layer the
    /// company paid for itself**, which is most of them. What makes «هل هذه الدفعة لمستثمر؟»
    /// answerable on the shelf itself rather than by hunting through the deals.
    @JsonKey(name: 'investor_deal_id') int? investorDealId,
    @JsonKey(name: 'investor_deal_code') String? investorDealCode,

    /// Who is in that deal and what each put in — so «مَن يملك هذه البضاعة؟» is answered on the
    /// shelf rather than by opening the deal.
    @JsonKey(name: 'investor_deal_investors')
    @Default(<BatchFunder>[])
    List<BatchFunder> investorDealInvestors,

    @JsonKey(name: 'source_type') required String sourceType,
    @JsonKey(name: 'source_type_label') required String sourceTypeLabel,

    /// The FIFO key. Not [createdAt]: a layer relocated by a transfer keeps the age of the stock
    /// it actually is, so goods do not get younger by moving shelves.
    @JsonKey(name: 'received_at') DateTime? receivedAt,
    @JsonKey(name: 'revalued_at') DateTime? revaluedAt,

    @JsonKey(name: 'stock_movement_id') int? stockMovementId,
    @JsonKey(name: 'purchase_order_id') int? purchaseOrderId,
    @JsonKey(name: 'split_from_batch_id') int? splitFromBatchId,

    @JsonKey(name: 'can_be_revalued') @Default(false) bool canBeRevalued,
    @JsonKey(name: 'is_partly_consumed') @Default(false) bool isPartlyConsumed,
    @JsonKey(name: 'is_uncosted') @Default(false) bool isUncosted,

    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _StockBatch;

  const StockBatch._();

  factory StockBatch.fromJson(Map<String, dynamic> json) => _$StockBatchFromJson(json);

  String get remainingLabel => groupedDecimal(quantityRemaining);

  String get receivedLabel => groupedDecimal(quantityReceived);

  /// `3.500` → `3.5`: trailing zeros carry nothing, and the screen is read at a glance.
  String get unitCostLabel => groupedDecimal(unitCost);

  /// Whether an investor's money is in this layer.
  bool get isFunded => investorDealId != null;

  /// What is left of this layer, at its price — money to two places.
  String get remainingValue => multiplyToMoney(quantityRemaining, unitCost);

  bool get isFullyConsumed => thousandths(quantityRemaining) <= BigInt.zero;
}

/// What a shelf is worth, read off its remaining layers.
///
/// The five states in INVENTORY-STOCK-SCREEN.md §٦.٢, decided once here: fully priced,
/// partly unpriced (the total is shown and the average dropped), wholly unpriced (a word, never
/// «٠ د.ل»), and nothing on the shelf at all.
class ShelfValuation {
  const ShelfValuation._({
    required this.totalValue,
    required this.averageUnitCost,
    required this.uncostedQuantity,
    required this.remainingQuantity,
    required this.layerCount,
    required this.oldestReceivedAt,
  });

  factory ShelfValuation.of(Iterable<StockBatch> batches) {
    var value = BigInt.zero;
    var remaining = BigInt.zero;
    var uncosted = BigInt.zero;
    var layers = 0;
    DateTime? oldest;

    for (final batch in batches) {
      final left = thousandths(batch.quantityRemaining);
      if (left <= BigInt.zero) continue;

      layers += 1;
      remaining += left;
      value += thousandths(batch.remainingValue);
      if (batch.isUncosted) uncosted += left;

      final at = batch.receivedAt;
      if (at != null && (oldest == null || at.isBefore(oldest))) oldest = at;
    }

    final total = fromThousandths(value, scale: 2);

    return ShelfValuation._(
      totalValue: total,
      averageUnitCost: uncosted > BigInt.zero || remaining == BigInt.zero
          ? null
          : divideToUnitCost(total, fromThousandths(remaining)),
      uncostedQuantity: fromThousandths(uncosted),
      remainingQuantity: fromThousandths(remaining),
      layerCount: layers,
      oldestReceivedAt: oldest,
    );
  }

  /// Money to two places — the sum of every layer's remaining value.
  final String totalValue;

  /// Weighted by what remains, and **null whenever any of it is unpriced**: an average dragged
  /// down by zeros is not an estimate, it is a number that describes nothing.
  final String? averageUnitCost;

  final String uncostedQuantity;
  final String remainingQuantity;
  final int layerCount;
  final DateTime? oldestReceivedAt;

  bool get isEmpty => layerCount == 0;

  bool get hasUncosted => thousandths(uncostedQuantity) > BigInt.zero;

  bool get isWhollyUncosted => hasUncosted && uncostedQuantity == remainingQuantity;
}

/// One partner behind a funded cost layer: what he put in, and the share it bought him.
@freezed
abstract class BatchFunder with _$BatchFunder {
  const factory BatchFunder({
    @JsonKey(name: 'investor_id') required int investorId,
    required String name,
    @JsonKey(name: 'committed_amount') required String committedAmount,
    @JsonKey(name: 'share_percent') required String sharePercent,
  }) = _BatchFunder;

  const BatchFunder._();

  factory BatchFunder.fromJson(Map<String, dynamic> json) => _$BatchFunderFromJson(json);
}
