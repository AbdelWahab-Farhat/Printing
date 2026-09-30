import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/presentation/viewmodel/support_tickets_cubit.dart';
import 'package:dayaa/features/support/presentation/views/support_tickets_page.dart';
import 'package:dayaa/features/support/presentation/widgets/support_ticket_card.dart';
import 'package:dayaa/features/support/repositories/support_repository.dart';
import 'package:dayaa/features/support/usecases/support_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// تذاكر الدعم on screen — the queue that had nobody reading it.
///
/// **The three things worth pinning are the ones a customer feels.** That the chips name every
/// status the business has and no more, so no part of the queue is unreachable; that «غير
/// مُسندة» is visible at a glance, because an unassigned ticket is one nobody has decided to
/// answer; and that the unread badge is drawn from the server's own count rather than from
/// anything this app counts for itself.
///
/// **There is deliberately no «تذكرة جديدة» to look for.** A ticket is a customer beginning a
/// conversation, and the shop opening one on their behalf would be a thread they never asked
/// for and cannot recognise — `SupportTicketController` has no `store` for the same reason.
/// The test states its absence, because a button is the kind of thing somebody adds helpfully.
///
/// Arrange - Act - Assert throughout.
class _MockSupportRepository extends Mock implements SupportRepository {}

void main() {
  late _MockSupportRepository repository;

  SupportTicket ticketWith({
    int id = 1,
    TicketStatus status = TicketStatus.open,
    String subject = 'أين طلبيتي؟',
    TicketAssignee? assignee,
    int unread = 0,
    TicketOrderRef? order,
    TicketCustomer customer = const TicketCustomer(id: 4, name: 'سالم', phone: '0910000000'),
    DateTime? lastMessageAt,
  }) => SupportTicket(
    id: id,
    subject: subject,
    status: status,
    statusLabel: status.label,
    customer: customer,
    order: order,
    assignedTo: assignee?.id,
    assignee: assignee,
    unreadCount: unread,
    lastMessageAt: lastMessageAt ?? DateTime(2026, 9, 16, 8, 30),
  );

  /// ما على بطاقة التذكرة وحدها — فشرائحُ التصفية فوقها تحمل الكلماتِ نفسها.
  Finder onCard(String text) =>
      find.descendant(of: find.byType(SupportTicketCard), matching: find.text(text));

  Future<void> arrange(
    List<SupportTicket> tickets, {
    List<String> permissions = const ['support.view', 'support.manage'],
  }) async {
    await Injector.reset();

    repository = _MockSupportRepository();

    when(() => repository.watchChanges()).thenAnswer((_) => const Stream.empty());
    when(() => repository.liveResumed).thenAnswer((_) => const Stream<void>.empty());

    when(
      () => repository.tickets(
        page: any(named: 'page'),
        status: any(named: 'status'),
        assignedTo: any(named: 'assignedTo'),
      ),
    ).thenAnswer(
      (_) async => Right(
        Paginated<SupportTicket>(
          items: tickets,
          meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: tickets.length),
        ),
      ),
    );

    sl
      ..registerSingleton<Session>(
        Session()
          ..adopt(
            AuthUser(
              id: 1,
              name: 'عبدالوهاب',
              phone: '0911234567',
              permissions: permissions,
            ),
          ),
      )
      ..registerFactory<SupportTicketsCubit>(
        () => SupportTicketsCubit(
          browse: BrowseTickets(repository),
          watch: WatchTicketChanges(repository),
        ),
      );
  }

  Widget host({bool embedded = false}) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: SupportTicketsPage(embedded: embedded),
    ),
  );

  tearDown(Injector.reset);

  testWidgets('the chips name «الكل» and every status the business has', (tester) async {
    // Arrange
    await arrange([ticketWith()]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — one chip per real status plus «الكل». Derived from the enum in the page, so a
    // fourth status joins the queue without anybody editing a list; this is the check that the
    // derivation is actually wired rather than replaced by a literal again.
    // و«المسندة إليّ» آخراً، لأن الجلسة تعرف من أنا.
    expect(find.byType(FilterOptionChip), findsNWidgets(offerableTicketStatuses.length + 2));
    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('المسندة إليّ'), findsOneWidget);

    // Scoped to the chips on purpose: a ticket card prints its own `status_label`, so an
    // unscoped search for «مفتوحة» finds the row as well as the chip and would pass even if
    // the chip were missing.
    for (final status in offerableTicketStatuses) {
      expect(
        find.descendant(
          of: find.byType(FilterOptionChip),
          matching: find.text(status.label),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('it opens on the whole queue, and offers nothing that opens a ticket', (
    tester,
  ) async {
    // Arrange
    await arrange([ticketWith()]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — the first request carries no status, and there is no «تذكرة جديدة» anywhere.
    verify(() => repository.tickets(page: 1, status: null, assignedTo: null)).called(1);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('تذكرة جديدة'), findsNothing);
  });

  testWidgets('a ticket shows who is asking by code, and the number to ring them on', (
    tester,
  ) async {
    // Arrange
    await arrange([
      ticketWith(
        customer: const TicketCustomer(id: 4, code: 'C12', name: 'سالم', phone: '0910000000'),
      ),
    ]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — الكودُ لا الاسم، كما في بريمولا وبطاقة تذكرة التصميم: هو ما يُقال في الهاتف ويُبحث
    // به. والهاتفُ شريحةٌ وحده لأن من يجيب «أين طلبيتي؟» يمدّ يده إليه بعدها.
    expect(find.text('أين طلبيتي؟'), findsOneWidget);
    expect(onCard('C12'), findsOneWidget);
    expect(onCard('0910000000'), findsOneWidget);
    expect(find.text('سالم'), findsNothing);
  });

  testWidgets('a customer with no code is named instead', (tester) async {
    // Arrange — حمولةٌ أقدم بلا كود: الاسمُ خيرٌ من شريحةٍ فارغة.
    await arrange([ticketWith()]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(onCard('سالم'), findsOneWidget);
  });

  testWidgets('an unassigned ticket says so, and an assigned one names the desk', (
    tester,
  ) async {
    // Arrange
    await arrange([
      ticketWith(id: 1),
      ticketWith(id: 2, assignee: const TicketAssignee(id: 9, name: 'محمد')),
    ]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — «غير مُسندة» is the queue's real question: a ticket nobody has taken is a
    // customer nobody has decided to answer.
    expect(find.text('غير مُسندة'), findsOneWidget);
    expect(find.text('محمد'), findsOneWidget);
  });

  testWidgets('a ticket on my own desk reads «تذكرتك» rather than my name', (tester) async {
    // Arrange — الجلسةُ للمستخدم 1، والتذكرةُ مسندةٌ إليه.
    await arrange([
      ticketWith(assignee: const TicketAssignee(id: 1, name: 'عبدالوهاب')),
    ]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — اسمي على بطاقتي لا يقول شيئاً؛ «تذكرتك» تقول إنها عليّ أنا.
    expect(onCard('تذكرتك'), findsOneWidget);
    expect(find.text('عبدالوهاب'), findsNothing);
  });

  testWidgets('the card wears its status as a chip beside the title', (tester) async {
    // Arrange
    await arrange([ticketWith(status: TicketStatus.inProgress)]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — كلمةُ الخادم نفسها (`status_label`)، على البطاقة لا على شريحة التصفية وحدها.
    expect(onCard(TicketStatus.inProgress.label), findsOneWidget);
  });

  testWidgets('a status filter chip carries the colour dot its card chip wears', (tester) async {
    // Arrange
    await arrange([ticketWith()]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — مفتاحٌ واحد للألوان بين الشرائح والبطاقات؛ و«الكل» و«المسندة إليّ» بلا نقطة.
    final chips = tester.widgetList<FilterOptionChip>(find.byType(FilterOptionChip)).toList();
    final dotted = {for (final chip in chips) chip.label: chip.dot};

    expect(dotted['الكل'], isNull);
    expect(dotted['المسندة إليّ'], isNull);
    for (final status in offerableTicketStatuses) {
      expect(dotted[status.label], isNotNull);
    }
  });

  testWidgets('the card says how long ago the thread last moved', (tester) async {
    // Arrange
    await arrange([
      ticketWith(lastMessageAt: DateTime.now().subtract(const Duration(hours: 3))),
    ]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — «كم انتظر العميل؟» هو سؤالُ الطابور، لا «في أيّ يوم».
    expect(onCard('منذ 3 ساعات'), findsOneWidget);
  });

  testWidgets('the unread badge is the count the server sent', (tester) async {
    // Arrange — one thread with two unread, one with none.
    await arrange([ticketWith(id: 1, unread: 2), ticketWith(id: 2)]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — derived server-side from a read cursor, never stored and never counted here, so
    // it cannot drift from what the desk has actually read.
    expect(find.text('2'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('a ticket about an order names the order', (tester) async {
    // Arrange
    await arrange([ticketWith(order: const TicketOrderRef(id: 77, code: '77'))]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — «طلب 77» saves whoever is answering a search they would otherwise run by hand in
    // another screen.
    expect(onCard('طلب 77'), findsOneWidget);
  });

  testWidgets('an empty queue says which emptiness it is', (tester) async {
    // Arrange — nothing at all, with no chip selected.
    await arrange([]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — «لا توجد تذاكر» means the desk is clear. The narrowed message is a different
    // sentence precisely so a filtered empty screen is not read as an empty queue.
    expect(find.text('لا توجد تذاكر'), findsOneWidget);
  });

  testWidgets('an empty filter says something else entirely', (tester) async {
    // Arrange
    await arrange([]);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act — narrow to «مغلقة», which also returns nothing.
    await tester.tap(find.text(TicketStatus.closed.label));
    await tester.pumpAndSettle();

    // Assert — the distinction matters: one says go home, the other says look elsewhere.
    expect(find.text('لا توجد تذاكر بهذا الاختيار'), findsOneWidget);
    verify(
      () => repository.tickets(page: 1, status: TicketStatus.closed, assignedTo: null),
    ).called(1);
  });

  testWidgets('«المسندة إليّ» asks the server for my desk, and a second tap lets it go', (
    tester,
  ) async {
    // Arrange
    await arrange([ticketWith()]);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act — الشريحةُ آخرُ الصفّ، والصفُّ يتمرّر أفقياً.
    await tester.ensureVisible(find.text('المسندة إليّ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المسندة إليّ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المسندة إليّ'));
    await tester.pumpAndSettle();

    // Assert — رقمي من الجلسة، لا من شيءٍ على الشاشة.
    verify(
      () => repository.tickets(page: 1, status: null, assignedTo: 1),
    ).called(1);
    verify(
      () => repository.tickets(page: 1, status: null, assignedTo: null),
    ).called(2);
  });

  testWidgets('inside the tickets tabs it draws no bar of its own', (tester) async {
    // Arrange — صفحةُ «التذاكر» تحمل الشريطَ وتبويبيه، والطابورُ تحته بلا شريطٍ ثانٍ.
    await arrange([ticketWith()]);

    // Act
    await tester.pumpWidget(host(embedded: true));
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(AppBar), findsNothing);
    expect(find.textContaining('أين طلبيتي؟'), findsOneWidget);
  });
}
