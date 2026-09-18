import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_counts.dart';
import 'package:dayaa/features/design_tickets/models/design_tickets_filter.dart';
import 'package:dayaa/features/design_tickets/usecases/design_ticket_usecases.dart';
import 'package:flutter/foundation.dart';

/// The تذاكر التصميم list, its chip row, and the filters both are narrowed by.
///
/// **Every filter rides on every page**, including the ones `loadMore` asks for — a screen that
/// sent them separately would show a list narrowed by whichever landed last.
///
/// **The chip row is a second request, asked without the status.** It answers «what *else* is
/// there?», so narrowing it by the status already on screen would make every chip but one read
/// zero. Every other filter is kept, so «قيد التصميم ٥» under a customer filter means five of
/// that customer's.
///
/// **What the list contains is the server's decision, not this class's.** A reader without
/// `design_tickets.view_all` is answered with their own tickets and the unclaimed pool; there is
/// nothing to filter out here, and a client-side attempt would only disagree with the counts.
class DesignTicketsCubit extends PagedCubit<DesignTicket> {
  DesignTicketsCubit({
    required GetDesignTickets getTickets,
    required GetDesignTicketCounts getCounts,
    required AcceptDesignTicket acceptTicket,
  }) : _getTickets = getTickets,
       _getCounts = getCounts,
       _accept = acceptTicket;

  final GetDesignTickets _getTickets;
  final GetDesignTicketCounts _getCounts;
  final AcceptDesignTicket _accept;

  /// Which status the list is showing. Null is every status — **closed ones included**, which is
  /// what it opens on: the historical record is part of what the section is for.
  DesignTicketStatus? status;

  /// `'me'`, `'none'` (the shared pool), a user id as a string, or null for everybody's.
  String? designer;

  String? requestedBy;
  int? customerId;
  int? orderId;

  /// The chip row's numbers. Rebuilt on every question, and **never derived from the rows on
  /// screen** — a page of twenty says nothing about how many there are.
  final ValueNotifier<DesignTicketCounts> counts = ValueNotifier(
    const DesignTicketCounts.empty(),
  );

  @override
  Object identityOf(DesignTicket item) => item.id;

  @override
  Future<Either<Failure, Paginated<DesignTicket>>> fetchPage({
    String? search,
    required int page,
  }) {
    // The row is refreshed beside the first page and never beside `loadMore`: the numbers
    // describe the whole question, and page two does not change it.
    if (page == 1) unawaited(_refreshCounts(search));

    return _getTickets(
      statuses: [?status],
      designer: designer,
      requestedBy: requestedBy,
      customerId: customerId,
      orderId: orderId,
      search: search,
      page: page,
    );
  }

  Future<void> _refreshCounts(String? search) async {
    final result = await _getCounts(
      designer: designer,
      requestedBy: requestedBy,
      customerId: customerId,
      orderId: orderId,
      search: search,
    );

    if (isClosed) return;

    // A failed row leaves the last numbers standing rather than blanking it: the list underneath
    // still answered, and zeros nobody measured would be a worse lie than stale ones.
    result.fold((_) {}, (fresh) => counts.value = fresh);
  }

  /// Opens the list on a question somebody else settled — one customer's tickets, say.
  ///
  /// **The filter's fields are seeded before the first page is asked for.**
  /// [DesignTicketsFilter] never crosses the wire; it travels as `extra` on one route, so an id
  /// in it has to be copied onto this cubit first.
  Future<void> start(DesignTicketsFilter? filter) async {
    if (filter != null) {
      status = filter.status;
      designer = filter.designer;
      requestedBy = filter.requestedBy;
      customerId = filter.customerId;
      orderId = filter.orderId;
    }

    await load();
  }

  /// Narrows to one status, or clears it. Re-runs the current search term rather than a blank
  /// one, so tapping a chip does not silently drop what was typed.
  Future<void> showStatus(DesignTicketStatus? next) async {
    status = next;

    await load(search: currentSearch);
  }

  /// The designer's three queues: everything, «شغلي», and the shared pool.
  Future<void> showDesigner(String? next) async {
    designer = next;

    await load(search: currentSearch);
  }

  /// A designer taking a ticket without opening it.
  ///
  /// **The row is patched from what the server hands back, not re-read.** Accepting returns the
  /// whole ticket, so the list already knows the answer — and a refresh here would throw away
  /// the reader's scroll position in the middle of a queue they are working down.
  ///
  /// **The counts are re-asked, and they are the reason this is not a pure patch.** The ticket
  /// leaves «جديد» for «قيد التصميم», so two of the numbers in the picker above the list are
  /// wrong the moment the row changes.
  ///
  /// Returns the failure when there is one, so the screen says it in its own words — a Cubit
  /// that emitted a failure state here would blank the list it is sitting under.
  Future<Failure?> accept(int ticketId) async {
    final result = await _accept(ticketId);

    if (isClosed) return null;

    return result.fold((failure) => failure, (ticket) {
      replace(ticket);
      unawaited(_refreshCounts(currentSearch));

      return null;
    });
  }

  @override
  Future<void> close() {
    counts.dispose();

    return super.close();
  }
}

/// What the تذاكر التصميم list can be. The generic union, named for this feature so
/// `DesignTicketsLoaded` reads at call sites while there is only one implementation to fix.
typedef DesignTicketsState = PagedState<DesignTicket>;
