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

  testWidgets('a count nobody sent leaves a dash under the label', (tester) async {
    // Arrange — a reader without `orders.view` gets no key, and neither does the form's own
    // response after a save.
    await tester.pumpWidget(host(CustomerCard(customer: customerWith())));

    // Act
    final label = find.text('الطلبيات');
    final value = find.text('–');

    // Assert — the column keeps its place so the two cards in view still line up, and says «–»
    // rather than a number: «لا طلبيات» about a customer nobody counted would be a claim this
    // card was never given the right to make.
    expect(label, findsOneWidget);
    expect(value, findsOneWidget);
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

  // ─────────────────────── the shape of the card ────────────────────────

  testWidgets('the name and the code share one strip above the details', (tester) async {
    // Arrange
    await tester.pumpWidget(host(CustomerCard(customer: customerWith())));

    // Act
    final name = tester.getCenter(find.text('مطبعة الفجر'));
    final phoneLabel = tester.getCenter(find.text('رقم الهاتف'));

    // Assert — who this is comes first and on its own line; what you do about them sits
    // underneath, the way the reference card is read top to bottom.
    expect(name.dy, lessThan(phoneLabel.dy));
  });

  testWidgets('the code is introduced by a hash, to its right', (tester) async {
    // Arrange
    await tester.pumpWidget(host(CustomerCard(customer: customerWith())));

    // Act
    final hash = tester.getCenter(find.text('#'));
    final code = tester.getCenter(find.text('C8'));

    // Assert — «# C8», which in an RTL row means the hash is the child before the code and so
    // lands to its right.
    expect(code.dx, lessThan(hash.dx));
  });

  testWidgets('the phone is a labelled field, not a line with an icon', (tester) async {
    // Arrange
    await tester.pumpWidget(host(CustomerCard(customer: customerWith())));

    // Act
    final label = tester.getCenter(find.text('رقم الهاتف'));
    final value = tester.getCenter(find.text('0917775555'));

    // Assert — the label says what the number is, so the number itself needs no glyph to
    // explain it, and the two stack in one column.
    expect(label.dy, lessThan(value.dy));
    expect((label.dx - value.dx).abs(), lessThan(1));
  });

  testWidgets('the phone column takes the reading side, the orders column the other', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host(CustomerCard(customer: customerWith(ordersCount: 17))));

    // Act
    final phone = tester.getCenter(find.text('رقم الهاتف'));
    final orders = tester.getCenter(find.text('الطلبيات'));

    // Assert — two halves of one row: the phone is what the card is opened for, so it keeps the
    // side an Arabic reader starts from.
    expect(orders.dx, lessThan(phone.dx));
  });

  testWidgets('the call sheet renames the column to what it is showing', (tester) async {
    // Arrange
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
    final label = find.text('آخر طلبية');

    // Assert — «منذ شهرين» under «الطلبيات» would read as a quantity of orders.
    expect(label, findsOneWidget);
    expect(find.text('الطلبيات'), findsNothing);
  });

}
