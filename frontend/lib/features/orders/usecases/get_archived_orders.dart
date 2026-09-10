// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_counts.dart';
import 'package:dayaa/features/orders/models/orders_sort.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/get_order_counts.dart';
import 'package:dayaa/features/orders/usecases/get_orders.dart';

/// One page of الأرشيف — the same question, asked of the deleted orders.
///
/// **A subclass of [GetOrders] rather than a use case beside it, and that is the whole of §٨'s
/// «الأرشيف شاشةٌ تُحاكي `OrdersPage`».** The archive screen is not a different screen, it is
/// the orders screen reading a different source; expressing that as a substitutable source lets
/// [ArchivedOrdersCubit] be [OrdersCubit] with one line changed — the search, the status chips,
/// the payment axis, the urgency, the sort, the counts and the patching all come across intact
/// and none of them is written twice.
///
/// The alternative was a second Cubit carrying its own copy of those six axes. It loses the
/// moment somebody adds a seventh: the archive would keep the button and stop honouring it,
/// with nothing on screen to say so.
///
/// Its own `_repository` rather than the parent's, because that field is private to the
/// library that declares it — the `super` call hands the same instance over so the inherited
/// members stay honest.
final class GetArchivedOrders extends GetOrders {
  GetArchivedOrders(this._repository) : super(_repository);

  final OrderRepository _repository;

  @override
  Future<Either<Failure, Paginated<Order>>> call({
    String? search,
    List<String> statuses = const <String>[],
    List<String> paymentStatuses = const <String>[],
    bool? isUrgent,
    OrdersSort sort = OrdersSort.fallback,
    int? customerId,
    String? from,
    String? to,
    int page = 1,
    int perPage = 20,
  }) {
    return _repository.archivedOrders(
      search: search,
      statuses: statuses,
      paymentStatuses: paymentStatuses,
      isUrgent: isUrgent,
      sort: sort,
      customerId: customerId,
      from: from,
      to: to,
      page: page,
      perPage: perPage,
    );
  }
}

/// The numbers beside الأرشيف's filter, counted over الأرشيف.
///
/// **Substituted the same way [GetArchivedOrders] is, and for a sharper reason than symmetry.**
/// §٦ names three queries that seed themselves separately — the list, the status counts and the
/// payment counts — and warns that pointing only some of them at the archive leaves two rows of
/// chips describing two different sets, contradicting each other in front of the eye. Swapping
/// the *source* rather than threading a flag is what makes that impossible here: the Cubit has
/// exactly one place to fetch counts from, and it is this.
final class GetArchivedOrderCounts extends GetOrderCounts {
  GetArchivedOrderCounts(this._repository) : super(_repository);

  final OrderRepository _repository;

  @override
  Future<Either<Failure, OrderCounts>> call({String? search, int? customerId}) =>
      _repository.archivedStatusCounts(search: search, customerId: customerId);
}
