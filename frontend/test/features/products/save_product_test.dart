import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/products/models/new_product.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/repositories/product_repository.dart';
import 'package:dayaa/features/products/usecases/save_product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// What the form typed, turned into what the API accepts.
///
/// This is the file that earns the use case its place: thirteen numeric fields, every one of
/// which a Libyan keyboard can fill with Arabic-Indic digits that no server-side rule matches.
///
/// Arrange - Act - Assert throughout.
class _MockProductRepository extends Mock implements ProductRepository {}

class _FakeNewProduct extends Fake implements NewProduct {}

void main() {
  late _MockProductRepository repository;
  late SaveProduct createProduct;

  setUpAll(() {
    registerFallbackValue(_FakeNewProduct());
    // A real one rather than a Fake: PickedFile is three final fields and a const constructor,
    // so there is nothing to stub and nothing that could be interacted with.
    registerFallbackValue(
      const PickedFile(
        path: '/tmp/fallback.jpg',
        name: 'fallback.jpg',
        sizeBytes: 1,
      ),
    );
  });

  const stored = Product(
    id: 1,
    code: 'P1',
    slug: 'shipping-bag',
    name: 'أكياس الشحن',
    pricingUnit: 'piece',
    pricingUnitLabel: 'قطعة',
    pricingMode: 'tiered',
    pricingModeLabel: 'حسب الكمية',
    minOrderQuantity: '100.000',
  );

  /// A photo, as the picker would hand one over. Required on create.
  const photo = PickedFile(
    path: '/tmp/bag.jpg',
    name: 'bag.jpg',
    sizeBytes: 2048,
  );

  setUp(() {
    repository = _MockProductRepository();
    createProduct = SaveProduct(repository);
    when(
      () => repository.create(any(), image: any(named: 'image')),
    ).thenAnswer((_) async => const Right(stored));
    when(
      () => repository.update(any(), any()),
    ).thenAnswer((_) async => const Right(stored));
  });

  /// The draft the repository was actually handed.
  ///
  /// Called once per test and held in a local: `verify` marks the call verified, so a second
  /// `sent()` in the same test finds nothing.
  NewProduct sent() =>
      verify(
            () => repository.create(captureAny(), image: any(named: 'image')),
          ).captured.single
          as NewProduct;

  Future<Either<Failure, Product>> submit({
    int? id,
    String name = 'أكياس الشحن',
    String? description,
    List<String> features = const [],
    String pricingUnit = 'piece',
    String pricingMode = 'tiered',
    String minOrderQuantity = '100',
    List<DraftVariant> variants = const [],
    PickedFile? image = photo,
  }) {
    return createProduct(
      id: id,
      name: name,
      description: description,
      features: features,
      // Required by the API from today on — see PRODUCT-CATEGORIES.md.
      productCategoryId: 3,
      pricingUnit: pricingUnit,
      pricingMode: pricingMode,
      minOrderQuantity: minOrderQuantity,
      variants: variants,
      image: image,
    );
  }

  group('Arabic-Indic digits', () {
    test(
      'a minimum typed on a Libyan keyboard reaches the API as ASCII',
      () async {
        // Arrange — the server's `numeric` rule is ASCII-only, so ١٠٠ is a 422 the user cannot
        // diagnose from the field in front of them.
        // Act
        await submit(minOrderQuantity: '١٠٠');

        // Assert
        expect(sent().minOrderQuantity, '100');
      },
    );

    test('a width typed as ٢٥ arrives as 25, not as nothing', () async {
      // Arrange — the sharp one. `width_cm` is nullable server-side, so an unparsed dimension
      // is accepted as absent: no error, no size saved, nobody told.
      // Act
      await submit(
        variants: const [
          DraftVariant(label: '25*35', widthCm: '٢٥', heightCm: '٣٥'),
        ],
      );

      // Assert
      final variant = sent().variants.single;
      expect(variant.widthCm, 25);
      expect(variant.heightCm, 35);
    });

    test('a price keeps every decimal it was given, as text', () async {
      // Arrange — money is never parsed; ٠٫٨٥٠ and 0,850 both mean the same number.
      // Act
      await submit(
        variants: const [
          DraftVariant(
            label: '25*35',
            priceTiers: [
              DraftPriceTier(minQuantity: '١٠٠', unitPrice: '١٫١٠٠'),
              DraftPriceTier(minQuantity: '1000', unitPrice: '0,850'),
            ],
          ),
        ],
      );

      // Assert — the trailing zero survives, because nothing here went through a double.
      final tiers = sent().variants.single.priceTiers;
      expect(tiers.first.minQuantity, '100');
      expect(tiers.first.unitPrice, '1.100');
      expect(tiers.last.unitPrice, '0.850');
    });
  });

  group('what is sent, and what is not', () {
    test(
      'a size with no dimensions sends none, rather than sending zero',
      () async {
        // Arrange — the catalogue's per-kilo bags genuinely have no dimensions.
        // Act
        await submit(variants: const [DraftVariant(label: 'سادة')]);

        // Assert
        final variant = sent().variants.single;
        expect(variant.widthCm, isNull);
        expect(variant.heightCm, isNull);
      },
    );

    test('a blank feature left behind by an add button is dropped', () async {
      // Arrange — `features.*` is `required|string`, so an empty row is a 422 pointing at a
      // field the user believes they deleted.
      // Act
      await submit(features: const ['مقاومة للماء', '   ', 'لاصق قوي']);

      // Assert
      expect(sent().features, ['مقاومة للماء', 'لاصق قوي']);
    });

    test('no features at all is omitted, not sent as an empty list', () async {
      // Arrange
      // Act
      await submit(features: const ['  ']);

      // Assert
      final draft = sent();
      expect(draft.features, isNull);
      expect(draft.toJson().containsKey('features'), isFalse);
    });

    test(
      'whitespace around what was typed never reaches the catalogue',
      () async {
        // Arrange — a name pasted out of a message carries it, and the product it creates is one
        // nobody finds again by searching.
        // Act
        await submit(name: '  أكياس الشحن  ');

        // Assert
        expect(sent().name, 'أكياس الشحن');
      },
    );

    test(
      'a blank description is absent from the body, not null in it',
      () async {
        // Arrange
        // Act
        await submit(description: '   ');

        // Assert
        expect(sent().toJson().containsKey('description'), isFalse);
      },
    );
  });

  group('the body itself', () {
    test(
      'nests sizes and their price breaks the way the API reads them',
      () async {
        // Arrange
        // Act
        await submit(
          variants: const [
            DraftVariant(
              label: '25*35',
              widthCm: '25',
              heightCm: '35',
              priceTiers: [
                DraftPriceTier(minQuantity: '100', unitPrice: '1.100'),
              ],
            ),
          ],
        );

        // Assert — snake_case all the way down, and nothing the app invented.
        // No `slug` key at all: the server derives it from the name and the code it allocates.
        expect(sent().toJson(), {
          'name': 'أكياس الشحن',
          // «التصنيف», required by the API — the heading the product is filed under.
          'product_category_id': 3,
          'pricing_unit': 'piece',
          'pricing_mode': 'tiered',
          'min_order_quantity': '100',
          'variants': [
            {
              'label': '25*35',
              'width_cm': 25,
              'height_cm': 35,
              'price_tiers': [
                {'min_quantity': '100', 'unit_price': '1.100'},
              ],
            },
          ],
        });
      },
    );

    test('a quote-only product carries no prices at all', () async {
      // Arrange — the server refuses the whole list if it does, and that refusal has no field
      // on the form to land on.
      // Act
      await submit(
        pricingMode: 'quote_on_request',
        variants: const [DraftVariant(label: 'حسب الطلب')],
      );

      // Assert
      expect(sent().variants.single.priceTiers, isEmpty);
    });
  });

  test('a failure comes back untouched, with the server own message', () async {
    // Arrange
    when(() => repository.create(any(), image: any(named: 'image'))).thenAnswer(
      (_) async => const Left(Failure.server(message: 'المعرف مستخدم مسبقاً')),
    );

    // Act
    final result = await submit();

    // Assert
    expect(result.isLeft(), isTrue);
    expect(
      result.fold((failure) => failure.message, (_) => null),
      'المعرف مستخدم مسبقاً',
    );
  });

  // ─────────────────────── correcting one that exists ───────────────────────

  test('no id adds; an id corrects the product it names', () async {
    // Act
    await submit();
    await submit(id: 7);

    // Assert — one endpoint each, and the id decides which. A product cannot be created twice
    // by a form somebody opened to fix a typo.
    verify(
      () => repository.create(any(), image: any(named: 'image')),
    ).called(1);

    final corrected = verify(
      () => repository.update(captureAny(), any()),
    ).captured.single;
    expect(corrected, 7);
  });

  // ─────────────────────── the photo ───────────────────────

  test(
    'the photo chosen on the form is the one handed to the repository',
    () async {
      // Arrange
      const chosen = PickedFile(
        path: '/tmp/chosen.png',
        name: 'chosen.png',
        sizeBytes: 900,
      );

      // Act
      await submit(image: chosen);

      // Assert
      final captured = verify(
        () => repository.create(any(), image: captureAny(named: 'image')),
      ).captured.single;
      expect(captured, chosen);
    },
  );

  test('adding without a photo is refused before a request is made', () async {
    // Arrange — the form checks this first, so getting here is a bug. It still has to fail as a
    // failure rather than throw: an exception out of a Cubit takes the screen down with it.
    // Act
    final result = await submit(image: null);

    // Assert
    expect(result.isLeft(), isTrue);
    expect(
      result.fold((failure) => failure.message, (_) => null),
      'صورة المنتج مطلوبة',
    );
    verifyNever(() => repository.create(any(), image: any(named: 'image')));
  });

  test(
    'correcting a product needs no photo, because it already has one',
    () async {
      // Arrange — the form hides the picker when editing, so nothing would supply one.
      // Act
      final result = await submit(id: 7, image: null);

      // Assert
      expect(result.isRight(), isTrue);
      verify(() => repository.update(7, any())).called(1);
    },
  );

  test('a size that already exists keeps its id on the way through', () async {
    // Arrange — the load-bearing detail of editing: the server matches sizes by id and removes
    // any it is not sent, so a size that arrived without one would be deleted and recreated —
    // taking every order line pointing at it with it.
    const sizes = [
      DraftVariant(id: 12, label: '25*35', widthCm: '25', heightCm: '35'),
      DraftVariant(label: '45*50'),
    ];

    // Act
    await submit(id: 7, variants: sizes);

    // Assert
    final draft =
        verify(() => repository.update(any(), captureAny())).captured.single
            as NewProduct;

    expect(draft.variants.first.id, 12);
    // The new size carries none, which is how the server is told it is new.
    expect(draft.variants.last.id, isNull);
  });

  test('a size added on the create form carries no id at all', () async {
    // Act
    await submit(variants: const [DraftVariant(label: '25*35')]);

    // Assert — omitted rather than sent as null: the API's rule is `nullable|integer`, and a
    // null id on a create would be a field the request did not need to mention.
    final draft = sent();

    expect(draft.variants.single.id, isNull);
    // Omitted from the body, not sent as null — `includeIfNull: false` on the field.
    expect(
      (draft.toJson()['variants'] as List<dynamic>).single,
      isNot(contains('id')),
    );
  });
}
