import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/customers/presentation/widgets/design_thumbnail.dart';
import 'package:dayaa/features/customers/presentation/widgets/design_viewer.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_card.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/presentation/widgets/product_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// **الغلاف على البطاقة: ما يُطبع، لا الكيس الأبيض.**
///
/// كانت كل بطاقة في القائمة تعرض صورة المنتج من الكتالوج — الكيس الأبيض نفسه على كل سطر من كل
/// طلبية في المحل — وهي أقل ما يميّز طلبيةً عن أخرى. التصميم هو ما يميّزها، فحلّ محلّها.
///
/// **وأكثر من تصميم يقف بجنب بعضه صغيراً.** «التصميم الأول» و«الثاني» على الطلبية الواحدة هما
/// الشعار وظهر الكيس بقدر ما هما مسوّدة وتصحيحها، فكلاهما يُعرض؛ ومربّعٌ واحد يصغر حين يصير
/// اثنين حتى لا يطول ذيل البطاقة بصفٍّ ثانٍ.
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

  CustomerDesign design({
    int id = 1,
    DesignKind kind = DesignKind.image,
    String? url = 'https://files.test/artwork-1.png',
  }) {
    return CustomerDesign(
      id: id,
      customerId: 5,
      label: 'شعار المحل',
      kind: kind,
      kindLabel: kind == DesignKind.image ? 'صورة' : 'PDF',
      fileUrl: url,
    );
  }

  OrderDesign version(int number, {String status = 'approved', CustomerDesign? file}) {
    return OrderDesign(
      id: number,
      version: number,
      status: status,
      statusLabel: status,
      design: file ?? design(id: number, url: 'https://files.test/artwork-$number.png'),
    );
  }

  OrderItem line(int id, String name, {ProductImage? image}) => OrderItem(
    id: id,
    productId: id,
    productVariantId: id,
    productName: name,
    variantLabel: '25*35',
    productImage: image,
    pricingUnitLabel: 'قطعة',
    quantity: '100.000',
    unitPrice: '1.000',
    lineTotal: '100.00',
  );

  Order orderWith({List<OrderItem>? items, List<OrderDesign>? designs}) => Order(
    id: 52,
    code: '52',
    status: OrderStatus.ready,
    statusLabel: 'جاهزة',
    isFinal: false,
    customerId: 5,
    cityId: 3,
    designSource: 'customer',
    cityName: 'زليتن',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'تصميم العميل',
    itemsTotal: '430.00',
    designFee: '0.00',
    deliveryPrice: '20.00',
    discount: '0.00',
    grandTotal: '450.00',
    items: items,
    designs: designs,
  );

  const photo = ProductImage(id: 7, url: 'https://files.test/bag.png', isPrimary: true);

  testWidgets('the card draws the design the order is printed from', (tester) async {
    // Arrange
    final order = orderWith(
      items: [line(1, 'أكياس الشحن السادة')],
      designs: [version(1)],
    );
    await tester.pumpWidget(host(OrderCard(order: order)));

    // Act
    await tester.pump();

    // Assert
    final cover = tester.widget<DesignThumbnail>(find.byType(DesignThumbnail));
    expect(cover.design.fileUrl, 'https://files.test/artwork-1.png');
  });

  testWidgets('أكثر من تصميم يقف بجنب بعضه، وأصغر', (tester) async {
    // Arrange — الشعار وظهر الكيس على الطلبية الواحدة.
    final order = orderWith(
      items: [line(1, 'أكياس مطبوعة')],
      designs: [version(1), version(2)],
    );
    await tester.pumpWidget(host(OrderCard(order: order)));

    // Act
    await tester.pump();

    // Assert — اثنان، وبالترتيب الذي اختيرا به، وكلٌّ أصغر من المربّع الواحد.
    final covers = tester.widgetList<DesignThumbnail>(find.byType(DesignThumbnail)).toList();
    expect(covers.map((cover) => cover.design.fileUrl), [
      'https://files.test/artwork-1.png',
      'https://files.test/artwork-2.png',
    ]);

    final single = tester.widget<DesignThumbnail>(
      find.descendant(
        of: find.byType(OrderCard),
        matching: find.byType(DesignThumbnail),
      ).first,
    );
    expect(single.size, lessThan(56));
  });

  testWidgets('a rejected version is not what the shop is printing', (tester) async {
    // Arrange — the customer turned the second one down, so the agreed one stands alone.
    final order = orderWith(
      items: [line(1, 'أكياس مطبوعة')],
      designs: [version(1), version(2, status: 'rejected')],
    );
    await tester.pumpWidget(host(OrderCard(order: order)));

    // Act
    await tester.pump();

    // Assert
    final cover = tester.widget<DesignThumbnail>(find.byType(DesignThumbnail));
    expect(cover.design.fileUrl, 'https://files.test/artwork-1.png');
  });

  testWidgets('a كيس سادة draws no cover, and no empty square either', (tester) async {
    // Arrange — nothing is printed, so there is nothing to show.
    final order = orderWith(items: [line(1, 'أكياس الشحن السادة')]);
    await tester.pumpWidget(host(OrderCard(order: order)));

    // Act
    await tester.pump();

    // Assert — the lines are still there, and no slot is held open for a picture that does not
    // exist.
    expect(find.text('أكياس الشحن السادة'), findsOneWidget);
    expect(find.byType(DesignThumbnail), findsNothing);
  });

  testWidgets('a PDF has nothing this card can draw', (tester) async {
    // Arrange — the print file itself, which no thumbnail can paint.
    final order = orderWith(
      items: [line(1, 'أكياس مطبوعة')],
      designs: [version(1, file: design(kind: DesignKind.pdf))],
    );
    await tester.pumpWidget(host(OrderCard(order: order)));

    // Act
    await tester.pump();

    // Assert
    expect(find.byType(DesignThumbnail), findsNothing);
  });

  testWidgets('صورة المنتج نُزعت من البطاقة', (tester) async {
    // Arrange — الكيس الأبيض نفسه على كل سطر من كل طلبية: صورةٌ لا تقول شيئاً عن الطلبية التي
    // هي تحتها، وقد أخذ التصميم مكانها.
    final order = orderWith(
      items: [line(1, 'أكياس الشحن السادة', image: photo), line(2, 'أكياس مطبوعة', image: photo)],
      designs: [version(1)],
    );
    await tester.pumpWidget(host(OrderCard(order: order)));

    // Act
    await tester.pump();

    // Assert — الأسماء والكميات كما كانت، ولا مربّع منتج على البطاقة.
    expect(find.text('أكياس الشحن السادة'), findsOneWidget);
    expect(find.text('100 قطعة'), findsNWidgets(2));
    expect(find.byType(ProductThumbnail), findsNothing);
  });

  testWidgets('a cover on an order with no lines still draws', (tester) async {
    // Arrange — a payload that carries the artwork and no lines.
    final order = orderWith(designs: [version(1)]);
    await tester.pumpWidget(host(OrderCard(order: order)));

    // Act
    await tester.pump();

    // Assert
    expect(find.byType(DesignThumbnail), findsOneWidget);
  });

  testWidgets('الضغط على الغلاف يفتح الملف نفسه', (tester) async {
    // Arrange — الغلاف صغير، وما يُطبع يُقرأ بالتقريب لا بالنظرة: من ضغط على الصورة أرادها.
    var taps = 0;
    final order = orderWith(items: [line(1, 'أكياس مطبوعة')], designs: [version(1)]);
    await tester.pumpWidget(host(OrderCard(order: order, onTap: () => taps++)));

    // Act — `pump` بمدة لا `pumpAndSettle`: العارض يدور مؤشّر تحميلٍ إلى أن تصل الصورة، وهي
    // في الاختبار لا تصل أبداً، فـ`pumpAndSettle` تنتظر سكوناً لا يأتي.
    await tester.tap(find.byType(DesignThumbnail));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Assert — العارض بملء الشاشة، والطلبية لم تُفتح تحته.
    expect(find.byType(DesignViewer), findsOneWidget);
    expect(taps, 0);
  });

  testWidgets('وما عداه من البطاقة يفتح الطلبية', (tester) async {
    // Arrange — الغلاف وحده هو الاستثناء؛ البطاقة كلها تبقى ضغطةً واحدة.
    var taps = 0;
    final order = orderWith(items: [line(1, 'أكياس مطبوعة')], designs: [version(1)]);
    await tester.pumpWidget(host(OrderCard(order: order, onTap: () => taps++)));

    // Act
    await tester.tap(find.text('أكياس مطبوعة'));
    await tester.pump();

    // Assert
    expect(taps, 1);
  });
}
