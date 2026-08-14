// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'dart:async';

import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_counts.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/usecases/get_order_counts.dart';
import 'package:dayaa/features/orders/usecases/get_orders.dart';
import 'package:flutter/foundation.dart';

/// The orders screen's ViewModel.
///
/// The debounce, the out-of-order guard, appending pages and keeping the list when a page fails
/// all come from [PagedCubit]. What is left is what makes this list about orders: which queue it
/// is narrowed to.
class OrdersCubit extends PagedCubit<Order> {
  OrdersCubit({required GetOrders getOrders, required GetOrderCounts getCounts})
    : _getOrders = getOrders,
      _getCounts = getCounts;

  final GetOrders _getOrders;
  final GetOrderCounts _getCounts;

  /// The number beside each row of the status filter.
  ///
  /// A `ValueNotifier` rather than part of the state, and the reason is what the numbers are
  /// for: they describe the *unfiltered* set, so they do not change when the user picks a
  /// queue. Folding them into `PagedState` would mean every page emission carried them and
  /// every queue change threw them away and re-fetched — a second request per tap to redraw
  /// numbers that had not moved.
  ///
  /// They follow the **search** instead, which is the one filter that does change what there is
  /// to count.
  final counts = ValueNotifier<OrderCounts>(const OrderCounts.empty());

  /// The term the counts were last fetched for, so a queue tap does not refetch them.
  String? _countedFor;
  bool _hasCounted = false;

  /// Which status the list is showing, or null for «الكل».
  ///
  /// Read by the filter button, which sits inside the same `BlocBuilder` as the list — so what
  /// the sheet says is selected and what is on screen cannot disagree.
  ///
  /// **One status, not a group.** The filter used to offer queues that stood for several
  /// statuses at once, which made «أرِني ما ينتظر عند شركة التوصيل» unaskable.
  OrderStatus? status;

  /// Which payment states the list is narrowed to. Empty means every one of them.
  ///
  /// **A set, and a second axis beside [status].** «جاهزة وغير مدفوعة» is one question with two
  /// answers applied at once, so this narrows the same list rather than replacing the status.
  Set<PaymentStatus> paymentStatuses = const <PaymentStatus>{};

  /// Whether the list is narrowed by anything at all — what fills the filter button.
  bool get isFiltered => status != null || paymentStatuses.isNotEmpty;

  @override
  Future<Either<Failure, Paginated<Order>>> fetchPage({String? search, required int page}) {
    // The status rides along with every page, including the ones `loadMore` asks for: page two
    // of «نواقص» must not arrive as page two of everything.
    return _getOrders(
      search: search,
      statuses: [?status?.wire],
      paymentStatuses: paymentStatuses.map((status) => status.wire).toList(growable: false),
      page: page,
    );
  }

  /// Loads the page and, when the search has moved, the numbers beside the filter.
  ///
  /// The two are not awaited together: the list is what the user is waiting for, and holding it
  /// back until a count arrives would make every search feel slower to serve a number that is
  /// decoration on the same screen.
  @override
  Future<void> load({String? search}) async {
    unawaited(_refreshCounts(search));

    return super.load(search: search);
  }

  Future<void> _refreshCounts(String? search) async {
    if (_hasCounted && _countedFor == search) return;

    _hasCounted = true;
    _countedFor = search;

    final result = await _getCounts(search: search);

    if (isClosed) return;

    // A failed count leaves the last numbers standing rather than blanking them: the list beside
    // it is the answer the user came for, and a missing number is a smaller lie than a zero.
    result.fold((_) {}, (fresh) => counts.value = fresh);
  }

  /// Closing twice is not an error.
  ///
  /// `Cubit.close()` is idempotent, and callers rely on it — `bloc_test` closes the cubit it
  /// built, and a `tearDown` that also closes it is the ordinary way these tests are written.
  /// `ValueNotifier.dispose()` is *not* idempotent and throws on the second call, so without
  /// this flag the notifier would take a safe operation and make it throw.
  bool _countsDisposed = false;

  @override
  Future<void> close() {
    if (!_countsDisposed) {
      _countsDisposed = true;
      counts.dispose();
    }

    return super.close();
  }

  /// Narrows the list to one status, or widens it back to «الكل» with null.
  ///
  /// The search term survives: somebody who typed a customer's name and then tapped «راجع مكتب»
  /// is asking a narrower question, not starting a new one.
  Future<void> showStatus(OrderStatus? next) async {
    if (next == status) return;

    status = next;
    await load(search: currentSearch);
  }

  /// Applies both axes at once.
  ///
  /// One call rather than two, because the sheet answers both together — and two calls would
  /// fetch the list twice for a single tap on «تطبيق», with the first result thrown away.
  Future<void> showFilters({
    required OrderStatus? status,
    required Set<PaymentStatus> paymentStatuses,
  }) async {
    if (status == this.status && setEquals(paymentStatuses, this.paymentStatuses)) return;

    this.status = status;
    this.paymentStatuses = paymentStatuses;

    await load(search: currentSearch);
  }

  /// Replaces one row in place, without a round trip.
  ///
  /// Called when the detail screen hands back an order it has just moved. Re-fetching the whole
  /// page instead would be correct and wasteful — and worse, it would scroll a long list back to
  /// wherever page one ends.
  ///
  /// **A row that no longer belongs under the current status is dropped rather than left
  /// showing.** Marking an order delivered while «جاهزة» is selected should take it off that
  /// list; leaving it there would make the filter a lie until the next refresh.
  void replace(Order updated) {
    final current = state;
    if (current is! PagedLoaded<Order>) return;

    // Both axes, for the same reason: an order that has just been paid off while «غير مدفوعة»
    // is selected should leave that list, exactly as one marked delivered leaves «جاهزة».
    final belongs =
        (status == null || updated.status == status) &&
        (paymentStatuses.isEmpty || paymentStatuses.contains(updated.paymentStatus));

    final items = <Order>[
      for (final order in current.page.items)
        if (order.id != updated.id) order else if (belongs) updated,
    ];

    emit(
      current.copyWith(
        page: Paginated<Order>(items: items, meta: current.page.meta),
      ),
    );

    // The move changed what the numbers describe, so they are asked for again — the counts are
    // the one thing on this screen that a status change makes stale everywhere at once.
    _hasCounted = false;
    unawaited(_refreshCounts(currentSearch));
  }
}

/// The state this screen switches on.
typedef OrdersState = PagedState<Order>;
typedef OrdersInitial = PagedInitial<Order>;
typedef OrdersLoading = PagedLoading<Order>;
typedef OrdersLoaded = PagedLoaded<Order>;
typedef OrdersFailure = PagedFailure<Order>;
