import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/models/ticket_change.dart';
import 'package:dayaa/features/support/presentation/viewmodel/ticket_thread_cubit.dart';
import 'package:dayaa/features/support/presentation/views/ticket_thread_page.dart';
import 'package:dayaa/features/support/repositories/support_repository.dart';
import 'package:dayaa/features/support/usecases/support_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// One thread on screen — **مرسومةً كمحادثة بريمولا وتيليغرام**: اسمُ العميل في وسط الشريط وتحته
/// شرائحُ الحالة والمكتب والكود، وما يُفعل بالتذكرة في «⋮»؛ والفقاعاتُ بذيلٍ في سلاسل، والضغطةُ
/// المطوّلة ترفع الرسالة فوق محادثةٍ مضبّبة.
///
/// **Two properties carry this file.** The reply box is cleared only when the reply actually
/// sent — a failed send that wiped the field would make somebody retype a paragraph they are
/// about to be asked to send again — and every write is behind `support.manage`, so a reader
/// who may see the queue is offered nothing they would be refused.
///
/// The rest is what the screen owes the desk: the customer's number without leaving the thread,
/// a closed ticket saying it is closed rather than showing a dead box, and the ticket going back
/// to the queue on the way out so the list can patch itself without a refetch.
///
/// **ويُضاف ما جعل الشاشةَ حيّة**: سطرُ العميل يظهر ساعةَ يصل من المقبس بلا سحب، والملفُّ المرفق
/// يُرسم باسمه، وردُّ المحل الذي رآه العميل يحمل ✓✓، وزرُّ إعادة الفتح يعيد صندوق الرد.
///
/// Arrange - Act - Assert throughout.
class _MockSupportRepository extends Mock implements SupportRepository {}

void main() {
  late _MockSupportRepository repository;
  late StreamController<TicketChange> changes;

  const me = 7;

  const fromCustomer = TicketMessage(
    id: 1,
    from: MessageAuthor.customer,
    body: 'مرّ أسبوع',
  );

  const fromDesk = TicketMessage(
    id: 2,
    from: MessageAuthor.staff,
    authorName: 'محمد',
    body: 'نعتذر، خرجت اليوم',
  );

  SupportTicket ticketWith({
    TicketStatus status = TicketStatus.open,
    int? assignedTo,
    TicketAssignee? assignee,
    int? customerReadUpTo,
    TicketOrderRef? order,
    List<TicketMessage> messages = const [fromCustomer, fromDesk],
  }) => SupportTicket(
    id: 12,
    subject: 'أين طلبيتي؟',
    status: status,
    statusLabel: status.label,
    customer: const TicketCustomer(id: 4, name: 'سالم', code: 'A-1001', phone: '0910000000'),
    assignedTo: assignedTo,
    assignee: assignee,
    customerReadUpTo: customerReadUpTo,
    order: order,
    messages: messages,
  );

  Future<void> arrange(
    SupportTicket ticket, {
    List<String> permissions = const ['support.view', 'support.manage'],
  }) async {
    await Injector.reset();

    repository = _MockSupportRepository();
    changes = StreamController<TicketChange>.broadcast();

    when(() => repository.ticket(any())).thenAnswer((_) async => Right(ticket));
    when(() => repository.watchChanges()).thenAnswer((_) => changes.stream);
    when(() => repository.liveResumed).thenAnswer((_) => const Stream<void>.empty());

    sl
      ..registerSingleton<Session>(
        Session()
          ..adopt(
            AuthUser(
              id: me,
              name: 'عبدالوهاب',
              phone: '0911234567',
              permissions: permissions,
            ),
          ),
      )
      ..registerFactoryParam<TicketThreadCubit, int, void>(
        (ticketId, _) => TicketThreadCubit(
          ticketId: ticketId,
          get: GetTicket(repository),
          reply: ReplyToTicket(repository),
          assign: AssignTicket(repository),
          close: CloseTicket(repository),
          reopen: ReopenTicket(repository),
          watch: WatchTicketChanges(repository),
        ),
      );
  }

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
      home: TicketThreadPage(ticketId: 12),
    ),
  );

  /// زرُّ الإرسال المستدير — بأيقونته، لا بمكانه.
  final sendButton = find.byIcon(AppIcons.send);

  /// يفتح «⋮» — ما يُفعل بالتذكرة كلّه هناك، كما في بريمولا.
  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byTooltip('إجراءات التذكرة'));
    await tester.pumpAndSettle();
  }

  tearDown(() async {
    await Injector.reset();
    await changes.close();
  });

  group('the bar', () {
    testWidgets('names the customer, where the ticket stands and whose desk it is on', (
      tester,
    ) async {
      // Arrange
      await arrange(ticketWith());

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert — اسمُ العميل عنواناً وتحته شرائحُه، كشريط بريمولا؛ والموضوعُ مثبّتٌ تحته.
      final bar = find.byType(AppBar);
      expect(find.descendant(of: bar, matching: find.text('سالم')), findsOneWidget);
      expect(find.descendant(of: bar, matching: find.text('مفتوحة')), findsOneWidget);
      expect(find.descendant(of: bar, matching: find.text('غير مُسندة')), findsOneWidget);
      expect(find.descendant(of: bar, matching: find.text('A-1001')), findsOneWidget);
      expect(find.text('أين طلبيتي؟'), findsOneWidget);
      expect(find.textContaining('مرّ أسبوع'), findsOneWidget);
      expect(find.textContaining('نعتذر، خرجت اليوم'), findsOneWidget);
    });

    testWidgets('keeps the number to ring one tap away, in «⋮»', (tester) async {
      // Arrange
      await arrange(ticketWith());

      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act
      await openMenu(tester);

      // Assert — الهاتفُ ما يمدّ إليه من يجيب يده بعد الخيط.
      expect(find.text('اتصال بالعميل'), findsOneWidget);
      expect(find.text('0910000000'), findsOneWidget);
    });

    testWidgets('pins the order the ticket is about', (tester) async {
      // Arrange
      await arrange(ticketWith(order: const TicketOrderRef(id: 77, code: '1077')));

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('طلب 1077'), findsOneWidget);
    });
  });

  group('the conversation', () {
    testWidgets('the shop\'s replies sit at the end of the line, the customer\'s at its start', (
      tester,
    ) async {
      // Arrange
      await arrange(ticketWith());

      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act
      final deskLeft = tester.getTopLeft(find.textContaining('نعتذر، خرجت اليوم')).dx;
      final customerLeft = tester.getTopLeft(find.textContaining('مرّ أسبوع')).dx;

      // Assert — عربيٌّ من اليمين إلى اليسار: نهايةُ السطر يسار، كشاشة الملاحظات وتطبيق العميل.
      expect(deskLeft, lessThan(customerLeft));
    });

    testWidgets('a colleague\'s run carries their name once, above its first message', (
      tester,
    ) async {
      // Arrange — ردّان متتابعان من محمد.
      await arrange(
        ticketWith(
          messages: const [
            fromCustomer,
            fromDesk,
            TicketMessage(id: 3, from: MessageAuthor.staff, authorName: 'محمد', body: 'وأخرى'),
          ],
        ),
      );

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert — «من ردّ عليه؟» سؤالٌ يحقّ للمحل أن يسأله نفسه، ويكفيه الاسمُ مرّةً للسلسلة.
      expect(find.text('محمد'), findsOneWidget);
    });

    testWidgets('every sentence runs in its own direction', (tester) async {
      // Arrange
      await arrange(
        ticketWith(
          messages: const [
            TicketMessage(id: 1, from: MessageAuthor.customer, body: 'OK, thanks'),
            fromDesk,
          ],
        ),
      );

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert
      final latin = tester.widget<Text>(find.textContaining('OK, thanks'));
      expect(latin.textDirection, TextDirection.ltr);
    });

    testWidgets('a long press lifts the message with what can be done to it', (tester) async {
      // Arrange
      await arrange(ticketWith());

      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act
      await tester.longPress(find.textContaining('مرّ أسبوع'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('نسخ'), findsOneWidget);
    });
  });

  group('the reply box', () {
    testWidgets('is cleared when the reply actually sent', (tester) async {
      // Arrange
      await arrange(ticketWith());

      when(() => repository.reply(any(), body: any(named: 'body'))).thenAnswer(
        (_) async => Right(
          ticketWith(
            status: TicketStatus.inProgress,
            messages: const [fromCustomer, fromDesk],
          ),
        ),
      );

      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextField), 'سنتابع طلبك اليوم');
      await tester.pumpAndSettle();
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Assert
      verify(() => repository.reply(12, body: 'سنتابع طلبك اليوم')).called(1);
      expect(find.text('سنتابع طلبك اليوم'), findsNothing);
    });

    testWidgets('keeps the sentence when the send failed', (tester) async {
      // Arrange
      await arrange(ticketWith());

      when(() => repository.reply(any(), body: any(named: 'body'))).thenAnswer(
        (_) async => const Left(Failure.network(message: 'انقطع الاتصال')),
      );

      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextField), 'سنتابع طلبك اليوم');
      await tester.pumpAndSettle();
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Assert — the sentence is still in the box, and the thread is still on screen behind
      // it. Both halves of the same promise.
      expect(find.text('سنتابع طلبك اليوم'), findsOneWidget);
      expect(find.textContaining('مرّ أسبوع'), findsOneWidget);

      // The failure is also reported in a SnackBar, whose dismissal timer outlives these
      // assertions and would fail the test for a pending timer. Letting it expire is part of
      // the scenario, not cleanup around it.
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
    });

    testWidgets('the send key sends nothing while the box is empty', (tester) async {
      // Arrange
      await arrange(ticketWith());

      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Assert
      verifyNever(() => repository.reply(any(), body: any(named: 'body')));
    });
  });

  group('what a closed ticket offers', () {
    testWidgets('says it is closed instead of showing a box that would be refused', (
      tester,
    ) async {
      // Arrange
      await arrange(ticketWith(status: TicketStatus.closed));

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert — the server refuses a staff reply on a closed ticket. Saying so in the thread
      // beats a box that throws the paragraph away — and the one way back in is right there.
      expect(find.byType(TextField), findsNothing);
      expect(find.text('أُغلقت التذكرة'), findsOneWidget);
      expect(find.text('إعادة فتح التذكرة'), findsOneWidget);

      await openMenu(tester);
      expect(find.text('خذها'), findsNothing);
      expect(find.text('إغلاق التذكرة'), findsNothing);
    });

    testWidgets('reopening it brings the reply box back', (tester) async {
      // Arrange
      await arrange(ticketWith(status: TicketStatus.closed));

      when(() => repository.reopen(any())).thenAnswer(
        (_) async => Right(ticketWith(status: TicketStatus.inProgress)),
      );

      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('إعادة فتح التذكرة'));
      await tester.pumpAndSettle();

      // Assert
      verify(() => repository.reopen(12)).called(1);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('إعادة فتح التذكرة'), findsNothing);
    });

    testWidgets('a reader who may not write sees it closed, and nothing to reopen it with', (
      tester,
    ) async {
      // Arrange
      await arrange(ticketWith(status: TicketStatus.closed), permissions: const ['support.view']);

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('أُغلقت التذكرة'), findsOneWidget);
      expect(find.text('إعادة فتح التذكرة'), findsNothing);
    });
  });

  testWidgets('closing it from «⋮» asks first, then closes', (tester) async {
    // Arrange
    await arrange(ticketWith());

    when(() => repository.close(any())).thenAnswer(
      (_) async => Right(ticketWith(status: TicketStatus.closed)),
    );

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await openMenu(tester);
    await tester.tap(find.text('إغلاق التذكرة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إغلاق'));
    await tester.pumpAndSettle();

    // Assert
    verify(() => repository.close(12)).called(1);
    expect(find.text('أُغلقت التذكرة'), findsOneWidget);
  });

  group('live', () {
    testWidgets('what the customer writes appears without a refresh', (tester) async {
      // Arrange
      await arrange(ticketWith());

      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act — سطرٌ جديد من المقبس.
      changes.add(
        TicketChange(
          ticket: ticketWith(),
          message: const TicketMessage(id: 3, from: MessageAuthor.customer, body: 'هل من جديد؟'),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('هل من جديد؟'), findsOneWidget);
    });
  });

  group('what a message carries', () {
    testWidgets('a file is drawn by its name, its kind and its size', (tester) async {
      // Arrange
      await arrange(
        ticketWith(
          messages: const [
            TicketMessage(
              id: 1,
              from: MessageAuthor.customer,
              attachment: TicketAttachment(
                kind: AttachmentKind.pdf,
                kindLabel: 'PDF',
                name: 'التصميم.pdf',
                sizeBytes: 3355443,
                url: 'https://example.test/signed',
              ),
            ),
          ],
        ),
      );

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert — رسالةٌ بلا نصّ لا تُسقط الخيط؛ الملفُّ نفسه هو الرسالة. والحجمُ أوّلاً: سطرٌ عربيّ
      // يبدأ بـ«PDF» يقلبه الاتجاه فيُقرأ «3.2 · PDF م.ب».
      expect(find.text('التصميم.pdf'), findsOneWidget);
      expect(find.text('3.2 م.ب · PDF'), findsOneWidget);
    });

    testWidgets('a reply the customer has seen carries ✓✓, one they have not carries ✓', (
      tester,
    ) async {
      // Arrange — رأى العميل حتى الرسالة ٢، ولم يرَ الرسالة ٣.
      final semantics = tester.ensureSemantics();
      await arrange(
        ticketWith(
          customerReadUpTo: 2,
          messages: const [
            fromCustomer,
            fromDesk,
            TicketMessage(id: 3, from: MessageAuthor.staff, authorName: 'محمد', body: 'وأخرى'),
          ],
        ),
      );

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert — ولا علامة على رسالة العميل نفسه. تُقرأ العلامةُ مع نصّ فقاعتها؛ ونسختُها الشفّافة
      // التي تحجز مكان الوقت خارج شجرة المعاني، فتُعدّ مرّةً لكل ردّ.
      expect(find.semantics.byLabel(RegExp('قرأها العميل')), findsOne);
      expect(find.semantics.byLabel(RegExp('وصلت')), findsOne);

      semantics.dispose();
    });
  });

  group('taking the ticket', () {
    testWidgets('offers «خذها» while it is nobody\'s', (tester) async {
      // Arrange — unassigned.
      await arrange(ticketWith());

      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act
      await openMenu(tester);

      // Assert
      expect(find.text('خذها'), findsOneWidget);
      expect(find.text('غير مُسندة'), findsOneWidget);
    });

    // A test of its own rather than a second phase of the one above: pumping the same const
    // `TicketThreadPage` again reuses the element, so the `BlocProvider` never rebuilds and the
    // screen keeps the cubit the first arrangement handed it — the second `arrange` would have
    // no effect and the assertion would fail for a reason that is not about the screen.
    testWidgets('offers «أعدها للطابور» once it is on my desk', (tester) async {
      // Arrange
      await arrange(
        ticketWith(assignedTo: me, assignee: const TicketAssignee(id: me, name: 'عبدالوهاب')),
      );

      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act
      await openMenu(tester);

      // Assert — the two moves that need no user picker, which is why they are the only two;
      // and the bar says «تذكرتك» rather than my own name back to me.
      expect(find.text('أعدها للطابور'), findsOneWidget);
      expect(find.text('خذها'), findsNothing);
      expect(find.text('تذكرتك'), findsOneWidget);
    });

    testWidgets('sends my own id when I take it', (tester) async {
      // Arrange
      await arrange(ticketWith());

      when(() => repository.assign(any(), userId: any(named: 'userId'))).thenAnswer(
        (_) async => Right(
          ticketWith(assignedTo: me, assignee: const TicketAssignee(id: me, name: 'عبدالوهاب')),
        ),
      );

      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act
      await openMenu(tester);
      await tester.tap(find.text('خذها'));
      await tester.pumpAndSettle();

      // Assert — the signed-in user's id, taken from the session rather than from anything on
      // screen, so «خذها» cannot put a ticket on somebody else's desk.
      verify(() => repository.assign(12, userId: me)).called(1);
    });
  });

  group('a reader who may not write', () {
    testWidgets('is offered no composer, no close and no assignment', (tester) async {
      // Arrange — `support.view` without `support.manage`.
      await arrange(ticketWith(), permissions: const ['support.view']);

      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act
      await openMenu(tester);

      // Assert — the gate on screen is a courtesy; `can:` on the route is the real limit. What
      // this proves is that the courtesy is not missing, so nobody is offered a 403.
      expect(find.byType(TextField), findsNothing);
      expect(find.text('خذها'), findsNothing);
      expect(find.text('إغلاق التذكرة'), findsNothing);

      // And the conversation is still fully readable, which is what `support.view` buys.
      expect(find.textContaining('مرّ أسبوع'), findsOneWidget);
    });
  });
}
