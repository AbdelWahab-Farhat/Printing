import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/products/models/new_product.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/models/product_category.dart';
import 'package:dayaa/features/products/presentation/viewmodel/product_categories_cubit.dart';
import 'package:dayaa/features/products/presentation/viewmodel/save_product_cubit.dart';
import 'package:dayaa/features/products/presentation/views/product_form_page.dart';
import 'package:dayaa/features/products/repositories/product_category_repository.dart';
import 'package:dayaa/features/products/repositories/product_repository.dart';
import 'package:dayaa/features/products/usecases/delete_product_category.dart';
import 'package:dayaa/features/products/usecases/get_product_categories.dart';
import 'package:dayaa/features/products/usecases/reorder_product_categories.dart';
import 'package:dayaa/features/products/usecases/save_product.dart';
import 'package:dayaa/features/products/usecases/set_product_category_activation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubRepository implements ProductRepository {
  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Keeps the body the form handed over, and refuses it.
///
/// **Refused on purpose, with a complaint the form paints under «اسم المنتج».** A success would
/// send the page through `context.pop()` and a snackbar, neither of which the one test using
/// this is about; a refusal on a key the form renders inline leaves the screen where it is and
/// the body captured. See `SaveProductState.hasUnrenderedErrors`.
class _RecordingRepository implements ProductRepository {
  NewProduct? sent;

  static const _refusal = Left<Failure, Product>(
    Failure.server(
      message: 'البيانات غير صحيحة',
      fieldErrors: {
        'name': ['الاسم مستخدم مسبقاً'],
      },
    ),
  );

  @override
  Future<Either<Failure, Product>> update(
    int productId,
    NewProduct product,
  ) async {
    sent = product;

    return _refusal;
  }

  @override
  Future<Either<Failure, Product>> create(
    NewProduct product, {
    required PickedFile image,
  }) async {
    sent = product;

    return _refusal;
  }

  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Answers the picker with one heading, so the form has something to open with.
///
/// The categories are a screen of their own and are exercised there; here they only have to
/// exist, because the form refuses to submit without one.
class _StubCategoryRepository implements ProductCategoryRepository {
  @override
  Future<Either<Failure, Paginated<ProductCategory>>> categories({
    String? search,
    bool? isActive,
    bool leafOnly = false,
    int page = 1,
    int perPage = 20,
  }) async => const Right(
    Paginated<ProductCategory>(
      items: [ProductCategory(id: 3, name: 'أكياس')],
      meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 1),
    ),
  );

  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Opening the product form on a product that already exists.
///
/// **The seeding is the risky half of editing.** Saving is one call; filling a grid of sizes by
/// quantity break is where a product quietly comes back different from how it went in — a price
/// under the wrong column, or a size whose id was lost on the way through.
///
/// Arrange - Act - Assert throughout.
void main() {
  setUp(() {
    sl.registerLazySingleton<SaveProduct>(() => SaveProduct(_StubRepository()));
    sl.registerFactory<SaveProductCubit>(
      () => SaveProductCubit(saveProduct: sl<SaveProduct>()),
    );

    // The form provides this itself, so the screen cannot be built without it registered.
    final categories = _StubCategoryRepository();
    sl.registerFactory<ProductCategoriesCubit>(
      () => ProductCategoriesCubit(
        getCategories: GetProductCategories(categories),
        setActivation: SetProductCategoryActivation(categories),
        deleteCategory: DeleteProductCategory(categories),
        reorderCategories: ReorderProductCategories(categories),
      ),
      instanceName: Injector.activeProductCategoriesCubit,
    );
  });

  tearDown(() => sl.reset());

  Widget host(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    );
  }

  /// «كيس شحن» — the material both of this product's sizes are cut from.
  const material = ProductMaterial(
    id: 3,
    code: 'G3',
    name: 'كيس شحن',
    defaultUnit: 'piece',
    defaultUnitLabel: 'قطعة',
  );

  /// The shelf «25*35» draws on, as the API nests it on a variant.
  const shelf = VariantStockItem(
    id: 4,
    code: 'S4',
    name: 'كيس شحن',
    widthCm: 25,
    heightCm: 35,
    displayName: 'كيس شحن 25*35',
    unit: 'piece',
    unitLabel: 'قطعة',
  );

  const product = Product(
    id: 7,
    code: 'P7',
    slug: 'shipping-bags',
    name: 'أكياس الشحن',
    pricingUnit: 'piece',
    pricingUnitLabel: 'بالقطعة',
    stockItemGroupId: 3,
    stockItemGroup: material,
    pricingMode: 'tiered',
    pricingModeLabel: 'أسعار مدرجة',
    minOrderQuantity: '100.000',
    variants: [
      ProductVariant(
        id: 12,
        label: '25*35',
        widthCm: 25,
        heightCm: 35,
        // Filed by the server the last time this product was saved, from the material above.
        stockItemId: 4,
        stockItem: shelf,
        priceTiers: [
          ProductPriceTier(id: 1, minQuantity: '1.000', unitPrice: '1.100'),
          ProductPriceTier(id: 2, minQuantity: '300.000', unitPrice: '0.950'),
          ProductPriceTier(id: 3, minQuantity: '1000.000', unitPrice: '0.850'),
        ],
      ),
      ProductVariant(
        id: 13,
        label: '35*40',
        priceTiers: [
          // Deliberately out of order and missing the middle break: the grid is matched by
          // threshold, so this size's prices must still land under the right headings.
          ProductPriceTier(id: 5, minQuantity: '1000.000', unitPrice: '0.950'),
          ProductPriceTier(id: 4, minQuantity: '1.000', unitPrice: '1.200'),
        ],
      ),
    ],
  );

  testWidgets('the form opens on what the product already says', (
    tester,
  ) async {
    // Arrange & Act
    await tester.pumpWidget(host(const ProductFormPage(product: product)));
    await tester.pump();

    // Assert — the name, the minimum and the sizes, all as they are.
    expect(find.text('تعديل المنتج'), findsOneWidget);
    expect(find.text('أكياس الشحن'), findsOneWidget);
    expect(find.text('100'), findsWidgets);
    expect(find.text('25*35'), findsWidgets);
    expect(find.text('35*40'), findsWidgets);

    // The button says what pressing it does.
    expect(find.text('حفظ التعديلات'), findsOneWidget);
    expect(find.text('إضافة المنتج'), findsNothing);
  });

  testWidgets('a price lands under its own threshold, not under its position', (
    tester,
  ) async {
    // Arrange & Act
    await tester.pumpWidget(host(const ProductFormPage(product: product)));
    await tester.pump();

    // Assert — «35*40» lists its 1000-break *first* and has no 300 at all. Matched by position
    // the 0.950 would sit under «1 قطعة فأكثر»; matched by threshold it sits where it belongs
    // and the empty cell stays empty for somebody to fill.
    expect(find.text('1.200'), findsWidgets);
    expect(find.text('0.950'), findsWidgets);
    expect(find.text('1.100'), findsWidgets);
  });

  testWidgets('adding a product opens the same form empty', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(host(const ProductFormPage()));
    await tester.pump();

    // Assert
    expect(find.text('منتج جديد'), findsOneWidget);
    expect(find.text('إضافة المنتج'), findsOneWidget);
    expect(find.text('أكياس الشحن'), findsNothing);
  });

  // ─────────────────────────── the photo ───────────────────────────

  testWidgets('adding asks for a photo', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(host(const ProductFormPage()));
    await tester.pump();

    // Assert
    expect(find.text('صورة المنتج'), findsOneWidget);
    expect(find.text('مطلوبة — اضغط للاختيار'), findsOneWidget);
  });

  testWidgets('correcting a product does not, because it already has one', (
    tester,
  ) async {
    // Arrange — swapping a photo is two operations on the images endpoint, and doing them from
    // a form whose Save might never be pressed would change the product before the user
    // committed to anything.
    // Act
    await tester.pumpWidget(host(const ProductFormPage(product: product)));
    await tester.pump();

    // Assert
    expect(find.text('صورة المنتج'), findsNothing);
  });

  testWidgets('submitting with no photo says so and sends nothing', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host(const ProductFormPage()));
    await tester.pump();
    expect(find.text('صورة المنتج مطلوبة'), findsNothing);

    // Act — the button sits below the fold of the test viewport, so it is scrolled to first.
    await tester.ensureVisible(find.text('إضافة المنتج'));
    await tester.pump();
    await tester.tap(find.text('إضافة المنتج'));
    await tester.pump();

    // Assert — the complaint is on screen. Nothing was sent either: _StubRepository answers any
    // call by throwing, so a request would have failed this test rather than passed it quietly.
    expect(find.text('صورة المنتج مطلوبة'), findsOneWidget);
  });

  // ─────────────────────────── the catalogue heading ───────────────────────────

  /// **«التصنيف» is required, and it is the only question of its kind left.**
  ///
  /// A product with no heading cannot be found in the catalogue at all — which is what the
  /// catalogue is for — so the form refuses to send one. «النوع» used to sit under it asking a
  /// second, nearly identical question; مطبوعة and سادة are two more headings now, and the form
  /// asks once. See PRODUCT-CATEGORIES.md.
  testWidgets('the form asks for a catalogue heading, and refuses to send without one', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host(const ProductFormPage()));
    await tester.pumpAndSettle();

    // Assert — one classification question, not two.
    expect(find.text('التصنيف'), findsOneWidget);
    expect(find.text('النوع'), findsNothing);

    // Act
    await tester.ensureVisible(find.text('إضافة المنتج'));
    await tester.pump();
    await tester.tap(find.text('إضافة المنتج'));
    await tester.pump();

    // Assert — the complaint sits under the picker, not in a toast that leaves the user
    // guessing which field to fix. Nothing was sent: _StubRepository throws on any call.
    expect(find.text('اختر تصنيف المنتج'), findsOneWidget);
  });

  // ─────────────────────────── «المادة» ───────────────────────────

  /// **The whole stock feature, from the user's side, is one field at the top of this form.**
  ///
  /// Naming what the product is cut from files every one of its sizes onto a shelf on the next
  /// save: the server takes each size without a shelf of its own and finds this material's «صنف
  /// مخزني» at that size, minting it if the material has not reached that size yet. It replaced a
  /// per-size picker that asked the same question once per size, where one wrong answer split
  /// «كيس شحن 25*35» into two heaps with nothing to say it had happened.
  ///
  /// The storage-unit switch that used to stand here is **gone, not moved.** Two products at one
  /// size share one pile, so what that pile is counted in cannot belong to either of them; it
  /// lives on «الصنف المخزني» and is changed from that screen, where changing it empties the
  /// shelf through a recorded adjustment rather than relabelling a figure that would then mean
  /// nothing.
  testWidgets('asks what the product is cut from, and never what the shelf counts in', (
    tester,
  ) async {
    // Arrange & Act
    await tester.pumpWidget(host(const ProductFormPage()));
    await tester.pumpAndSettle();

    // Assert — one material question, with the selling unit beside it. There is no second unit
    // picker and no switch to reveal one: `POST|PUT /products` has carried no `stock_unit` rule
    // since the column was dropped, and a control that silently did nothing would be worse than
    // no control at all.
    expect(find.text('المادة'), findsOneWidget);
    expect(find.text('وحدة التسعير'), findsOneWidget);
    expect(find.text('وحدة المخزون'), findsNothing);
    expect(find.text('وحدة المخزون تختلف عن وحدة البيع'), findsNothing);
  });

  testWidgets('a product with no material says what that costs, rather than nothing', (
    tester,
  ) async {
    // Arrange — «بلا مادة» is a real answer: a quote-only bag is never stocked. But it has a
    // consequence nothing else on any screen will mention until an order is refused at «جاهزة»,
    // so the empty field states it here.
    // Act
    await tester.pumpWidget(host(const ProductFormPage()));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('اختر المادة — اضغط للاختيار'), findsOneWidget);
    expect(find.textContaining('لن تُربط المقاسات بأي صنف مخزني'), findsOneWidget);
  });

  testWidgets('a product being corrected opens on the material it is filed under', (
    tester,
  ) async {
    // Arrange — the one thing a form must never do to data it was only asked to display is
    // silently blank it. An empty picker would read as «بلا مادة» while the save omitted the key
    // and kept the material anyway: the screen would have been lying, and only by luck harmlessly.
    // Act
    await tester.pumpWidget(host(const ProductFormPage(product: product)));
    await tester.pumpAndSettle();

    // Assert — the material's own name, and the sentence that says what naming it does.
    expect(find.text('كيس شحن'), findsOneWidget);
    expect(find.text('اختر المادة — اضغط للاختيار'), findsNothing);
    expect(find.textContaining('كل مقاس يُربط تلقائياً بصنف هذه المادة'), findsOneWidget);
  });

  // ─────────────────────── the per-size shelf pickers ───────────────────────

  testWidgets('the shelf pickers stay folded away when a material explains them', (
    tester,
  ) async {
    // Arrange — every link on this product is the server's own doing, produced by the one field
    // at the top. Four pickers repeating that answer would bury the field that made it.
    // Act
    await tester.pumpWidget(host(const ProductFormPage(product: product)));
    await tester.pumpAndSettle();

    // Assert — the fold is shut and still names what is inside it: a fold that says nothing about
    // its contents is one people stop opening, and these links travel with every save whether or
    // not anybody opens it.
    expect(find.text('الصنف المخزني'), findsNothing);
    expect(find.text('1 مقاس مربوط بصنف بعينه — عرض'), findsOneWidget);
  });

  testWidgets('a shelf pinned by hand with no material to explain it opens unfolded', (
    tester,
  ) async {
    // Arrange — the escape hatch: a 25*35 bag deliberately cut from a wider sheet. With no
    // material, this link is the only record of a decision somebody took, and the form is about
    // to send it back — hiding it would hide what the next save does.
    const pinned = Product(
      id: 7,
      code: 'P7',
      slug: 'shipping-bags',
      name: 'أكياس الشحن',
      pricingUnit: 'piece',
      pricingUnitLabel: 'بالقطعة',
      pricingMode: 'tiered',
      pricingModeLabel: 'أسعار مدرجة',
      minOrderQuantity: '100.000',
      variants: [
        ProductVariant(
          id: 12,
          label: '25*35',
          stockItemId: 4,
          stockItem: shelf,
        ),
      ],
    );

    // Act
    await tester.pumpWidget(host(const ProductFormPage(product: pinned)));
    await tester.pumpAndSettle();

    // Assert — «كيس شحن 25*35» drawn exactly as the server composed it, one `*` and no spaces.
    // The shortfall sentence an order is refused with quotes that string, and a second spelling
    // built here out of the name and the dimensions is a second thing to reconcile.
    expect(find.text('الصنف المخزني'), findsOneWidget);
    expect(find.text('كيس شحن 25*35'), findsOneWidget);
  });

  /// **The trap, from the screen's end.**
  ///
  /// `PUT /products/{id}` replaces the whole variant set and re-resolves every size's shelf from
  /// the body it is handed. The links are folded away and nobody touched them — so a form that
  /// sent only what it was showing would detach every size from its pile on a save that corrected
  /// a price, and nobody would find out until an order failed at «جاهزة».
  ///
  /// `SaveProduct` round-trips rather than omitting the `variants` key, and this is the screen's
  /// half of that: the seeding reads `stock_item_id` off each variant and the submit sends it
  /// back untouched, fold open or shut.
  testWidgets('a save that touched no size still sends every shelf back', (tester) async {
    // Arrange — one break per size and every cell filled, so Save is not stopped by a validator
    // and the assertion is about the body rather than about the grid. Both sizes are filed under
    // the material; only the first has reached a shelf so far.
    const filed = Product(
      id: 7,
      code: 'P7',
      slug: 'shipping-bags',
      name: 'أكياس الشحن',
      productCategory: ProductCategory(id: 3, name: 'أكياس'),
      productCategoryId: 3,
      pricingUnit: 'piece',
      pricingUnitLabel: 'بالقطعة',
      stockItemGroupId: 3,
      stockItemGroup: material,
      pricingMode: 'tiered',
      pricingModeLabel: 'أسعار مدرجة',
      minOrderQuantity: '100.000',
      variants: [
        ProductVariant(
          id: 12,
          label: '25*35',
          stockItemId: 4,
          stockItem: shelf,
          priceTiers: [
            ProductPriceTier(id: 1, minQuantity: '100.000', unitPrice: '1.100'),
          ],
        ),
        ProductVariant(
          id: 13,
          label: '35*40',
          priceTiers: [
            ProductPriceTier(id: 2, minQuantity: '100.000', unitPrice: '1.200'),
          ],
        ),
      ],
    );

    final repository = _RecordingRepository();
    sl.unregister<SaveProduct>();
    sl.registerLazySingleton<SaveProduct>(() => SaveProduct(repository));

    await tester.pumpWidget(host(const ProductFormPage(product: filed)));
    await tester.pumpAndSettle();
    // Nobody can see the links this save is about to restate, which is the whole point.
    expect(find.text('الصنف المخزني'), findsNothing);

    // Act — nothing edited; just Save. No `pumpAndSettle` after the tap: the button carries a
    // repeating spinner while the request is in flight and would never settle.
    await tester.ensureVisible(find.text('حفظ التعديلات'));
    await tester.pump();
    await tester.tap(find.text('حفظ التعديلات'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Assert — the sizes go back with their ids *and* their shelves, and the one that never had
    // a shelf omits the key rather than sending null: absent means «اترك المادة تقرر», which is
    // what lets the server file it. The material travels too, as its id.
    final sent = repository.sent!;

    expect(sent.stockItemGroupId, 3);
    expect([for (final size in sent.variants) size.id], [12, 13]);
    expect([for (final size in sent.variants) size.stockItemId], [4, null]);
    expect(
      (sent.toJson()['variants'] as List<dynamic>).last,
      isNot(contains('stock_item_id')),
    );
  });

  testWidgets('a product being corrected opens on the heading it already has', (
    tester,
  ) async {
    // Arrange — the one thing a form must never do to data it was only asked to display is
    // silently blank it.
    const filed = Product(
      id: 7,
      code: 'P7',
      slug: 'shipping-bags',
      name: 'أكياس الشحن',
      productCategory: ProductCategory(id: 3, name: 'أكياس'),
      productCategoryId: 3,
      pricingUnit: 'piece',
      pricingUnitLabel: 'بالقطعة',
      pricingMode: 'tiered',
      pricingModeLabel: 'أسعار مدرجة',
      minOrderQuantity: '100.000',
    );

    // Act
    await tester.pumpWidget(host(const ProductFormPage(product: filed)));
    await tester.pumpAndSettle();

    // Assert — the heading is selected, not merely available.
    expect(find.text('أكياس'), findsOneWidget);
  });
}
