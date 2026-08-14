import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_orders_filter.dart';
import 'package:dayaa/features/purchase_orders/usecases/purchase_order_usecases.dart';

/// One fixed question about the purchase orders, asked once.
///
/// **Separate from [PurchaseOrdersCubit] rather than a mode of it, and the difference is who
/// chooses.** The purchase-orders tab is a place somebody browses: its queue changes under their
/// thumb, and it carries the chips that make that worth doing. This answers a question that was
/// already asked — a row on a supplier's screen was tapped — so the filter is fixed for the life
/// of the screen and there is nothing on it to change. Same split `FilteredOrdersCubit` draws.
class FilteredPurchaseOrdersCubit extends PagedCubit<PurchaseOrder> {
  FilteredPurchaseOrdersCubit({
    required GetPurchaseOrders getOrders,
    required PurchaseOrdersFilter filter,
  }) : _getOrders = getOrders,
       _filter = filter;

  final GetPurchaseOrders _getOrders;
  final PurchaseOrdersFilter _filter;

  @override
  Future<Either<Failure, Paginated<PurchaseOrder>>> fetchPage({
    String? search,
    required int page,
  }) {
    // The filter rides along with every page, including the ones `loadMore` asks for: page two
    // of one supplier's orders must not arrive as page two of every supplier's.
    return _getOrders(
      vendorId: _filter.vendorId,
      statuses: _filter.statuses
          .map(PurchaseOrderStatus.fromWire)
          .toList(growable: false),
      search: search,
      page: page,
    );
  }

  /// Puts back an order the detail screen changed, or drops it when the change took it out of
  /// the answer this screen is showing.
  ///
  /// **Dropping is the point.** Cancelling the last outstanding order from a screen titled
  /// «الجارية» should empty it, not leave a row contradicting the title above it.
  void replace(PurchaseOrder updated) {
    final current = state;
    if (current is! PagedLoaded<PurchaseOrder>) return;

    final belongs =
        _filter.statuses.isEmpty ||
        _filter.statuses.contains(updated.status.wire);

    emit(
      current.copyWith(
        page: Paginated<PurchaseOrder>(
          items: [
            for (final order in current.page.items)
              if (order.id != updated.id) order else if (belongs) updated,
          ],
          meta: current.page.meta,
        ),
      ),
    );
  }
}

typedef FilteredPurchaseOrdersState = PagedState<PurchaseOrder>;
