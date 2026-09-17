import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/ticket_thread_cubit.dart';
import 'package:dayaa_client/features/support/repositories/support_repository.dart';
import 'package:dayaa_client/features/support/usecases/get_ticket.dart';
import 'package:dayaa_client/features/support/usecases/reply_to_ticket.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSupportRepository extends Mock implements SupportRepository {}

void main() {
  late _MockSupportRepository repository;

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

  setUp(() => repository = _MockSupportRepository());

  TicketThreadCubit build() => TicketThreadCubit(
    ticketId: 7,
    get: GetTicket(repository),
    reply: ReplyToTicket(repository),
  );

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
      messages: [question, answer, TicketMessage(id: 3, from: MessageAuthor.me, body: 'شكراً')],
    );

    blocTest<TicketThreadCubit, TicketThreadState>(
      'redraws the thread from what came back',
      build: () {
        when(
          () => repository.reply(id: 7, body: 'شكراً'),
        ).thenAnswer((_) async => const Right(replied));

        return build();
      },
      seed: () => const TicketThreadState.loaded(thread),
      act: (cubit) => cubit.send('شكراً'),
      expect: () => const [
        TicketThreadState.loaded(thread, isSending: true),
        TicketThreadState.loaded(replied),
      ],
    );

    /// **Nothing is drawn before the server accepted it.** A reply shown optimistically is a
    /// message the customer believes was sent — and support is the one place where that belief
    /// is expensive. A failure leaves the thread exactly as it was, with the reason beside it.
    blocTest<TicketThreadCubit, TicketThreadState>(
      'a failed reply keeps the thread and does not invent a message',
      build: () {
        when(
          () => repository.reply(id: 7, body: 'شكراً'),
        ).thenAnswer((_) async => const Left(NetworkFailure(message: 'لا يوجد اتصال')));

        return build();
      },
      seed: () => const TicketThreadState.loaded(thread),
      act: (cubit) => cubit.send('شكراً'),
      expect: () => const [
        TicketThreadState.loaded(thread, isSending: true),
        TicketThreadState.loaded(
          thread,
          lastFailure: NetworkFailure(message: 'لا يوجد اتصال'),
        ),
      ],
    );

    /// **A reply to a closed thread reopens it**, and that is the server's answer coming back,
    /// not a guess this app makes. The status has to travel with the messages or the screen
    /// keeps drawing «مغلقة» over a conversation that is live again.
    blocTest<TicketThreadCubit, TicketThreadState>(
      'a reply that reopened the ticket brings the new status with it',
      build: () {
        when(() => repository.reply(id: 7, body: 'ما زالت المشكلة')).thenAnswer(
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

    blocTest<TicketThreadCubit, TicketThreadState>(
      'ignores a second send while one is in flight',
      build: () {
        when(() => repository.reply(id: 7, body: any(named: 'body'))).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));

          return const Right(replied);
        });

        return build();
      },
      seed: () => const TicketThreadState.loaded(thread),
      act: (cubit) {
        cubit
          ..send('شكراً')
          ..send('شكراً');
      },
      wait: const Duration(milliseconds: 60),
      verify: (_) {
        verify(() => repository.reply(id: 7, body: any(named: 'body'))).called(1);
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
        verifyNever(() => repository.reply(id: any(named: 'id'), body: any(named: 'body')));
      },
    );

    blocTest<TicketThreadCubit, TicketThreadState>(
      'trims before sending',
      build: () {
        when(
          () => repository.reply(id: 7, body: 'شكراً'),
        ).thenAnswer((_) async => const Right(replied));

        return build();
      },
      seed: () => const TicketThreadState.loaded(thread),
      act: (cubit) => cubit.send('  شكراً  '),
      verify: (_) {
        verify(() => repository.reply(id: 7, body: 'شكراً')).called(1);
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
}
