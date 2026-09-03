import 'package:dayaa/features/products/models/product_category.dart';
import 'package:dayaa/features/products/models/production_mode.dart';
import 'package:dayaa/features/products/presentation/widgets/product_category_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The tail on a category row that says how its goods come to exist.
///
/// **Read off the mode, not off the boolean it replaced.** `skips_production` is true for سادة
/// and for وسيط alike, so a card still printing «بدون طباعة» from it would call a vendor's
/// heading a plain one. The word drawn is the server's own label where it came.
///
/// Arrange - Act - Assert throughout.
void main() {
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
        home: Scaffold(body: Directionality(textDirection: TextDirection.rtl, child: child)),
      ),
    );
  }

  testWidgets('a وسيط heading says so on its row', (tester) async {
    // Arrange
    const category = ProductCategory(
      id: 9,
      name: 'كروت بزنس',
      productionMode: ProductionMode.outsourced,
      productionModeLabel: 'وسيط — لدى مورد خارجي',
      skipsProduction: true,
      productsCount: 3,
    );

    // Act
    await tester.pumpWidget(host(const ProductCategoryCard(category: category)));
    await tester.pump();

    // Assert
    expect(find.text('3 منتجات · وسيط — لدى مورد خارجي'), findsOneWidget);
    expect(find.textContaining('بدون طباعة'), findsNothing);
  });

  testWidgets('a plain heading keeps its own word', (tester) async {
    // Arrange
    const category = ProductCategory(
      id: 5,
      name: 'أكياس سادة',
      productionMode: ProductionMode.none,
      productionModeLabel: 'بلا تصميم وطباعة',
      skipsProduction: true,
      productsCount: 1,
    );

    // Act
    await tester.pumpWidget(host(const ProductCategoryCard(category: category)));
    await tester.pump();

    // Assert
    expect(find.text('منتج واحد · بلا تصميم وطباعة'), findsOneWidget);
  });

  testWidgets('a printed heading says nothing about it', (tester) async {
    // Arrange — the ordinary case is the quiet one.
    const category = ProductCategory(id: 1, name: 'أكياس', productsCount: 12);

    // Act
    await tester.pumpWidget(host(const ProductCategoryCard(category: category)));
    await tester.pump();

    // Assert
    expect(find.text('12 منتجاً'), findsOneWidget);
  });
}
