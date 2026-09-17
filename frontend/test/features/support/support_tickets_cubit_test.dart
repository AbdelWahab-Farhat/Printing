import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/presentation/viewmodel/support_tickets_cubit.dart';
import 'package:dayaa/features/support/repositories/support_repository.dart';
import 'package:dayaa/features/support/usecases/support_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// The desk's queue, and the three things this cubit adds to `PagedCubit`.
///
/// **The paging itself is not retested here.** Debounce, the out-of-order guard and appending
/// without duplicates are `PagedCubit`'s and are covered where they live; repeating them for
/// every feature that inherits them buys a slower suite and no extra safety.
///
/// What is this cubit's own: the filter reaching the request rather than being applied to a
/// page the server already truncated, `belongs` taking a ticket off a list it has stopped
/// qualifying for, and `absorb` patching a row from the thread screen with no round trip.
///
/// Arrange - Act - Assert throughout.
class _MockSupportRepository extends Mock implements SupportRepository {}

void main() {
  late _MockSupportRepository repository;

  SupportTicket ticketWith({
    int id = 1,
    TicketStatus status = TicketStatus.open,
    int? assignedTo,
    int unread = 0,
  }) => SupportTicket(
    id: id,
    subject: 'سؤال $id',
    status: status,
    statusLabel: status.label,
    assignedTo: assignedTo,
    unreadCount: unread,
  );

  Paginated<SupportTicket> pageOf(List<SupportTicket> tickets) => Paginated<SupportTicket>(
    items: tickets,
    meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: tickets.length),
  );

  void stub(List<SupportTicket> tickets) {
    when(
      () => repository.tickets(
        page: any(named: 'page'),
        status: any(named: 'status'),
        assignedTo: any(named: 'assignedTo'),
      ),
    ).thenAnswer((_) async => Right(pageOf(tickets)));
  }

  SupportTicketsCubit build() => SupportTicketsCubit(browse: BrowseTickets(repository));

  setUp(() {
    repository = _MockSupportRepository();
  });

  group('opening the queue', () {
    blocTest<SupportTicketsCubit, SupportTicketsState>(
      'opens on the whole queue, closed threads included',
      setUp: () => stub([ticketWith(), ticketWith(id: 2, status: TicketStatus.closed)]),
      build: build,
      act: (cubit) => cubit.load(),
      // Assert — no status filter on the first request. «ماذا قلنا لهم آخر مرة؟» is half of
      // what the desk is for, so a queue that opened on «مفتوحة» would hide the answers.
      verify: (cubit) {
        expect(cubit.status, isNull);
        verify(() => repository.tickets(page: 1, status: null, assignedTo: null)).called(1);
      },
      expect: () => [isA<PagedLoading<SupportTicket>>(), isA<PagedLoaded<SupportTicket>>()],
    );
  });

  group('narrowing', () {
    blocTest<SupportTicketsCubit, SupportTicketsState>(
      'sends the chosen status to the server rather than filtering on screen',
      setUp: () => stub([ticketWith(status: TicketStatus.closed)]),
      build: build,
      act: (cubit) => cubit.narrowTo(TicketStatus.closed),
      // Assert — filtering a page the server already truncated would show "three closed
      // tickets" when there are ninety.
      verify: (_) {
        verify(
          () => repository.tickets(page: 1, status: TicketStatus.closed, assignedTo: null),
        ).called(1);
      },
      expect: () => [isA<PagedLoading<SupportTicket>>(), isA<PagedLoaded<SupportTicket>>()],
    );

    blocTest<SupportTicketsCubit, SupportTicketsState>(
      'choosing the chip that is already chosen asks the server nothing',
      setUp: () => stub([ticketWith()]),
      build: build,
      act: (cubit) async {
        await cubit.narrowTo(TicketStatus.open);
        await cubit.narrowTo(TicketStatus.open);
      },
      // Assert — a chip gets tapped twice by accident often enough to matter, and the second
      // tap would otherwise throw the list away and rebuild it identically.
      verify: (_) {
        verify(
          () => repository.tickets(page: 1, status: TicketStatus.open, assignedTo: null),
        ).called(1);
      },
    );
  });

  group('a thread coming back from the screen that read it', () {
    blocTest<SupportTicketsCubit, SupportTicketsState>(
      'patches the row in place, with no second request',
      setUp: () => stub([ticketWith(id: 4, unread: 3), ticketWith(id: 5, unread: 1)]),
      build: build,
      act: (cubit) async {
        await cubit.load();
        clearInteractions(repository);

        // Act — what the thread screen hands back: the same ticket, its badge cleared by the
        // GET that opened it.
        cubit.absorb(ticketWith(id: 4));
      },
      verify: (cubit) {
        // Assert — no refetch. The caller is holding the server's own answer; asking again
        // would throw the scroll position away to learn what the app already knows.
        verifyNever(
          () => repository.tickets(
            page: any(named: 'page'),
            status: any(named: 'status'),
            assignedTo: any(named: 'assignedTo'),
          ),
        );

        final state = cubit.state as PagedLoaded<SupportTicket>;

        expect(state.page.items.map((ticket) => ticket.id), [4, 5]);
        expect(state.page.items.first.unreadCount, 0);
      },
    );

    blocTest<SupportTicketsCubit, SupportTicketsState>(
      'a ticket that has left the filter leaves the list',
      setUp: () => stub([ticketWith(id: 4), ticketWith(id: 5)]),
      build: build,
      act: (cubit) async {
        await cubit.narrowTo(TicketStatus.open);

        // Act — somebody closed it from the thread screen while «مفتوحة» is selected.
        cubit.absorb(ticketWith(id: 4, status: TicketStatus.closed));
      },
      verify: (cubit) {
        // Assert — the chip would otherwise be a lie until the next refresh: a list headed
        // «مفتوحة» still showing a closed thread.
        final state = cubit.state as PagedLoaded<SupportTicket>;

        expect(state.page.items.map((ticket) => ticket.id), [5]);
      },
    );

    blocTest<SupportTicketsCubit, SupportTicketsState>(
      'a ticket assigned away leaves a list scoped to one desk',
      setUp: () => stub([ticketWith(id: 4, assignedTo: 9), ticketWith(id: 5, assignedTo: 9)]),
      build: build,
      act: (cubit) async {
        await cubit.showDeskOf(9);

        // Act — a colleague took it.
        cubit.absorb(ticketWith(id: 4, assignedTo: 11));
      },
      verify: (cubit) {
        // Assert — the same property as the status chip, on the axis the shift lead uses.
        final state = cubit.state as PagedLoaded<SupportTicket>;

        expect(state.page.items.map((ticket) => ticket.id), [5]);
      },
    );
  });

  group('when the queue cannot be read', () {
    blocTest<SupportTicketsCubit, SupportTicketsState>(
      'reports the failure rather than an empty queue',
      setUp: () {
        when(
          () => repository.tickets(
            page: any(named: 'page'),
            status: any(named: 'status'),
            assignedTo: any(named: 'assignedTo'),
          ),
        ).thenAnswer(
          (_) async => const Left(Failure.network(message: 'انقطع الاتصال')),
        );
      },
      build: build,
      act: (cubit) => cubit.load(),
      // Assert — «لا توجد تذاكر» over a failed request tells the desk there is nothing to
      // answer, which is the one wrong thing this screen could say.
      expect: () => [isA<PagedLoading<SupportTicket>>(), isA<PagedFailure<SupportTicket>>()],
    );
  });
}
