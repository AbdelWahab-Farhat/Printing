import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/usecases/get_products.dart';

/// The catalogue screen's ViewModel.
///
/// The debounce, the out-of-order guard, appending pages and keeping the list when a page fails
/// all come from [PagedCubit]. What is left is the one thing that is about products: which use
/// case fetches them.
class ProductsCubit extends PagedCubit<Product> {
  ProductsCubit({required GetProducts getProducts, this.onlyOrderable = false})
    : _getProducts = getProducts;

  final GetProducts _getProducts;

  /// Whether to leave out the bags the shop has stopped making.
  ///
  /// False for the catalogue screen, which must keep showing a stopped product — its past
  /// orders point at it, and «مُوقَف» is a fact about it rather than a reason to hide it. True
  /// for the picker that adds a line to an order, where offering one would be offering to
  /// print something nobody makes any more.
  final bool onlyOrderable;

  /// Which catalogue heading the list is narrowed to — «التصنيف». Null is «الكل».
  ///
  /// A raw id rather than an enum, because the headings are rows the business curates: a filter
  /// this app spelled out in code would go stale the first time somebody adds one. It is also
  /// the only filter left — «النوع» had a chip row of its own until مطبوعة and سادة became two
  /// more headings on this one.
  int? productCategoryId;

  @override
  Future<Either<Failure, Paginated<Product>>> fetchPage({
    String? search,
    required int page,
  }) {
    // The filter rides along with every page, including the ones `loadMore` asks for: page two
    // of «سادة» must not arrive as page two of everything.
    return _getProducts(
      search: search,
      productCategoryId: productCategoryId,
      isActive: onlyOrderable ? true : null,
      page: page,
    );
  }

  /// Narrows the catalogue to one heading, or widens it back to all of them.
  ///
  /// The search term survives: someone who typed «شفافة» and then tapped «سادة» is asking a
  /// narrower question, not starting a new one.
  Future<void> filterByProductCategory(int? next) async {
    if (next == productCategoryId) return;

    productCategoryId = next;
    await load(search: currentSearch);
  }
}

/// The state this screen switches on. A name for `PagedState<Product>`, so the view reads as a
/// catalogue screen while there is one implementation behind every list in the app.
typedef ProductsState = PagedState<Product>;
typedef ProductsInitial = PagedInitial<Product>;
typedef ProductsLoading = PagedLoading<Product>;
typedef ProductsLoaded = PagedLoaded<Product>;
typedef ProductsFailure = PagedFailure<Product>;
