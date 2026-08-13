part of 'customer_comments_cubit.dart';

/// Everything the notes screen can be.
///
/// **[loaded] is never left once it is reached.** Adding, editing and deleting all keep the
/// list on screen and mark the one row that is moving — a page that blanks to a spinner
/// because a sentence is being saved has taken away what the user was reading. [failure] is
/// only for the first read, when there is nothing to keep.
@freezed
sealed class CustomerCommentsState with _$CustomerCommentsState {
  const factory CustomerCommentsState.loading() = CustomerCommentsLoading;

  const factory CustomerCommentsState.loaded({
    required List<CustomerComment> comments,

    /// Ids of notes being rewritten or removed right now. A set rather than a single id
    /// because two rows can be worked on at once and each has to show its own state.
    @Default(<int>{}) Set<int> busy,

    /// True while a *new* note is on its way up. Separate from [busy], which is keyed by id —
    /// a note that does not exist yet has none.
    @Default(false) bool isAdding,
  }) = CustomerCommentsLoaded;

  const factory CustomerCommentsState.failure(Failure failure) = CustomerCommentsFailure;
}

extension CustomerCommentsStateX on CustomerCommentsState {
  /// The notes, whenever there are any — including while one of them is being saved.
  List<CustomerComment>? get comments => switch (this) {
    CustomerCommentsLoaded(:final comments) => comments,
    _ => null,
  };

  bool get isAdding => switch (this) {
    CustomerCommentsLoaded(:final isAdding) => isAdding,
    _ => false,
  };

  /// Whether this particular note is mid-request, which is what greys its row and disables its
  /// buttons without touching the rest of the list.
  bool isBusy(int commentId) => switch (this) {
    CustomerCommentsLoaded(:final busy) => busy.contains(commentId),
    _ => false,
  };
}
