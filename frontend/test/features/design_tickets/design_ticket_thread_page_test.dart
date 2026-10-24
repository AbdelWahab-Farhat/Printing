import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/chat/chat_composer.dart';
import 'package:dayaa/core/chat/chat_message.dart';
import 'package:dayaa/core/chat/voice_note_view.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/voice/voice_note_cache.dart';
import 'package:dayaa/core/voice/voice_playback.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_thread.dart';
import 'package:dayaa/features/design_tickets/presentation/viewmodel/design_ticket_thread_cubit.dart';
import 'package:dayaa/features/design_tickets/presentation/views/design_ticket_thread_page.dart';
import 'package:dayaa/features/design_tickets/repositories/design_ticket_thread_repository.dart';
import 'package:dayaa/features/design_tickets/usecases/design_ticket_thread_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements DesignTicketThreadRepository {}

class _MockCache extends Mock implements VoiceNoteCache {}

/// «الرد داخل التذكرة» — **محادثةُ التذكرة الداخلية نفسها** (DESIGN-TICKET-CHAT §٢): الطرفُ الآخر في
/// الشريط، والعنوانُ والعميلُ تحته، والصندوقُ بمشبكه وميكروفونه، والصوتُ مشغّلٌ بموجته. والتذكرةُ
/// المنتهية تُقرأ ولا يُكتب فيها، ومكانَ الصندوق سببُ انتهائها.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockRepository repository;
  late StreamController<DesignTicketThreadChange> changes;

  const me = 7;
  const requester = ChatPerson(id: me, name: 'سالم');
  const designer = ChatPerson(id: 9, name: 'هدى');

  DesignTicketThread thread({
    DesignTicketStatus status = DesignTicketStatus.inProgress,
    bool canReply = true,
    String? closedNote,
    List<ChatMessage> messages = const [],
  }) => DesignTicketThread(
    ticket: DesignThreadTicket(
      id: 3,
      code: 'D3',
      title: 'كيس شحن أسود',
      status: status,
      statusLabel: status.label,
      isOpen: canReply,
      customerName: 'متجر إكس',
      requester: requester,
      designer: designer,
    ),
    isParty: true,
    canReply: canReply,
    closedNote: closedNote,
    messages: messages,
  );

  setUp(() async {
    await Injector.reset();

    repository = _MockRepository();
    changes = StreamController<DesignTicketThreadChange>.broadcast();

    when(() => repository.watch(any())).thenAnswer((_) => changes.stream);
    when(() => repository.liveResumed).thenAnswer((_) => const Stream<void>.empty());
    when(
      () => repository.markRead(any(), upToMessageId: any(named: 'upToMessageId')),
    ).thenAnswer((_) async => const Right(0));

    sl
      ..registerSingleton<VoicePlayback>(VoicePlayback(cache: _MockCache()))
      ..registerFactoryParam<DesignTicketThreadCubit, int, void>(
        (ticketId, _) => DesignTicketThreadCubit(
          ticketId: ticketId,
          me: me,
          get: GetDesignTicketThread(repository),
          send: SendDesignTicketMessage(repository),
          edit: EditDesignTicketMessage(repository),
          retract: RetractDesignTicketMessage(repository),
          markRead: MarkDesignTicketThreadRead(repository),
          watch: WatchDesignTicketThread(repository),
          voiceCache: _MockCache(),
        ),
      );
  });

  tearDown(() async {
    await changes.close();
    await Injector.reset();
  });

  Widget host() => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => const MaterialApp(
      locale: Locale('ar'),
      supportedLocales: [Locale('ar')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: DesignTicketThreadPage(ticketId: 3),
    ),
  );

  testWidgets('the bar names the other side, and the ticket sits under it', (tester) async {
    // Arrange
    when(() => repository.thread(3)).thenAnswer((_) async => Right(thread()));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — الطالبُ يرى المصمّمة في الوسط.
    expect(find.text('هدى'), findsOneWidget);
    expect(find.text('D3 · قيد التصميم'), findsOneWidget);
    expect(find.text('كيس شحن أسود'), findsOneWidget);
    expect(find.text('متجر إكس'), findsOneWidget);
  });

  testWidgets('an open ticket has the composer with its clip and its microphone', (tester) async {
    // Arrange
    when(() => repository.thread(3)).thenAnswer((_) async => Right(thread()));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(ChatComposer), findsOneWidget);
    expect(find.byIcon(AppIcons.mic), findsOneWidget);
  });

  testWidgets('words and a voice note are drawn as the internal tickets draw them', (tester) async {
    // Arrange
    when(() => repository.thread(3)).thenAnswer(
      (_) async => Right(
        thread(
          messages: [
            ChatMessage(
              id: 11,
              author: requester,
              isMine: true,
              body: 'الشعار في المرفقات',
              sentAt: DateTime(2026, 10, 24, 9),
            ),
            ChatMessage(
              id: 12,
              author: designer,
              sentAt: DateTime(2026, 10, 24, 9, 5),
              attachments: const [
                ChatAttachment(id: 44, kind: ChatAttachmentKind.voice, durationSeconds: 4),
              ],
            ),
          ],
        ),
      ),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.textContaining('الشعار في المرفقات', findRichText: true), findsOneWidget);
    expect(find.byType(VoiceNoteView), findsOneWidget);
  });

  testWidgets('an approved ticket has no box, and says how it ended', (tester) async {
    // Arrange
    when(() => repository.thread(3)).thenAnswer(
      (_) async => Right(
        thread(
          status: DesignTicketStatus.completed,
          canReply: false,
          closedNote: 'اعتُمد التصميم وأُغلقت المحادثة',
        ),
      ),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(ChatComposer), findsNothing);
    expect(find.text('اعتُمد التصميم وأُغلقت المحادثة'), findsOneWidget);
    expect(find.text('اعتُمد التصميم'), findsOneWidget);
  });
}
