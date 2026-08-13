import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/products/models/product_category.dart';
import 'package:printing/features/products/presentation/viewmodel/product_categories_cubit.dart';
import 'package:printing/features/products/repositories/product_category_repository.dart';
import 'package:printing/features/products/usecases/delete_product_category.dart';
import 'package:printing/features/products/usecases/get_product_categories.dart';
import 'package:printing/features/products/usecases/set_product_category_activation.dart';

/// التصنيفات — the headings the catalogue is organised under, and the two things the list can
/// do to a row.
///
/// **Both reload rather than patch in place.** Deactivating changes what a filtered list should
/// contain and deleting changes the paging, so a locally edited copy would disagree with the
/// server the moment either happened.
///
/// Arrange - Act - Assert throughout.
class _MockCategoryRepository extends Mock implements ProductCategoryRepository {}

void main() {
  late _MockCategoryRepository repository;
  late ProductCategoriesCubit cubit;

  const bags = ProductCategory(id: 1, name: 'أكياس', productsCount: 12);
  const boxes = ProductCategory(id: 2, name: 'علب وكراتين', productsCount: 0);

  Paginated<ProductCategory> page(List<ProductCategory> items) => Paginated<ProductCategory>(
    items: items,
    meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: items.length),
  );

  void arrangeList(List<ProductCategory> items) {
    when(
      () => repository.categories(
        search: any(named: 'search'),
        isActive: any(named: 'isActive'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(page(items)));
  }

  setUp(() {
    repository = _MockCategoryRepository();
    cubit = ProductCategoriesCubit(
      getCategories: GetProductCategories(repository),
      setActivation: SetProductCategoryActivation(repository),
      deleteCategory: DeleteProductCategory(repository),
    );
  });

  tearDown(() => cubit.close());

  // ───────────────────────────── reading them ─────────────────────────────

  test('the list opens on everything, stopped headings included', () async {
    // Arrange — a screen for *curating* the list has to show what it has stopped offering.
    arrangeList([bags, boxes]);

    // Act
    await cubit.load();

    // Assert
    expect(cubit.state, isA<ProductCategoriesLoaded>());
    verify(
      () => repository.categories(
        search: any(named: 'search'),
        isActive: null,
        page: 1,
        perPage: any(named: 'perPage'),
      ),
    ).called(1);
  });

  test('a picker asks for the ones still on offer', () async {
    // Arrange — the same Cubit, narrowed: filing a product under a stopped heading is exactly
    // what the flag exists to prevent.
    arrangeList([bags]);
    cubit.isActive = true;

    // Act
    await cubit.load();

    // Assert
    verify(
      () => repository.categories(
        search: any(named: 'search'),
        isActive: true,
        page: 1,
        perPage: any(named: 'perPage'),
      ),
    ).called(1);
  });

  // ───────────────────────────── retiring one ─────────────────────────────

  test('stopping a heading re-reads the list rather than editing it here', () async {
    // Arrange
    arrangeList([bags, boxes]);
    await cubit.load();

    when(() => repository.setActivation(1, isActive: false))
        .thenAnswer((_) async => const Right(ProductCategory(id: 1, name: 'أكياس', isActive: false)));

    // Act
    final failure = await cubit.setActivation(bags, isActive: false);

    // Assert — the server's list is the one on screen; nothing was patched locally.
    expect(failure, isNull);
    verify(
      () => repository.categories(
        search: any(named: 'search'),
        isActive: any(named: 'isActive'),
        page: 1,
        perPage: any(named: 'perPage'),
      ),
    ).called(2);
  });

  test('a refused activation is handed back and the list is left alone', () async {
    // Arrange
    arrangeList([bags]);
    await cubit.load();

    when(() => repository.setActivation(1, isActive: false))
        .thenAnswer((_) async => const Left(Failure.server(message: 'تعذّر الإيقاف')));

    // Act
    final failure = await cubit.setActivation(bags, isActive: false);

    // Assert — one read, the opening one: a failed change must not cost a refresh.
    expect(failure, isNotNull);
    verify(
      () => repository.categories(
        search: any(named: 'search'),
        isActive: any(named: 'isActive'),
        page: 1,
        perPage: any(named: 'perPage'),
      ),
    ).called(1);
  });

  // ───────────────────────────── removing one ─────────────────────────────

  test('a heading nothing points at is removed and the list re-read', () async {
    // Arrange
    arrangeList([bags, boxes]);
    await cubit.load();

    when(() => repository.delete(2)).thenAnswer((_) async => const Right('تم حذف التصنيف'));

    // Act
    final failure = await cubit.remove(boxes);

    // Assert
    expect(failure, isNull);
    verify(() => repository.delete(2)).called(1);
  });

  test('the server refusal is the message the screen shows', () async {
    // Arrange — «مرتبط بمنتجات». The app never decides for itself what may be deleted; the
    // count on the card is a courtesy and this is the rule.
    arrangeList([bags]);
    await cubit.load();

    when(() => repository.delete(1)).thenAnswer(
      (_) async => const Left(
        Failure.server(message: 'لا يمكن حذف «أكياس» لارتباطه بـ 12 من المنتجات'),
      ),
    );

    // Act
    final failure = await cubit.remove(bags);

    // Assert
    expect(failure, isNotNull);
    expect(failure!.message, contains('لارتباطه'));
  });

  // ───────────────────────────── narrowing the list ─────────────────────────────

  test('the search term survives a change of filter', () async {
    // Arrange
    arrangeList([bags]);

    // Act — somebody who typed a word and then tapped a chip is narrowing, not restarting.
    await cubit.load(search: 'أكي');
    await cubit.filterByActivity(true);

    // Assert
    verify(
      () => repository.categories(
        search: 'أكي',
        isActive: true,
        page: 1,
        perPage: any(named: 'perPage'),
      ),
    ).called(1);
  });
}
