import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/products/models/product_category.dart';
import 'package:dayaa/features/products/usecases/delete_product_category.dart';
import 'package:dayaa/features/products/usecases/get_product_categories.dart';
import 'package:dayaa/features/products/usecases/reorder_product_categories.dart';
import 'package:dayaa/features/products/usecases/set_product_category_activation.dart';

/// التصنيفات — the management screen's ViewModel.
///
/// The debounce, the out-of-order guard, appending pages and keeping the list when a page fails
/// all come from [PagedCubit]. What is added here is the two things the list itself can do to a
/// row — stop offering it, or remove it — because both change the list under the user and the
/// screen must not be left guessing what it now holds.
///
/// **Deactivating patches the row; deleting and reordering still reload.** The activation
/// endpoint answers with the category it just changed, so there is nothing left to ask for — and
/// [belongs] takes the row off a narrowed list rather than leaving it there contradicting the
/// chip. A delete moves the page boundary, and a reorder is about the order of rows this screen
/// does not entirely hold; both of those re-read, and say why below.
class ProductCategoriesCubit extends PagedCubit<ProductCategory> {
  ProductCategoriesCubit({
    required GetProductCategories getCategories,
    required SetProductCategoryActivation setActivation,
    required DeleteProductCategory deleteCategory,
    required ReorderProductCategories reorderCategories,
  }) : _getCategories = getCategories,
       _setActivation = setActivation,
       _deleteCategory = deleteCategory,
       _reorderCategories = reorderCategories;

  final GetProductCategories _getCategories;
  final SetProductCategoryActivation _setActivation;
  final DeleteProductCategory _deleteCategory;
  final ReorderProductCategories _reorderCategories;

  /// Which categories the list is narrowed to. `null` — the default — shows the stopped ones
  /// too, which is what a screen for *curating* the list has to do.
  bool? isActive;

  /// Whether to leave out the headings that hold subheadings.
  ///
  /// True for the picker on the product form: a heading with children is a heading, not a slot,
  /// and offering one would be offering a choice the server refuses. False for the management
  /// screen, which has to show the whole catalogue to curate it.
  bool leafOnly = false;

  @override
  Object identityOf(ProductCategory item) => item.id;

  /// A heading stopped while «المعروضة» is showing leaves the list, rather than sitting there
  /// contradicting the chip above it.
  @override
  bool belongs(ProductCategory item) => isActive == null || item.isActive == isActive;

  @override
  Future<Either<Failure, Paginated<ProductCategory>>> fetchPage({
    String? search,
    required int page,
  }) {
    // The filter rides along with every page, including the ones `loadMore` asks for.
    return _getCategories(
      search: search,
      isActive: isActive,
      leafOnly: leafOnly,
      page: page,
    );
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

    return result.fold<Failure?>((failure) => failure, (updated) {
      replace(updated);

      return null;
    });
  }

  /// Saves the order the cards were dragged into, and re-reads the list from the server.
  ///
  /// **The list is not patched locally first.** A drag is cheap to redo and a wrong order is
  /// invisible until somebody notices it; re-reading is what guarantees the screen shows the
  /// order that was actually saved. The screen keeps its own optimistic copy for the frame the
  /// request takes — that is a rendering detail, and it belongs there rather than here.
  ///
  /// Answers with the failure so the screen can put the list back; `null` means it landed.
  Future<Failure?> reorder(List<int> orderedIds) async {
    final result = await _reorderCategories(orderedIds);

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
