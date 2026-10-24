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

/// يجيب بالتذكرة التي يعطيها الاختبار، ويسجّل كلَّ سحب.
class _StubRepository implements DesignTicketRepository {
  _StubRepository(this.current);

  DesignTicket current;
  int reads = 0;
  final withdrawn = <(int, int)>[];

  @override
  Future<Either<Failure, DesignTicket>> ticket(int ticketId) async {
    reads++;

    return Right(current);
  }

  @override
  Future<Either<Failure, DesignTicketFile>> withdrawVersion(int ticketId, int versionId) async {
    withdrawn.add((ticketId, versionId));

    return Right(_version.copyWith(status: DesignSubmissionStatus.withdrawn));
  }

  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _version = DesignTicketFile(
  id: 21,
  designTicketId: 1,
  kind: DesignTicketFileKind.submission,
  kindLabel: 'تصميم',
  label: 'النسخة 1',
  fileKind: DesignKind.image,
  fileKindLabel: 'صورة',
  version: 1,
  status: DesignSubmissionStatus.proposed,
  statusLabel: 'بانتظار المراجعة',
  isAwaitingReview: true,
);

DesignTicket _ticket({required bool canWithdraw}) => DesignTicket(
  id: 1,
  code: 'D1',
  title: 'كيس شحن أسود',
  description: 'الشعار في المنتصف',
  status: DesignTicketStatus.underReview,
  statusLabel: 'بانتظار المراجعة',
  customerId: 4,
  customerName: 'متجر إكس',
  versions: const [_version],
  canWithdraw: canWithdraw,
);

/// «سحب النسخة» — **المصمّم يصلح ملفاً رفعه خطأً بنفسه.** الزرُّ لمن يقول الخادمُ إنه يسحب
/// (`can_withdraw`: مَن رفع النسخة التي بانتظار المراجعة)، ويُسأل قبل أن يسحب، ثم تُقرأ التذكرة من
/// جديد فيظهر «رفع نسخة معدّلة».
///
/// Arrange - Act - Assert throughout.
void main() {
  late _StubRepository repository;

  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(view.reset);

    repository = _StubRepository(_ticket(canWithdraw: true));

    sl.registerSingleton<Session>(
      Session()
        ..adopt(
          AuthUser(
            id: 9,
            name: 'هدى',
            phone: '0911234567',
            permissions: [
              AppPermission.viewDesignTickets.wire,
              AppPermission.submitDesignTickets.wire,
            ],
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
      ),
    );
  });

  tearDown(() => sl.reset());

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
      home: DesignTicketDetailPage(ticketId: 1),
    ),
  );

  testWidgets('the uploader withdraws the version waiting on review, after saying yes', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    final readsBefore = repository.reads;

    // Act
    await tester.scrollUntilVisible(find.text('سحب النسخة'), 200);
    await tester.tap(find.text('سحب النسخة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('سحب').last);
    await tester.pumpAndSettle();
    // التنبيهُ يذهب وحده — وساعتُه لا تبقى معلّقةً بعد الاختبار.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Assert — طلبٌ واحد على النسخة نفسها، ثم قراءةٌ للتذكرة كما صارت.
    expect(repository.withdrawn, [(1, 21)]);
    expect(repository.reads, greaterThan(readsBefore));
  });

  testWidgets('changing one\'s mind withdraws nothing', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.scrollUntilVisible(find.text('سحب النسخة'), 200);
    await tester.tap(find.text('سحب النسخة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    // Assert
    expect(repository.withdrawn, isEmpty);
  });

  testWidgets('nobody else is offered the button', (tester) async {
    // Arrange — المراجِع، أو مَن يقرأ التذكرة فقط: الخادمُ يقول `can_withdraw: false`.
    repository.current = _ticket(canWithdraw: false);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('سحب النسخة'), findsNothing);
  });

  test('a withdrawn version and the flag read off the wire', () {
    // Act
    final file = DesignTicketFile.fromJson({
      'id': 21,
      'design_ticket_id': 1,
      'kind': 'submission',
      'kind_label': 'تصميم',
      'label': 'النسخة 1',
      'file_kind': 'image',
      'file_kind_label': 'صورة',
      'version': 1,
      'status': 'withdrawn',
      'status_label': 'سحبها المصمّم',
      'is_awaiting_review': false,
    });

    // Assert
    expect(file.status, DesignSubmissionStatus.withdrawn);
    expect(file.isWithdrawn, isTrue);
    expect(file.statusLabel, 'سحبها المصمّم');
  });
}
