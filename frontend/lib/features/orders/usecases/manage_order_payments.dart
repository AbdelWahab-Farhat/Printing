import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
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
