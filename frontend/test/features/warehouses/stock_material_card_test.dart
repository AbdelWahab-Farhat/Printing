import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/features/warehouses/models/stock_group.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/stock_material_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// One material, its sizes underneath it.
///
/// The card exists to say the material **once**: four rows that differ only in two digits read as
/// four materials until you look twice, so the heading carries what the sizes share and the lines
/// carry what they do not.
///
/// **This was a product card, and swapping the heading is the point of the whole migration.**
/// «كيس شحن سادة» and «كيس شحن مطبوع» at one size are two catalogue rows and one pile of bags, so
/// heading the card with a product's name — or its photograph, which is what used to lead it —
/// picked one of the two arbitrarily and told the storekeeper the shelf was that product's. The
/// heading is now the material, which is what the sizes genuinely have in common.
///
/// **The code moved down rather than away.** A product card carried one `P7` in its heading
/// because every size under it belonged to that one product. A material card cannot: each size is
/// its own shelf with its own `S1`, and the card above has no code to say once for all of them.
///
/// Arrange - Act - Assert throughout.
void main() {
  WarehouseStock shelf({
    required int id,
    required int width,
    required int height,
    String quantity = '50.000',
    String? threshold,
    bool isLow = false,
  }) => WarehouseStock(
    id: id,
    warehouseId: 1,
    stockItemId: id,
    quantity: quantity,
    unit: 'kg',
    unitLabel: 'كيلوغرام',
    lowStockThreshold: threshold,
    isLowStock: isLow,
    item: StockItemRef(
      id: id,
      code: 'S$id',
      name: 'كيس شحن',
      widthCm: width,
      heightCm: height,
      // Composed server-side, written out here rather than assembled — the app never rebuilds
      // it, and neither does its test.
      displayName: 'كيس شحن $width*$height',
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
        body: StockMaterialCard(
          group: group,
          onTapShelf: onTapShelf,
          onEditThreshold: onEditThreshold,
        ),
      ),
    ),
  );

  final group = StockGroup([
    shelf(id: 1, width: 25, height: 35, quantity: '0.000'),
    shelf(id: 2, width: 45, height: 50, quantity: '120.000'),
    shelf(id: 3, width: 50, height: 60, quantity: '10.000', threshold: '20.000', isLow: true),
  ]);

  testWidgets('the material is named once, above its sizes', (tester) async {
    // Arrange
    await tester.pumpWidget(host(group));

    // Act
    await tester.pump();

    // Assert — exactly one «كيس شحن» for three shelves is the whole reason the card exists;
    // three of them is the list this replaced. The count under it names what the reader is
    // about to see, and each line still carries its own code because each is its own pile.
    expect(find.text('كيس شحن'), findsOneWidget);
    expect(find.text('3 مواد'), findsOneWidget);
    expect(find.text('S1'), findsOneWidget);
    expect(find.text('S2'), findsOneWidget);
    expect(find.text('S3'), findsOneWidget);
  });

  testWidgets('every size keeps its own line, balance and state', (tester) async {
    // Arrange
    await tester.pumpWidget(host(group));

    // Act
    await tester.pump();

    // Assert — the size alone on the line: the composed name would repeat, under its own
    // heading, the word that heading exists to say once.
    expect(find.text('25*35'), findsOneWidget);
    expect(find.text('45*50'), findsOneWidget);
    expect(find.text('50*60'), findsOneWidget);
    expect(find.text('كيس شحن 25*35'), findsNothing);

    expect(find.text('0'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('نافد'), findsOneWidget);
    expect(find.text('تحت الحد'), findsOneWidget);
  });

  testWidgets('nothing is totalled on the heading', (tester) async {
    // Arrange — 0 + 120 + 10 is 130, and the card must not be the thing that says so
    await tester.pumpWidget(host(group));

    // Act
    await tester.pump();

    // Assert — each shelf is counted in the unit it was stocked in, so a sum across them is
    // arithmetic this app has deliberately never done. The warehouse's own total is on the
    // summary card above the list, where the server counted it.
    expect(find.text('130'), findsNothing);
  });

  testWidgets('a line leads to its own history', (tester) async {
    // Arrange
    WarehouseStock? tapped;
    await tester.pumpWidget(host(group, onTapShelf: (stock) => tapped = stock));
    await tester.pump();

    // Act
    await tester.tap(find.text('45*50'));

    // Assert — the shelf that was tapped, not the group's first. A card holds several piles and
    // the ledger explaining one of them is not the ledger explaining another.
    expect(tapped?.id, 2);
  });

  testWidgets('the alert level is set per size, and only for whoever may', (tester) async {
    // Arrange
    final edited = <int>[];
    await tester.pumpWidget(host(group, onEditThreshold: (stock) => edited.add(stock.id)));
    await tester.pump();

    // Act
    await tester.tap(find.byIcon(AppIcons.edit).last);

    // Assert — one button per size, and it carries that size: a threshold belongs to a shelf,
    // and a material has no balance for one to be set against.
    expect(find.byIcon(AppIcons.edit), findsNWidgets(3));
    expect(edited, [3]);
  });

  testWidgets('a reader with no permission gets no buttons at all', (tester) async {
    // Arrange
    await tester.pumpWidget(host(group));

    // Act
    await tester.pump();

    // Assert — absent rather than greyed: a control that only ever refuses is one to leave out.
    expect(find.byIcon(AppIcons.edit), findsNothing);
  });

  testWidgets('two sizes are counted with the word Arabic has for a pair', (tester) async {
    // Arrange
    final pair = StockGroup([
      shelf(id: 1, width: 25, height: 35),
      shelf(id: 2, width: 45, height: 50),
    ]);
    await tester.pumpWidget(host(pair));

    // Act
    await tester.pump();

    // Assert — «2 مواد» is the kind of wrong a reader notices before they read the number.
    // Arabic counts the pair with its own word, and this card is drawn from two shelves upward,
    // so the pair is the most common card on the screen rather than an edge case.
    expect(find.text('مادتان'), findsOneWidget);
    expect(find.text('2 مواد'), findsNothing);
  });
}
