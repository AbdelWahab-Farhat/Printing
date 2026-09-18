import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_counts.dart';
import 'package:dayaa/features/design_tickets/models/design_tickets_filter.dart';
import 'package:dayaa/features/design_tickets/presentation/viewmodel/design_tickets_cubit.dart';
import 'package:dayaa/features/design_tickets/repositories/design_ticket_repository.dart';
import 'package:dayaa/features/design_tickets/usecases/design_ticket_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// The تذاكر التصميم list, its chip row, and the two queues.
///
/// The repository is faked and nothing touches Dio — which is what the abstract contract buys.
///
/// Arrange - Act - Assert throughout.
class _MockDesignTicketRepository extends Mock implements DesignTicketRepository {}

void main() {
  late _MockDesignTicketRepository repository;
  late DesignTicketsCubit cubit;

  const ticket = DesignTicket(
    id: 7,
    code: 'D7',
    title: 'تصميم كيس شحن — أسود',
    description: 'ضع الشعار في المنتصف',
    status: DesignTicketStatus.fresh,
    statusLabel: 'جديد',
    customerId: 3,
    customerName: 'متجر إكس',
    isInSharedPool: true,
  );

  Paginated<DesignTicket> pageOf(
    List<DesignTicket> tickets, {
    int currentPage = 1,
    int lastPage = 1,
  }) {
    return Paginated<DesignTicket>(
      items: tickets,
      meta: PageMeta(
        currentPage: currentPage,
        perPage: 20,
        lastPage: lastPage,
        total: tickets.length,
      ),
    );
  }

  /// Every page this fake is asked for, whatever the filters.
  void answerWith(Either<Failure, Paginated<DesignTicket>> result) {
    when(
      () => repository.tickets(
        statuses: any(named: 'statuses'),
        designer: any(named: 'designer'),
        requestedBy: any(named: 'requestedBy'),
        customerId: any(named: 'customerId'),
        orderId: any(named: 'orderId'),
        search: any(named: 'search'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => result);
  }

  void answerCountsWith(Either<Failure, DesignTicketCounts> result) {
    when(
      () => repository.statusCounts(
        designer: any(named: 'designer'),
        requestedBy: any(named: 'requestedBy'),
        customerId: any(named: 'customerId'),
        orderId: any(named: 'orderId'),
        search: any(named: 'search'),
      ),
    ).thenAnswer((_) async => result);
  }

  setUp(() {
    repository = _MockDesignTicketRepository();
    cubit = DesignTicketsCubit(
      getTickets: GetDesignTickets(repository),
      getCounts: GetDesignTicketCounts(repository),
      acceptTicket: AcceptDesignTicket(repository),
    );
  });

  // `blocTest` closes the cubit it built, and `DesignTicketsCubit.close()` disposes the counts
  // notifier — so an unconditional close here would dispose it twice and fail the test for a
  // reason that has nothing to do with what it asserts.
  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });

  blocTest<DesignTicketsCubit, DesignTicketsState>(
    'loads a page and lands on loaded',
    setUp: () {
      answerWith(Right(pageOf(const [ticket])));
      answerCountsWith(
        const Right(DesignTicketCounts(byStatus: {'new': 1}, total: 1)),
      );
    },
    build: () => cubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<PagedLoading<DesignTicket>>(),
      isA<PagedLoaded<DesignTicket>>().having(
        (state) => state.page.items.single.code,
        'the ticket that came back',
        'D7',
      ),
    ],
  );

  blocTest<DesignTicketsCubit, DesignTicketsState>(
    // RULES §9: the server's Arabic is what the user must see, not a generic sentence.
    'a failure carries the server own message',
    setUp: () {
      answerWith(const Left(Failure.server(message: 'ليس لديك صلاحية')));
      answerCountsWith(const Left(Failure.server(message: 'ليس لديك صلاحية')));
    },
    build: () => cubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<PagedLoading<DesignTicket>>(),
      isA<PagedFailure<DesignTicket>>().having(
        (state) => state.failure.message,
        'the message shown',
        'ليس لديك صلاحية',
      ),
    ],
  );

  blocTest<DesignTicketsCubit, DesignTicketsState>(
    'an empty queue is a loaded state, not a failure',
    setUp: () {
      answerWith(Right(pageOf(const [])));
      answerCountsWith(const Right(DesignTicketCounts.empty()));
    },
    build: () => cubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<PagedLoading<DesignTicket>>(),
      isA<PagedLoaded<DesignTicket>>().having(
        (state) => state.page.items,
        'no tickets',
        isEmpty,
      ),
    ],
  );

  test('the shared pool asks the server for it rather than filtering on the client', () async {
    // Arrange
    answerWith(Right(pageOf(const [ticket])));
    answerCountsWith(const Right(DesignTicketCounts.empty()));

    // Act
    await cubit.showDesigner('none');

    // Assert — «none» is a word, not an id: a null the query string cannot otherwise carry.
    verify(
      () => repository.tickets(
        statuses: any(named: 'statuses'),
        designer: 'none',
        requestedBy: any(named: 'requestedBy'),
        customerId: any(named: 'customerId'),
        orderId: any(named: 'orderId'),
        search: any(named: 'search'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).called(1);
  });

  test('the chip row is asked without a status, so it can say what else there is', () async {
    // Arrange
    answerWith(Right(pageOf(const [ticket])));
    answerCountsWith(
      const Right(DesignTicketCounts(byStatus: {'new': 3, 'in_progress': 5}, total: 8)),
    );

    // Act
    await cubit.showStatus(DesignTicketStatus.inProgress);

    // Assert — the counts call takes every filter *except* the status. Narrowing it by the status
    // already on screen would make every chip but one read zero.
    verify(
      () => repository.statusCounts(
        designer: any(named: 'designer'),
        requestedBy: any(named: 'requestedBy'),
        customerId: any(named: 'customerId'),
        orderId: any(named: 'orderId'),
        search: any(named: 'search'),
      ),
    ).called(1);

    expect(cubit.counts.value.forStatus(DesignTicketStatus.inProgress), 5);
    expect(cubit.counts.value.total, 8);
  });

  test('a failed chip row leaves the last numbers standing', () async {
    // Arrange — the list answered; only the board did not.
    answerWith(Right(pageOf(const [ticket])));
    answerCountsWith(const Right(DesignTicketCounts(byStatus: {'new': 4}, total: 4)));
    await cubit.load();

    answerCountsWith(const Left(Failure.network(message: 'تعذّر الاتصال')));

    // Act
    await cubit.load();

    // Assert — zeros nobody measured would be a worse lie than stale numbers.
    expect(cubit.counts.value.total, 4);
  });

  test('a filter handed in is seeded before the first page is asked for', () async {
    // Arrange
    answerWith(Right(pageOf(const [ticket])));
    answerCountsWith(const Right(DesignTicketCounts.empty()));

    // Act — the filter travels as `extra` on a route and never crosses the wire, so its fields
    // have to be copied onto the cubit first.
    await cubit.start(
      const DesignTicketsFilter(customerId: 3, status: DesignTicketStatus.underReview),
    );

    // Assert
    expect(cubit.customerId, 3);
    expect(cubit.status, DesignTicketStatus.underReview);

    verify(
      () => repository.tickets(
        statuses: ['under_review'],
        designer: any(named: 'designer'),
        requestedBy: any(named: 'requestedBy'),
        customerId: 3,
        orderId: any(named: 'orderId'),
        search: any(named: 'search'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).called(1);
  });
}
