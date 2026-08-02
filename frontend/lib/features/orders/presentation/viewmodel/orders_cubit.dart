// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/pagination/paged_cubit.dart';
import 'package:printing/core/pagination/paged_state.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/usecases/get_orders.dart';

/// The orders screen's ViewModel.
///
/// The debounce, the out-of-order guard, appending pages and keeping the list when a page fails
/// all come from [PagedCubit]. What is left is what makes this list about orders: which queue it
/// is narrowed to.
class OrdersCubit extends PagedCubit<Order> {
  OrdersCubit({required GetOrders getOrders}) : _getOrders = getOrders;

  final GetOrders _getOrders;

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
  }
}

/// The state this screen switches on.
typedef OrdersState = PagedState<Order>;
typedef OrdersInitial = PagedInitial<Order>;
typedef OrdersLoading = PagedLoading<Order>;
typedef OrdersLoaded = PagedLoaded<Order>;
typedef OrdersFailure = PagedFailure<Order>;
