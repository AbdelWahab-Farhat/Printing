import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/products/models/product.dart';
import 'package:printing/features/products/presentation/viewmodel/products_cubit.dart';
import 'package:printing/features/products/repositories/product_repository.dart';
import 'package:printing/features/products/usecases/get_products.dart';

/// The repository contract is faked, so nothing here touches Dio or the network.
///
/// Arrange - Act - Assert throughout.
class _MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late _MockProductRepository repository;
  late ProductsCubit cubit;

  Product product(int id, String name) => Product(
    id: id,
    slug: 'product-$id',
    name: name,
    category: 'printed',
    categoryLabel: 'مطبوعة',
    pricingUnit: 'piece',
    pricingUnitLabel: 'قطعة',
    pricingMode: 'tiered',
    pricingModeLabel: 'أسعار مدرجة',
    hasListedPrices: true,
    minOrderQuantity: '100.000',
    variants: [
      ProductVariant(
        id: id * 10,
        label: '25*35',
        priceTiers: const [
          ProductPriceTier(id: 1, minQuantity: '1.000', unitPrice: '1.100'),
          ProductPriceTier(id: 2, minQuantity: '300.000', unitPrice: '0.950'),
        ],
      ),
    ],
  );

  Paginated<Product> page(List<Product> items, {int current = 1, int last = 1}) => Paginated(
    items: items,
    meta: PageMeta(currentPage: current, perPage: 20, lastPage: last, total: items.length),
  );

  setUp(() {
    repository = _MockProductRepository();
    cubit = ProductsCubit(getProducts: GetProducts(repository));
  });

  tearDown(() => cubit.close());

  void arrangeProducts(
    Either<Failure, Paginated<Product>> result, {
    String? search,
    int? onPage,
  }) {
    when(
      () => repository.products(
        search: search ?? any(named: 'search'),
        category: any(named: 'category'),
        isActive: any(named: 'isActive'),
        page: onPage ?? any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => result);
  }

  group('load', () {
    blocTest<ProductsCubit, ProductsState>(
      'goes loading then loaded when the catalogue answers',
      setUp: () {
        // Arrange
        arrangeProducts(right(page([product(1, 'أكياس الشحن')])));
      },
      build: () => cubit,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => [
        const ProductsState.loading(),
        isA<ProductsLoaded>().having(
          (state) => state.page.items.single.name,
          'the product',
          'أكياس الشحن',
        ),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      "shows the server's own message rather than a generic one",
      setUp: () {
        // Arrange
        arrangeProducts(left(const Failure.server(message: 'تعذر جلب المنتجات')));
      },
      build: () => cubit,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => const [
        ProductsState.loading(),
        ProductsState.failure(Failure.server(message: 'تعذر جلب المنتجات')),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'an empty catalogue is a loaded state, not a failure',
      setUp: () {
        // Arrange
        arrangeProducts(right(page([])));
      },
      build: () => cubit,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => [
        const ProductsState.loading(),
        isA<ProductsLoaded>().having((state) => state.page.isEmpty, 'is empty', isTrue),
      ],
    );
  });

  group('search', () {
    blocTest<ProductsCubit, ProductsState>(
      'waits for a pause in the typing, then asks once',
      setUp: () {
        // Arrange
        arrangeProducts(right(page([product(1, 'أكياس ورقية')])));
      },
      build: () => cubit,
      // Act — four keystrokes in quick succession.
      act: (cubit) {
        cubit
          ..search('أ')
          ..search('أك')
          ..search('أكي')
          ..search('أكياس');
      },
      wait: const Duration(milliseconds: 500),
      // Assert — one request, carrying the last term.
      verify: (_) {
        verify(
          () => repository.products(
            search: 'أكياس',
            category: any(named: 'category'),
            isActive: any(named: 'isActive'),
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
          ),
        ).called(1);
      },
    );

    blocTest<ProductsCubit, ProductsState>(
      'clearing the box searches for everything again, not for an empty string',
      setUp: () {
        // Arrange
        arrangeProducts(right(page([product(1, 'أكياس الشحن')])));
      },
      build: () => cubit,
      // Act
      act: (cubit) => cubit.search('   '),
      wait: const Duration(milliseconds: 500),
      // Assert
      verify: (_) {
        verify(
          () => repository.products(
            search: null,
            category: any(named: 'category'),
            isActive: any(named: 'isActive'),
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
          ),
        ).called(1);
      },
    );
  });

  group('loadMore', () {
    blocTest<ProductsCubit, ProductsState>(
      'appends the next page and keeps what is already on screen',
      setUp: () {
        // Arrange
        arrangeProducts(right(page([product(1, 'الأول')], last: 2)), onPage: 1);
        arrangeProducts(right(page([product(2, 'الثاني')], current: 2, last: 2)), onPage: 2);
      },
      build: () => cubit,
      // Act
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
      },
      // Assert
      expect: () => [
        const ProductsState.loading(),
        isA<ProductsLoaded>().having((state) => state.page.items.length, 'first page', 1),
        isA<ProductsLoaded>().having((state) => state.isLoadingMore, 'is loading more', isTrue),
        isA<ProductsLoaded>()
            .having((state) => state.page.items.length, 'both pages', 2)
            .having((state) => state.isLoadingMore, 'is loading more', isFalse),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'a failed extra page leaves the products already loaded alone',
      setUp: () {
        // Arrange
        arrangeProducts(right(page([product(1, 'الأول')], last: 2)), onPage: 1);
        arrangeProducts(left(const Failure.network(message: 'لا يوجد اتصال')), onPage: 2);
      },
      build: () => cubit,
      // Act
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
      },
      // Assert — the list survives; only the footer clears.
      expect: () => [
        const ProductsState.loading(),
        isA<ProductsLoaded>().having((state) => state.page.items.length, 'first page', 1),
        isA<ProductsLoaded>().having((state) => state.isLoadingMore, 'is loading more', isTrue),
        isA<ProductsLoaded>()
            .having((state) => state.page.items.length, 'still there', 1)
            .having((state) => state.isLoadingMore, 'is loading more', isFalse),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'asks for nothing once the last page has been reached',
      setUp: () {
        // Arrange
        arrangeProducts(right(page([product(1, 'الوحيد')])));
      },
      build: () => cubit,
      // Act
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
      },
      // Assert — one request in total: `loadMore` never fired a second.
      verify: (_) {
        verify(
          () => repository.products(
            search: any(named: 'search'),
            category: any(named: 'category'),
            isActive: any(named: 'isActive'),
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
          ),
        ).called(1);
      },
    );
  });

  group('the product itself', () {
    test('starting price is the cheapest tier, exactly as the server wrote it', () {
      // Arrange
      final item = product(1, 'أكياس الشحن');

      // Act
      final price = item.startingPrice;

      // Assert — the string, not a float that rounds it.
      expect(price, '0.950');
    });

    test('a product with no listed prices has no starting price to show', () {
      // Arrange
      final item = product(1, 'أكياس خاصة').copyWith(hasListedPrices: false, variants: []);

      // Act
      final price = item.startingPrice;

      // Assert
      expect(price, isNull);
    });

    test('quantities are shown as people write them', () {
      // Arrange
      final item = product(1, 'أكياس الشحن');

      // Act - Assert
      expect(item.minOrderQuantityLabel, '100');
      expect(item.variants.single.priceTiers.last.minQuantityLabel, '300');
    });
  });
}
