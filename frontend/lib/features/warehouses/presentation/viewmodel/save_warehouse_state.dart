part of 'save_warehouse_cubit.dart';

/// Everything the warehouse sheet can be, and nothing it cannot.
@freezed
sealed class SaveWarehouseState with _$SaveWarehouseState {
  const factory SaveWarehouseState.initial() = SaveWarehouseInitial;
  const factory SaveWarehouseState.submitting() = SaveWarehouseSubmitting;

  /// Saved. Carries the warehouse the *server* stored, so the list refreshes from its answer.
  const factory SaveWarehouseState.success(Warehouse warehouse) = SaveWarehouseSuccess;

  const factory SaveWarehouseState.failure(Failure failure) = SaveWarehouseFailure;
}

extension SaveWarehouseStateX on SaveWarehouseState {
  bool get isSubmitting => this is SaveWarehouseSubmitting;

  /// The server's complaint about the name — «اسم المخزن مستخدم مسبقاً» belongs under the box
  /// holding the name, not in a toast that leaves the user guessing which field to fix.
  String? get nameError => _fieldError('name');

  String? get locationError => _fieldError('location');

  String? _fieldError(String field) => switch (this) {
    SaveWarehouseFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) => fieldErrors?[field]?.firstOrNull,
      _ => null,
    },
    _ => null,
  };
}
