import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/pagination/paged_cubit.dart';
import 'package:printing/core/pagination/paged_state.dart';
import 'package:printing/features/purchase_orders/models/purchase_order.dart';
import 'package:printing/features/purchase_orders/usecases/purchase_order_usecases.dart';

/// The purchase orders list, narrowed by status.
///
/// **No search box, and that is the API rather than a choice.** The list endpoint accepts
/// `vendor_id`, `warehouse_id` and `status` — and nothing to type into. Offering a search field
/// that filtered nothing would be worse than not offering one.
class PurchaseOrdersCubit extends PagedCubit<PurchaseOrder> {
  PurchaseOrdersCubit({required GetPurchaseOrders getOrders}) : _getOrders = getOrders;

  final GetPurchaseOrders _getOrders;

  /// Which state the list is showing. Null is every state, which is what it opens on.
  PurchaseOrderStatus? status;

  @override
  Future<Either<Failure, Paginated<PurchaseOrder>>> fetchPage({
    String? search,
    required int page,
  }) {
    // The filter rides along with every page, including the ones `loadMore` asks for.
    return _getOrders(status: status, page: page);
  }

  /// Shows one state, or all of them.
  Future<void> showStatus(PurchaseOrderStatus? next) async {
    if (status == next) return;

    status = next;

    await load();
  }

  /// Puts back an order the detail screen changed, or drops it when the change took it out of
  /// the state on screen.
  void replace(PurchaseOrder updated) {
    final current = state;
    if (current is! PagedLoaded<PurchaseOrder>) return;

    final belongs = status == null || status == updated.status;

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

typedef PurchaseOrdersState = PagedState<PurchaseOrder>;
typedef PurchaseOrdersLoaded = PagedLoaded<PurchaseOrder>;
