import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/fixed_point.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_movement.freezed.dart';
part 'stock_movement.g.dart';

/// Why a balance changed. The ledger's own vocabulary, mirrored from the server.
///
/// Each case has a different *shape* — an arrival has no source, a fulfillment has no
/// destination, an adjustment has a direction instead of either — which is why the API writes
/// each through its own endpoint rather than one route with four optional fields.
///
/// **The last three are written elsewhere and read here.** A fulfillment, a reversal after a
/// cancelled order and a scrap loss all come out of the Order context, and none of them has a
/// control on this feature's sheet; they are cases all the same, because the feed they land on is
/// this one and a row nobody named would draw with the fallback glyph beside its own Arabic.
enum MovementType {
  @JsonValue('purchase_arrival')
  purchaseArrival,
  @JsonValue('internal_transfer')
  internalTransfer,
  @JsonValue('order_fulfillment')
  orderFulfillment,
  @JsonValue('adjustment')
  adjustment,

  /// «إرجاع بعد إلغاء طلبية» — stock booked out for an order that was then cancelled, coming
  /// back. Written by the Order context, never from here.
  @JsonValue('order_reversal')
  orderReversal,

  /// «تلف أثناء الإنتاج» — material destroyed on the way through the workshop. Also the Order
  /// context's, and the one kind here that is nobody's mistake to correct: it is a loss, not a
  /// miscount, so it is not an [adjustment].
  @JsonValue('scrap_loss')
  scrapLoss,

  /// A kind this build has never heard of. The row still renders — its Arabic came with it.
  unknown,
}

/// One line of the ledger: what moved, how much, from where to where, and who recorded it.
///
/// **Rows are written once and never edited.** A mistake is corrected by another movement, not
/// by changing this one, which is what makes the ledger add up to the balance beside it — and
/// why the server sends no `updated_at` for one.
@freezed
abstract class StockMovement with _$StockMovement {
  const factory StockMovement({
    required int id,

    @JsonKey(name: 'movement_type', unknownEnumValue: MovementType.unknown)
    required MovementType movementType,

    /// The server's Arabic for [movementType].
    @JsonKey(name: 'movement_type_label') required String movementTypeLabel,

    /// Always positive. Which way it went is [movementType] plus the two warehouses — an
    /// adjustment down is a movement *out of* a warehouse, not a negative number.
    required String quantity,

    /// **The pile that moved, not a product's size.** Two catalogue rows can share one, so a row
    /// here answers «ماذا تحرّك من الرف» and deliberately not «لأي منتج».
    @JsonKey(name: 'stock_item_id') required int stockItemId,
    @JsonKey(name: 'stock_item') StockItemRef? item,

    @JsonKey(name: 'from_warehouse_id') int? fromWarehouseId,
    @JsonKey(name: 'from_warehouse') MovementPlace? fromWarehouse,
    @JsonKey(name: 'to_warehouse_id') int? toWarehouseId,
    @JsonKey(name: 'to_warehouse') MovementPlace? toWarehouse,

    /// The order a fulfillment was for, or the purchase an arrival came from.
    @JsonKey(name: 'reference_id') int? referenceId,

    @JsonKey(name: 'employee_id') int? employeeId,
    MovementActor? employee,

    String? notes,

    /// [quantity] with its sign, **relative to the warehouse the list was read for**: a
    /// transfer is `+200` on the shelf that received it and `-200` on the one that sent it.
    /// Null when the feed was not scoped to a warehouse — there is no sign to give.
    @JsonKey(name: 'signed_quantity') String? signedQuantity,

    /// What the shelf held once this row had happened. Null unless the feed was scoped to one
    /// warehouse *and* one shelf; a running total across shelves would be a meaningless number.
    @JsonKey(name: 'balance_after') String? balanceAfter,

    /// What the stock on this row cost, for a reader who holds `inventory.view_cost` — the
    /// server leaves all three keys out otherwise, and this build cannot tell that apart from
    /// «not recorded», which is why the row is told separately whether it may draw them.
    ///
    /// [unitCost] is dropped by the server whenever part of the row is unpriced: an average
    /// that counts zeros describes nothing, so the row gets the total it can vouch for and the
    /// quantity it cannot. [totalCost] null means «nobody recorded it» — a row older than the
    /// cost ledger — and is read as unknown, never as free.
    @JsonKey(name: 'unit_cost') String? unitCost,
    @JsonKey(name: 'total_cost') String? totalCost,
    @JsonKey(name: 'uncosted_quantity') String? uncostedQuantity,

    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _StockMovement;

  const StockMovement._();

  factory StockMovement.fromJson(Map<String, dynamic> json) => _$StockMovementFromJson(json);

  String get quantityLabel => groupedDecimal(quantity);

  /// «كيس شحن 25*35» — the server's own composition, drawn as sent.
  String get title => item?.displayName ?? 'مادة #$stockItemId';

  /// `S7`, in the accent a code wears everywhere in this app. Null only for a row that arrived
  /// without its item.
  String? get code => item?.code;

  /// «من المخزن الرئيسي ← صالة العرض», or one half of it for a movement that has one end.
  String get route => switch ((fromWarehouse?.name, toWarehouse?.name)) {
    (final from?, final to?) => '$from ← $to',
    (final from?, null) => 'من $from',
    (null, final to?) => 'إلى $to',
    _ => '',
  };

  // ── the ledger reading ─────────────────────────────────────────────────────────────

  /// Whether this row added to the shelf it was read for. Null when the feed was unscoped.
  bool? get isInbound => signedQuantity == null ? null : !signedQuantity!.startsWith('-');

  /// `+1,000` / `−1,000`. **The sign is never dropped**: a thousand in and a thousand out drawn
  /// as the same digits was the whole reason the old feed could not be read.
  String? get signedQuantityLabel {
    final signed = signedQuantity;
    if (signed == null) return null;

    return signed.startsWith('-')
        ? '−${groupedDecimal(signed.substring(1))}'
        : '+${groupedDecimal(signed)}';
  }

  String? get balanceAfterLabel => balanceAfter == null ? null : groupedDecimal(balanceAfter!);

  /// What the shelf held *before* a count corrected it — «كان 105,250». The person entered a
  /// count, not a difference, and the row hands them back the number they saw; the difference
  /// stays in its own column so the ledger still adds up.
  String? get balanceBeforeLabel {
    final after = balanceAfter;
    final signed = signedQuantity;
    if (after == null || signed == null) return null;

    return groupedDecimal(subtractDecimals(after, signed));
  }

  /// The other end of a transfer, seen from [warehouseId] — «← صالة العرض» on the sender's
  /// ledger, «من المخزن الرئيسي» on the receiver's. Empty for anything that is not a transfer:
  /// a shelf's own ledger already says where it is, and repeating the place on every row was
  /// a column of identical words.
  String otherEndFrom(int warehouseId) {
    if (movementType != MovementType.internalTransfer) return '';

    return switch ((fromWarehouseId == warehouseId, toWarehouse?.name, fromWarehouse?.name)) {
      (true, final to?, _) => '← $to',
      (false, _, final from?) => 'من $from',
      _ => '',
    };
  }

  /// The cost line, or null when there is nothing honest to say — the server sent no figures
  /// (a row older than the cost ledger), which the row draws as unknown rather than as free.
  ///
  /// Arriving stock leads with the unit price, because that is the number a person knows is
  /// wrong on sight («٣٫٥ للكيلو؟ لا، ٢٫٨»); leaving stock leads with the total, because that is
  /// what actually left. Stock nobody priced is *named* in `warn` and never averaged.
  MovementCostLine? costLine(String unitLabel) {
    final total = totalCost;
    if (total == null) return null;

    final uncosted = uncostedQuantity ?? '0';
    final uncostedMilli = thousandths(uncosted);

    if (uncostedMilli > BigInt.zero) {
      if (uncostedMilli >= thousandths(quantity)) {
        return const MovementCostLine('بلا تكلفة', warns: true);
      }

      return MovementCostLine(
        '${groupedDecimal(total)} د.ل · ${groupedDecimal(uncosted)} $unitLabel بلا تكلفة',
        warns: true,
      );
    }

    final unit = unitCost;
    final inbound = isInbound ?? (toWarehouse != null && fromWarehouse == null);

    if (unit == null) return MovementCostLine('${groupedDecimal(total)} د.ل');

    return MovementCostLine(
      inbound
          ? '${unit.grouped} د.ل/$unitLabel · ${groupedDecimal(total)} د.ل'
          : '${groupedDecimal(total)} د.ل (${unit.grouped}/$unitLabel)',
    );
  }
}

/// One cost line on a ledger row, and whether it is a warning («بلا تكلفة») or a plain fact.
class MovementCostLine {
  const MovementCostLine(this.text, {this.warns = false});

  final String text;
  final bool warns;
}

/// A warehouse as it appears on a ledger row: an id and the name it had.
@freezed
abstract class MovementPlace with _$MovementPlace {
  const factory MovementPlace({required int id, required String name}) = _MovementPlace;

  factory MovementPlace.fromJson(Map<String, dynamic> json) => _$MovementPlaceFromJson(json);
}

/// Who recorded the movement.
@freezed
abstract class MovementActor with _$MovementActor {
  const factory MovementActor({
    required int id,
    required String name,
    @JsonKey(name: 'employee_code') String? employeeCode,
  }) = _MovementActor;

  factory MovementActor.fromJson(Map<String, dynamic> json) => _$MovementActorFromJson(json);
}
