import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:dayaa/features/shortages/models/shortage_supply.dart';
import 'package:dayaa/features/shortages/presentation/widgets/supplies_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The ledger under a shortage — every operation, including the ones this section never wrote.
///
/// **A shortage has two doors.** An employee closes one from here by recording what they bought;
/// a colleague closes the same one from the order screen, by typing what arrived. Both are real,
/// and both land in this table — which is why a row can carry no money at all.
///
/// Arrange - Act - Assert throughout.
void main() {
  Shortage shortage(List<ShortageSupply> supplies) => Shortage(
    id: 41,
    code: 'N41',
    source: ShortageSource.order,
    sourceLabel: 'من طلبية',
    name: 'كيس شحن — 25*35',
    unit: 'kilogram',
    unitLabel: 'كجم',
    requiredQuantity: '30.000',
    suppliedQuantity: '20.000',
    remainingQuantity: '10.000',
    totalPaid: '500.00',
    status: ShortageStatus.searching,
    statusLabel: 'جاري البحث',
    supplies: supplies,
  );

  ShortageSupply purchase({bool movedStock = true, bool isReversible = true}) => ShortageSupply(
    id: 77,
    shortageId: 41,
    kind: SupplyKind.purchased,
    kindLabel: 'شراء',
    quantity: '20.000',
    amount: '500.00',
    method: 'cash',
    methodLabel: 'كاش',
    occurredOn: '2026-09-11',
    warehouseId: movedStock ? 3 : null,
    warehouse: movedStock ? const ShortageSupplyWarehouseRef(id: 3, name: 'المخزن الرئيسي') : null,
    movedStock: movedStock,
    isReversible: isReversible,
    recorder: const ShortageSupplyPersonRef(id: 6, name: 'محمد'),
  );

  const arrival = ShortageSupply(
    id: 78,
    shortageId: 41,
    kind: SupplyKind.resolvedExternally,
    kindLabel: 'وصلت من الطلبية',
    quantity: '10.000',
  );

  Widget host(Widget child) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );

  testWidgets('an empty ledger says so in words, not as a zero', (tester) async {
    // Arrange
    await tester.pumpWidget(host(SuppliesTable(shortage: shortage(const []))));

    // Act - Assert — «٠ عمليات» would suggest a figure was measured.
    expect(find.text('لم تُسجَّل أي عملية توفير بعد'), findsOneWidget);
  });

  testWidgets('a purchase names its money, its method and the shelf it landed on', (tester) async {
    // Arrange
    await tester.pumpWidget(host(SuppliesTable(shortage: shortage([purchase()]))));

    // Act - Assert
    expect(find.textContaining('20 كجم'), findsOneWidget);
    expect(find.textContaining('500'), findsOneWidget);
    expect(find.text('كاش'), findsOneWidget);
    expect(find.text('المخزن الرئيسي'), findsOneWidget);
  });

  testWidgets('an arrival from the order prints a dash, never 0.00', (tester) async {
    // Arrange — it carries no money at all: `amount`, `method` and `method_label` are null.
    await tester.pumpWidget(host(SuppliesTable(shortage: shortage(const [arrival]))));

    // Act - Assert — «0.00» would read as a free purchase and sit wrongly in a mental total.
    expect(find.text('—'), findsOneWidget);
    expect(find.textContaining('0.00'), findsNothing);
    expect(find.text('وصلت من الطلبية'), findsOneWidget);
  });

  testWidgets('only a row the server calls reversible is offered an undo', (tester) async {
    // Arrange — an arrival from the order is not: it is corrected on the order screen.
    await tester.pumpWidget(
      host(
        SuppliesTable(
          shortage: shortage([purchase(), arrival]),
          onReverse: (_) {},
        ),
      ),
    );

    // Act - Assert — one button for two rows.
    expect(find.text('عكس'), findsOneWidget);
  });

  testWidgets('a reader without the grant is offered none at all', (tester) async {
    // Arrange
    await tester.pumpWidget(host(SuppliesTable(shortage: shortage([purchase()]))));

    // Act - Assert
    expect(find.text('عكس'), findsNothing);
  });

  testWidgets('a purchase that moved nothing names no shelf', (tester) async {
    // Arrange — `moved_stock` is the flag, never `warehouse_id`: the three stock fields are null
    // together, and a CHECK on the table keeps them from coming apart.
    await tester.pumpWidget(host(SuppliesTable(shortage: shortage([purchase(movedStock: false)]))));

    // Act - Assert
    expect(find.text('المخزن الرئيسي'), findsNothing);
  });
}
