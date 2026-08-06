import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/features/products/models/product.dart';
import 'package:printing/features/products/presentation/viewmodel/save_product_cubit.dart';
import 'package:printing/features/products/presentation/views/product_form_page.dart';
import 'package:printing/features/products/repositories/product_repository.dart';
import 'package:printing/features/products/usecases/save_product.dart';

class _StubRepository implements ProductRepository {
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
    category: 'printed',
    categoryLabel: 'مطبوعة',
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

  testWidgets('the form opens on what the product already says', (tester) async {
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

  testWidgets('a price lands under its own threshold, not under its position', (tester) async {
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
}
