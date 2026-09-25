import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/models/ticket_change.dart';
import 'package:dayaa/features/support/presentation/viewmodel/ticket_thread_cubit.dart';
import 'package:dayaa/features/support/repositories/support_repository.dart';
import 'package:dayaa/features/support/usecases/support_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// One thread, and the promise that nothing takes the conversation off the screen.
///
/// **The property this file exists for is the failed write.** A reply that did not send must
/// leave the thread exactly where it was and say so beside it — replacing a conversation with
/// «حدث خطأ» over a timeout loses what was said, on the one screen whose entire content is what
/// was said. `TicketThreadLoaded` carries its own `lastFailure` for that reason, and every test
/// below that stubs a `Left` is checking the same promise from a different verb.
///
/// The second is the double-tap guard. «إغلاق» is one press, and two requests would put two
/// closures in the audit trail for one decision.
///
/// **والثالث أن الخيط حيّ ولا يكذب**: ما يصل من المقبس يُلحق مرةً واحدة، ورسالةُ العميل تُقرأ
/// بصمت، وقراءةٌ صامتة تجاوزها خبرٌ أحدث لا تُعرض — ولا يُسقط جوابُ طلبٍ رسالةً وصلت حيّةً أثناءه.
///
/// Arrange - Act - Assert throughout.
class _MockSupportRepository extends Mock implements SupportRepository {}

void main() {
  late _MockSupportRepository repository;
  late StreamController<TicketChange> changes;
  late StreamController<void> resumes;

  setUpAll(() {
    registerFallbackValue(const PickedFile(path: 'x', name: 'x', sizeBytes: 1));
  });

  SupportTicket ticketWith({
    TicketStatus status = TicketStatus.open,
    int? assignedTo,
    List<TicketMessage> messages = const <TicketMessage>[],
  }) => SupportTicket(
    id: 12,
    subject: 'أين طلبيتي؟',
    status: status,
    statusLabel: status.label,
    assignedTo: assignedTo,
    messages: messages,
  );

  const original = TicketMessage(id: 1, from: MessageAuthor.customer, body: 'مرّ أسبوع');
  const answer = TicketMessage(id: 2, from: MessageAuthor.staff, body: 'نعتذر');

  /// The thread as it stands before anybody writes into it.
  final opened = ticketWith(messages: const [original]);

  /// The thread the server returns once a reply lands: its own answer, never one built here.
  final answered = ticketWith(
    status: TicketStatus.inProgress,
    messages: const [original, answer],
  );

  const failure = Failure.network(message: 'انقطع الاتصال');

  TicketThreadCubit build() => TicketThreadCubit(
    ticketId: 12,
    get: GetTicket(repository),
    reply: ReplyToTicket(repository),
    assign: AssignTicket(repository),
    close: CloseTicket(repository),
    reopen: ReopenTicket(repository),
    watch: WatchTicketChanges(repository),
  );

  void stubRead(SupportTicket ticket) {
    when(() => repository.ticket(any())).thenAnswer((_) async => Right(ticket));
  }

  /// ما يدفعه المقبس، بعد أن تهدأ المهام المؤجّلة.
  Future<void> live(TicketChange change) async {
    changes.add(change);
    await Future<void>.delayed(Duration.zero);
  }

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

  group('opening the thread', () {
    blocTest<TicketThreadCubit, TicketThreadState>(
      'reads it once, and that read is what clears the badge',
      setUp: () => stubRead(opened),
      build: build,
      act: (cubit) => cubit.load(),
      // Assert — exactly one GET. The read has a side effect on the server, so a cubit that
      // fetched twice would be marking a thread read on behalf of somebody who opened it once.
      verify: (_) => verify(() => repository.ticket(12)).called(1),
      expect: () => [
        isA<TicketThreadLoading>(),
        isA<TicketThreadLoaded>().having((s) => s.ticket.messages, 'messages', hasLength(1)),
      ],
    );

    blocTest<TicketThreadCubit, TicketThreadState>(
      'a read that fails has nothing to show, so it becomes the failure',
      setUp: () {
        when(() => repository.ticket(any())).thenAnswer((_) async => const Left(failure));
      },
      build: build,
      act: (cubit) => cubit.load(),
      // Assert — the one case where a failure legitimately replaces the screen: there is no
      // conversation to keep.
      expect: () => [isA<TicketThreadLoading>(), isA<TicketThreadFailure>()],
    );
  });

  group('replying', () {
    blocTest<TicketThreadCubit, TicketThreadState>(
      'draws the thread the server returned, never one assembled here',
      setUp: () {
        stubRead(opened);
        when(
          () => repository.reply(any(), body: any(named: 'body')),
        ).thenAnswer((_) async => Right(answered));
      },
      build: build,
      act: (cubit) async {
        await cubit.load();

        expect(await cubit.send('نعتذر'), isTrue);
      },
      verify: (cubit) {
        // Assert — appending locally would show a message with an id and a timestamp this app
        // invented, for a row the database may not have.
        final state = cubit.state as TicketThreadLoaded;

        expect(state.ticket.messages, hasLength(2));
        expect(state.ticket.messages.last.body, 'نعتذر');
        expect(state.ticket.status, TicketStatus.inProgress);
        expect(state.lastFailure, isNull);
        expect(state.isWorking, isFalse);
      },
    );

    blocTest<TicketThreadCubit, TicketThreadState>(
      'a send that fails keeps the conversation and reports beside it',
      setUp: () {
        stubRead(opened);
        when(
          () => repository.reply(any(), body: any(named: 'body')),
        ).thenAnswer((_) async => const Left(failure));
      },
      build: build,
      act: (cubit) async {
        await cubit.load();

        expect(await cubit.send('نعتذر'), isFalse);
      },
      verify: (cubit) {
        // Assert — the whole reason `loaded` carries a failure instead of becoming one.
        final state = cubit.state as TicketThreadLoaded;

        expect(state.ticket.messages, hasLength(1));
        expect(state.lastFailure, failure);
        expect(state.isWorking, isFalse);
      },
    );

    blocTest<TicketThreadCubit, TicketThreadState>(
      'refuses to send whitespace, and trims what it does send',
      setUp: () {
        stubRead(opened);
        when(
          () => repository.reply(any(), body: any(named: 'body')),
        ).thenAnswer((_) async => Right(answered));
      },
      build: build,
      act: (cubit) async {
        await cubit.load();

        expect(await cubit.send('   '), isFalse);
        await cubit.send('  نعتذر  ');
      },
      verify: (_) {
        // Assert — an empty bubble in a customer's thread is worse than a button that did
        // nothing, and the server would have to refuse it anyway.
        verify(() => repository.reply(12, body: 'نعتذر')).called(1);
        verifyNever(() => repository.reply(any(), body: '   '));
      },
    );

    blocTest<TicketThreadCubit, TicketThreadState>(
      'a file goes up with whatever was typed as its caption, and alone when nothing was',
      setUp: () {
        stubRead(opened);
        when(
          () => repository.reply(
            any(),
            body: any(named: 'body'),
            attachment: any(named: 'attachment'),
          ),
        ).thenAnswer((_) async => Right(answered));
      },
      build: build,
      act: (cubit) async {
        await cubit.load();

        await cubit.send('  الفاتورة  ', attachment: const PickedFile(path: '/f.pdf', name: 'f.pdf', sizeBytes: 9));
        await cubit.send('   ', attachment: const PickedFile(path: '/p.jpg', name: 'p.jpg', sizeBytes: 9));
      },
      verify: (_) {
        // Assert — التعليقُ مقصوصاً، وبلا تعليقٍ لا يُرسل نصٌّ فارغ: الخادم يقبل الملف وحده.
        verify(
          () => repository.reply(
            12,
            body: 'الفاتورة',
            attachment: const PickedFile(path: '/f.pdf', name: 'f.pdf', sizeBytes: 9),
          ),
        ).called(1);
        verify(
          () => repository.reply(
            12,
            body: null,
            attachment: const PickedFile(path: '/p.jpg', name: 'p.jpg', sizeBytes: 9),
          ),
        ).called(1);
      },
    );
  });

  group('taking a ticket and putting it back', () {
    blocTest<TicketThreadCubit, TicketThreadState>(
      'assigning sends the id; putting it back in the queue sends null',
      setUp: () {
        stubRead(opened);
        when(
          () => repository.assign(any(), userId: any(named: 'userId')),
        ).thenAnswer((_) async => Right(ticketWith(assignedTo: 9)));
      },
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.assignTo(9);
        await cubit.assignTo(null);
      },
      verify: (_) {
        // Assert — null is «أعدها للطابور», a real instruction rather than a missing one, so it
        // must reach the server as a value and not be dropped as absent.
        verify(() => repository.assign(12, userId: 9)).called(1);
        verify(() => repository.assign(12, userId: null)).called(1);
      },
    );
  });

  group('closing', () {
    blocTest<TicketThreadCubit, TicketThreadState>(
      'a double tap sends one request',
      setUp: () {
        stubRead(opened);
        when(() => repository.close(any())).thenAnswer((_) async {
          // A real round trip: without a gap the guard has no window to be tested in.
          await Future<void>.delayed(const Duration(milliseconds: 20));

          return Right(ticketWith(status: TicketStatus.closed));
        });
      },
      build: build,
      act: (cubit) async {
        await cubit.load();

        // Act — both presses land before the first answer comes back.
        await Future.wait([cubit.closeTicket(), cubit.closeTicket()]);
      },
      verify: (cubit) {
        // Assert — `isWorking` is what stops the second, and two closures for one decision
        // would be two rows in the audit trail.
        verify(() => repository.close(12)).called(1);

        expect((cubit.state as TicketThreadLoaded).ticket.status, TicketStatus.closed);
      },
    );

    blocTest<TicketThreadCubit, TicketThreadState>(
      'writing before the thread has loaded does nothing',
      setUp: () {
        when(() => repository.close(any())).thenAnswer(
          (_) async => Right(ticketWith(status: TicketStatus.closed)),
        );
      },
      build: build,
      act: (cubit) async {
        // Act — no `load()` first: there is no ticket on screen to act on.
        expect(await cubit.closeTicket(), isFalse);
      },
      // Assert — a write against a thread nobody has read would be acting on an id from the
      // route and nothing else.
      verify: (_) => verifyNever(() => repository.close(any())),
      expect: () => <TicketThreadState>[],
    );
  });

  group('reopening', () {
    blocTest<TicketThreadCubit, TicketThreadState>(
      'sends one request and draws the ticket the server returned',
      setUp: () {
        stubRead(ticketWith(status: TicketStatus.closed, messages: const [original]));
        when(() => repository.reopen(any())).thenAnswer(
          (_) async => Right(ticketWith(status: TicketStatus.inProgress, messages: const [original])),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.load();

        expect(await cubit.reopenTicket(), isTrue);
      },
      verify: (cubit) {
        // Assert
        verify(() => repository.reopen(12)).called(1);
        expect((cubit.state as TicketThreadLoaded).ticket.status, TicketStatus.inProgress);
      },
    );
  });

  group('live', () {
    const fresh = TicketMessage(id: 3, from: MessageAuthor.customer, body: 'وصلت؟');

    blocTest<TicketThreadCubit, TicketThreadState>(
      'a customer message arriving live is added, and read at once',
      setUp: () => stubRead(opened),
      build: build,
      act: (cubit) async {
        await cubit.load();

        // Act
        await live(TicketChange(ticket: ticketWith(), message: fresh));
      },
      verify: (cubit) {
        // Assert — مرّتان: فتحُ الخيط، ثم قراءتُه الصامتة التي تُطفئ شارته عند الزملاء.
        verify(() => repository.ticket(12)).called(2);
        expect(
          (cubit.state as TicketThreadLoaded).ticket.messages.map((m) => m.id),
          containsAllInOrder(<int>[1, 3]),
        );
      },
    );

    blocTest<TicketThreadCubit, TicketThreadState>(
      'a message it already holds is not added twice, and a desk message is not re-read',
      setUp: () => stubRead(answered),
      build: build,
      act: (cubit) async {
        await cubit.load();

        // Act — صدى ردّي أنا، يصل من المقبس بعد جواب الطلب.
        await live(TicketChange(ticket: ticketWith(status: TicketStatus.inProgress), message: answer));
      },
      verify: (cubit) {
        // Assert
        verify(() => repository.ticket(12)).called(1);
        expect((cubit.state as TicketThreadLoaded).ticket.messages, hasLength(2));
      },
    );

    blocTest<TicketThreadCubit, TicketThreadState>(
      'what changed on the ticket reaches the screen, and another ticket is ignored',
      setUp: () => stubRead(opened),
      build: build,
      act: (cubit) async {
        await cubit.load();

        // Act — زميلٌ أغلقها، ثم خبرٌ عن تذكرةٍ أخرى.
        await live(TicketChange(ticket: ticketWith(status: TicketStatus.closed)));
        await live(
          const TicketChange(
            ticket: SupportTicket(id: 99, subject: 'أخرى', statusLabel: 'مفتوحة'),
            message: TicketMessage(id: 50, from: MessageAuthor.customer, body: 'ليست لك'),
          ),
        );
      },
      verify: (cubit) {
        // Assert — الحالةُ من الحدث، والخيطُ باقٍ كما هو.
        final ticket = (cubit.state as TicketThreadLoaded).ticket;

        expect(ticket.status, TicketStatus.closed);
        expect(ticket.messages.map((m) => m.id), [1]);
      },
    );

    test('a quiet read overtaken by a newer event is not drawn', () async {
      // Arrange — القراءةُ الصامتة معلّقة حتى يُطلق الاختبار جوابها.
      final gate = Completer<Either<Failure, SupportTicket>>();
      var reads = 0;
      when(() => repository.ticket(any())).thenAnswer((_) {
        reads++;

        return reads == 1 ? Future.value(Right(opened)) : gate.future;
      });
      final cubit = build();
      await cubit.load();

      // Act — رسالةٌ تستدعي القراءة، ثم رسالةٌ أحدث قبل أن تعود.
      await live(TicketChange(ticket: ticketWith(), message: fresh));
      await live(
        TicketChange(
          ticket: ticketWith(),
          message: const TicketMessage(id: 4, from: MessageAuthor.staff, body: 'نتابعها'),
        ),
      );
      gate.complete(Right(ticketWith(messages: const [original, fresh])));
      await Future<void>.delayed(Duration.zero);

      // Assert — جوابُ القراءة لا يعرف الرسالة ٤؛ عرضُه كان سيُخفيها من الشاشة.
      expect((cubit.state as TicketThreadLoaded).ticket.messages.map((m) => m.id), [1, 3, 4]);

      await cubit.close();
    });

    test('a reply answer keeps a message that arrived live while it was in flight', () async {
      // Arrange
      stubRead(opened);
      final gate = Completer<Either<Failure, SupportTicket>>();
      when(() => repository.reply(any(), body: any(named: 'body'))).thenAnswer((_) => gate.future);
      final cubit = build();
      await cubit.load();

      // Act — ردّي في الطريق، والعميل يكتب، ثم يصل جوابي وقد بُني قبل سطره.
      final sending = cubit.send('نعتذر');
      await live(TicketChange(ticket: ticketWith(), message: fresh));
      gate.complete(Right(answered));
      await sending;

      // Assert
      expect((cubit.state as TicketThreadLoaded).ticket.messages.map((m) => m.id), [1, 2, 3]);

      await cubit.close();
    });

    blocTest<TicketThreadCubit, TicketThreadState>(
      'when the socket comes back the thread is read again without a spinner',
      setUp: () {
        var reads = 0;
        when(() => repository.ticket(any())).thenAnswer((_) async {
          reads++;

          return Right(reads == 1 ? opened : ticketWith(messages: const [original, fresh]));
        });
      },
      build: build,
      act: (cubit) async {
        await cubit.load();

        // Act
        resumes.add(null);
        await Future<void>.delayed(Duration.zero);
      },
      // Assert — لا `loading` ثانية: الخيطُ لا يختفي خلف دائرةٍ لأن الشبكة عادت.
      expect: () => [
        isA<TicketThreadLoading>(),
        isA<TicketThreadLoaded>().having((s) => s.ticket.messages, 'messages', hasLength(1)),
        isA<TicketThreadLoaded>().having((s) => s.ticket.messages, 'messages', hasLength(2)),
      ],
    );
  });
}
