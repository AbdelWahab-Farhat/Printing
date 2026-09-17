import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/usecases/support_usecases.dart';

/// The list the queue is bound to.
typedef SupportTicketsState = PagedState<SupportTicket>;

/// The desk's queue.
///
/// **The paging is inherited, not written here.** Debounce, the out-of-order guard, appending
/// without duplicating a row that moved between pages, and keeping the list when page three
/// fails all live in [PagedCubit] — every one of them is a bug somebody has shipped by
/// forgetting it.
///
/// **No search.** The tickets endpoint takes `status` and `assigned_to` and nothing else; a
/// search box wired to a parameter the server ignores is worse than no search box, because it
/// looks like it worked.
class SupportTicketsCubit extends PagedCubit<SupportTicket> {
  SupportTicketsCubit({required BrowseTickets browse}) : _browse = browse;

  final BrowseTickets _browse;

  /// Which state the queue is narrowed to. Null is everything, **closed ones included** — which
  /// is what it opens on, because «ماذا قلنا لهم آخر مرة؟» is half of what the desk is for.
  TicketStatus? status;

  /// One person's desk, or null for the whole queue.
  int? assignedTo;

  @override
  Future<Either<Failure, Paginated<SupportTicket>>> fetchPage({
    String? search,
    required int page,
  }) => _browse(page: page, status: status, assignedTo: assignedTo);

  @override
  Object identityOf(SupportTicket item) => item.id;

  /// **A ticket that leaves the filter leaves the list.** Closing one while «مفتوحة» is selected
  /// must take it off the screen, or the chip is a lie until the next refresh — see
  /// [PagedCubit.belongs].
  @override
  bool belongs(SupportTicket item) {
    if (status != null && item.status != status) return false;
    if (assignedTo != null && item.assignedTo != assignedTo) return false;

    return true;
  }

  Future<void> narrowTo(TicketStatus? value) {
    if (value == status) return Future<void>.value();

    status = value;

    return load();
  }

  Future<void> showDeskOf(int? userId) {
    if (userId == assignedTo) return Future<void>.value();

    assignedTo = userId;

    return load();
  }

  /// Takes a thread back from the screen that was reading it — its badge cleared, its status or
  /// its assignee possibly changed.
  ///
  /// **[replace] rather than a refresh**: the caller is holding the server's own answer, so a
  /// round trip would re-fetch what the app already has and throw the scroll position away.
  void absorb(SupportTicket ticket) => replace(ticket);
}
