import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:dayaa/features/orders/presentation/views/order_notes_page.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_status_chip.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/get_order.dart';
import 'package:dayaa/features/orders/usecases/manage_order_designs.dart';
import 'package:dayaa/features/orders/usecases/reinstate_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// «ماذا كُتب على هذه الطلبية؟» — every note, each beside the status it was written at.
///
/// The order's own note used to be a row inside «التوصيل», where it was the only note the screen
/// could show; what the shop actually writes — «ناقص ٤٠ كيس» on the way into «نواقص» — was
/// readable only inside the timeline, among names and timestamps.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  Order order({String? notes, List<OrderTransitionRecord>? transitions}) => Order(
    id: 7,
    createdBy: const OrderActor(id: 1, name: 'سالم'),
    placedAt: DateTime(2026, 8, 1, 10, 15),
    code: '7',
    status: OrderStatus.shortage,
    statusLabel: 'نواقص',
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
    deliveryPrice: '0.00',
    discount: '0.00',
    grandTotal: '110.00',
    remainingAmount: '110.00',
    paymentStatusLabel: 'غير مدفوعة',
    notes: notes,
    transitions: transitions,
  );

  const opening = OrderTransitionRecord(
    id: 1,
    toStatus: OrderStatus.taken,
    toStatusLabel: 'جديدة',
  );

  final shortage = OrderTransitionRecord(
    id: 2,
    fromStatusLabel: 'قيد الطباعة',
    toStatus: OrderStatus.shortage,
    toStatusLabel: 'نواقص',
    reason: 'ناقص ٤٠ كيس',
    user: const OrderActor(id: 3, name: 'أحمد'),
    createdAt: DateTime(2026, 8, 2, 14, 30),
  );

  Widget host(Widget page) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: page,
    ),
  );

  /// The page reaches for the same cubit the order screen does, so the DI has to answer.
  void registerCubit(Order answer) {
    final repository = _MockOrderRepository();
    when(() => repository.order(7)).thenAnswer((_) async => Right(answer));

    sl.registerFactoryParam<OrderDetailCubit, int, void>(
      (orderId, _) => OrderDetailCubit(
        orderId: orderId,
        getOrder: GetOrder(repository),
        addDesign: AddOrderDesign(repository),
        reviewDesign: ReviewOrderDesign(repository),
        reinstateOrder: ReinstateOrder(repository),
      ),
    );
  }

  setUp(Injector.reset);
  tearDown(Injector.reset);

  group('what counts as a note', () {
    test('the order’s own note comes first, and wears no status', () {
      // Arrange
      final subject = order(notes: 'يُسلَّم قبل الظهر', transitions: [opening, shortage]);

      // Act
      final notes = OrderNote.on(subject);

      // Assert — it is edited from «تعديل الطلبية» at any point, so no status owns it.
      expect(notes.first.text, 'يُسلَّم قبل الظهر');
      expect(notes.first.status, isNull);
    });

    test('every move that carried words is a note, in the order they happened', () {
      // Arrange
      final subject = order(notes: 'ملاحظة الطلبية', transitions: [opening, shortage]);

      // Act
      final notes = OrderNote.on(subject);

      // Assert — the opening row carried no reason, so it is not a note.
      expect(notes.length, 2);
      expect(notes.last.text, 'ناقص ٤٠ كيس');
      expect(notes.last.status, OrderStatus.shortage);
      expect(notes.last.statusLabel, 'نواقص');
    });

    test('a status note carries who moved the order and when', () {
      // Arrange
      final subject = order(transitions: [opening, shortage]);

      // Act
      final note = OrderNote.on(subject).single;

      // Assert — the same two facts the timeline prints against the move.
      expect(note.author, 'أحمد');
      expect(note.at, DateTime(2026, 8, 2, 14, 30));
    });

    test('the order’s own note carries who took the order and when', () {
      // Arrange
      final subject = order(notes: 'يُسلَّم قبل الظهر');

      // Act
      final note = OrderNote.on(subject).single;

      // Assert — the closest thing anybody recorded about it.
      expect(note.author, 'سالم');
      expect(note.at, DateTime(2026, 8, 1, 10, 15));
    });

    test('a note nobody signed carries no author rather than a guess', () {
      // Arrange
      final subject = order(transitions: [opening, shortage.copyWith(user: null, createdAt: null)]);

      // Act
      final note = OrderNote.on(subject).single;

      // Assert
      expect(note.author, isNull);
      expect(note.at, isNull);
    });

    test('a note of nothing but spaces is no note', () {
      // Arrange
      final subject = order(
        notes: '   ',
        transitions: const [
          OrderTransitionRecord(id: 3, toStatus: OrderStatus.ready, toStatusLabel: 'جاهزة', reason: ' '),
        ],
      );

      // Act
      final notes = OrderNote.on(subject);

      // Assert
      expect(notes, isEmpty);
    });
  });

  testWidgets('each note is drawn beside the status it was written at', (tester) async {
    // Arrange
    final subject = order(notes: 'يُسلَّم قبل الظهر', transitions: [opening, shortage]);
    registerCubit(subject);

    // Act
    await tester.pumpWidget(host(OrderNotesPage(orderId: 7, order: subject)));
    await tester.pumpAndSettle();

    // Assert — the status keeps the legend it wears on the card and in the header.
    expect(find.text('ملاحظات طلبية #7'), findsOneWidget);
    expect(find.text('يُسلَّم قبل الظهر'), findsOneWidget);
    expect(find.text('ناقص ٤٠ كيس'), findsOneWidget);
    expect(find.text('ملاحظة الطلبية'), findsOneWidget);
    expect(tester.widget<OrderStatusChip>(find.byType(OrderStatusChip)).status, OrderStatus.shortage);
  });

  testWidgets('each note says who wrote it and when, the way the timeline does', (tester) async {
    // Arrange
    final subject = order(notes: 'يُسلَّم قبل الظهر', transitions: [opening, shortage]);
    registerCubit(subject);

    // Act
    await tester.pumpWidget(host(OrderNotesPage(orderId: 7, order: subject)));
    await tester.pumpAndSettle();

    // Assert — one line under the words: the stamp, then «بواسطة» and the name.
    expect(find.text('2 أغسطس 2026 · 2:30 م · بواسطة أحمد'), findsOneWidget);
    expect(find.text('1 أغسطس 2026 · 10:15 ص · بواسطة سالم'), findsOneWidget);
  });

  testWidgets('a note nobody signed draws no line at all', (tester) async {
    // Arrange
    final subject = order(transitions: [opening, shortage.copyWith(user: null, createdAt: null)]);
    registerCubit(subject);

    // Act
    await tester.pumpWidget(host(OrderNotesPage(orderId: 7, order: subject)));
    await tester.pumpAndSettle();

    // Assert — a gap is honest; a name guessed from whoever is reading is not.
    expect(find.text('ناقص ٤٠ كيس'), findsOneWidget);
    expect(find.textContaining('بواسطة'), findsNothing);
  });

  testWidgets('an order nobody wrote on says so, and says where notes come from', (tester) async {
    // Arrange
    final subject = order(transitions: const [opening]);
    registerCubit(subject);

    // Act
    await tester.pumpWidget(host(OrderNotesPage(orderId: 7, order: subject)));
    await tester.pumpAndSettle();

    // Assert — an empty page that explains itself, rather than a button that vanished.
    expect(find.text('لا توجد ملاحظات على هذه الطلبية'), findsOneWidget);
    expect(find.textContaining('تُكتب الملاحظة عند تغيير حالة الطلبية'), findsOneWidget);
  });

  testWidgets('handed the order, it asks the server for nothing', (tester) async {
    // Arrange
    final subject = order(notes: 'ملاحظة');
    registerCubit(order(notes: 'شيء آخر تماماً'));

    // Act
    await tester.pumpWidget(host(OrderNotesPage(orderId: 7, order: subject)));
    await tester.pumpAndSettle();

    // Assert — what the caller handed over is what is drawn; no request went out to replace it.
    expect(find.text('ملاحظة'), findsOneWidget);
    expect(find.text('شيء آخر تماماً'), findsNothing);
  });

  testWidgets('a cold deep link fetches the order itself', (tester) async {
    // Arrange — nothing handed over, as when the page is opened from a link.
    registerCubit(order(notes: 'ملاحظة من الخادم'));

    // Act
    await tester.pumpWidget(host(const OrderNotesPage(orderId: 7)));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('ملاحظة من الخادم'), findsOneWidget);
  });
}
