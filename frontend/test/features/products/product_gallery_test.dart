import 'package:cached_network_image/cached_network_image.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/presentation/widgets/product_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a product looks like on the screen that exists to show it.
///
/// The gallery used to be a 240-wide strip that scrolled sideways, so on a 430-wide phone the
/// photograph occupied a little over half the width and the rest was the next photograph's edge.
/// A product screen's first job is the product, so the picture takes the width it is given.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// A real phone, not the 800×600 the test binding defaults to.
  ///
  /// Every assertion here is about how much of the width a photograph takes, and at 800 wide
  /// against a 430 design ScreenUtil scales everything by 1.86 — so the numbers below would be
  /// arithmetic about the test harness rather than about the widget.
  void useAPhone(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(430 * 3, 932 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  /// The same frame the app boots into: ScreenUtil at the reference size, RTL.
  Widget host(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }

  ProductImage image({
    int id = 1,
    bool isPrimary = false,
    int sortOrder = 0,
    String? url,
  }) {
    return ProductImage(
      id: id,
      url: url ?? 'https://example.test/bag-$id.png',
      isPrimary: isPrimary,
      sortOrder: sortOrder,
      widthPx: 225,
      heightPx: 225,
      sizeBytes: 28 * 1024,
    );
  }

  group('the order pictures are shown in', () {
    test('the primary picture leads, whatever order the server sent', () {
      // Arrange — the primary arrives last, which is the case the old sort existed for.
      final images = [
        image(id: 1, sortOrder: 0),
        image(id: 2, sortOrder: 1),
        image(id: 3, sortOrder: 2, isPrimary: true),
      ];

      // Act
      final ordered = galleryOrder(images);

      // Assert
      expect(ordered.first.id, 3);
    });

    test('the rest keep the order the server sent', () {
      // Arrange — the API already sorts by `sort_order` then `id`, so re-sorting here would be
      // a second opinion about an order the shop set deliberately.
      final images = [
        image(id: 1, sortOrder: 1),
        image(id: 2, sortOrder: 2),
        image(id: 3, sortOrder: 0, isPrimary: true),
      ];

      // Act
      final ordered = galleryOrder(images);

      // Assert
      expect(ordered.map((each) => each.id), [3, 1, 2]);
    });

    test('the list it was handed is left alone', () {
      // Arrange — the page hands over `product.images`, which is the model's own list.
      final images = [image(id: 1), image(id: 2, isPrimary: true)];

      // Act
      galleryOrder(images);

      // Assert
      expect(images.map((each) => each.id), [1, 2]);
    });
  });

  group('the shape it takes', () {
    testWidgets('the picture fills the width it is given, square', (tester) async {
      // Arrange
      useAPhone(tester);

      // Act
      await tester.pumpWidget(host(ProductGallery(images: [image(isPrimary: true)])));
      await tester.pump();

      // Assert — the whole content column, and square, so nothing of a square photograph is
      // cropped away to make it fit. This is the regression the 240-wide strip was.
      expect(tester.getSize(find.byType(CachedNetworkImage)), const Size(430, 430));
    });

    testWidgets('a picture still arriving holds the same box', (tester) async {
      // Arrange — there is no network in a test, so this is the loading state, which is also
      // what a phone on a bad connection sees for a second.
      useAPhone(tester);

      // Act
      await tester.pumpWidget(host(ProductGallery(images: [image(isPrimary: true)])));
      await tester.pump();

      // Assert — the page below does not jump as the photograph resolves.
      expect(tester.getSize(find.byType(ProductGallery)).width, 430);
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('no pictures at all draws nothing', (tester) async {
      // Arrange — the legacy rows the image backfill has not reached.
      useAPhone(tester);

      // Act
      await tester.pumpWidget(host(const ProductGallery(images: [])));
      await tester.pump();

      // Assert — no empty box holding a third of the screen open.
      expect(tester.getSize(find.byType(ProductGallery)).height, 0);
    });

    testWidgets('the square is fixed before the picture resolves', (tester) async {
      // Arrange — a narrower column than the phone, which is what the page's padding gives it.
      useAPhone(tester);

      // Act
      await tester.pumpWidget(host(
          SizedBox(width: 300, child: ProductGallery(images: [image(isPrimary: true)])),
        ),
      );
      await tester.pump();

      // Assert — the width it was handed, squared. Nothing here waits on a photograph to know
      // how tall to be, so the sections below it never shift.
      expect(tester.getSize(find.byType(CachedNetworkImage)), const Size(300, 300));
    });
  });

  group('saying there is more than one', () {
    testWidgets('three pictures make a pager of three, with dots', (tester) async {
      // Arrange
      useAPhone(tester);

      // Act
      await tester.pumpWidget(host(
          ProductGallery(
            images: [
              image(id: 1, isPrimary: true),
              image(id: 2, sortOrder: 1),
              image(id: 3, sortOrder: 2),
            ],
          ),
        ),
      );
      await tester.pump();

      // Assert — a pager with nothing to say it is a pager is a picture nobody swipes.
      final pager = tester.widget<PageView>(find.byType(PageView));
      expect((pager.childrenDelegate as SliverChildBuilderDelegate).childCount, 3);
      expect(find.byKey(const ValueKey('product-gallery-dots')), findsOneWidget);
    });

    testWidgets('a single picture gets neither dots nor a badge', (tester) async {
      // Arrange
      useAPhone(tester);

      // Act
      await tester.pumpWidget(host(ProductGallery(images: [image(isPrimary: true)])));
      await tester.pump();

      // Assert — one dot under one picture says nothing, and «الصورة الرئيسية» over the only
      // photograph there is distinguishes it from nothing.
      expect(find.byKey(const ValueKey('product-gallery-dots')), findsNothing);
      expect(find.text('الصورة الرئيسية'), findsNothing);
    });

    testWidgets('with several, the badge is on the one leading', (tester) async {
      // Arrange — the primary arrives second, so the badge cannot simply be "the first page".
      useAPhone(tester);

      // Act
      await tester.pumpWidget(
        host(
          ProductGallery(
            images: [image(id: 1, sortOrder: 1), image(id: 2, isPrimary: true)],
          ),
        ),
      );
      await tester.pump();

      // Assert — exactly one, on the page the pager opens at.
      expect(find.text('الصورة الرئيسية'), findsOneWidget);
    });
  });

  group('the thumbnail the catalogue uses', () {
    testWidgets('holds its square whatever state the picture is in', (tester) async {
      // Arrange
      useAPhone(tester);

      // Act
      await tester.pumpWidget(host(ProductThumbnail(image: image(), side: 48)));
      await tester.pump();

      // Assert — a catalogue that reflows as each row's photograph lands is unreadable while
      // it settles.
      expect(tester.getSize(find.byType(ProductThumbnail)), const Size(48, 48));
    });

    testWidgets('a product with no picture keeps the same square', (tester) async {
      // Arrange
      useAPhone(tester);

      // Act
      await tester.pumpWidget(host(const ProductThumbnail(image: null, side: 48)));
      await tester.pump();

      // Assert — the column stays a column, so the eye can still run down the names beside it.
      expect(tester.getSize(find.byType(ProductThumbnail)), const Size(48, 48));
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('carries none of the hero furniture', (tester) async {
      // Arrange
      useAPhone(tester);

      // Act
      await tester.pumpWidget(host(ProductThumbnail(image: image(isPrimary: true), side: 48)));
      await tester.pump();

      // Assert — a product row is read for its prices; the picture is there to be recognised in
      // passing and nothing more.
      expect(find.byType(PageView), findsNothing);
      expect(find.byKey(const ValueKey('product-gallery-dots')), findsNothing);
    });
  });
}
