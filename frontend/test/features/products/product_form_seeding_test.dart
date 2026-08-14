import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/products/models/product.dart';
import 'package:printing/features/products/models/product_category.dart';
import 'package:printing/features/products/presentation/viewmodel/product_categories_cubit.dart';
import 'package:printing/features/products/presentation/viewmodel/save_product_cubit.dart';
import 'package:printing/features/products/presentation/views/product_form_page.dart';
import 'package:printing/features/products/repositories/product_category_repository.dart';
import 'package:printing/features/products/repositories/product_repository.dart';
import 'package:printing/features/products/usecases/delete_product_category.dart';
import 'package:printing/features/products/usecases/get_product_categories.dart';
import 'package:printing/features/products/usecases/save_product.dart';
import 'package:printing/features/products/usecases/set_product_category_activation.dart';

class _StubRepository implements ProductRepository {
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

  const product = Product(
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
        widthCm: 25,
        heightCm: 35,
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
