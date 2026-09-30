// A harness, not a test: it draws تذاكر الدعم to PNGs so the card can be set beside Primula's
// without the phone. Named outside `test/` so `flutter test` never collects it.
//
//   PREVIEW_OUT=/tmp flutter test tool/preview/support_tickets_preview.dart
//
// The bundled Almarai is registered under the family the theme asks for, and Material's icon
// font is loaded from the Flutter SDK so the chips' glyphs draw instead of empty squares.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/theme/theme.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/models/ticket_change.dart';
import 'package:dayaa/features/support/presentation/viewmodel/support_tickets_cubit.dart';
import 'package:dayaa/features/support/presentation/views/support_tickets_page.dart';
import 'package:dayaa/features/support/repositories/support_repository.dart';
import 'package:dayaa/features/support/usecases/support_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.now();

final _tickets = [
  SupportTicket(
    id: 1,
    subject: 'مرحبا كيف الحال',
    status: TicketStatus.open,
    statusLabel: 'مفتوحة',
    customer: const TicketCustomer(id: 4, code: 'C1042', name: 'Flyrex', phone: '0910000000'),
    unreadCount: 2,
    lastMessageAt: _now.subtract(const Duration(minutes: 12)),
  ),
  SupportTicket(
    id: 2,
    subject: 'متى تصل طلبيتي؟ مرّ أسبوع على الدفع ولم يتواصل معي أحد',
    status: TicketStatus.inProgress,
    statusLabel: 'قيد المعالجة',
    customer: const TicketCustomer(id: 5, code: 'B849', name: 'سالم', phone: '0924455667'),
    order: const TicketOrderRef(id: 77, code: '1077'),
    assignedTo: 1,
    assignee: const TicketAssignee(id: 1, name: 'عبدالوهاب'),
    lastMessageAt: _now.subtract(const Duration(hours: 3)),
  ),
  SupportTicket(
    id: 3,
    subject: 'تعديل على التصميم',
    status: TicketStatus.closed,
    statusLabel: 'مغلقة',
    customer: const TicketCustomer(id: 6, code: 'A713', name: 'اسامة', phone: '0911112233'),
    assignedTo: 9,
    assignee: const TicketAssignee(id: 9, name: 'محمد'),
    lastMessageAt: _now.subtract(const Duration(days: 15)),
  ),
];

class _StubRepository implements SupportRepository {
  @override
  Stream<TicketChange> watchChanges() => const Stream.empty();

  @override
  Stream<void> get liveResumed => const Stream.empty();

  @override
  Future<Either<Failure, Paginated<SupportTicket>>> tickets({
    int page = 1,
    TicketStatus? status,
    int? assignedTo,
  }) async => Right(
    Paginated<SupportTicket>(
      items: _tickets,
      meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: _tickets.length),
    ),
  );

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

  for (final dark in [true, false]) {
    testWidgets('draw the queue (${dark ? 'dark' : 'light'})', (tester) async {
      await Injector.reset();
      final repository = _StubRepository();
      sl
        ..registerSingleton<Session>(
          Session()
            ..adopt(
              const AuthUser(
                id: 1,
                name: 'عبدالوهاب',
                phone: '0911234567',
                permissions: ['support.view', 'support.manage'],
              ),
            ),
        )
        ..registerFactory<SupportTicketsCubit>(
          () => SupportTicketsCubit(
            browse: BrowseTickets(repository),
            watch: WatchTicketChanges(repository),
          ),
        );

      tester.view.physicalSize = const Size(430, 932);
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
              home: const SupportTicketsPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${Platform.environment['PREVIEW_OUT'] ?? '.'}/support-tickets-${dark ? 'dark' : 'light'}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
      });
    });
  }
}
