import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/utils/validators.dart';
import 'package:printing/features/warehouses/models/stock_movement.dart';
import 'package:printing/features/warehouses/repositories/warehouse_repository.dart';

/// What a storekeeper is recording: stock arriving, stock moving between our own places, or a
/// count that disagreed with the record.
///
/// One enum rather than three screens, because the form is the same three questions — which
/// size, how much, and where — and only the *where* differs.
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
}

/// Writes one line into the ledger.
///
/// **The quantity is normalised here and nowhere else.** ٢٥٠ from an Arabic keyboard and «250,5»
/// with the decimal comma that keyboard offers first both have to reach the API as `250` and
/// `250.5`, or the storekeeper gets a 422 about a field they filled in correctly.
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
    required int productVariantId,
    required int warehouseId,
    int? fromWarehouseId,
    required String quantity,
    String? notes,
  }) {
    final amount = Validators.toWesternDigits(quantity.trim()).replaceAll(',', '.');
    final trimmedNotes = notes?.trim();

    return switch (kind) {
      MovementKind.arrival => _repository.recordArrival(
        productVariantId: productVariantId,
        toWarehouseId: warehouseId,
        quantity: amount,
        notes: trimmedNotes,
      ),
      MovementKind.transfer => _repository.recordTransfer(
        productVariantId: productVariantId,
        // Required by the form before it ever gets here; the server refuses the pair anyway if
        // both ends name the same place.
        fromWarehouseId: fromWarehouseId!,
        toWarehouseId: warehouseId,
        quantity: amount,
        notes: trimmedNotes,
      ),
      MovementKind.increase || MovementKind.decrease => _repository.recordAdjustment(
        productVariantId: productVariantId,
        warehouseId: warehouseId,
        quantity: amount,
        isIncrease: kind == MovementKind.increase,
        notes: trimmedNotes,
      ),
    };
  }
}
