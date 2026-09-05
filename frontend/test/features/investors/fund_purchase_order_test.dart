import 'package:dayaa/features/investors/presentation/views/fund_purchase_order_page.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The funding screen: which lines it offers, and the arithmetic the server does not send.
///
/// **The coverage is worked out here**, from the landed cost of the lines actually chosen — it
/// is what tells the person signing that the partners covered 30,000 of a 40,000 shipment and
/// the company is a partner for the rest: 75% of the goods theirs, 25% the company's, and the
/// deal split by exactly those two figures once the server derives and freezes them.
///
/// And **a line another deal already took is shown, not hidden** — one order may carry a deal
/// per line, so «مموَّل ضمن D3» is the answer to why that one cannot be chosen.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// The same frame the app boots into: ScreenUtil at the reference size, Arabic, RTL.
  Widget host(Widget page) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Directionality(textDirection: TextDirection.rtl, child: page),
    ),
  );

  PurchaseOrderItem lineOf({
    required int id,
    required String displayName,
    required String finalTotalCost,
  }) => PurchaseOrderItem(
    id: id,
    stockItemId: id,
    stockItem: StockItemRef(
      id: id,
      code: 'S$id',
      name: displayName,
      displayName: displayName,
    ),
    quantityOrdered: '10000.000',
    quantityReceived: '0.000',
    quantityRemaining: '10000.000',
    finalTotalCost: finalTotalCost,
  );

  PurchaseOrder orderOf(
    List<PurchaseOrderItem> items, {
    List<PurchaseOrderFunding> funding = const [],
  }) => PurchaseOrder(
    id: 12,
    vendorId: 3,
    status: PurchaseOrderStatus.fresh,
    statusLabel: 'جديد',
    orderDate: '2026-09-05',
    items: items,
    investorFunding: funding,
  );

  testWidgets('the shipment cost is the sum of the landed lines, and nobody has covered it yet', (
    tester,
  ) async {
    // Arrange — two lines, 30,000 and 10,000 landed.
    final order = orderOf([
      lineOf(id: 1, displayName: 'كيس شحن 25*35', finalTotalCost: '30000.00'),
      lineOf(id: 2, displayName: 'كيس شحن 30*40', finalTotalCost: '10000.00'),
    ]);

    // Act
    await tester.pumpWidget(host(FundPurchaseOrderPage(order: order)));
    await tester.pumpAndSettle();

    // Assert — the cost of what is selected, and the whole of it still on the company.
    // Twice: once as the cost, once as the remainder nobody has covered.
    expect(find.text('تكلفة ما اخترته'), findsOneWidget);
    expect(find.text('الباقي على الشركة'), findsOneWidget);
    expect(find.text('40,000 د.ل'), findsNWidgets(2));

    // And the materials are the order's own lines, not a list to be typed again.
    expect(find.text('كيس شحن 25*35'), findsOneWidget);
    expect(find.text('كيس شحن 30*40'), findsOneWidget);
  });

  testWidgets('with nobody in yet, the company is the partner for all of it', (tester) async {
    // Arrange — one line, 20,000 landed, and no partner has typed a dinar.
    final order = orderOf([
      lineOf(id: 1, displayName: 'كيس شحن 25*35', finalTotalCost: '20000.00'),
    ]);

    // Act
    await tester.pumpWidget(host(FundPurchaseOrderPage(order: order)));
    await tester.pumpAndSettle();

    // Assert — the remainder is the whole shipment, and the screen says so as a fraction of the
    // goods too, because that fraction is what the deal will be split by from now on: the
    // company is a partner for «الباقي على الشركة», not a bystander to it.
    expect(find.text('الباقي على الشركة'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('a line the allocator never costed counts as nothing, not as a guess', (
    tester,
  ) async {
    // Arrange — `final_total_cost` is null on a line written before cost tracking.
    final order = orderOf([
      lineOf(id: 1, displayName: 'كيس شحن 25*35', finalTotalCost: '30000.00'),
      const PurchaseOrderItem(
        id: 2,
        stockItemId: 2,
        quantityOrdered: '5000.000',
        quantityReceived: '0.000',
        quantityRemaining: '5000.000',
      ),
    ]);

    // Act
    await tester.pumpWidget(host(FundPurchaseOrderPage(order: order)));
    await tester.pumpAndSettle();

    // Assert — 30,000, not a total inflated by a line nobody priced: the priced line's own row,
    // the total, and the remainder.
    expect(find.text('30,000 د.ل'), findsNWidgets(3));
  });

  testWidgets('a line another deal already took is offered locked, and left out of the cost', (
    tester,
  ) async {
    // Arrange — two lines of 30,000 each, one of them already funded by D3.
    final order = orderOf(
      [
        lineOf(id: 1, displayName: 'كيس شحن 25*35', finalTotalCost: '30000.00'),
        lineOf(id: 2, displayName: 'كيس شحن 30*40', finalTotalCost: '30000.00'),
      ],
      funding: const [
        PurchaseOrderFunding(
          dealId: 3,
          code: 'D3',
          status: 'open',
          statusLabel: 'مفتوحة',
          investorProfitSharePercent: '50.00',
          stockItemIds: [2],
        ),
      ],
    );

    // Act
    await tester.pumpWidget(host(FundPurchaseOrderPage(order: order)));
    await tester.pumpAndSettle();

    // Assert — the taken line is named by its deal and its box refuses the touch...
    expect(find.text('مموَّل ضمن D3'), findsOneWidget);

    final boxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();

    expect(boxes[0].onChanged, isNotNull);
    expect(boxes[1].onChanged, isNull);

    // ...and only the free line counts towards what has to be covered: the two line rows, the
    // total of the one chosen, and the remainder — never 60,000.
    expect(find.text('تكلفة ما اخترته'), findsOneWidget);
    expect(find.text('30,000 د.ل'), findsNWidgets(4));
    expect(find.text('60,000 د.ل'), findsNothing);
  });
}
