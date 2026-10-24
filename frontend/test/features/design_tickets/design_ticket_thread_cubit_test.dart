import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/chat/chat_message.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/voice/voice_note_cache.dart';
import 'package:dayaa/core/voice/voice_recorder.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_thread.dart';
import 'package:dayaa/features/design_tickets/presentation/viewmodel/design_ticket_thread_cubit.dart';
import 'package:dayaa/features/design_tickets/repositories/design_ticket_thread_repository.dart';
import 'package:dayaa/features/design_tickets/usecases/design_ticket_thread_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements DesignTicketThreadRepository {}

class _MockCache extends Mock implements VoiceNoteCache {}

/// محادثة تذكرة تصميم — بوعود محادثة التذاكر الداخلية نفسها (DESIGN-TICKET-CHAT):
///
/// * **لا شيء يأخذ المحادثة عن الشاشة.** كتابةٌ لم تأخذ تُقال بجانبها، والصوتُ الذي لم يصل يبقى
///   ليُعاد بالرمز نفسه.
/// * **المحادثةُ حيّة ولا تكذب**: البثُّ بلا قارئ، فلا يُطفئ «تعديل» على رسالتي، ورسالةُ الطرف
///   الآخر تُقرأ ساعةَ تصل.
/// * **والصوتُ يُحفظ باسم المحادثة**: رقمُ مرفقها من جدولٍ غير جدول التذاكر الداخلية.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockRepository repository;
  late _MockCache cache;
  late StreamController<DesignTicketThreadChange> changes;
  late StreamController<void> resumes;
  late Directory temp;
  late List<int> bellCounts;
  var tokens = 0;

  const me = 7;
  const designer = ChatPerson(id: 9, name: 'هدى');
  const self = ChatPerson(id: me, name: 'سالم');

  setUpAll(() {
    registerFallbackValue(const OutgoingChatMessage(clientToken: 'x'));
  });

  ChatMessage message(int id, {ChatPerson author = self, String body = 'نص'}) => ChatMessage(
    id: id,
    author: author,
    isMine: author.id == me,
    body: body,
    canEdit: author.id == me,
    canDelete: author.id == me,
  );

  DesignTicketThread threadWith(List<ChatMessage> messages, {bool isParty = true}) =>
      DesignTicketThread(
        ticket: const DesignThreadTicket(
          id: 3,
          code: 'D3',
          title: 'كيس شحن أسود',
          status: DesignTicketStatus.inProgress,
          customerName: 'متجر إكس',
          requester: self,
          designer: designer,
        ),
        isParty: isParty,
        canReply: true,
        messages: messages,
      );

  final opened = threadWith([message(1)]);
  const failure = Failure.network(message: 'انقطع الاتصال');

  DesignTicketThreadCubit build() => DesignTicketThreadCubit(
    ticketId: 3,
    me: me,
    get: GetDesignTicketThread(repository),
    send: SendDesignTicketMessage(repository),
    edit: EditDesignTicketMessage(repository),
    retract: RetractDesignTicketMessage(repository),
    markRead: MarkDesignTicketThreadRead(repository),
    watch: WatchDesignTicketThread(repository),
    voiceCache: cache,
    onBellCount: bellCounts.add,
    newToken: () => 'token-${++tokens}',
  );

  Future<void> live(DesignTicketThreadChange change) async {
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
    bellCounts = [];
    repository = _MockRepository();
    cache = _MockCache();
    changes = StreamController<DesignTicketThreadChange>.broadcast();
    resumes = StreamController<void>.broadcast();
    temp = Directory.systemTemp.createTempSync('design_thread_test');

    when(() => repository.watch(any())).thenAnswer((_) => changes.stream);
    when(() => repository.liveResumed).thenAnswer((_) => resumes.stream);
    when(() => repository.thread(any())).thenAnswer((_) async => Right(opened));
    when(
      () => repository.markRead(any(), upToMessageId: any(named: 'upToMessageId')),
    ).thenAnswer((_) async => const Right(4));
    when(() => cache.keep(any(), any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await changes.close();
    await resumes.close();
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  test('loading puts the thread on screen and sets the bell to what is left', () async {
    // Arrange
    final cubit = build();

    // Act
    await cubit.load();
    await Future<void>.delayed(Duration.zero);

    // Assert — فتحُ المحادثة أطفأ جرسها على الخادم، والرقمُ الجديد يوضع فوق الجرس كما كان يُفعل.
    expect(cubit.state, DesignTicketThreadState.loaded(thread: opened));
    expect(bellCounts, [4]);
    await cubit.close();
  });

  test('a read that never arrives is the failure state', () async {
    // Arrange
    when(() => repository.thread(any())).thenAnswer((_) async => const Left(failure));
    final cubit = build();

    // Act
    await cubit.load();

    // Assert
    expect(cubit.state, const DesignTicketThreadState.failure(failure));
    await cubit.close();
  });

  test('a sent message replaces the thread with the server\'s and quotes what was chosen', () async {
    // Arrange
    final answered = threadWith([message(1), message(2)]);
    when(() => repository.send(any(), any())).thenAnswer((_) async => Right(answered));
    final cubit = build();
    await cubit.load();
    cubit.replyTo(message(1, author: designer));

    // Act
    final sent = await cubit.sendText('  وصلني  ');

    // Assert
    expect(sent, isTrue);
    final outgoing =
        verify(() => repository.send(3, captureAny())).captured.single as OutgoingChatMessage;
    expect(outgoing.body, 'وصلني');
    expect(outgoing.replyToMessageId, 1);
    expect(outgoing.clientToken, 'token-1');
    final state = cubit.state as DesignTicketThreadLoaded;
    expect(state.thread.messages, hasLength(2));
    expect(state.replyingTo, isNull);
    await cubit.close();
  });

  test('a failed send keeps the thread and says why beside it', () async {
    // Arrange
    when(() => repository.send(any(), any())).thenAnswer((_) async => const Left(failure));
    final cubit = build();
    await cubit.load();

    // Act
    final sent = await cubit.sendText('هل وصلك الشعار؟');

    // Assert
    expect(sent, isFalse);
    final state = cubit.state as DesignTicketThreadLoaded;
    expect(state.thread, opened);
    expect(state.lastFailure, failure);
    expect(state.isWorking, isFalse);
    await cubit.close();
  });

  test('a second press while the first is in flight sends nothing', () async {
    // Arrange
    final gate = Completer<Either<Failure, DesignTicketThread>>();
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
    final pending = (cubit.state as DesignTicketThreadLoaded).unsentVoice;
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

  test('a voice note that arrives is kept under its design attachment key', () async {
    // Arrange
    final note = recording();
    final answered = threadWith([
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

    // Assert — باسم المحادثة: مرفقُ رقم ٤٤ في تذكرةٍ داخلية صوتٌ آخر.
    verify(() => cache.keep(VoiceNoteCache.keyFor(44, scope: 'design'), note.path)).called(1);
    expect(File(note.path).existsSync(), isFalse);
    expect((cubit.state as DesignTicketThreadLoaded).unsentVoice, isNull);
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
    expect((cubit.state as DesignTicketThreadLoaded).unsentVoice, isNull);
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
    final messages = (cubit.state as DesignTicketThreadLoaded).thread.messages;
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
    final state = cubit.state as DesignTicketThreadLoaded;
    expect(state.thread.messages.single.isDeleted, isFalse);
    expect(state.lastFailure, refused);
    await cubit.close();
  });

  test('the designer\'s live message joins once and is read at once', () async {
    // Arrange
    final cubit = build();
    await cubit.load();
    await Future<void>.delayed(Duration.zero);
    final fromThem = message(5, author: designer, body: 'رفعتُ النسخة');
    // حمولةُ البثّ: بلا قارئ، فلا طرفٌ ولا صندوق.
    final broadcast = DesignTicketThreadChange(
      change: 'message_posted',
      thread: opened.copyWith(messages: const [], isParty: false, canReply: false),
      message: fromThem,
    );

    // Act
    await live(broadcast);
    await live(broadcast);

    // Assert
    final state = cubit.state as DesignTicketThreadLoaded;
    expect(state.thread.messages.map((m) => m.id), [1, 5]);
    // ما يخصّني لا يأتي من البثّ: الصندوقُ باقٍ.
    expect(state.thread.canReply, isTrue);
    expect(state.thread.isParty, isTrue);
    verify(() => repository.markRead(3, upToMessageId: 5)).called(2);
    await cubit.close();
  });

  test('a reader who is neither party does not read live messages on anyone\'s behalf', () async {
    // Arrange
    when(
      () => repository.thread(any()),
    ).thenAnswer((_) async => Right(threadWith([message(1)], isParty: false)));
    final cubit = build();
    await cubit.load();
    await Future<void>.delayed(Duration.zero);
    clearInteractions(repository);

    // Act
    await live(
      DesignTicketThreadChange(
        change: 'message_posted',
        thread: opened.copyWith(messages: const []),
        message: message(5, author: designer),
      ),
    );

    // Assert
    verifyNever(() => repository.markRead(any(), upToMessageId: any(named: 'upToMessageId')));
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
      DesignTicketThreadChange(
        change: 'message_edited',
        thread: opened.copyWith(messages: const []),
        message: echo,
      ),
    );

    // Assert
    final kept = (cubit.state as DesignTicketThreadLoaded).thread.messages.single;
    expect(kept.body, 'بعد التعديل');
    expect(kept.canEdit, isTrue);
    expect(kept.isMine, isTrue);
    await cubit.close();
  });

  test('a live read moves the ticks', () async {
    // Arrange
    final cubit = build();
    await cubit.load();

    // Act
    await live(
      DesignTicketThreadChange(
        change: 'read',
        thread: opened.copyWith(
          messages: const [],
          readUpTo: const DesignThreadReadUpTo(requester: 1, designer: 1),
        ),
      ),
    );

    // Assert
    final thread = (cubit.state as DesignTicketThreadLoaded).thread;
    expect(thread.readByOtherSideUpTo(me), 1);
    await cubit.close();
  });
}
