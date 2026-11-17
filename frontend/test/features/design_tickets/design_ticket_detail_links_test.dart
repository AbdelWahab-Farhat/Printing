import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
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
  _StubRepository(this._ticket);

  final DesignTicket _ticket;

  @override
  Future<Either<Failure, DesignTicket>> ticket(int ticketId) async => Right(_ticket);

  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _forOrder = DesignTicket(
  id: 1,
  code: 'D7',
  title: 'تصميم طلبية 1321',
  description: 'أكياس يد خارجية',
  status: DesignTicketStatus.completed,
  statusLabel: 'مكتمل',
  customerId: 4,
  customerName: 'حساب تجريبي ٢',
  customerCode: 'A730',
  orderId: 77,
  order: DesignTicketOrder(id: 77, code: '1321'),
  designer: DesignTicketActor(id: 15, name: 'مصمم تجريبي'),
  acceptedBy: DesignTicketActor(id: 15, name: 'مصمم تجريبي'),
  approvedBy: DesignTicketActor(id: 2, name: 'فرحات'),
);

/// The customer and the order are the two ways out of a design ticket, and both are links where
/// the reader may open them.
///
/// Arrange - Act - Assert in every test.
void main() {
  void arrange(DesignTicket ticket, List<AppPermission> grants) {
    final repository = _StubRepository(ticket);

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
          path: '/orders/:id',
          builder: (_, state) => Scaffold(body: Text('طلبية ${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/customers/:id',
          builder: (_, state) => Scaffold(body: Text('عميل ${state.pathParameters['id']}')),
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
      ..physicalSize = const Size(430, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
  }

  group('the order', () {
    testWidgets('is named by its bare number and opens the order', (tester) async {
      // Arrange
      arrange(_forOrder, [AppPermission.viewDesignTickets, AppPermission.viewOrders]);
      await open(tester);

      // Act
      await tester.tap(find.text('1321'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('طلبية 77'), findsOneWidget);
    });

    testWidgets('stays as plain text for a reader the order would turn away', (tester) async {
      // Arrange
      arrange(_forOrder, [AppPermission.viewDesignTickets]);
      await open(tester);

      // Act
      await tester.tap(find.text('1321'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('طلبية 77'), findsNothing);
      expect(find.text('1321'), findsOneWidget);
    });

    testWidgets('is not drawn on a ticket raised without one', (tester) async {
      // Arrange
      arrange(
        _forOrder.copyWith(orderId: null, order: null),
        [AppPermission.viewDesignTickets, AppPermission.viewOrders],
      );

      // Act
      await open(tester);

      // Assert
      expect(find.text('الطلبية'), findsNothing);
      expect(find.text('1321'), findsNothing);
    });

    testWidgets('replaces the old «تصميم طلبية» chip rather than sitting beside it', (tester) async {
      // Arrange
      arrange(_forOrder, [AppPermission.viewDesignTickets, AppPermission.viewOrders]);

      // Act
      await open(tester);

      // Assert
      expect(find.text('تصميم طلبية #1321'), findsNothing);
      expect(find.text('الطلبية'), findsOneWidget);
    });
  });

  group('the customer', () {
    testWidgets('opens the account the design lands on', (tester) async {
      // Arrange
      arrange(_forOrder, [AppPermission.viewDesignTickets, AppPermission.viewCustomers]);
      await open(tester);

      // Act
      await tester.tap(find.text('A730'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('عميل 4'), findsOneWidget);
    });

    testWidgets('stays as plain text for a designer', (tester) async {
      // Arrange
      arrange(_forOrder, [AppPermission.viewDesignTickets]);
      await open(tester);

      // Act
      await tester.tap(find.text('A730'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('عميل 4'), findsNothing);
    });
  });

  group('the people', () {
    testWidgets('one person given it and taking it is one row with both roles', (tester) async {
      // Arrange
      arrange(_forOrder, [AppPermission.viewDesignTickets]);

      // Act
      await open(tester);

      // Assert
      expect(find.text('مصمم تجريبي'), findsOneWidget);
      expect(find.text('المصمم · استلمها'), findsOneWidget);
      expect(find.text('اعتمدها'), findsOneWidget);
    });

    testWidgets('a ticket nobody holds says it is not assigned to a designer', (tester) async {
      // Arrange
      arrange(
        _forOrder.copyWith(
          status: DesignTicketStatus.fresh,
          statusLabel: 'جديد',
          designer: null,
          acceptedBy: null,
          approvedBy: null,
          isInSharedPool: true,
        ),
        [AppPermission.viewDesignTickets],
      );

      // Act
      await open(tester);

      // Assert
      expect(find.text('غير مُسنَد لمصمم'), findsOneWidget);
      expect(find.text('الطابور المشترك'), findsNothing);
      expect(find.text('المصمم'), findsOneWidget);
    });
  });

  testWidgets('the status is the pill beside the title, not a track of steps', (tester) async {
    // Arrange
    arrange(_forOrder, [AppPermission.viewDesignTickets]);

    // Act
    await open(tester);

    // Assert
    expect(find.text('مكتمل'), findsOneWidget);
    expect(find.text('قيد التصميم'), findsNothing);
  });

  testWidgets('a withdrawn version is still listed, under its verdict', (tester) async {
    // Arrange
    arrange(
      _forOrder.copyWith(
        versions: const [
          DesignTicketFile(
            id: 21,
            designTicketId: 1,
            kind: DesignTicketFileKind.submission,
            kindLabel: 'نسخة',
            label: 'النسخة 1',
            fileKind: DesignKind.image,
            fileKindLabel: 'صورة',
            version: 1,
            status: DesignSubmissionStatus.withdrawn,
            statusLabel: 'سحبها المصمّم',
          ),
        ],
      ),
      [AppPermission.viewDesignTickets],
    );

    // Act
    await open(tester);

    // Assert
    expect(find.text('التصاميم (1)'), findsOneWidget);
    expect(find.text('سحبها المصمّم'), findsOneWidget);
  });
}
