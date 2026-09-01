import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_detail_header.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The four facts a visit to an order begins with, in the screen's own bar.
///
/// Which order this is, whose it is, what state it is in and where it goes were four cards the
/// reader scrolled past to reach the invoice. They are the header now — and the two records kept
/// beside an order, the note and the change log, are the buttons on it.
///
/// Arrange - Act - Assert throughout.
void main() {
  const customer = Customer(
    id: 10,
    code: 'A650',
    name: 'نسيبة ساسي',
    phone: '0921695826',
    isActive: true,
  );

  Order order({
    Customer? who = customer,
    String? notes,
    OrderStatus status = OrderStatus.ready,
    String statusLabel = 'جاهزة',
    bool officePickup = false,
    String fulfilmentLabel = 'توصيل',
    String city = 'طرابلس',
    String? region = 'الحشان',
  }) => Order(
    id: 1,
    code: '1',
    status: status,
    statusLabel: statusLabel,
    isFinal: false,
    customerId: 10,
    cityId: 1,
    designSource: 'customer',
    cityName: city,
    fulfilmentTypeLabel: fulfilmentLabel,
    isOfficePickup: officePickup,
    designSourceLabel: 'من الزبون',
    itemsTotal: '110.00',
    designFee: '0.00',
    deliveryPrice: '15.00',
    discount: '0.00',
    grandTotal: '125.00',
    remainingAmount: '125.00',
    paymentStatusLabel: 'غير مدفوعة',
    regionName: region,
    notes: notes,
    customer: who,
  );

  /// The same frame the app boots into, with the header in the scroll view it is a sliver of.
  Widget host(Widget headerSliver) {
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
          body: CustomScrollView(
            slivers: [
              headerSliver,
              const SliverToBoxAdapter(child: SizedBox(height: 1200)),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('it names the order, and the customer by code before name', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderDetailHeader(order: order())));

    // Act
    await tester.pumpAndSettle();

    // Assert — the code leads, because it is what one colleague says to another.
    expect(find.text('طلبية #1'), findsOneWidget);
    expect(find.text('A650 — نسيبة ساسي'), findsOneWidget);
  });

  testWidgets('an order whose customer did not travel with it still says whose it is', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host(OrderDetailHeader(order: order(who: null))));

    // Act
    await tester.pumpAndSettle();

    // Assert — the id nobody says out loud beats a blank line.
    expect(find.text('عميل #10'), findsOneWidget);
  });

  testWidgets('where it goes is one line, under one word', (tester) async {
    // Arrange — the city on a pickup order is itself called «إستلام مكتب (قرجي)».
    await tester.pumpWidget(
      host(
        OrderDetailHeader(
          order: order(officePickup: true, city: 'إستلام مكتب (قرجي)', region: null),
        ),
      ),
    );

    // Act
    await tester.pumpAndSettle();

    // Assert — «عنوان استلام مكتب: إستلام مكتب (قرجي)» said the arrangement twice.
    expect(find.text('الاستلام: إستلام مكتب (قرجي)'), findsOneWidget);
  });

  testWidgets('a delivery is titled by the word its section carries', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderDetailHeader(order: order())));

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('التوصيل: طرابلس — الحشان'), findsOneWidget);
  });

  testWidgets('the state wears the legend it wears everywhere else', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(OrderDetailHeader(order: order(status: OrderStatus.shortage, statusLabel: 'نواقص'))),
    );

    // Act
    await tester.pumpAndSettle();
    final chip = tester.widget<OrderStatusChip>(find.byType(OrderStatusChip));

    // Assert — one status, one look, wherever it is drawn.
    expect(chip.status, OrderStatus.shortage);
    expect(chip.label, 'نواقص');
  });

  testWidgets('both records are offered when there is something behind each', (tester) async {
    // Arrange
    var notes = 0;
    var log = 0;

    await tester.pumpWidget(
      host(
        OrderDetailHeader(
          order: order(notes: 'يُسلَّم قبل الظهر'),
          onOpenNotes: () => notes++,
          onOpenLog: () => log++,
        ),
      ),
    );

    // Act
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(OrderDetailHeader.notesKey));
    await tester.pump();
    await tester.tap(find.byKey(OrderDetailHeader.logKey));
    await tester.pump();

    // Assert
    expect(find.text('الملاحظات'), findsOneWidget);
    expect(find.text('السجل'), findsOneWidget);
    expect((notes, log), (1, 1));
  });

  testWidgets('a door nobody may open is absent, not greyed', (tester) async {
    // Arrange — a reader without `logs.view`, so only the notes section is on offer.
    await tester.pumpWidget(host(OrderDetailHeader(order: order(), onOpenNotes: () {})));

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.byKey(OrderDetailHeader.notesKey), findsOneWidget);
    expect(find.byKey(OrderDetailHeader.logKey), findsNothing);
  });

  testWidgets('one section alone still spans the bar', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderDetailHeader(order: order(), onOpenLog: () {})));

    // Act
    await tester.pumpAndSettle();
    final section = tester.getSize(find.byKey(OrderDetailHeader.logKey));

    // Assert — the width of the header less its two margins, never shrink-wrapped to «السجل».
    expect(section.width, greaterThan(300));
  });

  testWidgets('the two sections share one plate, and share it evenly', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(OrderDetailHeader(order: order(), onOpenNotes: () {}, onOpenLog: () {})),
    );

    // Act
    await tester.pumpAndSettle();
    final log = tester.getSize(find.byKey(OrderDetailHeader.logKey));
    final notes = tester.getSize(find.byKey(OrderDetailHeader.notesKey));

    // Assert — halves, so neither reads as the heading and the other as an afterthought.
    expect(log.width, closeTo(notes.width, 1));
  });

  testWidgets('the state wears its own glyph up here', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(OrderDetailHeader(order: order(status: OrderStatus.shortage, statusLabel: 'نواقص'))),
    );

    // Act
    await tester.pumpAndSettle();
    final chip = tester.widget<OrderStatusChip>(find.byType(OrderStatusChip));

    // Assert — the shape is read before the word is.
    expect(chip.showIcon, isTrue);
    expect(
      find.descendant(
        of: find.byType(OrderStatusChip),
        matching: find.byIcon(OrderStatusChip.iconFor(OrderStatus.shortage)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the order’s number survives the header being scrolled away', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderDetailHeader(order: order(notes: 'ملاحظة'))));
    await tester.pumpAndSettle();

    final expanded = tester.getSize(find.byType(FlexibleSpaceBar)).height;

    // Act — past the whole expanded header.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();

    // Assert — pinned: the block of facts collapses onto the toolbar, and the order's number
    // stays legible all the way down the screen.
    expect(tester.getSize(find.byType(FlexibleSpaceBar)).height, lessThan(expanded));
    expect(tester.getSize(find.byType(FlexibleSpaceBar)).height, kToolbarHeight);
    expect(find.text('طلبية #1'), findsOneWidget);
  });
}
