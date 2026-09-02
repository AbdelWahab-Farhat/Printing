import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/features/warehouses/models/stock_movement.dart';
import 'package:dayaa/features/warehouses/repositories/warehouse_repository.dart';

/// What a storekeeper is recording: stock arriving, stock moving between our own places, or a
/// count that disagreed with the record.
///
/// One enum rather than three screens, because the form is the same three questions — which
/// shelf, how much, and where — and only the *where* differs.
enum MovementKind {
  arrival('توريد', 'مخزن الاستلام'),
  transfer('تحويل داخلي', 'مخزن الوجهة'),
  increase('تسوية بالزيادة', 'المخزن'),
  decrease('تسوية بالنقص', 'المخزن');

  const MovementKind(this.label, this.destinationLabel);

  /// What the tab says.
  final String label;

  /// What the warehouse box is called on this form — «مخزن الاستلام» reads as one end of a
  /// journey, «المخزن» as the place being corrected.
  final String destinationLabel;

  /// Whether the form asks where the stock is coming *from* as well.
  bool get needsSource => this == MovementKind.transfer;

  bool get isAdjustment => this == MovementKind.increase || this == MovementKind.decrease;

  /// Whether this kind opens a **new cost layer**, and so may carry a price.
  ///
  /// Only two of the four do. A transfer relocates the layers that exist at the prices they
  /// already hold, and a decrease consumes them — neither creates anything for a cost to attach
  /// to. **This lives here rather than in the sheet** because hiding a box is decoration, not a
  /// rule: a figure typed under «زيادة» and then abandoned by tapping «تحويل» has to be dropped
  /// by something, and a widget that merely stopped drawing it would still be holding it.
  bool get opensCostLayer => this == MovementKind.arrival || this == MovementKind.increase;

  /// Whether the API **refuses** the movement without one.
  ///
  /// The increase alone. An arrival may genuinely not know its price yet — a shipment whose
  /// invoice has not arrived — and its layer opens at `0.000` in the uncosted queue. A stocktake
  /// that found more than the book said has no vendor document to fall back on at all, so a
  /// silent zero there would understate the cost of goods sold with nothing in the record to
  /// explain why.
  bool get requiresCost => this == MovementKind.increase;
}

/// Writes one line into the ledger.
///
/// **What moves is a صنف مخزني, not a product's size.** Two catalogue rows at one size draw on
/// one pile, so the movement names the pile — a payload keyed by a product size could only ever
/// have moved one of the two products' shares of stock that was never divided.
///
/// **The quantity is normalised here and nowhere else.** ٢٥٠ from an Arabic keyboard and «250,5»
/// with the decimal comma that keyboard offers first both have to reach the API as `250` and
/// `250.5`, or the storekeeper gets a 422 about a field they filled in correctly.
///
/// **The cost is normalised here too, and an empty box is `null` rather than `'0'`.** «لا نعرف
/// سعرها» and «مجانية» are different claims: the first leaves the layer findable in the uncosted
/// queue for someone to price later, the second says a person decided it is worth nothing and
/// takes it out of that queue for good.
///
/// **Retrying after a `Failure.network` is not free**, and this is the one place in the app
/// where that matters: a movement has no unique key, so a request that landed before the
/// connection dropped and is sent again writes the stock twice. The screen says so rather than
/// offering a retry button.
class RecordStockMovement {
  const RecordStockMovement(this._repository);

  final WarehouseRepository _repository;

  Future<Either<Failure, StockMovement>> call({
    required MovementKind kind,
    required int stockItemId,
    required int warehouseId,
    int? fromWarehouseId,
    required String quantity,
    String? unitCost,
    String? notes,
  }) {
    final amount = _number(quantity);

    // Dropped for the two kinds that open no layer — **before** the call, not by the form
    // declining to draw a box.
    final cost = kind.opensCostLayer ? _optionalNumber(unitCost) : null;

    final trimmedNotes = _optional(notes);

    return switch (kind) {
      MovementKind.arrival => _repository.recordArrival(
        stockItemId: stockItemId,
        toWarehouseId: warehouseId,
        quantity: amount,
        unitCost: cost,
        notes: trimmedNotes,
      ),
      MovementKind.transfer => _repository.recordTransfer(
        stockItemId: stockItemId,
        // Required by the form before it ever gets here; the server refuses the pair anyway if
        // both ends name the same place.
        fromWarehouseId: fromWarehouseId!,
        toWarehouseId: warehouseId,
        quantity: amount,
        notes: trimmedNotes,
      ),
      MovementKind.increase || MovementKind.decrease => _repository.recordAdjustment(
        stockItemId: stockItemId,
        warehouseId: warehouseId,
        quantity: amount,
        isIncrease: kind == MovementKind.increase,
        // Null on a decrease, decided above: the two directions share one call, so this is the
        // one place that can tell them apart before the payload is built.
        unitCost: cost,
        notes: trimmedNotes,
      ),
    };
  }

  /// ٢٥٠ and «250,5» as the API reads them: `250` and `250.5`.
  static String _number(String input) =>
      Validators.toWesternDigits(input.trim()).replaceAll(',', '.');

  static String? _optionalNumber(String? input) {
    final trimmed = _optional(input);

    return trimmed == null ? null : _number(trimmed);
  }

  /// An untouched box is nothing at all, never an empty string — the repository omits a null key
  /// and would send `''` for anything else.
  static String? _optional(String? input) {
    final trimmed = input?.trim();

    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
