import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/products/presentation/widgets/product_gallery.dart';
import 'package:printing/features/warehouses/models/warehouse_stock.dart';
import 'package:printing/features/warehouses/presentation/widgets/stock_row.dart';

/// One shelf: a picture, a size, how much of it is here, and whether that is too little.
///
/// Two things this row has to get right and used not to:
///
///   * **a picture**, because a storekeeper standing in front of the rack recognises the bag
///     before they read its name,
///   * **zero is a state**, not a number. A line at zero with no threshold set was rendered
///     exactly like a healthy one — the same weight, the same colour, and «بلا حد تنبيه» beside
///     it — so the one shelf that has nothing on it read as the calmest row on the screen.
///
/// Arrange - Act - Assert throughout.
void main() {
  WarehouseStock stock({
    String quantity = '50.000',
    String? threshold,
    bool isLow = false,
    String? imageUrl,
    String unit = 'piece',
    String unitLabel = 'قطعة',
  }) => WarehouseStock(
    id: 1,
    warehouseId: 1,
    productVariantId: 7,
    quantity: quantity,
    unit: unit,
    unitLabel: unitLabel,
    lowStockThreshold: threshold,
    isLowStock: isLow,
    variant: StockVariant(
      id: 7,
      label: '30*30',
      productId: 3,
      productCode: 'P11',
      productName: 'أكياس شحن بيضاء',
      imageUrl: imageUrl,
    ),
  );

  Widget host(WarehouseStock line) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: StockRow(stock: line)),
    ),
  );

  testWidgets('the row carries the product picture', (tester) async {
    // Arrange
    await tester.pumpWidget(host(stock(imageUrl: 'https://example.test/bag.jpg')));

    // Act
    await tester.pump();

    // Assert — the catalogue's own thumbnail, not a second widget drawing the same thing
    expect(find.byType(ProductThumbnail), findsOneWidget);
  });

  testWidgets('a product with no picture still lays out at the same width', (tester) async {
    // Arrange — the slot is held, so a list does not reflow as each picture lands
    await tester.pumpWidget(host(stock()));

    // Act
    await tester.pump();

    // Assert
    expect(find.byType(ProductThumbnail), findsOneWidget);
  });

  testWidgets('the code and the size are both on the row', (tester) async {
    // Arrange
    await tester.pumpWidget(host(stock()));

    // Act
    await tester.pump();

    // Assert
    expect(find.text('P11'), findsOneWidget);
    expect(find.text('أكياس شحن بيضاء · 30*30'), findsOneWidget);
  });

  testWidgets('an empty shelf is named, not just numbered', (tester) async {
    // Arrange — no threshold, so the server does not call it low; it is still empty
    await tester.pumpWidget(host(stock(quantity: '0.000')));

    // Act
    await tester.pump();

    // Assert
    expect(find.text('نافد'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('a shelf below its alert level says which level', (tester) async {
    // Arrange
    await tester.pumpWidget(host(stock(quantity: '10.000', threshold: '20.000', isLow: true)));

    // Act
    await tester.pump();

    // Assert
    expect(find.text('تحت الحد'), findsOneWidget);
    expect(find.text('حد التنبيه 20'), findsOneWidget);
    expect(find.text('نافد'), findsNothing);
  });

  testWidgets('an empty shelf that is also below its level reads as empty, once', (tester) async {
    // Arrange — both are true and only the louder one is worth a word
    await tester.pumpWidget(host(stock(quantity: '0.000', threshold: '20.000', isLow: true)));

    // Act
    await tester.pump();

    // Assert
    expect(find.text('نافد'), findsOneWidget);
    expect(find.text('تحت الحد'), findsNothing);
  });

  testWidgets('a healthy shelf claims nothing at all', (tester) async {
    // Arrange
    await tester.pumpWidget(host(stock(quantity: '1000.000')));

    // Act
    await tester.pump();

    // Assert — no badge, and the quantity keeps the plain ink
    expect(find.text('نافد'), findsNothing);
    expect(find.text('تحت الحد'), findsNothing);
    expect(find.text('1,000'), findsOneWidget);
  });
}
