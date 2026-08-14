import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/presentation/widgets/purchase_order_card.dart';
import 'package:dayaa/features/vendors/models/stock_arrival.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The purchase-order row, and the one property that is easy to break twice.
///
/// **The card must not inset itself.** `PagedListView` already pads the list by 16.w and puts
/// 12.h between rows, so a card carrying its own margin as well lands at 32.w — narrower than
/// every other list in the app, on a screen meant to match them. It shipped that way once; this
/// is what stops it shipping that way again, on either of the two screens that draw this card.
///
/// Arrange - Act - Assert throughout.
void main() {
  const order = PurchaseOrder(
    id: 3,
    vendorId: 1,
    vendor: ArrivalRef(id: 1, name: 'شركة محمد بن عبد العزيز للأوراق'),
    warehouseId: 2,
    warehouse: ArrivalRef(id: 2, name: 'مخزن ولي العهد'),
    status: PurchaseOrderStatus.completed,
    statusLabel: 'مكتمل',
    orderDate: '2026-08-14',
  );

  Widget host({required double width}) => ScreenUtilInit(
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
        body: Center(
          child: SizedBox(
            width: width,
            child: PurchaseOrderCard(order: order, onTap: () {}),
          ),
        ),
      ),
    ),
  );

  testWidgets('fills the width it is given, keeping no margin of its own', (tester) async {
    // Arrange
    tester.view
      ..physicalSize = const Size(430 * 3, 932 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    const width = 300.0;

    // Act
    await tester.pumpWidget(host(width: width));

    // Assert — the list decides where the row starts and ends. A card that reserved its own
    // 16.w on each side would measure 268 here, and would sit doubly inset in the list.
    expect(tester.getSize(find.byType(PurchaseOrderCard)).width, width);
  });

  testWidgets('draws the vendor, the warehouse and the state', (tester) async {
    // Arrange
    tester.view
      ..physicalSize = const Size(430 * 3, 932 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // Act
    await tester.pumpWidget(host(width: 400));

    // Assert — the server's own word for the state, so one added later still reads right.
    expect(find.text('شركة محمد بن عبد العزيز للأوراق'), findsOneWidget);
    expect(find.text('مخزن ولي العهد'), findsOneWidget);
    expect(find.text('مكتمل'), findsOneWidget);
  });
}
