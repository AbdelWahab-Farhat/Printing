import 'package:dayaa/features/products/models/product_category.dart';
import 'package:dayaa/features/products/presentation/widgets/product_category_filter_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The sheet behind the button beside the catalogue's search box: «التصنيف».
///
/// Arrange - Act - Assert throughout.
void main() {
  const categories = [
    ProductCategory(id: 1, name: 'أكياس'),
    ProductCategory(id: 2, name: 'ستيكرات ومطبوعات أخرى'),
    ProductCategory(id: 3, name: 'مطبوعة'),
  ];

  /// The same frame the app boots into: ScreenUtil at the reference size, Arabic, RTL.
  Widget host(Widget child) {
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
          body: Directionality(textDirection: TextDirection.rtl, child: Center(child: child)),
        ),
      ),
    );
  }

  testWidgets('the sheet narrows the catalogue to the heading picked', (tester) async {
    // Arrange
    int? applied;
    var applications = 0;
    await tester.pumpWidget(
      host(
        ProductCategoryFilterButton(
          categories: categories,
          selected: null,
          onApplied: (id) {
            applied = id;
            applications++;
          },
        ),
      ),
    );

    // Act
    await tester.tap(find.byType(ProductCategoryFilterButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ستيكرات ومطبوعات أخرى'));
    await tester.pump();
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    // Assert — the id, once, on «تطبيق» rather than on the tap that picked it.
    expect(applied, 2);
    expect(applications, 1);
  });

  testWidgets('«الكل» is the way back to the whole catalogue', (tester) async {
    // Arrange
    int? applied = 3;
    await tester.pumpWidget(
      host(
        ProductCategoryFilterButton(
          categories: categories,
          selected: 3,
          onApplied: (id) => applied = id,
        ),
      ),
    );

    // Act
    await tester.tap(find.byType(ProductCategoryFilterButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الكل'));
    await tester.pump();
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    // Assert
    expect(applied, isNull);
  });

  testWidgets('the sheet opens on the heading already picked', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(
        ProductCategoryFilterButton(
          categories: categories,
          selected: 1,
          onApplied: (_) {},
        ),
      ),
    );

    // Act
    await tester.tap(find.byType(ProductCategoryFilterButton));
    await tester.pumpAndSettle();

    // Assert — «مسح الفلاتر» appears only when there is something to clear, so its presence is
    // the sheet saying it knows the catalogue is already narrowed.
    expect(find.text('مسح الفلاتر'), findsOneWidget);
  });

  testWidgets('«مسح الفلاتر» hands back the whole catalogue rather than closing the sheet', (
    tester,
  ) async {
    // Arrange
    int? applied = 1;
    await tester.pumpWidget(
      host(
        ProductCategoryFilterButton(
          categories: categories,
          selected: 1,
          onApplied: (id) => applied = id,
        ),
      ),
    );

    // Act
    await tester.tap(find.byType(ProductCategoryFilterButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مسح الفلاتر'));
    await tester.pump();
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    // Assert
    expect(applied, isNull);
  });

  testWidgets('closing the sheet without applying changes nothing', (tester) async {
    // Arrange
    var applications = 0;
    await tester.pumpWidget(
      host(
        ProductCategoryFilterButton(
          categories: categories,
          selected: null,
          onApplied: (_) => applications++,
        ),
      ),
    );

    // Act — picking a heading and dismissing is «غيّرت رأيي», and the list must not move.
    await tester.tap(find.byType(ProductCategoryFilterButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أكياس'));
    await tester.pump();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Assert
    expect(applications, 0);
  });

  testWidgets('one heading is no choice at all, so the button is absent', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(
        ProductCategoryFilterButton(
          categories: const [ProductCategory(id: 1, name: 'أكياس')],
          selected: null,
          onApplied: (_) {},
        ),
      ),
    );

    // Act — nothing: the widget is in the tree, and that is the point.

    // Assert — «الكل» and one heading filter to the same list.
    expect(find.byType(InkWell), findsNothing);
  });
}
