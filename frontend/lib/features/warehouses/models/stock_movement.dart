import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/utils/digits.dart';
import 'package:printing/features/warehouses/models/warehouse_stock.dart';

part 'stock_movement.freezed.dart';
part 'stock_movement.g.dart';

/// Why a balance changed. The ledger's own vocabulary, mirrored from the server.
///
/// Each case has a different *shape* — an arrival has no source, a fulfillment has no
/// destination, an adjustment has a direction instead of either — which is why the API writes
/// each through its own endpoint rather than one route with four optional fields.
enum MovementType {
  @JsonValue('purchase_arrival')
  purchaseArrival,
  @JsonValue('internal_transfer')
  internalTransfer,
  @JsonValue('order_fulfillment')
  orderFulfillment,
  @JsonValue('adjustment')
  adjustment,

  /// A kind this build has never heard of. The row still renders — its Arabic came with it.
  unknown,
}

/// One line of the ledger: what moved, how much, from where to where, and who recorded it.
///
/// **Rows are written once and never edited.** A mistake is corrected by another movement, not
/// by changing this one, which is what makes the ledger add up to the balance beside it.
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

    @JsonKey(name: 'product_variant_id') required int productVariantId,
    @JsonKey(name: 'product_variant') StockVariant? variant,

    @JsonKey(name: 'from_warehouse_id') int? fromWarehouseId,
    @JsonKey(name: 'from_warehouse') MovementPlace? fromWarehouse,
    @JsonKey(name: 'to_warehouse_id') int? toWarehouseId,
    @JsonKey(name: 'to_warehouse') MovementPlace? toWarehouse,

    /// The order a fulfillment was for, or the purchase an arrival came from.
    @JsonKey(name: 'reference_id') int? referenceId,

    @JsonKey(name: 'employee_id') int? employeeId,
    MovementActor? employee,

    String? notes,

    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _StockMovement;

  const StockMovement._();

  factory StockMovement.fromJson(Map<String, dynamic> json) => _$StockMovementFromJson(json);

  String get quantityLabel => groupedDecimal(quantity);

  String get title => variant == null
      ? 'مقاس #$productVariantId'
      : '${variant!.productName} · ${variant!.label}';

  /// «من المخزن الرئيسي ← صالة العرض», or one half of it for a movement that has one end.
  String get route => switch ((fromWarehouse?.name, toWarehouse?.name)) {
    (final from?, final to?) => '$from ← $to',
    (final from?, null) => 'من $from',
    (null, final to?) => 'إلى $to',
    _ => '',
  };
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
