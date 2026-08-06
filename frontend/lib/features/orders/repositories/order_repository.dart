// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/orders/models/new_order.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_counts.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/usecases/update_order_invoice.dart';

/// What the app can ask about orders, stated without saying how.
///
/// The Cubit depends on this, so a test hands it a fake in one line and never constructs Dio.
abstract interface class OrderRepository {
  /// [from] and [to] are plain `Y-m-d` days in the *shop's* timezone, and the server turns
  /// each into the instants that day begins and ends. Sending the same date for both is how a
  /// single day is asked for.
  /// [paymentStatuses] takes the wire values of `PaymentStatus`. It is a **second axis that
  /// crosses** [statuses] rather than narrowing it — «جاهزة وغير مدفوعة» is a real question, and
  /// both filters apply at once.
  Future<Either<Failure, Paginated<Order>>> orders({
    String? search,
    List<String> statuses,
    List<String> paymentStatuses,
    int? customerId,
    String? from,
    String? to,
    int page,
    int perPage,
  });

  /// How many orders sit in each status, under the same filters as [orders].
  ///
  /// Deliberately takes the search but not the statuses: counts narrowed to the queue already
  /// chosen would every one of them read as that queue's own length.
  ///
  /// Answers with **both** axes — how many orders sit in each status, and how many stand unpaid,
  /// part-paid, paid and overpaid. One request, because the filter sheet shows them together.
  Future<Either<Failure, OrderCounts>> statusCounts({String? search, int? customerId});

  Future<Either<Failure, Order>> order(int orderId);

  /// Takes an order, and answers with the one the server stored.
  ///
  /// The answer matters rather than a bare success: it carries the number the server allocated
  /// — plain digits, `52` — and the totals it worked out from the lines and the destination.
  /// Nothing the app added up is in it.
  Future<Either<Failure, Order>> create(NewOrder order);

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
  /// [lines] null leaves the order's own lines alone — which is how an edit that only moves
  /// the destination is expressed, on an order whose lines are already closed.
  ///
  /// [cityId] null keeps the address as it is; anything else re-addresses the order, and the
  /// server re-snapshots the city's name and re-prices the delivery from it.
  Future<Either<Failure, Order>> updateInvoice(
    int orderId, {
    List<InvoiceLineUpdate>? lines,
    String? discount,
    int? cityId,
    int? regionId,
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
