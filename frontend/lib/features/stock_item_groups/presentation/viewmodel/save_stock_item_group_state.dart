part of 'save_stock_item_group_cubit.dart';

/// Everything the material sheet can be, and nothing it cannot.
@freezed
sealed class SaveStockItemGroupState with _$SaveStockItemGroupState {
  const factory SaveStockItemGroupState.initial() = SaveStockItemGroupInitial;
  const factory SaveStockItemGroupState.submitting() = SaveStockItemGroupSubmitting;

  /// Saved. Carries the material the *server* stored — including the `G7` it allocated, which
  /// is the one field nobody typed and every screen shows.
  const factory SaveStockItemGroupState.success(StockItemGroup group) =
      SaveStockItemGroupSuccess;

  const factory SaveStockItemGroupState.failure(Failure failure) = SaveStockItemGroupFailure;
}

extension SaveStockItemGroupStateX on SaveStockItemGroupState {
  bool get isSubmitting => this is SaveStockItemGroupSubmitting;

  /// The server's complaint about the name — «يوجد مجموعة أصناف بنفس الاسم» belongs under the
  /// box holding the name, not in a toast that leaves somebody re-reading a form to find which
  /// field it meant. That refusal is the commonest one this sheet will ever see: the name is
  /// uniquely indexed because a size carries it.
  String? get nameError => _fieldError('name');

  /// «وحدة التخزين الافتراضية غير صحيحة» — under the chips, not over them.
  String? get defaultUnitError => _fieldError('default_unit');

  String? get descriptionError => _fieldError('description');

  String? _fieldError(String field) => switch (this) {
    SaveStockItemGroupFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) => fieldErrors?[field]?.firstOrNull,
      _ => null,
    },
    _ => null,
  };
}
