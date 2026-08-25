import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/stock_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// One shelf: a code, what is on it, how much, and whether that is too little.
///
/// Three things this row has to get right:
///
///   * **the code leads, where a photograph used to.** A shelf is a pile of material at a size
///     and two catalogue rows draw on it — «كيس شحن سادة» and «كيس شحن مطبوع» both take from this
///     row — so a picture here could only ever have been one of the two, chosen arbitrarily, and
///     it told the storekeeper the wrong thing. `S9` identifies the pile without claiming
///     anything about who sells it, and it is what gets read down a phone line.
///   * **the name is the server's own composition.** «كيس شحن 25*35» arrives composed and is
///     drawn as sent; a second implementation in Dart would drift from the string the shortfall
///     messages quote, and the first screen to notice would be one comparing a refusal to a list.
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
    bool withItem = true,
    String unit = 'piece',
    String unitLabel = 'قطعة',
  }) => WarehouseStock(
    id: 1,
    warehouseId: 1,
    stockItemId: 7,
    quantity: quantity,
    unit: unit,
    unitLabel: unitLabel,
    lowStockThreshold: threshold,
    isLowStock: isLow,
    item: withItem
        ? const StockItemRef(
            id: 7,
            code: 'S9',
            name: 'كيس شحن',
            widthCm: 30,
            heightCm: 30,
            // Composed server-side; written out here rather than assembled, because that is
            // exactly what the row is forbidden to do.
            displayName: 'كيس شحن 30*30',
          )
        : null,
  );

  Widget host(Widget row) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: row),
    ),
  );

  testWidgets('the code leads, and the shelf is named as the server composed it', (tester) async {
    // Arrange
    await tester.pumpWidget(host(StockRow(stock: stock())));

    // Act
    await tester.pump();

    // Assert — `S9` is the pile's own identity, and «كيس شحن 30*30» is one string that arrived
    // that way. Neither of them is a product: the row deliberately says nothing about which of
    // the catalogue rows sharing this pile it belongs to, because it belongs to both.
    expect(find.text('S9'), findsOneWidget);
    expect(find.text('كيس شحن 30*30'), findsOneWidget);
  });

  testWidgets('a line that arrived without its item still names itself', (tester) async {
    // Arrange — the nested item is optional on the payload, and a row that renders half a
    // widget when it is absent is a row that breaks the whole list on one thin response.
    await tester.pumpWidget(host(StockRow(stock: stock(withItem: false))));

    // Act
    await tester.pump();

    // Assert — «صنف #7» over a blank: the shelf id is a poor name and an honest one, and the
    // balance beside it is still the number the reader opened this screen for. Nothing invents
    // a code it does not have.
    expect(find.text('مادة #7'), findsOneWidget);
    expect(find.text('S9'), findsNothing);
    expect(find.text('50'), findsOneWidget);
  });

  testWidgets('inside a card the line drops the material, keeps the size', (tester) async {
    // Arrange — `StockRow.inGroup` sits under a heading that has already said «كيس شحن» once
    await tester.pumpWidget(host(StockRow.inGroup(stock: stock())));

    // Act
    await tester.pump();

    // Assert — repeating the whole composed name under its own heading is a card that says
    // everything twice. The size is what differs from the line above, and the code stays on
    // both forms because each size is its own shelf with its own `S9`.
    expect(find.text('30*30'), findsOneWidget);
    expect(find.text('كيس شحن 30*30'), findsNothing);
    expect(find.text('S9'), findsOneWidget);
  });

  testWidgets('an empty shelf is named, not just numbered', (tester) async {
    // Arrange — no threshold, so the server does not call it low; it is still empty
    await tester.pumpWidget(host(StockRow(stock: stock(quantity: '0.000'))));

    // Act
    await tester.pump();

    // Assert
    expect(find.text('نافد'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('a shelf below its alert level says which level', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(
        StockRow(
          stock: stock(quantity: '10.000', threshold: '20.000', isLow: true),
        ),
      ),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.text('تحت الحد'), findsOneWidget);
    expect(find.text('حد التنبيه 20'), findsOneWidget);
    expect(find.text('نافد'), findsNothing);
  });

  testWidgets('an empty shelf that is also below its level reads as empty, once', (tester) async {
    // Arrange — both are true and only the louder one is worth a word
    await tester.pumpWidget(
      host(
        StockRow(
          stock: stock(quantity: '0.000', threshold: '20.000', isLow: true),
        ),
      ),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.text('نافد'), findsOneWidget);
    expect(find.text('تحت الحد'), findsNothing);
  });

  testWidgets('a healthy shelf claims nothing at all', (tester) async {
    // Arrange
    await tester.pumpWidget(host(StockRow(stock: stock(quantity: '1000.000'))));

    // Act
    await tester.pump();

    // Assert — no badge, and the quantity keeps the plain ink
    expect(find.text('نافد'), findsNothing);
    expect(find.text('تحت الحد'), findsNothing);
    expect(find.text('1,000'), findsOneWidget);
  });

  testWidgets('the balance is drawn in the unit it was counted in', (tester) async {
    // Arrange — the unit lives on the balance line, not on the item: it was snapshotted when
    // the shelf was first stocked
    await tester.pumpWidget(
      host(
        StockRow(
          stock: stock(quantity: '250.000', unit: 'kg', unitLabel: 'كيلوغرام'),
        ),
      ),
    );

    // Act
    await tester.pump();

    // Assert — «250» alone is ambiguous on a floor holding both bags and kilos, and reading the
    // unit off the item instead would restate an old count in a unit somebody chose later.
    expect(find.text('250'), findsOneWidget);
    expect(find.text('كيلوغرام'), findsOneWidget);
  });
}
