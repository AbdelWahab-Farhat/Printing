import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
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

class _StubRepository implements DesignTicketRepository {
  _StubRepository(this._ticket);

  final DesignTicket _ticket;
  final List<String> reasons = [];

  @override
  Future<Either<Failure, DesignTicket>> ticket(int ticketId) async => Right(_ticket);

  @override
  Future<Either<Failure, DesignTicket>> cancel(int ticketId, {required String reason}) async {
    reasons.add(reason);

    return Right(
      _ticket.copyWith(
        status: DesignTicketStatus.cancelled,
        canManage: false,
        cancellationReason: reason,
      ),
    );
  }

  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _open = DesignTicket(
  id: 1,
  code: 'D7',
  title: 'تصميم طلبية 1321',
  description: 'أكياس يد خارجية',
  status: DesignTicketStatus.assigned,
  statusLabel: 'مُسنَد',
  customerId: 4,
  customerName: 'حساب تجريبي ٢',
  customerCode: 'A730',
  canManage: true,
);

/// Cancelling a ticket asks for a reason in a dialog of its own.
///
/// Arrange - Act - Assert in every test.
void main() {
  late _StubRepository repository;

  setUp(() {
    repository = _StubRepository(_open);

    sl.registerSingleton<Session>(
      Session()
        ..adopt(
          AuthUser(
            id: 9,
            name: 'هدى',
            phone: '0911234567',
            permissions: [AppPermission.manageDesignTickets.wire],
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

  Future<void> openReasonDialog(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(430, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: [Locale('ar')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: DesignTicketDetailPage(ticketId: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('إلغاء التذكرة'));
    await tester.pumpAndSettle();
    // The confirmation's title and its button carry the same words; the button comes last.
    await tester.tap(find.text('إلغاء التذكرة').last);
    await tester.pumpAndSettle();
  }

  Finder reasonField() =>
      find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));

  testWidgets('sends the reason and closes without touching a disposed controller', (
    tester,
  ) async {
    // Arrange
    await openReasonDialog(tester);
    await tester.enterText(reasonField(), '  الزبون غيّر رأيه  ');

    // Act: pumpAndSettle runs the dialog's whole exit animation, which is when the old code
    // threw "A TextEditingController was used after being disposed".
    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle();

    // Assert
    expect(tester.takeException(), isNull);
    expect(repository.reasons, ['الزبون غيّر رأيه']);
    expect(find.byType(AlertDialog), findsNothing);

    // The success toast holds a 3-second timer; let it run out before the tree is torn down.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('keeps the dialog open on a reason shorter than the server accepts', (
    tester,
  ) async {
    // Arrange
    await openReasonDialog(tester);
    await tester.enterText(reasonField(), 'لا');

    // Act
    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('السبب مطلوب'), findsOneWidget);
    expect(repository.reasons, isEmpty);
  });
}
