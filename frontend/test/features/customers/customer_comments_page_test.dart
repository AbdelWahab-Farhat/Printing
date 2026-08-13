import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/session/session.dart';
import 'package:printing/core/widgets/app_snackbar.dart';
import 'package:printing/features/auth/models/auth_user.dart';
import 'package:printing/features/customers/models/customer_comment.dart';
import 'package:printing/features/customers/presentation/viewmodel/customer_comments_cubit.dart';
import 'package:printing/features/customers/presentation/views/customer_comments_page.dart';
import 'package:printing/features/customers/repositories/customer_comment_repository.dart';
import 'package:printing/features/customers/usecases/add_customer_comment.dart';
import 'package:printing/features/customers/usecases/delete_customer_comment.dart';
import 'package:printing/features/customers/usecases/edit_customer_comment.dart';
import 'package:printing/features/customers/usecases/get_customer_comments.dart';

/// The screen that holds what staff have written about a customer.
///
/// **The rule under test is that this screen holds no authorization rule.** «صاحبه أو مشرف» is
/// computed on the server per reader and arrives as `can_edit` / `can_delete` on each note; the
/// row draws its buttons off those and compares no user ids of its own. A second copy of an
/// authorization rule is a copy that drifts.
///
/// Real Cubit, real use cases, fake repository — so the pre-flight checks and the list patching
/// are all exercised.
///
/// Arrange - Act - Assert throughout.
class _MockCommentRepository extends Mock implements CustomerCommentRepository {}

void main() {
  late _MockCommentRepository repository;
  late Session session;

  const mine = CustomerComment(
    id: 1,
    customerId: 7,
    body: 'يفضّل التسليم صباحاً',
    author: CommentAuthor(id: 1, name: 'عبدالوهاب'),
    canEdit: true,
    canDelete: true,
  );

  const theirs = CustomerComment(
    id: 2,
    customerId: 7,
    body: 'لا يردّ إلا على واتساب',
    author: CommentAuthor(id: 9, name: 'علي'),
  );

  AuthUser userWith(List<String> permissions) =>
      AuthUser(id: 1, name: 'عبدالوهاب', phone: '0911234567', permissions: permissions);

  setUp(() async {
    await Injector.reset();

    repository = _MockCommentRepository();
    session = Session()..adopt(userWith(['customers.view']));

    when(() => repository.comments(7)).thenAnswer((_) async => const Right([theirs, mine]));

    sl
      ..registerSingleton<Session>(session)
      ..registerFactoryParam<CustomerCommentsCubit, int, void>(
        (customerId, _) => CustomerCommentsCubit(
          customerId: customerId,
          getComments: GetCustomerComments(repository),
          addComment: AddCustomerComment(repository),
          editComment: EditCustomerComment(repository),
          deleteComment: DeleteCustomerComment(repository),
        ),
      );
  });

  tearDown(Injector.reset);

  // The toast's bookkeeping is library-level, so it outlives the tree that raised it — and by
  // the time a `tearDown` runs, the Navigator that owns its ticker is already being torn down.
  // A test that provokes a refusal clears it while there is still a tree to clear it from.
  Future<void> clearTheToast(WidgetTester tester) async {
    resetSnackBars();
    await tester.pump();
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
      home: CustomerCommentsPage(customerId: 7, customerName: 'مطبعة النور'),
    ),
  );

  testWidgets('shows whose notes these are, and who said each of them', (tester) async {
    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — the name travels with the note, because a note nobody can be asked about is a
    // rumour.
    expect(find.text('مطبعة النور'), findsOneWidget);
    expect(find.text('يفضّل التسليم صباحاً'), findsOneWidget);
    expect(find.text('علي'), findsOneWidget);
  });

  testWidgets('only the notes the server said are changeable offer buttons', (tester) async {
    // Arrange — one of each: mine carries the flags, the colleague's does not.

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — one pair for one note, not two. Absent rather than disabled: a greyed bin
    // invites a tap that can only ever produce a 403.
    expect(find.text('تعديل'), findsOneWidget);
    expect(find.text('حذف'), findsOneWidget);
  });

  testWidgets('an empty screen says what notes are for', (tester) async {
    // Arrange — an empty page that only reports emptiness leaves somebody wondering whether it
    // is broken.
    when(() => repository.comments(7)).thenAnswer((_) async => const Right([]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('لا توجد ملاحظات على هذا العميل'), findsOneWidget);
    expect(find.textContaining('موعد التسليم الذي يفضّله'), findsOneWidget);
  });

  testWidgets('writing a note puts it at the top and empties the box', (tester) async {
    // Arrange
    const added = CustomerComment(
      id: 5,
      customerId: 7,
      body: 'اتفقنا على خصم ٥٪',
      author: CommentAuthor(id: 1, name: 'عبدالوهاب'),
      canEdit: true,
      canDelete: true,
    );
    when(() => repository.add(7, body: any(named: 'body')))
        .thenAnswer((_) async => const Right(added));

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.enterText(find.byType(TextField).first, 'اتفقنا على خصم ٥٪');
    await tester.tap(find.text('إضافة ملاحظة'));
    await tester.pumpAndSettle();

    // Assert — the note is on screen, and the box is ready for the next one.
    expect(find.text('اتفقنا على خصم ٥٪'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField).first).controller?.text, isEmpty);
  });

  testWidgets('a refused note keeps what was typed', (tester) async {
    // Arrange — a refusal that also empties the field costs somebody the sentence they wrote.
    when(() => repository.add(7, body: any(named: 'body')))
        .thenAnswer((_) async => const Left(Failure.server(message: 'تعذّر الحفظ')));

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.enterText(find.byType(TextField).first, 'ملاحظة لن تُحفظ');
    await tester.tap(find.text('إضافة ملاحظة'));
    await tester.pumpAndSettle();

    // Assert
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'ملاحظة لن تُحفظ',
    );

    await clearTheToast(tester);
  });
}
