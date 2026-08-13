import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_comment.freezed.dart';
part 'customer_comment.g.dart';

/// One thing a member of staff wrote about a customer.
///
/// The things that are true of the person and have no field in the form — «يفضّل التسليم
/// صباحاً», «لا يردّ إلا على واتساب» — which are said out loud today and leave with whoever
/// heard them. See `CustomerCommentResource` for the wire shape.
///
/// **[canEdit] and [canDelete] are the server's answers, not this app's guesses.** The rule is
/// «its author, or a moderator», and it is computed per reader on the backend and sent with
/// every row. Recomputing it here would be a second copy of an authorization rule that drifts
/// the day the first one changes — and the endpoints refuse the request regardless, so these
/// two decide what is *drawn*, never what is *allowed*.
@freezed
abstract class CustomerComment with _$CustomerComment {
  const factory CustomerComment({
    required int id,
    @JsonKey(name: 'customer_id') required int customerId,
    required String body,
    required CommentAuthor author,
    @JsonKey(name: 'created_at') DateTime? createdAt,

    /// When it was last rewritten. Null means «as it was written» — a note that changed says
    /// so, because a sentence that quietly becomes a different sentence is worse than none.
    @JsonKey(name: 'edited_at') DateTime? editedAt,

    @JsonKey(name: 'can_edit') @Default(false) bool canEdit,
    @JsonKey(name: 'can_delete') @Default(false) bool canDelete,
  }) = _CustomerComment;

  const CustomerComment._();

  factory CustomerComment.fromJson(Map<String, dynamic> json) =>
      _$CustomerCommentFromJson(json);

  bool get wasEdited => editedAt != null;
}

/// Who wrote it.
///
/// The name travels with the note rather than being looked up by id: every screen showing a
/// note shows the name, and an app that fetches one per row is an app making N requests to
/// draw a list. Nullable because a note is attributed to a user row, and this app has no screen
/// that can promise the name was loaded.
@freezed
abstract class CommentAuthor with _$CommentAuthor {
  const factory CommentAuthor({required int id, String? name}) = _CommentAuthor;

  const CommentAuthor._();

  factory CommentAuthor.fromJson(Map<String, dynamic> json) => _$CommentAuthorFromJson(json);

  /// What to print above the note when the name did not come through — «موظف» rather than an
  /// empty line, which reads as a note nobody wrote.
  String get displayName => (name?.trim().isNotEmpty ?? false) ? name!.trim() : 'موظف';
}
