import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/products/models/new_product.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/presentation/viewmodel/save_product_cubit.dart';
import 'package:dayaa/features/products/repositories/product_repository.dart';
import 'package:dayaa/features/products/usecases/save_product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// The add-product screen's ViewModel.
///
/// Arrange - Act - Assert throughout.
class _MockProductRepository extends Mock implements ProductRepository {}

class _FakeNewProduct extends Fake implements NewProduct {}

void main() {
  late _MockProductRepository repository;
  late SaveProductCubit cubit;

  setUpAll(() {
    registerFallbackValue(_FakeNewProduct());
    registerFallbackValue(
      const PickedFile(
        path: '/tmp/fallback.jpg',
        name: 'fallback.jpg',
        sizeBytes: 1,
      ),
    );
  });

  const stored = Product(
    id: 7,
    code: 'P7',
    slug: 'shipping-bag',
    name: 'أكياس الشحن',
    pricingUnit: 'piece',
    pricingUnitLabel: 'قطعة',
    pricingMode: 'tiered',
    pricingModeLabel: 'حسب الكمية',
    minOrderQuantity: '100.000',
  );

  setUp(() {
    repository = _MockProductRepository();
    cubit = SaveProductCubit(saveProduct: SaveProduct(repository));
  });

  tearDown(() => cubit.close());

  Future<void> submit(SaveProductCubit cubit) => cubit.submit(
    name: 'أكياس الشحن',
    productCategoryId: 3,
    pricingUnit: 'piece',
    pricingMode: 'tiered',
    minOrderQuantity: '100',
    // Adding, so the server requires one and the form has collected it.
    image: const PickedFile(
      path: '/tmp/bag.jpg',
      name: 'bag.jpg',
      sizeBytes: 2048,
    ),
  );

  blocTest<SaveProductCubit, SaveProductState>(
    'goes submitting then success, carrying the product the server stored',
    setUp: () {
      // Arrange
      when(
        () => repository.create(any(), image: any(named: 'image')),
      ).thenAnswer((_) async => const Right(stored));
    },
    build: () => cubit,
    // Act
    act: submit,
    // Assert — the code is the server's, and it is what the screen reads back to the user.
    expect: () => [
      const SaveProductState.submitting(),
      isA<SaveProductSuccess>().having(
        (state) => state.product.code,
        'the code',
        'P7',
      ),
    ],
  );

  blocTest<SaveProductCubit, SaveProductState>(
    "shows the server's own complaint rather than a generic one",
    setUp: () {
      // Arrange
      when(
        () => repository.create(any(), image: any(named: 'image')),
      ).thenAnswer(
        (_) async =>
            const Left(Failure.server(message: 'المعرف مستخدم مسبقاً')),
      );
    },
    build: () => cubit,
    // Act
    act: submit,
    // Assert
    expect: () => const [
      SaveProductState.submitting(),
      SaveProductState.failure(Failure.server(message: 'المعرف مستخدم مسبقاً')),
    ],
  );

  blocTest<SaveProductCubit, SaveProductState>(
    'an impatient second tap does not send a second product',
    setUp: () {
      // Arrange — the slug is unique in the database, so a duplicate POST is a confusing 422
      // rather than a duplicate row. Either way the user asked once.
      when(
        () => repository.create(any(), image: any(named: 'image')),
      ).thenAnswer((_) async => const Right(stored));
    },
    build: () => cubit,
    // Act
    act: (cubit) async {
      final first = submit(cubit);
      await submit(cubit);
      await first;
    },
    // Assert
    verify: (_) => verify(
      () => repository.create(any(), image: any(named: 'image')),
    ).called(1),
  );

  group('field errors', () {
    test(
      'a complaint about the slug reaches the snackbar, having no box to sit in',
      () {
        // Arrange — the form stopped asking for a slug once the server started generating them,
        // so an error about one has nowhere to be painted. It must not be swallowed for that.
        const failure = Failure.server(
          message: 'البيانات غير صحيحة',
          fieldErrors: {
            'slug': ['المعرف مستخدم مسبقاً'],
          },
        );

        // Act
        const state = SaveProductState.failure(failure);

        // Assert
        expect(state.nameError, isNull);
        expect(state.hasUnrenderedErrors, isTrue);
      },
    );

    test("a size's price complaint finds its own cell", () {
      // Arrange — Laravel addresses it by index, and the grid is built in the same order.
      const failure = Failure.server(
        message: 'البيانات غير صحيحة',
        fieldErrors: {
          'variants.1.price_tiers.2.unit_price': [
            'سعر الوحدة لا يمكن أن يكون سالباً',
          ],
        },
      );

      // Act
      const state = SaveProductState.failure(failure);

      // Assert
      expect(state.priceError(1, 2), 'سعر الوحدة لا يمكن أن يكون سالباً');
      expect(state.priceError(0, 2), isNull);
      expect(state.hasUnrenderedErrors, isFalse);
    });

    test('a refusal the form has nowhere to paint reaches the snackbar', () {
      // Arrange — the quote-only rule refuses the whole price list, and no cell owns that key.
      // Without this the screen would appear to do nothing at all.
      const failure = Failure.server(
        message: 'البيانات غير صحيحة',
        fieldErrors: {
          'variants.0.price_tiers': [
            'لا يمكن إضافة أسعار لمنتج سعره حسب الطلب',
          ],
        },
      );

      // Act
      const state = SaveProductState.failure(failure);

      // Assert
      expect(state.hasUnrenderedErrors, isTrue);
    });

    test('a complaint about the material sits under the material field', () {
      // Arrange — the rule is `exists … whereNull(deleted_at)`, so a material archived between
      // the picker being opened and Save being pressed is the one refusal the picker itself
      // cannot prevent.
      const failure = Failure.server(
        message: 'البيانات غير صحيحة',
        fieldErrors: {
          'stock_item_group_id': ['التصنيف المحدد غير موجود'],
        },
      );

      // Act
      const state = SaveProductState.failure(failure);

      // Assert — painted, and therefore not also shouted: the form has a box for this one, and
      // saying it twice is worse than saying it once.
      expect(state.materialError, 'التصنيف المحدد غير موجود');
      expect(state.hasUnrenderedErrors, isFalse);
    });

    test("a complaint about one size's shelf names that size, and unfolds the pickers", () {
      // Arrange — the sharp one. `variants.N.stock_item_id` is listed as a key the form paints
      // inline, but the shelf pickers sit folded away behind «ربط كل مقاس بصنف مخزني بعينه» for
      // almost every product. Both halves have to agree or the screen goes quiet: counted as
      // rendered, no snackbar is raised; left folded, the message lands under a control nobody
      // can see, and Save appears to have done nothing at all.
      const failure = Failure.server(
        message: 'البيانات غير صحيحة',
        fieldErrors: {
          'variants.2.stock_item_id': ['المادة المحددة غير موجودة'],
        },
      );

      // Act
      const state = SaveProductState.failure(failure);

      // Assert — beside the third size and nowhere else: with several sizes on screen, said out
      // loud it would name none of them.
      expect(state.variantStockItemError(2), 'المادة المحددة غير موجودة');
      expect(state.variantStockItemError(0), isNull);
      expect(state.hasUnrenderedErrors, isFalse);
      expect(hasVariantStockItemError(failure), isTrue);
    });

    test('a failure with no field errors at all is always spoken aloud', () {
      // Arrange — a 403, a 500, a dropped connection. Nothing is inline.
      // Act
      const state = SaveProductState.failure(
        Failure.network(message: 'تعذر الاتصال'),
      );

      // Assert
      expect(state.hasUnrenderedErrors, isTrue);
    });
  });

  blocTest<SaveProductCubit, SaveProductState>(
    'typing again clears the error under the field',
    setUp: () {
      // Arrange
      when(
        () => repository.create(any(), image: any(named: 'image')),
      ).thenAnswer(
        (_) async =>
            const Left(Failure.server(message: 'المعرف مستخدم مسبقاً')),
      );
    },
    build: () => cubit,
    // Act
    act: (cubit) async {
      await submit(cubit);
      cubit.clearFailure();
    },
    // Assert — it goes as soon as the user starts correcting, not at the next submit.
    expect: () => [
      const SaveProductState.submitting(),
      const SaveProductState.failure(
        Failure.server(message: 'المعرف مستخدم مسبقاً'),
      ),
      const SaveProductState.initial(),
    ],
  );
}
