import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/customers/models/customer_design.dart';
import 'package:printing/features/customers/presentation/widgets/design_thumbnail.dart';

/// What a design looks like before anybody opens it.
///
/// The picker used to show one glyph for every row, which turned «الشعار الأزرق» and «الشعار
/// الأزرق — نسخة معدّلة» into two identical lines of text. The file is the thing being chosen,
/// so the file is what has to be on the row.
///
/// Arrange - Act - Assert throughout.
void main() {
  Widget host(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: Directionality(textDirection: TextDirection.rtl, child: child),
        ),
      ),
    );
  }

  CustomerDesign design({
    DesignKind kind = DesignKind.image,
    String? fileUrl = 'https://example.test/logo.png',
    String? previewUrl,
  }) {
    return CustomerDesign(
      id: 7,
      customerId: 5,
      label: 'الشعار الأزرق',
      kind: kind,
      kindLabel: kind == DesignKind.pdf ? 'PDF' : 'صورة',
      fileUrl: fileUrl,
      previewUrl: previewUrl,
    );
  }

  testWidgets('an image is drawn, not described', (tester) async {
    // Arrange
    await tester.pumpWidget(host(DesignThumbnail(design: design(), size: 44)));

    // Act
    await tester.pump();

    // Assert
    expect(find.byType(CachedNetworkImage), findsOneWidget);
  });

  testWidgets('a PDF with no rendered page shows its own glyph', (tester) async {
    // Arrange — the server renders no first page today, so this is every PDF.
    await tester.pumpWidget(
      host(DesignThumbnail(design: design(kind: DesignKind.pdf), size: 44)),
    );

    // Act
    await tester.pump();

    // Assert — a glyph, not a broken image box.
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byType(Icon), findsOneWidget);
  });

  testWidgets('a rendered page is preferred over the file itself', (tester) async {
    // Arrange — the day the backend starts rendering a PDF's first page, every phone already
    // out there starts showing it without being updated.
    await tester.pumpWidget(
      host(
        DesignThumbnail(
          design: design(kind: DesignKind.pdf, previewUrl: 'https://example.test/page-1.png'),
          size: 44,
        ),
      ),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.byType(CachedNetworkImage), findsOneWidget);
  });

  testWidgets('a design with no address at all still occupies its square', (tester) async {
    // Arrange
    await tester.pumpWidget(host(DesignThumbnail(design: design(fileUrl: null), size: 44)));

    // Act
    await tester.pump();

    // Assert — the row keeps its shape, so a library of these does not jump about as the
    // signed links come and go.
    expect(tester.getSize(find.byType(DesignThumbnail)).width, greaterThan(0));
    expect(find.byType(Icon), findsOneWidget);
  });
}
