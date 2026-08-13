import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/pagination/paged_cubit.dart';
import 'package:printing/core/pagination/paged_state.dart';
import 'package:printing/features/products/models/product_category.dart';
import 'package:printing/features/products/usecases/delete_product_category.dart';
import 'package:printing/features/products/usecases/get_product_categories.dart';
import 'package:printing/features/products/usecases/set_product_category_activation.dart';

/// التصنيفات — the management screen's ViewModel.
///
/// The debounce, the out-of-order guard, appending pages and keeping the list when a page fails
/// all come from [PagedCubit]. What is added here is the two things the list itself can do to a
/// row — stop offering it, or remove it — because both change the list under the user and the
/// screen must not be left guessing what it now holds.
///
/// **Both reload rather than patch the row in place.** Deactivating changes what a filtered list
/// should contain, and deleting changes the paging; a locally edited copy would disagree with
/// the server the moment either happened. The list is short and the request is cheap.
class ProductCategoriesCubit extends PagedCubit<ProductCategory> {
  ProductCategoriesCubit({
    required GetProductCategories getCategories,
    required SetProductCategoryActivation setActivation,
    required DeleteProductCategory deleteCategory,
  }) : _getCategories = getCategories,
       _setActivation = setActivation,
       _deleteCategory = deleteCategory;

  final GetProductCategories _getCategories;
  final SetProductCategoryActivation _setActivation;
  final DeleteProductCategory _deleteCategory;

  /// Which categories the list is narrowed to. `null` — the default — shows the stopped ones
  /// too, which is what a screen for *curating* the list has to do.
  bool? isActive;

  @override
  Future<Either<Failure, Paginated<ProductCategory>>> fetchPage({
    String? search,
    required int page,
  }) {
    // The filter rides along with every page, including the ones `loadMore` asks for.
    return _getCategories(search: search, isActive: isActive, page: page);
  }

  /// Narrows the list to the offered categories, or widens it back.
  ///
  /// The search term survives: somebody who typed a word and then tapped a chip is asking a
  /// narrower question, not starting a new one.
  Future<void> filterByActivity(bool? next) async {
    if (next == isActive) return;

    isActive = next;
    await load(search: currentSearch);
  }

  /// Stops offering a category, or offers it again.
  ///
  /// Answers with the failure so the screen can say why nothing changed; `null` means it did.
  Future<Failure?> setActivation(ProductCategory category, {required bool isActive}) async {
    final result = await _setActivation(category.id, isActive: isActive);

    if (isClosed) return null;

    final failure = result.fold<Failure?>((failure) => failure, (_) => null);
    if (failure == null) await refresh();

    return failure;
  }

  /// Removes a category from the catalogue.
  ///
  /// Refused by the server with a readable 422 once any product is recorded under it — that
  /// message is the [Failure] handed back here, and it is the one the screen shows.
  Future<Failure?> remove(ProductCategory category) async {
    final result = await _deleteCategory(category.id);

    if (isClosed) return null;

    final failure = result.fold<Failure?>((failure) => failure, (_) => null);
    if (failure == null) await refresh();

    return failure;
  }
}

/// The state this screen switches on. A name for `PagedState<ProductCategory>`, so the view
/// reads as a categories screen while there is one implementation behind every list in the app.
typedef ProductCategoriesState = PagedState<ProductCategory>;
typedef ProductCategoriesInitial = PagedInitial<ProductCategory>;
typedef ProductCategoriesLoading = PagedLoading<ProductCategory>;
typedef ProductCategoriesLoaded = PagedLoaded<ProductCategory>;
typedef ProductCategoriesFailure = PagedFailure<ProductCategory>;
