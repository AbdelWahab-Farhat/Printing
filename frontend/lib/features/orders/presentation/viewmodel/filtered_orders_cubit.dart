// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/orders_filter.dart';
import 'package:dayaa/features/orders/models/orders_sort.dart';
import 'package:dayaa/features/orders/usecases/get_orders.dart';

/// One fixed question about the orders, asked once.
///
/// **Separate from [OrdersCubit] rather than a mode of it, and the difference is who chooses.**
/// The orders tab is a place somebody browses: its queue changes under their thumb, and it
/// carries the chips and the counts that make that worth doing. This answers a question that was
/// already asked — a number was tapped — so the filter is fixed for the life of the screen and
/// there is nothing on it to change.
///
/// It keeps the search from [PagedCubit] because narrowing «١٢ راجع مكتب» by a customer's name
/// is a reasonable second thought.
class FilteredOrdersCubit extends PagedCubit<Order> {
  FilteredOrdersCubit({required GetOrders getOrders, required OrdersFilter filter})
    : _getOrders = getOrders,
      _filter = filter,
      sort = filter.initialSort;

  final GetOrders _getOrders;
  final OrdersFilter _filter;

  /// Which end of the queue the screen is reading from.
  ///
  /// **The one thing on this screen that does change**, and it is not a filter: the question was
  /// settled by the tap that opened it, and this narrows nothing — it only says where the list
  /// starts. Which is why it is a button of its own rather than a chip, exactly as it is on the
  /// orders tab. See [OrderSortButton].
  ///
  /// It starts where the filter says it should — «جاهزة للطباعة» opens at the far end, see
  /// [OrdersFilter.initialSort] — and the reader's tap wins from then on.
  OrdersSort sort;

  @override
  Object identityOf(Order item) => item.id;

  @override
  Future<Either<Failure, Paginated<Order>>> fetchPage({String? search, required int page}) {
    // The filter rides along with every page, including the ones `loadMore` asks for: page two
    // of «نواقص» must not arrive as page two of everything — and page two of one customer's
    // orders must not arrive as page two of the whole shop's.
    return _getOrders(
      search: search,
      statuses: _filter.statuses,
      paymentStatuses: _filter.paymentStatuses,
      readyMessageSent: _filter.readyMessageSent,
      customerId: _filter.customerId,
      from: _filter.from,
      to: _filter.to,
      // And so does the sort, for the same reason: page two of «الأقدم أولاً» fetched the other
      // way round is a page of orders the reader has just read, appended under the ones they
      // have.
      sort: sort,
      page: page,
    );
  }

  /// Turns the list round.
  ///
  /// The question survives it — the statuses, the payment states, the customer, the days, and
  /// the search typed into the box: somebody asking «أرِني الجاهزة للطباعة، الأحدث أولاً» is
  /// asking one question in two taps, not opening a different screen.
  Future<void> showSort(OrdersSort next) async {
    if (next == sort) return;

    sort = next;
    await load(search: currentSearch);
  }

  /// Whether an order still answers the question this screen was opened to ask.
  ///
  /// **Dropping is the point.** Marking the last «نواقص» resolved should empty this screen, not
  /// leave a row contradicting the title above it until somebody pulls to refresh — and an
  /// order paid off while this screen is showing «غير مدفوعة» leaves it the same way.
  /// [PagedCubit.replace] drops the row when this says no.
  @override
  bool belongs(Order item) =>
      (_filter.statuses.isEmpty || _filter.statuses.contains(item.status.wire)) &&
      (_filter.paymentStatuses.isEmpty ||
          _filter.paymentStatuses.contains(item.paymentStatus.wire)) &&
      // **Ticking «أُرسلت الرسالة» empties this screen row by row, which is the point.** The
      // employee works down the queue marking each one, and a row that stayed under the title
      // «بانتظار رسالة الجاهزية» after being marked would be the screen arguing with itself. The
      // detail screen hands the order back and [PagedCubit.replace] drops it here.
      (_filter.readyMessageSent == null || _filter.readyMessageSent == item.isReadyMessageSent) &&
      // And an archived one leaves too, exactly as it leaves الطلبيات. This screen reads the
      // live list, so a deleted order was never one of its answers — but the row can be deleted
      // *from* here, on the detail screen this list opens, and the trashed order is handed
      // straight back. Without this line it would sit under a title it no longer belongs to
      // until somebody pulled to refresh.
      !item.isArchived;
}

typedef FilteredOrdersState = PagedState<Order>;
