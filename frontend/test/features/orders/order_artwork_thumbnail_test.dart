import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_item_card.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/presentation/widgets/product_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// **What the line shows a picture of: the bags, or what is being printed on them.**
///
/// A printed order's rows used to show the catalogue photograph — the same anonymous white bag
/// on every line of every order in the shop. The thing that tells one order from another is the
/// artwork, and it was already on the payload: the screen simply drew the other picture.
///
/// So when an order carries a design, that is what the line shows. A كيس سادة carries none and
/// shows the product exactly as before — which is not a special case in the code, only the
/// absence of an answer.
///
/// **A PDF is not drawn.** The kind comes decided from the server precisely so nothing here
/// tries to paint a print file into a 52-pixel square, and the product photograph is the honest
/// thing to show instead of a grey box.
///
/// Arrange - Act - Assert throughout.
void main() {
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

  OrderDesign version(
    int number, {
    String status = 'approved',
    CustomerDesign? file,
  }) {
    return OrderDesign(
      id: number,
      version: number,
      status: status,
      statusLabel: status,
      design: file ?? design(id: number, url: 'https://files.test/artwork-$number.png'),
    );
  }

  Order orderWith({List<OrderDesign>? designs}) {
    return Order(
      id: 52,
      code: '52',
      status: OrderStatus.printing,
      statusLabel: 'قيد الطباعة',
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
      paidAmount: '0.00',
      remainingAmount: '450.00',
      paymentStatus: PaymentStatus.unpaid,
      paymentStatusLabel: 'غير مدفوعة',
      designs: designs,
    );
  }

  group('which picture the order has to show', () {
    test('the artwork, when one version has been attached', () {
      // Arrange
      final order = orderWith(designs: [version(1)]);

      // Act
      final artwork = order.artwork;

      // Assert
      expect(artwork?.fileUrl, 'https://files.test/artwork-1.png');
    });

    test('the newest version, because that is the last word on it', () {
      // Arrange — the conversation, in the order it happened.
      final order = orderWith(designs: [version(1), version(3), version(2)]);

      // Act
      final artwork = order.artwork;

      // Assert
      expect(artwork?.fileUrl, 'https://files.test/artwork-3.png');
    });

    test('a rejected version is not what the shop is printing', () {
      // Arrange — the customer turned the latest one down, so the agreed one stands.
      final order = orderWith(
        designs: [version(1), version(2, status: 'rejected')],
      );

      // Act
      final artwork = order.artwork;

      // Assert
      expect(artwork?.fileUrl, 'https://files.test/artwork-1.png');
    });

    test('a PDF has nothing this screen can draw', () {
      // Arrange
      final order = orderWith(
        designs: [version(1, file: design(kind: DesignKind.pdf))],
      );

      // Act - Assert — null rather than a URL nothing can paint. The line falls back to the
      // product photograph, which is a picture rather than a broken square.
      expect(order.artwork, isNull);
    });

    test('a design whose link did not come with the payload is not one either', () {
      // Arrange — a list endpoint that never loaded the file behind the version.
      final order = orderWith(designs: [version(1, file: design(url: null))]);

      // Act - Assert
      expect(order.artwork, isNull);
    });

    test('a كيس سادة has none, and that is not a special case', () {
      // Arrange — nothing was ever attached, because nothing is printed.
      final order = orderWith();

      // Act - Assert
      expect(order.artwork, isNull);
    });
  });

  /// **وقد تكون الطلبية الواحدة أكثر من ملف.** «التصميم الأول» و«الثاني» هما الشعار وظهر الكيس
  /// بقدر ما هما مسوّدة وتصحيحها — والجدول لا يفرّق بينهما — فتُعرض كلّها على البطاقة بجانب
  /// بعضها، بالترتيب الذي اختيرت به.
  group('كل ما يُطبع على الطلبية', () {
    test('بالترتيب الذي اختير به، لا معكوساً', () {
      // Arrange — الخادم يرسل الأحدث أولاً؛ والصفّ يُقرأ كما اختاره الموظف.
      final order = orderWith(designs: [version(3), version(2), version(1)]);

      // Act
      final artworks = order.artworks;

      // Assert
      expect(artworks.map((design) => design.fileUrl), [
        'https://files.test/artwork-1.png',
        'https://files.test/artwork-2.png',
        'https://files.test/artwork-3.png',
      ]);
    });

    test('والمرفوض ليس منها', () {
      // Arrange
      final order = orderWith(
        designs: [version(1), version(2, status: 'rejected'), version(3)],
      );

      // Act
      final artworks = order.artworks;

      // Assert
      expect(artworks.map((design) => design.fileUrl), [
        'https://files.test/artwork-1.png',
        'https://files.test/artwork-3.png',
      ]);
    });

    test('وكيسٌ سادة قائمةٌ فارغة، لا null', () {
      // Arrange — شاشةٌ تدور على القائمة لا تحتاج حالةً خاصة لغيابها.
      final order = orderWith();

      // Act - Assert
      expect(order.artworks, isEmpty);
    });
  });

  group('the line on the order screen', () {
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

    OrderItem line({ProductImage? image}) {
      return OrderItem(
        id: 11,
        productId: 3,
        productVariantId: 2,
        productName: 'كيس شحن مطبوع',
        variantLabel: '25*35',
        quantity: '500.000',
        unitPrice: '0.86',
        lineTotal: '430.00',
        pricingUnitLabel: 'قطعة',
        productImage: image,
      );
    }

    const photo = ProductImage(id: 7, url: 'https://files.test/bag.png');

    testWidgets('draws the artwork in place of the catalogue photograph', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(
          OrderItemCard(
            item: line(image: photo),
            showCosts: false,
            artworkUrl: 'https://files.test/artwork-1.png',
          ),
        ),
      );

      // Act
      final thumbnail = tester.widget<ProductThumbnail>(find.byType(ProductThumbnail));

      // Assert — one square, showing what is being printed rather than the same white bag
      // every printed order in the shop would otherwise show.
      expect(thumbnail.url, 'https://files.test/artwork-1.png');
    });

    testWidgets('falls back to the product when there is no artwork', (tester) async {
      // Arrange — a كيس سادة, or a printed order whose file has not arrived yet.
      await tester.pumpWidget(host(OrderItemCard(item: line(image: photo), showCosts: false)));

      // Act
      final thumbnail = tester.widget<ProductThumbnail>(find.byType(ProductThumbnail));

      // Assert
      expect(thumbnail.url, 'https://files.test/bag.png');
    });

    testWidgets('a product with no photograph still shows the artwork', (tester) async {
      // Arrange — the square used to be drawn only when the product had a picture, so an
      // unphotographed product hid a design nobody could otherwise see on this screen.
      await tester.pumpWidget(
        host(
          OrderItemCard(
            item: line(),
            showCosts: false,
            artworkUrl: 'https://files.test/artwork-1.png',
          ),
        ),
      );

      // Act - Assert
      expect(find.byType(ProductThumbnail), findsOneWidget);
    });

    testWidgets('a line with neither draws no square at all', (tester) async {
      // Arrange
      await tester.pumpWidget(host(OrderItemCard(item: line(), showCosts: false)));

      // Act - Assert — unchanged: an empty grey box beside the name says nothing.
      expect(find.byType(ProductThumbnail), findsNothing);
    });
  });
}
