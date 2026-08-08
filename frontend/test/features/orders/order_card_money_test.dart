import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/core/theme/app_tones.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_payment.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/presentation/widgets/order_card.dart';

/// The money on one row of the orders list.
///
/// The card carried «سعر الطلبية» alone for as long as the server had nothing else to say about
/// it. It says three things now, and the point of these tests is that all three are **printed as
/// sent** — a card that subtracted its own «المتبقي» would be a second answer to a question the
/// server already answered, and its answer would be the one made of doubles.
///
/// Arrange - Act - Assert throughout.
void main() {
  Widget host(Widget card) {
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
            child: SingleChildScrollView(child: card),
          ),
        ),
      ),
    );
  }

  Order orderWith({
    String paid = '150.00',
    String remaining = '300.00',
    PaymentStatus paymentStatus = PaymentStatus.partiallyPaid,
    String paymentLabel = 'مدفوعة جزئياً',
  }) {
    return Order(
      id: 52,
      code: '52',
      status: OrderStatus.delivered,
      statusLabel: 'تم الاستلام',
      isFinal: false,
      customerId: 5,
      cityId: 3,
      designSource: 'none',
      cityName: 'زليتن',
      fulfilmentTypeLabel: 'توصيل',
      isOfficePickup: false,
      designSourceLabel: 'بدون تصميم',
      itemsTotal: '430.00',
      designFee: '0.00',
      deliveryPrice: '20.00',
      discount: '0.00',
      grandTotal: '450.00',
      paidAmount: paid,
      remainingAmount: remaining,
      paymentStatus: paymentStatus,
      paymentStatusLabel: paymentLabel,
    );
  }

  testWidgets('the three money figures sit on the card, each under its own name', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host(OrderCard(order: orderWith())));

    // Act - Assert
    expect(find.text('سعر الطلبية'), findsOneWidget);
    expect(find.text('المدفوع'), findsOneWidget);
    expect(find.text('المتبقي'), findsOneWidget);

    expect(find.text('450.00'), findsOneWidget);
    expect(find.text('150.00'), findsOneWidget);
    expect(find.text('300.00'), findsOneWidget);
  });

  testWidgets('nothing is recomputed — the strings arrive rendered as they were sent', (
    tester,
  ) async {
    // Arrange — a remaining amount that disagrees with the subtraction, which is what an
    // overpaid order looks like. The card must show what it was handed.
    await tester.pumpWidget(
      host(
        OrderCard(
          order: orderWith(
            paid: '500.00',
            remaining: '-50.00',
            paymentStatus: PaymentStatus.overpaid,
            paymentLabel: 'مدفوعة بالزيادة',
          ),
        ),
      ),
    );

    // Act - Assert
    expect(find.text('-50.00'), findsOneWidget);
  });

  testWidgets('the payment state is a chip beside the status one', (tester) async {
    // Arrange — two axes that cross: «تم الاستلام» says nothing about whether it was paid.
    await tester.pumpWidget(host(OrderCard(order: orderWith())));

    // Act - Assert
    expect(find.text('تم الاستلام'), findsOneWidget);
    expect(find.text('مدفوعة جزئياً'), findsOneWidget);
  });

  testWidgets('the payment chip prints the server\'s own Arabic', (tester) async {
    // Arrange — a state this build was never taught still reads correctly.
    await tester.pumpWidget(
      host(
        OrderCard(
          order: orderWith(
            paymentStatus: PaymentStatus.unknown,
            paymentLabel: 'حالة لم تكن موجودة',
          ),
        ),
      ),
    );

    // Act - Assert
    expect(find.text('حالة لم تكن موجودة'), findsOneWidget);
  });

  testWidgets('a settled order wears its state in green, not in the app\'s teal', (tester) async {
    // Arrange — «مدفوعة بالكامل» used to take `primary`, which is the same teal as «سعر الطلبية»
    // beneath it and as half the app besides. Settled is the one state worth reading without
    // reading the word.
    await tester.pumpWidget(
      host(
        OrderCard(
          order: orderWith(
            paid: '450.00',
            remaining: '0.00',
            paymentStatus: PaymentStatus.paid,
            paymentLabel: 'مدفوعة بالكامل',
          ),
        ),
      ),
    );

    // Act
    final chip = tester.widget<Text>(find.text('مدفوعة بالكامل'));
    final scheme = Theme.of(tester.element(find.text('مدفوعة بالكامل'))).colorScheme;

    // Assert
    expect(chip.style?.color, scheme.paid);
    expect(chip.style?.color, isNot(scheme.primary));
  });

  group('the card that is paid for', () {
    /// The surface the card actually draws — the `Material` the whole row sits on.
    Color surfaceOf(WidgetTester tester) {
      return tester
          .widget<Material>(
            find.descendant(of: find.byType(OrderCard), matching: find.byType(Material)).first,
          )
          .color!;
    }

    testWidgets('«مدفوعة بالكامل» tints the whole card, not just its chip', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(
          OrderCard(
            order: orderWith(
              paid: '450.00',
              remaining: '0.00',
              paymentStatus: PaymentStatus.paid,
              paymentLabel: 'مدفوعة بالكامل',
            ),
          ),
        ),
      );

      // Act
      final scheme = Theme.of(tester.element(find.byType(OrderCard))).colorScheme;

      // Assert — green enough to be seen down a list without reading a word, and still a long
      // way from the flat `paidContainer` fill, which would make the row shout.
      expect(surfaceOf(tester), isNot(scheme.surfaceContainerLowest));
      expect(surfaceOf(tester), isNot(scheme.paidContainer));
      expect(surfaceOf(tester).g, greaterThan(surfaceOf(tester).b));
    });

    testWidgets('every other payment state keeps the plain card', (tester) async {
      // Arrange — part-paid is the common case, and a queue where most rows are tinted has
      // told nobody anything.
      await tester.pumpWidget(host(OrderCard(order: orderWith())));

      // Act
      final scheme = Theme.of(tester.element(find.byType(OrderCard))).colorScheme;

      // Assert
      expect(surfaceOf(tester), scheme.surfaceContainerLowest);
    });

    testWidgets('an order the API said nothing about stays plain', (tester) async {
      // Arrange — an empty label is a build of the API that predates payments, and
      // `PaymentStatus.unpaid` is only its default. Tinting on that would be a claim.
      await tester.pumpWidget(
        host(
          OrderCard(
            order: orderWith(
              paid: '0.00',
              remaining: '450.00',
              paymentLabel: '',
            ),
          ),
        ),
      );

      // Act
      final scheme = Theme.of(tester.element(find.byType(OrderCard))).colorScheme;

      // Assert
      expect(surfaceOf(tester), scheme.surfaceContainerLowest);
    });
  });

  testWidgets('an order from an API that predates payments wears no chip', (tester) async {
    // Arrange — silence beats a chip reading «غير مدفوعة» about a number nobody computed.
    await tester.pumpWidget(
      host(
        OrderCard(
          order: orderWith(
            paid: '0.00',
            remaining: '0.00',
            paymentStatus: PaymentStatus.unpaid,
            paymentLabel: '',
          ),
        ),
      ),
    );

    // Act - Assert — the status chip is still there; the payment one is not.
    expect(find.text('تم الاستلام'), findsOneWidget);
    expect(find.text('غير مدفوعة'), findsNothing);
  });
}
