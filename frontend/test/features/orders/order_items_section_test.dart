import 'package:dayaa/core/widgets/image_viewer.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_item_card.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_items_section.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_product_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «البنود» كما يقرؤها من يطبع: التصميم كبيراً، واسم المنتج وعدد قطعه فوقه، وتحته سطرٌ لكل مقاس.
///
/// كانت كل بندٍ بطاقةً تكرّر اسم المنتج وصورةً صغيرة بحجم إصبع، والسعر والتكلفة وزرّ التلف في
/// كل واحدة — فمن يقف عند المطبعة يبحث عن «كم قطعة من أي مقاس» بين أربعة أسطر من المال.
///
/// Arrange - Act - Assert throughout.
void main() {
  Widget host(Widget section) {
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
            child: SingleChildScrollView(child: section),
          ),
        ),
      ),
    );
  }

  OrderItem line({
    required int id,
    int productId = 2,
    String productName = 'أكياس يد خارجية - مطبوعه',
    String size = '40*40',
    String quantity = '100.000',
    String? billable,
    String? shortage,
    String unit = 'قطعة',
  }) => OrderItem(
    id: id,
    productId: productId,
    productVariantId: id,
    productName: productName,
    variantLabel: size,
    productCode: 'P$productId',
    pricingUnitLabel: unit,
    quantity: quantity,
    billableQuantity: billable,
    shortageQuantity: shortage,
    unitPrice: '2.250',
    lineTotal: '225.00',
  );

  group('البنود مجموعةٌ لكل منتج', () {
    test('بنود المنتج الواحد مجموعةٌ واحدة، بترتيب أخذها', () {
      // Arrange
      final items = [line(id: 1), line(id: 2, size: '30*40'), line(id: 3, size: '25*35')];

      // Act
      final groups = OrderProductGroup.of(items);

      // Assert
      expect(groups, hasLength(1));
      expect(groups.single.items.map((item) => item.id), [1, 2, 3]);
    });

    test('منتجٌ ثانٍ يبدأ مجموعته بعد الأول، ولو تفرّقت بنوده', () {
      // Arrange — من أدخل الطلبية لم يرتّبها بالمنتج، والشريط فوق الصورة يسمّي منتجاً واحداً.
      final items = [line(id: 1), line(id: 2, productId: 5), line(id: 3)];

      // Act
      final groups = OrderProductGroup.of(items);

      // Assert
      expect(groups.map((group) => group.items.map((item) => item.id).toList()), [
        [1, 3],
        [2],
      ]);
    });

    test('العدد يجمع ما سيُصنع، بوحدة البنود', () {
      // Arrange
      final group = OrderProductGroup.of([
        line(id: 1),
        line(id: 2, quantity: '200.000'),
        line(id: 3, quantity: '150.000'),
      ]).single;

      // Act
      final count = group.count;

      // Assert
      expect(count, '450 قطعة');
    });

    test('البند الناقص يُعدّ بما بقي منه', () {
      // Arrange — نقص أربعون من المئة، فالمطبعة تطبع ستين لا مئة.
      final group = OrderProductGroup.of([
        line(id: 1, shortage: '40.000', billable: '60.000'),
        line(id: 2, quantity: '200.000'),
      ]).single;

      // Act
      final count = group.count;

      // Assert
      expect(count, '260 قطعة');
    });

    test('وحدتان مختلفتان لا تُجمعان', () {
      // Arrange — قطعٌ وكيلوات معاً رقمٌ لا معنى له.
      final group = OrderProductGroup.of([
        line(id: 1),
        line(id: 2, quantity: '12.500', unit: 'كجم'),
      ]).single;

      // Act
      final count = group.count;

      // Assert
      expect(count, isNull);
    });
  });

  group('الشريط فوق الصورة', () {
    testWidgets('يحمل رمز المنتج واسمه وعدد قطعه', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(
          OrderItemsSection(
            items: [line(id: 1), line(id: 2, quantity: '200.000', size: '30*40')],
            showCosts: false,
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert — الاسم مرةً واحدة فوق الصورة، لا على كل سطر.
      expect(find.text('P2 أكياس يد خارجية - مطبوعه'), findsOneWidget);
      expect(find.text('300 قطعة'), findsOneWidget);
      expect(find.byType(OrderItemCard), findsNWidgets(2));
    });

    testWidgets('الاسم كاملاً، لا يُقصّ', (tester) async {
      // Arrange — «أكياس يد خارجية - مطبوعه» لا يسعها سطرٌ واحد بجانب العدد على هاتفٍ صغير.
      await tester.pumpWidget(host(OrderItemsSection(items: [line(id: 1)], showCosts: false)));

      // Act
      final name = tester.widget<Text>(find.text('P2 أكياس يد خارجية - مطبوعه'));

      // Assert
      expect(name.maxLines, isNull);
      expect(name.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets('منتجان، شريطان', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(
          OrderItemsSection(
            items: [line(id: 1), line(id: 2, productId: 5, productName: 'كيس سادة')],
            showCosts: false,
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.byType(OrderProductBanner), findsNWidgets(2));
      expect(find.text('P5 كيس سادة'), findsOneWidget);
    });

    testWidgets('الضغط على الصورة يفتح التصاميم كاملةً، على أحدثها', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(
          OrderItemsSection(
            items: [line(id: 1)],
            showCosts: false,
            artworkUrls: const ['https://files.test/v1.png', 'https://files.test/v2.png'],
          ),
        ),
      );

      // Act
      await tester.tap(find.byKey(OrderProductBanner.enlargeKey));
      // ضغطٌ ثم انتظار الانتقال، لا `pumpAndSettle`: مؤشّر التحميل في العارض لا يتوقف.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final viewer = tester.widget<ImageViewerPage>(find.byType(ImageViewerPage));

      // Assert
      expect(viewer.urls, ['https://files.test/v1.png', 'https://files.test/v2.png']);
      expect(viewer.initialIndex, 1);
    });

    testWidgets('بلا صورةٍ لا زرّ تكبير', (tester) async {
      // Arrange
      await tester.pumpWidget(host(OrderItemsSection(items: [line(id: 1)], showCosts: false)));

      // Act
      await tester.pump();

      // Assert
      expect(find.byKey(OrderProductBanner.enlargeKey), findsNothing);
      expect(find.text('P2 أكياس يد خارجية - مطبوعه'), findsOneWidget);
    });
  });

  testWidgets('الوزن تحت البنود كما كان', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(OrderItemsSection(items: [line(id: 1)], showCosts: false, weight: '13.6 كجم')),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.text('وزن الطلبية'), findsOneWidget);
    expect(find.text('13.6 كجم'), findsOneWidget);
  });
}
