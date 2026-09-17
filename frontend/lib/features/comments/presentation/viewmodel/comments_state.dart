part of 'comments_cubit.dart';

/// Everything the notes screen can be.
///
/// **[loaded] is never left once it is reached.** Adding, editing and deleting all keep the
/// list on screen and mark the one row that is moving — a page that blanks to a spinner
/// because a sentence is being saved has taken away what the user was reading. [failure] is
/// only for the first read, when there is nothing to keep.
@freezed
sealed class CommentsState with _$CommentsState {
  const factory CommentsState.loading() = CommentsLoading;

  const factory CommentsState.loaded({
    required List<Comment> comments,

    /// Whether anything more may be said here — the server's answer, carried on the list.
    ///
    /// **A fact about the thread, not about any note.** A design ticket's conversation ends with
    /// the ticket, and the screen that has to know it is the box: an empty closed thread has no
    /// row to read it off. True for a customer and a supplier, always.
    @Default(true) bool canComment,

    /// Why it closed, in the record's own words. Null while it is open.
    String? closedNote,

    /// Ids of notes being rewritten or removed right now. A set rather than a single id
    /// because two rows can be worked on at once and each has to show its own state.
    @Default(<int>{}) Set<int> busy,

    /// True while a *new* note is on its way up. Separate from [busy], which is keyed by id —
    /// a note that does not exist yet has none.
    @Default(false) bool isAdding,
  }) = CommentsLoaded;

  const factory CommentsState.failure(Failure failure) = CommentsFailure;
}

extension CommentsStateX on CommentsState {
  /// The notes, whenever there are any — including while one of them is being saved.
  List<Comment>? get comments => switch (this) {
    CommentsLoaded(:final comments) => comments,
    _ => null,
  };

  bool get isAdding => switch (this) {
    CommentsLoaded(:final isAdding) => isAdding,
    _ => false,
  };

  /// Whether the box is drawn. Open until the server says otherwise — including while the first
  /// read is still out, so nothing flickers shut and open again.
  bool get canComment => switch (this) {
    CommentsLoaded(:final canComment) => canComment,
    _ => true,
  };

  String? get closedNote => switch (this) {
    CommentsLoaded(:final closedNote) => closedNote,
    _ => null,
  };

  /// Whether this particular note is mid-request, which is what greys its row and disables its
  /// buttons without touching the rest of the list.
  bool isBusy(int commentId) => switch (this) {
    CommentsLoaded(:final busy) => busy.contains(commentId),
    _ => false,
  };
}
