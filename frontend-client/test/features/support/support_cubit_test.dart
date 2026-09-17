import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/pagination/paged_state.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/support_cubit.dart';
import 'package:dayaa_client/features/support/repositories/support_repository.dart';
import 'package:dayaa_client/features/support/usecases/browse_tickets.dart';
import 'package:dayaa_client/features/support/usecases/open_ticket.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSupportRepository extends Mock implements SupportRepository {}

void main() {
  late _MockSupportRepository repository;

  const first = SupportTicket(
    id: 1,
    subject: 'الطلبية وصلت ناقصة',
    status: TicketStatus.open,
    statusLabel: 'مفتوحة',
    unreadCount: 2,
  );
  const second = SupportTicket(
    id: 2,
    subject: 'سؤال عن الأسعار',
    status: TicketStatus.closed,
    statusLabel: 'مغلقة',
    isOpen: false,
  );

  Paginated<SupportTicket> page(
    List<SupportTicket> items, {
    int current = 1,
    int last = 1,
  }) => Paginated<SupportTicket>(
    items: items,
    meta: PageMeta(currentPage: current, perPage: 15, lastPage: last, total: items.length),
  );

  setUp(() => repository = _MockSupportRepository());

  SupportCubit build() =>
      SupportCubit(browse: BrowseTickets(repository), open: OpenTicket(repository));

  void stubList(Paginated<SupportTicket> result) {
    when(
      () => repository.tickets(page: any(named: 'page'), openOnly: any(named: 'openOnly')),
    ).thenAnswer((_) async => Right(result));
  }

  group('load', () {
    blocTest<SupportCubit, SupportState>(
      'emits loading then the first page',
      build: () {
        stubList(page([first, second]));

        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const PagedState<SupportTicket>.loading(),
        PagedState<SupportTicket>.loaded(page: page([first, second])),
      ],
      verify: (_) {
        verify(() => repository.tickets(page: 1, openOnly: null)).called(1);
      },
    );

    /// **Three states, not two.** `openOnly: null` is «الكل», and a `bool` would have to pick a
    /// side — the side it would lose is the one that undoes a narrowing.
    blocTest<SupportCubit, SupportState>(
      'narrowing and then widening reaches all three filters',
      build: () {
        stubList(page([first]));

        return build();
      },
      act: (cubit) async {
        await cubit.narrowTo(true);
        await cubit.narrowTo(false);
        await cubit.narrowTo(null);
      },
      verify: (cubit) {
        verify(() => repository.tickets(page: 1, openOnly: true)).called(1);
        verify(() => repository.tickets(page: 1, openOnly: false)).called(1);
        verify(() => repository.tickets(page: 1, openOnly: null)).called(1);
        expect(cubit.openOnly, isNull);
      },
    );

    /// There is no ticket search endpoint, so the term the base class threads through is
    /// dropped rather than sent to be silently ignored.
    blocTest<SupportCubit, SupportState>(
      'a search term never reaches the wire',
      build: () {
        stubList(page([first]));

        return build();
      },
      act: (cubit) => cubit.load(search: 'ناقصة'),
      verify: (_) {
        verify(() => repository.tickets(page: 1, openOnly: null)).called(1);
      },
    );
  });

  group('loadMore', () {
    blocTest<SupportCubit, SupportState>(
      'appends the next page',
      build: () {
        when(
          () => repository.tickets(page: 1, openOnly: any(named: 'openOnly')),
        ).thenAnswer((_) async => Right(page([first], last: 2)));
        when(
          () => repository.tickets(page: 2, openOnly: any(named: 'openOnly')),
        ).thenAnswer((_) async => Right(page([second], current: 2, last: 2)));

        return build();
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
      },
      verify: (cubit) {
        expect((cubit.state as PagedLoaded<SupportTicket>).page.items, [first, second]);
      },
    );

    blocTest<SupportCubit, SupportState>(
      'ignores a second request while one is in flight',
      build: () {
        when(
          () => repository.tickets(page: 1, openOnly: any(named: 'openOnly')),
        ).thenAnswer((_) async => Right(page([first], last: 2)));
        when(() => repository.tickets(page: 2, openOnly: any(named: 'openOnly'))).thenAnswer((
          _,
        ) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));

          return Right(page([second], current: 2, last: 2));
        });

        return build();
      },
      act: (cubit) async {
        await cubit.load();
        unawaited(cubit.loadMore());
        unawaited(cubit.loadMore());
      },
      wait: const Duration(milliseconds: 60),
      verify: (_) {
        verify(() => repository.tickets(page: 2, openOnly: any(named: 'openOnly'))).called(1);
      },
    );
  });

  group('submit', () {
    const opened = SupportTicket(
      id: 9,
      subject: 'تذكرة جديدة',
      status: TicketStatus.open,
      statusLabel: 'مفتوحة',
    );

    void stubOpen(Either<Failure, SupportTicket> result) {
      when(
        () => repository.open(
          subject: any(named: 'subject'),
          body: any(named: 'body'),
          orderId: any(named: 'orderId'),
        ),
      ).thenAnswer((_) async => result);
    }

    /// The list is most-recently-active first and the server returns it that way, so the top is
    /// exactly where the next read would put this row.
    blocTest<SupportCubit, SupportState>(
      'a new ticket goes to the head of the list',
      build: () {
        stubList(page([first]));
        stubOpen(const Right(opened));

        return build();
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.submit(subject: 'تذكرة جديدة', body: 'التفاصيل');
      },
      verify: (cubit) {
        expect((cubit.state as PagedLoaded<SupportTicket>).page.items, [opened, first]);
      },
    );

    /// The screen opens the thread it just created, so the ticket has to come back out.
    test('hands back the ticket it opened', () async {
      stubList(page([first]));
      stubOpen(const Right(opened));

      final cubit = build();
      await cubit.load();

      final result = await cubit.submit(subject: 'تذكرة جديدة', body: 'التفاصيل');

      expect(result.getOrElse(() => first), opened);
    });

    /// **A ticket that failed to send must not take the list with it.** The threads already
    /// loaded are still readable, and the customer needs to see them while they retry.
    test('a failed send keeps the list and reports the reason', () async {
      stubList(page([first]));
      stubOpen(const Left(NetworkFailure(message: 'لا يوجد اتصال')));

      final cubit = build();
      await cubit.load();

      final result = await cubit.submit(subject: 'تذكرة', body: 'نص');

      expect(result.isLeft(), isTrue);
      expect((cubit.state as PagedLoaded<SupportTicket>).page.items, [first]);
    });
  });

  group('absorb', () {
    /// A thread that was read comes back with its badge cleared. **Patched rather than
    /// refetched** — the caller is holding the server's own answer, and a round trip would
    /// throw the scroll position away to learn what the app already knows.
    blocTest<SupportCubit, SupportState>(
      'replaces the row it matches without a request',
      build: () {
        stubList(page([second, first]));

        return build();
      },
      act: (cubit) async {
        await cubit.load();
        cubit.absorb(first.copyWith(unreadCount: 0));
      },
      verify: (cubit) {
        final items = (cubit.state as PagedLoaded<SupportTicket>).page.items;

        expect(items.map((t) => t.id), [second.id, first.id]);
        expect(items.last.unreadCount, 0);
        verify(() => repository.tickets(page: 1, openOnly: null)).called(1);
      },
    );

    /// **The filter must not become a lie.** A thread that closed while «المفتوحة» is selected
    /// leaves the list rather than sitting there until the next refresh.
    blocTest<SupportCubit, SupportState>(
      'a ticket that closed leaves a list narrowed to the open ones',
      build: () {
        stubList(page([first]));

        return build();
      },
      act: (cubit) async {
        await cubit.narrowTo(true);
        cubit.absorb(first.copyWith(isOpen: false, status: TicketStatus.closed));
      },
      verify: (cubit) {
        expect((cubit.state as PagedLoaded<SupportTicket>).page.items, isEmpty);
      },
    );
  });

  /// A status this build has not heard of must not crash the list — it draws the label the
  /// server sent.
  test('an unknown status falls back rather than throwing', () {
    final parsed = SupportTicket.fromJson(const {
      'id': 5,
      'subject': 'موضوع',
      'status': 'escalated',
      'status_label': 'تم التصعيد',
    });

    expect(parsed.status, TicketStatus.unknown);
    expect(parsed.statusLabel, 'تم التصعيد');
  });
}
