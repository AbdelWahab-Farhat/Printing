import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/comments/models/comment.dart';
import 'package:dayaa/features/comments/models/comment_subject.dart';
import 'package:dayaa/features/comments/usecases/add_comment.dart';
import 'package:dayaa/features/comments/usecases/delete_comment.dart';
import 'package:dayaa/features/comments/usecases/edit_comment.dart';
import 'package:dayaa/features/comments/usecases/get_comments.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'comments_cubit.freezed.dart';
part 'comments_state.dart';

/// The notes staff leave on one record — a customer, a supplier — and the three things done to
/// them.
///
/// **Every write answers with a `Failure?` rather than putting the failure on the state.** The
/// same reasoning `CustomerDesignsCubit` gives for renaming and deleting: there is nothing left
/// on screen for a refusal to attach to, and a field holding it would either linger into the
/// next rebuild or be cleared by a second emit nobody can see. The screen awaits the call and
/// shows a snackbar, keeping whatever was typed.
///
/// **Nothing here re-reads the list after a write.** Each endpoint answers with the row it
/// stored, so the list is patched from the response — a second round trip to fetch something
/// already in hand is a spinner the user pays for twice.
class CommentsCubit extends Cubit<CommentsState> {
  CommentsCubit({
    required CommentSubject subject,
    required GetComments getComments,
    required AddComment addComment,
    required EditComment editComment,
    required DeleteComment deleteComment,
  }) : _subject = subject,
       _getComments = getComments,
       _addComment = addComment,
       _editComment = editComment,
       _deleteComment = deleteComment,
       super(const CommentsState.loading());

  final CommentSubject _subject;
  final GetComments _getComments;
  final AddComment _addComment;
  final EditComment _editComment;
  final DeleteComment _deleteComment;

  Future<void> load() async {
    // Only from nothing. A pull-to-refresh must not blank a list somebody is reading.
    if (state is! CommentsLoaded) emit(const CommentsState.loading());

    final result = await _getComments(_subject);
    if (isClosed) return;

    emit(
      result.fold(CommentsState.failure, (comments) {
        final current = state;

        return current is CommentsLoaded
            // `busy` is deliberately kept: a refresh that lands while a row is saving must not
            // un-grey it — the request it is waiting on is still out there.
            ? current.copyWith(comments: comments)
            : CommentsState.loaded(comments: comments);
      }),
    );
  }

  /// Leaves a note. Null when it landed; the failure when it did not.
  ///
  /// The order the server sends is newest-first, so a new note goes to the front — that is the
  /// same list the next `load()` will produce, which is what stops the screen re-ordering
  /// itself under the reader a second later.
  Future<Failure?> add(String body) async {
    final current = state;
    if (current is! CommentsLoaded) return null;

    final text = body.trim();
    if (text.isEmpty) {
      // The server refuses this too — a line of spaces satisfies `required` while telling the
      // next reader nothing — so this only spares the round trip, and is shaped as the 422 the
      // API would have sent so the screen has one kind of refusal to render.
      return const Failure.server(message: 'اكتب الملاحظة قبل الحفظ', statusCode: 422);
    }

    emit(current.copyWith(isAdding: true));

    final result = await _addComment(_subject, body: text);
    if (isClosed) return null;

    return result.fold(
      (failure) {
        _patch((loaded) => loaded.copyWith(isAdding: false));

        return failure;
      },
      (comment) {
        _patch(
          (loaded) => loaded.copyWith(
            comments: [comment, ...loaded.comments],
            isAdding: false,
          ),
        );

        return null;
      },
    );
  }

  /// Rewrites one, in place.
  ///
  /// **In place, not moved to the top.** A correction is not a new thing said, and a note that
  /// jumped up the list every time a typo was fixed would keep re-ordering a page people read
  /// as a conversation.
  Future<Failure?> edit(int commentId, String body) async {
    final current = state;
    if (current is! CommentsLoaded) return null;

    final text = body.trim();
    if (text.isEmpty) {
      // 422 with the server's own wording, so the screen shows a refusal that reads exactly
      // like the one the API would have sent — see UploadCustomerDesign's pre-flight check.
      return const Failure.server(message: 'اكتب الملاحظة قبل الحفظ', statusCode: 422);
    }

    emit(current.copyWith(busy: {...current.busy, commentId}));

    final result = await _editComment(_subject, commentId, body: text);
    if (isClosed) return null;

    return result.fold(
      (failure) {
        _release(commentId);

        return failure;
      },
      (updated) {
        _patch(
          (loaded) => loaded.copyWith(
            comments: [
              for (final comment in loaded.comments)
                if (comment.id == commentId) updated else comment,
            ],
            busy: {...loaded.busy}..remove(commentId),
          ),
        );

        return null;
      },
    );
  }

  /// Takes one off the record.
  ///
  /// The row leaves the list only once the server has agreed. Removing it first would read
  /// better for a second and then be contradicted by the next refresh — and this endpoint
  /// refuses a colleague's note, which is precisely the case that would flicker.
  Future<Failure?> remove(int commentId) async {
    final current = state;
    if (current is! CommentsLoaded) return null;

    emit(current.copyWith(busy: {...current.busy, commentId}));

    final result = await _deleteComment(_subject, commentId);
    if (isClosed) return null;

    return result.fold(
      (failure) {
        _release(commentId);

        return failure;
      },
      (_) {
        _patch(
          (loaded) => loaded.copyWith(
            comments: [
              for (final comment in loaded.comments)
                if (comment.id != commentId) comment,
            ],
            busy: {...loaded.busy}..remove(commentId),
          ),
        );

        return null;
      },
    );
  }

  /// Applies a change to the loaded state, and does nothing at all if the screen has moved on.
  ///
  /// Read fresh rather than closing over the state captured before the request: a refresh may
  /// have landed while it was in flight, and writing the old list back would undo it.
  void _patch(CommentsLoaded Function(CommentsLoaded loaded) change) {
    final current = state;
    if (current is! CommentsLoaded) return;

    emit(change(current));
  }

  void _release(int commentId) {
    _patch((loaded) => loaded.copyWith(busy: {...loaded.busy}..remove(commentId)));
  }
}
