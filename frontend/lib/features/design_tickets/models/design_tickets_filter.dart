import 'package:dayaa/features/design_tickets/models/design_ticket.dart';

/// A question somebody else settled, handed to the list screen.
///
/// Travels as `extra` on one route and **never crosses the wire** — which is why the cubit copies
/// its fields onto itself before asking for the first page. The `ShortagesFilter` shape.
///
/// [title] is the caller's, because a screen opened on «تصاميم متجر إكس» should say so rather
/// than «تذاكر التصميم» with a filter the user cannot see.
class DesignTicketsFilter {
  const DesignTicketsFilter({
    this.status,
    this.designer,
    this.requestedBy,
    this.customerId,
    this.orderId,
    this.title,
  });

  /// One status to open on. Null is all of them — **including closed ones**, which is what the
  /// screen opens on by default: the historical record is part of what the section is for.
  final DesignTicketStatus? status;

  /// A user id as a string, **`'me'`** or **`'none'`**. Two of the three are not ids: «me» is
  /// only knowable on the server from the bearer token, and «none» — the shared pool — is a null
  /// a query string cannot otherwise carry.
  final String? designer;

  final String? requestedBy;
  final int? customerId;
  final int? orderId;

  /// What to put in the app bar instead of the section's own name.
  final String? title;
}
