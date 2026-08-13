// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/pagination/paged_cubit.dart';
import 'package:printing/core/pagination/paged_state.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/orders_filter.dart';
import 'package:printing/features/orders/usecases/get_orders.dart';

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
      _filter = filter;

  final GetOrders _getOrders;
  final OrdersFilter _filter;

  @override
  Future<Either<Failure, Paginated<Order>>> fetchPage({String? search, required int page}) {
    // The filter rides along with every page, including the ones `loadMore` asks for: page two
    // of «نواقص» must not arrive as page two of everything — and page two of one customer's
    // orders must not arrive as page two of the whole shop's.
    return _getOrders(
      search: search,
      statuses: _filter.statuses,
      paymentStatuses: _filter.paymentStatuses,
      customerId: _filter.customerId,
      from: _filter.from,
      to: _filter.to,
      page: page,
    );
  }

  /// Puts back an order the detail screen moved, or drops it when the move took it out of the
  /// answer this screen is showing.
  ///
  /// **Dropping is the point.** Marking the last «نواقص» resolved should empty this screen, not
  /// leave a row contradicting the title above it until somebody pulls to refresh.
  void replace(Order updated) {
    final current = state;
    if (current is! PagedLoaded<Order>) return;

    // Both axes, for the reason above: an order paid off while this screen is showing «غير
    // مدفوعة» should leave it, exactly as a resolved «نواقص» does.
    final belongs =
        (_filter.statuses.isEmpty || _filter.statuses.contains(updated.status.wire)) &&
        (_filter.paymentStatuses.isEmpty ||
            _filter.paymentStatuses.contains(updated.paymentStatus.wire));

    emit(
      current.copyWith(
        page: Paginated<Order>(
          items: <Order>[
            for (final order in current.page.items)
              if (order.id != updated.id) order else if (belongs) updated,
          ],
          meta: current.page.meta,
        ),
      ),
    );
  }
}

typedef FilteredOrdersState = PagedState<Order>;
