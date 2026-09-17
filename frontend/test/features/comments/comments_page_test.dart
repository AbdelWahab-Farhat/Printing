import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/app_snackbar.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/comments/models/comment.dart';
import 'package:dayaa/features/comments/models/comment_subject.dart';
import 'package:dayaa/features/comments/models/comment_thread.dart';
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
/// **The second rule is that it reads as a conversation.** The thread is parted by the day each
/// note was said, a run from one person says their name once, and what can be done to a note is
/// behind a long press — the three things every messaging app on these phones already does.
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

    when(() => repository.comments(subject))
        .thenAnswer((_) async => const Right(CommentThread(comments: [theirs, mine])));

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

  testWidgets('a bubble carries no buttons until it is held', (tester) async {
    // Arrange — a row of «تعديل» and «حذف» under every note is what stopped this reading as a
    // conversation: the words outnumbered the sentences.

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('تعديل'), findsNothing);
    expect(find.text('حذف'), findsNothing);
  });

  testWidgets('holding my own note offers copying it, rewriting it and taking it back', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.longPress(find.text('يفضّل التسليم صباحاً'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('نسخ'), findsOneWidget);
    expect(find.text('تعديل'), findsOneWidget);
    expect(find.text('حذف'), findsOneWidget);
  });

  testWidgets('holding a colleague\'s note offers only copying it', (tester) async {
    // Arrange — absent rather than disabled: a greyed bin invites a tap that can only ever
    // produce a 403. The server said `can_edit: false`, and the sheet says nothing more.
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.longPress(find.text('لا يردّ إلا على واتساب'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('نسخ'), findsOneWidget);
    expect(find.text('تعديل'), findsNothing);
    expect(find.text('حذف'), findsNothing);
  });

  testWidgets('opening the edit dialog and closing it throws nothing', (tester) async {
    // Arrange — the plain sequence a person actually performs: hold the note, tap «تعديل», the
    // dialog opens with its field autofocused, then back out.
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.longPress(find.text('يفضّل التسليم صباحاً'));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('تعديل'));
    await tester.pumpAndSettle();

    expect(find.text('تعديل الملاحظة'), findsOneWidget);

    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('تعديل الملاحظة'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the thread is parted by the day each note was said', (tester) async {
    // Arrange — a column of bubbles each repeating its own date is a column nobody reads. The
    // date is said once, between the days, the way every messaging app says it.
    final now = DateTime.now();
    final yesterday = Comment(
      id: 3,
      commentableType: 'customer',
      commentableId: 7,
      body: 'كلّمته أمس',
      author: const CommentAuthor(id: 9, name: 'علي'),
      createdAt: now.subtract(const Duration(days: 1)),
    );
    final today = Comment(
      id: 4,
      commentableType: 'customer',
      commentableId: 7,
      body: 'ردّ اليوم',
      author: const CommentAuthor(id: 9, name: 'علي'),
      createdAt: now,
    );

    when(() => repository.comments(subject))
        .thenAnswer((_) async => Right(CommentThread(comments: [today, yesterday])));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('أمس'), findsOneWidget);
    expect(find.text('اليوم'), findsOneWidget);
  });

  testWidgets('a run of notes from one person says their name once', (tester) async {
    // Arrange — two sentences said one after the other are one person talking, not two.
    final at = DateTime.now();
    final first = Comment(
      id: 5,
      commentableType: 'customer',
      commentableId: 7,
      body: 'مرّ على المحل',
      author: const CommentAuthor(id: 9, name: 'علي'),
      createdAt: at.subtract(const Duration(minutes: 5)),
    );
    final second = Comment(
      id: 6,
      commentableType: 'customer',
      commentableId: 7,
      body: 'وطلب نفس الطلبية',
      author: const CommentAuthor(id: 9, name: 'علي'),
      createdAt: at,
    );

    when(() => repository.comments(subject))
        .thenAnswer((_) async => Right(CommentThread(comments: [second, first])));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — both sentences, one name.
    expect(find.text('مرّ على المحل'), findsOneWidget);
    expect(find.text('وطلب نفس الطلبية'), findsOneWidget);
    expect(find.text('علي'), findsOneWidget);
  });

  testWidgets('an empty screen says what notes are for', (tester) async {
    // Arrange — an empty page that only reports emptiness leaves somebody wondering whether it
    // is broken.
    when(() => repository.comments(subject))
        .thenAnswer((_) async => const Right(CommentThread(comments: [])));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('لا توجد ملاحظات على هذا العميل'), findsOneWidget);
    expect(find.textContaining('موعد التسليم الذي يفضّله'), findsOneWidget);
  });

  // The list is drawn reversed — oldest at the top, newest at the bottom, the way a chat reads —
  // so a new note goes to the front of the *data* and renders at the bottom of the *screen*.
  // Named for what the reader sees rather than for the index it lands at.
  testWidgets('writing a note puts it at the end of the thread and empties the box', (
    tester,
  ) async {
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
    await tester.pump();
    await tester.tap(find.byTooltip('إرسال'));
    await tester.pumpAndSettle();

    // Assert — the note is on screen, and the box is ready for the next one.
    expect(find.text('اتفقنا على خصم ٥٪'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField).first).controller?.text, isEmpty);
  });

  testWidgets('an empty box has nothing to send', (tester) async {
    // Arrange — the send key is lit by there being a sentence to send, which is what spares
    // somebody a refusal they could have been told about before tapping.
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byTooltip('إرسال'));
    await tester.pumpAndSettle();

    // Assert — nothing left the phone.
    verifyNever(() => repository.add(any(), body: any(named: 'body')));
  });

  testWidgets('a refused note keeps what was typed', (tester) async {
    // Arrange — a refusal that also empties the field costs somebody the sentence they wrote.
    when(() => repository.add(subject, body: any(named: 'body')))
        .thenAnswer((_) async => const Left(Failure.server(message: 'تعذّر الحفظ')));

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.enterText(find.byType(TextField).first, 'ملاحظة لن تُحفظ');
    await tester.pump();
    await tester.tap(find.byTooltip('إرسال'));
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
        .thenAnswer((_) async => const Right(CommentThread(comments: [aboutTheVendor])));

    // Act
    await tester.pumpWidget(host(about: vendor, ownerName: 'مصنع الصفا'));
    await tester.pumpAndSettle();

    // Assert — the supplier's note is on screen, and the customer's list was never asked for.
    expect(find.text('لا يسلّم قبل الظهر'), findsOneWidget);
    expect(find.text('مصنع الصفا'), findsOneWidget);
    verifyNever(() => repository.comments(subject));
  });

  testWidgets('and a design ticket, where the notes are the point of the record', (tester) async {
    // Arrange — the third subject, and the one whose conversation is not an aside: «الرد داخل
    // التذكرة» is most of what makes a ticket a ticket rather than a form.
    const ticket = CommentSubject.designTicket(7);
    const fromTheDesigner = Comment(
      id: 11,
      commentableType: 'design_ticket',
      commentableId: 7,
      body: 'وصلني، أبدأ اليوم',
      author: CommentAuthor(id: 5, name: 'سالم'),
    );

    when(() => repository.comments(ticket))
        .thenAnswer((_) async => const Right(CommentThread(comments: [fromTheDesigner])));

    // Act
    await tester.pumpWidget(host(about: ticket, ownerName: 'تصميم كيس شحن — أسود'));
    await tester.pumpAndSettle();

    // Assert — one screen, three kinds of record, and neither of the other two was asked for.
    expect(find.text('وصلني، أبدأ اليوم'), findsOneWidget);
    expect(find.text('تصميم كيس شحن — أسود'), findsOneWidget);
    verifyNever(() => repository.comments(subject));
  });

  testWidgets('a closed conversation has no box, and says why', (tester) async {
    // Arrange — a ticket whose design was approved. Nothing more is written on it, by the
    // designer or by the employee who asked, so the box is gone rather than greyed: a field
    // somebody can type into and never send is worse than no field.
    const ticket = CommentSubject.designTicket(7);
    const settled = Comment(
      id: 11,
      commentableType: 'design_ticket',
      commentableId: 7,
      body: 'اعتمدنا النسخة الثالثة',
      author: CommentAuthor(id: 1, name: 'عبدالوهاب'),
    );

    when(() => repository.comments(ticket)).thenAnswer(
      (_) async => const Right(
        CommentThread(
          comments: [settled],
          canComment: false,
          closedNote: 'اعتُمد التصميم وأُغلقت المحادثة',
        ),
      ),
    );

    // Act
    await tester.pumpWidget(host(about: ticket, ownerName: 'تصميم كيس شحن — أسود'));
    await tester.pumpAndSettle();

    // Assert — the conversation is still readable; only writing has ended.
    expect(find.text('اعتمدنا النسخة الثالثة'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byTooltip('إرسال'), findsNothing);
    expect(find.text('اعتُمد التصميم وأُغلقت المحادثة'), findsOneWidget);
  });

  testWidgets('an empty closed conversation still says why it is closed', (tester) async {
    // Arrange — the case that made this a fact about the thread rather than about a note: a
    // ticket signed off before anybody wrote a word has no row to hang the reason on.
    const ticket = CommentSubject.designTicket(7);
    when(() => repository.comments(ticket)).thenAnswer(
      (_) async => const Right(
        CommentThread(
          comments: [],
          canComment: false,
          closedNote: 'أُلغيت التذكرة وأُغلقت المحادثة',
        ),
      ),
    );

    // Act
    await tester.pumpWidget(host(about: ticket, ownerName: 'تصميم كيس شحن — أسود'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('أُلغيت التذكرة وأُغلقت المحادثة'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('a Latin sentence is drawn the way it was typed', (tester) async {
    // Arrange — the app is right-to-left and a message box is the one place that stops being
    // true: «ok» rendered right-to-left puts its full stop at the wrong end.
    const inEnglish = Comment(
      id: 12,
      commentableType: 'customer',
      commentableId: 7,
      body: 'ok, sending the PDF now',
      author: CommentAuthor(id: 9, name: 'علي'),
    );
    when(() => repository.comments(subject))
        .thenAnswer((_) async => const Right(CommentThread(comments: [inEnglish, mine])));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — each bubble reads the way its own sentence does, in the same thread.
    expect(
      tester.widget<Text>(find.text('ok, sending the PDF now')).textDirection,
      TextDirection.ltr,
    );
    expect(
      tester.widget<Text>(find.text('يفضّل التسليم صباحاً')).textDirection,
      TextDirection.rtl,
    );
  });

  testWidgets('the box turns with the language being typed into it', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final box = find.byType(TextField).first;

    // Act & Assert — an empty box has no opinion and keeps the app's own direction.
    expect(tester.widget<TextField>(box).textDirection, isNull);

    await tester.enterText(box, 'ok');
    await tester.pump();
    expect(tester.widget<TextField>(box).textDirection, TextDirection.ltr);

    await tester.enterText(box, 'تمام، نبعثه الآن');
    await tester.pump();
    expect(tester.widget<TextField>(box).textDirection, TextDirection.rtl);
  });

  testWidgets('a ticket asks for a reply, not for a note about a customer', (tester) async {
    // Arrange — the same screen served three records while its box asked about «هذا العميل» on
    // all three. What is being written differs, and the box is where somebody reads it.
    const ticket = CommentSubject.designTicket(7);
    when(() => repository.comments(ticket))
        .thenAnswer((_) async => const Right(CommentThread(comments: [])));

    // Act
    await tester.pumpWidget(host(about: ticket, ownerName: 'تصميم كيس شحن — أسود'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('اكتب رسالة في هذه التذكرة…'), findsOneWidget);
    expect(find.textContaining('هذا العميل'), findsNothing);
  });
}
