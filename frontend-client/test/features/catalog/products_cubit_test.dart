import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/pagination/paged_state.dart';
import 'package:dayaa_client/features/catalog/models/product.dart';
import 'package:dayaa_client/features/catalog/presentation/viewmodel/products_cubit.dart';
import 'package:dayaa_client/features/catalog/repositories/catalog_repository.dart';
import 'package:dayaa_client/features/catalog/usecases/browse_products.dart';
import 'package:dayaa_client/features/catalog/usecases/list_categories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCatalogRepository extends Mock implements CatalogRepository {}

void main() {
  late _MockCatalogRepository repository;

  const bag = Product(id: 1, name: 'كيس شحن');
  const sticker = Product(id: 2, name: 'ملصق');

  const bags = ProductCategory(id: 5, name: 'أكياس');

  Paginated<Product> page(List<Product> items, {int current = 1, int last = 1}) =>
      Paginated<Product>(
        items: items,
        meta: PageMeta(
          currentPage: current,
          perPage: 15,
          lastPage: last,
          total: items.length,
        ),
      );

  setUp(() => repository = _MockCatalogRepository());

  ProductsCubit build() => ProductsCubit(
    browse: BrowseProducts(repository),
    categories: ListCategories(repository),
  );

  void stubProducts(Paginated<Product> result) {
    when(
      () => repository.products(
        page: any(named: 'page'),
        search: any(named: 'search'),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer((_) async => Right(result));
  }

  void stubCategories(Either<Failure, List<ProductCategory>> result) {
    when(() => repository.categories()).thenAnswer((_) async => result);
  }

  group('start', () {
    test('loads the headings and the first page', () async {
      stubCategories(const Right([bags]));
      stubProducts(page([bag, sticker]));

      final cubit = build();
      await cubit.start();

      expect(cubit.categories, [bags]);
      expect((cubit.state as PagedLoaded<Product>).page.items, [bag, sticker]);
    });

    /// **A heading list that failed is not a failure of the screen.** The catalogue is still
    /// browsable without chips, and a grid replaced by an error because a filter row did not
    /// load would be the app throwing away what it has.
    test('a failed heading list leaves the catalogue browsable', () async {
      stubCategories(const Left(NetworkFailure(message: 'لا يوجد اتصال')));
      stubProducts(page([bag]));

      final cubit = build();
      await cubit.start();

      expect(cubit.categories, isEmpty);
      expect((cubit.state as PagedLoaded<Product>).page.items, [bag]);
    });

    /// The headings do not depend on the search or the filter, so asking for them again on
    /// every keystroke would be the app repeating a question whose answer has not moved.
    test('the headings are fetched once, not on every filter change', () async {
      stubCategories(const Right([bags]));
      stubProducts(page([bag]));

      final cubit = build();
      await cubit.start();
      await cubit.filterBy(bags.id);
      await cubit.refresh();

      verify(() => repository.categories()).called(1);
    });
  });

  group('filterBy', () {
    blocTest<ProductsCubit, ProductsState>(
      'narrows to a heading and re-runs the query',
      build: () {
        stubCategories(const Right([bags]));
        stubProducts(page([bag]));

        return build();
      },
      act: (cubit) async {
        await cubit.start();
        await cubit.filterBy(bags.id);
      },
      verify: (cubit) {
        verify(
          () => repository.products(page: 1, search: null, categoryId: bags.id),
        ).called(1);
        expect(cubit.categoryId, bags.id);
      },
    );

    /// Tapping the chip that is already selected must not fire a request — a catalogue that
    /// reloads when nothing changed is a screen that flickers for no reason.
    blocTest<ProductsCubit, ProductsState>(
      'selecting the heading already selected does nothing',
      build: () {
        stubCategories(const Right([bags]));
        stubProducts(page([bag]));

        return build();
      },
      act: (cubit) async {
        await cubit.start();
        await cubit.filterBy(bags.id);
        await cubit.filterBy(bags.id);
      },
      verify: (_) {
        verify(
          () => repository.products(page: 1, search: null, categoryId: bags.id),
        ).called(1);
      },
    );

    /// **The heading survives a search.** Typing inside «أكياس» searches the bags, not the
    /// whole catalogue — a filter that silently clears itself is a filter the customer has to
    /// re-apply without being told why.
    blocTest<ProductsCubit, ProductsState>(
      'the heading and the search term are sent together',
      build: () {
        stubCategories(const Right([bags]));
        stubProducts(page([bag]));

        return build();
      },
      act: (cubit) async {
        await cubit.start();
        await cubit.filterBy(bags.id);
        await cubit.load(search: 'شحن');
      },
      verify: (_) {
        verify(
          () => repository.products(page: 1, search: 'شحن', categoryId: bags.id),
        ).called(1);
      },
    );

    /// And clearing it goes back to the whole catalogue, rather than to an empty filter the
    /// server would read as a heading named nothing.
    blocTest<ProductsCubit, ProductsState>(
      'clearing the heading sends null, not an empty value',
      build: () {
        stubCategories(const Right([bags]));
        stubProducts(page([bag]));

        return build();
      },
      act: (cubit) async {
        await cubit.start();
        await cubit.filterBy(bags.id);
        await cubit.filterBy(null);
      },
      verify: (cubit) {
        verify(() => repository.products(page: 1, search: null, categoryId: null)).called(2);
        expect(cubit.categoryId, isNull);
      },
    );
  });

  group('loadMore', () {
    blocTest<ProductsCubit, ProductsState>(
      'appends the next page and keeps the heading',
      build: () {
        stubCategories(const Right([bags]));
        when(
          () => repository.products(
            page: 1,
            search: any(named: 'search'),
            categoryId: any(named: 'categoryId'),
          ),
        ).thenAnswer((_) async => Right(page([bag], last: 2)));
        when(
          () => repository.products(
            page: 2,
            search: any(named: 'search'),
            categoryId: any(named: 'categoryId'),
          ),
        ).thenAnswer((_) async => Right(page([sticker], current: 2, last: 2)));

        return build();
      },
      act: (cubit) async {
        await cubit.start();
        await cubit.loadMore();
      },
      verify: (cubit) {
        expect((cubit.state as PagedLoaded<Product>).page.items, [bag, sticker]);
        expect(cubit.categories, [bags]);
      },
    );
  });
}
