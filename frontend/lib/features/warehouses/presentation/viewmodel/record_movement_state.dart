part of 'record_movement_cubit.dart';

/// Everything the recording sheet can be, and nothing it cannot.
@freezed
sealed class RecordMovementState with _$RecordMovementState {
  const factory RecordMovementState.initial() = RecordMovementInitial;
  const factory RecordMovementState.submitting() = RecordMovementSubmitting;

  /// Written. Carries the ledger row the server stored — the balance it moved is re-read from
  /// the server rather than computed here.
  const factory RecordMovementState.success(StockMovement movement) = RecordMovementSuccess;

  const factory RecordMovementState.failure(Failure failure) = RecordMovementFailure;
}

extension RecordMovementStateX on RecordMovementState {
  bool get isSubmitting => this is RecordMovementSubmitting;

  /// «الكمية المطلوبة غير متوفرة في المخزن» arrives keyed by field, and belongs under the box
  /// holding the number it is about.
  String? get quantityError => _fieldError('quantity');

  String? get warehouseError => _fieldError('to_warehouse_id') ?? _fieldError('warehouse_id');

  String? get sourceError => _fieldError('from_warehouse_id');

  /// «الصنف المخزني مطلوب», «الصنف المخزني المحدد غير موجود» — and the refusal a size with no
  /// shelf earns, ««المنتج — المقاس» غير مرتبط بصنف مخزني», which the Order context raises under
  /// this very key. All three belong under the box that picked the shelf.
  String? get stockItemError => _fieldError('stock_item_id');

  /// «تكلفة الوحدة مطلوبة عند تسجيل زيادة» — the refusal this form used to earn every single
  /// time it recorded a stocktake that found more than the book said, about a box it did not
  /// draw. It belongs under the box, not behind a generic snackbar.
  String? get unitCostError => _fieldError('unit_cost');

  /// «سبب التسوية مطلوب». Required on an adjustment and on nothing else — the other three
  /// movements explain themselves, so this key only ever arrives for one kind.
  String? get notesError => _fieldError('notes');

  /// Whether anything the server complained about has a box on this form to sit under. What is
  /// left goes to a snackbar; without this, a field the form forgot to map would vanish behind
  /// «البيانات المدخلة غير صحيحة» and the user would have nothing to act on.
  bool get hasFieldErrors =>
      quantityError != null ||
      warehouseError != null ||
      sourceError != null ||
      stockItemError != null ||
      unitCostError != null ||
      notesError != null;

  /// Whether the request may have landed. A movement has no unique key, so this is the one
  /// form in the app that must not offer «أعد المحاولة».
  bool get mayHaveLanded => switch (this) {
    RecordMovementFailure(:final failure) => failure is NetworkFailure,
    _ => false,
  };

  String? _fieldError(String field) => switch (this) {
    RecordMovementFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) => fieldErrors?[field]?.firstOrNull,
      _ => null,
    },
    _ => null,
  };
}
