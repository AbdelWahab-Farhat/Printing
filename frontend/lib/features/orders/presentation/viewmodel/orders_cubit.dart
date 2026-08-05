// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'dart:async';

import 'package:dartz/dartz.dart' hide Order;
import 'package:flutter/foundation.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/pagination/paged_cubit.dart';
import 'package:printing/core/pagination/paged_state.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_counts.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/usecases/get_order_counts.dart';
import 'package:printing/features/orders/usecases/get_orders.dart';

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

  /// Which queue the list is showing. Read by the chips row, which sits inside the same
  /// `BlocBuilder` as the list — so the selected chip and what is on screen cannot disagree.
  OrderQueue queue = OrderQueue.all;

  @override
  Future<Either<Failure, Paginated<Order>>> fetchPage({
    String? search,
    required int page,
  }) {
    // The queue rides along with every page, including the ones `loadMore` asks for: page two
    // of «رواجع» must not arrive as page two of everything.
    return _getOrders(search: search, statuses: queue.wires, page: page);
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

  /// Narrows the list to one queue, or widens it back to all of them.
  ///
  /// The search term survives: somebody who typed a customer's name and then tapped «رواجع» is
  /// asking a narrower question, not starting a new one.
  Future<void> showQueue(OrderQueue next) async {
    if (next == queue) return;

    queue = next;
    await load(search: currentSearch);
  }

  /// Replaces one row in place, without a round trip.
  ///
  /// Called when the detail screen hands back an order it has just moved. Re-fetching the whole
  /// page instead would be correct and wasteful — and worse, it would scroll a long list back to
  /// wherever page one ends.
  ///
  /// **A row that no longer belongs in the current queue is dropped rather than left showing.**
  /// Marking an order delivered while «جاهزة» is selected should take it off that list; leaving
  /// it there would make the chip a lie until the next refresh.
  void replace(Order updated) {
    final current = state;
    if (current is! PagedLoaded<Order>) return;

    final belongs = queue == OrderQueue.all || queue.statuses.contains(updated.status);

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
