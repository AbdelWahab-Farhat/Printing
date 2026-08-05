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

  String? get warehouseError =>
      _fieldError('to_warehouse_id') ?? _fieldError('warehouse_id');

  String? get sourceError => _fieldError('from_warehouse_id');

  String? get variantError => _fieldError('product_variant_id');

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
