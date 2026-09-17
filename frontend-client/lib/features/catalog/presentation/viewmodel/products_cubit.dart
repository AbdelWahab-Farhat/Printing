import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/pagination/paged_cubit.dart';
import 'package:dayaa_client/core/pagination/paged_state.dart';
import 'package:dayaa_client/features/catalog/models/product.dart';
import 'package:dayaa_client/features/catalog/usecases/browse_products.dart';
import 'package:dayaa_client/features/catalog/usecases/list_categories.dart';

/// The list «المنتجات» is bound to.
typedef ProductsState = PagedState<Product>;

/// The ViewModel for the catalogue grid, its headings and its search box.
///
/// **The paging is inherited.** Debounced search, the out-of-order guard that stops a slow
/// answer for «كي» overwriting a fast one for «كيس», and appending without duplicating a row all
/// come from [PagedCubit].
///
/// What this class adds is the heading filter, and one deliberate departure from the base:
/// **the headings are held on the Cubit rather than in the state.** They are a handful of rows
/// that do not depend on the search or the filter, so a chip row that emptied on every keystroke
/// would be the app asking the same question over and over — and `PagedState` has no room for
/// them by design, because it is the shape *every* list shares.
class ProductsCubit extends PagedCubit<Product> {
  ProductsCubit({required BrowseProducts browse, required ListCategories categories})
    : _browse = browse,
      _categories = categories;

  final BrowseProducts _browse;
  final ListCategories _categories;

  List<ProductCategory> _headings = const [];
  int? _categoryId;

  /// The filter chips. Empty until the first [start], and empty afterwards if the request
  /// failed — **which is not worth taking the catalogue away for.** The grid is perfectly
  /// browsable without chips.
  List<ProductCategory> get categories => _headings;

  /// Which heading is selected, or null for the whole catalogue.
  int? get categoryId => _categoryId;

  /// The first load: the headings and page one.
  ///
  /// Separate from [load] because the base class owns that one and calls it again on every
  /// search, refresh and filter change — fetching the headings each time would be four requests
  /// for an answer that has not moved.
  Future<void> start() async {
    // Awaited before the page so the chips and the first rows appear together, rather than the
    // filter row popping in a beat after the grid.
    _headings = (await _categories()).fold((_) => const <ProductCategory>[], (list) => list);

    if (isClosed) return;

    await load(search: currentSearch);
  }

  @override
  Future<Either<Failure, Paginated<Product>>> fetchPage({
    String? search,
    required int page,
  }) => _browse(page: page, search: search, categoryId: _categoryId);

  @override
  Object identityOf(Product item) => item.id;

  /// Narrows to a heading, or clears it when [categoryId] is null.
  ///
  /// **Not debounced**, unlike the search box: a tap is a decision, not a half-typed word.
  Future<void> filterBy(int? categoryId) {
    if (categoryId == _categoryId) return Future<void>.value();

    _categoryId = categoryId;

    return load(search: currentSearch);
  }
}
