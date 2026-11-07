import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/print_colors/print_color.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
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

/// يجيب بالتذكرة التي يعطيها الاختبار، ويحفظ ما أُرسل.
class _StubRepository implements DesignTicketRepository {
  _StubRepository(this.current);

  DesignTicket current;

  bool payWasSet = false;
  String? sentPay;
  bool wasAccepted = false;
  String? acceptedPay;
  String? confirmedPay;
  bool wasUpdated = false;
  bool refusesUpdate = false;

  @override
  Future<Either<Failure, DesignTicket>> ticket(int ticketId) async => Right(current);

  @override
  Future<Either<Failure, DesignTicket>> setPay(int ticketId, {required String? designerPay}) async {
    payWasSet = true;
    sentPay = designerPay;

    return Right(current);
  }

  @override
  Future<Either<Failure, DesignTicket>> update(
    int ticketId, {
    required String title,
    required String description,
    String? instructions,
    List<PrintColor>? printColors,
  }) async {
    if (refusesUpdate) return const Left(Failure.server(message: 'لا يمكن تعديل هذا الطلب'));

    wasUpdated = true;

    return Right(current);
  }

  @override
  Future<Either<Failure, DesignTicket>> accept(int ticketId, {String? designerPay}) async {
    wasAccepted = true;
    acceptedPay = designerPay;

    return Right(current);
  }

  @override
  Future<Either<Failure, DesignTicketFile>> reviewVersion(
    int ticketId,
    int versionId, {
    required String verdict,
    String? note,
    String? confirmedPay,
  }) async {
    this.confirmedPay = confirmedPay;

    return const Right(_version);
  }

  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _version = DesignTicketFile(
  id: 3,
  designTicketId: 1,
  kind: DesignTicketFileKind.submission,
  kindLabel: 'نسخة',
  label: 'النسخة 1',
  fileKind: DesignKind.image,
  fileKindLabel: 'صورة',
  status: DesignSubmissionStatus.proposed,
  isAwaitingReview: true,
  uploader: DesignTicketActor(id: 5, name: 'أحمد'),
);

DesignTicket _ticket({
  String? pay,
  String? suggested,
  bool canSetPay = false,
  bool canManage = false,
  bool canAccept = false,
  bool canReview = false,
  List<DesignTicketFile> versions = const [],
}) => DesignTicket(
  id: 1,
  code: 'D1',
  title: 'كيس شحن أسود',
  description: 'الشعار في المنتصف',
  status: DesignTicketStatus.inProgress,
  statusLabel: 'قيد التصميم',
  customerId: 4,
  customerName: 'متجر إكس',
  designerPay: pay,
  suggestedPay: suggested,
  canSetPay: canSetPay,
  canManage: canManage,
  canAccept: canAccept,
  canReview: canReview,
  versions: versions,
);

/// «أجر التصميم» على شاشة التذكرة — SERVICE-PAY-DESIGN §٣ و§٥.
///
/// Arrange - Act - Assert في كل اختبار.
void main() {
  late _StubRepository repository;

  void arrange(DesignTicket ticket, {EmployeeServicePrice? ownService}) {
    repository = _StubRepository(ticket);

    sl.registerSingleton<Session>(
      Session()
        ..adopt(
          AuthUser(
            id: 9,
            name: 'هدى',
            phone: '0911234567',
            permissions: [AppPermission.viewDesignTickets.wire],
            services: [?ownService],
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

  Future<void> open(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(430, 1400)
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
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: DesignTicketDetailPage(ticketId: 1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// ما يبقى من مؤقّت الرسالة الخضراء بعد كل كتابة.
  Future<void> settleSnack(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  Future<void> tapAction(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('the pay is a fact on the ticket, and nothing is said about the wallet', (tester) async {
    // Arrange
    arrange(_ticket(pay: '50.00'));

    // Act
    await open(tester);

    // Assert
    expect(find.text('أجر التصميم'), findsOneWidget);
    expect(find.text('50 د.ل'), findsOneWidget);
    expect(find.textContaining('محفظتك'), findsNothing);
  });

  testWidgets('a reader who is told nothing is shown nothing', (tester) async {
    // Arrange
    arrange(_ticket());

    // Act
    await open(tester);

    // Assert
    expect(find.text('أجر التصميم'), findsNothing);
  });

  testWidgets('a reader who may write it is told it is not set', (tester) async {
    // Arrange
    arrange(_ticket(canSetPay: true));

    // Act
    await open(tester);

    // Assert
    expect(find.text('لم يُحدَّد'), findsOneWidget);
  });

  /// قلم الشريط: «تعديل الطلب» لمن يديرها، و«تعديل أجر التصميم» للمصمم.
  Future<void> pencil(WidgetTester tester, String tooltip) async {
    await tester.tap(find.byTooltip(tooltip));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.text('حفظ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
  }

  testWidgets('the figure on the ticket only reads: the pencil is the way in', (tester) async {
    // Arrange
    arrange(_ticket(pay: '50.00', canSetPay: true));
    await open(tester);

    // Act
    await tester.tap(find.text('50 د.ل'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('a reader who may write nothing is handed no pencil', (tester) async {
    // Arrange
    arrange(_ticket(pay: '50.00'));

    // Act
    await open(tester);

    // Assert
    expect(find.byIcon(AppIcons.edit), findsNothing);
  });

  group('المصمم، ولا يملك «تعديل الطلب»', () {
    testWidgets('the pencil opens the pay alone, on the suggestion', (tester) async {
      // Arrange
      arrange(_ticket(canSetPay: true, suggested: '75.00'));
      await open(tester);

      // Act
      await pencil(tester, 'تعديل أجر التصميم');
      final opened = find.widgetWithText(TextFormField, '75');
      expect(opened, findsOneWidget);
      expect(find.text('عنوان الطلب'), findsNothing);
      await tester.enterText(opened, '80');
      await tester.pump();
      await save(tester);
      await settleSnack(tester);

      // Assert
      expect(repository.sentPay, '80');
      expect(repository.wasUpdated, isFalse);
    });

    testWidgets('emptying the box clears the pay', (tester) async {
      // Arrange
      arrange(_ticket(pay: '50.00', canSetPay: true));
      await open(tester);

      // Act
      await pencil(tester, 'تعديل أجر التصميم');
      await tester.enterText(find.widgetWithText(TextFormField, '50'), '');
      await tester.pump();
      await save(tester);
      await settleSnack(tester);

      // Assert
      expect(repository.payWasSet, isTrue);
      expect(repository.sentPay, isNull);
    });
  });

  group('«تعديل الطلب» لمن يدير التذاكر', () {
    testWidgets('the pay sits on the sheet and saves with the words', (tester) async {
      // Arrange
      arrange(_ticket(pay: '50.00', canManage: true, canSetPay: true));
      await open(tester);

      // Act
      await pencil(tester, 'تعديل الطلب');
      await tester.enterText(find.widgetWithText(TextFormField, '50'), '60');
      await tester.pump();
      await save(tester);
      await settleSnack(tester);

      // Assert
      expect(repository.wasUpdated, isTrue);
      expect(repository.sentPay, '60');
    });

    testWidgets('correcting the words leaves the pay alone', (tester) async {
      // Arrange
      arrange(_ticket(pay: '50.00', canManage: true, canSetPay: true));
      await open(tester);

      // Act
      await pencil(tester, 'تعديل الطلب');
      await save(tester);
      await settleSnack(tester);

      // Assert
      expect(repository.wasUpdated, isTrue);
      expect(repository.payWasSet, isFalse);
    });

    testWidgets('an empty box on a ticket with no pay sends nothing', (tester) async {
      // Arrange
      arrange(_ticket(canManage: true, canSetPay: true));
      await open(tester);

      // Act
      await pencil(tester, 'تعديل الطلب');
      await save(tester);
      await settleSnack(tester);

      // Assert
      expect(repository.payWasSet, isFalse);
    });

    testWidgets('the suggestion in the box is saved as it is seen', (tester) async {
      // Arrange
      arrange(_ticket(suggested: '75.00', canManage: true, canSetPay: true));
      await open(tester);

      // Act
      await pencil(tester, 'تعديل الطلب');
      expect(find.widgetWithText(TextFormField, '75'), findsOneWidget);
      await save(tester);
      await settleSnack(tester);

      // Assert
      expect(repository.sentPay, '75');
    });

    testWidgets('clearing the box clears the pay', (tester) async {
      // Arrange
      arrange(_ticket(pay: '50.00', canManage: true, canSetPay: true));
      await open(tester);

      // Act
      await pencil(tester, 'تعديل الطلب');
      await tester.enterText(find.widgetWithText(TextFormField, '50'), '');
      await tester.pump();
      await save(tester);
      await settleSnack(tester);

      // Assert
      expect(repository.payWasSet, isTrue);
      expect(repository.sentPay, isNull);
    });

    testWidgets('what is not a number stops the save, and the sheet stays', (tester) async {
      // Arrange
      arrange(_ticket(pay: '50.00', canManage: true, canSetPay: true));
      await open(tester);

      // Act
      await pencil(tester, 'تعديل الطلب');
      await tester.enterText(find.widgetWithText(TextFormField, '50'), '1.2.3');
      await tester.pump();
      await save(tester);

      // Assert
      expect(find.text('المبلغ يجب أن يكون رقماً'), findsOneWidget);
      expect(repository.wasUpdated, isFalse);
    });

    testWidgets('a refused edit does not go on to the pay', (tester) async {
      // Arrange
      arrange(_ticket(pay: '50.00', canManage: true, canSetPay: true));
      repository.refusesUpdate = true;
      await open(tester);

      // Act
      await pencil(tester, 'تعديل الطلب');
      await tester.enterText(find.widgetWithText(TextFormField, '50'), '60');
      await tester.pump();
      await save(tester);
      await settleSnack(tester);

      // Assert
      expect(repository.payWasSet, isFalse);
    });

    testWidgets('a server that does not offer the pay keeps the sheet as it was', (tester) async {
      // Arrange: خادمٌ لم يُحدَّث بعد لا يرسل `can_set_pay`، والتطبيق يُنشر قبله.
      arrange(_ticket(canManage: true));
      await open(tester);

      // Act
      await pencil(tester, 'تعديل الطلب');

      // Assert
      expect(find.text('أجر التصميم'), findsNothing);
      expect(find.text('عنوان الطلب'), findsOneWidget);
    });
  });

  Future<void> approve(WidgetTester tester) async {
    await tapAction(tester, 'مراجعة التصميم');
    await tester.pumpAndSettle();
    await tester.tap(find.text('اعتماد التصميم'));
    await tester.pumpAndSettle();
  }

  testWidgets('the confirmation names the amount and the wallet, and the amount is sent back', (
    tester,
  ) async {
    // Arrange
    arrange(_ticket(pay: '50.00', canReview: true, versions: const [_version]));
    await open(tester);

    // Act
    await approve(tester);
    final warned = find.textContaining('ويدخل 50 د.ل محفظة أحمد');
    expect(warned, findsOneWidget);
    await tester.tap(find.text('اعتماد'));
    await tester.pumpAndSettle();
    await settleSnack(tester);

    // Assert
    expect(repository.confirmedPay, '50.00');
  });

  testWidgets('with no pay the confirmation stays as it was, and says it saw none', (tester) async {
    // Arrange
    arrange(_ticket(canReview: true, versions: const [_version]));
    await open(tester);

    // Act
    await approve(tester);
    expect(find.textContaining('محفظة'), findsNothing);
    await tester.tap(find.text('اعتماد'));
    await tester.pumpAndSettle();
    await settleSnack(tester);

    // Assert
    expect(repository.confirmedPay, '0');
  });

  testWidgets('taking a ticket with no pay asks for it, with the reader\'s own price written', (
    tester,
  ) async {
    // Arrange
    arrange(
      _ticket(canAccept: true),
      ownService: const EmployeeServicePrice(
        service: 'design',
        label: 'التصميم',
        suggestedPrice: '75.00',
      ),
    );
    await open(tester);

    // Act
    await tapAction(tester, 'قبول الطلب');
    expect(find.widgetWithText(TextFormField, '75'), findsOneWidget);
    await tester.tap(find.text('قبول الطلب').last);
    await tester.pumpAndSettle();
    await settleSnack(tester);

    // Assert
    expect(repository.wasAccepted, isTrue);
    expect(repository.acceptedPay, '75');
  });

  testWidgets('taking a ticket that has a pay only asks the usual question', (tester) async {
    // Arrange
    arrange(_ticket(pay: '50.00', canAccept: true));
    await open(tester);

    // Act
    await tapAction(tester, 'قبول الطلب');

    // Assert
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('قبول الطلب؟'), findsOneWidget);
  });

  testWidgets('backing out of the sheet takes nothing', (tester) async {
    // Arrange
    arrange(_ticket(canAccept: true));
    await open(tester);

    // Act
    await tapAction(tester, 'قبول الطلب');
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Assert
    expect(repository.wasAccepted, isFalse);
  });
}
