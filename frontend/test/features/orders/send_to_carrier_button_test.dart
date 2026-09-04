import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_detail_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «إرسال للنورس» — the overflow menu on the order's header.
///
/// **The menu is absent, not disabled, when the order cannot go.** Three conditions stand behind
/// it — «جاهزة», a delivery rather than «استلام مكتب», and `carrier.manage` — and the header is
/// handed the answer as a callback that is either there or null, exactly as the note and log
/// buttons are. These tests own the last of the three only by proxy: a null callback is what the
/// screen passes when the grant is missing.
///
/// **The status is deliberately not advanced by pressing it.** Nawris moves the order when a
/// courier picks the parcel up; the button only creates the parcel. Nothing here asserts a status
/// change because there is none to assert.
///
/// Arrange - Act - Assert throughout.
void main() {
  Order order({
    OrderStatus status = OrderStatus.ready,
    String statusLabel = 'جاهزة',
    bool officePickup = false,
  }) => Order(
    id: 1,
    code: '1',
    status: status,
    statusLabel: statusLabel,
    isFinal: false,
    customerId: 10,
    cityId: 1,
    designSource: 'customer',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: officePickup ? 'استلام مكتب' : 'توصيل',
    isOfficePickup: officePickup,
    designSourceLabel: 'من الزبون',
    itemsTotal: '110.00',
    designFee: '0.00',
    deliveryPrice: '15.00',
    discount: '0.00',
    grandTotal: '125.00',
    remainingAmount: '125.00',
    paymentStatusLabel: 'غير مدفوعة',
    regionName: 'الحشان',
  );

  /// The same frame the app boots into, with the header in the scroll view it is a sliver of.
  Widget host(Widget headerSliver) {
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
          body: CustomScrollView(
            slivers: [
              headerSliver,
              const SliverToBoxAdapter(child: SizedBox(height: 1200)),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('an order that can go offers the menu, and the carrier inside it', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(OrderDetailHeader(order: order(), onSendToCarrier: () async {})),
    );
    await tester.pumpAndSettle();

    // Act — the item lives behind the three dots, not on the bar.
    await tester.tap(find.byKey(OrderDetailHeader.overflowKey));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('إرسال للنورس'), findsOneWidget);
  });

  testWidgets('pressing it runs the send the screen handed down', (tester) async {
    // Arrange
    var sent = 0;
    await tester.pumpWidget(
      host(OrderDetailHeader(order: order(), onSendToCarrier: () async => sent++)),
    );
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byKey(OrderDetailHeader.overflowKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(OrderDetailHeader.sendToCarrierKey));
    await tester.pumpAndSettle();

    // Assert
    expect(sent, 1);
  });

  testWidgets('without the grant there is no menu at all', (tester) async {
    // Arrange — a null callback is what the screen passes without `carrier.manage`. A greyed
    // line would advertise a door that answers 403.
    await tester.pumpWidget(host(OrderDetailHeader(order: order())));

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.byKey(OrderDetailHeader.overflowKey), findsNothing);
  });

  testWidgets('the two ways of taking a hand-over back sit under the same menu', (tester) async {
    // Arrange — the app cannot tell whether a parcel still exists at Nawris, so both are offered
    // and the server answers whichever is true.
    await tester.pumpWidget(
      host(
        OrderDetailHeader(
          order: order(),
          onSendToCarrier: () async {},
          onDeleteShipment: () async {},
          onUnlinkShipment: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byKey(OrderDetailHeader.overflowKey));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('إرسال للنورس'), findsOneWidget);
    expect(find.text('حذف الشحنة من النورس'), findsOneWidget);
    expect(find.text('فكّ الربط'), findsOneWidget);
  });

  testWidgets('each item runs its own callback and no other', (tester) async {
    // Arrange — «حذف» reaches into the carrier's system and «فكّ الربط» deliberately does not, so
    // one wired to the other would be the worst possible bug on this menu.
    final ran = <String>[];
    await tester.pumpWidget(
      host(
        OrderDetailHeader(
          order: order(),
          onSendToCarrier: () async => ran.add('send'),
          onDeleteShipment: () async => ran.add('delete'),
          onUnlinkShipment: () async => ran.add('unlink'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byKey(OrderDetailHeader.overflowKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(OrderDetailHeader.unlinkShipmentKey));
    await tester.pumpAndSettle();

    // Assert
    expect(ran, ['unlink']);
  });

  testWidgets('the menu opens under the button, never across the order number', (tester) async {
    // Arrange — the default anchors the sheet at the tap, which landed it on «طلبية #1».
    await tester.pumpWidget(
      host(OrderDetailHeader(order: order(), onSendToCarrier: () async {})),
    );
    await tester.pumpAndSettle();

    // Act
    final title = tester.getRect(find.text('طلبية #1'));
    await tester.tap(find.byKey(OrderDetailHeader.overflowKey));
    await tester.pumpAndSettle();

    // Assert
    final sheet = tester.getRect(find.text('إرسال للنورس'));
    expect(sheet.top, greaterThan(title.bottom));
  });

  testWidgets('the two records beside the order are untouched by it', (tester) async {
    // Arrange — the menu is a third surface on this header and must not have eaten the first two.
    await tester.pumpWidget(
      host(
        OrderDetailHeader(
          order: order(),
          onOpenLog: () {},
          onOpenNotes: () {},
          onSendToCarrier: () async {},
        ),
      ),
    );

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.byKey(OrderDetailHeader.logKey), findsOneWidget);
    expect(find.byKey(OrderDetailHeader.notesKey), findsOneWidget);
    expect(find.byKey(OrderDetailHeader.overflowKey), findsOneWidget);
  });
}
