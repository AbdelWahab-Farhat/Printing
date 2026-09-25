// أداةٌ لا اختبار: ترسم «الدعم» والمحادثة صوراً PNG كي يُنظر فيها بلا هاتف. خارج `test/` كي لا
// يجمعها `flutter test`.
//
//   PREVIEW_OUT=<مجلد الصور> flutter test tool/preview/support_preview.dart
//
// على طريقة `orders_preview.dart`: آيفون ٣٩٠×٨٤٤ بكثافة ٢، وCairo بأوزانه الستة. البيانات مزيّفة
// وللرسم وحده: تذكرةٌ عن تأخّر طلبية، فيها صورةٌ من العميل وعرضُ تعويضٍ PDF من المحل، وجملةٌ
// إنجليزية، ورسالةٌ في الطريق وملفٌّ يُرفع ورسالةٌ رُفضت. الصورة من `assets/billboards/`.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/files/attachment_store.dart';
import 'package:dayaa_client/core/files/picked_file.dart';
import 'package:dayaa_client/core/files/transfer_cancel.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/theme/text_theme.dart';
import 'package:dayaa_client/core/theme/theme.dart';
import 'package:dayaa_client/features/badges/models/customer_badge.dart';
import 'package:dayaa_client/features/badges/presentation/viewmodel/badges_cubit.dart';
import 'package:dayaa_client/features/badges/repositories/badge_repository.dart';
import 'package:dayaa_client/features/badges/usecases/get_badges.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/models/ticket_change.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/attachment_files_cubit.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/open_thread.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/support_cubit.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/ticket_thread_cubit.dart';
import 'package:dayaa_client/features/support/presentation/views/support_page.dart';
import 'package:dayaa_client/features/support/presentation/views/ticket_thread_page.dart';
import 'package:dayaa_client/features/support/presentation/widgets/chat_attachments.dart';
import 'package:dayaa_client/features/support/repositories/support_repository.dart';
import 'package:dayaa_client/features/support/usecases/browse_tickets.dart';
import 'package:dayaa_client/features/support/usecases/download_attachment.dart';
import 'package:dayaa_client/features/support/usecases/find_attachment_on_phone.dart';
import 'package:dayaa_client/features/support/usecases/get_ticket.dart';
import 'package:dayaa_client/features/support/usecases/open_ticket.dart';
import 'package:dayaa_client/features/support/usecases/reply_to_ticket.dart';
import 'package:dayaa_client/features/support/usecases/watch_ticket_changes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final DateTime _now = DateTime.now();
final DateTime _today = DateTime(_now.year, _now.month, _now.day);
final DateTime _yesterday = _today.subtract(const Duration(days: 1));

DateTime _at(DateTime day, int hour, int minute) => day.add(Duration(hours: hour, minutes: minute));

final List<TicketMessage> _thread = [
  TicketMessage(
    id: 101,
    from: MessageAuthor.me,
    body: 'السلام عليكم، الطلبية #1228 كان موعدها أمس ولم تصل',
    sentAt: _at(_yesterday, 18, 2),
  ),
  TicketMessage(id: 102, from: MessageAuthor.me, body: 'هل من جديد؟', sentAt: _at(_yesterday, 18, 3)),
  TicketMessage(
    id: 103,
    from: MessageAuthor.support,
    body: 'وعليكم السلام، نعتذر عن التأخير. نراجعها مع قسم الإنتاج الآن',
    sentAt: _at(_yesterday, 18, 40),
  ),
  TicketMessage(
    id: 104,
    from: MessageAuthor.me,
    attachment: const TicketAttachment(
      kind: AttachmentKind.image,
      kindLabel: 'صورة',
      name: 'IMG_2231.jpg',
      widthPx: 1600,
      heightPx: 1200,
      url: 'https://preview.example/104',
    ),
    sentAt: _at(_today, 9, 12),
  ),
  TicketMessage(
    id: 105,
    from: MessageAuthor.me,
    body: 'هذه الأكياس من الدفعة السابقة، اللون أفتح من المطلوب',
    sentAt: _at(_today, 9, 13),
  ),
  TicketMessage(
    id: 106,
    from: MessageAuthor.support,
    body: 'أرسلنا لك عرض التعويض، نرجو مراجعته',
    attachment: const TicketAttachment(
      kind: AttachmentKind.pdf,
      kindLabel: 'PDF',
      name: 'compensation-offer-1228.pdf',
      sizeBytes: 1258291,
      url: 'https://preview.example/106',
    ),
    sentAt: _at(_today, 9, 40),
  ),
  TicketMessage(
    id: 107,
    from: MessageAuthor.support,
    body: 'OK, we will reprint the whole batch at no cost.',
    sentAt: _at(_today, 9, 41),
  ),
  TicketMessage(
    id: 108,
    from: MessageAuthor.me,
    body: 'تمام، أوافق على العرض 👍',
    sentAt: _at(_today, 11, 20),
  ),
];

final SupportTicket _ticket = SupportTicket(
  id: 41,
  subject: 'الطلبية #1228 تأخرت',
  status: TicketStatus.inProgress,
  statusLabel: 'قيد المعالجة',
  order: const TicketOrderRef(id: 12, code: '1228'),
  supportReadUpTo: 107,
  messages: _thread,
  lastMessageAt: _at(_today, 11, 20),
);

final List<SupportTicket> _openTickets = [
  SupportTicket(
    id: 41,
    subject: 'الطلبية #1228 تأخرت',
    status: TicketStatus.inProgress,
    statusLabel: 'قيد المعالجة',
    order: const TicketOrderRef(id: 12, code: '1228'),
    unreadCount: 2,
    preview: 'خرجت مع المندوب اليوم، تصلك قبل المغرب',
    lastMessageAt: _at(_today, 11, 24),
  ),
  SupportTicket(
    id: 40,
    subject: 'تعديل تصميم الشعار',
    status: TicketStatus.open,
    statusLabel: 'مفتوحة',
    preview: 'final-logo.pdf',
    lastMessageAt: _at(_yesterday, 20, 5),
  ),
  SupportTicket(
    id: 37,
    subject: 'سؤال عن أسعار الكميات',
    status: TicketStatus.inProgress,
    statusLabel: 'قيد المعالجة',
    preview: 'شكراً، سأطلب 2000 كيس الأسبوع القادم',
    lastMessageAt: _today.subtract(const Duration(days: 3)),
  ),
  SupportTicket(
    id: 35,
    subject: 'فاتورة ضريبية',
    status: TicketStatus.open,
    statusLabel: 'مفتوحة',
    preview: 'Please send the invoice as PDF',
    lastMessageAt: _today.subtract(const Duration(days: 6)),
  ),
];

class _Support implements SupportRepository {
  final Completer<Either<Failure, SupportTicket>> _never = Completer();

  @override
  Future<Either<Failure, Paginated<SupportTicket>>> tickets({int page = 1, bool? openOnly}) async {
    final items = openOnly == false ? <SupportTicket>[] : _openTickets;

    return Right(
      Paginated<SupportTicket>(
        items: items,
        meta: PageMeta(currentPage: 1, perPage: 15, lastPage: 1, total: items.length),
      ),
    );
  }

  @override
  Future<Either<Failure, SupportTicket>> ticket(int id) async => Right(_ticket);

  @override
  Future<Either<Failure, SupportTicket>> open({
    required String subject,
    required String body,
    int? orderId,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, SupportTicket>> reply({
    required int id,
    String body = '',
    PickedFile? file,
    String? clientToken,
    void Function(double progress)? onProgress,
    TransferCancel? cancel,
  }) {
    if (body == 'وهل التوصيل مجاني؟') {
      return Future.value(const Left(NetworkFailure(message: 'تعذّر الاتصال بالإنترنت')));
    }

    if (file != null) onProgress?.call(0.42);

    return _never.future;
  }

  @override
  Stream<TicketChange> watchChanges() => const Stream.empty();

  @override
  Stream<void> get liveResumed => const Stream.empty();
}

class _Store implements AttachmentStore {
  @override
  Future<String?> localPath({required String key, required String fileName}) async => null;

  @override
  Future<Either<Failure, String>> download({
    required String url,
    required String key,
    required String fileName,
    void Function(double progress)? onProgress,
    TransferCancel? cancel,
  }) {
    onProgress?.call(0.6);

    return Completer<Either<Failure, String>>().future;
  }
}

class _Badges implements BadgeRepository {
  @override
  Future<Either<Failure, Map<CustomerBadge, int>>> badges() async => const Right({});
}

Future<void> _load(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = await File(path).readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final out = Platform.environment['PREVIEW_OUT'] ?? '.';
  ui.Image? photo;

  setUpAll(() async {
    await _load('Cairo', [
      for (final face in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold', 'Black'])
        'assets/fonts/Cairo-$face.ttf',
    ]);
    final artifacts = File(Platform.resolvedExecutable).parent.parent.parent.path;
    final icons = '$artifacts/material_fonts/MaterialIcons-Regular.otf';
    if (File(icons).existsSync()) await _load('MaterialIcons', [icons]);
  });

  Future<void> draw(
    WidgetTester tester, {
    required String name,
    required Brightness brightness,
    required String location,
    Future<void> Function(WidgetTester tester)? then,
  }) async {
    await sl.reset();
    final support = _Support();
    final store = _Store();
    final openThread = OpenThread();

    sl
      ..registerFactory<SupportCubit>(
        () => SupportCubit(
          browse: BrowseTickets(support),
          open: OpenTicket(support),
          watch: WatchTicketChanges(support),
        ),
      )
      ..registerFactoryParam<TicketThreadCubit, int, void>(
        (id, _) => TicketThreadCubit(
          ticketId: id,
          get: GetTicket(support),
          reply: ReplyToTicket(support),
          watch: WatchTicketChanges(support),
          openThread: openThread,
        ),
      )
      ..registerFactory<AttachmentFilesCubit>(
        () => AttachmentFilesCubit(
          find: FindAttachmentOnPhone(store),
          download: DownloadAttachment(store),
        ),
      );

    // صورة الرسالة ١٠٤ في ذاكرة الصور تحت مفتاحها، فلا شبكة.
    photo ??= await tester.runAsync(() async {
      final bytes = await File('assets/billboards/printed_bags.jpg').readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);

      return (await codec.getNextFrame()).image;
    });
    PaintingBinding.instance.imageCache.putIfAbsent(
      CachedNetworkImageProvider('https://preview.example/104', cacheKey: chatImageCacheKey(104)),
      () => OneFrameImageStreamCompleter(SynchronousFuture(ImageInfo(image: photo!.clone()))),
    );

    // آيفون بجزيرة: ٣٩٠×٨٤٤، شريط الحالة ٥٩، والمؤشر السفلي ٣٤.
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    tester.view.padding = const FakeViewPadding(top: 118, bottom: 68);
    tester.view.viewPadding = const FakeViewPadding(top: 118, bottom: 68);
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(path: '/support', builder: (context, state) => const SupportPage()),
        GoRoute(
          path: '/support/:id',
          builder: (context, state) =>
              TicketThreadPage(ticketId: int.parse(state.pathParameters['id']!)),
        ),
      ],
    );
    final key = GlobalKey();

    debugDisableShadows = false;
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ScreenUtilInit(
          designSize: const Size(430, 932),
          builder: (context, _) {
            final theme = MaterialTheme(createTextTheme(context, 'Cairo', 'Cairo'));

            return BlocProvider(
              create: (_) => BadgesCubit(getBadges: GetBadges(_Badges())),
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                routerConfig: router,
                theme: brightness == Brightness.light ? theme.light() : theme.dark(),
                locale: const Locale('ar'),
                supportedLocales: const [Locale('ar')],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    if (then != null) await then(tester);

    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$out/$name-${brightness.name}.png').writeAsBytes(bytes!.buffer.asUint8List());
    });
    debugDisableShadows = true;

    // تنبيهُ الرسالة المرفوضة يختفي بمؤقّت؛ يُترك ينتهي كي لا يبقى معلّقاً بعد الرسم.
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 1));
  }

  /// ما في الطريق: رسالةٌ رُفضت، وملفٌّ يُرفع، ورسالةٌ تنتظر خلفه — وملفُّ المحل يُنزَّل.
  Future<void> busy(WidgetTester tester) async {
    final context = tester.element(find.byType(ListView).first);
    final thread = BlocProvider.of<TicketThreadCubit>(context);
    final files = BlocProvider.of<AttachmentFilesCubit>(context);

    unawaited(thread.send('وهل التوصيل مجاني؟'));
    await tester.pump();
    unawaited(
      thread.sendFile(
        const PickedFile(path: '/tmp/signed-offer.pdf', name: 'signed-offer.pdf', sizeBytes: 842000),
      ),
    );
    await tester.pump();
    unawaited(thread.send('متى يصل المندوب تقريباً؟'));
    unawaited(files.fetch(_thread[5]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  for (final brightness in Brightness.values) {
    testWidgets('draw the list, ${brightness.name}', (tester) async {
      await draw(tester, name: 'support-list', brightness: brightness, location: '/support');
    });

    testWidgets('draw the thread, ${brightness.name}', (tester) async {
      await draw(
        tester,
        name: 'support-thread',
        brightness: brightness,
        location: '/support/41',
        then: busy,
      );
    });
  }

  testWidgets('draw the message menu', (tester) async {
    await draw(
      tester,
      name: 'support-menu',
      brightness: Brightness.light,
      location: '/support/41',
      then: (tester) async {
        await tester.longPress(find.textContaining('اللون أفتح'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      },
    );
  });
}
