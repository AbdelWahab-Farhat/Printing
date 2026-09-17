import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/presentation/viewmodel/support_tickets_cubit.dart';
import 'package:dayaa/features/support/presentation/views/support_tickets_page.dart';
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
  }) => SupportTicket(
    id: id,
    subject: subject,
    status: status,
    statusLabel: status.label,
    customer: const TicketCustomer(id: 4, name: 'سالم', phone: '0910000000'),
    order: order,
    assignedTo: assignee?.id,
    assignee: assignee,
    unreadCount: unread,
    lastMessageAt: DateTime(2026, 9, 16, 8, 30),
  );

  Future<void> arrange(
    List<SupportTicket> tickets, {
    List<String> permissions = const ['support.view', 'support.manage'],
  }) async {
    await Injector.reset();

    repository = _MockSupportRepository();

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
        () => SupportTicketsCubit(browse: BrowseTickets(repository)),
      );
  }

  Widget host() => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => const MaterialApp(
      locale: Locale('ar'),
      supportedLocales: [Locale('ar')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: SupportTicketsPage(),
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
    expect(find.byType(FilterOptionChip), findsNWidgets(offerableTicketStatuses.length + 1));
    expect(find.text('الكل'), findsOneWidget);

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

  testWidgets('a ticket shows who is asking and the number to ring them on', (tester) async {
    // Arrange
    await arrange([ticketWith()]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — the phone is on the card because whoever answers «أين طلبيتي؟» reaches for it
    // next; making them leave the queue to find it is the difference between a ticket answered
    // now and one answered later.
    expect(find.text('أين طلبيتي؟'), findsOneWidget);
    expect(find.text('سالم · 0910000000'), findsOneWidget);
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

    // Assert — «بخصوص الطلبية #77» saves whoever is answering a search they would otherwise
    // run by hand in another screen.
    expect(find.text('بخصوص الطلبية #77'), findsOneWidget);
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
    expect(find.text('لا توجد تذاكر بهذه الحالة'), findsOneWidget);
    verify(
      () => repository.tickets(page: 1, status: TicketStatus.closed, assignedTo: null),
    ).called(1);
  });
}
