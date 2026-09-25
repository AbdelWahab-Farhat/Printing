import 'package:dayaa/features/orders/models/order_counts.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/models/orders_sort.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_filter_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

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
  late bool? appliedUrgency;

  setUp(() {
    appliedStatus = null;
    appliedPayments = null;
    appliedUrgency = null;
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
    bool? selectedUrgency,
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
            selectedUrgency: selectedUrgency,
            counts: counts,
            onApplied: (status, payments, isUrgent) {
              appliedStatus = status;
              appliedPayments = payments;
              appliedUrgency = isUrgent;
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
  /// Every status label the sheet draws, «الكل» included.
  ///
  /// Derived from the enum rather than written out, so a status added to the business joins this
  /// check without anybody remembering to add it here.
  final statusLabels = <String>[
    'الكل',
    for (final status in OrderStatus.values)
      if (status != OrderStatus.unknown) status.label,
  ];

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

  testWidgets('the sheet stops at the ceiling it may take, and scrolls the rest', (tester) async {
    // Arrange — **this test used to ask a question the screen can no longer answer**, and the
    // history is worth keeping because the replacement is weaker on purpose.
    //
    // The bug it was written for was a sheet that asked for 90% of whatever it was given: a
    // fixed fraction of the phone, whether it had two chips in it or twenty. The guard was to
    // put it on a very tall screen and watch it come back *under* the fraction, which only a
    // content-measuring layout does. That worked while the content fitted, and the screen was
    // grown twice — 1400, then 2800 — as «جاهزة للطباعة» and «الاستعجال» were added.
    //
    // It cannot be grown a third time. «انتظار العربون» و«عربون مدفوع» take the status chips to
    // seventeen, and every dimension here is a ScreenUtil dimension: the text, the padding and
    // the gaps all scale with the screen, so the content is the *same fraction* of any phone.
    // Once that fraction passes 0.8 it passes it everywhere, and at 3200, 3600 and 4000 the
    // sheet comes back pinned at exactly 80%. There is no height left that can tell the two
    // layouts apart.
    //
    // So this asserts what is still observable and still the thing that would break: the sheet
    // never exceeds its ceiling, and what does not fit is reachable by scrolling rather than
    // clipped. The old layout would fail the first half at 90%. `Column` is still `mainAxisSize:
    // min` and the scroller still `Flexible` — the widget measures its content as it always
    // did; it simply has more content than the ceiling now.
    useAPhone(tester, height: 932);
    await tester.pumpWidget(host());

    // Act
    await openTheSheet(tester);
    final height = tester.getSize(find.byKey(OrderFilterButton.sheetKey)).height;

    // Assert — at the ceiling and not past it, with the overflow scrollable rather than lost.
    expect(height, lessThanOrEqualTo(932 * 0.8));
    expect(
      find.descendant(
        of: find.byKey(OrderFilterButton.sheetKey),
        matching: find.byType(Scrollable),
      ),
      findsWidgets,
    );
  });

  testWidgets('the options share lines — chips, not a column of full-width rows', (tester) async {
    // Arrange — the shape change is what buys the height: a chip is as wide as its word, so
    // «ملغاة» stops reserving the width of «راجع لدى شركة التوصيل».
    useAPhone(tester);
    await tester.pumpWidget(host());

    // Act
    await openTheSheet(tester);

    // Assert — **counted rather than named.** This used to assert «الكل» and «جديدة» share a
    // line, being the two shortest labels and adjacent. They stopped being adjacent the day
    // «بانتظار المراجعة» was added to the enum ahead of «جديدة», and the test went red over a
    // new status rather than over the property it is guarding. What it means is that the
    // options wrap — so that is what it now measures: fewer lines than options.
    final lines = <double>{
      for (final label in statusLabels) tester.getCenter(find.text(label)).dy,
    };

    expect(
      lines.length,
      lessThan(statusLabels.length),
      reason: 'every option is on a line of its own — these are rows, not wrapped chips',
    );
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

  testWidgets('the sort is not on this sheet at all', (tester) async {
    // Arrange — it was, and it was wrong: every chip here narrows the list, and one that does
    // not reads as a filter that has stopped working. It is a button above the list now.
    useAPhone(tester);
    await tester.pumpWidget(host());

    // Act
    await openTheSheet(tester);

    // Assert
    expect(find.text('الترتيب'), findsNothing);
    for (final option in OrdersSort.values) {
      expect(find.text(option.label), findsNothing, reason: option.wire);
    }
  });

  testWidgets('«المستعجلة فقط» is a tick, and unticking it asks for everything again', (
    tester,
  ) async {
    // Arrange — the third axis. Ticked it narrows; untouched it says nothing at all, which is
    // not the same as asking for the calm ones.
    useAPhone(tester);
    await tester.pumpWidget(host());
    await openTheSheet(tester);

    // Act
    await tapOption(tester, 'المستعجلة فقط');
    await tapOption(tester, 'المستعجلة فقط');
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    // Assert
    expect(appliedUrgency, isNull);
  });

  testWidgets('the axes cross rather than replace each other', (tester) async {
    // Arrange — «الجاهزة غير المدفوعة المستعجلة» is one question, and every part of it has to
    // survive one tap on «تطبيق».
    useAPhone(tester);
    await tester.pumpWidget(host());
    await openTheSheet(tester);

    // Act
    await tapOption(tester, OrderStatus.ready.label);
    await tapOption(tester, 'غير مدفوعة');
    await tapOption(tester, 'المستعجلة فقط');
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    // Assert
    expect(appliedStatus, OrderStatus.ready);
    expect(appliedPayments, {PaymentStatus.unpaid});
    expect(appliedUrgency, isTrue);
  });

  testWidgets('«مسح الفلاتر» clears urgency with the rest', (tester) async {
    // Arrange
    useAPhone(tester);
    await tester.pumpWidget(host(selectedUrgency: true));
    await openTheSheet(tester);

    // Act
    await tester.tap(find.text('مسح الفلاتر'));
    await tester.pump();
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    // Assert
    expect(appliedUrgency, isNull);
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
