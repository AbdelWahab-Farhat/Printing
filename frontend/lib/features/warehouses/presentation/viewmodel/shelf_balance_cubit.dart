import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:dayaa/features/warehouses/usecases/get_warehouse_stocks.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shelf_balance_cubit.freezed.dart';
part 'shelf_balance_state.dart';

/// What is on one shelf right now, read while a movement is being written against it.
///
/// **The number the quantity being typed is judged against.** «تسوية بالنقص ٢٠٠» is a different
/// decision on a shelf holding ٨٠٠ than on one holding ١٥٠ — and the storekeeper used to learn
/// which only from the server's refusal, after the form had been filled in. So the balance is
/// fetched the moment the shelf and the warehouse are both known.
///
/// **It fails silently**, like the summary above the shelves: the form works perfectly well
/// without the figure, and an error banner over a working page would be the worst of the
/// available answers. A lookup that could not be read simply shows nothing.
class ShelfBalanceCubit extends Cubit<ShelfBalanceState> {
  ShelfBalanceCubit({required GetWarehouseStocks getStocks})
    : _getStocks = getStocks,
      super(const ShelfBalanceState.initial());

  final GetWarehouseStocks _getStocks;

  /// Guards against the answer to an older question arriving last — a storekeeper changing the
  /// warehouse twice would otherwise be shown the first one's balance under the second's name.
  int _requestId = 0;

  Future<void> look({required int warehouseId, required int stockItemId}) async {
    final requestId = ++_requestId;

    emit(const ShelfBalanceState.loading());

    final result = await _getStocks(warehouseId, stockItemId: stockItemId, perPage: 1);

    if (isClosed || requestId != _requestId) return;

    emit(
      result.fold(
        (_) => const ShelfBalanceState.failure(),
        // An empty page is an answer, not a miss: this size has never been in this warehouse,
        // so there is nothing on the shelf. The screen says so in the shelf's own words.
        (page) => ShelfBalanceState.loaded(page.items.firstOrNull),
      ),
    );
  }

  /// Nothing to say — the shelf or the warehouse is no longer settled.
  void clear() {
    _requestId++;

    emit(const ShelfBalanceState.initial());
  }
}
