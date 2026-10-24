import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/chat/chat_message.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/voice/voice_note_cache.dart';
import 'package:dayaa/core/voice/voice_recorder.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:dayaa/features/internal_tickets/presentation/viewmodel/internal_thread_cubit.dart';
import 'package:dayaa/features/internal_tickets/repositories/internal_tickets_repository.dart';
import 'package:dayaa/features/internal_tickets/usecases/internal_tickets_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements InternalTicketsRepository {}

class _MockCache extends Mock implements VoiceNoteCache {}

/// محادثةٌ داخلية واحدة — والوعدُ نفسه الذي في محادثة الدعم: **لا شيء يأخذ المحادثة عن الشاشة.**
/// كتابةٌ لم تأخذ تُقال بجانبها، والصوتُ الذي لم يصل يبقى ليُعاد بالرمز نفسه.
///
/// والثاني أن المحادثة حيّة ولا تكذب: البثُّ بلا قارئ، فلا يُطفئ «تعديل» على رسالتي، ورسالةُ زميلي
/// تُقرأ ساعةَ تصل.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockRepository repository;
  late _MockCache cache;
  late StreamController<InternalTicketChange> changes;
  late StreamController<void> resumes;
  late Directory temp;
  var tokens = 0;

  const me = 7;
  const colleague = ChatPerson(id: 9, name: 'هدى');
  const self = ChatPerson(id: me, name: 'سالم');

  setUpAll(() {
    registerFallbackValue(const OutgoingChatMessage(clientToken: 'x'));
  });

  ChatMessage message(int id, {ChatPerson author = self, String body = 'نص'}) =>
      ChatMessage(
        id: id,
        author: author,
        isMine: author.id == me,
        body: body,
        canEdit: author.id == me,
        canDelete: author.id == me,
      );

  InternalTicket ticketWith(List<ChatMessage> messages, {bool isParty = true}) =>
      InternalTicket(
        id: 3,
        code: 'T3',
        title: 'الطلبية متأخرة',
        status: InternalTicketStatus.inProgress,
        opener: self,
        assignee: colleague,
        isParty: isParty,
        canReply: isParty,
        messages: messages,
      );

  final opened = ticketWith([message(1)]);
  const failure = Failure.network(message: 'انقطع الاتصال');

  InternalThreadCubit build() => InternalThreadCubit(
    ticketId: 3,
    me: me,
    get: GetInternalTicket(repository),
    send: SendInternalMessage(repository),
    edit: EditInternalMessage(repository),
    retract: RetractInternalMessage(repository),
    markRead: MarkInternalTicketRead(repository),
    close: CloseInternalTicket(repository),
    transfer: TransferInternalTicket(repository),
    colleagues: GetColleagues(repository),
    watch: WatchInternalTickets(repository),
    voiceCache: cache,
    newToken: () => 'token-${++tokens}',
  );

  Future<void> live(InternalTicketChange change) async {
    changes.add(change);
    await Future<void>.delayed(Duration.zero);
  }

  VoiceRecording recording() {
    final file = File('${temp.path}/note-${DateTime.now().microsecondsSinceEpoch}.m4a')
      ..writeAsBytesSync(List<int>.filled(512, 1));

    return VoiceRecording(
      path: file.path,
      duration: const Duration(seconds: 4),
      waveform: List<int>.filled(48, 30),
    );
  }

  setUp(() {
    tokens = 0;
    repository = _MockRepository();
    cache = _MockCache();
    changes = StreamController<InternalTicketChange>.broadcast();
    resumes = StreamController<void>.broadcast();
    temp = Directory.systemTemp.createTempSync('internal_thread_test');

    when(() => repository.watchTicket(any())).thenAnswer((_) => changes.stream);
    when(() => repository.liveResumed).thenAnswer((_) => resumes.stream);
    when(() => repository.ticket(any())).thenAnswer((_) async => Right(opened));
    when(
      () => repository.markRead(any(), upToMessageId: any(named: 'upToMessageId')),
    ).thenAnswer((_) async => const Right(unit));
    when(() => cache.keep(any(), any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await changes.close();
    await resumes.close();
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  test('loading puts the thread on screen', () async {
    // Arrange
    final cubit = build();

    // Act
    await cubit.load();

    // Assert
    expect(cubit.state, InternalThreadState.loaded(ticket: opened));
    await cubit.close();
  });

  test('a read that never arrives is the failure state', () async {
    // Arrange
    when(() => repository.ticket(any())).thenAnswer((_) async => const Left(failure));
    final cubit = build();

    // Act
    await cubit.load();

    // Assert
    expect(cubit.state, const InternalThreadState.failure(failure));
    await cubit.close();
  });

  test(
    'a sent message replaces the thread with the server\'s and quotes what was chosen',
    () async {
      // Arrange
      final answered = ticketWith([message(1), message(2)]);
      when(() => repository.send(any(), any())).thenAnswer((_) async => Right(answered));
      final cubit = build();
      await cubit.load();
      cubit.replyTo(message(1, author: colleague));

      // Act
      final sent = await cubit.sendText('  وصلت  ');

      // Assert
      expect(sent, isTrue);
      final outgoing =
          verify(() => repository.send(3, captureAny())).captured.single as OutgoingChatMessage;
      expect(outgoing.body, 'وصلت');
      expect(outgoing.replyToMessageId, 1);
      expect(outgoing.clientToken, 'token-1');
      final state = cubit.state as InternalThreadLoaded;
      expect(state.ticket.messages, hasLength(2));
      expect(state.replyingTo, isNull);
      await cubit.close();
    },
  );

  test('an album goes out as one message: the pictures in order, the caption and the quote', () async {
    // Arrange — كبريمولا: الصورُ وتعليقُها رسالةٌ واحدة لا رسائلُ متفرّقة.
    when(() => repository.send(any(), any())).thenAnswer((_) async => Right(opened));
    final cubit = build();
    await cubit.load();
    cubit.replyTo(message(1, author: colleague));
    const front = PickedFile(path: '/tmp/front.jpg', name: 'front.jpg', sizeBytes: 10);
    const back = PickedFile(path: '/tmp/back.jpg', name: 'back.jpg', sizeBytes: 10);
    const side = PickedFile(path: '/tmp/side.jpg', name: 'side.jpg', sizeBytes: 10);

    // Act
    final sent = await cubit.sendImages([front, back, side], caption: '  الوجهان والجانب ');

    // Assert
    expect(sent, isTrue);
    final outgoing =
        verify(() => repository.send(3, captureAny())).captured.single as OutgoingChatMessage;
    expect(outgoing.images, [front, back, side]);
    expect(outgoing.voice, isNull);
    expect(outgoing.body, 'الوجهان والجانب');
    expect(outgoing.replyToMessageId, 1);
    await cubit.close();
  });

  test('an empty album sends nothing', () async {
    // Arrange
    final cubit = build();
    await cubit.load();

    // Act
    final sent = await cubit.sendImages(const []);

    // Assert
    expect(sent, isFalse);
    verifyNever(() => repository.send(any(), any()));
    await cubit.close();
  });

  test('a failed send keeps the thread and says why beside it', () async {
    // Arrange
    when(() => repository.send(any(), any())).thenAnswer((_) async => const Left(failure));
    final cubit = build();
    await cubit.load();

    // Act
    final sent = await cubit.sendText('هل وصلت؟');

    // Assert
    expect(sent, isFalse);
    final state = cubit.state as InternalThreadLoaded;
    expect(state.ticket, opened);
    expect(state.lastFailure, failure);
    expect(state.isWorking, isFalse);
    await cubit.close();
  });

  test('a second press while the first is in flight sends nothing', () async {
    // Arrange
    final gate = Completer<Either<Failure, InternalTicket>>();
    when(() => repository.send(any(), any())).thenAnswer((_) => gate.future);
    final cubit = build();
    await cubit.load();

    // Act
    final first = cubit.sendText('أ');
    final second = await cubit.sendText('ب');
    gate.complete(Right(opened));
    await first;

    // Assert
    expect(second, isFalse);
    verify(() => repository.send(any(), any())).called(1);
    await cubit.close();
  });

  test('a voice note that did not arrive stays, and the retry carries the same token', () async {
    // Arrange
    when(() => repository.send(any(), any())).thenAnswer((_) async => const Left(failure));
    final cubit = build();
    await cubit.load();
    final note = recording();

    // Act
    await cubit.sendVoice(note);
    final pending = (cubit.state as InternalThreadLoaded).unsentVoice;
    await cubit.retryVoice();

    // Assert
    expect(pending, isNotNull);
    expect(pending!.path, note.path);
    expect(pending.durationSeconds, 4);
    final sent = verify(
      () => repository.send(3, captureAny()),
    ).captured.cast<OutgoingChatMessage>();
    expect(sent.map((m) => m.clientToken).toSet(), {'token-1'});
    expect(sent.first.waveform, hasLength(48));
    expect(File(note.path).existsSync(), isTrue);
    await cubit.close();
  });

  test('a voice note that arrives is kept under its attachment and the recording goes', () async {
    // Arrange
    final note = recording();
    final answered = ticketWith([
      message(1),
      const ChatMessage(
        id: 2,
        author: self,
        isMine: true,
        clientToken: 'token-1',
        attachments: [ChatAttachment(id: 44, kind: ChatAttachmentKind.voice)],
      ),
    ]);
    when(() => repository.send(any(), any())).thenAnswer((_) async => Right(answered));
    final cubit = build();
    await cubit.load();

    // Act
    await cubit.sendVoice(note);
    await Future<void>.delayed(Duration.zero);

    // Assert
    verify(() => cache.keep(VoiceNoteCache.keyFor(44), note.path)).called(1);
    expect(File(note.path).existsSync(), isFalse);
    expect((cubit.state as InternalThreadLoaded).unsentVoice, isNull);
    await cubit.close();
  });

  test('discarding an unsent voice note deletes its file', () async {
    // Arrange
    when(() => repository.send(any(), any())).thenAnswer((_) async => const Left(failure));
    final cubit = build();
    await cubit.load();
    final note = recording();
    await cubit.sendVoice(note);

    // Act
    cubit.discardVoice();

    // Assert
    expect((cubit.state as InternalThreadLoaded).unsentVoice, isNull);
    expect(File(note.path).existsSync(), isFalse);
    await cubit.close();
  });

  test('an edit puts the server\'s message in place', () async {
    // Arrange
    final edited = message(1, body: 'معدّلة').copyWith(isEdited: true);
    when(() => repository.edit(any(), any(), any())).thenAnswer((_) async => Right(edited));
    final cubit = build();
    await cubit.load();

    // Act
    final ok = await cubit.editMessage(1, 'معدّلة');

    // Assert
    expect(ok, isTrue);
    final messages = (cubit.state as InternalThreadLoaded).ticket.messages;
    expect(messages.single.body, 'معدّلة');
    expect(messages.single.isEdited, isTrue);
    await cubit.close();
  });

  test('a refused deletion keeps the message and says why', () async {
    // Arrange
    const refused = Failure.forbidden(message: 'مضت 20 دقيقة على إرسال الرسالة');
    when(() => repository.retract(any(), any())).thenAnswer((_) async => const Left(refused));
    final cubit = build();
    await cubit.load();

    // Act
    final ok = await cubit.retractMessage(1);

    // Assert
    expect(ok, isFalse);
    final state = cubit.state as InternalThreadLoaded;
    expect(state.ticket.messages.single.isDeleted, isFalse);
    expect(state.lastFailure, refused);
    await cubit.close();
  });

  test('a colleague\'s live message joins once and is read at once', () async {
    // Arrange
    final cubit = build();
    await cubit.load();
    final fromThem = message(5, author: colleague, body: 'وصلت');
    // حمولةُ البثّ: بلا قارئ، فلا طرفٌ ولا أعلام.
    final broadcast = InternalTicketChange(
      change: 'message_posted',
      ticket: opened.copyWith(messages: const [], isParty: false, canReply: false),
      message: fromThem,
    );

    // Act
    await live(broadcast);
    await live(broadcast);

    // Assert
    final state = cubit.state as InternalThreadLoaded;
    expect(state.ticket.messages.map((m) => m.id), [1, 5]);
    // ما يخصّني لا يأتي من البثّ: الصندوقُ باقٍ.
    expect(state.ticket.canReply, isTrue);
    verify(() => repository.markRead(3, upToMessageId: 5)).called(2);
    await cubit.close();
  });

  test('a live edit of my message keeps my right to edit it', () async {
    // Arrange
    final cubit = build();
    await cubit.load();
    final echo = message(
      1,
      body: 'بعد التعديل',
    ).copyWith(isEdited: true, isMine: false, canEdit: false, canDelete: false);

    // Act
    await live(
      InternalTicketChange(
        change: 'message_edited',
        ticket: opened.copyWith(messages: const []),
        message: echo,
      ),
    );

    // Assert
    final kept = (cubit.state as InternalThreadLoaded).ticket.messages.single;
    expect(kept.body, 'بعد التعديل');
    expect(kept.canEdit, isTrue);
    expect(kept.isMine, isTrue);
    await cubit.close();
  });

  test('my own live echo is not read again', () async {
    // Arrange
    final cubit = build();
    await cubit.load();

    // Act
    await live(
      InternalTicketChange(
        change: 'message_posted',
        ticket: opened.copyWith(messages: const []),
        message: message(6),
      ),
    );

    // Assert
    verifyNever(() => repository.markRead(any(), upToMessageId: any(named: 'upToMessageId')));
    await cubit.close();
  });

  test('a live read moves the ticks', () async {
    // Arrange
    final cubit = build();
    await cubit.load();

    // Act
    await live(
      InternalTicketChange(
        change: 'read',
        ticket: opened.copyWith(
          messages: const [],
          readUpTo: const InternalReadUpTo(opener: 1, assignee: 1),
        ),
      ),
    );

    // Assert
    final ticket = (cubit.state as InternalThreadLoaded).ticket;
    expect(ticket.readByOtherSideUpTo(me), 1);
    await cubit.close();
  });

  test('a live closure is read again quietly, for what I may now do', () async {
    // Arrange
    final closed = opened.copyWith(status: InternalTicketStatus.closed, canReply: false);
    final cubit = build();
    await cubit.load();
    when(() => repository.ticket(any())).thenAnswer((_) async => Right(closed));

    // Act
    await live(
      InternalTicketChange(
        change: 'closed',
        ticket: closed.copyWith(messages: const []),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    // Assert
    final ticket = (cubit.state as InternalThreadLoaded).ticket;
    expect(ticket.status, InternalTicketStatus.closed);
    expect(ticket.canReply, isFalse);
    await cubit.close();
  });

  test('colleagues for a transfer that cannot be read say why and offer none', () async {
    // Arrange
    when(() => repository.colleagues()).thenAnswer((_) async => const Left(failure));
    final cubit = build();
    await cubit.load();

    // Act
    final colleagues = await cubit.colleaguesForTransfer();

    // Assert
    expect(colleagues, isEmpty);
    expect((cubit.state as InternalThreadLoaded).lastFailure, failure);
    await cubit.close();
  });
}
