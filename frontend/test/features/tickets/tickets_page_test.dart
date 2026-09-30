import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_counts.dart';
import 'package:dayaa/features/design_tickets/presentation/viewmodel/design_tickets_cubit.dart';
import 'package:dayaa/features/design_tickets/presentation/views/design_tickets_page.dart';
import 'package:dayaa/features/design_tickets/repositories/design_ticket_repository.dart';
import 'package:dayaa/features/design_tickets/usecases/design_ticket_usecases.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/presentation/viewmodel/support_tickets_cubit.dart';
import 'package:dayaa/features/support/presentation/views/support_tickets_page.dart';
import 'package:dayaa/features/support/repositories/support_repository.dart';
import 'package:dayaa/features/support/usecases/support_usecases.dart';
import 'package:dayaa/features/tickets/presentation/views/tickets_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSupportRepository extends Mock implements SupportRepository {}

/// لا تذاكر تصميم، وعددٌ صفر — يكفي أن تُبنى القائمة.
class _EmptyDesignRepository implements DesignTicketRepository {
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
      items: [],
      meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 0),
    ),
  );

  @override
  Future<Either<Failure, DesignTicketCounts>> statusCounts({
    String? designer,
    String? requestedBy,
    int? customerId,
    int? orderId,
    String? search,
  }) async => const Right(DesignTicketCounts(byStatus: {}, total: 0));

  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// «التذاكر»: تذاكر التصميم وتذاكر العملاء في شاشةٍ واحدة، تبويبين.
///
/// كانت تذاكرُ الدعم صفّاً في الدرج، وتذاكرُ التصميم أيقونةً في الشريط. طلب المستخدم أن تجتمعا في
/// خانة تذاكر التصميم باسمٍ عامّ، وتبويبين: «تصميم» و«العملاء» — بلا كلمة «تذاكر» قبلهما
/// (2026-09-25).
///
/// **والتبويبان هما ما يملك القارئ فتحه**، كـ«الجهات»: مَن يرى إحداهما وحدها يجدها كما كانت،
/// بشريطها وعنوانها، لا شريطَ تبويبٍ فوق تبويبٍ واحد لا يفعل شيئاً.
///
/// Arrange - Act - Assert throughout.
void main() {
  Future<void> arrange(List<AppPermission> grants) async {
    await Injector.reset();

    final support = _MockSupportRepository();
    when(support.watchChanges).thenAnswer((_) => const Stream.empty());
    when(() => support.liveResumed).thenAnswer((_) => const Stream<void>.empty());
    when(
      () => support.tickets(
        page: any(named: 'page'),
        status: any(named: 'status'),
        assignedTo: any(named: 'assignedTo'),
      ),
    ).thenAnswer(
      (_) async => const Right(
        Paginated<SupportTicket>(
          items: [],
          meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 0),
        ),
      ),
    );

    final design = _EmptyDesignRepository();

    sl
      ..registerSingleton<Session>(
        Session()
          ..adopt(
            AuthUser(
              id: 1,
              name: 'عبدالوهاب',
              phone: '0911234567',
              permissions: [for (final grant in grants) grant.wire],
            ),
          ),
      )
      ..registerFactory<SupportTicketsCubit>(
        () => SupportTicketsCubit(
          browse: BrowseTickets(support),
          watch: WatchTicketChanges(support),
        ),
      )
      ..registerFactory<DesignTicketsCubit>(
        () => DesignTicketsCubit(
          getTickets: GetDesignTickets(design),
          getCounts: GetDesignTicketCounts(design),
          acceptTicket: AcceptDesignTicket(design),
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
      home: TicketsPage(),
    ),
  );

  tearDown(Injector.reset);

  const both = [AppPermission.viewDesignTickets, AppPermission.viewSupportTickets];

  testWidgets('with both queues it is «التذاكر», «تصميم» first and «العملاء» second', (
    tester,
  ) async {
    // Arrange
    await arrange(both);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — الأول يميناً في شاشةٍ عربية.
    final design = tester.getCenter(find.widgetWithText(Tab, 'تصميم')).dx;
    final customers = tester.getCenter(find.widgetWithText(Tab, 'العملاء')).dx;

    expect(find.text('التذاكر'), findsOneWidget);
    expect(design, greaterThan(customers));
  });

  testWidgets('one bar over both: the lists inside draw none of their own', (tester) async {
    // Arrange
    await arrange(both);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('«العملاء» opens the customers\' queue', (tester) async {
    // Arrange
    await arrange(both);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.widgetWithText(Tab, 'العملاء'));
    await tester.pumpAndSettle();

    // Assert
    final tabs = DefaultTabController.of(tester.element(find.byType(TabBarView)));
    expect(tabs.index, 1);
    expect(find.byType(SupportTicketsPage), findsOneWidget);
  });

  testWidgets('with the design queue alone, it opens as it always did', (tester) async {
    // Arrange
    await arrange([AppPermission.viewDesignTickets]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — شريطُ تبويبٍ فوق تبويبٍ واحد أداةٌ لا تفعل شيئاً.
    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(DesignTicketsPage), findsOneWidget);
    expect(find.text('تذاكر التصميم'), findsOneWidget);
  });

  testWidgets('with the customers\' queue alone, it opens as it always did', (tester) async {
    // Arrange
    await arrange([AppPermission.viewSupportTickets]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(SupportTicketsPage), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
