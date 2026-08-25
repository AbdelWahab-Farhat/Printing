import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/stock_item_groups/models/stock_item_group.dart';
import 'package:dayaa/features/stock_item_groups/usecases/get_stock_item_group.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_item_group_items_cubit.freezed.dart';
part 'stock_item_group_items_state.dart';

/// «ما المقاسات الموجودة من هذه المادة؟» — the one question the list cannot answer.
///
/// **Not a `PagedCubit`, because there is no page to ask for.** `/stock-items` accepts no
/// `stock_item_group_id`, deliberately, so the sizes of a material arrive only as the `items[]`
/// of `GET /stock-item-groups/{id}` — one call, all of them, smallest first, and no `meta` to
/// scroll through. A paged Cubit here would be paging over a list that came whole.
///
/// It carries the material it loaded rather than just the sizes, because the two facts the sheet
/// states are on the parent: how the material is counted, and that renaming it would rewrite
/// every row below.
class StockItemGroupItemsCubit extends Cubit<StockItemGroupItemsState> {
  StockItemGroupItemsCubit({
    required this.groupId,
    required GetStockItemGroup getGroup,
  }) : _getGroup = getGroup,
       super(const StockItemGroupItemsState.initial());

  /// Which material. A construction argument rather than something the Cubit is told
  /// afterwards: this ViewModel is *about* one of them and has nothing to show without it.
  final int groupId;

  final GetStockItemGroup _getGroup;

  /// First load, and the retry after a failure — there is nothing on screen worth keeping in
  /// either case.
  Future<void> load() async {
    emit(const StockItemGroupItemsState.loading());

    final result = await _getGroup(groupId);

    if (isClosed) return;

    emit(
      result.fold(
        (f) => StockItemGroupItemsState.failure(f),
        (g) => StockItemGroupItemsState.loaded(g),
      ),
    );
  }
}
