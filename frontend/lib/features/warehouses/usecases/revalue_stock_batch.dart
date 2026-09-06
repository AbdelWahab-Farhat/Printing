import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/features/warehouses/models/stock_batch.dart';
import 'package:dayaa/features/warehouses/repositories/warehouse_repository.dart';

/// Corrects what a quantity of stock is carried at.
///
/// **The figures are normalised here and nowhere else**, the same rule `RecordStockMovement`
/// states beside its own call: ٣٫٥ from an Arabic keyboard has to reach the API as `3.5`, or a
/// person gets a 422 about a field they filled in correctly.
///
/// **An empty quantity box is `null`, never `'0'`.** The absent key is what asks for all of what
/// is left — the common case, and the one that splits nothing. A zero would be a quantity, and
/// the API refuses it.
///
/// Nothing here decides whether the layer *may* be repriced: a used-up layer and one an
/// investor's money bought are both refused by the server, and `StockBatch.canBeRevalued` is the
/// server's own answer about the first two. A second copy of that rule in Dart would drift.
class RevalueStockBatch {
  const RevalueStockBatch(this._repository);

  final WarehouseRepository _repository;

  Future<Either<Failure, StockBatch>> call({
    required int batchId,
    required String unitCost,
    required String reason,
    String? quantity,
  }) {
    return _repository.revalueStockBatch(
      batchId,
      unitCost: _number(unitCost),
      reason: reason.trim(),
      quantity: _optionalNumber(quantity),
    );
  }

  /// ٣٫٥ and «3,5» as the API reads them: `3.5`.
  static String _number(String input) =>
      Validators.toWesternDigits(input.trim()).replaceAll(',', '.');

  static String? _optionalNumber(String? input) {
    final trimmed = input?.trim();

    return (trimmed == null || trimmed.isEmpty) ? null : _number(trimmed);
  }
}
