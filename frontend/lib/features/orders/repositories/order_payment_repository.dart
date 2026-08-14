import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';

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
  Future<Either<Failure, PaymentResult>> record(
    int orderId, {
    required String amount,
    required PaymentMethod method,
    String? reference,
    DateTime? paidAt,
    String? notes,
    String? receiptPath,
    String? receiptFilename,
  });

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
}

/// What a write to the ledger answers with: the entry, and the order's money after it.
class PaymentResult {
  const PaymentResult({required this.payment, required this.summary});

  final OrderPayment payment;
  final PaymentSummary summary;
}
