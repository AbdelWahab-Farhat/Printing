import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_item_card.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/presentation/widgets/product_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// One line of an order, as a card that names the product and opens it.
///
/// A line used to be two lines of text: what it is, and what it costs. The product it was sold
/// from was a name on the invoice and nothing more — anybody who wanted the size chart, the
/// price tiers or the photograph went to the products tab and searched for a word they had just
/// read. The line now carries the product's own card, and the card is the door.
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
    String? code,
    ProductImage? image,
  }) => OrderItem(
    id: 11,
    productId: 7,
    productVariantId: 2,
    productName: 'أكياس الشحن السادة',
    variantLabel: 'سادة',
    productCode: code,
    productImage: image,
    pricingUnitLabel: 'كيلوغرام',
    quantity: '100.000',
    shortageQuantity: shortage,
    billableQuantity: billable,
    unitPrice: '32.000',
    lineTotal: shortage == null ? '3200.00' : '2400.00',
    materialCost: cogs == null ? null : '100.00',
    cogs: cogs,
  );

  testWidgets('the product names itself on the line it was sold on', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderItemCard(item: line(), showCosts: false)));

    // Act
    await tester.pump();

    // Assert — the product and the variant are two facts, not one string with a dash in it.
    expect(find.text('أكياس الشحن السادة'), findsOneWidget);
    expect(find.text('سادة'), findsOneWidget);
  });

  testWidgets('the catalogue row shows its own face on the line', (tester) async {
    // Arrange — the code people say down the phone, and the one photograph.
    const image = ProductImage(id: 3, url: 'https://example.test/bag.jpg', isPrimary: true);
    await tester.pumpWidget(
      host(OrderItemCard(item: line(code: 'P7', image: image), showCosts: false)),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.text('P7'), findsOneWidget);
    expect(find.byType(ProductThumbnail), findsOneWidget);
  });

  testWidgets('a product with no photograph leaves the slot empty', (tester) async {
    // Arrange — most of the catalogue, most of the time. A tinted glyph on every line would put
    // the same shape down the whole column until the eye learned to skip it.
    await tester.pumpWidget(host(OrderItemCard(item: line(code: 'P7'), showCosts: false)));

    // Act
    await tester.pump();

    // Assert
    expect(find.byType(ProductThumbnail), findsNothing);
    expect(find.text('P7'), findsOneWidget);
  });

  testWidgets('a line whose product did not come with it still reads', (tester) async {
    // Arrange — the list payload carries no product, and neither does an older server.
    await tester.pumpWidget(host(OrderItemCard(item: line(), showCosts: false)));

    // Act
    await tester.pump();

    // Assert — the snapshot alone, which is what an invoice is made of anyway.
    expect(find.text('أكياس الشحن السادة'), findsOneWidget);
    expect(find.byType(ProductThumbnail), findsNothing);
  });

  testWidgets('the three numbers an invoice is checked by are still on the line', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderItemCard(item: line(), showCosts: false)));

    // Act
    await tester.pump();

    // Assert
    expect(find.text('100 كيلوغرام × 32'), findsOneWidget);
    expect(find.text('3,200'), findsOneWidget);
  });

  testWidgets('a tap opens the product', (tester) async {
    // Arrange
    var opened = 0;
    await tester.pumpWidget(
      host(OrderItemCard(item: line(), showCosts: false, onOpenProduct: () => opened++)),
    );

    // Act
    await tester.tap(find.text('أكياس الشحن السادة'));
    await tester.pump();

    // Assert
    expect(opened, 1);
  });

  testWidgets('without a way in, nothing on the card offers one', (tester) async {
    // Arrange — somebody without `products.view` reads the line and is promised no screen that
    // would answer 403.
    await tester.pumpWidget(host(OrderItemCard(item: line(), showCosts: false)));

    // Act
    await tester.pump();

    // Assert
    expect(find.byKey(OrderItemCard.chevronKey), findsNothing);
  });

  testWidgets('a way in is advertised by the chevron', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(OrderItemCard(item: line(), showCosts: false, onOpenProduct: () {})),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.byKey(OrderItemCard.chevronKey), findsOneWidget);
  });

  testWidgets('recording a scrap does not also walk off to the product', (tester) async {
    // Arrange — the button sits inside a card that navigates, and a foreman reporting a spoiled
    // bag must not land on the catalogue instead.
    var opened = 0;
    var scraps = 0;
    await tester.pumpWidget(
      host(
        OrderItemCard(
          item: line(),
          showCosts: false,
          onOpenProduct: () => opened++,
          onScrap: () => scraps++,
        ),
      ),
    );

    // Act
    await tester.tap(find.text('تسجيل تلف'));
    await tester.pump();

    // Assert
    expect(scraps, 1);
    expect(opened, 0);
  });

  testWidgets('no scrap on offer draws no button', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderItemCard(item: line(), showCosts: false)));

    // Act
    await tester.pump();

    // Assert
    expect(find.text('تسجيل تلف'), findsNothing);
  });

  testWidgets('what is missing is said on the line it is missing from', (tester) async {
    // Arrange
    final item = line(shortage: '25.000', billable: '75.000');
    await tester.pumpWidget(host(OrderItemCard(item: item, showCosts: false)));

    // Act
    await tester.pump();

    // Assert — priced on what is left, and «ناقص من كم» answered on the same line.
    expect(find.text('75 كيلوغرام × 32'), findsOneWidget);
    expect(find.text('ناقص: 25 من 100 كيلوغرام — غير محتسب'), findsOneWidget);
  });

  testWidgets('what the line cost is drawn only for those who may read it', (tester) async {
    // Arrange
    final item = line(cogs: '150.00');

    // Act — first without the grant, then with it.
    await tester.pumpWidget(host(OrderItemCard(item: item, showCosts: false)));
    await tester.pump();
    final hidden = find.textContaining('التكلفة').evaluate().isEmpty;

    await tester.pumpWidget(host(OrderItemCard(item: item, showCosts: true)));
    await tester.pump();

    // Assert
    expect(hidden, isTrue);
    expect(find.textContaining('التكلفة'), findsOneWidget);
  });
}
