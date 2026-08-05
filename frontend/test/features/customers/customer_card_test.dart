import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/presentation/widgets/customer_card.dart';

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
  }) {
    return Customer(
      id: 8,
      code: code,
      name: name,
      phone: phone,
      isActive: isActive,
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
}
