import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/orders/presentation/widgets/product_picker_sheet.dart';
import 'package:printing/features/products/models/product.dart';
import 'package:printing/features/products/presentation/widgets/product_gallery.dart';
import 'package:printing/features/products/repositories/product_repository.dart';
import 'package:printing/features/products/usecases/get_products.dart';

/// Choosing what goes on an order line — and recognising it by sight.
///
/// The picker used to be two lines of Arabic per row, so somebody who knows the shop's bags by
/// how they look had to read the catalogue to find one they could have pointed at. The picture
/// is what the row is now found by; the name and the size count still say what it is.
///
/// Arrange - Act - Assert throughout.
class _MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late _MockProductRepository products;

  /// What the sheet handed back, or null while nothing has been picked.
  PickedProduct? picked;

  ProductImage image({int id = 1, bool isPrimary = true}) => ProductImage(
    id: id,
    url: 'https://example.test/bag-$id.png',
    isPrimary: isPrimary,
    widthPx: 225,
    heightPx: 225,
  );

  Product product({
    int id = 1,
    String name = 'أكياس الشحن',
    List<ProductImage> images = const <ProductImage>[],
    List<ProductVariant> variants = const <ProductVariant>[],
  }) {
    return Product(
      id: id,
      code: 'P$id',
      slug: 'bag-$id',
      name: name,
      category: 'printed',
      categoryLabel: 'مطبوعة',
      pricingUnit: 'piece',
      pricingUnitLabel: 'قطعة',
      pricingMode: 'listed',
      pricingModeLabel: 'حسب القائمة',
      hasListedPrices: true,
      minOrderQuantity: '100.000',
      images: images,
      variants: variants.isEmpty
          ? const [
              ProductVariant(id: 11, label: '25*35'),
              ProductVariant(id: 12, label: '30*40'),
            ]
          : variants,
    );
  }

  void answerWith(List<Product> page) {
    when(
      () => products.products(
        search: any(named: 'search'),
        category: any(named: 'category'),
        pricingUnit: any(named: 'pricingUnit'),
        isActive: any(named: 'isActive'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => Right(
        Paginated<Product>(
          items: page,
          meta: PageMeta(
            currentPage: 1,
            perPage: 20,
            lastPage: 1,
            total: page.length,
          ),
        ),
      ),
    );
  }

  setUp(() async {
    await Injector.reset();

    picked = null;
    products = _MockProductRepository();
    sl.registerSingleton<GetProducts>(GetProducts(products));
  });

  tearDown(Injector.reset);

  /// The app's own frame — ScreenUtil at the reference size, Arabic, right to left — with a
  /// button that opens the sheet the way the order form does.
  Widget host({Set<int> addedVariantIds = const {}}) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              picked = await showProductPicker(
                context: context,
                addedVariantIds: addedVariantIds,
              );
            },
            child: const Text('افتح'),
          ),
        ),
      ),
    ),
  );

  Future<void> openThePicker(
    WidgetTester tester, {
    Set<int> addedVariantIds = const {},
  }) async {
    // A real phone, not the 800×600 the binding defaults to: every size below is a claim about
    // the widget, and at 800 wide against a 430 design ScreenUtil scales everything by 1.86.
    tester.view
      ..physicalSize = const Size(430 * 3, 932 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(addedVariantIds: addedVariantIds));
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
  }

  group('the catalogue step', () {
    testWidgets('every row carries the product’s picture', (tester) async {
      // Arrange
      answerWith([
        product(id: 1, name: 'أكياس الشحن', images: [image(id: 1)]),
        product(id: 2, name: 'أكياس هدايا فاخرة', images: [image(id: 2)]),
      ]);

      // Act
      await openThePicker(tester);

      // Assert — one per row, and the name is still there beside it.
      expect(find.byType(ProductThumbnail), findsNWidgets(2));
      expect(find.text('أكياس الشحن'), findsOneWidget);
    });

    testWidgets('a product with no picture keeps the column straight', (tester) async {
      // Arrange — a bag from before photographs were mandatory, next to one from after.
      answerWith([
        product(id: 1, name: 'أكياس الشحن', images: [image(id: 1)]),
        product(id: 2, name: 'awdawd'),
      ]);

      // Act
      await openThePicker(tester);

      // Assert — a placeholder square rather than a missing one, so the names below stay in
      // line and the list can be read down.
      final squares = tester
          .widgetList<ProductThumbnail>(find.byType(ProductThumbnail))
          .toList();
      expect(squares, hasLength(2));
      expect(squares.last.image, isNull);
    });

    testWidgets('every picture is the same square, whatever the row says', (tester) async {
      // Arrange — a long name and a short one: the picture is not what reflows for them.
      answerWith([
        product(id: 1, name: 'أكياس ورقية 3D (مقواة) بمقاسات كبيرة', images: [image(id: 1)]),
        product(id: 2, name: 'awdawd', images: [image(id: 2)]),
      ]);

      // Act
      await openThePicker(tester);

      // Assert
      final sizes = tester
          .renderObjectList<RenderBox>(find.byType(ProductThumbnail))
          .map((box) => box.size)
          .toSet();
      expect(sizes, hasLength(1));
      expect(sizes.single.width, sizes.single.height);
    });
  });

  group('on a screen that is not a phone', () {
    testWidgets('the picture is still square', (tester) async {
      // Arrange — a tablet, where ScreenUtil scales 48 up past the 56 that `ListTile` caps a
      // `leading` widget's height at while leaving its width alone. That cap is why this row is
      // a `Row`.
      tester.view
        ..physicalSize = const Size(800 * 2, 1200 * 2)
        ..devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      answerWith([product(id: 1, images: [image(id: 1)])]);

      // Act
      await tester.pumpWidget(host());
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();

      // Assert — a photograph that changes shape with the device is worse than none.
      final square = tester.getSize(find.byType(ProductThumbnail).first);
      expect(square.width, square.height);
    });
  });

  group('the size step', () {
    testWidgets('the picture follows the product into its sizes', (tester) async {
      // Arrange — two sizes, so the second step is actually asked.
      answerWith([product(id: 1, name: 'أكياس الشحن', images: [image(id: 1)])]);
      await openThePicker(tester);

      // Act
      await tester.tap(find.text('أكياس الشحن'));
      await tester.pumpAndSettle();

      // Assert — one picture, in the header beside the product's name: which bag is being sized
      // is the one thing this step assumes you still know.
      expect(find.text('25*35'), findsOneWidget);
      expect(find.byType(ProductThumbnail), findsOneWidget);
    });
  });

  /// **A size already on the order is shown and refused, not hidden.**
  ///
  /// Two lines of the same size are two lines the price ladder is climbed twice for: 100 and 200
  /// of one size are priced as 100 and as 200, never as the 300 the customer is actually buying.
  /// So the second one is stopped where it is chosen. Shown rather than dropped from the list,
  /// because a size that vanishes reads as «نفد» — and the answer the clerk needs is «it is
  /// already here, raise its quantity».
  group('a size that is already on the order', () {
    testWidgets('is offered greyed out and refuses the tap', (tester) async {
      // Arrange — 25*35 is on the order already; 30*40 is not.
      answerWith([product(id: 1, name: 'أكياس الشحن', images: [image(id: 1)])]);
      await openThePicker(tester, addedVariantIds: {11});
      await tester.tap(find.text('أكياس الشحن'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('25*35'));
      await tester.pumpAndSettle();

      // Assert — the sheet is still open, nothing was handed back, and the row says why.
      expect(picked, isNull);
      expect(find.text('مضاف — عدّل كميته من البنود'), findsOneWidget);
      expect(find.text('30*40'), findsOneWidget);
    });

    testWidgets('still lets the other sizes through', (tester) async {
      // Arrange
      answerWith([product(id: 1, name: 'أكياس الشحن', images: [image(id: 1)])]);
      await openThePicker(tester, addedVariantIds: {11});
      await tester.tap(find.text('أكياس الشحن'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('30*40'));
      await tester.pumpAndSettle();

      // Assert
      expect(picked?.variant.id, 12);
    });

    testWidgets('a one-size product is not waved through on the tap that picks it', (
      tester,
    ) async {
      // Arrange — the shortcut that skips the size step is exactly where a duplicate would slip
      // past: one size, and it is the one already on the order.
      answerWith([
        product(
          id: 1,
          name: 'أكياس الشحن',
          images: [image(id: 1)],
          variants: const [ProductVariant(id: 11, label: '25*35')],
        ),
      ]);
      await openThePicker(tester, addedVariantIds: {11});

      // Act
      await tester.tap(find.text('أكياس الشحن'));
      await tester.pumpAndSettle();

      // Assert — the size step opens instead, and says what is wrong rather than closing on
      // nothing.
      expect(picked, isNull);
      expect(find.text('مضاف — عدّل كميته من البنود'), findsOneWidget);
    });
  });
}
