import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_counts.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_file.dart';
import 'package:dayaa/features/design_tickets/presentation/viewmodel/design_tickets_cubit.dart';
import 'package:dayaa/features/design_tickets/presentation/views/design_tickets_page.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/design_version_tile.dart';
import 'package:dayaa/features/design_tickets/repositories/design_ticket_repository.dart';
import 'package:dayaa/features/design_tickets/usecases/design_ticket_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// One ticket, and a record of the statuses the list was asked for.
class _StubRepository implements DesignTicketRepository {
  /// Every `statuses` argument the screen has sent, newest last.
  final List<List<String>> asked = <List<String>>[];

  /// Whether the row on the list may be taken by whoever is reading it.
  bool offersAcceptance = false;

  /// The newest version the list sends back, or null for a ticket nobody has drawn for.
  DesignTicketFile? latestVersion;

  /// The ids the accept endpoint was called with.
  final List<int> accepted = <int>[];

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
  }) async {
    asked.add(statuses);

    return Right(
      Paginated<DesignTicket>(
        items: [
          DesignTicket(
            id: 1,
            code: 'D1',
            title: 'تصميم كيس عصري',
            description: 'كيس شحن بهوية جديدة',
            status: DesignTicketStatus.fresh,
            statusLabel: 'جديد',
            customerId: 4,
            customerName: 'اسامة حماد',
            customerCode: 'A713',
            isInSharedPool: true,
            canAccept: offersAcceptance,
            latestVersion: latestVersion,
          ),
        ],
        meta: const PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 1),
      ),
    );
  }

  @override
  Future<Either<Failure, DesignTicket>> accept(int ticketId) async {
    accepted.add(ticketId);

    return const Right(
      DesignTicket(
        id: 1,
        code: 'D1',
        title: 'تصميم كيس عصري',
        description: 'كيس شحن بهوية جديدة',
        status: DesignTicketStatus.inProgress,
        statusLabel: 'قيد التصميم',
        customerId: 4,
        customerName: 'اسامة حماد',
      ),
    );
  }

  @override
  Future<Either<Failure, DesignTicketCounts>> statusCounts({
    String? designer,
    String? requestedBy,
    int? customerId,
    int? orderId,
    String? search,
  }) async => const Right(
    DesignTicketCounts(byStatus: {'new': 1, 'in_progress': 0}, total: 1),
  );

  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// تذاكر التصميم — the band above the list.
///
/// **One filter, beside the search box.** The screen shipped with two rows of chips above the
/// list — the designer's three queues, and the six statuses — and both were taken off: the
/// queues because nobody was asking that question of this screen, the statuses because a row
/// that scrolls sideways hides half its own options.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _StubRepository repository;

  late Session session;

  /// Signs in an account holding exactly the grants named, and nothing else.
  void signInWith(List<AppPermission> grants) => session.adopt(
    AuthUser(
      id: 1,
      name: 'عبدالوهاب',
      phone: '0911234567',
      permissions: [for (final grant in grants) grant.wire],
    ),
  );

  setUp(() {
    repository = _StubRepository();
    session = Session();
    sl.registerSingleton<Session>(session);
    sl.registerFactory<DesignTicketsCubit>(
      () => DesignTicketsCubit(
        getTickets: GetDesignTickets(repository),
        getCounts: GetDesignTicketCounts(repository),
        acceptTicket: AcceptDesignTicket(repository),
      ),
    );
  });

  tearDown(() => sl.reset());

  /// The shell every test draws the screen inside — RTL and Arabic, like the app.
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
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: DesignTicketsPage(),
      ),
    ),
  );

  testWidgets('the designer queues are gone from the screen', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act - Assert — «الكل / شغلي / الطابور المشترك» were a row of their own above the list.
    // The server still answers the question; this screen no longer asks it. «شغلي» is the one
    // word that belonged to that row alone — the card still calls unclaimed work by its name.
    expect(find.text('شغلي'), findsNothing);
    expect(find.byType(FilterOptionChip), findsNothing);
  });

  testWidgets('the statuses are one dropdown, opening on الكل', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act - Assert — one closed control carrying the total, not six chips on a sideways
    // scroller. The other five are inside it and are not on screen until it is opened.
    expect(find.byType(DropdownButtonFormField<DesignTicketStatus?>), findsOneWidget);
    expect(find.text('الكل (1)'), findsOneWidget);
    expect(find.text('بانتظار المراجعة (0)'), findsNothing);
  });

  testWidgets('choosing a status narrows the list to it', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(repository.asked.last, isEmpty);

    // Act
    await tester.tap(find.byType(DropdownButtonFormField<DesignTicketStatus?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('جديد (1)').last);
    await tester.pumpAndSettle();

    // Assert — the narrowing is the server's to do, and the field says what was chosen.
    expect(repository.asked.last, ['new']);
    expect(find.text('جديد (1)'), findsOneWidget);
  });

  testWidgets('going back to الكل drops the status again', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<DesignTicketStatus?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مكتمل (0)').last);
    await tester.pumpAndSettle();
    expect(repository.asked.last, ['completed']);

    // Act — «الكل» is a row in the menu like any other, so clearing needs no second control.
    await tester.tap(find.byType(DropdownButtonFormField<DesignTicketStatus?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الكل (1)').last);
    await tester.pumpAndSettle();

    // Assert
    expect(repository.asked.last, isEmpty);
  });

  testWidgets('a designer, who has no drawer, is given a way to الإعدادات', (tester) async {
    // Arrange — the account the router sends straight here: it may take design work and cannot
    // read orders, so it never reaches the home shell and never sees the drawer that holds
    // «الإعدادات» — the one screen with «تسجيل الخروج» on it.
    signInWith([AppPermission.acceptDesignTickets, AppPermission.viewDesignTickets]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — without this the designer is stuck on this screen for good.
    expect(find.byTooltip('الإعدادات'), findsOneWidget);
  });

  testWidgets('an employee who came through the drawer is not offered it twice', (tester) async {
    // Arrange — somebody who reads orders lands on the home shell and pushed their way here,
    // so they have both a back arrow and the drawer behind it.
    signInWith([AppPermission.viewDesignTickets, AppPermission.viewOrders]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byTooltip('الإعدادات'), findsNothing);
  });

  testWidgets('a ticket the reader may take carries «قبول» on the row', (tester) async {
    // Arrange — a designer scrolling the pool. Opening each ticket to find out whether it is
    // free is the scroll this button exists to save.
    signInWith([AppPermission.viewDesignTickets, AppPermission.acceptDesignTickets]);
    repository.offersAcceptance = true;

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('قبول'), findsOneWidget);
  });

  testWidgets('a ticket the reader may not take carries nothing', (tester) async {
    // Arrange — the employee who raised it, and every ticket already taken.
    signInWith([AppPermission.viewDesignTickets, AppPermission.viewOrders]);
    repository.offersAcceptance = false;

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('قبول'), findsNothing);
  });

  testWidgets('«قبول» asks before it claims, and backing out claims nothing', (tester) async {
    // Arrange — the tap locks every other designer out and makes this account the only one
    // that may upload, which is too much to hang on a mis-tap while scrolling.
    signInWith([AppPermission.viewDesignTickets, AppPermission.acceptDesignTickets]);
    repository.offersAcceptance = true;
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('قبول'));
    await tester.pumpAndSettle();
    expect(find.text('قبول الطلب؟'), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    // Assert
    expect(repository.accepted, isEmpty);
  });

  testWidgets('confirming takes it, and the row says so without a re-read', (tester) async {
    // Arrange
    signInWith([AppPermission.viewDesignTickets, AppPermission.acceptDesignTickets]);
    repository.offersAcceptance = true;
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    final readsBefore = repository.asked.length;

    // Act
    await tester.tap(find.text('قبول'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('قبول الطلب'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Assert — the saved row is handed back, so the list patches rather than asks again.
    expect(repository.accepted, [1]);
    expect(repository.asked.length, readsBefore);
    expect(find.text('قيد التصميم'), findsOneWidget);
  });

  testWidgets('the row names the customer by code and the designer by role', (tester) async {
    // Arrange — two lines behind the same person icon said nothing about which was which.
    signInWith([AppPermission.viewDesignTickets, AppPermission.viewOrders]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — the code, not the name: it is what the search box takes and what somebody says
    // on the telephone.
    expect(find.text('العميل: A713'), findsOneWidget);
    expect(find.text('اسامة حماد'), findsNothing);
    expect(find.text('المصمم: الطابور المشترك'), findsOneWidget);
  });

  testWidgets('the newest design is drawn on the row when there is one', (tester) async {
    // Arrange — the list sends one file rather than the whole conversation; the card draws it.
    signInWith([AppPermission.viewDesignTickets, AppPermission.viewOrders]);
    repository.latestVersion = const DesignTicketFile(
      id: 9,
      designTicketId: 1,
      kind: DesignTicketFileKind.submission,
      kindLabel: 'نسخة',
      label: 'النسخة 1',
      fileKind: DesignKind.image,
      fileKindLabel: 'صورة',
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(DesignTicketFileThumbnail), findsOneWidget);
  });

  testWidgets('a ticket nobody has drawn for carries no square', (tester) async {
    // Arrange
    signInWith([AppPermission.viewDesignTickets, AppPermission.viewOrders]);
    repository.latestVersion = null;

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(DesignTicketFileThumbnail), findsNothing);
  });
}
