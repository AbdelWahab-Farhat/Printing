import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// بندٌ واحد من الطلبية، سطراً تحت صورة التصميم: المقاس وكم قطعة، لا أكثر.
///
/// كان البند بطاقةً تحمل صورة المنتج واسمه وسعر القطعة وتفصيل التكلفة وزرّ التلف. الاسم والصورة
/// صعدا إلى الشريط فوق التصميم — المنتج واحدٌ لبنودٍ كثيرة — وما يحتاجه من يدقّق فاتورةً (المبلغ،
/// سعر القطعة، التكلفة) أو يسجّل تلفاً صار في ورقة «⋯» البند نفسه.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// The same frame the app boots into: ScreenUtil at the reference size, Arabic, RTL.
  Widget host(Widget card) {
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
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(child: card),
          ),
        ),
      ),
    );
  }

  OrderItem line({
    String? shortage,
    String? billable,
    String? cogs,
    String? warehouseShortage,
    bool weighed = false,
    bool priced = true,
  }) => OrderItem(
    id: 11,
    productId: 7,
    productVariantId: 2,
    productName: 'أكياس الشحن السادة',
    variantLabel: 'سادة',
    pricingUnitLabel: 'كجم',
    quantity: '100.000',
    shortageQuantity: shortage,
    shortageWarehouseQuantity: warehouseShortage,
    // The shelf's unit, which only matters on the lines that carry a second figure.
    stockUnitLabel: 'قطعة',
    // Sold by the kilo off a piece-counted pile. `weighed` alone is the two-unit case with the
    // weight still unknown; pass `warehouseShortage` too for one somebody has since stated.
    isStockedInAnotherUnit: weighed || warehouseShortage != null,
    billableQuantity: billable,
    unitPrice: priced ? '32.000' : null,
    lineTotal: !priced ? null : (shortage == null ? '3200.00' : '2400.00'),
    materialCost: cogs == null ? null : '100.00',
    cogs: cogs,
  );

  /// يفتح ورقة البند من زرّ «⋯»، كما يفعل من يقرأ الشاشة.
  Future<void> openOptions(WidgetTester tester) async {
    await tester.tap(find.byTooltip('خيارات البند'));
    await tester.pumpAndSettle();
  }

  group('السطر', () {
    testWidgets('المقاس وكم قطعة، والمنتج لا يتكرّر عليه', (tester) async {
      // Arrange
      await tester.pumpWidget(host(OrderItemCard(item: line(), showCosts: false)));

      // Act
      await tester.pump();

      // Assert — اسم المنتج على الشريط فوق الصورة، مرةً لكل البنود.
      expect(find.text('سادة'), findsOneWidget);
      expect(find.text('100 كجم'), findsOneWidget);
      expect(find.text('أكياس الشحن السادة'), findsNothing);
    });

    testWidgets('لا مال على السطر، ولو لمن يملك التكلفة', (tester) async {
      // Arrange — السطر لمن يطبع: المقاس وكم قطعة. المبلغ والتكلفة في ورقة «⋯».
      await tester.pumpWidget(host(OrderItemCard(item: line(cogs: '150.00'), showCosts: true)));

      // Act
      await tester.pump();

      // Assert
      expect(find.textContaining('3,200'), findsNothing);
      expect(find.textContaining('التكلفة'), findsNothing);
    });
  });

  group('the shortage stays on the line it is missing from', () {
    testWidgets('what is missing is said on the line it is missing from', (tester) async {
      // Arrange
      final item = line(shortage: '25.000', billable: '75.000');
      await tester.pumpWidget(host(OrderItemCard(item: item, showCosts: false)));

      // Act
      await tester.pump();

      // Assert — the press makes what is left, and «ناقص من كم» is answered on the same line.
      expect(find.text('75 كجم'), findsOneWidget);
      expect(find.text('ناقص: 25 من 100 كجم — غير محتسب'), findsOneWidget);
    });

    testWidgets('a line stocked in another unit says what has to be bought', (tester) async {
      // Arrange — sold by the kilo off a pile counted by the piece, so the gap is two numbers.
      final item = line(shortage: '25.000', billable: '75.000', warehouseShortage: '6.000');
      await tester.pumpWidget(host(OrderItemCard(item: item, showCosts: false)));

      // Act
      await tester.pump();

      // Assert — the invoice's figure and the warehouse's, one under the other.
      expect(find.text('ناقص: 25 من 100 كجم — غير محتسب'), findsOneWidget);
      expect(find.text('ناقص من المخزن: 6 قطعة — هذا ما يُشترى'), findsOneWidget);
    });

    testWidgets('a line whose weight nobody knows yet says so', (tester) async {
      // Arrange — sold by the kilo off a piece-counted pile, and nobody has stated the weight.
      final item = line(shortage: '25.000', billable: '75.000', weighed: true);
      await tester.pumpWidget(host(OrderItemCard(item: item, showCosts: false)));

      // Act
      await tester.pump();

      // Assert
      expect(find.text('الوزن من المخزن غير محدد — حدِّده قبل تسجيل الشراء'), findsOneWidget);
    });

    testWidgets('a line stocked in its own unit says it once', (tester) async {
      // Arrange — the ordinary case: the server sends no second figure, because there is not one.
      final item = line(shortage: '25.000', billable: '75.000');
      await tester.pumpWidget(host(OrderItemCard(item: item, showCosts: false)));

      // Act
      await tester.pump();

      // Assert
      expect(find.text('ناقص: 25 من 100 كجم — غير محتسب'), findsOneWidget);
      expect(find.textContaining('من المخزن:'), findsNothing);
    });
  });

  group('ورقة «⋯»', () {
    testWidgets('فيها المبلغ، وسعر القطعة الذي يُدقَّق به', (tester) async {
      // Arrange
      await tester.pumpWidget(host(OrderItemCard(item: line(), showCosts: false)));

      // Act
      await openOptions(tester);

      // Assert
      expect(find.text('100 كجم × 32'), findsOneWidget);
      expect(find.text('3,200'), findsOneWidget);
    });

    testWidgets('بندٌ لم يُسعَّر يقول ذلك مكان السعر', (tester) async {
      // Arrange — منتجٌ «حسب الطلب» قبل أن يسعّره المراجع.
      await tester.pumpWidget(host(OrderItemCard(item: line(priced: false), showCosts: false)));

      // Act
      await openOptions(tester);

      // Assert
      expect(find.text('100 كجم غير مسعّر'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('وتفصيل التكلفة لمن يملكها', (tester) async {
      // Arrange
      await tester.pumpWidget(host(OrderItemCard(item: line(cogs: '150.00'), showCosts: true)));

      // Act
      await openOptions(tester);

      // Assert
      expect(find.text('التكلفة 150 — مواد 100'), findsOneWidget);
    });

    testWidgets('ولا تكلفة فيها لمن لا يملكها', (tester) async {
      // Arrange
      await tester.pumpWidget(host(OrderItemCard(item: line(cogs: '150.00'), showCosts: false)));

      // Act
      await openOptions(tester);

      // Assert
      expect(find.textContaining('التكلفة'), findsNothing);
    });

    testWidgets('الضغط على السطر يفتحها كذلك', (tester) async {
      // Arrange — the row is the bigger target, and a thumb at the press finds it first.
      await tester.pumpWidget(host(OrderItemCard(item: line(), showCosts: false)));

      // Act
      await tester.tap(find.text('100 كجم'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('100 كجم × 32'), findsOneWidget);
    });

    testWidgets('تسجيل التلف منها، وتُغلق بعده', (tester) async {
      // Arrange
      var scraps = 0;
      await tester.pumpWidget(
        host(OrderItemCard(item: line(), showCosts: false, onScrap: () => scraps++)),
      );
      await openOptions(tester);

      // Act
      await tester.tap(find.text('تسجيل تلف'));
      await tester.pumpAndSettle();

      // Assert
      expect(scraps, 1);
      expect(find.text('تسجيل تلف'), findsNothing);
    });

    testWidgets('لا تلف معروض، لا صفّ له', (tester) async {
      // Arrange
      await tester.pumpWidget(host(OrderItemCard(item: line(), showCosts: false)));

      // Act
      await openOptions(tester);

      // Assert
      expect(find.text('تسجيل تلف'), findsNothing);
    });

    testWidgets('فتح المنتج منها', (tester) async {
      // Arrange
      var opened = 0;
      await tester.pumpWidget(
        host(OrderItemCard(item: line(), showCosts: false, onOpenProduct: () => opened++)),
      );
      await openOptions(tester);

      // Act
      await tester.tap(find.text('فتح المنتج'));
      await tester.pumpAndSettle();

      // Assert
      expect(opened, 1);
    });

    testWidgets('بلا `products.view` لا يُعرض فتح المنتج', (tester) async {
      // Arrange — a door onto a 403 is worse than no door.
      await tester.pumpWidget(host(OrderItemCard(item: line(), showCosts: false)));

      // Act
      await openOptions(tester);

      // Assert
      expect(find.text('فتح المنتج'), findsNothing);
    });
  });

  testWidgets('تكلفة المورد الناقصة تبقى ظاهرةً على السطر', (tester) async {
    // Arrange — ربح الطلبية مجهولٌ حتى تُسجَّل، فهي مهمّةٌ معلّقة لا خيارٌ يُخفى في ورقة.
    var recorded = 0;
    await tester.pumpWidget(
      host(OrderItemCard(item: line(), showCosts: false, onVendorCost: () => recorded++)),
    );

    // Act
    await tester.tap(find.text('تسجيل تكلفة المورد'));
    await tester.pumpAndSettle();

    // Assert
    expect(recorded, 1);
  });
}
