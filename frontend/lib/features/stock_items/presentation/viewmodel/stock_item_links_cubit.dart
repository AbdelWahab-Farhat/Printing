import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/stock_items/models/stock_item.dart';
import 'package:dayaa/features/stock_items/usecases/get_stock_item.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_item_links_cubit.freezed.dart';
part 'stock_item_links_state.dart';

/// Which product sizes draw on the material the form is open on — read, then held while it is
/// edited.
///
/// **Its own ViewModel rather than three more fields on `SaveStockItemCubit`**, because the two
/// have different lifetimes and different failure modes: the save is an act with a spinner and an
/// outcome, and this is a list that is fetched once and then edited locally until that act
/// happens.
///
/// **The fetch is not optional, and skipping it would lose links.** `PUT /stock-items/{id}
/// /variants` replaces the whole set, so a form that submitted a selection it had seeded from an
/// empty list would unlink every size the material already had. The listing carries
/// `variants_count` and not the sizes themselves — deliberately, it would ship the catalogue
/// inside the inventory list — so the one response that has them is `GET /stock-items/{id}`, and
/// this asks for it before anything can be ticked.
///
/// **Nothing is sent until something changed.** [pending] answers null while the selection is
/// untouched, which is what keeps opening a form and pressing «حفظ» from rewriting links the
/// person never looked at.
class StockItemLinksCubit extends Cubit<StockItemLinksState> {
  StockItemLinksCubit({
    required GetStockItem getStockItem,
    required this.stockItemId,
  }) : _getStockItem = getStockItem,
       super(const StockItemLinksState.initial());

  /// Null while creating: there is nothing to read yet, and the selection starts empty and is
  /// sent right after the material is stored.
  final int? stockItemId;

  final GetStockItem _getStockItem;

  Future<void> load() async {
    final id = stockItemId;

    // A new material has no links and no id to ask about. Loaded, with nothing in it, so the
    // section draws its normal empty state rather than a spinner that never resolves.
    if (id == null) {
      emit(const StockItemLinksState.loaded(<StockItemVariantRef>[]));

      return;
    }

    emit(const StockItemLinksState.loading());

    final result = await _getStockItem(id);

    if (isClosed) return;

    emit(
      result.fold(
        StockItemLinksState.failure,
        (item) => StockItemLinksState.loaded(item.variants),
      ),
    );
  }

  /// Takes what the picker answered.
  ///
  /// Recorded even when it matches what was loaded — «I looked and it is right» is still a change
  /// of state as far as the form is concerned, and re-sending an identical set costs one request
  /// and moves nothing: the action only saves the variants whose link actually differs.
  void select(Set<int> ids) {
    if (state case StockItemLinksLoaded(:final variants)) {
      emit(StockItemLinksState.loaded(variants, selected: ids));
    }
  }
}
