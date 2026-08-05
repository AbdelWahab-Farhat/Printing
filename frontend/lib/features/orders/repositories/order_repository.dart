// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_counts.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/usecases/update_order_invoice.dart';

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

  /// How many orders sit in each status, under the same filters as [orders].
  ///
  /// Deliberately takes the search but not the statuses: counts narrowed to the queue already
  /// chosen would every one of them read as that queue's own length.
  Future<Either<Failure, OrderCounts>> statusCounts({String? search, int? customerId});

  Future<Either<Failure, Order>> order(int orderId);

  /// Moves an order, and answers with it as the server left it.
  ///
  /// The updated order comes back rather than a bare success, because the move changes more
  /// than the status: the timeline gains a row, a timestamp is stamped, and — the one the
  /// screen cannot guess — `available_transitions` becomes a different set. Re-fetching would
  /// be a second round trip for something the write already knew.
  /// Replaces the order's lines and its discount, and answers with it re-priced.
  ///
  /// The destination has to be re-sent because `PUT` replaces the whole order — leaving
  /// `city_id` out would be an instruction to clear it, which is what PUT means.
  Future<Either<Failure, Order>> updateInvoice(
    int orderId, {
    required List<InvoiceLineUpdate> lines,
    required String discount,
  });

  /// [fields] is whatever the chosen transition asked for, keyed as the server described it —
  /// see `TransitionField`. Nothing here knows what those keys mean.
  Future<Either<Failure, Order>> changeStatus(
    int orderId, {
    required OrderStatus status,
    String? reason,
    Map<String, Object?> fields,
  });

  /// Puts the next version of the artwork in front of the customer.
  ///
  /// The design is *pointed at*, never uploaded here: it lives in the customer's library, which
  /// is where a design is uploaded and where every other order finds it again.
  Future<Either<Failure, void>> addDesign(int orderId, {required int customerDesignId});

  /// Approves or rejects one version. A rejection owes a sentence — it is the whole reason
  /// versions are rows rather than a single file that gets replaced.
  Future<Either<Failure, void>> reviewDesign(
    int orderId,
    int designId, {
    required bool isApproved,
    String? rejectionReason,
  });
}
