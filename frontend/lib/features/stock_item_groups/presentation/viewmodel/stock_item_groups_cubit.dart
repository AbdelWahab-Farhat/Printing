import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/stock_item_groups/models/stock_item_group.dart';
import 'package:dayaa/features/stock_item_groups/usecases/delete_stock_item_group.dart';
import 'package:dayaa/features/stock_item_groups/usecases/get_stock_item_groups.dart';

/// مجموعات الأصناف — the list screen's ViewModel, and the picker's.
///
/// Paging, the search debounce and the out-of-order guard come from [PagedCubit]. Two things are
/// added: the one operation the list performs on a row, and the one axis it can be narrowed on.
///
/// **[isActive] is a field rather than a constructor argument** because the same Cubit serves
/// two screens with opposite needs. The management list shows everything — a material somebody
/// stopped last month is exactly the one they come back looking for — while a picker must offer
/// only the live ones, since filing a new size under a stopped material buys paper the shop no
/// longer stocks. [loadActiveOnly] is that second opening, said in one call so the restriction
/// and the first fetch cannot get out of step.
class StockItemGroupsCubit extends PagedCubit<StockItemGroup> {
  StockItemGroupsCubit({
    required GetStockItemGroups getGroups,
    required DeleteStockItemGroup deleteGroup,
  }) : _getGroups = getGroups,
       _deleteGroup = deleteGroup;

  final GetStockItemGroups _getGroups;
  final DeleteStockItemGroup _deleteGroup;

  /// `null` — the default — shows the stopped materials too.
  bool? isActive;

  @override
  Future<Either<Failure, Paginated<StockItemGroup>>> fetchPage({
    String? search,
    required int page,
  }) {
    // The restriction rides along with every page, including the ones `loadMore` asks for —
    // otherwise page two quietly reintroduces what page one filtered out.
    return _getGroups(search: search, isActive: isActive, page: page);
  }

  /// First load for a picker: only the materials still in use.
  Future<void> loadActiveOnly() {
    isActive = true;

    return load();
  }

  /// Removes a material and re-reads the list.
  ///
  /// Answers with the failure so the screen can say why nothing changed — «لأن 4 صنفاً مخزنياً
  /// و 2 منتجاً مرتبط بها» is the server's own accounting, including rows the app cannot see,
  /// and it is never rebuilt here.
  ///
  /// Re-reads rather than dropping the row locally: the counts on every other row are unchanged
  /// by this, but the paging is not, and a list that quietly loses a row without moving the page
  /// boundary hides whatever slid up into it.
  Future<Failure?> remove(StockItemGroup group) async {
    final result = await _deleteGroup(group.id);

    if (isClosed) return null;

    final failure = result.fold<Failure?>((failure) => failure, (_) => null);
    if (failure == null) await refresh();

    return failure;
  }
}

/// A name for `PagedState<StockItemGroup>`, so the view reads as a materials screen while there
/// is one implementation behind every list in the app.
typedef StockItemGroupsState = PagedState<StockItemGroup>;
typedef StockItemGroupsInitial = PagedInitial<StockItemGroup>;
typedef StockItemGroupsLoading = PagedLoading<StockItemGroup>;
typedef StockItemGroupsLoaded = PagedLoaded<StockItemGroup>;
typedef StockItemGroupsFailure = PagedFailure<StockItemGroup>;
