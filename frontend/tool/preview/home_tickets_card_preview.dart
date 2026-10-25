// A harness, not a test: it draws the employee card with the tickets waiting on the reader, to set
// beside Primula's home card without the phone. Named outside `test/` so `flutter test` never
// collects it.
//
//   FLUTTER_ROOT=… PREVIEW_OUT=/tmp flutter test tool/preview/home_tickets_card_preview.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/chat/chat_message.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/theme/theme.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/home/presentation/widgets/employee_card.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:dayaa/features/internal_tickets/presentation/viewmodel/internal_tickets_home_cubit.dart';
import 'package:dayaa/features/internal_tickets/presentation/widgets/internal_tickets_card_section.dart';
import 'package:dayaa/features/internal_tickets/repositories/internal_tickets_repository.dart';
import 'package:dayaa/features/internal_tickets/usecases/internal_tickets_usecases.dart';
import 'package:dayaa/features/notifications/models/unread_count.dart';
import 'package:dayaa/features/notifications/presentation/viewmodel/unread_badge_cubit.dart';
import 'package:dayaa/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:dayaa/features/notifications/usecases/get_unread_count.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _user = AuthUser(
  id: 7,
  name: 'فرحات',
  phone: '0911234567',
  employeeCode: '1013',
  permissions: [],
  roles: [UserRole(name: 'admin', label: 'مدير')],
);

class _UnreadThree implements GetUnreadCount {
  @override
  Future<Either<Failure, UnreadCount>> call() async => const Right(UnreadCount(count: 3));

  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _tickets = [
  InternalTicket(
    id: 3,
    code: 'T3',
    title: 'الأكياس المطبوعة للمتجر',
    status: InternalTicketStatus.inProgress,
    statusLabel: 'قيد المعالجة',
    counterpart: const ChatPerson(id: 9, name: 'المدير'),
    awaitingMyReply: true,
    unreadCount: 2,
    order: const InternalOrderRef(id: 77, code: '1077'),
    lastMessage: InternalLastMessage(
      id: 30,
      authorId: 9,
      authorName: 'المدير',
      preview: '🎤 رسالة صوتية',
      kind: 'voice',
      sentAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ),
  InternalTicket(
    id: 4,
    code: 'T4',
    title: 'فاتورة المطبعة',
    status: InternalTicketStatus.inProgress,
    statusLabel: 'قيد المعالجة',
    counterpart: const ChatPerson(id: 10, name: 'هدى'),
    awaitingMyReply: true,
    lastMessage: InternalLastMessage(
      id: 40,
      authorId: 10,
      authorName: 'هدى',
      preview: 'وصلت الفاتورة؟ نبي نقفل حساب الشهر قبل الخميس',
      sentAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ),
];

class _StubRepository implements InternalTicketsRepository {
  @override
  Future<Either<Failure, InternalTicketsHome>> home() async =>
      Right(InternalTicketsHome(tickets: _tickets, awaitingMyReply: 2, totalOpen: 3));

  @override
  Stream<int> watchMine(int userId) => const Stream.empty();

  @override
  Stream<void> get liveResumed => const Stream.empty();

  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final cairo = FontLoader('Cairo');
    for (final file in ['Almarai-Regular.ttf', 'Almarai-Bold.ttf']) {
      cairo.addFont(
        File('assets/fonts/$file').readAsBytes().then((bytes) => ByteData.view(bytes.buffer)),
      );
    }
    await cairo.load();

    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    if (flutterRoot != null) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
              .readAsBytes()
              .then((bytes) => ByteData.view(bytes.buffer)),
        );
      await icons.load();
    }
  });

  final modes = switch (Platform.environment['PREVIEW_MODE']) {
    'light' => [false],
    'dark' => [true],
    _ => [true, false],
  };

  for (final dark in modes) {
    testWidgets('draw the card (${dark ? 'dark' : 'light'})', (tester) async {
      await Injector.reset();
      sl.registerSingleton<Session>(Session()..adopt(_user));
      final repository = _StubRepository();
      final cubit = InternalTicketsHomeCubit(
        get: GetInternalTicketsHome(repository),
        send: SendInternalMessage(repository),
        markSeen: MarkInternalTicketSeen(repository),
        watch: WatchInternalTickets(repository),
        me: 7,
      );
      await cubit.load();

      tester.view.physicalSize = const Size(430, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final key = GlobalKey();
      final text = dark ? Typography.material2021().white : Typography.material2021().black;
      final theme = MaterialTheme(text.apply(fontFamily: 'Cairo'));

      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: ScreenUtilInit(
            designSize: const Size(430, 932),
            builder: (context, _) => MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: dark ? theme.dark() : theme.light(),
              locale: const Locale('ar'),
              supportedLocales: const [Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: Scaffold(
                body: MultiBlocProvider(
                  providers: [
                    BlocProvider<InternalTicketsHomeCubit>.value(value: cubit),
                    BlocProvider<UnreadBadgeCubit>(
                      create: (_) => UnreadBadgeCubit(_UnreadThree())..load(),
                    ),
                  ],
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    children: const [
                      EmployeeCard(
                        user: _user,
                        action: NotificationBell(onCard: true),
                        bottom: InternalTicketsCardSection(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> shoot(String name) async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('${Platform.environment['PREVIEW_OUT'] ?? '.'}/$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
        });
      }

      final mode = dark ? 'dark' : 'light';
      await shoot('home-card-$mode');

      // «رد» على الأول: الحقلُ تحته.
      await tester.tap(find.text('رد').first);
      await tester.pumpAndSettle();
      await shoot('home-card-$mode-reply');
    });
  }
}
