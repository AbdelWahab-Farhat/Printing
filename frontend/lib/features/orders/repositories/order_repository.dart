// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_status.dart';

/// What the app can ask about orders, stated without saying how.
///
/// The Cubit depends on this, so a test hands it a fake in one line and never constructs Dio.
abstract interface class OrderRepository {
  Future<Either<Failure, Paginated<Order>>> orders({
    String? search,
    List<String> statuses,
    int? customerId,
    int page,
    int perPage,
  });

  Future<Either<Failure, Order>> order(int orderId);

  /// Moves an order, and answers with it as the server left it.
  ///
  /// The updated order comes back rather than a bare success, because the move changes more
  /// than the status: the timeline gains a row, a timestamp is stamped, and — the one the
  /// screen cannot guess — `available_transitions` becomes a different set. Re-fetching would
  /// be a second round trip for something the write already knew.
  Future<Either<Failure, Order>> changeStatus(
    int orderId, {
    required OrderStatus status,
    String? reason,
  });
}
