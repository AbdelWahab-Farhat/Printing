import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/orders/models/order_counts.dart';
import 'package:printing/features/orders/models/order_payment.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/presentation/widgets/order_filter_button.dart';

/// تصفية الطلبيات — the sheet behind the button beside the search box.
///
/// The behaviour it has always had — every status offered with its count, two axes applied
/// together, a way back to «الكل» — plus the two things that changed: the options are **wrapped
/// chips** rather than a column of full-width rows, and the sheet is **as tall as what it has to
/// say** rather than a fixed fraction of the phone. Fifteen full-width rows filled a screen from
/// the handle to the home indicator and still clipped the last of them, so both are tested
/// properties and not matters of taste.
///
/// **Absolute heights are not asserted anywhere here, on purpose.** The test binding draws in a
/// font whose every glyph is the same fixed-width box, so Arabic measures roughly twice what it
/// does on a phone and any pixel threshold would be describing a layout the app never produces.
/// What is asserted instead is font-independent: that the sheet does not grow with the screen,
/// and that options share lines.
///
/// Arrange - Act - Assert throughout.
void main() {
  late OrderStatus? appliedStatus;
  late Set<PaymentStatus>? appliedPayments;

  setUp(() {
    appliedStatus = null;
    appliedPayments = null;
  });

  /// A real phone, not the 800×600 the test binding defaults to.
  void useAPhone(WidgetTester tester, {double height = 932}) {
    tester.view
      ..physicalSize = Size(430 * 3, height * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  /// Distinct numbers throughout, so a `find.text` for one count cannot match another's.
  final counts = ValueNotifier<OrderCounts>(
    const OrderCounts(
      total: 26,
      byStatus: {
        'new': 1,
        'designing': 2,
        'printing': 3,
        'ready': 4,
        'shortage': 5,
        'office_pickup': 6,
        'out_for_delivery': 7,
        'delivered': 8,
        'settled': 9,
        'returned_courier': 10,
        'returned_carrier': 11,
        'returned_office': 12,
        'resend': 13,
        'cancelled': 14,
      },
      byPaymentStatus: {'paid': 15, 'partially_paid': 16, 'unpaid': 17},
    ),
  );

  Widget host({
    OrderStatus? selected,
    Set<PaymentStatus> selectedPayments = const <PaymentStatus>{},
  }) => ScreenUtilInit(
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
        body: Center(
          child: OrderFilterButton(
            selected: selected,
            selectedPayments: selectedPayments,
            counts: counts,
            onApplied: (status, payments) {
              appliedStatus = status;
              appliedPayments = payments;
            },
          ),
        ),
      ),
    ),
  );

  Future<void> openTheSheet(WidgetTester tester) async {
    await tester.tap(find.byType(OrderFilterButton));
    await tester.pumpAndSettle();
  }

  /// Scrolls first, because in the test font the chips run past the fold on a phone even though
  /// they do not on a real one.
  Future<void> tapOption(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pump();
  }

  testWidgets('every status is on the sheet, each with its own count', (tester) async {
    // Arrange
    useAPhone(tester);
    await tester.pumpWidget(host());

    // Act
    await openTheSheet(tester);

    // Assert — including «تم التسوية», which nothing in the list is sitting in: a queue reading
    // zero is exactly the one worth being able to ask about.
    for (final status in OrderStatus.filterable) {
      expect(find.text(status.label), findsOneWidget, reason: status.wire);
    }

    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('26'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
  });

  testWidgets('the sheet is as tall as its content, not a fraction of the phone', (tester) async {
    // Arrange — a tall screen, so that the fixed-fraction layout this replaced and the
    // content-sized one that took its place cannot land on the same number by accident.
    useAPhone(tester, height: 1400);
    await tester.pumpWidget(host());

    // Act
    await openTheSheet(tester);
    final height = tester.getSize(find.byKey(OrderFilterButton.sheetKey)).height;

    // Assert — it stops short of the 80% it is allowed, which is the observable meaning of
    // "measures its own content". The layout this replaced asked for 90% of whatever it was
    // given and would have come back with 1260 — and this is the *inflated* test font, so a real
    // phone has more room left over than this number suggests.
    expect(height, lessThan(1400 * 0.8));
  });

  testWidgets('the options share lines — chips, not a column of full-width rows', (tester) async {
    // Arrange — the shape change is what buys the height: a chip is as wide as its word, so
    // «ملغاة» stops reserving the width of «راجع لدى شركة التوصيل».
    useAPhone(tester);
    await tester.pumpWidget(host());

    // Act
    await openTheSheet(tester);

    // Assert — the two shortest labels sit side by side rather than one under the other.
    expect(tester.getCenter(find.text('الكل')).dy, tester.getCenter(find.text('جديدة')).dy);
  });

  testWidgets('picking a status and applying answers with it', (tester) async {
    // Arrange
    useAPhone(tester);
    await tester.pumpWidget(host());
    await openTheSheet(tester);

    // Act
    await tapOption(tester, 'قيد التصميم');
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    // Assert
    expect(appliedStatus, OrderStatus.designing);
    expect(appliedPayments, isEmpty);
  });

  testWidgets('the payment states combine — they are ticks, not a second single choice', (
    tester,
  ) async {
    // Arrange — «أرِني ما لم يُدفع» means unpaid *and* part-paid in practice.
    useAPhone(tester);
    await tester.pumpWidget(host());
    await openTheSheet(tester);

    // Act
    await tapOption(tester, 'غير مدفوعة');
    await tapOption(tester, 'مدفوعة جزئياً');
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    // Assert
    expect(appliedPayments, {PaymentStatus.unpaid, PaymentStatus.partiallyPaid});
    expect(appliedStatus, isNull);
  });

  testWidgets('the statuses replace each other — one queue at a time', (tester) async {
    // Arrange
    useAPhone(tester);
    await tester.pumpWidget(host());
    await openTheSheet(tester);

    // Act
    await tapOption(tester, 'جاهزة');
    await tapOption(tester, 'نواقص');
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    // Assert — the second answer, not both.
    expect(appliedStatus, OrderStatus.shortage);
  });

  testWidgets('both axes are applied on one tap, not one each', (tester) async {
    // Arrange — closing on the first answer would put the second out of reach.
    useAPhone(tester);
    await tester.pumpWidget(host());
    await openTheSheet(tester);

    // Act
    await tapOption(tester, 'جاهزة');
    await tapOption(tester, 'مدفوعة بالكامل');

    // Assert — nothing has been reported yet.
    expect(appliedStatus, isNull);
    expect(appliedPayments, isNull);

    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    expect(appliedStatus, OrderStatus.ready);
    expect(appliedPayments, {PaymentStatus.paid});
  });

  testWidgets('«مسح الفلاتر» takes both axes back to «الكل»', (tester) async {
    // Arrange — opened on something narrower than everything.
    useAPhone(tester);
    await tester.pumpWidget(
      host(selected: OrderStatus.cancelled, selectedPayments: {PaymentStatus.unpaid}),
    );
    await openTheSheet(tester);

    // Act
    await tester.tap(find.text('مسح الفلاتر'));
    await tester.pump();
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    // Assert
    expect(appliedStatus, isNull);
    expect(appliedPayments, isEmpty);
  });

  testWidgets('the button says whether the list is narrowed before it is opened', (tester) async {
    // Arrange
    useAPhone(tester);
    await tester.pumpWidget(host());
    final button = find.descendant(
      of: find.byType(OrderFilterButton),
      matching: find.byType(Material),
    );

    // Act
    final neutral = tester.widget<Material>(button.first).color;
    await tester.pumpWidget(host(selected: OrderStatus.shortage));
    final active = tester.widget<Material>(button.first).color;

    // Assert
    expect(active, isNot(neutral));
  });
}
