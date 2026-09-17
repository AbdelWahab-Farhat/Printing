import 'package:flutter/foundation.dart';

/// What a note is about — which record, and which kind of record it is.
///
/// **The one thing every call in this feature needs, and the only thing that differs between a
/// customer's notes and a supplier's.** The API nests notes under their owner
/// (`/customers/7/comments`, `/vendors/4/comments`), so a repository handed a bare id would have
/// no way to know which door to knock on; handed this, it has exactly one.
///
/// [kind] is the same short name the server writes into `commentable_type`, which is what lets a
/// note read off the wire be matched to the screen showing it.
@immutable
class CommentSubject {
  const CommentSubject.customer(this.id) : kind = CommentSubjectKind.customer;

  const CommentSubject.vendor(this.id) : kind = CommentSubjectKind.vendor;

  const CommentSubject.designTicket(this.id) : kind = CommentSubjectKind.designTicket;

  final CommentSubjectKind kind;
  final int id;

  @override
  bool operator ==(Object other) =>
      other is CommentSubject && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}

/// The records that accept notes today.
///
/// Three: the customer, the supplier, and a design ticket. An order or a purchase order is a case
/// here and a route on the server — and neither is added before a screen wants it, which is the
/// same rule that kept this feature customer-only until a supplier needed it. See
/// GENERAL-COMMENTS.md.
enum CommentSubjectKind {
  customer('customer'),
  vendor('vendor'),

  /// **The one whose notes are the point of the record rather than an aside.** A customer's notes
  /// are things worth remembering about them; a ticket's notes are the conversation the ticket
  /// exists to hold — «الشعار في المرفقات», «وصلني، أبدأ اليوم». Same four calls, same rules.
  designTicket('design_ticket');

  const CommentSubjectKind(this.wire);

  /// The `commentable_type` the server sends back — the short morph name, never a class path.
  final String wire;
}
