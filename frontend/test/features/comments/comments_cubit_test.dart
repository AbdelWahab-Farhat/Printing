import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/comments/models/comment.dart';
import 'package:dayaa/features/comments/models/comment_subject.dart';
import 'package:dayaa/features/comments/models/comment_thread.dart';
import 'package:dayaa/features/comments/presentation/viewmodel/comments_cubit.dart';
import 'package:dayaa/features/comments/repositories/comment_repository.dart';
import 'package:dayaa/features/comments/usecases/add_comment.dart';
import 'package:dayaa/features/comments/usecases/delete_comment.dart';
import 'package:dayaa/features/comments/usecases/edit_comment.dart';
import 'package:dayaa/features/comments/usecases/get_comments.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// ملاحظات الموظفين على عميل: قراءتها، والأشياء الثلاثة التي تُفعل بها.
///
/// **القائمة لا تُرمى بعد وصولها إلى الشاشة أبداً.** الإضافة والتعديل والحذف كلّها تُبقيها
/// وتُعلّم الصفّ المتحرّك وحده — وصفحةٌ تبيضّ إلى دوّارةٍ لأن جملةً تُحفظ سلبت المستخدمَ ما كان
/// يقرؤه.
///
/// Arrange - Act - Assert في كل اختبار.
class _MockCommentRepository extends Mock implements CommentRepository {}

void main() {
  /// السجلّ الذي تتعلّق به كلّ ملاحظةٍ في هذا الملف — عميلٌ واحد، يُسمّى مرّة.
  const subject = CommentSubject.customer(7);

  // Mocktail تحتاج شيئاً تسلّمه لمطابِق `any()` حين لا يكون المُعامل قيمةً بدائية.
  setUpAll(() => registerFallbackValue(subject));

  late _MockCommentRepository repository;
  late CommentsCubit cubit;

  const mine = Comment(
    id: 1,
    commentableType: 'customer',
    commentableId: 7,
    body: 'يفضّل التسليم صباحاً',
    author: CommentAuthor(id: 3, name: 'محمد'),
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

  setUp(() {
    repository = _MockCommentRepository();
    cubit = CommentsCubit(
      subject: subject,
      getComments: GetComments(repository),
      addComment: AddComment(repository),
      editComment: EditComment(repository),
      deleteComment: DeleteComment(repository),
    );
  });

  tearDown(() => cubit.close());

  // ───────────────────────────── قراءتها ─────────────────────────────

  test('the notes arrive in the order the server sent them', () async {
    // Arrange — الأحدث أولاً قرارُ الخادم؛ والتطبيق لا يعيد ترتيبها.
    when(() => repository.comments(subject))
        .thenAnswer((_) async => const Right(CommentThread(comments: [theirs, mine])));

    // Act
    await cubit.load();

    // Assert
    expect(cubit.state, isA<CommentsLoaded>());
    expect(cubit.state.comments?.map((comment) => comment.id), [2, 1]);
  });

  test('a first read that fails has nothing to keep and says so', () async {
    // Arrange
    when(() => repository.comments(subject))
        .thenAnswer((_) async => const Left(Failure.server(message: 'لا يوجد اتصال')));

    // Act
    await cubit.load();

    // Assert
    expect(cubit.state, isA<CommentsFailure>());
  });

  test('a closed conversation arrives with the reason it closed', () async {
    // Arrange — «بعد الاعتماد لا يوجد مزيد». الخادم يقرّر هذا، والخيط الفارغ على تذكرةٍ اعتُمدت
    // لا صفَّ فيه يحمله، فيسافر بجوار الصفوف.
    when(() => repository.comments(subject)).thenAnswer(
      (_) async => const Right(
        CommentThread(
          comments: [mine],
          canComment: false,
          closedNote: 'اعتُمد التصميم وأُغلقت المحادثة',
        ),
      ),
    );

    // Act
    await cubit.load();

    // Assert
    expect(cubit.state.canComment, isFalse);
    expect(cubit.state.closedNote, 'اعتُمد التصميم وأُغلقت المحادثة');
  });

  test('an open conversation is the default, and says nothing about closing', () async {
    // Arrange
    when(() => repository.comments(subject))
        .thenAnswer((_) async => const Right(CommentThread(comments: [mine])));

    // Act
    await cubit.load();

    // Assert
    expect(cubit.state.canComment, isTrue);
    expect(cubit.state.closedNote, isNull);
  });

  // ───────────────────────────── إضافة واحدة ─────────────────────────────

  test('a new note lands at the top of the list without a reload', () async {
    // Arrange
    when(() => repository.comments(subject))
        .thenAnswer((_) async => const Right(CommentThread(comments: [mine])));
    await cubit.load();

    const added = Comment(
      id: 5,
      commentableType: 'customer',
      commentableId: 7,
      body: 'اتفقنا على خصم ٥٪ للطلبيات فوق ألف',
      author: CommentAuthor(id: 3, name: 'محمد'),
      canEdit: true,
      canDelete: true,
    );
    when(() => repository.add(subject, body: any(named: 'body')))
        .thenAnswer((_) async => const Right(added));

    // Act
    final failure = await cubit.add('اتفقنا على خصم ٥٪ للطلبيات فوق ألف');

    // Assert — الأحدث أولاً، والصفُّ الذي خزّنه الخادم فعلاً لا نسخةً محليّة.
    expect(failure, isNull);
    expect(cubit.state.comments?.map((comment) => comment.id), [5, 1]);
    // القراءة الافتتاحية ولا ثانية لها: الملاحظة المُنشأة *هي* الردّ، فإعادةُ قراءة القائمة
    // كلّها رحلةٌ لشيءٍ في اليد أصلاً.
    verify(() => repository.comments(subject)).called(1);
  });

  test('a refused note is handed back and the list is untouched', () async {
    // Arrange
    when(() => repository.comments(subject))
        .thenAnswer((_) async => const Right(CommentThread(comments: [mine])));
    await cubit.load();

    when(() => repository.add(subject, body: any(named: 'body')))
        .thenAnswer((_) async => const Left(Failure.server(message: 'تعذّر الحفظ')));

    // Act
    final failure = await cubit.add('ملاحظة لن تُحفظ');

    // Assert — تُعاد ولا تُوضع في الحالة: لم يبقَ على الشاشة شيءٌ تتعلّق به، والشاشةُ تعرض
    // شريحةً وتحتفظ بما كُتب.
    expect(failure, isNotNull);
    expect(cubit.state.comments?.map((comment) => comment.id), [1]);
  });

  test('an empty note is never sent', () async {
    // Arrange
    when(() => repository.comments(subject))
        .thenAnswer((_) async => const Right(CommentThread(comments: [mine])));
    await cubit.load();

    // Act
    final failure = await cubit.add('   ');

    // Assert — الخادم يرفضها أيضاً؛ وهذه توفّر الرحلة فقط.
    expect(failure, isNotNull);
    verifyNever(() => repository.add(any(), body: any(named: 'body')));
  });

  // ───────────────────────────── تعديل واحدة ─────────────────────────────

  test('an edited note replaces itself where it sits', () async {
    // Arrange
    when(() => repository.comments(subject))
        .thenAnswer((_) async => const Right(CommentThread(comments: [theirs, mine])));
    await cubit.load();

    const edited = Comment(
      id: 1,
      commentableType: 'customer',
      commentableId: 7,
      body: 'التصحيح: بعد الظهر وليس صباحاً',
      author: CommentAuthor(id: 3, name: 'محمد'),
      canEdit: true,
      canDelete: true,
    );
    when(() => repository.edit(subject, 1, body: any(named: 'body')))
        .thenAnswer((_) async => const Right(edited));

    // Act
    final failure = await cubit.edit(1, 'التصحيح: بعد الظهر وليس صباحاً');

    // Assert — في مكانها لا في الأعلى: التصحيح ليس شيئاً جديداً قيل.
    expect(failure, isNull);
    expect(cubit.state.comments?.map((comment) => comment.id), [2, 1]);
    expect(cubit.state.comments?.last.body, 'التصحيح: بعد الظهر وليس صباحاً');
  });

  test('the row being saved is marked, and unmarked when it answers', () async {
    // Arrange
    when(() => repository.comments(subject))
        .thenAnswer((_) async => const Right(CommentThread(comments: [mine])));
    await cubit.load();

    final gate = Completer<Either<Failure, Comment>>();
    when(() => repository.edit(subject, 1, body: any(named: 'body')))
        .thenAnswer((_) => gate.future);

    // Act
    final pending = cubit.edit(1, 'نص جديد');

    // Assert — الصفّ يقول إنه يعمل؛ والقائمة تبقى على الشاشة.
    expect(cubit.state.isBusy(1), isTrue);

    // Act
    gate.complete(const Right(mine));
    await pending;

    // Assert
    expect(cubit.state.isBusy(1), isFalse);
  });

  // ───────────────────────────── حذف واحدة ─────────────────────────────

  test('a removed note leaves the list', () async {
    // Arrange
    when(() => repository.comments(subject))
        .thenAnswer((_) async => const Right(CommentThread(comments: [theirs, mine])));
    await cubit.load();

    when(() => repository.remove(subject, 2))
        .thenAnswer((_) async => const Right('تم حذف الملاحظة'));

    // Act
    final failure = await cubit.remove(2);

    // Assert
    expect(failure, isNull);
    expect(cubit.state.comments?.map((comment) => comment.id), [1]);
  });

  test('a refused removal keeps the note exactly where it was', () async {
    // Arrange
    when(() => repository.comments(subject))
        .thenAnswer((_) async => const Right(CommentThread(comments: [theirs, mine])));
    await cubit.load();

    when(() => repository.remove(subject, 2)).thenAnswer(
      (_) async => const Left(Failure.server(message: 'هذه الملاحظة كتبها موظف آخر')),
    );

    // Act
    final failure = await cubit.remove(2);

    // Assert — الكلمة الأخيرة للخادم، وملاحظةٌ رفض حذفها يجب ألّا تختفي من شاشةٍ ستعرض القائمة
    // القديمة بعد التحديث.
    expect(failure, isNotNull);
    expect(cubit.state.comments?.map((comment) => comment.id), [2, 1]);
    expect(cubit.state.isBusy(2), isFalse);
  });
}
