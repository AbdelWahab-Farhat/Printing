// A harness, not a test: it draws تذاكر التصميم to PNGs so the band above the list and the
// ticket's own header can be looked at without the phone. Named outside `test/` so
// `flutter test` never collects it.
//
//   PREVIEW_OUT=/tmp flutter test tool/preview/design_tickets_preview.dart
//
// Two traps, both handled below: the app's text theme goes through GoogleFonts, which cannot
// fetch in a test, so the bundled Almarai is registered under the family the theme asks for; and
// Material's icon font is not loaded in a test, so icon glyphs come out as empty squares.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/theme/theme.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_counts.dart';
import 'package:dayaa/features/design_tickets/presentation/viewmodel/design_ticket_detail_cubit.dart';
import 'package:dayaa/features/design_tickets/presentation/viewmodel/design_tickets_cubit.dart';
import 'package:dayaa/features/design_tickets/presentation/views/design_ticket_detail_page.dart';
import 'package:dayaa/features/design_tickets/presentation/views/design_tickets_page.dart';
import 'package:dayaa/features/design_tickets/repositories/design_ticket_repository.dart';
import 'package:dayaa/features/design_tickets/usecases/design_ticket_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «D1», as it stands the moment it is raised: nobody has claimed it.
const _ticket = DesignTicket(
  id: 1,
  code: 'D1',
  title: 'تصميم كيس عصري',
  description: 'وضع شعار في منتصف',
  instructions: 'تيست',
  status: DesignTicketStatus.fresh,
  statusLabel: 'جديد',
  customerId: 713,
  customerName: 'اسامة حماد',
  customerCode: 'A713',
  isInSharedPool: true,
  canAccept: true,
);

class _StubRepository implements DesignTicketRepository {
  @override
  Future<Either<Failure, Paginated<DesignTicket>>> tickets({
    List<String> statuses = const <String>[],
    String? designer,
    String? requestedBy,
    int? customerId,
    int? orderId,
    String? search,
    int page = 1,
    int perPage = 20,
  }) async => const Right(
    Paginated<DesignTicket>(
      items: [_ticket],
      meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 1),
    ),
  );

  @override
  Future<Either<Failure, DesignTicketCounts>> statusCounts({
    String? designer,
    String? requestedBy,
    int? customerId,
    int? orderId,
    String? search,
  }) async => const Right(
    DesignTicketCounts(byStatus: {'new': 1}, total: 1),
  );

  @override
  Future<Either<Failure, DesignTicket>> ticket(int ticketId) async => const Right(_ticket);

  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('Cairo');
    for (final file in ['Almarai-Regular.ttf', 'Almarai-Bold.ttf']) {
      loader.addFont(
        File('assets/fonts/$file').readAsBytes().then((bytes) => ByteData.view(bytes.buffer)),
      );
    }
    await loader.load();
  });

  testWidgets('draw the list band and the ticket header', (tester) async {
    await Injector.reset();
    final repository = _StubRepository();
    sl.registerSingleton<Session>(Session());
    sl.registerFactory<DesignTicketsCubit>(
      () => DesignTicketsCubit(
        getTickets: GetDesignTickets(repository),
        getCounts: GetDesignTicketCounts(repository),
        // القبول من الصفّ نفسه — الشاشة ترسم زرّ «قبول» على كل صفٍّ يقول الخادم إنّ قارئه يجوز
        // له أخذه، فالمعاينة تحتاج الحالة التي تحتاجها الشاشة.
        acceptTicket: AcceptDesignTicket(repository),
      ),
    );
    sl.registerFactoryParam<DesignTicketDetailCubit, int, void>(
      (ticketId, _) => DesignTicketDetailCubit(
        ticketId: ticketId,
        getTicket: GetDesignTicket(repository),
        acceptTicket: AcceptDesignTicket(repository),
        assignTicket: AssignDesignTicket(repository),
        updateTicket: UpdateDesignTicket(repository),
        cancelTicket: CancelDesignTicket(repository),
        attachFile: AttachDesignTicketFile(repository),
        removeAttachment: RemoveDesignTicketAttachment(repository),
        submitVersion: SubmitDesignVersion(repository),
        reviewVersion: ReviewDesignVersion(repository),
      ),
    );

    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final key = GlobalKey();

    Future<void> open(Widget screen) async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: ScreenUtilInit(
            designSize: const Size(430, 932),
            builder: (context, _) => MaterialApp(
              debugShowCheckedModeBanner: false,
              // Drawn dark, which is how the shop reads it.
              theme: MaterialTheme(
                Typography.material2021().white.apply(fontFamily: 'Cairo'),
              ).dark(),
              locale: const Locale('ar'),
              supportedLocales: const [Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: screen,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> shoot(String name) async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${Platform.environment['PREVIEW_OUT'] ?? '.'}/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
      });
    }

    await open(const DesignTicketsPage());
    await shoot('tickets-1-list');

    await tester.tap(find.byType(DropdownButtonFormField<DesignTicketStatus?>));
    await tester.pumpAndSettle();
    await shoot('tickets-2-filter-open');

    await tester.tap(find.text('الكل (1)').last);
    await tester.pumpAndSettle();

    await open(const DesignTicketDetailPage(ticketId: 1));
    await shoot('tickets-3-detail');
  });
}
