import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/payment_settlement.dart';
import 'package:dayaa/features/orders/repositories/order_payment_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [OrderPaymentRepository] over HTTP.
///
/// The fact that a receipt travels as `multipart/form-data` under the key `receipt`, and that an
/// amount is a decimal *string* on the wire, never leaves this file.
class OrderPaymentRepositoryImpl implements OrderPaymentRepository {
  const OrderPaymentRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, OrderLedger>> ledger(int orderId) {
    return safeRequest<OrderLedger>(
      () => _dio.get(OrderEndpoints.payments(orderId)),
      // `safeRequest`, not `safePaginatedRequest`: an order's ledger comes back whole, with no
      // `meta` beside it. An order has a handful of entries, and a page boundary through a
      // ledger would hide the reversal that explains the row above it.
      parse: (data) => OrderLedger.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
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
  }) {
    return _write(
      OrderEndpoints.payments(orderId),
      amount: amount,
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

  @override
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
  }) {
    return _write(
      OrderEndpoints.refundPayment(orderId),
      amount: amount,
      method: method,
      reference: reference,
      paidAt: paidAt,
      notes: notes,
      receiptPath: receiptPath,
      receiptFilename: receiptFilename,
      treasuryAccountId: treasuryAccountId,
    );
  }

  @override
  Future<Either<Failure, PaymentResult>> reverse(
    int orderId,
    int paymentId, {
    required String reason,
  }) {
    return safeRequest<PaymentResult>(
      () => _dio.post(
        OrderEndpoints.reversePayment(orderId, paymentId),
        // No amount and no method: the reversal carries its original's, and no money moved.
        data: <String, dynamic>{'reason': reason.trim()},
      ),
      parse: _result,
    );
  }

  @override
  Future<Either<Failure, PaymentResult>> writeOff(
    int orderId, {
    required String amount,
    required String reason,
  }) {
    return safeRequest<PaymentResult>(
      () => _dio.post(
        OrderEndpoints.writeOffPayment(orderId),
        // Plain JSON rather than the `FormData` the two above use: there is no file here, and
        // no method or date either — nothing moved to have one.
        data: <String, dynamic>{'amount': amount, 'reason': reason.trim()},
      ),
      parse: _result,
    );
  }

  @override
  Future<Either<Failure, OrderPayment>> review(
    int orderId,
    int paymentId, {
    required bool reviewed,
  }) {
    return safeRequest<OrderPayment>(
      () => _dio.patch(
        OrderEndpoints.reviewPayment(orderId, paymentId),
        data: <String, dynamic>{'reviewed': reviewed},
      ),
      parse: (data) =>
          OrderPayment.fromJson((data! as Map<String, dynamic>)['payment'] as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Paginated<OrderPayment>>> reviewQueue({
    required int page,
    OrderPaymentType? type,
    int? accountId,
    DateTime? from,
    DateTime? to,
    String? search,
  }) {
    return safePaginatedRequest<OrderPayment>(
      () => _dio.get(
        OrderEndpoints.paymentReviewQueue,
        queryParameters: {
          'page': page,
          // The two kinds of entry a review covers; anything else is not sent.
          if (type == OrderPaymentType.payment) 'type': 'payment',
          if (type == OrderPaymentType.refund) 'type': 'refund',
          'account_id': ?accountId,
          if (from != null) 'from': _day(from),
          if (to != null) 'to': _day(to),
          if (search != null && search.trim().isNotEmpty) 'q': search.trim(),
        },
      ),
      parseItem: OrderPayment.fromJson,
    );
  }

  @override
  Future<Either<Failure, Paginated<OrderPayment>>> settlementQueue({
    required int page,
    required SettlementState state,
    DateTime? from,
    DateTime? to,
    int? accountId,
    String? search,
  }) {
    return safePaginatedRequest<OrderPayment>(
      () => _dio.get(
        OrderEndpoints.paymentSettlementQueue,
        queryParameters: {
          'page': page,
          'state': state.wire,
          if (from != null) 'from': _day(from),
          if (to != null) 'to': _day(to),
          'account_id': ?accountId,
          if (search != null && search.trim().isNotEmpty) 'q': search.trim(),
        },
      ),
      parseItem: OrderPayment.fromJson,
    );
  }

  @override
  Future<Either<Failure, SettlementAccounts>> settlementAccounts() {
    return safeRequest<SettlementAccounts>(
      () => _dio.get(OrderEndpoints.paymentSettlementAccounts),
      parse: (data) => SettlementAccounts.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, List<OrderPayment>>> settle(List<SettleRow> rows, {int? accountId}) {
    return safeRequest<List<OrderPayment>>(
      () => _dio.post(
        OrderEndpoints.settlePayments,
        data: <String, dynamic>{
          'payments': [for (final row in rows) row.toJson()],
          // Absent rather than null: each payment then goes to its own automatic account.
          'account_id': ?accountId,
        },
      ),
      parse: (data) => [
        for (final row in ((data! as Map<String, dynamic>)['payments'] as List<dynamic>))
          OrderPayment.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  @override
  Future<Either<Failure, OrderPayment>> unsettle(
    int orderId,
    int paymentId, {
    required String reason,
  }) {
    return safeRequest<OrderPayment>(
      () => _dio.post(
        OrderEndpoints.unsettlePayment(orderId, paymentId),
        data: <String, dynamic>{'reason': reason.trim()},
      ),
      parse: (data) =>
          OrderPayment.fromJson((data! as Map<String, dynamic>)['payment'] as Map<String, dynamic>),
    );
  }

  /// A plain day, as the list filters take it. The phone's own calendar day — where that day
  /// begins is the server's business.
  static String _day(DateTime at) =>
      '${at.year.toString().padLeft(4, '0')}-${at.month.toString().padLeft(2, '0')}-'
      '${at.day.toString().padLeft(2, '0')}';

  /// The two write paths differ only in their URL, so they share everything below it.
  ///
  /// **Always `FormData`, receipt or not.** A body that changed shape depending on whether a
  /// file was attached would be two request formats to get right, and Laravel reads a
  /// multipart body with no file exactly as it reads a JSON one.
  Future<Either<Failure, PaymentResult>> _write(
    String path, {
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
    return safeRequest<PaymentResult>(
      () async => _dio.post(
        path,
        data: FormData.fromMap(<String, dynamic>{
          'amount': amount,
          'method': method.wire,
          // Omitted rather than sent empty: `nullable|string` on the server treats `''` as a
          // present-but-blank value, and a blank reference is not the same fact as no reference.
          if (reference != null && reference.trim().isNotEmpty) 'reference': reference.trim(),
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
          // **UTC, and the server refuses the future.** A phone whose clock runs a minute fast
          // would otherwise have every «الآن» rejected as a payment that has not happened yet,
          // which is why this is only sent when a date was deliberately chosen.
          if (paidAt != null) 'paid_at': paidAt.toUtc().toIso8601String(),
          // حين يختاره أحدٌ فقط: غائباً تقرّر الخزينة — حساب صاحب الدفعة، وإلا افتراضي
          // الطريقة (TREASURY-DESIGN §٥).
          'treasury_account_id': ?treasuryAccountId,
          // Only when it was asked and answered — a multipart body carries no booleans, and `1`
          // is what Laravel's `boolean` rule reads as yes.
          if (acceptOverpayment) 'accept_overpayment': '1',
          // `fromFile` streams from disk rather than holding the file in memory. The fallback
          // name claims no extension on purpose: the server sniffs the bytes and would record
          // a made-up `.pdf` as the original name of what might be a photograph.
          if (receiptPath != null)
            'receipt': await MultipartFile.fromFile(
              receiptPath,
              filename: receiptFilename ?? 'receipt',
            ),
        }),
      ),
      parse: _result,
    );
  }

  PaymentResult _result(Object? data) {
    final body = data! as Map<String, dynamic>;

    return PaymentResult(
      payment: OrderPayment.fromJson(body['payment'] as Map<String, dynamic>),
      summary: PaymentSummary.fromJson(body['summary'] as Map<String, dynamic>),
    );
  }
}
