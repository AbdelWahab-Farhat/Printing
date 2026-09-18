import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/files/picked_file.dart';
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
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hands back whatever the test told it the person chose.
///
/// A fake rather than the real picker: both packages behind it answer through a platform
/// channel that does not exist under `flutter_test`, so a real pick would hang.
class _FakePicker implements AttachmentPicker {
  _FakePicker(this.files);

  List<PickedFile> files;

  @override
  Future<List<PickedFile>> pick(
    AttachmentSource source, {
    List<String> extensions = AttachmentPicker.defaultExtensions,
  }) async => files;
}

/// Records every attachment upload, and refuses the ones the test names.
class _StubRepository implements DesignTicketRepository {
  /// Filenames the attach endpoint was called with, in the order it was called.
  final List<String> attached = <String>[];

  /// Filenames to answer with a refusal rather than a success.
  Set<String> refuse = <String>{};

  static const _ticket = DesignTicket(
    id: 1,
    code: 'D1',
    title: 'تصميم كيس عصري',
    description: 'كيس شحن بهوية جديدة',
    status: DesignTicketStatus.fresh,
    statusLabel: 'جديد',
    customerId: 4,
    customerName: 'اسامة حماد',
    instructions: 'واطلع طول',
    canManage: true,
  );

  @override
  Future<Either<Failure, DesignTicket>> ticket(int ticketId) async => const Right(_ticket);

  @override
  Future<Either<Failure, DesignTicketFile>> attach(
    int ticketId, {
    required String path,
    required String filename,
    String? note,
    ProgressCallback? onProgress,
  }) async {
    attached.add(filename);

    if (refuse.contains(filename)) {
      return const Left(Failure.server(message: 'الملف يجب أن يكون صورة أو PDF'));
    }

    return const Right(
      DesignTicketFile(
        id: 9,
        designTicketId: 1,
        kind: DesignTicketFileKind.brief,
        kindLabel: 'مرفق',
        label: 'مرفق',
        fileKind: DesignKind.image,
        fileKindLabel: 'صورة',
      ),
    );
  }

  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// «إضافة مرفق» — several at once.
///
/// **The picker has always returned a list.** The screen took `picked.first` and dropped the
/// rest without saying so, which is why somebody selecting four reference photos got one.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _StubRepository repository;
  late _FakePicker picker;

  PickedFile file(String name) => PickedFile(path: '/tmp/$name', name: name, sizeBytes: 1024);

  setUp(() {
    repository = _StubRepository();
    picker = _FakePicker(const []);

    sl.registerSingleton<Session>(
      Session()
        ..adopt(
          AuthUser(
            id: 1,
            name: 'عبدالوهاب',
            phone: '0911234567',
            permissions: [
              AppPermission.viewDesignTickets.wire,
              AppPermission.manageDesignTickets.wire,
            ],
          ),
        ),
    );
    sl.registerSingleton<AttachmentPicker>(picker);
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
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: DesignTicketDetailPage(ticketId: 1),
      ),
    ),
  );

  /// Taps «إضافة مرفق» and answers the source sheet with «مستندات».
  Future<void> addAttachments(WidgetTester tester) async {
    await tester.tap(find.text('إضافة مرفق'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مستندات'));
    await tester.pumpAndSettle();
    // The snackbar dismisses itself on a three-second timer; a timer still running when the
    // tree is torn down fails the test on an invariant unrelated to the upload.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  testWidgets('every file the person chose is uploaded, one after another', (tester) async {
    // Arrange
    picker.files = [file('a.png'), file('b.png'), file('c.pdf')];
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await addAttachments(tester);

    // Assert — three requests in the order they were picked, not one and a silent drop.
    expect(repository.attached, ['a.png', 'b.png', 'c.pdf']);
  });

  testWidgets('one refusal does not take the rest of the batch with it', (tester) async {
    // Arrange — the middle one is refused, which is the case that matters: stopping there
    // would leave the third unsent and the person guessing which arrived.
    picker.files = [file('a.png'), file('bad.png'), file('c.png')];
    repository.refuse = {'bad.png'};
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await addAttachments(tester);

    // Assert
    expect(repository.attached, ['a.png', 'bad.png', 'c.png']);
  });

  testWidgets('the brief is one block, whatever an older ticket carries', (tester) async {
    // Arrange — this row predates the merge, so it still has `instructions`.

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — one heading, and the older ticket's words are under it rather than dropped.
    expect(find.text('الطلب'), findsOneWidget);
    expect(find.text('الملاحظات والتعليمات'), findsNothing);
    expect(find.text('كيس شحن بهوية جديدة'), findsOneWidget);
    expect(find.text('واطلع طول'), findsOneWidget);
  });
}
