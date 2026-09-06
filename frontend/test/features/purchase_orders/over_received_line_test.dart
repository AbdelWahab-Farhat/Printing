import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/presentation/widgets/receive_arrival_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// A line the supplier overshipped.
///
/// **More than was ordered turns up, and it is booked in.** A run of bags comes off the machine
/// heavy and the whole lot arrives on the lorry; the goods are on the shelf whether or not the
/// order expected them. The server accepts the receipt, floors the remainder at zero and names
/// the surplus on its own — these are the screens agreeing with it: no negative «متبقٍ», the
/// extra said in the informational tone, and a box to type it into even on a line that has
/// already had everything it asked for.
///
/// Arrange - Act - Assert throughout.
void main() {
  PurchaseOrderItem lineFrom(Map<String, dynamic> json) =>
      PurchaseOrderItem.fromJson({
        'id': 1,
        'stock_item_id': 4,
        'quantity_ordered': '1000.000',
        'quantity_received': '1200.000',
        'quantity_remaining': '0.000',
        'unit': 'kilogram',
        'unit_label': 'كجم',
        ...json,
      });

  group('the model', () {
    test('carries the surplus the server worked out', () {
      // Arrange
      final item = lineFrom({'quantity_over_received': '200.000'});

      // Act & Assert
      expect(item.isOverReceived, isTrue);
      expect(item.overReceivedWithUnit, '200 كجم');
    });

    test('owes nothing once everything ordered has arrived', () {
      // Arrange
      final item = lineFrom({'quantity_over_received': '200.000'});

      // Act & Assert — the remainder is floored server-side, so no screen prints a debt that
      // runs the wrong way.
      expect(item.isOutstanding, isFalse);
      expect(item.remainingWithUnit, '0 كجم');
    });

    test('reads a response older than the field as no surplus at all', () {
      // Arrange — the key absent entirely.
      final item = lineFrom({
        'quantity_received': '400.000',
        'quantity_remaining': '600.000',
      });

      // Act & Assert
      expect(item.isOverReceived, isFalse);
      expect(item.overReceivedLabel, '0');
    });
  });

  group('the receiving sheet', () {
    const order = PurchaseOrder(
      id: 4,
      vendorId: 1,
      warehouseId: 2,
      status: PurchaseOrderStatus.arrived,
      statusLabel: 'وصلت',
      orderDate: '2026-09-06',
      items: [
        PurchaseOrderItem(
          id: 1,
          stockItemId: 4,
          quantityOrdered: '1000.000',
          quantityReceived: '1000.000',
          quantityRemaining: '0.000',
          unit: 'kilogram',
          unitLabel: 'كجم',
        ),
      ],
    );

    Widget host() => ScreenUtilInit(
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
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showReceiveArrivalSheet(context: context, order: order),
              child: const Text('افتح'),
            ),
          ),
        ),
      ),
    );

    testWidgets('still offers a box on a line that has had everything it asked for', (tester) async {
      // Arrange
      tester.view
        ..physicalSize = const Size(430 * 3, 932 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host());

      // Act
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();

      // Assert — the line is drawn, said to be complete rather than «المتبقي ٠», and its box is
      // there for the pallet that turned up anyway.
      expect(find.text('اكتمل · وصل 1,000 من 1,000 كجم'), findsOneWidget);
      expect(find.text('الكمية التي وصلت (كجم)'), findsOneWidget);
    });
  });
}
