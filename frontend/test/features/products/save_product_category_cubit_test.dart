import 'package:dartz/dartz.dart';
import 'package:dayaa/features/products/models/product_category.dart';
import 'package:dayaa/features/products/presentation/viewmodel/save_product_category_cubit.dart';
import 'package:dayaa/features/products/repositories/product_category_repository.dart';
import 'package:dayaa/features/products/usecases/save_product_category.dart';
import 'package:dayaa/features/products/usecases/set_product_category_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// «يتخطّى التصميم والطباعة» — the flag that puts an order made only of this heading's goods
/// straight from «جديدة» to «جاهزة».
///
/// **What is under test is that the answer travels.** The rule itself is the server's — see
/// `ResolveOrderFlow` — and the app's whole job is to carry the switch's position to it
/// unchanged, on the way out and on the way back. A form that drew the switch and dropped it
/// on submit would look right and change nothing, which is the failure this file exists to
/// catch.
///
/// Arrange - Act - Assert throughout.
class _MockProductCategoryRepository extends Mock implements ProductCategoryRepository {}

void main() {
  late _MockProductCategoryRepository repository;
  late SaveProductCategoryCubit cubit;

  const stored = ProductCategory(id: 4, name: 'أكياس سادة', skipsProduction: true);

  setUp(() {
    repository = _MockProductCategoryRepository();
    cubit = SaveProductCategoryCubit(
      saveCategory: SaveProductCategory(repository),
      setImage: SetProductCategoryImage(repository),
    );
  });

  tearDown(() => cubit.close());

  test('carries the flag to the server when a heading is added', () async {
    // Arrange
    when(
      () => repository.create(
        name: any(named: 'name'),
        description: any(named: 'description'),
        sortOrder: any(named: 'sortOrder'),
        skipsProduction: any(named: 'skipsProduction'),
      ),
    ).thenAnswer((_) async => const Right(stored));

    // Act
    await cubit.submit(name: 'أكياس سادة', skipsProduction: true);

    // Assert
    verify(
      () => repository.create(
        name: 'أكياس سادة',
        description: null,
        sortOrder: 0,
        skipsProduction: true,
      ),
    ).called(1);
  });

  test('carries the flag to the server when a heading is edited', () async {
    // Arrange
    when(
      () => repository.update(
        any(),
        name: any(named: 'name'),
        description: any(named: 'description'),
        sortOrder: any(named: 'sortOrder'),
        isActive: any(named: 'isActive'),
        skipsProduction: any(named: 'skipsProduction'),
      ),
    ).thenAnswer((_) async => const Right(stored));

    // Act
    await cubit.submit(categoryId: 4, name: 'أكياس سادة', skipsProduction: true);

    // Assert
    verify(
      () => repository.update(
        4,
        name: 'أكياس سادة',
        description: null,
        sortOrder: 0,
        isActive: true,
        skipsProduction: true,
      ),
    ).called(1);
  });

  test('is off unless the switch was turned on', () async {
    // Arrange
    when(
      () => repository.create(
        name: any(named: 'name'),
        description: any(named: 'description'),
        sortOrder: any(named: 'sortOrder'),
        skipsProduction: any(named: 'skipsProduction'),
      ),
    ).thenAnswer((_) async => const Right(stored));

    // Act — a caller that says nothing about production, as every caller did before the flag.
    await cubit.submit(name: 'أكياس مطبوعة');

    // Assert
    verify(
      () => repository.create(
        name: 'أكياس مطبوعة',
        description: null,
        sortOrder: 0,
        skipsProduction: false,
      ),
    ).called(1);
  });

  group('reading the server back', () {
    test('takes the flag off the wire', () {
      // Arrange
      final json = <String, dynamic>{
        'id': 4,
        'name': 'أكياس سادة',
        'skips_production': true,
      };

      // Act
      final category = ProductCategory.fromJson(json);

      // Assert
      expect(category.skipsProduction, isTrue);
    });

    test('reads a heading the server said nothing about as ordinary production work', () {
      // Arrange — the unknown case takes the road that asks more of the shop, never less.
      final json = <String, dynamic>{'id': 5, 'name': 'أكياس مطبوعة'};

      // Act
      final category = ProductCategory.fromJson(json);

      // Assert
      expect(category.skipsProduction, isFalse);
    });
  });
}
