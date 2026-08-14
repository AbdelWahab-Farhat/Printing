import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/app_snackbar.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/comments/models/comment.dart';
import 'package:dayaa/features/comments/models/comment_subject.dart';
import 'package:dayaa/features/comments/presentation/viewmodel/comments_cubit.dart';
import 'package:dayaa/features/comments/presentation/views/comments_page.dart';
import 'package:dayaa/features/comments/repositories/comment_repository.dart';
import 'package:dayaa/features/comments/usecases/add_comment.dart';
import 'package:dayaa/features/comments/usecases/delete_comment.dart';
import 'package:dayaa/features/comments/usecases/edit_comment.dart';
import 'package:dayaa/features/comments/usecases/get_comments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
class _MockCommentRepository extends Mock implements CommentRepository {}

void main() {
  /// The record every note in this file hangs off — one customer, named once.
  const subject = CommentSubject.customer(7);

  // Mocktail needs something to hand an `any()` matcher when the parameter is not a primitive.
  setUpAll(() => registerFallbackValue(subject));

  late _MockCommentRepository repository;
  late Session session;

  const mine = Comment(
    id: 1,
    commentableType: 'customer',
    commentableId: 7,
    body: 'يفضّل التسليم صباحاً',
    author: CommentAuthor(id: 1, name: 'عبدالوهاب'),
    canEdit: true,
    canDelete: true,
  );

  const theirs = Comment(
    id: 2,
    commentableType: 'customer',
    commentableId: 7,
    body: 'لا يردّ إلا على واتساب',
    author: CommentAuthor(id: 9, name: 'علي'),
  );

  AuthUser userWith(List<String> permissions) =>
      AuthUser(id: 1, name: 'عبدالوهاب', phone: '0911234567', permissions: permissions);

  setUp(() async {
    await Injector.reset();

    repository = _MockCommentRepository();
    session = Session()..adopt(userWith(['customers.view']));

    when(() => repository.comments(subject)).thenAnswer((_) async => const Right([theirs, mine]));

    sl
      ..registerSingleton<Session>(session)
      ..registerFactoryParam<CommentsCubit, CommentSubject, void>(
        (subject, _) => CommentsCubit(
          subject: subject,
          getComments: GetComments(repository),
          addComment: AddComment(repository),
          editComment: EditComment(repository),
          deleteComment: DeleteComment(repository),
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

  Widget host({
    CommentSubject about = subject,
    String ownerName = 'مطبعة النور',
  }) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: CommentsPage(subject: about, ownerName: ownerName),
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
    when(() => repository.comments(subject)).thenAnswer((_) async => const Right([]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('لا توجد ملاحظات على هذا العميل'), findsOneWidget);
    expect(find.textContaining('موعد التسليم الذي يفضّله'), findsOneWidget);
  });

  testWidgets('writing a note puts it at the top and empties the box', (tester) async {
    // Arrange
    const added = Comment(
      id: 5,
      commentableType: 'customer',
      commentableId: 7,
      body: 'اتفقنا على خصم ٥٪',
      author: CommentAuthor(id: 1, name: 'عبدالوهاب'),
      canEdit: true,
      canDelete: true,
    );
    when(() => repository.add(subject, body: any(named: 'body')))
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
    when(() => repository.add(subject, body: any(named: 'body')))
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

  testWidgets('the same screen serves a supplier, reading a supplier\'s notes', (tester) async {
    // Arrange — the point of the whole generalisation: one screen, one cubit, one repository,
    // and the record it is about arrives as a subject.
    const vendor = CommentSubject.vendor(4);
    const aboutTheVendor = Comment(
      id: 8,
      commentableType: 'vendor',
      commentableId: 4,
      body: 'لا يسلّم قبل الظهر',
      author: CommentAuthor(id: 3, name: 'محمد'),
    );

    when(() => repository.comments(vendor))
        .thenAnswer((_) async => const Right([aboutTheVendor]));

    // Act
    await tester.pumpWidget(host(about: vendor, ownerName: 'مصنع الصفا'));
    await tester.pumpAndSettle();

    // Assert — the supplier's note is on screen, and the customer's list was never asked for.
    expect(find.text('لا يسلّم قبل الظهر'), findsOneWidget);
    expect(find.text('مصنع الصفا'), findsOneWidget);
    verifyNever(() => repository.comments(subject));
  });
}
