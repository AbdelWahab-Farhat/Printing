import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/files/attachment_picker.dart';
import 'package:printing/core/files/picked_file.dart';
import 'package:printing/core/session/session.dart';
import 'package:printing/features/auth/models/auth_user.dart';
import 'package:printing/features/customers/models/customer_design.dart';
import 'package:printing/features/customers/presentation/viewmodel/customer_designs_cubit.dart';
import 'package:printing/features/customers/presentation/views/customer_designs_page.dart';
import 'package:printing/features/customers/repositories/customer_design_repository.dart';
import 'package:printing/features/customers/usecases/delete_customer_design.dart';
import 'package:printing/features/customers/usecases/get_customer_designs.dart';
import 'package:printing/features/customers/usecases/rename_customer_design.dart';
import 'package:printing/features/customers/usecases/upload_customer_design.dart';

/// The screen that holds a customer's artwork.
///
/// Real Cubit, real use cases, fake repository and fake picker — so the pre-flight rules, the
/// permission gates and the upload queue are all exercised, and nothing reaches a platform
/// channel that does not exist here.
///
/// Arrange - Act - Assert throughout.
class _MockDesignRepository extends Mock implements CustomerDesignRepository {}

/// Answers with whatever the test put in it, without opening anything.
class _FakePicker implements AttachmentPicker {
  List<PickedFile> answer = const [];
  AttachmentSource? asked;

  @override
  Future<List<PickedFile>> pick(AttachmentSource source) async {
    asked = source;

    return answer;
  }
}

void main() {
  late _MockDesignRepository repository;
  late _FakePicker picker;
  late Session session;

  const flyer = CustomerDesign(
    id: 2,
    customerId: 7,
    label: 'المنشور النهائي',
    kind: DesignKind.pdf,
    kindLabel: 'PDF',
    sizeBytes: 1048576,
    fileUrl: 'https://cdn.example.com/flyer.pdf',
  );

  AuthUser userWith(List<String> permissions) =>
      AuthUser(id: 1, name: 'عبدالوهاب', phone: '0911234567', permissions: permissions);

  setUp(() async {
    await Injector.reset();

    repository = _MockDesignRepository();
    picker = _FakePicker();
    session = Session();

    when(() => repository.designs(7)).thenAnswer((_) async => const Right([flyer]));

    sl
      ..registerSingleton<Session>(session)
      ..registerSingleton<AttachmentPicker>(picker)
      ..registerFactoryParam<CustomerDesignsCubit, int, void>(
        (customerId, _) => CustomerDesignsCubit(
          customerId: customerId,
          getDesigns: GetCustomerDesigns(repository),
          uploadDesign: UploadCustomerDesign(repository),
          renameDesign: RenameCustomerDesign(repository),
          deleteDesign: DeleteCustomerDesign(repository),
        ),
      );
  });

  tearDown(Injector.reset);

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
      home: CustomerDesignsPage(customerId: 7, customerName: 'مطبعة النور'),
    ),
  );

  testWidgets('shows the customer whose library this is, and what is in it', (tester) async {
    // Arrange
    session.adopt(userWith(['customers.view']));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — a PDF has no thumbnail to draw, so the tile says what it is instead.
    expect(find.text('مطبعة النور'), findsOneWidget);
    expect(find.text('المنشور النهائي'), findsOneWidget);
    expect(find.text('PDF · 1 ميجابايت'), findsOneWidget);
  });

  testWidgets('an empty library says what it is for, not just that it is empty', (
    tester,
  ) async {
    // Arrange — an empty screen that only reports emptiness leaves somebody wondering whether
    // it is broken.
    when(() => repository.designs(7)).thenAnswer((_) async => const Right([]));
    session.adopt(userWith(['customers.view']));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('لا توجد تصاميم لهذا العميل'), findsOneWidget);
    expect(find.textContaining('عند إنشاء الطلبات'), findsOneWidget);
  });

  testWidgets('somebody who may only read is offered nothing to press', (tester) async {
    // Arrange — a courtesy, never a boundary: the server refuses either way, and hiding the
    // button spares them work they cannot finish.
    session.adopt(userWith(['customers.view']));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('إضافة تصميم'), findsNothing);
  });

  testWidgets('the sheet, the picker and the upload are one flow', (tester) async {
    // Arrange
    session.adopt(userWith(['customers.view', 'customers.manage']));
    picker.answer = const [
      PickedFile(path: '/tmp/logo.png', name: 'logo.png', sizeBytes: 2048),
    ];
    when(
      () => repository.upload(
        any(),
        path: any(named: 'path'),
        filename: any(named: 'filename'),
        label: any(named: 'label'),
        notes: any(named: 'notes'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer(
      (_) async => const Right(
        CustomerDesign(
          id: 3,
          customerId: 7,
          label: 'logo.png',
          kind: DesignKind.image,
          kindLabel: 'صورة',
        ),
      ),
    );

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('إضافة تصميم'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مستندات'));
    await tester.pumpAndSettle();

    // Assert — the sheet asked the picker for the source the user chose, and what came back is
    // now in the library.
    expect(picker.asked, AttachmentSource.documents);
    expect(find.text('logo.png'), findsOneWidget);
    verify(
      () => repository.upload(
        7,
        path: '/tmp/logo.png',
        filename: 'logo.png',
        label: any(named: 'label'),
        notes: any(named: 'notes'),
        onProgress: any(named: 'onProgress'),
      ),
    ).called(1);
  });

  testWidgets('backing out of the picker uploads nothing and says nothing', (tester) async {
    // Arrange — a person changing their mind is an ordinary ending.
    session.adopt(userWith(['customers.view', 'customers.manage']));
    picker.answer = const [];

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('إضافة تصميم'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('صور'));
    await tester.pumpAndSettle();

    // Assert
    expect(picker.asked, AttachmentSource.photos);
    verifyNever(
      () => repository.upload(
        any(),
        path: any(named: 'path'),
        filename: any(named: 'filename'),
        label: any(named: 'label'),
        notes: any(named: 'notes'),
        onProgress: any(named: 'onProgress'),
      ),
    );
  });

  testWidgets('a stopped upload keeps its file on screen with a way to try again', (
    tester,
  ) async {
    // Arrange
    session.adopt(userWith(['customers.view', 'customers.manage']));
    picker.answer = const [
      PickedFile(path: '/tmp/logo.png', name: 'logo.png', sizeBytes: 2048),
    ];
    when(
      () => repository.upload(
        any(),
        path: any(named: 'path'),
        filename: any(named: 'filename'),
        label: any(named: 'label'),
        notes: any(named: 'notes'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer(
      (_) async => const Left(Failure.network(message: FailureMessages.noConnection)),
    );

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('إضافة تصميم'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مستندات'));
    await tester.pumpAndSettle();

    // Assert — the file is still named, the reason is beside it, and the retry is a button
    // rather than "pick it again".
    expect(find.text('logo.png'), findsOneWidget);
    expect(find.text(FailureMessages.noConnection), findsOneWidget);
    expect(find.byTooltip('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('the options sheet offers a reader nothing that would end in a 403', (
    tester,
  ) async {
    // Arrange
    session.adopt(userWith(['customers.view']));
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act — the ⋯ on the tile, not a long press: the long press opens the same sheet, but it
    // is a gesture nobody discovers and this is the way in that has to work.
    await tester.tap(find.byTooltip('خيارات التصميم'));
    await tester.pumpAndSettle();

    // Assert — opening the file is everybody's; changing it is not.
    expect(find.text('فتح الملف'), findsOneWidget);
    expect(find.text('إعادة التسمية'), findsNothing);
    expect(find.text('حذف'), findsNothing);
  });

  testWidgets('deleting asks first, and says the file is not destroyed', (tester) async {
    // Arrange — the row is hidden and the stored object stays, so an order printed last year
    // can still show what was printed. The dialog has to say so.
    session.adopt(userWith(['customers.view', 'customers.manage']));
    when(() => repository.remove(7, 2)).thenAnswer((_) async => const Right('تم حذف التصميم'));

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byTooltip('خيارات التصميم'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();

    // Assert — the warning first.
    expect(find.text('حذف التصميم؟'), findsOneWidget);
    expect(find.textContaining('الطلبات السابقة'), findsOneWidget);

    // Act — the dialog's confirm button, which is the `FilledButton`; the sheet's own row is a
    // `ListTile` and has already gone.
    await tester.tap(find.widgetWithText(FilledButton, 'حذف'));
    await tester.pumpAndSettle();

    // Assert
    verify(() => repository.remove(7, 2)).called(1);
    expect(find.text('لا توجد تصاميم لهذا العميل'), findsOneWidget);
    expect(find.text('تم حذف التصميم'), findsOneWidget);

    // The success toast holds a three-second dismissal timer of its own, and a timer still
    // pending when the tree is torn down fails the test. Let it run out.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
