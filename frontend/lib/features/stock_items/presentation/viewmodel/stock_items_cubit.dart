import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/stock_items/models/stock_item.dart';
import 'package:dayaa/features/stock_items/usecases/delete_stock_item.dart';
import 'package:dayaa/features/stock_items/usecases/get_stock_items.dart';

/// «أصناف المخزون» — the ViewModel behind both the management list and the shelf picker.
///
/// Paging, the search debounce, the out-of-order guard and keeping the rows when a later page
/// fails all come from [PagedCubit]. What is added is the three filters the endpoint actually
/// offers and the one thing the list does to a row.
///
/// **One Cubit for the list and the picker**, because they ask the endpoint the same question
/// with different opening arguments: the management screen starts wide, the picker starts
/// narrowed to a size and to the shelves still in use. A second implementation of the same four
/// filters would be a second thing to keep in step with the API.
///
/// **The size filter is a filter, never a constraint.** [loadForSize] opens the picker on the
/// shelves that match a variant's dimensions, and [clearSizeFilter] is one tap away, because a
/// 25*35 bag can legitimately be cut from a wider sheet — the API is explicit about it and a
/// picker that hid the wider sheets would make that job impossible to record.
class StockItemsCubit extends PagedCubit<StockItem> {
  StockItemsCubit({required GetStockItems getStockItems, required DeleteStockItem deleteStockItem})
    : _getStockItems = getStockItems,
      _deleteStockItem = deleteStockItem;

  final GetStockItems _getStockItems;
  final DeleteStockItem _deleteStockItem;

  /// `null` — the default — shows the stopped shelves too, which is what a screen for *curating*
  /// the list has to do: a shelf somebody stopped last month is exactly the one they come back
  /// looking for. A picker sets it to `true`, because offering a stopped shelf to a movement is
  /// how a balance nobody can explain appears.
  bool? isActive;

  /// The two halves of a size, filtered independently — everything 25 wide is as answerable a
  /// question as one exact shelf.
  int? widthCm;
  int? heightCm;

  bool get hasSizeFilter => widthCm != null || heightCm != null;

  /// Whether the list is showing less than it could — what the filter button's fill says.
  bool get isFiltered => isActive != null || hasSizeFilter;

  @override
  Future<Either<Failure, Paginated<StockItem>>> fetchPage({String? search, required int page}) {
    // The filters ride along with every page, including the ones `loadMore` asks for — a second
    // page fetched without them would append rows the first one had excluded.
    return _getStockItems(
      search: search,
      isActive: isActive,
      widthCm: widthCm,
      heightCm: heightCm,
      page: page,
    );
  }

  /// Every axis at once, because the sheet answers them together — one method per axis would
  /// fetch the list three times for a single tap on «تطبيق».
  ///
  /// The parameters are required rather than optional so that `null` unambiguously means «الكل»:
  /// with defaults, "leave this one alone" and "clear this one" would be the same call.
  Future<void> filterBy({
    required bool? isActive,
    required int? widthCm,
    required int? heightCm,
  }) async {
    if (isActive == this.isActive && widthCm == this.widthCm && heightCm == this.heightCm) {
      return;
    }

    this.isActive = isActive;
    this.widthCm = widthCm;
    this.heightCm = heightCm;

    // `refresh` rather than `load`: the latter takes no term and would wipe whatever is in the
    // search box, so narrowing by size after typing a name would silently widen the search.
    await refresh();
  }

  /// The picker's opening move: the shelves that match a variant's size, still-offered ones only.
  ///
  /// Both halves null is a picker opened from somewhere with no size in hand — a purchase order
  /// line, say — which is a legitimate way in and simply starts wide.
  Future<void> loadForSize({int? widthCm, int? heightCm}) {
    isActive = true;
    this.widthCm = widthCm;
    this.heightCm = heightCm;

    return load();
  }

  /// Widens a picker back to every size. See the note on this class for why this exists at all.
  Future<void> clearSizeFilter() => filterBy(isActive: isActive, widthCm: null, heightCm: null);

  /// Removes a shelf and re-reads the list.
  ///
  /// Answers with the failure so the screen can say why nothing changed — «لأن هناك كمية منه في
  /// المخازن» and «لأن N مقاساً يسحب منه» are the server's rules, and the app does not guess at
  /// which of them applied.
  ///
  /// Re-reads rather than patching the row out: a delete changes the paging, and a locally
  /// edited copy disagrees with the server from the next page onwards.
  Future<Failure?> remove(StockItem item) async {
    final result = await _deleteStockItem(item.id);

    if (isClosed) return null;

    final failure = result.fold<Failure?>((failure) => failure, (_) => null);
    if (failure == null) await refresh();

    return failure;
  }
}

/// A name for `PagedState<StockItem>`, so the views read as a stock-items screen while there is
/// still one implementation behind every list in the app.
typedef StockItemsState = PagedState<StockItem>;
typedef StockItemsInitial = PagedInitial<StockItem>;
typedef StockItemsLoading = PagedLoading<StockItem>;
typedef StockItemsLoaded = PagedLoaded<StockItem>;
typedef StockItemsFailure = PagedFailure<StockItem>;
