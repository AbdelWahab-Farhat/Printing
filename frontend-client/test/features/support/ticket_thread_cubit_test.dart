import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/files/picked_file.dart';
import 'package:dayaa_client/core/files/transfer_cancel.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/models/ticket_change.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/open_thread.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/outgoing_message.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/ticket_thread_cubit.dart';
import 'package:dayaa_client/features/support/repositories/support_repository.dart';
import 'package:dayaa_client/features/support/usecases/get_ticket.dart';
import 'package:dayaa_client/features/support/usecases/reply_to_ticket.dart';
import 'package:dayaa_client/features/support/usecases/watch_ticket_changes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSupportRepository extends Mock implements SupportRepository {}

void main() {
  late _MockSupportRepository repository;
  late StreamController<TicketChange> changes;
  late StreamController<void> resumes;
  late OpenThread openThread;

  const question = TicketMessage(id: 1, from: MessageAuthor.me, body: 'الطلبية وصلت ناقصة');
  const answer = TicketMessage(id: 2, from: MessageAuthor.support, body: 'نعتذر، نراجعها الآن');

  const thread = SupportTicket(
    id: 7,
    subject: 'الطلبية وصلت ناقصة',
    status: TicketStatus.open,
    statusLabel: 'مفتوحة',
    unreadCount: 1,
    messages: [question, answer],
  );

  setUp(() {
    repository = _MockSupportRepository();
    changes = StreamController<TicketChange>.broadcast();
    resumes = StreamController<void>.broadcast();
    openThread = OpenThread();

    when(() => repository.watchChanges()).thenAnswer((_) => changes.stream);
    when(() => repository.liveResumed).thenAnswer((_) => resumes.stream);
  });

  tearDown(() async {
    await changes.close();
    await resumes.close();
  });

  TicketThreadCubit build() {
    var issued = 0;

    return TicketThreadCubit(
      ticketId: 7,
      get: GetTicket(repository),
      reply: ReplyToTicket(repository),
      watch: WatchTicketChanges(repository),
      openThread: openThread,
      newToken: () => 't${issued++}',
    );
  }

  void stubReply(
    String body,
    Future<Either<Failure, SupportTicket>> Function(Invocation invocation) answer,
  ) {
    when(
      () => repository.reply(
        id: 7,
        body: body,
        file: any(named: 'file'),
        clientToken: any(named: 'clientToken'),
        onProgress: any(named: 'onProgress'),
        cancel: any(named: 'cancel'),
      ),
    ).thenAnswer(answer);
  }

  /// ما يدفعه المقبس، بعد أن تهدأ المهام المؤجّلة.
  Future<void> live(TicketChange change) async {
    changes.add(change);
    await Future<void>.delayed(Duration.zero);
  }

  group('load', () {
    blocTest<TicketThreadCubit, TicketThreadState>(
      'emits loading then the thread',
      build: () {
        when(() => repository.ticket(7)).thenAnswer((_) async => const Right(thread));

        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => const [
        TicketThreadState.loading(),
        TicketThreadState.loaded(thread),
      ],
    );

    blocTest<TicketThreadCubit, TicketThreadState>(
      'a thread that will not load is a failure state, not an empty conversation',
      build: () {
        when(
          () => repository.ticket(7),
        ).thenAnswer((_) async => const Left(NetworkFailure(message: 'لا يوجد اتصال')));

        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => const [
        TicketThreadState.loading(),
        TicketThreadState.failure(NetworkFailure(message: 'لا يوجد اتصال')),
      ],
    );
  });

  group('send', () {
    const replied = SupportTicket(
      id: 7,
      subject: 'الطلبية وصلت ناقصة',
      status: TicketStatus.open,
      statusLabel: 'مفتوحة',
      messages: [
        question,
        answer,
        TicketMessage(id: 3, from: MessageAuthor.me, body: 'شكراً', clientToken: 't0'),
      ],
    );

    Matcher waiting(List<String> bodies, {OutgoingStatus status = OutgoingStatus.sending}) =>
        isA<TicketThreadLoaded>().having(
          (state) => [
            for (final message in state.outbox)
              if (message.status == status) message.body,
          ],
          'outbox',
          bodies,
        );

    /// **تظهر في الحال بساعة، ثم تهبط رسالةً قبلها الخادم** — كما في تطبيق المحادثة المرجع. الساعة
    /// تقول «لم تصل بعد» بوضوح، فلا يظنّ العميل أنها وصلت قبل أن تصل.
    blocTest<TicketThreadCubit, TicketThreadState>(
      'a message appears at once with a clock, then lands from what came back',
      build: () {
        stubReply('شكراً', (_) async => const Right(replied));

        return build();
      },
      seed: () => const TicketThreadState.loaded(thread),
      act: (cubit) => cubit.send('شكراً'),
      expect: () => [
        waiting(['شكراً']),
        const TicketThreadState.loaded(replied),
      ],
    );

    /// **رسالةٌ رُفضت تبقى في مكانها بعلامةٍ حمراء وسببها**، ولا يضيع ما كُتب؛ والخيط كما كان.
    blocTest<TicketThreadCubit, TicketThreadState>(
      'a failed message stays where it was written, with its reason',
      build: () {
        stubReply('شكراً', (_) async => const Left(NetworkFailure(message: 'لا يوجد اتصال')));

        return build();
      },
      seed: () => const TicketThreadState.loaded(thread),
      act: (cubit) => cubit.send('شكراً'),
      expect: () => [
        waiting(['شكراً']),
        isA<TicketThreadLoaded>()
            .having((s) => s.ticket, 'ticket', thread)
            .having((s) => s.lastFailure, 'lastFailure', const NetworkFailure(message: 'لا يوجد اتصال'))
            .having((s) => s.outbox.single.status, 'status', OutgoingStatus.failed),
      ],
    );

    test('a retry sends it again under the same token, so the server cannot write it twice', () async {
      // Arrange
      final tokens = <String?>[];
      var attempt = 0;
      when(
        () => repository.reply(
          id: 7,
          body: 'شكراً',
          file: any(named: 'file'),
          clientToken: any(named: 'clientToken'),
          onProgress: any(named: 'onProgress'),
          cancel: any(named: 'cancel'),
        ),
      ).thenAnswer((invocation) async {
        tokens.add(invocation.namedArguments[#clientToken] as String?);

        return attempt++ == 0
            ? const Left(NetworkFailure(message: 'لا يوجد اتصال'))
            : const Right(replied);
      });
      final cubit = build()..emit(const TicketThreadState.loaded(thread));
      await cubit.send('شكراً');
      final failed = cubit.state.outbox.single;

      // Act
      await cubit.retry(failed.clientToken);

      // Assert
      expect(tokens, ['t0', 't0']);
      expect(cubit.state.outbox, isEmpty);
      expect(cubit.ticket?.messages.map((m) => m.id), [1, 2, 3]);

      await cubit.close();
    });

    test('a failed message can be let go', () async {
      // Arrange
      stubReply('شكراً', (_) async => const Left(NetworkFailure(message: 'لا يوجد اتصال')));
      final cubit = build()..emit(const TicketThreadState.loaded(thread));
      await cubit.send('شكراً');

      // Act
      cubit.discard(cubit.state.outbox.single.clientToken);

      // Assert
      expect(cubit.state.outbox, isEmpty);
      expect(cubit.ticket, thread);

      await cubit.close();
    });

    /// **واحدةً بعد واحدة، بترتيب كتابتها** — فيصل الخادمَ ما كُتب كما كُتب، والحقل لا يُقفل.
    test('messages written in a row are sent one after another, in order', () async {
      // Arrange
      final sent = <String>[];
      when(
        () => repository.reply(
          id: 7,
          body: any(named: 'body'),
          file: any(named: 'file'),
          clientToken: any(named: 'clientToken'),
          onProgress: any(named: 'onProgress'),
          cancel: any(named: 'cancel'),
        ),
      ).thenAnswer((invocation) async {
        sent.add(invocation.namedArguments[#body] as String);
        await Future<void>.delayed(const Duration(milliseconds: 5));

        return const Right(thread);
      });
      final cubit = build()..emit(const TicketThreadState.loaded(thread));

      // Act
      final first = cubit.send('الأولى');
      final second = cubit.send('الثانية');
      await Future.wait([first, second]);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Assert
      expect(sent, ['الأولى', 'الثانية']);
      expect(cubit.state.outbox, isEmpty);

      await cubit.close();
    });

    /// **A reply to a closed thread reopens it**, and that is the server's answer coming back,
    /// not a guess this app makes. The status has to travel with the messages or the screen
    /// keeps drawing «مغلقة» over a conversation that is live again.
    blocTest<TicketThreadCubit, TicketThreadState>(
      'a reply that reopened the ticket brings the new status with it',
      build: () {
        stubReply(
          'ما زالت المشكلة',
          (_) async => const Right(
            SupportTicket(
              id: 7,
              subject: 'الطلبية وصلت ناقصة',
              status: TicketStatus.open,
              statusLabel: 'مفتوحة',
              messages: [question],
            ),
          ),
        );

        return build();
      },
      seed: () => const TicketThreadState.loaded(
        SupportTicket(
          id: 7,
          subject: 'الطلبية وصلت ناقصة',
          status: TicketStatus.closed,
          statusLabel: 'مغلقة',
          isOpen: false,
          messages: [question],
        ),
      ),
      act: (cubit) => cubit.send('ما زالت المشكلة'),
      verify: (cubit) {
        expect(cubit.ticket?.status, TicketStatus.open);
        expect(cubit.ticket?.statusLabel, 'مفتوحة');
      },
    );

    /// Whitespace is not a message. Sending it would put an empty bubble in a conversation and
    /// a 422 on the wire.
    blocTest<TicketThreadCubit, TicketThreadState>(
      'refuses to send a blank reply',
      build: build,
      seed: () => const TicketThreadState.loaded(thread),
      act: (cubit) => cubit.send('   '),
      expect: () => const <TicketThreadState>[],
      verify: (_) {
        verifyNever(
          () => repository.reply(
            id: any(named: 'id'),
            body: any(named: 'body'),
            file: any(named: 'file'),
            clientToken: any(named: 'clientToken'),
            onProgress: any(named: 'onProgress'),
            cancel: any(named: 'cancel'),
          ),
        );
      },
    );

    blocTest<TicketThreadCubit, TicketThreadState>(
      'trims before sending',
      build: () {
        stubReply('شكراً', (_) async => const Right(replied));

        return build();
      },
      seed: () => const TicketThreadState.loaded(thread),
      act: (cubit) => cubit.send('  شكراً  '),
      verify: (_) {
        verify(
          () => repository.reply(
            id: 7,
            body: 'شكراً',
            file: any(named: 'file'),
            clientToken: any(named: 'clientToken'),
            onProgress: any(named: 'onProgress'),
            cancel: any(named: 'cancel'),
          ),
        ).called(1);
      },
    );

    test('load keeps what is still on its way', () async {
      // Arrange
      final gate = Completer<Either<Failure, SupportTicket>>();
      stubReply('في الطريق', (_) => gate.future);
      when(() => repository.ticket(7)).thenAnswer((_) async => const Right(thread));
      final cubit = build()..emit(const TicketThreadState.loaded(thread));
      unawaited(cubit.send('في الطريق'));
      await Future<void>.delayed(Duration.zero);

      // Act
      await cubit.load();

      // Assert
      expect(cubit.state.outbox.map((m) => m.body), ['في الطريق']);

      gate.complete(const Right(thread));
      await cubit.close();
    });
  });

  group('files', () {
    const photo = PickedFile(path: '/tmp/receipt.jpg', name: 'receipt.jpg', sizeBytes: 240000);

    test('a file shows its upload filling, and ✕ lets it go without an error', () async {
      // Arrange
      when(
        () => repository.reply(
          id: 7,
          body: any(named: 'body'),
          file: photo,
          clientToken: any(named: 'clientToken'),
          onProgress: any(named: 'onProgress'),
          cancel: any(named: 'cancel'),
        ),
      ).thenAnswer((invocation) async {
        final onProgress = invocation.namedArguments[#onProgress] as void Function(double);
        final cancel = invocation.namedArguments[#cancel] as TransferCancel;
        onProgress(0.5);
        await cancel.whenCancelled;

        return const Left(UnexpectedFailure(message: 'أُلغي'));
      });
      final cubit = build()..emit(const TicketThreadState.loaded(thread));

      // Act
      final sending = cubit.sendFile(photo);
      await Future<void>.delayed(Duration.zero);
      final midway = cubit.state.outbox.single.progress;
      cubit.cancelUpload(cubit.state.outbox.single.clientToken);
      await sending;

      // Assert
      expect(midway, 0.5);
      expect(cubit.state.outbox, isEmpty);
      expect((cubit.state as TicketThreadLoaded).lastFailure, isNull);

      await cubit.close();
    });

    blocTest<TicketThreadCubit, TicketThreadState>(
      'a file over the limit is refused before a byte is uploaded',
      build: build,
      seed: () => const TicketThreadState.loaded(thread),
      act: (cubit) => cubit.sendFile(
        const PickedFile(path: '/tmp/huge.pdf', name: 'huge.pdf', sizeBytes: 40 * 1024 * 1024),
      ),
      expect: () => [
        isA<TicketThreadLoaded>().having(
          (s) => s.lastFailure?.message,
          'lastFailure',
          'حجم الملف يجب ألا يتجاوز 25 ميجابايت',
        ),
      ],
      verify: (_) {
        verifyNever(
          () => repository.reply(
            id: any(named: 'id'),
            body: any(named: 'body'),
            file: any(named: 'file'),
            clientToken: any(named: 'clientToken'),
            onProgress: any(named: 'onProgress'),
            cancel: any(named: 'cancel'),
          ),
        );
      },
    );
  });

  /// The screen hands the thread back to the list on its way out, so that the badge it just
  /// cleared clears there too without a second request.
  test('exposes the thread it is holding', () async {
    when(() => repository.ticket(7)).thenAnswer((_) async => const Right(thread));

    final cubit = build();
    await cubit.load();

    expect(cubit.ticket, thread);
  });

  test('a message knows whose it is', () {
    expect(question.isMine, isTrue);
    expect(answer.isMine, isFalse);
  });

  group('live', () {
    const reply = TicketMessage(id: 3, from: MessageAuthor.support, body: 'خرجت مع المندوب');

    SupportTicket ticketWith({List<TicketMessage> messages = const [], int unread = 0}) =>
        SupportTicket(
          id: 7,
          subject: 'الطلبية وصلت ناقصة',
          status: TicketStatus.inProgress,
          statusLabel: 'قيد المعالجة',
          unreadCount: unread,
          messages: messages,
        );

    test('a reply from the shop is added at once and the thread is read quietly', () async {
      // Arrange
      var reads = 0;
      when(() => repository.ticket(7)).thenAnswer((_) async {
        reads++;

        return Right(reads == 1 ? thread : ticketWith(messages: const [question, answer, reply]));
      });
      final cubit = build();
      await cubit.load();

      // Act
      await live(TicketChange(ticket: ticketWith(unread: 1), message: reply));

      // Assert — القراءةُ الصامتة هي ما ينقل المؤشّر فيرى المحلّ ✓✓.
      expect(reads, 2);
      expect(cubit.ticket?.messages.map((m) => m.id), [1, 2, 3]);
      expect(cubit.ticket?.status, TicketStatus.inProgress);

      await cubit.close();
    });

    test('my own message echoed back is neither doubled nor re-read', () async {
      // Arrange
      when(() => repository.ticket(7)).thenAnswer((_) async => const Right(thread));
      final cubit = build();
      await cubit.load();

      // Act
      await live(TicketChange(ticket: ticketWith(), message: question));

      // Assert
      verify(() => repository.ticket(7)).called(1);
      expect(cubit.ticket?.messages.map((m) => m.id), [1, 2]);

      await cubit.close();
    });

    test('a change on another of my tickets is not this thread\'s business', () async {
      // Arrange
      when(() => repository.ticket(7)).thenAnswer((_) async => const Right(thread));
      final cubit = build();
      await cubit.load();

      // Act
      await live(
        const TicketChange(
          ticket: SupportTicket(id: 99, subject: 'أخرى', statusLabel: 'مفتوحة'),
          message: TicketMessage(id: 40, from: MessageAuthor.support, body: 'ليست لهذا الخيط'),
        ),
      );

      // Assert
      expect(cubit.ticket?.messages.map((m) => m.id), [1, 2]);

      await cubit.close();
    });

    test('a reply answer keeps a message that arrived live while it was in flight', () async {
      // Arrange
      when(() => repository.ticket(7)).thenAnswer((_) async => const Right(thread));
      final gate = Completer<Either<Failure, SupportTicket>>();
      stubReply('شكراً', (_) => gate.future);
      final cubit = build();
      await cubit.load();

      // Act — رسالتي في الطريق، وردُّ المحل يصل قبل جوابها.
      final sending = cubit.send('شكراً');
      await live(TicketChange(ticket: ticketWith(), message: reply));
      gate.complete(
        const Right(
          SupportTicket(
            id: 7,
            subject: 'الطلبية وصلت ناقصة',
            statusLabel: 'مفتوحة',
            messages: [question, answer, TicketMessage(id: 4, from: MessageAuthor.me, body: 'شكراً')],
          ),
        ),
      );
      await sending;

      // Assert
      expect(cubit.ticket?.messages.map((m) => m.id), [1, 2, 3, 4]);

      await cubit.close();
    });

    test('while it is alive its ticket counts as open on screen, and not after', () async {
      // Arrange
      when(() => repository.ticket(7)).thenAnswer((_) async => const Right(thread));

      // Act
      final cubit = build();
      final whileOpen = openThread.isShowing(7);
      await cubit.close();

      // Assert — هذا ما يمنع شارة «الدعم» من الإضاءة لردٍّ أمام عيني العميل.
      expect(whileOpen, isTrue);
      expect(openThread.isShowing(7), isFalse);
    });

    blocTest<TicketThreadCubit, TicketThreadState>(
      'when the socket comes back the thread is read again without a spinner',
      build: () {
        var reads = 0;
        when(() => repository.ticket(7)).thenAnswer((_) async {
          reads++;

          return Right(reads == 1 ? thread : ticketWith(messages: const [question, answer, reply]));
        });

        return build();
      },
      act: (cubit) async {
        await cubit.load();

        // Act
        resumes.add(null);
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const TicketThreadState.loading(),
        const TicketThreadState.loaded(thread),
        isA<TicketThreadLoaded>().having((s) => s.ticket.messages, 'messages', hasLength(3)),
      ],
    );
  });
}
