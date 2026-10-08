import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/payment_settlement.dart';
import 'package:dayaa/features/orders/repositories/order_payment_repository.dart';

/// Reading an order's ledger.
class GetOrderLedger {
  const GetOrderLedger(this._repository);

  final OrderPaymentRepository _repository;

  Future<Either<Failure, OrderLedger>> call(int orderId) => _repository.ledger(orderId);
}

/// Taking money from a customer.
///
/// **The amount is normalised here and nowhere else.** Arabic-Indic digits (`٥٠`) are what a
/// phone keyboard set to Arabic produces, and `num.parse` refuses them — so a clerk typing the
/// number they see would be told the amount is not a number. Converted once, on the way in.
class RecordOrderPayment {
  const RecordOrderPayment(this._repository);

  final OrderPaymentRepository _repository;

  Future<Either<Failure, PaymentResult>> call(
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
  }) {
    return _repository.record(
      orderId,
      amount: normaliseAmount(amount),
      method: method,
      reference: reference,
      paidAt: paidAt,
      notes: notes,
      receiptPath: receiptPath,
      receiptFilename: receiptFilename,
      treasuryAccountId: treasuryAccountId,
      acceptOverpayment: acceptOverpayment,
    );
  }
}

/// Handing money back.
class RefundOrderPayment {
  const RefundOrderPayment(this._repository);

  final OrderPaymentRepository _repository;

  Future<Either<Failure, PaymentResult>> call(
    int orderId, {
    required String amount,
    required PaymentMethod method,
    String? reference,
    DateTime? paidAt,
    String? notes,
    String? receiptPath,
    String? receiptFilename,
    int? treasuryAccountId,
  }) {
    return _repository.refund(
      orderId,
      amount: normaliseAmount(amount),
      method: method,
      reference: reference,
      paidAt: paidAt,
      notes: notes,
      receiptPath: receiptPath,
      receiptFilename: receiptFilename,
      treasuryAccountId: treasuryAccountId,
    );
  }
}

/// Cancelling an entry that should never have been written.
///
/// The reason is trimmed for the same cause as everywhere else: a sentence of spaces satisfies a
/// required check and tells the next reader nothing. The server refuses a blank one, and that
/// refusal is the honest ending.
class ReverseOrderPayment {
  const ReverseOrderPayment(this._repository);

  final OrderPaymentRepository _repository;

  Future<Either<Failure, PaymentResult>> call(
    int orderId,
    int paymentId, {
    required String reason,
  }) => _repository.reverse(orderId, paymentId, reason: reason.trim());
}

/// Closing what is left of a debt nobody is going to collect.
///
/// The amount is normalised like every other one on this screen, and the reason is trimmed for
/// the reason a reversal's is: a sentence of spaces satisfies a required check and tells the
/// next reader nothing.
class WriteOffOrderBalance {
  const WriteOffOrderBalance(this._repository);

  final OrderPaymentRepository _repository;

  Future<Either<Failure, PaymentResult>> call(
    int orderId, {
    required String amount,
    required String reason,
  }) => _repository.writeOff(orderId, amount: normaliseAmount(amount), reason: reason.trim());
}

/// «مراجعة الدفعة» — a check on an entry, or taking it back.
class ReviewOrderPayment {
  const ReviewOrderPayment(this._repository);

  final OrderPaymentRepository _repository;

  Future<Either<Failure, OrderPayment>> call(
    int orderId,
    int paymentId, {
    required bool reviewed,
  }) => _repository.review(orderId, paymentId, reviewed: reviewed);
}

/// A page of the entries still waiting for a review, across all orders.
class GetPaymentReviewQueue {
  const GetPaymentReviewQueue(this._repository);

  final OrderPaymentRepository _repository;

  Future<Either<Failure, Paginated<OrderPayment>>> call({
    required int page,
    OrderPaymentType? type,
    int? accountId,
    DateTime? from,
    DateTime? to,
    String? search,
  }) => _repository.reviewQueue(
    page: page,
    type: type,
    accountId: accountId,
    from: from,
    to: to,
    search: search,
  );
}

/// «تسوية الدفعات» — a page of waiting or settled payments. TREASURY-DESIGN §٢٣.
class GetPaymentSettlementQueue {
  const GetPaymentSettlementQueue(this._repository);

  final OrderPaymentRepository _repository;

  Future<Either<Failure, Paginated<OrderPayment>>> call({
    required int page,
    required SettlementState state,
    DateTime? from,
    DateTime? to,
    int? accountId,
    String? search,
  }) => _repository.settlementQueue(
    page: page,
    state: state,
    from: from,
    to: to,
    accountId: accountId,
    search: search,
  );
}

/// Where payments wait, and where they may be settled to.
class GetSettlementAccounts {
  const GetSettlementAccounts(this._repository);

  final OrderPaymentRepository _repository;

  Future<Either<Failure, SettlementAccounts>> call() => _repository.settlementAccounts();
}

/// «تسوية دفعة» — one or several payments, all or nothing. A fee is typed money: its digits are
/// cleaned like any amount's.
class SettleOrderPayments {
  const SettleOrderPayments(this._repository);

  final OrderPaymentRepository _repository;

  Future<Either<Failure, List<OrderPayment>>> call(List<SettleRow> rows, {int? accountId}) =>
      _repository.settle(
        [
          for (final row in rows)
            SettleRow(
              paymentId: row.paymentId,
              fee: row.fee == null || row.fee!.trim().isEmpty ? null : normaliseAmount(row.fee!),
            ),
        ],
        accountId: accountId,
      );
}

/// Takes a payment's settlement back, with a reason.
class UnsettleOrderPayment {
  const UnsettleOrderPayment(this._repository);

  final OrderPaymentRepository _repository;

  Future<Either<Failure, OrderPayment>> call(
    int orderId,
    int paymentId, {
    required String reason,
  }) => _repository.unsettle(orderId, paymentId, reason: reason.trim());
}

/// Turns what somebody typed into the decimal string the API takes.
///
/// Two things happen, both for the same reason — the number that leaves this phone must be the
/// number the clerk read out to the customer:
///
/// 1. **Arabic-Indic digits become Western ones.** `٥٠` is what an Arabic keyboard produces, and
///    the server's `numeric` rule refuses them.
/// 2. **The Arabic decimal separator becomes a point.** `٥٠٫٥` means 50.5.
///
/// **Nothing is parsed to a `double`.** The string is cleaned and passed on; the server does the
/// arithmetic in exact decimals, and a round trip through binary floating point is how `50.05`
/// becomes `50.049999999999997`.
///
/// **A comma is dropped, never read as a decimal point**, and that is a deliberate refusal to be
/// clever. `1,500` is a thousands separator to most people who type it and a decimal separator
/// to some, and guessing wrong turns fifteen hundred dinars into one and a half. Dropping it
/// reads `1,500` as `1500`, which is what the person who typed it meant; the *field* is what
/// stops a comma being typed at all — see the amount input's formatter — so this is the second
/// line of defence rather than the first.
String normaliseAmount(String input) {
  const arabicIndic = '٠١٢٣٤٥٦٧٨٩';

  final buffer = StringBuffer();

  for (final rune in input.trim().runes) {
    final char = String.fromCharCode(rune);
    final indic = arabicIndic.indexOf(char);

    if (indic != -1) {
      buffer.write(indic);
    } else if (char == '٫' || char == '.') {
      buffer.write('.');
    } else if (RegExp(r'\d').hasMatch(char)) {
      buffer.write(char);
    }
  }

  return buffer.toString();
}
