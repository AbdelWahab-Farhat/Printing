import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/files/attachment_store.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/widgets/receipt_viewer.dart';
import 'package:dayaa_client/features/badges/models/customer_badge.dart';
import 'package:dayaa_client/features/badges/presentation/viewmodel/badges_cubit.dart';
import 'package:dayaa_client/features/badges/repositories/badge_repository.dart';
import 'package:dayaa_client/features/badges/usecases/get_badges.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/models/ticket_change.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/attachment_files_cubit.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/open_thread.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/ticket_thread_cubit.dart';
import 'package:dayaa_client/features/support/presentation/views/ticket_thread_page.dart';
import 'package:dayaa_client/features/support/presentation/widgets/chat_attachments.dart';
import 'package:dayaa_client/features/support/repositories/support_repository.dart';
import 'package:dayaa_client/features/support/usecases/download_attachment.dart';
import 'package:dayaa_client/features/support/usecases/find_attachment_on_phone.dart';
import 'package:dayaa_client/features/support/usecases/get_ticket.dart';
import 'package:dayaa_client/features/support/usecases/reply_to_ticket.dart';
import 'package:dayaa_client/features/support/usecases/watch_ticket_changes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSupport extends Mock implements SupportRepository {}

class _MockStore extends Mock implements AttachmentStore {}

class _MockBadges extends Mock implements BadgeRepository {}

/// المحادثة كما يراها العميل: شكلُ تيليغرام، وعلامةُ الوصول، وما يُفعل بالرسالة.
///
/// Arrange - Act - Assert في كل حالة.
void main() {
  late _MockSupport support;
  late _MockStore store;

  final now = DateTime.now();

  final mine = TicketMessage(id: 1, from: MessageAuthor.me, body: 'متى تصل الطلبية؟', sentAt: now);
  final theirs = TicketMessage(
    id: 2,
    from: MessageAuthor.support,
    body: 'OK, it leaves today.',
    sentAt: now,
  );
  final unseen = TicketMessage(id: 3, from: MessageAuthor.me, body: 'شكراً لكم', sentAt: now);

  SupportTicket thread({int? readUpTo = 2}) => SupportTicket(
    id: 41,
    subject: 'تأخر الطلبية',
    status: TicketStatus.inProgress,
    statusLabel: 'قيد المعالجة',
    supportReadUpTo: readUpTo,
    messages: [mine, theirs, unseen],
  );

  void stubReply(Future<Either<Failure, SupportTicket>> Function() answer) {
    when(
      () => support.reply(
        id: 41,
        body: any(named: 'body'),
        file: any(named: 'file'),
        clientToken: any(named: 'clientToken'),
        onProgress: any(named: 'onProgress'),
        cancel: any(named: 'cancel'),
      ),
    ).thenAnswer((_) => answer());
  }

  setUp(() {
    support = _MockSupport();
    store = _MockStore();

    when(() => support.ticket(41)).thenAnswer((_) async => Right(thread()));
    when(() => support.watchChanges()).thenAnswer((_) => const Stream<TicketChange>.empty());
    when(() => support.liveResumed).thenAnswer((_) => const Stream<void>.empty());
    when(
      () => store.localPath(key: any(named: 'key'), fileName: any(named: 'fileName')),
    ).thenAnswer((_) async => null);

    sl
      ..registerFactoryParam<TicketThreadCubit, int, void>(
        (id, _) => TicketThreadCubit(
          ticketId: id,
          get: GetTicket(support),
          reply: ReplyToTicket(support),
          watch: WatchTicketChanges(support),
          openThread: OpenThread(),
        ),
      )
      ..registerFactory(
        () => AttachmentFilesCubit(
          find: FindAttachmentOnPhone(store),
          download: DownloadAttachment(store),
        ),
      );

    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(430, 932);
    view.devicePixelRatio = 1;
  });

  tearDown(() async {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
    await sl.reset();
  });

  Widget host() {
    final badges = _MockBadges();
    when(badges.badges).thenAnswer((_) async => const Right(<CustomerBadge, int>{}));

    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => BlocProvider(
        create: (_) => BadgesCubit(getBadges: GetBadges(badges)),
        child: const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: [Locale('ar')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: TicketThreadPage(ticketId: 41),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(host());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('my messages sit at the end of the line, the shop\'s at its start', (tester) async {
    // Arrange
    await open(tester);

    // Act
    final myLeft = tester.getTopLeft(find.textContaining('متى تصل')).dx;
    final theirLeft = tester.getTopLeft(find.textContaining('OK, it leaves')).dx;

    // Assert — عربيٌّ من اليمين إلى اليسار: نهاية السطر يسار.
    expect(myLeft, lessThan(theirLeft));
  });

  testWidgets('every sentence runs in its own direction', (tester) async {
    // Arrange
    await open(tester);

    // Act
    final latin = tester.widget<Text>(find.textContaining('OK, it leaves'));
    final arabic = tester.widget<Text>(find.textContaining('متى تصل'));

    // Assert
    expect(latin.textDirection, TextDirection.ltr);
    expect(arabic.textDirection, TextDirection.rtl);
  });

  testWidgets('what the shop has seen carries ✓✓, what it has not carries ✓', (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();

    // Act
    await open(tester);

    // Assert — الأولى قبل حدّ القراءة (٢)، والأخيرة بعده. العلامة تُقرأ مع نصّ فقاعتها.
    expect(find.semantics.byLabel(RegExp('قرأها الدعم')), findsOne);
    expect(find.semantics.byLabel(RegExp('أُرسلت')), findsOne);

    semantics.dispose();
  });

  testWidgets('a message shows at once with a clock, and ✓ when the server has it', (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();
    final gate = Completer<Either<Failure, SupportTicket>>();
    stubReply(() => gate.future);
    await open(tester);

    // Act
    await tester.enterText(find.byType(TextFormField), 'هل خرجت؟');
    await tester.pump();
    await tester.tap(find.byIcon(AppIcons.send));
    await tester.pump();

    // Assert — في الطريق: ساعة، والحقل فارغٌ لأن ما كُتب صار فقاعة.
    expect(find.textContaining('هل خرجت؟'), findsOne);
    expect(find.semantics.byLabel(RegExp('قيد الإرسال')), findsOne);
    expect(tester.widget<TextFormField>(find.byType(TextFormField)).controller?.text, isEmpty);

    gate.complete(
      Right(
        thread().copyWith(
          messages: [
            mine,
            theirs,
            unseen,
            TicketMessage(id: 4, from: MessageAuthor.me, body: 'هل خرجت؟', clientToken: 'x', sentAt: now),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.semantics.byLabel(RegExp('قيد الإرسال')), findsNothing);
    expect(find.semantics.byLabel(RegExp('أُرسلت')), findsExactly(2));

    semantics.dispose();
  });

  testWidgets('a message that failed stays, with a red mark that offers to send it again', (
    tester,
  ) async {
    // Arrange
    stubReply(() async => const Left(NetworkFailure(message: 'لا يوجد اتصال')));
    await open(tester);
    await tester.enterText(find.byType(TextFormField), 'هل خرجت؟');
    await tester.pump();
    await tester.tap(find.byIcon(AppIcons.send));
    await tester.pump();

    // Act
    await tester.tap(find.byIcon(AppIcons.error));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Assert
    expect(find.textContaining('هل خرجت؟'), findsOne);
    expect(find.text('أعد الإرسال'), findsOne);
    expect(find.text('احذفها'), findsOne);

    // يُترك التنبيه يختفي والورقة تستقرّ، فلا يبقى مؤقّتٌ ولا حركةٌ بعد الاختبار.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });

  testWidgets('a long press lifts the message with what can be done to it', (tester) async {
    // Arrange
    await open(tester);

    // Act
    await tester.longPress(find.textContaining('متى تصل'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Assert
    expect(find.text('نسخ'), findsOne);

    await tester.pumpAndSettle();
  });

  /// اسمُ الصورة على هاتف مرسلها («image_picker_A3CC…») لا يقول شيئاً لأحد، فلا يُكتب تحتها
  /// (طلب المستخدم، 2026-09-25).
  testWidgets('a photo opens full screen with no file name under it', (tester) async {
    // Arrange
    final photo = TicketMessage(
      id: 9,
      from: MessageAuthor.me,
      attachment: const TicketAttachment(
        kind: AttachmentKind.image,
        name: 'image_picker_A3CC66CA.jpg',
        widthPx: 800,
        heightPx: 600,
        url: 'https://api.example/storage/9',
      ),
      sentAt: now,
    );
    when(() => support.ticket(41)).thenAnswer(
      (_) async => Right(thread().copyWith(messages: [mine, photo])),
    );
    final image = await tester.runAsync(createTestImage);
    PaintingBinding.instance.imageCache.putIfAbsent(
      CachedNetworkImageProvider('https://api.example/storage/9', cacheKey: chatImageCacheKey(9)),
      () => OneFrameImageStreamCompleter(SynchronousFuture(ImageInfo(image: image!))),
    );
    await open(tester);

    // Act
    await tester.tap(find.byType(ChatRemoteImage));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Assert
    expect(find.byType(ReceiptViewer), findsOne);
    expect(find.textContaining('image_picker'), findsNothing);

    PaintingBinding.instance.imageCache.clear();
  });

  testWidgets('the send key sends nothing while the box is empty', (tester) async {
    // Arrange
    stubReply(() async => Right(thread()));
    await open(tester);

    // Act
    await tester.tap(find.byIcon(AppIcons.send));
    await tester.pump();

    // Assert
    verifyNever(
      () => support.reply(
        id: any(named: 'id'),
        body: any(named: 'body'),
        file: any(named: 'file'),
        clientToken: any(named: 'clientToken'),
        onProgress: any(named: 'onProgress'),
        cancel: any(named: 'cancel'),
      ),
    );
  });
}
