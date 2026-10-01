import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_card.dart';
import 'package:dayaa/features/orders/presentation/widgets/send_together.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «إرسال معاً للنورس» — several orders in one parcel.
///
/// **The server owns the rule** (one customer, one door, one phone); what is tested here is the
/// courtesy on top of it — which cards the list lets you pick — and the two facts the screens
/// read off the payload: who else is in the parcel, and that a mode entered on purpose turns a
/// tap into a pick.
///
/// Arrange - Act - Assert throughout.
void main() {
  Order order({
    int id = 52,
    int customerId = 5,
    int cityId = 3,
    int? regionId = 9,
    bool isOfficePickup = false,
    NawrisParcelRef? parcel,
  }) => Order(
    id: id,
    code: '$id',
    status: OrderStatus.ready,
    statusLabel: 'جاهزة',
    isFinal: false,
    customerId: customerId,
    cityId: cityId,
    regionId: regionId,
    designSource: 'none',
    cityName: 'زليتن',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: isOfficePickup,
    designSourceLabel: 'بدون تصميم',
    itemsTotal: '100.00',
    designFee: '0.00',
    deliveryPrice: '0.00',
    discount: '0.00',
    grandTotal: '100.00',
    paidAmount: '0.00',
    remainingAmount: '100.00',
    nawrisParcel: parcel,
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
      home: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );

  group('which cards may be picked', () {
    test('a ready delivery with nothing out may be the first', () {
      // Act
      final why = whyNotSendTogether(order());

      // Assert
      expect(why, isNull);
    });

    test('an office pickup never leaves the building', () {
      // Act
      final why = whyNotSendTogether(order(isOfficePickup: true));

      // Assert
      expect(why, isNotNull);
    });

    test('an order already with the carrier cannot go twice', () {
      // Act
      final why = whyNotSendTogether(
        order(parcel: const NawrisParcelRef(code: '3702994', isOpen: true)),
      );

      // Assert
      expect(why, isNotNull);
    });

    test('an order whose parcel came back may go again', () {
      // Act — closed is history, not a hand-over in progress.
      final why = whyNotSendTogether(order(parcel: const NawrisParcelRef(code: '3702994')));

      // Assert
      expect(why, isNull);
    });

    test('once one is picked, another customer is refused', () {
      // Arrange
      final first = order(id: 1);

      // Act
      final why = whyNotSendTogether(order(id: 2, customerId: 99), first: first);

      // Assert
      expect(why, 'الطرد المشترك لزبون واحد');
    });

    test('once one is picked, another region is refused', () {
      // Arrange
      final first = order(id: 1);

      // Act
      final why = whyNotSendTogether(order(id: 2, regionId: 10), first: first);

      // Assert
      expect(why, 'الطرد المشترك يذهب إلى عنوان واحد');
    });

    test('the same customer to the same door may join', () {
      // Arrange
      final first = order(id: 1);

      // Act
      final why = whyNotSendTogether(order(id: 2), first: first);

      // Assert
      expect(why, isNull);
    });

    test('the first pick is never blocked by itself', () {
      // Arrange
      final first = order(id: 1);

      // Act
      final why = whyNotSendTogether(first, first: first);

      // Assert
      expect(why, isNull);
    });
  });

  group('who else is in the parcel', () {
    test('the other orders are read off the payload', () {
      // Act
      final ref = NawrisParcelRef.fromJson({
        'code': '3702994',
        'is_open': true,
        'shared_with': [
          {'id': 8, 'code': '1221'},
        ],
      });

      // Assert
      expect(ref.sharedWith, [const SharedParcelOrder(id: 8, code: '1221')]);
    });

    test('a parcel of one, or an older server, shares with nobody', () {
      // Act — absent, not an error: the key predates shared parcels.
      final ref = NawrisParcelRef.fromJson({'code': '3702994'});

      // Assert
      expect(ref.sharedWith, isEmpty);
    });
  });

  group('the card while picking', () {
    testWidgets('a tap picks instead of opening', (tester) async {
      // Arrange
      var toggled = 0;
      await tester.pumpWidget(
        host(
          PickableOrderCard(
            order: order(),
            picked: false,
            blockedBecause: null,
            onToggle: () => toggled++,
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(OrderCard));
      await tester.pump();

      // Assert
      expect(toggled, 1);
    });

    testWidgets('a card that cannot join is not picked by a tap', (tester) async {
      // Arrange
      var toggled = 0;
      await tester.pumpWidget(
        host(
          PickableOrderCard(
            order: order(),
            picked: false,
            blockedBecause: 'الطلبية استلام مكتب',
            onToggle: () => toggled++,
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(OrderCard));
      await tester.pump(const Duration(milliseconds: 300));

      // Assert — not picked, and the tap says why rather than doing nothing.
      expect(toggled, 0);
      expect(find.text('الطلبية استلام مكتب'), findsOneWidget);

      // The snackbar dismisses itself after three seconds; let it, so no timer outlives the test.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  });

  group('the bar under the list', () {
    Widget bar(int count) => host(
      SendTogetherBar(count: count, isSending: false, onSend: () {}, onCancel: () {}),
    );

    testWidgets('one order is not a shared parcel', (tester) async {
      // Arrange
      await tester.pumpWidget(bar(1));

      // Act
      final button = tester.widget<AppButton>(
        find.ancestor(of: find.text('إرسال معاً للنورس'), matching: find.byType(AppButton)),
      );

      // Assert
      expect(button.onPressed, isNull);
    });

    testWidgets('two orders may go', (tester) async {
      // Arrange
      await tester.pumpWidget(bar(2));

      // Act
      final button = tester.widget<AppButton>(
        find.ancestor(of: find.text('إرسال معاً للنورس'), matching: find.byType(AppButton)),
      );

      // Assert
      expect(button.onPressed, isNotNull);
    });
  });
}
