import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/chat/chat_message.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket_query.dart';
import 'package:dayaa/features/internal_tickets/presentation/viewmodel/internal_tickets_cubit.dart';
import 'package:dayaa/features/internal_tickets/presentation/viewmodel/internal_tickets_home_cubit.dart';
import 'package:dayaa/features/internal_tickets/presentation/viewmodel/new_internal_ticket_cubit.dart';
import 'package:dayaa/features/internal_tickets/repositories/internal_tickets_repository.dart';
import 'package:dayaa/features/internal_tickets/usecases/internal_tickets_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements InternalTicketsRepository {}

/// القائمة، وبطاقةُ الرئيسية، ونموذجُ «تذكرة جديدة».
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockRepository repository;
  late StreamController<int> mine;
  late StreamController<void> resumes;

  const failure = Failure.network(message: 'انقطع الاتصال');

  setUpAll(() {
    registerFallbackValue(const InternalTicketQuery());
    registerFallbackValue(const OutgoingChatMessage(clientToken: 'x'));
    registerFallbackValue(const InternalTicketDraft(assigneeId: 1, title: 'x', description: 'xyz'));
  });

  InternalTicket ticket(
    int id, {
    InternalTicketStatus status = InternalTicketStatus.inProgress,
    int unread = 0,
    DateTime? at,
  }) => InternalTicket(
    id: id,
    code: 'T$id',
    title: 'تذكرة $id',
    status: status,
    unreadCount: unread,
    lastMessageAt: at,
  );

  Paginated<InternalTicket> page(List<InternalTicket> items) => Paginated<InternalTicket>(
    items: items,
    meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: items.length),
  );

  setUp(() {
    repository = _MockRepository();
    mine = StreamController<int>.broadcast();
    resumes = StreamController<void>.broadcast();
    when(() => repository.watchMine(any())).thenAnswer((_) => mine.stream);
    when(() => repository.liveResumed).thenAnswer((_) => resumes.stream);
  });

  tearDown(() async {
    await mine.close();
    await resumes.close();
  });

  group('the list', () {
    InternalTicketsCubit build({InternalTicketQuery query = const InternalTicketQuery()}) =>
        InternalTicketsCubit(
          browse: BrowseInternalTickets(repository),
          watch: WatchInternalTickets(repository),
          me: 7,
          query: query,
        );

    void stubPage(List<InternalTicket> items) {
      when(
        () => repository.tickets(
          query: any(named: 'query'),
          search: any(named: 'search'),
          page: any(named: 'page'),
        ),
      ).thenAnswer((_) async => Right(page(items)));
    }

    test('it asks with its query and the search typed', () async {
      // Arrange
      stubPage([ticket(1)]);
      final cubit = build(query: const InternalTicketQuery(orderId: 55));

      // Act
      await cubit.load(search: 'T1');

      // Assert
      final captured =
          verify(
                () => repository.tickets(
                  query: captureAny(named: 'query'),
                  search: 'T1',
                  page: 1,
                ),
              ).captured.single
              as InternalTicketQuery;
      expect(captured.orderId, 55);
      expect(captured.status, InternalTicketStatus.inProgress);
      await cubit.close();
    });

    test('narrowing asks again, and the same question twice does not', () async {
      // Arrange
      stubPage([]);
      final cubit = build();
      await cubit.load();

      // Act
      await cubit.narrow(const InternalTicketQuery(status: InternalTicketStatus.closed));
      await cubit.narrow(const InternalTicketQuery(status: InternalTicketStatus.closed));

      // Assert
      verify(
        () => repository.tickets(
          query: any(named: 'query'),
          search: any(named: 'search'),
          page: any(named: 'page'),
        ),
      ).called(2);
      expect(cubit.query.status, InternalTicketStatus.closed);
      await cubit.close();
    });

    test('a ticket closed while «قيد المعالجة» is shown leaves the list', () async {
      // Arrange
      stubPage([ticket(1), ticket(2)]);
      final cubit = build();
      await cubit.load();

      // Act
      cubit.absorb(ticket(1, status: InternalTicketStatus.closed));

      // Assert
      final items = (cubit.state as PagedLoaded<InternalTicket>).page.items;
      expect(items.map((t) => t.id), [2]);
      await cubit.close();
    });

    test('live signals in a row read page one once, quietly, and place what changed', () async {
      // Arrange
      stubPage([ticket(1, at: DateTime(2026, 10, 1)), ticket(2, at: DateTime(2026, 10, 2))]);
      final cubit = InternalTicketsCubit(
        browse: BrowseInternalTickets(repository),
        watch: WatchInternalTickets(repository),
        me: 7,
        catchUpDelay: Duration.zero,
      );
      await cubit.load();
      stubPage([ticket(1, unread: 3, at: DateTime(2026, 10, 3))]);

      // Act
      mine
        ..add(1)
        ..add(1);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Assert — إشارتان متتاليتان طلبٌ واحد، والتذكرةُ صعدت بشارتها.
      final items = (cubit.state as PagedLoaded<InternalTicket>).page.items;
      expect(items.first.id, 1);
      expect(items.first.unreadCount, 3);
      verify(
        () => repository.tickets(
          query: any(named: 'query'),
          search: any(named: 'search'),
          page: any(named: 'page'),
        ),
      ).called(2);
      await cubit.close();
    });
  });

  group('the home card', () {
    const home = InternalTicketsHome(awaitingMyReply: 2, totalOpen: 3, unreadTickets: 1);

    InternalTicketsHomeCubit build() => InternalTicketsHomeCubit(
      get: GetInternalTicketsHome(repository),
      send: SendInternalMessage(repository),
      markSeen: MarkInternalTicketSeen(repository),
      watch: WatchInternalTickets(repository),
      me: 7,
      newToken: () => 'home-1',
    );

    test('it loads what waits on me', () async {
      // Arrange
      when(() => repository.home()).thenAnswer((_) async => const Right(home));
      final cubit = build();

      // Act
      await cubit.load();

      // Assert
      expect(cubit.state, const InternalTicketsHomeState.loaded(home: home));
      await cubit.close();
    });

    test('a failed refresh keeps the card that was there', () async {
      // Arrange
      when(() => repository.home()).thenAnswer((_) async => const Right(home));
      final cubit = build();
      await cubit.load();
      when(() => repository.home()).thenAnswer((_) async => const Left(failure));

      // Act
      await cubit.load();

      // Assert
      expect(cubit.state, const InternalTicketsHomeState.loaded(home: home));
      await cubit.close();
    });

    test('a quick reply is sent and the card is read again', () async {
      // Arrange
      when(() => repository.home()).thenAnswer((_) async => const Right(home));
      when(() => repository.send(any(), any())).thenAnswer((_) async => Right(ticket(4)));
      final cubit = build();
      await cubit.load();

      // Act
      final sent = await cubit.quickReply(4, ' تمام ');
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(sent, isTrue);
      final outgoing =
          verify(() => repository.send(4, captureAny())).captured.single as OutgoingChatMessage;
      expect(outgoing.body, 'تمام');
      verify(() => repository.home()).called(2);
      await cubit.close();
    });

    test('the read mark takes the row off at once, up to the message that was on it', () async {
      // Arrange
      final waiting = ticket(4).copyWith(
        awaitingMyReply: true,
        lastMessage: const InternalLastMessage(id: 40, authorId: 9),
      );
      final withRows = home.copyWith(tickets: [ticket(3), waiting]);
      when(() => repository.home()).thenAnswer((_) async => Right(withRows));
      when(
        () => repository.markSeen(any(), upToMessageId: any(named: 'upToMessageId')),
      ).thenAnswer((_) async => const Right(unit));
      final cubit = build();
      await cubit.load();

      // Act
      final failed = await cubit.markSeen(4);

      // Assert
      expect(failed, isNull);
      final state = cubit.state as InternalTicketsHomeLoaded;
      expect(state.home.tickets.map((row) => row.id), [3]);
      expect(state.home.awaitingMyReply, 1);
      verify(() => repository.markSeen(4, upToMessageId: 40)).called(1);
      verify(() => repository.home()).called(1);
      await cubit.close();
    });

    test('a read mark that fails puts the row back where it was and says why', () async {
      // Arrange
      final withRows = home.copyWith(tickets: [ticket(3), ticket(4), ticket(5)]);
      when(() => repository.home()).thenAnswer((_) async => Right(withRows));
      when(
        () => repository.markSeen(any(), upToMessageId: any(named: 'upToMessageId')),
      ).thenAnswer((_) async => const Left(failure));
      final cubit = build();
      await cubit.load();

      // Act
      final failed = await cubit.markSeen(4);

      // Assert
      expect(failed, failure);
      final state = cubit.state as InternalTicketsHomeLoaded;
      expect(state.home.tickets.map((row) => row.id), [3, 4, 5]);
      expect(state.home.awaitingMyReply, 2);
      expect(state.lastFailure, isNull);
      await cubit.close();
    });

    test('a quick reply that fails says why and keeps the card', () async {
      // Arrange
      when(() => repository.home()).thenAnswer((_) async => const Right(home));
      when(() => repository.send(any(), any())).thenAnswer((_) async => const Left(failure));
      final cubit = build();
      await cubit.load();

      // Act
      final sent = await cubit.quickReply(4, 'تمام');

      // Assert
      expect(sent, isFalse);
      final state = cubit.state as InternalTicketsHomeLoaded;
      expect(state.lastFailure, failure);
      expect(state.replyingTo, isNull);
      await cubit.close();
    });
  });

  group('a new ticket', () {
    const colleagues = [Colleague(id: 9, name: 'هدى', openTicketsWithMe: 2)];
    const categories = [InternalCategory(id: 1, name: 'طلبية')];
    const draft = InternalTicketDraft(assigneeId: 9, title: 'سؤال', description: 'تفاصيل');

    NewInternalTicketCubit build() => NewInternalTicketCubit(
      colleagues: GetColleagues(repository),
      categories: GetInternalCategories(repository),
      open: OpenInternalTicket(repository),
    );

    test('it is ready with the colleagues and the kinds', () async {
      // Arrange
      when(() => repository.colleagues()).thenAnswer((_) async => const Right(colleagues));
      when(() => repository.categories()).thenAnswer((_) async => const Right(categories));
      final cubit = build();

      // Act
      await cubit.load();

      // Assert
      expect(
        cubit.state,
        const NewInternalTicketState.ready(colleagues: colleagues, categories: categories),
      );
      await cubit.close();
    });

    test('kinds that did not arrive do not stop a ticket being opened', () async {
      // Arrange
      when(() => repository.colleagues()).thenAnswer((_) async => const Right(colleagues));
      when(() => repository.categories()).thenAnswer((_) async => const Left(failure));
      final cubit = build();

      // Act
      await cubit.load();

      // Assert
      expect(
        cubit.state,
        const NewInternalTicketState.ready(colleagues: colleagues, categories: []),
      );
      await cubit.close();
    });

    test('without the colleagues there is no form', () async {
      // Arrange
      when(() => repository.colleagues()).thenAnswer((_) async => const Left(failure));
      when(() => repository.categories()).thenAnswer((_) async => const Right(categories));
      final cubit = build();

      // Act
      await cubit.load();

      // Assert
      expect(cubit.state, const NewInternalTicketState.failure(failure));
      await cubit.close();
    });

    test('an opened ticket is handed to the screen, with at most four photos', () async {
      // Arrange
      when(() => repository.colleagues()).thenAnswer((_) async => const Right(colleagues));
      when(() => repository.categories()).thenAnswer((_) async => const Right(categories));
      when(
        () => repository.open(any(), images: any(named: 'images')),
      ).thenAnswer((_) async => Right(ticket(31)));
      final cubit = build();
      await cubit.load();
      final photos = [
        for (var i = 0; i < 6; i++) PickedFile(path: 'p$i.jpg', name: 'p$i.jpg', sizeBytes: 10),
      ];

      // Act
      await cubit.submit(draft, images: photos);

      // Assert
      expect((cubit.state as NewInternalTicketReady).created?.id, 31);
      final sent =
          verify(() => repository.open(draft, images: captureAny(named: 'images'))).captured.single
              as List<PickedFile>;
      expect(sent, hasLength(4));
      await cubit.close();
    });

    test('a refusal keeps the form and carries the server\'s reasons', () async {
      // Arrange
      const refused = Failure.server(
        message: 'تحقق من البيانات',
        fieldErrors: {
          'assignee_id': ['لا تُفتح تذكرة مع نفسك'],
        },
      );
      when(() => repository.colleagues()).thenAnswer((_) async => const Right(colleagues));
      when(() => repository.categories()).thenAnswer((_) async => const Right(categories));
      when(
        () => repository.open(any(), images: any(named: 'images')),
      ).thenAnswer((_) async => const Left(refused));
      final cubit = build();
      await cubit.load();

      // Act
      await cubit.submit(draft);

      // Assert
      final state = cubit.state as NewInternalTicketReady;
      expect(state.lastFailure, refused);
      expect(state.isSubmitting, isFalse);
      expect(state.created, isNull);
      await cubit.close();
    });
  });
}
