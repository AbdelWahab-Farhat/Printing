part of 'shelf_balance_cubit.dart';

/// Everything the balance line above the quantity box can be.
///
/// [loaded] carries a nullable shelf on purpose: `null` is the warehouse that has never held
/// this size, which is a real balance of nothing rather than a failed lookup. [failure] carries
/// no message — see the note on the Cubit.
@freezed
sealed class ShelfBalanceState with _$ShelfBalanceState {
  const factory ShelfBalanceState.initial() = ShelfBalanceInitial;

  const factory ShelfBalanceState.loading() = ShelfBalanceLoading;

  const factory ShelfBalanceState.loaded(WarehouseStock? stock) = ShelfBalanceLoaded;

  const factory ShelfBalanceState.failure() = ShelfBalanceFailure;
}
