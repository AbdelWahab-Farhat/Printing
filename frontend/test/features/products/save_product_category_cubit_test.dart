import 'package:dartz/dartz.dart';
import 'package:dayaa/features/products/models/product_category.dart';
import 'package:dayaa/features/products/models/production_mode.dart';
import 'package:dayaa/features/products/presentation/viewmodel/save_product_category_cubit.dart';
import 'package:dayaa/features/products/repositories/product_category_repository.dart';
import 'package:dayaa/features/products/usecases/save_product_category.dart';
import 'package:dayaa/features/products/usecases/set_product_category_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// «طريقة التنفيذ» — the three-way answer that decides which road an order made only of this
/// heading's goods takes.
///
/// **What is under test is that the answer travels.** The rule itself is the server's — see
/// `ResolveOrderFlow` — and the app's whole job is to carry the picker's position to it
/// unchanged, on the way out and on the way back. A form that drew the picker and dropped it
/// on submit would look right and change nothing, which is the failure this file exists to
/// catch.
///
/// Arrange - Act - Assert throughout.
class _MockProductCategoryRepository extends Mock implements ProductCategoryRepository {}

void main() {
  late _MockProductCategoryRepository repository;
  late SaveProductCategoryCubit cubit;

  const stored = ProductCategory(
    id: 4,
    name: 'كروت بزنس',
    productionMode: ProductionMode.outsourced,
  );

  // `any(named: 'productionMode')` needs a value of the type to stand in for.
  setUpAll(() => registerFallbackValue(ProductionMode.inHouse));

  setUp(() {
    repository = _MockProductCategoryRepository();
    cubit = SaveProductCategoryCubit(
      saveCategory: SaveProductCategory(repository),
      setImage: SetProductCategoryImage(repository),
    );
  });

  tearDown(() => cubit.close());

  test('carries the mode to the server when a heading is added', () async {
    // Arrange
    when(
      () => repository.create(
        name: any(named: 'name'),
        description: any(named: 'description'),
        sortOrder: any(named: 'sortOrder'),
        productionMode: any(named: 'productionMode'),
      ),
    ).thenAnswer((_) async => const Right(stored));

    // Act
    await cubit.submit(name: 'كروت بزنس', productionMode: ProductionMode.outsourced);

    // Assert
    verify(
      () => repository.create(
        name: 'كروت بزنس',
        description: null,
        sortOrder: 0,
        productionMode: ProductionMode.outsourced,
      ),
    ).called(1);
  });

  test('carries the mode to the server when a heading is edited', () async {
    // Arrange
    when(
      () => repository.update(
        any(),
        name: any(named: 'name'),
        description: any(named: 'description'),
        sortOrder: any(named: 'sortOrder'),
        isActive: any(named: 'isActive'),
        productionMode: any(named: 'productionMode'),
      ),
    ).thenAnswer((_) async => const Right(stored));

    // Act
    await cubit.submit(
      categoryId: 4,
      name: 'كروت بزنس',
      productionMode: ProductionMode.outsourced,
    );

    // Assert
    verify(
      () => repository.update(
        4,
        name: 'كروت بزنس',
        description: null,
        sortOrder: 0,
        isActive: true,
        productionMode: ProductionMode.outsourced,
      ),
    ).called(1);
  });

  test('is printed here unless somebody said otherwise', () async {
    // Arrange
    when(
      () => repository.create(
        name: any(named: 'name'),
        description: any(named: 'description'),
        sortOrder: any(named: 'sortOrder'),
        productionMode: any(named: 'productionMode'),
      ),
    ).thenAnswer((_) async => const Right(stored));

    // Act — a caller that says nothing about production, as every caller did before the mode.
    await cubit.submit(name: 'أكياس مطبوعة');

    // Assert
    verify(
      () => repository.create(
        name: 'أكياس مطبوعة',
        description: null,
        sortOrder: 0,
        productionMode: ProductionMode.inHouse,
      ),
    ).called(1);
  });

  group('reading the server back', () {
    test('takes the mode off the wire', () {
      // Arrange
      final json = <String, dynamic>{
        'id': 4,
        'name': 'كروت بزنس',
        'production_mode': 'outsourced',
      };

      // Act
      final category = ProductCategory.fromJson(json);

      // Assert
      expect(category.productionMode, ProductionMode.outsourced);
    });

    test('still reads the boolean the old build was sent, without believing it', () {
      // Arrange — the server keeps sending `skips_production` for the shipped app. It is true
      // for سادة *and* وسيط, so it can no longer say which; the mode beside it can.
      final json = <String, dynamic>{
        'id': 4,
        'name': 'أكياس سادة',
        'production_mode': 'none',
        'skips_production': true,
      };

      // Act
      final category = ProductCategory.fromJson(json);

      // Assert
      expect(category.productionMode, ProductionMode.none);
      expect(category.skipsProduction, isTrue);
    });
  });
}
