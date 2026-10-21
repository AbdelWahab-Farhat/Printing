import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket_query.dart';
import 'package:dayaa/features/internal_tickets/usecases/internal_tickets_usecases.dart';

typedef InternalTicketsState = PagedState<InternalTicket>;

/// قائمة «الموظفين» — كقائمة بريمولا الداخلية: البحثُ بالكود والعنوان واسم الموظف، والرقاقتان
/// «قيد المعالجة» و«مغلقة»، والفلاتر، و«تذاكري / الكل» للمدير.
///
/// **الصفحاتُ موروثة** من [PagedCubit] — التأخير والردود المتأخرة والإلحاق بلا تكرار.
///
/// **وحيّة**: إشارةٌ على قناتي بأن تذكرةً أنا طرفٌ فيها تغيّرت تُقرأ لها الصفحةُ الأولى بصمت بعد
/// ثانية — الإشارةُ رقمٌ فقط، لأن «غير المقروء» و«مَن ينتظر مَن» يختلفان من قارئٍ لآخر — وتوضع صفوفُها
/// في أماكنها. والثانيةُ تجمع رسائلَ متتالية في طلبٍ واحد.
class InternalTicketsCubit extends PagedCubit<InternalTicket> {
  InternalTicketsCubit({
    required BrowseInternalTickets browse,
    required WatchInternalTickets watch,
    required int? me,
    InternalTicketQuery query = const InternalTicketQuery(),
    this.catchUpDelay = const Duration(seconds: 1),
  }) : _browse = browse,
       _query = query {
    _live = [
      if (me != null) watch.mine(me).listen((_) => _scheduleCatchUp()),
      watch.resumed.listen((_) => _scheduleCatchUp()),
    ];
  }

  final BrowseInternalTickets _browse;
  late final List<StreamSubscription<Object?>> _live;
  Timer? _catchUpTimer;

  InternalTicketQuery _query;

  InternalTicketQuery get query => _query;

  /// ثانيةٌ تجمع إشاراتٍ متتالية في طلبٍ واحد. تمرّرها الاختبارات صفراً.
  final Duration catchUpDelay;

  @override
  Future<Either<Failure, Paginated<InternalTicket>>> fetchPage({
    String? search,
    required int page,
  }) => _browse(query: _query, search: search, page: page);

  @override
  Object identityOf(InternalTicket item) => item.id;

  /// **تذكرةٌ تخرج من الفلتر تخرج من القائمة**: مغلقةٌ و«قيد المعالجة» مختارة، أو مقروءةٌ و«غير
  /// المقروءة» مختارة.
  @override
  bool belongs(InternalTicket item) {
    if (item.status != _query.status) return false;
    if (_query.unreadOnly && item.unreadCount == 0) return false;

    return true;
  }

  /// يغيّر السؤالَ ويعيد القراءة بالبحث نفسه.
  Future<void> narrow(InternalTicketQuery next) {
    if (next == _query) return Future<void>.value();

    _query = next;

    return load(search: currentSearch);
  }

  /// يأخذ تذكرةً عائدةً من محادثتها — بلا طلب.
  void absorb(InternalTicket ticket) => replace(ticket);

  /// ترتيبُ الخادم: الأحدثُ نشاطاً أولاً، ثم الأحدثُ رقماً — أو العكس لـ«أقدم نشاط».
  int _order(InternalTicket a, InternalTicket b) {
    final at = a.lastMessageAt;
    final bt = b.lastMessageAt;
    final sign = _query.oldestFirst ? -1 : 1;

    if (at != bt) {
      if (at == null) return -sign;
      if (bt == null) return sign;

      final byTime = bt.compareTo(at) * sign;
      if (byTime != 0) return byTime;
    }

    return b.id.compareTo(a.id) * sign;
  }

  void _scheduleCatchUp() {
    _catchUpTimer?.cancel();
    _catchUpTimer = Timer(catchUpDelay, () => unawaited(_catchUp()));
  }

  /// الصفحةُ الأولى بصمت — بلا هيكلٍ رماديّ ولا رجوعٍ إلى أعلى القائمة — وكلُّ صفٍّ فيها في مكانه.
  Future<void> _catchUp() async {
    if (state is! PagedLoaded<InternalTicket>) return;

    final result = await fetchPage(search: currentSearch, page: 1);

    if (isClosed) return;

    result.fold((_) {}, (page) {
      for (final ticket in page.items) {
        place(ticket, compare: _order);
      }
    });
  }

  @override
  Future<void> close() async {
    _catchUpTimer?.cancel();

    for (final subscription in _live) {
      await subscription.cancel();
    }

    return super.close();
  }
}
