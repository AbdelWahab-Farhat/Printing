import 'package:dayaa/features/comments/models/comment.dart';

/// Every note on one record, **and whether anything more may be said**.
///
/// The second half is why this exists rather than a bare `List<Comment>`. A design ticket ends —
/// «بعد الاعتماد لا يوجد مزيد» — and the thing that has to know it is the box under the list,
/// which is drawn whether or not there is a single note above it. An empty closed conversation
/// has no row to carry the fact, so it travels beside the rows: the server sends it as `meta`,
/// the same place a page's numbers come from.
///
/// **The server decides, as it does for `canEdit`.** A customer's conversation never closes and a
/// ticket's closes with the ticket, and neither rule is written twice — the app draws what it is
/// told and the endpoints refuse regardless.
class CommentThread {
  const CommentThread({
    required this.comments,
    this.canComment = true,
    this.closedNote,
  });

  /// From the envelope's two halves: `data` is the list, `meta` is what is true of the thread.
  ///
  /// **Open unless the server says otherwise.** An older build of the API sends no `meta` at
  /// all, and a box that refuses to open because a key was missing is worse than a box that
  /// opens and meets a refusal it can show.
  factory CommentThread.fromEnvelope(dynamic data, Map<String, dynamic> meta) {
    return CommentThread(
      comments: (data! as List)
          .whereType<Map<String, dynamic>>()
          .map(Comment.fromJson)
          .toList(growable: false),
      canComment: meta['can_comment'] as bool? ?? true,
      closedNote: meta['closed_note'] as String?,
    );
  }

  /// Newest first, exactly as the server sent them.
  final List<Comment> comments;

  /// Whether the box is open. False freezes the whole thread — nothing added, and nothing
  /// rewritten or removed either, which arrives per row as `canEdit` and `canDelete` false.
  final bool canComment;

  /// Why it closed, in the record's own words — «اعتُمد التصميم وأُغلقت المحادثة». Null while it
  /// is open, and never invented here: a reason the app wrote itself would be a guess printed as
  /// a fact.
  final String? closedNote;
}
