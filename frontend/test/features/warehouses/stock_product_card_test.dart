import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/features/products/presentation/widgets/product_gallery.dart';
import 'package:dayaa/features/warehouses/models/stock_group.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/stock_product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// One bag, its sizes underneath it.
///
/// The card exists to say the product **once**: the name, the code and the picture belong to
/// the bag, and repeating them on every size is what made four shelves of one product read as
/// four products. What stays on each line is what actually differs — the size, its balance, and
/// whether that balance is a problem.
///
/// Arrange - Act - Assert throughout.
void main() {
  WarehouseStock shelf({
    required int id,
    required String label,
    String quantity = '50.000',
    String? threshold,
    bool isLow = false,
    String? imageUrl,
  }) => WarehouseStock(
    id: id,
    warehouseId: 1,
    productVariantId: id,
    quantity: quantity,
    unit: 'kg',
    unitLabel: 'كيلوغرام',
    lowStockThreshold: threshold,
    isLowStock: isLow,
    variant: StockVariant(
      id: id,
      label: label,
      productId: 7,
      productCode: 'P7',
      productName: 'أكياس الشحن',
      imageUrl: imageUrl,
    ),
  );

  Widget host(
    StockGroup group, {
    void Function(WarehouseStock)? onTapShelf,
    void Function(WarehouseStock)? onEditThreshold,
  }) => ScreenUtilInit(
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
        body: StockProductCard(
          group: group,
          onTapShelf: onTapShelf,
          onEditThreshold: onEditThreshold,
        ),
      ),
    ),
  );

  final group = StockGroup([
    shelf(id: 1, label: '25*35', quantity: '0.000'),
    shelf(id: 2, label: '45*50', quantity: '120.000', imageUrl: 'https://example.test/bag.jpg'),
    shelf(id: 3, label: '50*60', quantity: '10.000', threshold: '20.000', isLow: true),
  ]);

  testWidgets('the product is named once, above its sizes', (tester) async {
    // Arrange
    await tester.pumpWidget(host(group));

    // Act
    await tester.pump();

    // Assert
    expect(find.text('أكياس الشحن'), findsOneWidget);
    expect(find.text('P7'), findsOneWidget);
    expect(find.byType(ProductThumbnail), findsOneWidget);
    expect(find.text('3 مقاسات'), findsOneWidget);
  });

  testWidgets('every size keeps its own line, balance and state', (tester) async {
    // Arrange
    await tester.pumpWidget(host(group));

    // Act
    await tester.pump();

    // Assert — the size alone on the line: the product name is not repeated under itself
    expect(find.text('25*35'), findsOneWidget);
    expect(find.text('45*50'), findsOneWidget);
    expect(find.text('50*60'), findsOneWidget);
    expect(find.text('أكياس الشحن · 25*35'), findsNothing);

    expect(find.text('0'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('نافد'), findsOneWidget);
    expect(find.text('تحت الحد'), findsOneWidget);
  });

  testWidgets('a line leads to its own history', (tester) async {
    // Arrange
    WarehouseStock? tapped;
    await tester.pumpWidget(host(group, onTapShelf: (stock) => tapped = stock));
    await tester.pump();

    // Act
    await tester.tap(find.text('45*50'));

    // Assert — the shelf that was tapped, not the group's first
    expect(tapped?.id, 2);
  });

  testWidgets('the alert level is set per size, and only for whoever may', (tester) async {
    // Arrange
    final edited = <int>[];
    await tester.pumpWidget(host(group, onEditThreshold: (stock) => edited.add(stock.id)));
    await tester.pump();

    // Act
    await tester.tap(find.byIcon(AppIcons.edit).last);

    // Assert — one button per size, and it carries that size
    expect(find.byIcon(AppIcons.edit), findsNWidgets(3));
    expect(edited, [3]);
  });

  testWidgets('a reader with no permission gets no buttons at all', (tester) async {
    // Arrange
    await tester.pumpWidget(host(group));

    // Act
    await tester.pump();

    // Assert
    expect(find.byIcon(AppIcons.edit), findsNothing);
  });
}
