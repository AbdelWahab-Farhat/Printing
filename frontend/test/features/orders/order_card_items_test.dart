import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_card.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/presentation/widgets/product_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// What is *in* the order, on the card that lists it.
///
/// The list said who, how much, where and when — and never what was ordered. «طلبية ٣٢٠٠ د.ل»
/// with no bag named on it is a row nobody can recognise without opening it, so the strip at the
/// foot of the card is the answer to «طلبية إيه؟» before the tap.
///
/// **بندٌ في سطر، ومعه مقاسه وكميته.** «أكياس الشحن السادة» وحده لا يقول كم منها ولا أيّ مقاس،
/// وطلبيةٌ من مقاسين تكتب الاسم نفسه مرتين فلا يُفرَّق بين سطريها إلا بالمقاس؛ والأسعار وحدها
/// تبقى في صفحة الطلبية.
///
/// **ولا صورة منتج بجانب الاسم.** كانت صورة الكتالوج تُرسم على كل سطر — الكيس الأبيض إيّاه على
/// كل بند من كل طلبية في المحل — فلا تميّز شيئاً وتزاحم الاسم. غلاف التصميم أخذ مكانها أعلى
/// الذيل، وله ملفّ اختبار خاص به: `order_card_design_cover_test.dart`.
///
/// **وما زاد عن بندين يُطوى.** بطاقة بخمسة أسطر تُخرج ما تحتها من الشاشة، فالاثنان الأولان
/// ظاهران دائماً والبقية خلف «عرض الكل».
///
/// Arrange - Act - Assert throughout.
void main() {
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

  OrderItem line(int id, String name, {ProductImage? image, String size = '25*35'}) => OrderItem(
    id: id,
    productId: id,
    productVariantId: id,
    productName: name,
    variantLabel: size,
    productImage: image,
    pricingUnitLabel: 'قطعة',
    quantity: '100.000',
    unitPrice: '1.000',
    lineTotal: '100.00',
  );

  Order orderWith(List<OrderItem>? items) => Order(
    id: 52,
    code: '52',
    status: OrderStatus.ready,
    statusLabel: 'جاهزة',
    isFinal: false,
    customerId: 5,
    cityId: 3,
    designSource: 'none',
    cityName: 'زليتن',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'بدون تصميم',
    itemsTotal: '430.00',
    designFee: '0.00',
    deliveryPrice: '20.00',
    discount: '0.00',
    grandTotal: '450.00',
    items: items,
  );

  const image = ProductImage(id: 1, url: 'https://example.test/bag.jpg', isPrimary: true);

  testWidgets('a line names itself, sizes itself and says how much of it', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(OrderCard(order: orderWith([line(1, 'أكياس الشحن السادة', image: image)]))),
    );

    // Act
    await tester.pump();

    // Assert — الاسم والمقاس والكمية بوحدتها، ولا صورة.
    expect(find.text('أكياس الشحن السادة'), findsOneWidget);
    expect(find.text('25*35'), findsOneWidget);
    expect(find.text('100 قطعة'), findsOneWidget);
    expect(find.byType(ProductThumbnail), findsNothing);
  });

  testWidgets('والمقاس هو ما يفرّق بين سطرين باسم واحد', (tester) async {
    // Arrange — «أكياس شحن ــ سادة» مرتين على طلبية واحدة: سطران لا يميّز بينهما شيء بلا
    // المقاس، وهو ما يُفتح السطر للسؤال عنه.
    final items = [
      line(1, 'أكياس شحن - سادة'),
      line(2, 'أكياس شحن - سادة', size: '30*40'),
    ];
    await tester.pumpWidget(host(OrderCard(order: orderWith(items))));

    // Act
    await tester.pump();

    // Assert
    expect(find.text('أكياس شحن - سادة'), findsNWidgets(2));
    expect(find.text('25*35'), findsOneWidget);
    expect(find.text('30*40'), findsOneWidget);
  });

  testWidgets('كل بند في سطره', (tester) async {
    // Arrange
    final items = [
      line(1, 'أكياس الشحن السادة', image: image),
      line(2, 'أكياس مطبوعة', image: image),
    ];
    await tester.pumpWidget(host(OrderCard(order: orderWith(items))));

    // Act
    await tester.pump();

    // Assert — سطران، ولا زرّ طيّ: بندان يسعهما ذيل البطاقة.
    expect(find.text('أكياس الشحن السادة'), findsOneWidget);
    expect(find.text('أكياس مطبوعة'), findsOneWidget);
    expect(find.textContaining('عرض الكل'), findsNothing);
  });

  testWidgets('ما زاد عن بندين يُطوى خلف زر', (tester) async {
    // Arrange — خمسة أنواع؛ الاثنان الأولان ظاهران والبقية معدودة على الزر.
    final items = [for (var id = 1; id <= 5; id++) line(id, 'منتج $id', image: image)];
    await tester.pumpWidget(host(OrderCard(order: orderWith(items))));

    // Act
    await tester.pump();

    // Assert
    expect(find.text('منتج 1'), findsOneWidget);
    expect(find.text('منتج 2'), findsOneWidget);
    expect(find.text('منتج 3'), findsNothing);
    expect(find.text('عرض الكل (5)'), findsOneWidget);
  });

  testWidgets('والزر يفتح البقية ثم يغلقها', (tester) async {
    // Arrange
    final items = [for (var id = 1; id <= 5; id++) line(id, 'منتج $id', image: image)];
    await tester.pumpWidget(host(OrderCard(order: orderWith(items))));

    // Act — فتح
    await tester.tap(find.text('عرض الكل (5)'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('منتج 5'), findsOneWidget);
    expect(find.text('إخفاء'), findsOneWidget);

    // Act — إغلاق. البطاقة المفتوحة أطول من شاشة الاختبار، فيُمرَّر إلى الزر قبل ضغطه.
    await tester.ensureVisible(find.text('إخفاء'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إخفاء'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('منتج 5'), findsNothing);
    expect(find.text('عرض الكل (5)'), findsOneWidget);
  });

  testWidgets('وفتح القائمة لا يفتح الطلبية', (tester) async {
    // Arrange — الزر داخل بطاقة كلّها ضغطةٌ واحدة تفتح الطلبية، وضغطته له وحده.
    var taps = 0;
    final items = [for (var id = 1; id <= 3; id++) line(id, 'منتج $id', image: image)];
    await tester.pumpWidget(
      host(OrderCard(order: orderWith(items), onTap: () => taps++)),
    );

    // Act
    await tester.tap(find.text('عرض الكل (3)'));
    await tester.pumpAndSettle();

    // Assert
    expect(taps, 0);
    expect(find.text('منتج 3'), findsOneWidget);
  });

  testWidgets('a photographed product draws no picture either', (tester) async {
    // Arrange — the catalogue's own photograph, which the card no longer has a slot for.
    await tester.pumpWidget(
      host(OrderCard(order: orderWith([line(1, 'أكياس الشحن السادة', image: image)]))),
    );

    // Act
    await tester.pump();

    // Assert — the name is the whole row, and it is the half of it that identifies the line.
    expect(find.text('أكياس الشحن السادة'), findsOneWidget);
    expect(find.byType(ProductThumbnail), findsNothing);
  });

  testWidgets('an order whose lines were not sent draws no strip', (tester) async {
    // Arrange — an older server, or a payload that carries no lines at all.
    await tester.pumpWidget(host(OrderCard(order: orderWith(null))));

    // Act
    await tester.pump();

    // Assert — the rest of the card is unchanged, and nothing empty is drawn under it.
    expect(find.text('#52'), findsOneWidget);
    expect(find.byType(ProductThumbnail), findsNothing);
  });

  testWidgets('the whole card still opens the order', (tester) async {
    // Arrange — the rows are something to read, not a second destination.
    var taps = 0;
    await tester.pumpWidget(
      host(
        OrderCard(
          order: orderWith([line(1, 'أكياس الشحن السادة', image: image)]),
          onTap: () => taps++,
        ),
      ),
    );

    // Act
    await tester.tap(find.text('أكياس الشحن السادة'));
    await tester.pump();

    // Assert
    expect(taps, 1);
  });
}
