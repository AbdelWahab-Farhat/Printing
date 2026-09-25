import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/pagination/paged_cubit.dart';
import 'package:dayaa_client/core/pagination/paged_state.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/models/ticket_change.dart';
import 'package:dayaa_client/features/support/usecases/browse_tickets.dart';
import 'package:dayaa_client/features/support/usecases/open_ticket.dart';
import 'package:dayaa_client/features/support/usecases/watch_ticket_changes.dart';

/// The list «الدعم» is bound to.
typedef SupportState = PagedState<SupportTicket>;

/// The ViewModel for «الدعم» — the list of threads, and starting a new one.
///
/// **The paging is inherited** from [PagedCubit], including the patching that lets a thread
/// come back from the screen that was reading it without the list re-fetching a page it holds.
///
/// **Opening a ticket lives here rather than in a Cubit of its own**, because the answer to
/// «أرسل تذكرة» is a row in this list. A separate ViewModel would mean the list re-reading page
/// one to learn about a ticket the server has already handed back.
///
/// **والقائمة حيّة.** ردُّ المحل يصل من المقبس فيصعد بالتذكرة إلى الأعلى بشارتها وسطرِ معاينته،
/// وإغلاقُها يغيّر حالتها أو يُخرجها من فلترٍ لم تعد تطابقه — بلا سحبٍ ولا طلب ([place]). وحين
/// يعود الاتصال بعد انقطاع تُقرأ الصفحة الأولى بصمت وتوضع صفوفها في أماكنها.
class SupportCubit extends PagedCubit<SupportTicket> {
  SupportCubit({
    required BrowseTickets browse,
    required OpenTicket open,
    required WatchTicketChanges watch,
  }) : _browse = browse,
       _open = open {
    _live = [
      watch().listen(_absorbLive),
      watch.resumed.listen((_) => unawaited(_catchUp())),
    ];
  }

  final BrowseTickets _browse;
  final OpenTicket _open;
  late final List<StreamSubscription<Object?>> _live;

  /// **Three states, not two**: null «الكل», true «المفتوحة», false «المغلقة». A `bool` would
  /// have to pick a side, and «الكل» is the side it would lose.
  bool? _openOnly;

  bool? get openOnly => _openOnly;

  /// **No `search` reaches the wire.** There is no search endpoint for tickets; the parameter
  /// is accepted to satisfy the base class and dropped, rather than sent to be ignored.
  @override
  Future<Either<Failure, Paginated<SupportTicket>>> fetchPage({
    String? search,
    required int page,
  }) => _browse(page: page, openOnly: _openOnly);

  @override
  Object identityOf(SupportTicket item) => item.id;

  /// A thread that closed while «المفتوحة» is selected leaves the list, and one that reopened
  /// while «المغلقة» is selected leaves it too — otherwise the filter is a lie until the next
  /// refresh.
  @override
  bool belongs(SupportTicket item) => _openOnly == null || item.isOpen == _openOnly;

  /// Narrows the list. [openOnly] null means «الكل».
  Future<void> narrowTo(bool? openOnly) {
    if (openOnly == _openOnly) return Future<void>.value();

    _openOnly = openOnly;

    return load();
  }

  /// Starts a thread and puts it at the head of the list.
  ///
  /// The list is most-recently-active first and the server returns it that way, so the top is
  /// exactly where the next read would put this row — which is what makes [insert] honest here.
  ///
  /// Returns the ticket so the screen can open it, which is what somebody who has just written
  /// a question expects to happen next. Null means it failed.
  Future<Either<Failure, SupportTicket>> submit({
    required String subject,
    required String body,
    int? orderId,
  }) async {
    final result = await _open(subject: subject, body: body, orderId: orderId);

    if (isClosed) return result;

    result.fold((_) {}, insert);

    return result;
  }

  /// Takes a thread back from the screen that was reading it — its badge cleared, its status
  /// possibly changed.
  ///
  /// **Patched rather than refetched**: the caller is holding the server's own answer, so a
  /// round trip would re-fetch what the app already has and throw the scroll position away.
  ///
  /// **يوضع حيث يضعه ترتيب القائمة ([place])، لا في مكانه القديم وحده.** «الدعم» تبويبان،
  /// لكلٍّ منهما قائمته: تذكرةٌ أعاد ردُّ العميل فتحها تغادر «المغلقة» وتظهر أعلى «المفتوحة»،
  /// ومحادثةٌ كُتب فيها الآن تصعد إلى الأعلى كما في كل تطبيق محادثة. الشاشة تسلّمها للتبويبين،
  /// وكلٌّ يأخذ ما يخصّه.
  ///
  /// **The card's two list-only fields are carried across, and this is not tidying.** `preview`
  /// and `messages_count` are sent by the index endpoint and not by the thread endpoint — which
  /// sends the messages themselves. A straight replacement would blank the preview line and the
  /// count on every card the customer opens. Where the thread *can* answer, it wins: somebody
  /// who has just replied should see their own words under the subject — «صورة» or the file's
  /// name when what they sent was a file ([TicketMessageX.previewText]). The messages arrive
  /// oldest-first, so the last of them is the newest; they are not kept on the row.
  void absorb(SupportTicket ticket) {
    final existing = switch (state) {
      PagedLoaded(:final page) => page.items
          .where((item) => item.id == ticket.id)
          .firstOrNull,
      _ => null,
    };

    final messages = ticket.messages;

    place(
      ticket.copyWith(
        preview: messages.isNotEmpty ? messages.last.previewText : existing?.preview,
        messagesCount: messages.isNotEmpty ? messages.length : existing?.messagesCount,
        messages: const [],
      ),
      compare: newestFirst,
    );
  }

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

  /// خبرٌ حيّ عن إحدى تذاكري: يوضع الصفّ في مكانه، ومعه سطرُ المعاينة.
  ///
  /// **المعاينةُ من الرسالة إن جاءت** — الحدث لا يحمل `preview`، والرسالةُ نفسها فيه — وإلا
  /// بقيت التي رُسم بها الصفّ: إغلاقٌ لا يمسح آخر ما قيل.
  void _absorbLive(TicketChange change) {
    final existing = switch (state) {
      PagedLoaded(:final page) => page.items.where((item) => item.id == change.ticket.id).firstOrNull,
      _ => null,
    };

    place(
      change.ticket.copyWith(
        preview: change.message?.previewText ?? existing?.preview,
        messagesCount: change.ticket.messagesCount ?? existing?.messagesCount,
      ),
      compare: newestFirst,
    );
  }

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
