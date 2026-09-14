import 'package:freezed_annotation/freezed_annotation.dart';

part 'shortage_supply.freezed.dart';
part 'shortage_supply.g.dart';

/// How a quantity reached the shortage.
enum SupplyKind {
  /// Somebody went out and bought it. The ordinary row: it has money on it, and it put goods on
  /// a shelf unless the shortage has none to put them on.
  @JsonValue('purchased')
  purchased('purchased'),

  /// **Nobody in this section created it.** It arrived because a colleague typed what turned up
  /// into the order screen when the order left «نواقص» — see the class note on [ShortageSupply].
  @JsonValue('resolved_externally')
  resolvedExternally('resolved_externally'),

  /// The undo of a purchase, carrying a negative quantity and the id it reverses.
  @JsonValue('reversal')
  reversal('reversal'),

  unknown('');

  const SupplyKind(this.wire);

  final String wire;
}

/// One entry in a shortage's ledger — what arrived, what it cost, and who says so.
///
/// **Rows this section never wrote sit in the same table.** A `resolved_externally` entry comes
/// from the order screen and has **no money on it at all**: [amount], [method] and [methodLabel]
/// are null, and [isReversible] is false because the correction belongs where the entry was
/// made. Draw it as «وصلت من الطلبية» with a dash in the value and method columns — **never
/// `0.00`**, which reads as a free purchase and sits wrongly in anybody's mental total.
///
/// **Reversals stay in the table, struck through.** §٩ of the brief asks for a log of every
/// operation, and a correction that vanished from the screen meant to explain the numbers would
/// make a shortage reading «١٠ كجم» after two entries of twenty look like a mistake rather than a
/// recorded one.
///
/// **[movedStock] is the flag to render from**, not [warehouseId]. The three stock fields are
/// null together on a purchase that moved nothing, and a CHECK on the table keeps them from
/// coming apart.
///
/// **There is no `updated_at`, on purpose.** A ledger entry is never updated, and publishing the
/// field would invite a client to believe it could be.
@freezed
abstract class ShortageSupply with _$ShortageSupply {
  const factory ShortageSupply({
    required int id,
    @JsonKey(name: 'shortage_id') required int shortageId,

    @JsonKey(unknownEnumValue: SupplyKind.unknown) required SupplyKind kind,
    @JsonKey(name: 'kind_label') required String kindLabel,

    /// Negative on a reversal, which is how the ledger adds up to the remainder.
    required String quantity,

    /// **Null on a `resolved_externally` row**, and the reason the table prints a dash rather
    /// than a zero there.
    String? amount,
    String? method,
    @JsonKey(name: 'method_label') String? methodLabel,

    String? reference,

    /// A plain day, held as a `String` for the reason `PnlPeriod` holds its two: round-tripping
    /// one through a `DateTime` is how a date grows a timezone offset it never had.
    @JsonKey(name: 'occurred_on') String? occurredOn,

    String? notes,

    @JsonKey(name: 'warehouse_id') int? warehouseId,
    ShortageSupplyWarehouseRef? warehouse,
    @JsonKey(name: 'stock_movement_id') int? stockMovementId,

    /// Whether the goods actually landed on a shelf. See the class note.
    @JsonKey(name: 'moved_stock') @Default(false) bool movedStock,

    @JsonKey(name: 'is_reversal') @Default(false) bool isReversal,
    @JsonKey(name: 'is_reversed') @Default(false) bool isReversed,

    /// Whether this row may be undone. **The server has already decided** that an arrival from
    /// the order and a reversal are not candidates, so the cancel action is drawn off this and
    /// never off [kind].
    @JsonKey(name: 'is_reversible') @Default(false) bool isReversible,

    /// **الواصل — the paper this purchase was made with, when there was one.**
    ///
    /// Optional on every method here, unlike a customer's payment: a sack bought from the shop
    /// next door often comes with nothing, and the entry is worth having either way. The four
    /// keys are the server's own answers — whether it is a picture is decided from the bytes it
    /// stored, so no format list lives in this app.
    @JsonKey(name: 'has_receipt') @Default(false) bool hasReceipt,
    @JsonKey(name: 'receipt_is_image') @Default(false) bool receiptIsImage,
    @JsonKey(name: 'receipt_url') String? receiptUrl,
    @JsonKey(name: 'receipt_filename') String? receiptFilename,

    @JsonKey(name: 'reverses_supply_id') int? reversesSupplyId,
    @JsonKey(name: 'recorded_by_user_id') int? recordedByUserId,
    ShortageSupplyPersonRef? recorder,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ShortageSupply;

  const ShortageSupply._();

  factory ShortageSupply.fromJson(Map<String, dynamic> json) => _$ShortageSupplyFromJson(json);

  /// Whether this row carries money at all — false on an arrival from the order.
  bool get hasMoney => amount != null;

  /// Whether the row is a correction, either because it is one or because one was made against
  /// it. Both are drawn struck through: the table shows the whole history and the arithmetic
  /// underneath it has already stopped counting them.
  bool get isStruckThrough => isReversal || isReversed;
}

/// The shelf a supply landed on, named for the ledger row.
@freezed
abstract class ShortageSupplyWarehouseRef with _$ShortageSupplyWarehouseRef {
  const factory ShortageSupplyWarehouseRef({required int id, required String name}) =
      _ShortageSupplyWarehouseRef;

  factory ShortageSupplyWarehouseRef.fromJson(Map<String, dynamic> json) =>
      _$ShortageSupplyWarehouseRefFromJson(json);
}

/// Who recorded the entry.
@freezed
abstract class ShortageSupplyPersonRef with _$ShortageSupplyPersonRef {
  const factory ShortageSupplyPersonRef({
    required int id,
    required String name,
    @JsonKey(name: 'employee_code') String? employeeCode,
  }) = _ShortageSupplyPersonRef;

  factory ShortageSupplyPersonRef.fromJson(Map<String, dynamic> json) =>
      _$ShortageSupplyPersonRefFromJson(json);
}
