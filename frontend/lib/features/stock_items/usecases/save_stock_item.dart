import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/features/stock_items/models/stock_item.dart';
import 'package:dayaa/features/stock_items/models/stock_unit.dart';
import 'package:dayaa/features/stock_items/repositories/stock_item_repository.dart';

/// Opens a shelf, or corrects one.
///
/// **One use case for both, because it is one form** — and because the two rules they share are
/// worth stating once:
///
///   * **the name is trimmed before it travels.** Identity is `(name, width, height)`, so
///     «كيس شحن» and «كيس شحن » would be two shelves nobody could tell apart in a picker, and
///     the second would quietly hold stock the first is short of;
///   * **the dimensions arrive as typed and leave as integers.** `٢٥` is what a Libyan keyboard
///     produces and the server's `integer` rule is ASCII-only, so a size entered correctly would
///     come back as a 422 about a field the person had filled in.
///
/// **What travels differs between the two calls, and that is the API's shape, not a shortcut.**
/// Creating may name a material and may leave the name and the unit to it; updating can change
/// neither the unit nor the material — the server carries no rule for either, so sending them is
/// silently ignored. The unit moves through [SetStockItemUnit] alone, which empties the shelves
/// on the way.
class SaveStockItem {
  const SaveStockItem(this._repository);

  final StockItemRepository _repository;

  /// [stockItemId] null opens a new shelf; anything else corrects that one.
  ///
  /// [stockItemGroupId] is honoured **on creation only**. [unit] likewise: on an update it is
  /// accepted here so the form can pass what it is showing, and deliberately not forwarded.
  ///
  /// [sortOrder] is required rather than defaulted, because the server rewrites the column from
  /// whatever arrives — a caller that forgot it would renumber the shelf to zero on every save.
  Future<Either<Failure, StockItem>> call({
    int? stockItemId,
    int? stockItemGroupId,
    required String name,
    String? widthCm,
    String? heightCm,
    required StockUnit unit,
    String? description,
    required bool isActive,
    required int sortOrder,
  }) {
    final trimmedName = name.trim();
    final width = _dimension(widthCm);
    final height = _dimension(heightCm);
    final trimmedDescription = _blankToNull(description);

    if (stockItemId == null) {
      return _repository.create(
        stockItemGroupId: stockItemGroupId,
        // Empty means «خذه من المادة», which is only a legal answer when a material was named —
        // the server refuses the pair otherwise, in Arabic, under `name`.
        name: trimmedName.isEmpty ? null : trimmedName,
        widthCm: width,
        heightCm: height,
        unit: unit,
        description: trimmedDescription,
        isActive: isActive,
        sortOrder: sortOrder,
      );
    }

    return _repository.update(
      stockItemId,
      name: trimmedName,
      widthCm: width,
      heightCm: height,
      description: trimmedDescription,
      isActive: isActive,
      sortOrder: sortOrder,
    );
  }

  /// An empty box means «بلا مقاس» — a roll, an ink, anything counted without dimensions — not
  /// a zero. The two halves travel together and the server refuses one without the other.
  ///
  /// Anything that is not a whole number after the digits are normalised is passed on as null
  /// rather than guessed at; the form's own validator has already refused it, and inventing a
  /// number here is the one failure a person could not see.
  int? _dimension(String? input) {
    final trimmed = input?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    return int.tryParse(Validators.toWesternDigits(trimmed));
  }

  /// An empty box means «لا وصف له», not «الوصف نصٌّ فارغ».
  String? _blankToNull(String? value) {
    final trimmed = value?.trim();

    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
