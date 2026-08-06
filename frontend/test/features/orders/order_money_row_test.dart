import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/core/theme/app_tones.dart';
import 'package:printing/features/orders/models/order_payment.dart';
import 'package:printing/features/orders/presentation/widgets/order_money_row.dart';

/// The three numbers at the top of an order: what it costs, what has been paid, what is left.
///
/// **The point of these tests is that the row renders what it was given and computes nothing.**
/// «المتبقي» is the server's subtraction, and a test that asserted `450 - 150 = 300` would be
/// asserting that this widget does arithmetic it must never do.
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

  PaymentSummary summary({
    String paid = '150.00',
    String remaining = '300.00',
    PaymentStatus status = PaymentStatus.partiallyPaid,
    String label = 'مدفوعة جزئياً',
    bool unrecorded = false,
  }) {
    return PaymentSummary(
      grandTotal: '450.00',
      paidAmount: paid,
      remainingAmount: remaining,
      paymentStatus: status,
      paymentStatusLabel: label,
      hasUnrecordedMoney: unrecorded,
    );
  }

  testWidgets('the three numbers are drawn side by side, each under its own name', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderMoneyRow(summary: summary())));

    // Act
    final labels = ['سعر الطلبية', 'المدفوع', 'المتبقي'];

    // Assert
    for (final label in labels) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('450.00'), findsOneWidget);
    expect(find.text('150.00'), findsOneWidget);
    expect(find.text('300.00'), findsOneWidget);
  });

  testWidgets('the middle cell says «المدفوع» and never «العربون»', (tester) async {
    // Arrange — a deposit is what a part-payment is *called*, and the word stops being true
    // the moment the order is paid in full.
    await tester.pumpWidget(host(OrderMoneyRow(summary: summary())));

    // Act - Assert
    expect(find.text('المدفوع'), findsOneWidget);
    expect(find.text('العربون'), findsNothing);
  });

  testWidgets('nothing is recomputed — the strings arrive rendered as they were sent', (
    tester,
  ) async {
    // Arrange — a remaining amount that disagrees with the subtraction, which is exactly what
    // an overpaid order or a mid-flight discount produces. The widget must show what it was
    // handed, not what it could work out.
    await tester.pumpWidget(
      host(
        OrderMoneyRow(
          summary: summary(
            paid: '500.00',
            remaining: '-50.00',
            status: PaymentStatus.overpaid,
            label: 'مدفوعة بالزيادة',
          ),
        ),
      ),
    );

    // Act - Assert
    expect(find.text('-50.00'), findsOneWidget);
    expect(find.text('مدفوعة بالزيادة'), findsOneWidget);
  });

  testWidgets('the payment state is shown in the server\'s own words', (tester) async {
    // Arrange — the label is never built here, so a state added after this release still reads
    // correctly on an old build.
    await tester.pumpWidget(host(OrderMoneyRow(summary: summary(label: 'حالة لم تكن موجودة'))));

    // Act - Assert
    expect(find.text('حالة لم تكن موجودة'), findsOneWidget);
  });

  testWidgets('an order that finished with money unaccounted for says so', (tester) async {
    // Arrange — settling writes no ledger entry, so the gap is surfaced rather than papered
    // over with an entry nobody made.
    await tester.pumpWidget(
      host(
        OrderMoneyRow(
          summary: summary(paid: '0.00', remaining: '450.00', unrecorded: true),
        ),
      ),
    );

    // Act - Assert
    expect(find.textContaining('لم يُسجَّل قبض 450.00'), findsOneWidget);
  });

  testWidgets('a settled order carries no warning', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(
        OrderMoneyRow(
          summary: summary(
            paid: '450.00',
            remaining: '0.00',
            status: PaymentStatus.paid,
            label: 'مدفوعة بالكامل',
          ),
        ),
      ),
    );

    // Act - Assert
    expect(find.textContaining('لم يُسجَّل قبض'), findsNothing);
    expect(find.text('مدفوعة بالكامل'), findsOneWidget);
  });

  testWidgets('the settled chip is green here too, the same green as everywhere else', (
    tester,
  ) async {
    // Arrange — three screens name this state: the home board, the order card, and this row. A
    // green on two of them and a teal on the third is the drift a shared tone exists to prevent.
    await tester.pumpWidget(
      host(
        OrderMoneyRow(
          summary: summary(
            paid: '450.00',
            remaining: '0.00',
            status: PaymentStatus.paid,
            label: 'مدفوعة بالكامل',
          ),
        ),
      ),
    );

    // Act
    final chip = tester.widget<Text>(find.text('مدفوعة بالكامل'));
    final scheme = Theme.of(tester.element(find.text('مدفوعة بالكامل'))).colorScheme;

    // Assert — the pale fill, with its own readable ink on top.
    expect(chip.style?.color, scheme.onPaidContainer);
    expect(scheme.paidContainer, isNot(scheme.primaryContainer));
  });
}
