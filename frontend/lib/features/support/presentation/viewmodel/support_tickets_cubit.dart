import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/models/ticket_change.dart';
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
///
/// **والطابور حيّ.** كلُّ تذكرةٍ تتغيّر في المكتب تصل من المقبس وتوضع في مكانها بلا طلب
/// ([place]): جاءتها رسالةٌ فتصعد إلى الأعلى، أُسندت أو قُرئت فتبقى حيث هي بعلاماتها الجديدة،
/// وخرجت من الفلتر فتغادر. وحين يعود الاتصال بعد انقطاع تُقرأ الصفحة الأولى بصمت وتوضع صفوفها
/// في أماكنها — ما فات في الانقطاع لا يُعاد على المقبس.
class SupportTicketsCubit extends PagedCubit<SupportTicket> {
  SupportTicketsCubit({required BrowseTickets browse, required WatchTicketChanges watch})
    : _browse = browse {
    _live = [
      watch().listen(_absorbLive),
      watch.resumed.listen((_) => unawaited(_catchUp())),
    ];
  }

  final BrowseTickets _browse;
  late final List<StreamSubscription<Object?>> _live;

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

  /// ترتيبُ الخادم نفسه: الأحدثُ رسالةً أولاً، ثم الأحدثُ رقماً. وتذكرةٌ بلا رسالةٍ بعد تسبق
  /// الجميع — Postgres يضع الفارغ أولاً في الترتيب التنازلي، وهذا يوافقه.
  static int newestFirst(SupportTicket a, SupportTicket b) {
    final at = a.lastMessageAt;
    final bt = b.lastMessageAt;

    if (at != bt) {
      if (at == null) return -1;
      if (bt == null) return 1;

      final byTime = bt.compareTo(at);
      if (byTime != 0) return byTime;
    }

    return b.id.compareTo(a.id);
  }

  void _absorbLive(TicketChange change) => place(change.ticket, compare: newestFirst);

  /// ما فات في الانقطاع: الصفحةُ الأولى بصمت — بلا هيكلٍ رمادي ولا رجوعٍ إلى أعلى القائمة —
  /// وكلُّ صفٍّ فيها يوضع في مكانه.
  Future<void> _catchUp() async {
    if (state is! PagedLoaded<SupportTicket>) return;

    final result = await fetchPage(page: 1);

    if (isClosed) return;

    result.fold((_) {}, (page) {
      for (final ticket in page.items) {
        place(ticket, compare: newestFirst);
      }
    });
  }

  @override
  Future<void> close() async {
    for (final subscription in _live) {
      await subscription.cancel();
    }

    return super.close();
  }
}
