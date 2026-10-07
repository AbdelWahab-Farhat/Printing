import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/payment_settlement.dart';

/// What the app can ask about an order's money, stated without saying how.
///
/// **There is no `update` and no `delete` here, and there never will be.** The API has no such
/// route: an entry is written once, and a mistake is undone by [reverse], which writes a second
/// entry beside the wrong one and leaves both readable. A method to edit one could only be
/// written by somebody who had decided to stop believing the ledger.
///
/// Its own repository rather than four more methods on `OrderRepository`, because it is guarded
/// by its own permissions: a screen that may read an order may not be allowed to read its money.
abstract interface class OrderPaymentRepository {
  /// The order's entries, oldest first, with the summary as it stands after them.
  Future<Either<Failure, OrderLedger>> ledger(int orderId);

  /// Money taken from the customer.
  ///
  /// [receiptPath] is a PDF on this device — **required when the method is a transfer**, which
  /// [PaymentMethod.requiresReceipt] answers before the request is sent. The server refuses one
  /// without it either way; asking here is what puts the file field in front of somebody while
  /// the customer is still at the counter.
  ///
  /// Answers with the entry *and* the order's money after it, so the screen never has to
  /// re-fetch the order to learn what the entry it just wrote did to the total.
  ///
  /// [acceptOverpayment] is the yes to «المبلغ يزيد على المتبقي — تسجيل الزائد للزبون؟». Without
  /// it the server refuses an amount beyond the debt; with it the part beyond is owed back.
  Future<Either<Failure, PaymentResult>> record(
    int orderId, {
    required String amount,
    required PaymentMethod method,
    String? reference,
    DateTime? paidAt,
    String? notes,
    String? receiptPath,
    String? receiptFilename,
    int? treasuryAccountId,
    bool acceptOverpayment = false,
  });

  /// «اعتبار الزائد إيراداً» — the whole excess the order holds is the shop's now. No amount: a
  /// part handed back is a [refund] first. No cash moves; undone by [reverse].
  Future<Either<Failure, PaymentResult>> keepExcess(int orderId, {String? notes});

  /// Money genuinely handed back.
  ///
  /// **Not the way to fix a mistyped entry** — that is [reverse]. The two subtract the same
  /// figure and answer different questions, and only one of them is a cash event.
  Future<Either<Failure, PaymentResult>> refund(
    int orderId, {
    required String amount,
    required PaymentMethod method,
    String? reference,
    DateTime? paidAt,
    String? notes,
    String? receiptPath,
    String? receiptFilename,
    int? treasuryAccountId,
  });

  /// Cancels an entry that should never have been written.
  ///
  /// No amount: a reversal always carries its original's, because a partial undo is not an undo.
  /// [reason] is required by the server — taking money back off an order owes the next reader an
  /// explanation.
  Future<Either<Failure, PaymentResult>> reverse(
    int orderId,
    int paymentId, {
    required String reason,
  });

  /// Closes what is left of the order's debt without any money moving.
  ///
  /// **Not a payment and not a discount.** The order goes on saying what the customer was
  /// billed; the difference is recorded as a difference, so it stays countable later as a loss.
  ///
  /// No method and no date: nothing moved to have a method, and the decision is dated when it is
  /// taken. [reason] is required, as it is for [reverse], and the server bounds [amount] by what
  /// the order actually still owes.
  ///
  /// A write-off decided in error is undone by [reverse], which puts the debt back where it was.
  Future<Either<Failure, PaymentResult>> writeOff(
    int orderId, {
    required String amount,
    required String reason,
  });

  /// «مراجعة الدفعة» — somebody with the grant saying the entry is right, or ([reviewed] false)
  /// taking that back. Moves no money. Their own entries included; refused only on a reversed or
  /// exempt entry, which the entry's own `can_review` says before anybody asks.
  Future<Either<Failure, OrderPayment>> review(
    int orderId,
    int paymentId, {
    required bool reviewed,
  });

  /// Every payment and refund still waiting for a review, across all orders, oldest first.
  ///
  /// `extraMeta` carries `incoming_total` and `outgoing_total` — what the whole filtered queue
  /// adds up to, money in and money out apart.
  Future<Either<Failure, Paginated<OrderPayment>>> reviewQueue({
    required int page,
    OrderPaymentType? type,
    int? accountId,
  });

  /// «تسوية الدفعات» — waiting or settled payments. `extraMeta['amount_total']` is what the whole
  /// filtered list adds up to. TREASURY-DESIGN §٢٣.
  Future<Either<Failure, Paginated<OrderPayment>>> settlementQueue({
    required int page,
    required SettlementState state,
    DateTime? from,
    DateTime? to,
    int? accountId,
    String? search,
  });

  /// Where payments wait, and where they may be settled to.
  Future<Either<Failure, SettlementAccounts>> settlementAccounts();

  /// One or several payments' money to the account it reached, all or nothing. [accountId]
  /// null: each to its own automatic account.
  Future<Either<Failure, List<OrderPayment>>> settle(List<SettleRow> rows, {int? accountId});

  /// Takes a payment's settlement back; its money returns to where it landed.
  Future<Either<Failure, OrderPayment>> unsettle(
    int orderId,
    int paymentId, {
    required String reason,
  });
}

/// What a write to the ledger answers with: the entry, and the order's money after it.
class PaymentResult {
  const PaymentResult({required this.payment, required this.summary});

  final OrderPayment payment;
  final PaymentSummary summary;
}
