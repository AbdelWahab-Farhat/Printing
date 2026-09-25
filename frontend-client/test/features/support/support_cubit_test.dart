import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/pagination/paged_state.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/models/ticket_change.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/support_cubit.dart';
import 'package:dayaa_client/features/support/repositories/support_repository.dart';
import 'package:dayaa_client/features/support/usecases/browse_tickets.dart';
import 'package:dayaa_client/features/support/usecases/open_ticket.dart';
import 'package:dayaa_client/features/support/usecases/watch_ticket_changes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSupportRepository extends Mock implements SupportRepository {}

void main() {
  late _MockSupportRepository repository;
  late StreamController<TicketChange> changes;
  late StreamController<void> resumes;

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

  setUp(() {
    repository = _MockSupportRepository();
    changes = StreamController<TicketChange>.broadcast();
    resumes = StreamController<void>.broadcast();

    when(() => repository.watchChanges()).thenAnswer((_) => changes.stream);
    when(() => repository.liveResumed).thenAnswer((_) => resumes.stream);
  });

  tearDown(() async {
    await changes.close();
    await resumes.close();
  });

  SupportCubit build() => SupportCubit(
    browse: BrowseTickets(repository),
    open: OpenTicket(repository),
    watch: WatchTicketChanges(repository),
  );

  Future<void> live(TicketChange change) async {
    changes.add(change);
    await Future<void>.delayed(Duration.zero);
  }

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

  group('absorb across the two tabs', () {
    /// «الدعم» تبويبان لكلٍّ قائمته: تذكرةٌ أعاد ردُّ العميل فتحها تظهر في «المفتوحة» ساعةَ
    /// يعود من المحادثة، بلا طلب — والمعاينة ردُّه هو.
    blocTest<SupportCubit, SupportState>(
      'a ticket that reopened arrives in the open list with the words just written',
      build: () {
        stubList(
          page([
            second.copyWith(
              isOpen: true,
              status: TicketStatus.inProgress,
              lastMessageAt: DateTime(2026, 9, 1),
            ),
          ]),
        );

        return build();
      },
      act: (cubit) async {
        await cubit.narrowTo(true);
        cubit.absorb(
          first.copyWith(
            isOpen: true,
            status: TicketStatus.open,
            lastMessageAt: DateTime(2030),
            messages: const [TicketMessage(id: 90, from: MessageAuthor.me, body: 'ما زالت المشكلة')],
          ),
        );
      },
      verify: (cubit) {
        final items = (cubit.state as PagedLoaded<SupportTicket>).page.items;

        expect(items.map((t) => t.id), [first.id, second.id]);
        expect(items.first.preview, 'ما زالت المشكلة');
        expect(items.first.messages, isEmpty);
      },
    );

    blocTest<SupportCubit, SupportState>(
      'a file sent with no words is previewed by what it is',
      build: () {
        stubList(page([first]));

        return build();
      },
      act: (cubit) async {
        await cubit.load();
        cubit.absorb(
          first.copyWith(
            messages: const [
              TicketMessage(
                id: 91,
                from: MessageAuthor.me,
                attachment: TicketAttachment(kind: AttachmentKind.pdf, name: 'quote.pdf'),
              ),
            ],
          ),
        );
      },
      verify: (cubit) {
        final items = (cubit.state as PagedLoaded<SupportTicket>).page.items;

        expect(items.single.preview, 'quote.pdf');
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

  group('live', () {
    DateTime at(int minute) => DateTime.utc(2026, 9, 25, 12, minute);

    SupportTicket row(int id, {int minute = 0, bool isOpen = true, int unread = 0, String? preview}) =>
        SupportTicket(
          id: id,
          subject: 'سؤال $id',
          status: isOpen ? TicketStatus.open : TicketStatus.closed,
          statusLabel: isOpen ? 'مفتوحة' : 'مغلقة',
          isOpen: isOpen,
          unreadCount: unread,
          preview: preview,
          messagesCount: 1,
          lastMessageAt: at(minute),
        );

    List<int> ids(SupportCubit cubit) =>
        (cubit.state as PagedLoaded<SupportTicket>).page.items.map((t) => t.id).toList();

    test('a reply from the shop lifts its thread to the top, with the reply as its preview', () async {
      // Arrange
      stubList(page([row(1, minute: 30, preview: 'سؤالي'), row(2, minute: 20, preview: 'سؤالٌ آخر')]));
      final cubit = build();
      await cubit.load();

      // Act — الحدثُ بلا `preview`؛ الرسالةُ نفسها فيه.
      await live(
        TicketChange(
          ticket: row(2, minute: 40, unread: 1).copyWith(preview: null),
          message: const TicketMessage(id: 9, from: MessageAuthor.support, body: 'وصلت الشحنة'),
        ),
      );

      // Assert
      final top = (cubit.state as PagedLoaded<SupportTicket>).page.items.first;
      expect(ids(cubit), [2, 1]);
      expect(top.unreadCount, 1);
      expect(top.preview, 'وصلت الشحنة');

      await cubit.close();
    });

    test('a change with nothing said keeps the preview the row was drawn with', () async {
      // Arrange
      stubList(page([row(1, minute: 30, preview: 'سؤالي')]));
      final cubit = build();
      await cubit.load();

      // Act — أُغلقت، ولم يُقل شيء.
      await live(TicketChange(ticket: row(1, minute: 30, isOpen: false).copyWith(preview: null)));

      // Assert
      final only = (cubit.state as PagedLoaded<SupportTicket>).page.items.single;
      expect(only.isOpen, isFalse);
      expect(only.preview, 'سؤالي');

      await cubit.close();
    });

    test('a thread closed while «المفتوحة» is chosen leaves the list', () async {
      // Arrange
      stubList(page([row(1, minute: 30), row(3, minute: 10)]));
      final cubit = build();
      await cubit.narrowTo(true);

      // Act
      await live(TicketChange(ticket: row(1, minute: 30, isOpen: false)));

      // Assert
      expect(ids(cubit), [3]);

      await cubit.close();
    });

    test('when the socket comes back page one is read quietly and placed', () async {
      // Arrange
      var reads = 0;
      when(
        () => repository.tickets(page: any(named: 'page'), openOnly: any(named: 'openOnly')),
      ).thenAnswer((_) async {
        reads++;

        return Right(page(reads == 1 ? [row(1, minute: 30)] : [row(5, minute: 50, unread: 1), row(1, minute: 30)]));
      });
      final cubit = build();
      await cubit.load();
      final states = <SupportState>[];
      final watching = cubit.stream.listen(states.add);

      // Act
      resumes.add(null);
      await Future<void>.delayed(Duration.zero);

      // Assert — لا هيكلَ رمادياً: القائمةُ لا تختفي لأن الشبكة عادت.
      expect(states.whereType<PagedLoading<SupportTicket>>(), isEmpty);
      expect(ids(cubit), [5, 1]);

      await watching.cancel();
      await cubit.close();
    });
  });
}
