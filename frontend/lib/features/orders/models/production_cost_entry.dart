import 'package:freezed_annotation/freezed_annotation.dart';

part 'production_cost_entry.freezed.dart';
part 'production_cost_entry.g.dart';

/// One cost posted against an order while it was being produced.
///
/// **The app only ever writes one kind of these — a scrap loss — and never types its amount.**
/// The storekeeper says how many bags were spoiled; the server draws them off the shelf, reads
/// what those particular bags cost out of the batches they came from, and answers with the
/// figure. That is the whole reason the response is worth parsing rather than discarded: it is
/// the one number in the exchange nobody in the shop knows.
///
/// **Recording one moves no total on the order.** `order_items.cogs` and `orders.total_cogs` are
/// what the line's *fulfilment* cost and are deliberately left alone — a scrap loss is a separate
/// loss, so nothing on the order screen changes and the warehouse balance is what moves. Anything
/// here that reads like «سيُضاف إلى تكلفة الطلبية» is wrong.
///
/// Mirrors `ProductionCostEntryResource.php`.
@freezed
abstract class ProductionCostEntry with _$ProductionCostEntry {
  const factory ProductionCostEntry({
    required int id,
    @JsonKey(name: 'order_id') required int orderId,
    @JsonKey(name: 'order_item_id') required int orderItemId,

    /// `labor`, `machine_runtime`, `overhead` or `scrap_loss`.
    ///
    /// A `String` rather than an enum, for the same reason an order step's `state` is one: it is
    /// branched on nowhere and drawn nowhere — [costTypeLabel] is what a screen shows — and a
    /// fifth kind added on the server should render as itself rather than fail to parse the
    /// entry it belongs to.
    @JsonKey(name: 'cost_type') required String costType,

    /// The server's own Arabic — «خسارة تلف». Rendered as-is, never mapped from [costType] here.
    @JsonKey(name: 'cost_type_label') required String costTypeLabel,

    /// What the entry cost, in dinars. A `String`, like every other money field in this app.
    required String amount,

    /// How much was spoiled, in the line's own unit. Null on an entry that is an amount and
    /// nothing else — an overhead posted per order rather than per bag.
    String? quantity,

    /// **Always null on a scrap loss**, and that is the fact rather than a gap: scrap is priced
    /// from the batches it came out of, not from a standard rate, so there is no per-unit figure
    /// to show and a screen that drew one would be inventing it.
    String? rate,

    String? notes,

    /// Who posted it — **absent, not null, on the response to recording one**, because that
    /// endpoint does not load the relation. «الخادم لم يُرسلها هنا» is a different fact from
    /// «لم يسجّلها أحد», and a required field here would throw on a perfectly good response.
    @JsonKey(name: 'recorded_by') ProductionCostRecorder? recordedBy,

    /// When the cost was incurred, which on a scrap loss is when it was recorded.
    @JsonKey(name: 'incurred_at') DateTime? incurredAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ProductionCostEntry;

  const ProductionCostEntry._();

  factory ProductionCostEntry.fromJson(Map<String, dynamic> json) =>
      _$ProductionCostEntryFromJson(json);

  /// Whether this entry is spoiled stock written off.
  bool get isScrapLoss => costType == 'scrap_loss';
}

/// Who posted a cost entry.
///
/// Two fields, because two is all any screen names. Deliberately not the app's user model — this
/// is a name on a ledger line, not an account somebody is about to edit.
@freezed
abstract class ProductionCostRecorder with _$ProductionCostRecorder {
  const factory ProductionCostRecorder({required int id, required String name}) =
      _ProductionCostRecorder;

  factory ProductionCostRecorder.fromJson(Map<String, dynamic> json) =>
      _$ProductionCostRecorderFromJson(json);
}
