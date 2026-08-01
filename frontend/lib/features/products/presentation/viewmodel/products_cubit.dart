import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/pagination/paged_cubit.dart';
import 'package:printing/core/pagination/paged_state.dart';
import 'package:printing/features/products/models/product.dart';
import 'package:printing/features/products/usecases/get_products.dart';

/// The catalogue screen's ViewModel.
///
/// The debounce, the out-of-order guard, appending pages and keeping the list when a page fails
/// all come from [PagedCubit]. What is left is the one thing that is about products: which use
/// case fetches them.
class ProductsCubit extends PagedCubit<Product> {
  ProductsCubit({required GetProducts getProducts}) : _getProducts = getProducts;

  final GetProducts _getProducts;

  @override
  Future<Either<Failure, Paginated<Product>>> fetchPage({
    String? search,
    required int page,
  }) {
    return _getProducts(search: search, page: page);
  }
}

/// The state this screen switches on. A name for `PagedState<Product>`, so the view reads as a
/// catalogue screen while there is one implementation behind every list in the app.
typedef ProductsState = PagedState<Product>;
typedef ProductsInitial = PagedInitial<Product>;
typedef ProductsLoading = PagedLoading<Product>;
typedef ProductsLoaded = PagedLoaded<Product>;
typedef ProductsFailure = PagedFailure<Product>;
