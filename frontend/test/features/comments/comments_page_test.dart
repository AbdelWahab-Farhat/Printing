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

/// الشاشة التي تحمل ما كتبه الموظفون عن سجلّ.
///
/// **القاعدة المختبَرة أنّ هذه الشاشة لا تحمل قاعدة صلاحيات.** «صاحبه أو مشرف» تُحسب على الخادم
/// لكل قارئ وتصل كـ`can_edit` / `can_delete` على كل ملاحظة؛ والصفّ يرسم أزراره منهما ولا يقارن
/// معرّفات مستخدمين خاصةً به. ونسخةٌ ثانية من قاعدة صلاحيات نسخةٌ تنحرف.
///
/// **والقاعدة الثانية أنها تُقرأ محادثة.** الخيط يُفصل باليوم الذي قيلت فيه كلّ رسالة، ورسائل
/// الشخص الواحد المتتابعة تقول اسمه مرّة، وما يُفعل بالرسالة خلف ضغطةٍ مطوّلة — وهي الأشياء
/// الثلاثة التي يفعلها أصلاً كلّ تطبيق محادثة في هذه الهواتف.
///
/// Cubit حقيقي، وحالات استعمال حقيقية، ومستودعٌ مزيّف — فتُمارَس الفحوص القَبْلية وترقيعُ القائمة
/// كلّها.
///
/// Arrange - Act - Assert في كل اختبار.
class _MockCommentRepository extends Mock implements CommentRepository {}

void main() {
  /// السجلّ الذي تتعلّق به كلّ ملاحظةٍ في هذا الملف — عميلٌ واحد، يُسمّى مرّة.
  const subject = CommentSubject.customer(7);

  // Mocktail تحتاج شيئاً تسلّمه لمطابِق `any()` حين لا يكون المُعامل قيمةً بدائية.
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

  // دفاتر الشريحة على مستوى المكتبة، فتعيش أطولَ من الشجرة التي أطلقتها — وحين يجري `tearDown`
  // يكون الـNavigator المالك لمؤقّتها قيد الفكّ أصلاً. فالاختبار الذي يستدرج رفضاً يمسحها ما دامت
  // هناك شجرةٌ تُمسح منها.
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

    // Assert — الاسم يسافر مع الملاحظة، لأن ملاحظةً لا يمكن سؤال أحدٍ عنها إشاعة.
    expect(find.text('مطبعة النور'), findsOneWidget);
    expect(find.text('يفضّل التسليم صباحاً'), findsOneWidget);
    expect(find.text('علي'), findsOneWidget);
  });

  testWidgets('a bubble carries no buttons until it is held', (tester) async {
    // Arrange — صفُّ «تعديل» و«حذف» تحت كل ملاحظة هو ما منع هذه من أن تُقرأ محادثة: الكلماتُ
    // فاقت الجُمل.

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
    // Arrange — غائبةٌ لا معطَّلة: سلّةٌ رماديّة تدعو إلى ضغطةٍ لا تُنتج إلا 403. الخادم قال
    // `can_edit: false`، والورقة لا تقول أكثر.
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
    // Arrange — التسلسل الذي يفعله الشخص فعلاً: يضغط الرسالة مطوّلاً، ثم «تعديل»، فتُفتح
    // الحواريّة وحقلُها مركَّزٌ عليه، ثم يخرج.
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
    // Arrange — عمودٌ من الفقاعات تكرّر كلٌّ منها تاريخها عمودٌ لا يقرؤه أحد. التاريخ يُقال
    // مرّة، بين الأيام، كما يقوله كلّ تطبيق محادثة.
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
    // Arrange — جملتان قيلتا تباعاً هما شخصٌ واحد يتكلّم، لا اثنان.
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

    // Assert — الجملتان كلتاهما، واسمٌ واحد.
    expect(find.text('مرّ على المحل'), findsOneWidget);
    expect(find.text('وطلب نفس الطلبية'), findsOneWidget);
    expect(find.text('علي'), findsOneWidget);
  });

  testWidgets('an empty screen says what notes are for', (tester) async {
    // Arrange — صفحةٌ فارغة لا تقول إلا إنها فارغة تترك صاحبها يتساءل هل هي معطّلة.
    when(() => repository.comments(subject))
        .thenAnswer((_) async => const Right(CommentThread(comments: [])));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('لا توجد ملاحظات على هذا العميل'), findsOneWidget);
    expect(find.textContaining('موعد التسليم الذي يفضّله'), findsOneWidget);
  });

  // القائمة تُرسم معكوسة — الأقدم فوق والأحدث تحت، كما تُقرأ المحادثة — فالملاحظة الجديدة تذهب
  // إلى مقدّمة *البيانات* وتُرسم في أسفل *الشاشة*. والاسم لِما يراه القارئ لا للموضع الذي تحطّ
  // فيه.
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

    // Assert — الملاحظة على الشاشة، والصندوق جاهزٌ للتالية.
    expect(find.text('اتفقنا على خصم ٥٪'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField).first).controller?.text, isEmpty);
  });

  testWidgets('an empty box has nothing to send', (tester) async {
    // Arrange — مفتاح الإرسال يُضيئه وجودُ جملةٍ تُرسل، وهذا ما يوفّر على صاحبه رفضاً كان يمكن
    // أن يُقال له قبل الضغط.
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byTooltip('إرسال'));
    await tester.pumpAndSettle();

    // Assert — لم يغادر الهاتفَ شيء.
    verifyNever(() => repository.add(any(), body: any(named: 'body')));
  });

  testWidgets('a refused note keeps what was typed', (tester) async {
    // Arrange — رفضٌ يُفرغ الحقل معه يكلّف صاحبه الجملة التي كتبها.
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
    // Arrange — مقصود التعميم كلّه: شاشةٌ واحدة، وcubit واحد، ومستودعٌ واحد، والسجلُّ الذي هي
    // عنه يصل موضوعاً.
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

    // Assert — ملاحظة المورّد على الشاشة، وقائمةُ العميل لم تُطلب أصلاً.
    expect(find.text('لا يسلّم قبل الظهر'), findsOneWidget);
    expect(find.text('مصنع الصفا'), findsOneWidget);
    verifyNever(() => repository.comments(subject));
  });

  testWidgets('and a design ticket, where the notes are the point of the record', (tester) async {
    // Arrange — الموضوع الثالث، وهو الوحيد الذي محادثتُه ليست هامشاً: «الرد داخل التذكرة» هو
    // معظمُ ما يجعل التذكرة تذكرةً لا نموذجاً.
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

    // Assert — شاشةٌ واحدة، وثلاثةُ أنواعٍ من السجلات، ولم يُطلب أيٌّ من الآخرَين.
    expect(find.text('وصلني، أبدأ اليوم'), findsOneWidget);
    expect(find.text('تصميم كيس شحن — أسود'), findsOneWidget);
    verifyNever(() => repository.comments(subject));
  });

  testWidgets('a closed conversation has no box, and says why', (tester) async {
    // Arrange — تذكرةٌ اعتُمد تصميمها. لا يُكتب عليها مزيد، لا من المصمّم ولا من الموظف الذي
    // طلب، فالصندوق يختفي ولا يُعطَّل: حقلٌ يُكتب فيه ولا يُرسل أسوأ من لا حقل.
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

    // Assert — المحادثة ما تزال تُقرأ؛ والذي انتهى هو الكتابة وحدها.
    expect(find.text('اعتمدنا النسخة الثالثة'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byTooltip('إرسال'), findsNothing);
    expect(find.text('اعتُمد التصميم وأُغلقت المحادثة'), findsOneWidget);
  });

  testWidgets('an empty closed conversation still says why it is closed', (tester) async {
    // Arrange — الحالة التي جعلت هذه حقيقةً عن الخيط لا عن ملاحظة: تذكرةٌ اعتُمدت قبل أن يكتب
    // أحدٌ كلمة لا صفَّ فيها يُعلَّق به السبب.
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
    // Arrange — التطبيق من اليمين إلى اليسار، وصندوق الرسائل هو المكان الوحيد الذي يبطل فيه
    // ذلك: «ok» مرسومةً من اليمين إلى اليسار تضع نقطتها في الطرف الخطأ.
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

    // Assert — كلّ فقاعةٍ تُقرأ باتجاه جملتها، في الخيط نفسه.
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

    // Act & Assert — الصندوق الفارغ لا رأي له فيبقى على اتجاه التطبيق.
    expect(tester.widget<TextField>(box).textDirection, isNull);

    await tester.enterText(box, 'ok');
    await tester.pump();
    expect(tester.widget<TextField>(box).textDirection, TextDirection.ltr);

    await tester.enterText(box, 'تمام، نبعثه الآن');
    await tester.pump();
    expect(tester.widget<TextField>(box).textDirection, TextDirection.rtl);
  });

  testWidgets('a ticket asks for a reply, not for a note about a customer', (tester) async {
    // Arrange — الشاشة نفسها خدمت ثلاثة سجلات وصندوقُها يسأل عن «هذا العميل» في الثلاثة. والذي
    // يُكتب يختلف، والصندوق هو المكان الذي يقرأ فيه صاحبه ذلك.
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
