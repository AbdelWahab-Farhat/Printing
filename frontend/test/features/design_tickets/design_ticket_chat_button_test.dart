import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/presentation/viewmodel/design_ticket_detail_cubit.dart';
import 'package:dayaa/features/design_tickets/presentation/views/design_ticket_detail_page.dart';
import 'package:dayaa/features/design_tickets/repositories/design_ticket_repository.dart';
import 'package:dayaa/features/design_tickets/usecases/design_ticket_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// يجيب بالتذكرة التي يعطيها الاختبار، ويعدّ القراءات.
class _StubRepository implements DesignTicketRepository {
  _StubRepository(this.current);

  DesignTicket current;
  int reads = 0;

  @override
  Future<Either<Failure, DesignTicket>> ticket(int ticketId) async {
    reads++;

    return Right(current);
  }

  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DesignTicket _ticket({int unread = 0}) => DesignTicket(
  id: 1,
  code: 'D1',
  title: 'كيس شحن أسود',
  description: 'الشعار في المنتصف',
  status: DesignTicketStatus.inProgress,
  statusLabel: 'قيد التصميم',
  customerId: 4,
  customerName: 'متجر إكس',
  unreadCommentsCount: unread,
);

/// زرُّ «المحادثة» في تذكرة التصميم — **زرٌّ عائمٌ باسمه، لا أيقونةٌ في الشريط.**
///
/// كان أيقونةَ فقاعتين بين «تعديل» و«إلغاء» و«السجل» في الشريط العلوي، فلم يعرف أحدٌ أنّ
/// للتذكرة محادثة. الآن يقول اسمه، ويحمل عددَ ما لم يُقرأ، ويبقى ظاهراً مهما نزلت الصفحة.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _StubRepository repository;

  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(view.reset);

    repository = _StubRepository(_ticket());

    sl.registerSingleton<Session>(
      Session()
        ..adopt(
          AuthUser(
            id: 9,
            name: 'هدى',
            phone: '0911234567',
            permissions: [AppPermission.viewDesignTickets.wire],
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
  });

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
          path: Routes.designTicketComments(1),
          builder: (_, _) => const Scaffold(body: Text('شاشة المحادثة')),
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

  Finder chatButton() => find.widgetWithText(FloatingActionButton, 'المحادثة');

  testWidgets('the conversation is a floating button with its name, not an icon in the bar', (
    tester,
  ) async {
    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(chatButton(), findsOneWidget);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.byTooltip('المحادثة')),
      findsNothing,
    );
  });

  testWidgets('the unread replies are counted on the button', (tester) async {
    // Arrange
    repository.current = _ticket(unread: 3);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.descendant(of: chatButton(), matching: find.text('3')), findsOneWidget);
  });

  testWidgets('no count is drawn when everything is read', (tester) async {
    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    final badge = tester.widget<Badge>(
      find.descendant(of: chatButton(), matching: find.byType(Badge)),
    );
    expect(badge.isLabelVisible, isFalse);
  });

  testWidgets('tapping it opens the conversation, and coming back re-reads the ticket', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    final readsBefore = repository.reads;

    // Act
    await tester.tap(chatButton());
    await tester.pumpAndSettle();
    final opened = find.text('شاشة المحادثة').evaluate().isNotEmpty;
    tester.state<NavigatorState>(find.byType(Navigator).last).pop();
    await tester.pumpAndSettle();

    // Assert — الشاشةُ تُطفئ الشارة على الخادم، فيُعاد قراءة التذكرة عند العودة.
    expect(opened, isTrue);
    expect(repository.reads, greaterThan(readsBefore));
  });
}
