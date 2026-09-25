import 'package:cached_network_image/cached_network_image.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/theme/theme.dart';
import 'package:dayaa_client/core/utils/bidi.dart';
import 'package:dayaa_client/features/catalog/models/product.dart';
import 'package:dayaa_client/features/catalog/presentation/viewmodel/product_detail_cubit.dart';
import 'package:dayaa_client/features/catalog/presentation/views/product_detail_page.dart';
import 'package:dayaa_client/features/catalog/repositories/catalog_repository.dart';
import 'package:dayaa_client/features/catalog/usecases/get_product.dart';
import 'package:dayaa_client/features/catalog/usecases/quote_price.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/cart_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// كتالوجٌ مزيّف يجيب عن السعر كما يجيب الخادم: الكسر الذي بلغته الكمية، والذي يليه، والباقي
/// إليه. يسجّل كل كميةٍ سُئل عنها وكل مقاس.
class _FakeCatalog implements CatalogRepository {
  _FakeCatalog(this.item);

  final Product item;
  final askedQuantities = <String>[];
  final askedSizes = <int>[];

  @override
  Future<Either<Failure, Product>> product(int id) async => Right(item);

  @override
  Future<Either<Failure, PriceQuote>> quote({
    required int productId,
    required int variantId,
    required String quantity,
  }) async {
    askedQuantities.add(quantity);
    askedSizes.add(variantId);

    final tiers = item.variants.firstWhere((variant) => variant.id == variantId).tiersInOrder;
    final amount = double.parse(quantity);
    final applied = tiers.lastWhere(
      (tier) => double.parse(tier.minQuantity) <= amount,
      orElse: () => tiers.first,
    );
    final nextIndex = tiers.indexOf(applied) + 1;
    final next = nextIndex < tiers.length ? tiers[nextIndex] : null;

    return Right(
      PriceQuote(
        quantity: quantity,
        unitPrice: applied.unitPrice,
        total: (amount * double.parse(applied.unitPrice)).toStringAsFixed(3),
        appliedTierMinQuantity: applied.minQuantity,
        nextTier: next == null
            ? null
            : NextTier(
                minQuantity: next.minQuantity,
                unitPrice: next.unitPrice,
                quantityToReach: (double.parse(next.minQuantity) - amount).toStringAsFixed(3),
              ),
      ),
    );
  }

  @override
  Future<Either<Failure, Paginated<Product>>> products({
    int page = 1,
    String? search,
    int? categoryId,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, List<ProductCategory>>> categories() => throw UnimplementedError();
}

const _photo = 'https://example.test/p1.jpg';

List<PriceTier> _tiers(List<String> prices) => [
  PriceTier(id: 1, minQuantity: '100.000', unitPrice: prices[0]),
  PriceTier(id: 2, minQuantity: '300.000', unitPrice: prices[1]),
  PriceTier(id: 3, minQuantity: '1000.000', unitPrice: prices[2]),
];

/// «أكياس شحن - مطبوعة» كما في قاعدة البيانات: بالقطعة من ١٠٠، وثلاثة كسور لكل مقاس.
final _printed = Product(
  id: 1,
  name: 'أكياس شحن - مطبوعة',
  code: 'P1',
  pricingUnit: 'piece',
  pricingUnitLabel: 'قطعة',
  minOrderQuantity: '100.000',
  variants: [
    ProductVariant(
      id: 10,
      label: 'صغير',
      widthCm: 25,
      heightCm: 35,
      priceTiers: _tiers(['1.130', '1.030', '0.880']),
    ),
    ProductVariant(
      id: 11,
      label: 'متوسط',
      widthCm: 35,
      heightCm: 40,
      priceTiers: _tiers(['1.410', '1.310', '1.160']),
    ),
  ],
);

/// «أكياس شفافه - ساده»: بالكيلو من ١، وسعرٌ واحد لكل مقاس.
const _plain = Product(
  id: 12,
  name: 'أكياس شفافه - ساده',
  code: 'P12',
  pricingUnit: 'kilogram',
  pricingUnitLabel: 'كجم',
  minOrderQuantity: '1.000',
  variants: [
    ProductVariant(
      id: 40,
      label: 'صغير جدا',
      widthCm: 20,
      heightCm: 26,
      priceTiers: [PriceTier(id: 9, minQuantity: '1.000', unitPrice: '49.000')],
    ),
    ProductVariant(
      id: 30,
      label: 'صغير',
      widthCm: 27,
      heightCm: 35,
      priceTiers: [PriceTier(id: 8, minQuantity: '1.000', unitPrice: '49.000')],
    ),
  ],
);

/// صفحة المنتج: الصورة التي تنطوي، والمقاسات في صفٍّ واحد، والكمية بسلايدر وزرّين، وبطاقات
/// الأسعار، وتفصيل السعر.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _FakeCatalog catalog;

  void register(Product product) {
    catalog = _FakeCatalog(product);

    sl
      ..registerFactory<ProductDetailCubit>(
        () => ProductDetailCubit(getProduct: GetProduct(catalog), quote: QuotePrice(catalog)),
      )
      ..registerLazySingleton<CartCubit>(CartCubit.new);
  }

  /// [animations] يُطفأ افتراضياً: الحركة لا تعني هذه الاختبارات إلا حيث تُختبر هي.
  Widget host({bool animations = false}) {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp(
        theme: const MaterialTheme(TextTheme()).dark(),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: !animations),
          child: child!,
        ),
        home: const ProductDetailPage(productId: 1),
      ),
    );
  }

  /// صورة المنتج من ذاكرة الصور مباشرة: الاختبار لا شبكة فيه ولا مخزن ملفات.
  Future<void> cachePhoto(WidgetTester tester) async {
    final image = await tester.runAsync(() => createTestImage(width: 8, height: 8));
    PaintingBinding.instance.imageCache.putIfAbsent(
      const CachedNetworkImageProvider(_photo),
      () => OneFrameImageStreamCompleter(SynchronousFuture(ImageInfo(image: image!))),
    );
  }

  bool isSelected(WidgetTester tester, String label) {
    final marks = find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.selected != null,
      ),
    );

    return tester.widget<Semantics>(marks.first).properties.selected!;
  }

  /// الرقم الكبير فوق السلايدر كما يُقرأ: «1,000 قطعة».
  String shownQuantity(WidgetTester tester) => tester
      .widget<Text>(find.byKey(const ValueKey('quantity-display')))
      .textSpan!
      .toPlainText();

  /// الرقم وحده، بلا فاصل الآلاف ولا الوحدة.
  double shownAmount(WidgetTester tester) =>
      double.parse(shownQuantity(tester).split(' ').first.replaceAll(',', ''));

  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(430, 932);
    view.devicePixelRatio = 1;
  });

  tearDown(() async {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
    PaintingBinding.instance.imageCache.clear();
    await sl.reset();
  });

  group('the photo', () {
    testWidgets('folds into a bar with the name once the page is scrolled', (tester) async {
      // Arrange
      register(
        _printed.copyWith(images: const [ProductImage(id: 1, url: _photo, isPrimary: true)]),
      );
      await cachePhoto(tester);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final before = tester.widget<Opacity>(find.byKey(const ValueKey('product-bar-title')));

      // Act
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Assert
      final after = tester.widget<Opacity>(find.byKey(const ValueKey('product-bar-title')));
      expect(before.opacity, 0);
      expect(after.opacity, 1);
    });

    testWidgets('a product with no photo opens on the bar alone', (tester) async {
      // Arrange
      register(_printed);

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert
      final bar = tester.widget<Opacity>(find.byKey(const ValueKey('product-bar-title')));
      expect(bar.opacity, 1);
    });
  });

  group('sizes', () {
    testWidgets('sit in one row, each with its measurements under its name', (tester) async {
      // Arrange
      register(_printed);

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('صغير'), findsOneWidget);
      expect(find.text('25×35'), findsOneWidget);
      expect(find.text('متوسط'), findsOneWidget);
      expect(find.text('35×40'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('صغير')).dy,
        tester.getTopLeft(find.text('متوسط')).dy,
      );
      expect(isSelected(tester, 'صغير'), isTrue);
    });

    testWidgets('tapping one picks it and prices it', (tester) async {
      // Arrange
      register(_printed);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('متوسط'));
      await tester.pumpAndSettle();

      // Assert
      expect(isSelected(tester, 'متوسط'), isTrue);
      expect(isSelected(tester, 'صغير'), isFalse);
      expect(catalog.askedSizes.last, 11);
    });

    testWidgets('a size named by its measurements shows them once', (tester) async {
      // Arrange
      register(
        _printed.copyWith(
          variants: [
            ProductVariant(
              id: 50,
              label: '30*30',
              widthCm: 30,
              heightCm: 30,
              priceTiers: _tiers(['1.720', '1.620', '1.470']),
            ),
            ProductVariant(
              id: 51,
              label: '40*40',
              widthCm: 40,
              heightCm: 40,
              priceTiers: _tiers(['2.250', '2.150', '2.000']),
            ),
          ],
        ),
      );

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert
      // الاسم معزولٌ عن ترتيب العربية حوله، فيُطابَق بعزله.
      expect(find.text('30*30'.bidiSafe), findsOneWidget);
      expect(find.text('30×30'), findsNothing);
    });

    testWidgets('a product that comes in one size shows no size row', (tester) async {
      // Arrange
      register(_printed.copyWith(variants: [_printed.variants.first]));

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('المقاس'), findsNothing);
    });
  });

  group('quantity', () {
    testWidgets('is counted in pieces for a product sold by the piece', (tester) async {
      // Arrange
      register(_printed);

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('بالقطعة'), findsOneWidget);
      expect(shownQuantity(tester), '100 قطعة');
      expect(find.text('2,000 قطعة'), findsOneWidget);
    });

    testWidgets('is weighed in kilograms for a product sold by weight', (tester) async {
      // Arrange
      register(_plain);

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('بالكجم'), findsOneWidget);
      expect(shownQuantity(tester), '1 كجم');
      expect(find.text('100 كجم'), findsOneWidget);
    });

    testWidgets('+ adds one step, and the number and the price follow', (tester) async {
      // Arrange
      register(_printed);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byTooltip('زيادة الكمية'));
      await tester.pumpAndSettle();

      // Assert
      expect(shownQuantity(tester), '150 قطعة');
      expect(catalog.askedQuantities.last, '150');
    });

    testWidgets('− cannot go below the minimum', (tester) async {
      // Arrange
      register(_printed);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act
      final minus = tester.widget<IconButton>(
        find.ancestor(of: find.byTooltip('إنقاص الكمية'), matching: find.byType(IconButton)),
      );

      // Assert
      expect(minus.onPressed, isNull);
    });

    testWidgets('dragging the slider asks for a price once, when it is let go', (tester) async {
      // Arrange
      register(_printed);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final before = catalog.askedQuantities.length;

      // Act
      await tester.drag(find.byType(Slider), const Offset(-120, 0));
      await tester.pumpAndSettle();

      // Assert
      expect(catalog.askedQuantities.length, before + 1);
      expect(shownAmount(tester), double.parse(catalog.askedQuantities.last));
      expect(shownAmount(tester), greaterThan(100));
    });

    testWidgets('sits centred above the slider, with no box around it', (tester) async {
      // Arrange
      register(_printed);

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert
      final number = tester.getRect(find.byKey(const ValueKey('quantity-display')));
      final slider = tester.getRect(find.byType(Slider));
      expect(number.center.dx, closeTo(slider.center.dx, 2));
      expect(number.bottom, lessThan(slider.top));
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('tapping the number opens a sheet to type one, and «تم» prices it', (
      tester,
    ) async {
      // Arrange
      register(_printed);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('quantity-display')));
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextField), '750');
      await tester.tap(find.text('تم'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(TextField), findsNothing);
      expect(catalog.askedQuantities.last, '750');
      expect(shownQuantity(tester), '750 قطعة');
      expect(find.text('أضف إلى السلة · 772.50 د.ل'), findsOneWidget);
    });

    testWidgets('the sheet will not take something that is not a quantity', (tester) async {
      // Arrange
      register(_printed);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final asked = catalog.askedQuantities.length;
      await tester.tap(find.byKey(const ValueKey('quantity-display')));
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextField), '0');
      await tester.tap(find.text('تم'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('أدخل كمية صحيحة'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(catalog.askedQuantities.length, asked);
    });
  });

  group('price breaks', () {
    testWidgets('show as cards, the one in force marked and the next one counted down', (
      tester,
    ) async {
      // Arrange
      register(_printed);

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('من 100'), findsOneWidget);
      expect(find.text('من 300'), findsOneWidget);
      expect(find.text('من 1,000'), findsOneWidget);
      expect(isSelected(tester, 'من 100'), isTrue);
      expect(isSelected(tester, 'من 300'), isFalse);
      expect(find.text('أضف 200'), findsOneWidget);
    });

    testWidgets('tapping one orders its threshold, and the last says it is the best', (
      tester,
    ) async {
      // Arrange
      register(_printed);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('من 1,000'));
      await tester.pumpAndSettle();

      // Assert
      expect(catalog.askedQuantities.last, '1000');
      expect(shownQuantity(tester), '1,000 قطعة');
      expect(isSelected(tester, 'من 1,000'), isTrue);
      expect(find.text('أفضل سعر'), findsOneWidget);
    });

    testWidgets('a product with a single price has no cards to show', (tester) async {
      // Arrange
      register(_plain);

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('من 1'), findsNothing);
      expect(find.textContaining(RegExp(r'^أضف \d')), findsNothing);
    });
  });

  group('the price', () {
    testWidgets('its total rides in the button, and there is no bill', (tester) async {
      // Arrange
      register(_printed);

      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('من 300'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('أضف إلى السلة · 309 د.ل'), findsOneWidget);
      expect(find.text('الإجمالي'), findsNothing);
      expect(find.text('سعر القطعة'), findsNothing);
    });

    testWidgets('a kilogram is priced per kilogram', (tester) async {
      // Arrange
      register(_plain);

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('سعر الكجم'), findsOneWidget);
      expect(find.text('49 د.ل'), findsOneWidget);
      expect(find.text('أضف إلى السلة · 49 د.ل'), findsOneWidget);
    });

    testWidgets('a product priced on request shows no bill and says so', (tester) async {
      // Arrange
      register(_printed.copyWith(hasListedPrices: false));

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('أضف إلى السلة'), findsOneWidget);
      expect(find.text('من 300'), findsNothing);
      expect(find.textContaining('يُسعَّر حسب الطلب'), findsOneWidget);
    });
  });

  testWidgets('the unit sits beside the name, on its left', (tester) async {
    // Arrange
    register(_printed);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    final name = tester.getRect(find.byKey(const ValueKey('product-title')));
    final unit = tester.getRect(find.text('بالقطعة'));
    expect(unit.center.dy, closeTo(name.center.dy, 4));
    expect(unit.center.dx, lessThan(name.center.dx));
  });

  /// أثناء السحب لم يُسأل الخادم بعد: الإجمالي في الزر يُرفع بدل أن يبقى رقماً لكميةٍ أخرى.
  testWidgets('the button drops its total while the thumb is moving, and shows it once let go', (
    tester,
  ) async {
    // Arrange
    register(_printed);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(tester.getCenter(find.byType(Slider)));
    await tester.pump();

    // Act
    await gesture.moveBy(const Offset(-60, 0));
    await tester.pump();
    final whileMoving = find.text('أضف إلى السلة').evaluate().length;
    await gesture.up();
    await tester.pumpAndSettle();

    // Assert
    expect(whileMoving, 1);
    expect(find.textContaining('أضف إلى السلة · '), findsOneWidget);
  });

  testWidgets('«أضف إلى السلة» puts the size and the quantity in the basket', (tester) async {
    // Arrange
    register(_printed);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.text('متوسط'));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.textContaining('أضف إلى السلة'));
    await tester.pumpAndSettle();
    final basket = sl<CartCubit>().state;
    final said = find.text('أُضيف إلى سلتك').evaluate().length;
    final flights = find.byKey(const ValueKey('cart-flight')).evaluate().length;
    // «أُضيف إلى سلتك» تبقى ثلاث ثوانٍ؛ مؤقّتها يُترك يكتمل قبل أن يُهدم الاختبار.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Assert
    expect(basket.count, 1);
    expect(basket.lines.single.line.productVariantId, 11);
    expect(basket.lines.single.line.quantity, '100.000');
    // بلا حركةٍ لا تطير الصورة، فيُقال بالكلمات.
    expect(flights, 0);
    expect(said, 1);
  });

  // «كجم أم قطعة؟» — السطر في السلة يقول الكمية بوحدتها (طلب المستخدم، 2026-09-25)، لا «الكمية
  // ١٠٠» التي لا يُعرف أهي أكياسٌ أم كيلوات.
  testWidgets('the basket line says its quantity in the product’s own unit', (tester) async {
    // Arrange
    register(_printed);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.text('متوسط'));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.textContaining('أضف إلى السلة'));
    await tester.pumpAndSettle();
    final line = sl<CartCubit>().state.lines.single;
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Assert
    expect(line.subtitle, 'متوسط · 100 قطعة');
  });

  testWidgets('with motion on, the photo flies to the basket and is gone once it lands', (
    tester,
  ) async {
    // Arrange
    register(_printed);
    await tester.pumpWidget(host(animations: true));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.textContaining('أضف إلى السلة'));
    await tester.pump(const Duration(milliseconds: 100));
    final inFlight = find.byKey(const ValueKey('cart-flight')).evaluate().length;
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Assert
    expect(inFlight, 1);
    expect(find.byKey(const ValueKey('cart-flight')), findsNothing);
    expect(find.text('أُضيف إلى سلتك'), findsNothing);
    expect(sl<CartCubit>().state.count, 1);
  });
}
