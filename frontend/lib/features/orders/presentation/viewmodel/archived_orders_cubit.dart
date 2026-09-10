import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/orders_cubit.dart';
import 'package:dayaa/features/orders/usecases/get_archived_orders.dart';

/// أرشيف الطلبيات — [OrdersCubit] reading the other side of the soft-delete line.
///
/// **Inheritance rather than a class of its own, and §٨ chose it for a reason worth repeating.**
/// The archive was going to be `FilteredOrdersPage` with a fixed question. It cannot be:
/// `OrdersFilter` carries six fields with no `isUrgent`, no `cityId` and no search, and its
/// `initialSort` is a derived getter — so «نفس الفلاتر التي طلبها الطلب» is literally
/// inexpressible in it. What the reader wants in الأرشيف is the orders screen: the same search
/// box, the same status chips with their own counts, the same payment axis, the same urgency,
/// the same sort. So it *is* that screen, with its two sources swapped out
/// ([GetArchivedOrders], [GetArchivedOrderCounts]) and one comparison turned round.
///
/// **The one comparison.** الطلبيات refuses a row carrying `deleted_at`; this refuses one
/// without. Both are read by [PagedCubit.replace], which already drops a row that stopped
/// belonging — so restoring an order on its detail screen takes it off الأرشيف, and deleting
/// one takes it off الطلبيات, and neither costs a request. That machinery predates this
/// feature; nothing here was built for it.
///
/// **What is deliberately absent is `insert`.** A restored order is not put at the top of
/// الطلبيات: `insert`'s docblock says it is for lists the server returns `id DESC` and counts
/// the orders among them, and that is a slip — `OrderListQuery` sorts by `placed_at` then `id`,
/// and the direction turns over under «الأقدم أولاً». Inventing a position the next page load
/// would contradict is worse than the row arriving one load later.
///
/// **No status moves reach this screen**, and not because anything here forbids them: a trashed
/// order arrives with no `available_transitions` at all, so [OrderCard] draws none. See §٦ —
/// the resource dropping that key is correctness, not economy.
class ArchivedOrdersCubit extends OrdersCubit {
  ArchivedOrdersCubit({
    required GetArchivedOrders getOrders,
    required GetArchivedOrderCounts getCounts,
  }) : super(getOrders: getOrders, getCounts: getCounts);

  /// The same three axes as الطلبيات, on the deleted orders instead of the live ones.
  @override
  bool belongs(Order item) => matchesFilters(item) && item.isArchived;
}
