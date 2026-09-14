import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_item_card.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_line_costs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a line says when the customer took only part of it.
///
/// A shortage and a partial delivery are the same *kind* of fact — a quantity this line is not
/// being charged for — and they answer the same question, «why is this line charging less than
/// it ordered?». They are not the same fact: a shortage is our failure to make the bags, and
/// this is the customer's choice, recorded. They can both be true at once.
///
/// **What became of the goods is read off the line, never worked out here.** سادة bags go back
/// on the shelf and printed ones are a loss, but that is a rule about the *order as it was
/// taken*, and re-filing a product must not rewrite a delivery recorded last March — so the
/// server sends both the value and its Arabic and the app prints what it is handed.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// The same frame the app boots into: ScreenUtil at the reference size, Arabic, RTL.
  Widget host(Widget child) {
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
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }

  OrderItem line({
    String? shortage,
    String? billable,
    String? undelivered,
    String? disposition,
    String? dispositionLabel,
    String? deliveryLoss,
    String? cogs,
  }) => OrderItem(
    id: 11,
    productId: 7,
    productVariantId: 2,
    productName: 'أكياس الشحن',
    variantLabel: '25*35',
    pricingUnitLabel: 'قطعة',
    quantity: '300.000',
    shortageQuantity: shortage,
    undeliveredQuantity: undelivered,
    undeliveredDisposition: disposition,
    undeliveredDispositionLabel: dispositionLabel,
    deliveryLoss: deliveryLoss,
    billableQuantity: billable,
    unitPrice: '1.550',
    lineTotal: '310.00',
    materialCost: cogs == null ? null : '600.00',
    cogs: cogs,
  );

  group('the line knows whether anything was left behind', () {
    test('a line delivered whole has nothing recorded against it', () {
      // Arrange — null on every line of every order delivered whole, which is nearly all.
      final item = line();

      // Act - Assert
      expect(item.wasPartlyLeftBehind, isFalse);
    });

    test('a line the customer took part of says so', () {
      // Arrange
      final item = line(undelivered: '100.000', billable: '200.000');

      // Act - Assert
      expect(item.wasPartlyLeftBehind, isTrue);
    });

    test('a recorded zero is «took it all», not «left nothing»', () {
      // Arrange — the same trap `hasShortage` was written for: a zero typed into the delivery
      // form reaches the screen before the round trip that clears it does.
      final item = line(undelivered: '0.000', billable: '300.000');

      // Act - Assert
      expect(item.wasPartlyLeftBehind, isFalse);
    });
  });

  group('the card prints it under the shortage', () {
    testWidgets('a line delivered whole says nothing about it', (tester) async {
      // Arrange
      await tester.pumpWidget(host(OrderItemCard(item: line(), showCosts: false)));

      // Act
      await tester.pump();

      // Assert — a heading over a fact that is not there is a line to read that says nothing.
      expect(find.textContaining('غير مُستلَم'), findsNothing);
    });

    testWidgets('what was left behind is named, in this line\'s own unit, with its fate', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        host(
          OrderItemCard(
            item: line(
              undelivered: '100.000',
              billable: '200.000',
              disposition: 'restocked',
              dispositionLabel: 'أُعيد إلى المخزن',
            ),
            showCosts: false,
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert — the quantity, the unit, and the server's own word for what became of it.
      expect(find.textContaining('غير مُستلَم'), findsOneWidget);
      expect(find.textContaining('100'), findsWidgets);
      expect(find.textContaining('أُعيد إلى المخزن'), findsOneWidget);
    });

    testWidgets('the app never translates the disposition itself', (tester) async {
      // Arrange — the wire value and the Arabic disagree on purpose: whatever the server sends
      // is what is printed, so a dictionary kept in Dart cannot go out of step with the one in
      // PHP.
      await tester.pumpWidget(
        host(
          OrderItemCard(
            item: line(
              undelivered: '50.000',
              billable: '250.000',
              disposition: 'written_off',
              dispositionLabel: 'كلمة الخادم',
            ),
            showCosts: false,
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.textContaining('كلمة الخادم'), findsOneWidget);
      expect(find.textContaining('خسارة'), findsNothing);
    });

    testWidgets('a short line the customer then took part of shows both facts', (tester) async {
      // Arrange — 300 ordered, 50 never made, and the customer took 200 of the 250 that existed.
      await tester.pumpWidget(
        host(
          OrderItemCard(
            item: line(
              shortage: '50.000',
              undelivered: '50.000',
              billable: '200.000',
              disposition: 'written_off',
              dispositionLabel: 'خسارة',
            ),
            showCosts: false,
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert — they are not alternatives, and a reader of the line wants them together.
      expect(find.textContaining('ناقص'), findsOneWidget);
      expect(find.textContaining('غير مُستلَم'), findsOneWidget);
    });

    testWidgets('the money it cost is not printed beside the quantity', (tester) async {
      // Arrange — a card a salesperson reads carries no cost figures at all, and this would be
      // the only one on it.
      await tester.pumpWidget(
        host(
          OrderItemCard(
            item: line(
              undelivered: '100.000',
              billable: '200.000',
              disposition: 'written_off',
              dispositionLabel: 'خسارة',
              deliveryLoss: '412.50',
            ),
            showCosts: false,
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert — a figure no other number on this card could be mistaken for.
      expect(find.textContaining('412'), findsNothing);
    });
  });

  group('the loss goes with the other costs', () {
    testWidgets('a reader of the production figures is told what it cost us', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(
          OrderLineCosts(
            item: line(
              undelivered: '100.000',
              billable: '200.000',
              disposition: 'written_off',
              dispositionLabel: 'خسارة',
              deliveryLoss: '412.50',
              cogs: '600.00',
            ),
          ),
        ),
      );

      // Act - Assert — «منها», because the figure is a slice of the line's own cost above and
      // not a second cost to add to it.
      expect(find.textContaining('خسارة تسليم'), findsOneWidget);
      expect(find.textContaining('منها'), findsOneWidget);
    });

    testWidgets('a clerk who may not see costs is not shown it either', (tester) async {
      // Arrange — the same grant the three figures above it sit behind.
      await tester.pumpWidget(
        host(
          OrderLineCosts(
            item: line(
              undelivered: '100.000',
              billable: '200.000',
              disposition: 'written_off',
              dispositionLabel: 'خسارة',
              deliveryLoss: '412.50',
              cogs: '600.00',
            ),
            showProduction: false,
          ),
        ),
      );

      // Act - Assert
      expect(find.textContaining('خسارة تسليم'), findsNothing);
    });

    testWidgets('bags back on the shelf cost the shop nothing, so nothing is drawn', (
      tester,
    ) async {
      // Arrange — a restocked line has no `delivery_loss` at all; the server sends null rather
      // than a zero, and a «خسارة ٠٫٠٠» would report a loss that did not happen.
      await tester.pumpWidget(
        host(
          OrderLineCosts(
            item: line(
              undelivered: '100.000',
              billable: '200.000',
              disposition: 'restocked',
              dispositionLabel: 'أُعيد إلى المخزن',
              cogs: '600.00',
            ),
          ),
        ),
      );

      // Act - Assert
      expect(find.textContaining('خسارة'), findsNothing);
    });
  });
}
