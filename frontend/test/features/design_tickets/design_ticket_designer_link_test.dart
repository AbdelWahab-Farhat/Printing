import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_file.dart';
import 'package:dayaa/features/design_tickets/presentation/viewmodel/design_ticket_detail_cubit.dart';
import 'package:dayaa/features/design_tickets/presentation/views/design_ticket_detail_page.dart';
import 'package:dayaa/features/design_tickets/repositories/design_ticket_repository.dart';
import 'package:dayaa/features/design_tickets/usecases/design_ticket_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _StubRepository implements DesignTicketRepository {
  @override
  Future<Either<Failure, DesignTicket>> ticket(int ticketId) async => const Right(
    DesignTicket(
      id: 1,
      code: 'D1',
      title: 'كيس شحن أسود',
      description: 'الشعار في المنتصف',
      status: DesignTicketStatus.completed,
      statusLabel: 'مكتمل',
      customerId: 4,
      customerName: 'متجر إكس',
      designer: DesignTicketActor(id: 15, name: 'مصمم تجريبي'),
      acceptedBy: DesignTicketActor(id: 16, name: 'مصمم بديل'),
      approvedBy: DesignTicketActor(id: 2, name: 'فرحات'),
    ),
  );

  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// اسم المصمم على التذكرة هو الطريق إلى صفحته، ومنها إلى محفظته.
///
/// Arrange - Act - Assert في كل اختبار.
void main() {
  void arrange(List<AppPermission> grants) {
    final repository = _StubRepository();

    sl.registerSingleton<Session>(
      Session()
        ..adopt(
          AuthUser(
            id: 9,
            name: 'هدى',
            phone: '0911234567',
            permissions: [for (final grant in grants) grant.wire],
          ),
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
        withdrawVersion: WithdrawDesignVersion(repository),
        setPay: SetDesignTicketPay(repository),
      ),
    );
  }

  tearDown(() => sl.reset());

  Widget host() {
    final router = GoRouter(
      initialLocation: '/design-tickets/1',
      routes: [
        GoRoute(
          path: '/design-tickets/1',
          builder: (_, _) => const DesignTicketDetailPage(ticketId: 1),
        ),
        GoRoute(
          path: Routes.employeePath,
          builder: (_, state) => Scaffold(body: Text('موظف ${state.pathParameters['id']}')),
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp.router(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
  }

  Future<void> open(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(430, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
  }

  testWidgets('the designer named on the ticket opens their page', (tester) async {
    // Arrange
    arrange([AppPermission.viewDesignTickets, AppPermission.viewUsers]);
    await open(tester);

    // Act
    await tester.tap(find.text('مصمم تجريبي'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('موظف 15'), findsOneWidget);
  });

  testWidgets('so does whoever took it, which may be somebody else', (tester) async {
    // Arrange
    arrange([AppPermission.viewDesignTickets, AppPermission.viewUsers]);
    await open(tester);

    // Act
    await tester.tap(find.text('مصمم بديل'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('موظف 16'), findsOneWidget);
  });

  testWidgets('a reader the employee page would turn away is given no link', (tester) async {
    // Arrange
    arrange([AppPermission.viewDesignTickets]);
    await open(tester);

    // Act
    await tester.tap(find.text('مصمم تجريبي'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('موظف 15'), findsNothing);
    expect(find.text('مصمم تجريبي'), findsOneWidget);
  });
}
