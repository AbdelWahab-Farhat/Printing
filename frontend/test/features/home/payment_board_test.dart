import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/core/theme/app_tones.dart';
import 'package:printing/features/home/models/home_summary.dart';
import 'package:printing/features/home/presentation/widgets/payment_board.dart';

/// Where the money stands, on the screen the shop opens on.
///
/// Arrange - Act - Assert throughout.
void main() {
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

  /// What the server sends: every state, in its own order, zeros included.
  const payments = [
    OrderStatusCount(status: 'unpaid', label: 'غير مدفوعة', count: 12),
    OrderStatusCount(status: 'partially_paid', label: 'مدفوعة جزئياً', count: 4),
    OrderStatusCount(status: 'paid', label: 'مدفوعة بالكامل', count: 31),
    OrderStatusCount(status: 'overpaid', label: 'مدفوعة بالزيادة', count: 1),
  ];

  testWidgets('it draws the three states somebody works a queue of', (tester) async {
    // Arrange
    await tester.pumpWidget(host(const PaymentBoard(payments: payments)));

    // Act - Assert
    expect(find.text('مدفوعة بالكامل'), findsOneWidget);
    expect(find.text('مدفوعة جزئياً'), findsOneWidget);
    expect(find.text('غير مدفوعة'), findsOneWidget);

    expect(find.text('31'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('«مدفوعة بالزيادة» is deliberately not a card', (tester) async {
    // Arrange — it arises only from a discount granted after payment; it is a rarity to notice
    // on an order, not a queue anybody works through in the morning.
    await tester.pumpWidget(host(const PaymentBoard(payments: payments)));

    // Act - Assert
    expect(find.text('مدفوعة بالزيادة'), findsNothing);
  });

  testWidgets('tapping a card hands back the row that was tapped', (tester) async {
    // Arrange — the card's own word travels with it, because this app holds no table of Arabic
    // names and the title of the screen it opens can only come from here.
    OrderStatusCount? opened;
    await tester.pumpWidget(
      host(PaymentBoard(payments: payments, onOpen: (payment) => opened = payment)),
    );

    // Act
    await tester.tap(find.text('غير مدفوعة'));
    await tester.pumpAndSettle();

    // Assert
    expect(opened?.status, 'unpaid');
    expect(opened?.label, 'غير مدفوعة');
  });

  testWidgets('a card counting nothing does not open a screen saying so', (tester) async {
    // Arrange
    var taps = 0;
    await tester.pumpWidget(
      host(
        PaymentBoard(
          payments: const [
            OrderStatusCount(status: 'unpaid', label: 'غير مدفوعة', count: 0),
            OrderStatusCount(status: 'paid', label: 'مدفوعة بالكامل', count: 3),
          ],
          onOpen: (_) => taps++,
        ),
      ),
    );

    // Act
    await tester.tap(find.text('غير مدفوعة'));
    await tester.pumpAndSettle();

    // Assert
    expect(taps, 0);
  });

  testWidgets('«مدفوعة بالكامل» is drawn in the settled green, not the app\'s teal', (
    tester,
  ) async {
    // Arrange — the scheme has no green of its own, so a paid card tinted `primary` reads as
    // "the usual accent" rather than as "this one is done".
    await tester.pumpWidget(host(const PaymentBoard(payments: payments)));

    // Act
    final number = tester.widget<Text>(find.text('31'));
    final scheme = Theme.of(tester.element(find.text('31'))).colorScheme;

    // Assert
    expect(number.style?.color, scheme.paid);
    expect(number.style?.color, isNot(scheme.primary));
  });

  testWidgets('a paid card counting nothing is not green either', (tester) async {
    // Arrange — the same rule «غير مدفوعة» follows: a mark that appears while counting zero is a
    // claim about nothing, and it teaches the reader to stop believing the mark.
    await tester.pumpWidget(
      host(
        const PaymentBoard(
          payments: [OrderStatusCount(status: 'paid', label: 'مدفوعة بالكامل', count: 0)],
        ),
      ),
    );

    // Act
    final number = tester.widget<Text>(find.text('0'));
    final scheme = Theme.of(tester.element(find.text('0'))).colorScheme;

    // Assert
    expect(number.style?.color, scheme.onSurface);
  });

  testWidgets('an API that sends no payment states draws no board at all', (tester) async {
    // Arrange — an empty board with a heading over it would be a section promising something.
    await tester.pumpWidget(host(const PaymentBoard(payments: [])));

    // Act - Assert
    expect(find.text('حالات الدفع'), findsNothing);
  });
}
