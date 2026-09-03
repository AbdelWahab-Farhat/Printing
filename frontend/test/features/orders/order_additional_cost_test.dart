import 'package:dayaa/features/orders/models/additional_cost_reason.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_additional_cost.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_totals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// A charge on the order that no line on it describes — «تغليف خاص», «نقل».
///
/// The server has published it for a while and the app dropped it on the floor: the money was
/// inside «الإجمالي» with nothing on screen naming it, which is the line that gets telephoned
/// about. Two places answer it now — the account prints the figure so the column adds up, and
/// «التكلفة الإضافية» says what it was for.
///
/// Arrange - Act - Assert throughout.
void main() {
  Order order({
    String cost = '0.00',
    AdditionalCostReason? reason,
    String? label,
    String? note,
    String discount = '0.00',
  }) => Order(
    id: 1,
    code: '1',
    status: OrderStatus.ready,
    statusLabel: 'جاهزة',
    isFinal: false,
    customerId: 10,
    cityId: 1,
    designSource: 'customer',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'من الزبون',
    itemsTotal: '110.00',
    designFee: '0.00',
    deliveryPrice: '15.00',
    discount: discount,
    additionalCost: cost,
    additionalCostReason: reason,
    additionalCostReasonLabel: label,
    additionalCostNote: note,
    grandTotal: '135.00',
    remainingAmount: '135.00',
    paymentStatusLabel: 'غير مدفوعة',
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
          child: Center(child: SizedBox(width: 400, child: child)),
        ),
      ),
    ),
  );

  group('what the charge is called', () {
    test('an order with no charge has nothing to say about one', () {
      // Arrange
      final subject = order();

      // Act
      final caption = subject.additionalCostCaption;

      // Assert — `'0.00'` is the absence of a fact, not a fact.
      expect(subject.hasAdditionalCost, isFalse);
      expect(caption, isNull);
    });

    test('the category alone, when nobody wrote anything under it', () {
      // Arrange
      final subject = order(cost: '10.00', reason: AdditionalCostReason.transport, label: 'نقل');

      // Act
      final caption = subject.additionalCostCaption;

      // Assert
      expect(subject.hasAdditionalCost, isTrue);
      expect(caption, 'نقل');
    });

    test('the category and the words, joined once and in one place', () {
      // Arrange
      final subject = order(
        cost: '10.00',
        reason: AdditionalCostReason.specialPackaging,
        label: 'تغليف خاص',
        note: 'علبة كرتون مزدوجة',
      );

      // Act
      final caption = subject.additionalCostCaption;

      // Assert — the invoice, the PDF and the message all read this one sentence.
      expect(caption, 'تغليف خاص — علبة كرتون مزدوجة');
    });

    test('under «أخرى» the note stands alone', () {
      // Arrange — the one reason the server refuses without words of its own.
      final subject = order(
        cost: '25.00',
        reason: AdditionalCostReason.other,
        label: 'أخرى',
        note: 'أجرة عامل تحميل',
      );

      // Act
      final caption = subject.additionalCostCaption;

      // Assert — «أخرى» names no category to anybody reading it.
      expect(caption, 'أجرة عامل تحميل');
    });

    test('a note of nothing but spaces is no note', () {
      // Arrange
      final subject = order(cost: '10.00', reason: AdditionalCostReason.modification, label: 'تعديل', note: '   ');

      // Act
      final caption = subject.additionalCostCaption;

      // Assert — a dash with a blank after it is worse than the category on its own.
      expect(caption, 'تعديل');
    });
  });

  testWidgets('the section says what for, and how much, in one row', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(
        OrderAdditionalCost(
          order: order(
            cost: '10.00',
            reason: AdditionalCostReason.specialPackaging,
            label: 'تغليف خاص',
            note: 'علبة كرتون مزدوجة',
          ),
        ),
      ),
    );

    // Act
    await tester.pump();

    // Assert — signed, so the direction is read before the number is.
    expect(find.text('تغليف خاص — علبة كرتون مزدوجة'), findsOneWidget);
    expect(find.text('+ 10.00'), findsOneWidget);
  });

  testWidgets('the account prints it after the delivery and before the discount', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(
      host(
        OrderTotals(
          order: order(cost: '10.00', reason: AdditionalCostReason.transport, label: 'نقل', discount: '5.00'),
        ),
      ),
    );

    // Act
    await tester.pump();
    final delivery = tester.getRect(find.text('التوصيل'));
    final charge = tester.getRect(find.text('التكلفة الإضافية'));
    final discount = tester.getRect(find.text('الخصم'));

    // Assert — the server's own order of operations, so a reader working down the column
    // reaches «الإجمالي» with the same arithmetic the server did.
    expect(charge.top, greaterThan(delivery.top));
    expect(charge.top, lessThan(discount.top));
    expect(find.text('+ 10.00'), findsOneWidget);
  });

  testWidgets('the account names the charge on the line it belongs to, once', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(
        OrderTotals(
          order: order(
            cost: '10.00',
            reason: AdditionalCostReason.transport,
            label: 'نقل',
            note: 'سيارة أجرة',
          ),
        ),
      ),
    );

    // Act
    await tester.pump();

    // Assert — «كم» and «على ماذا» are one fact and are read in one place. A second section
    // repeating the same figure under the account was the same answer twice.
    expect(find.text('التكلفة الإضافية'), findsOneWidget);
    expect(find.text('نقل — سيارة أجرة'), findsOneWidget);
    expect(find.text('+ 10.00'), findsOneWidget);
  });

  testWidgets('a charge the server sent with no category still gets its line', (tester) async {
    // Arrange — no reason and no note, which the server's own validation refuses; the figure
    // still has to be in the column or «الإجمالي» stops adding up.
    await tester.pumpWidget(host(OrderTotals(order: order(cost: '10.00'))));

    // Act
    await tester.pump();

    // Assert
    expect(find.text('التكلفة الإضافية'), findsOneWidget);
    expect(find.text('+ 10.00'), findsOneWidget);
  });

  testWidgets('an order with no charge draws no line for one', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderTotals(order: order())));

    // Act
    await tester.pump();

    // Assert — a charge of nothing is not a fact about this order.
    expect(find.text('التكلفة الإضافية'), findsNothing);
  });
}
