// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/orders/models/additional_cost_reason.dart';
import 'package:dayaa/features/orders/models/line_shortage_entry.dart';
import 'package:dayaa/features/orders/models/new_order.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_counts.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/models/orders_sort.dart';
import 'package:dayaa/features/orders/models/production_cost_entry.dart';
import 'package:dayaa/features/orders/usecases/update_order_invoice.dart';

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
  ///
  /// [readyMessageSent] `false` is **the queue**, not the column's negation: the server answers
  /// with the orders that have reached «جاهزة», have not been delivered, settled or cancelled,
  /// and that nobody has marked as messaged. `true` is the plain question, «أيّها أُبلِغ
  /// أصحابها؟». Null asks neither. See ORDER-READY-MESSAGE.md §٥ — the rule is the server's, and
  /// a copy of it here is the copy that drifts.
  Future<Either<Failure, Paginated<Order>>> orders({
    String? search,
    List<String> statuses,
    List<String> paymentStatuses,
    bool? isUrgent,
    bool? readyMessageSent,
    OrdersSort sort,
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

  /// The same page, taken from الأرشيف — the orders that were deleted.
  ///
  /// **Its own method rather than a flag on [orders]**, because it is its own route: the server
  /// declares `orders/archive` before the resource so the word is not read as an id, and the
  /// three queries behind the list and its two rows of counters are seeded separately. A flag
  /// threaded through one of them is how the chips end up describing a different set from the
  /// rows under them — see §٦.
  ///
  /// Takes every filter [orders] takes, and that is the point: الأرشيف is the orders screen
  /// with a different source, so «المحذوفة الجاهزة غير المدفوعة» has to be askable there too.
  Future<Either<Failure, Paginated<Order>>> archivedOrders({
    String? search,
    List<String> statuses,
    List<String> paymentStatuses,
    bool? isUrgent,
    bool? readyMessageSent,
    OrdersSort sort,
    int? customerId,
    String? from,
    String? to,
    int page,
    int perPage,
  });

  /// [statusCounts] over the archive. Separate for the same reason [archivedOrders] is.
  Future<Either<Failure, OrderCounts>> archivedStatusCounts({String? search, int? customerId});

  Future<Either<Failure, Order>> order(int orderId);

  /// Archives an order, and answers with it as the server left it — trashed.
  ///
  /// **Not «إلغاء تام», and the table in §١ is the whole distinction.** A cancellation says the
  /// order happened and ended without a delivery; this says it should never have been written —
  /// a duplicate entry, a wrong number, a test. So the goods it drew go back on the shelf, and
  /// the order leaves every list but الأرشيف.
  ///
  /// **It is refused on an order that has money on it or a parcel open at the carrier**, and
  /// both refusals arrive as the server's own Arabic naming what to do first. Neither is
  /// re-derived here: the app would be guessing at a ledger it does not hold and at a parcel
  /// only Nawris can close.
  ///
  /// The order comes back rather than a bare success, for the reason [changeStatus] does: it
  /// carries `deleted_at`, and it has *lost* `available_transitions` and `progress`, so the row
  /// the list is handed is already the archived one.
  Future<Either<Failure, Order>> deleteOrder(int orderId);

  /// Puts an archived order back in the shop, and answers with it live again.
  ///
  /// **The stock is deducted a second time**, which is exactly what «تراجع عن الإلغاء» refuses
  /// to do — see [reinstate]. The two are undoing different things: a cancellation is a real
  /// event that credited the goods back, while an archive is the claim that the order was never
  /// real, so it has to come back the way it left, with its stock drawn. The price is that the
  /// new deduction eats today's cost layers and the order returns costing something else; the
  /// server says so in `stock_effect.note` and the dialog shows it.
  ///
  /// Refused when the balance is short, or when the order's warehouse has since been retired —
  /// again in the server's own words, because «كل المقاسات صفر» is what an app that guessed
  /// would say about a store that no longer exists.
  Future<Either<Failure, Order>> restoreOrder(int orderId);

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
  ///
  /// [recipientPhone] is a record rather than a bare `String?` because two different intentions
  /// have to be expressible and `null` can only carry one of them: **absent** leaves the number
  /// alone, while `(number: null)` *clears* it — a wrong number deleted is a real edit, and
  /// omitting the field on a `PUT` is how the API is told so.
  ///
  /// [additionalCost] and its two companions travel together or not at all: sending an amount
  /// with no reason is a 422, and so is sending an unchanged amount back on an edit that was
  /// only about the address if its reason is dropped on the way. Absent means «leave the charge
  /// as it is», and the implementation echoes the order's own three fields back.
  Future<Either<Failure, Order>> updateInvoice(
    int orderId, {
    List<InvoiceLineUpdate>? lines,
    String? discount,
    int? cityId,
    int? regionId,
    ({String? number})? recipientPhone,
    String? additionalCost,
    AdditionalCostReason? additionalCostReason,
    String? additionalCostNote,
    bool? isUrgent,
  });

  /// Undoes a cancellation made by mistake, and answers with the order as the server left it.
  ///
  /// **There is no destination to pass, and that is the rule rather than an omission.** The
  /// server puts the order back in the status its own timeline says it was cancelled from; an
  /// undo that let the caller name one would be a second way into statuses the state machine
  /// makes unreachable from «إلغاء تام». [reason] is an optional note on the row.
  ///
  /// No stock moves either way: the cancellation already credited the goods back to the shelf,
  /// and putting the warehouse right afterwards is done by hand.
  Future<Either<Failure, Order>> reinstate(int orderId, {String? reason});

  /// Takes a settled order back to «تم الاستلام». [reason] is required by the server.
  Future<Either<Failure, Order>> unsettle(int orderId, {required String reason});

  /// Takes back a delivery recorded by mistake — the order goes back where it was delivered
  /// from, and the investors' profit comes off with it. [reason] is required by the server.
  Future<Either<Failure, Order>> undoDelivery(int orderId, {required String reason});

  /// [fields] is whatever the chosen transition asked for, keyed as the server described it —
  /// see `TransitionField`. Nothing here knows what those keys mean.
  Future<Either<Failure, Order>> changeStatus(
    int orderId, {
    required OrderStatus status,
    String? reason,
    Map<String, Object?> fields,
  });

  /// Records what is missing from each line, and therefore what the order costs.
  ///
  /// **The set is replaced.** [shortages] is line id → what is missing, and a null clears one —
  /// which is how a shortage is un-recorded and the invoice put back. A line left out of the map
  /// is cleared too, so callers send every line they showed.
  Future<Either<Failure, Order>> setShortages(
    int orderId, {
    required Map<int, LineShortageEntry> shortages,
  });

  /// Records that the customer was told their order is ready — or takes that back.
  ///
  /// **The message itself is sent elsewhere**, on WhatsApp or by telephone, so this records
  /// nothing but an employee saying they sent it. The order comes back rather than a bare
  /// success, for the reason [changeStatus] does: it carries who was stamped on it and when, and
  /// the screen has no way to invent either.
  ///
  /// Refused with the server's own Arabic before the order has ever been «جاهزة» — a refusal
  /// nobody should meet, because `Order.readyMessageApplies` says so in advance.
  Future<Either<Failure, Order>> confirmReadyMessage(int orderId, {required bool sent});

  /// Records that the عربون actually arrived — or takes that back.
  ///
  /// **A second person's tick over somebody else's claim.** Moving an order to «عربون مدفوع»
  /// says the customer paid; this says the shop has seen it. The order comes back rather than a
  /// bare success, for the reason [confirmReadyMessage] does: it carries who was stamped on it
  /// and when, and the screen cannot invent either.
  ///
  /// Two refusals, both in the server's own Arabic and both unreachable from a correct screen —
  /// `Order.canConfirmDeposit` and `Order.depositExpectedAmount` answer them in advance: the
  /// claimer may not confirm their own claim, and an order with no عربون has nothing to confirm.
  Future<Either<Failure, Order>> confirmDepositReceipt(int orderId, {required bool received});

  /// Writes off bags spoiled while this line was being produced.
  ///
  /// **The cost is not sent, it comes back.** [quantity] is what the storekeeper counted; the
  /// server draws it off the order's own shelf, reads what those particular bags cost out of the
  /// batches they came from, and answers with the entry it wrote. There is no unit price on this
  /// call and adding one would be inventing a number the batches already know.
  ///
  /// [notes] is required by the API and by this app's own form — the reason is the whole point of
  /// the record, and «تلف» on its own is a row nobody can act on a month later.
  ///
  /// **Nothing on the order moves.** The line keeps the cost of what it actually fulfilled, so
  /// `total_cogs` and the gross profit beside it are the same afterwards; what changes is the
  /// warehouse balance.
  Future<Either<Failure, ProductionCostEntry>> recordScrapLoss(
    int orderId,
    int itemId, {
    required String quantity,
    required String notes,
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
