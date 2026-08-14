import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/presentation/widgets/customer_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// What one customer row tells somebody looking a customer up.
///
/// The card never animates, so nothing here needs `pumpAndSettle` — and nothing here may
/// introduce a reason for it.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// The same frame the app boots into: ScreenUtil at the reference size, Arabic, RTL.
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

  Customer customerWith({
    String name = 'مطبعة الفجر',
    String code = 'C8',
    String phone = '0917775555',
    bool isActive = true,
    int? ordersCount,
    DateTime? lastOrderAt,
  }) {
    return Customer(
      id: 8,
      code: code,
      name: name,
      phone: phone,
      isActive: isActive,
      ordersCount: ordersCount,
      lastOrderAt: lastOrderAt,
    );
  }

  // ─────────────────────────── the code ───────────────────────────

  testWidgets('the code is on the card, once', (tester) async {
    // Arrange
    await tester.pumpWidget(host(CustomerCard(customer: customerWith())));

    // Act
    final code = find.text('C8');

    // Assert — once, not twice: it used to sit in a faint corner chip as well, and a value
    // repeated on one row makes the reader check whether the two agree.
    expect(code, findsOneWidget);
  });

  testWidgets('the code sits at the far left, past the name', (tester) async {
    // Arrange
    await tester.pumpWidget(host(CustomerCard(customer: customerWith())));

    // Act
    final code = tester.getCenter(find.text('C8'));
    final name = tester.getCenter(find.text('مطبعة الفجر'));

    // Assert — position, not alignment: the badge is the last child of an RTL row, which is
    // what stops it drifting when a long name grows. An assertion on the pixel is the only
    // kind that survives somebody "tidying" the widget order.
    expect(code.dx, lessThan(name.dx));
  });

  testWidgets('the code reads left to right inside the RTL card', (tester) async {
    // Arrange
    await tester.pumpWidget(host(CustomerCard(customer: customerWith(code: 'C12'))));

    // Act
    final text = tester.widget<Text>(find.text('C12'));

    // Assert — a Latin letter followed by digits is mangled by the card's own direction.
    expect(text.textDirection, TextDirection.ltr);
  });

  testWidgets('a long code is scaled down rather than clipped', (tester) async {
    // Arrange — codes are 'C' + the row id, so they grow with the table.
    await tester.pumpWidget(host(CustomerCard(customer: customerWith(code: 'C128456'))));

    // Assert — half a code is worse than a small one: «C128…» and «C1284…» read as the same
    // customer.
    expect(find.text('C128456'), findsOneWidget);
    expect(find.byType(FittedBox), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the first letter of the name is not the badge any more', (tester) async {
    // Arrange — «مطبعة» starts most print-shop names, so the initial said nothing.
    await tester.pumpWidget(host(CustomerCard(customer: customerWith())));

    // Assert
    expect(find.text('م'), findsNothing);
  });

  // ─────────────────────────── the rest of the row ───────────────────────────

  testWidgets('the name and the phone are both on the card', (tester) async {
    // Arrange
    await tester.pumpWidget(host(CustomerCard(customer: customerWith())));

    // Assert — the three things a customer is looked up by, all one tap short of nothing.
    expect(find.text('مطبعة الفجر'), findsOneWidget);
    expect(find.text('0917775555'), findsOneWidget);
  });

  testWidgets('a stopped customer says so beside the name', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(CustomerCard(customer: customerWith(isActive: false))),
    );

    // Assert
    expect(find.text('موقوف'), findsOneWidget);
  });

  testWidgets('a running customer says nothing about being running', (tester) async {
    // Arrange
    await tester.pumpWidget(host(CustomerCard(customer: customerWith())));

    // Assert — a badge on every row stops being read.
    expect(find.text('موقوف'), findsNothing);
  });

  testWidgets('a tap reaches the caller', (tester) async {
    // Arrange
    var tapped = false;
    await tester.pumpWidget(
      host(CustomerCard(customer: customerWith(), onTap: () => tapped = true)),
    );

    // Act
    await tester.tap(find.byType(CustomerCard));
    await tester.pump();

    // Assert
    expect(tapped, isTrue);
  });

  // ─────────────────────── how much they order ────────────────────────

  testWidgets('the row says how many orders this customer has placed', (tester) async {
    // Arrange
    await tester.pumpWidget(host(CustomerCard(customer: customerWith(ordersCount: 17))));

    // Act
    final orders = find.text('17 طلبية');

    // Assert
    expect(orders, findsOneWidget);
  });

  testWidgets('a customer who has never ordered says so', (tester) async {
    // Arrange
    await tester.pumpWidget(host(CustomerCard(customer: customerWith(ordersCount: 0))));

    // Act
    final orders = find.text('لا طلبيات');

    // Assert — a real answer about a real customer, and the one that makes «١٧ طلبية» beside it
    // worth reading: a row that goes quiet at zero teaches the eye that the slot means nothing.
    expect(orders, findsOneWidget);
  });

  testWidgets('a count nobody sent draws nothing at all', (tester) async {
    // Arrange — a reader without `orders.view` gets no key, and neither does the form's own
    // response after a save.
    await tester.pumpWidget(host(CustomerCard(customer: customerWith())));

    // Act
    final orders = find.textContaining('طلبية');

    // Assert — «لا طلبيات» about a customer nobody counted would be a claim this card was never
    // given the right to make.
    expect(orders, findsNothing);
    expect(find.text('لا طلبيات'), findsNothing);
  });

  // ─────────────────────────── the call sheet ───────────────────────────

  testWidgets('the sorted list shows how long the silence has been, in place of the count', (
    tester,
  ) async {
    // Arrange — `last_order_at` arrives only on `sort=least_recent_order`, which is the list
    // this card is being read off.
    await tester.pumpWidget(
      host(
        CustomerCard(
          customer: customerWith(
            ordersCount: 4,
            lastOrderAt: DateTime.now().subtract(const Duration(days: 70)),
          ),
        ),
      ),
    );

    // Act
    final silence = find.text('منذ شهرين');

    // Assert — the number the list was sorted by is the number on the row. «٤ طلبية» is the
    // right answer to a question nobody asked here, and both on one line is a line too long.
    expect(silence, findsOneWidget);
    expect(find.text('4 طلبية'), findsNothing);
  });

  testWidgets('a customer on that list who never ordered still says «لا طلبيات»', (tester) async {
    // Arrange — they sort last and carry a null date; the count is what is left to say.
    await tester.pumpWidget(host(CustomerCard(customer: customerWith(ordersCount: 0))));

    // Act
    final orders = find.text('لا طلبيات');

    // Assert
    expect(orders, findsOneWidget);
  });
}
