import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/comments/models/comment.dart';
import 'package:dayaa/features/comments/models/comment_subject.dart';
import 'package:dayaa/features/comments/presentation/viewmodel/comments_cubit.dart';
import 'package:dayaa/features/comments/repositories/comment_repository.dart';
import 'package:dayaa/features/comments/usecases/add_comment.dart';
import 'package:dayaa/features/comments/usecases/delete_comment.dart';
import 'package:dayaa/features/comments/usecases/edit_comment.dart';
import 'package:dayaa/features/comments/usecases/get_comments.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// The notes staff leave on a customer: reading them, and the three things done to them.
///
/// **The list is never thrown away once it is on screen.** Adding, editing and deleting all
/// keep it and mark the one row that is moving — a page that blanks to a spinner because a
/// sentence is being saved has taken away what the user was reading.
///
/// Arrange - Act - Assert throughout.
class _MockCommentRepository extends Mock implements CommentRepository {}

void main() {
  /// The record every note in this file hangs off — one customer, named once.
  const subject = CommentSubject.customer(7);

  // Mocktail needs something to hand an `any()` matcher when the parameter is not a primitive.
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

  // ───────────────────────────── reading them ─────────────────────────────

  test('the notes arrive in the order the server sent them', () async {
    // Arrange — newest first is the server's decision; the app does not re-sort it.
    when(() => repository.comments(subject)).thenAnswer((_) async => const Right([theirs, mine]));

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

  // ───────────────────────────── adding one ─────────────────────────────

  test('a new note lands at the top of the list without a reload', () async {
    // Arrange
    when(() => repository.comments(subject)).thenAnswer((_) async => const Right([mine]));
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

    // Assert — newest first, and the row the server actually stored rather than a local copy.
    expect(failure, isNull);
    expect(cubit.state.comments?.map((comment) => comment.id), [5, 1]);
    // The opening read, and no second one: the created note *is* the response, so re-reading
    // the whole list would be a round trip for something already in hand.
    verify(() => repository.comments(subject)).called(1);
  });

  test('a refused note is handed back and the list is untouched', () async {
    // Arrange
    when(() => repository.comments(subject)).thenAnswer((_) async => const Right([mine]));
    await cubit.load();

    when(() => repository.add(subject, body: any(named: 'body')))
        .thenAnswer((_) async => const Left(Failure.server(message: 'تعذّر الحفظ')));

    // Act
    final failure = await cubit.add('ملاحظة لن تُحفظ');

    // Assert — returned rather than put on the state: there is nothing on screen for it to
    // attach to, and the screen shows a snackbar and keeps what was typed.
    expect(failure, isNotNull);
    expect(cubit.state.comments?.map((comment) => comment.id), [1]);
  });

  test('an empty note is never sent', () async {
    // Arrange
    when(() => repository.comments(subject)).thenAnswer((_) async => const Right([mine]));
    await cubit.load();

    // Act
    final failure = await cubit.add('   ');

    // Assert — the server refuses it too; this only spares the round trip.
    expect(failure, isNotNull);
    verifyNever(() => repository.add(any(), body: any(named: 'body')));
  });

  // ───────────────────────────── editing one ─────────────────────────────

  test('an edited note replaces itself where it sits', () async {
    // Arrange
    when(() => repository.comments(subject)).thenAnswer((_) async => const Right([theirs, mine]));
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

    // Assert — in place, not moved to the top: a correction is not a new thing said.
    expect(failure, isNull);
    expect(cubit.state.comments?.map((comment) => comment.id), [2, 1]);
    expect(cubit.state.comments?.last.body, 'التصحيح: بعد الظهر وليس صباحاً');
  });

  test('the row being saved is marked, and unmarked when it answers', () async {
    // Arrange
    when(() => repository.comments(subject)).thenAnswer((_) async => const Right([mine]));
    await cubit.load();

    final gate = Completer<Either<Failure, Comment>>();
    when(() => repository.edit(subject, 1, body: any(named: 'body'))).thenAnswer((_) => gate.future);

    // Act
    final pending = cubit.edit(1, 'نص جديد');

    // Assert — the row shows it is working; the list stays on screen.
    expect(cubit.state.isBusy(1), isTrue);

    // Act
    gate.complete(const Right(mine));
    await pending;

    // Assert
    expect(cubit.state.isBusy(1), isFalse);
  });

  // ───────────────────────────── removing one ─────────────────────────────

  test('a removed note leaves the list', () async {
    // Arrange
    when(() => repository.comments(subject)).thenAnswer((_) async => const Right([theirs, mine]));
    await cubit.load();

    when(() => repository.remove(subject, 2)).thenAnswer((_) async => const Right('تم حذف الملاحظة'));

    // Act
    final failure = await cubit.remove(2);

    // Assert
    expect(failure, isNull);
    expect(cubit.state.comments?.map((comment) => comment.id), [1]);
  });

  test('a refused removal keeps the note exactly where it was', () async {
    // Arrange
    when(() => repository.comments(subject)).thenAnswer((_) async => const Right([theirs, mine]));
    await cubit.load();

    when(() => repository.remove(subject, 2)).thenAnswer(
      (_) async => const Left(Failure.server(message: 'هذه الملاحظة كتبها موظف آخر')),
    );

    // Act
    final failure = await cubit.remove(2);

    // Assert — the server has the last word, and a note it refused to delete must not vanish
    // from a screen that will still be showing the old list after a refresh.
    expect(failure, isNotNull);
    expect(cubit.state.comments?.map((comment) => comment.id), [2, 1]);
    expect(cubit.state.isBusy(2), isFalse);
  });
}
