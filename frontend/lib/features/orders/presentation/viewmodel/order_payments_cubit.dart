import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/repositories/order_payment_repository.dart';
import 'package:dayaa/features/orders/usecases/manage_order_payments.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_payments_cubit.freezed.dart';
part 'order_payments_state.dart';

/// One order's money: the ledger, and the four ways of writing to it.
///
/// **It owns the ledger and nothing else owns it.** The order's own payload deliberately does not
/// carry the entries — they are behind a permission the order screen's reader may not hold — so
/// there is exactly one place in the app that has them, and no second copy to fall out of date.
///
/// **Every write is applied from what the server answered, not from what was sent.** A payment
/// comes back with the order's money as it now stands, so the three numbers on screen are the
/// server's arithmetic after the entry rather than this app's guess at it. The ledger is re-read
/// alongside, because a reversal changes a row it did not return: the entry it struck through.
///
/// Registered as a factory with the order's id as `param1`, like [OrderDetailCubit] — a screen
/// Cubit held as a singleton would close on the first order and leave every one after it
/// emitting into a dead stream.
class OrderPaymentsCubit extends Cubit<OrderPaymentsState> {
  OrderPaymentsCubit({
    required int orderId,
    required GetOrderLedger getLedger,
    required RecordOrderPayment recordPayment,
    required RefundOrderPayment refundPayment,
    required ReverseOrderPayment reversePayment,
    required WriteOffOrderBalance writeOffBalance,
  }) : _orderId = orderId,
       _getLedger = getLedger,
       _recordPayment = recordPayment,
       _refundPayment = refundPayment,
       _reversePayment = reversePayment,
       _writeOffBalance = writeOffBalance,
       super(const OrderPaymentsState.loading());

  final int _orderId;
  final GetOrderLedger _getLedger;
  final RecordOrderPayment _recordPayment;
  final RefundOrderPayment _refundPayment;
  final ReverseOrderPayment _reversePayment;
  final WriteOffOrderBalance _writeOffBalance;

  Future<void> load() async {
    // Keeps whatever is on screen: this is also the pull-to-refresh path, and blanking the
    // ledger to a spinner on every pull makes the gesture feel like leaving the screen.
    if (state.ledger == null) emit(const OrderPaymentsState.loading());

    final result = await _getLedger(_orderId);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => OrderPaymentsState.failure(failure: failure, ledger: state.ledger),
        (ledger) => OrderPaymentsState.loaded(ledger: ledger),
      ),
    );
  }

  /// Takes money from the customer.
  ///
  /// Answers with the failure rather than parking it in the state: the sheet that called this is
  /// still open and is where the message belongs — beside the field the server named.
  Future<Failure?> record({
    required String amount,
    required PaymentMethod method,
    String? reference,
    DateTime? paidAt,
    String? notes,
    String? receiptPath,
    String? receiptFilename,
  }) {
    return _write(
      () => _recordPayment(
        _orderId,
        amount: amount,
        method: method,
        reference: reference,
        paidAt: paidAt,
        notes: notes,
        receiptPath: receiptPath,
        receiptFilename: receiptFilename,
      ),
    );
  }

  /// Hands money back.
  Future<Failure?> refund({
    required String amount,
    required PaymentMethod method,
    String? reference,
    DateTime? paidAt,
    String? notes,
    String? receiptPath,
    String? receiptFilename,
  }) {
    return _write(
      () => _refundPayment(
        _orderId,
        amount: amount,
        method: method,
        reference: reference,
        paidAt: paidAt,
        notes: notes,
        receiptPath: receiptPath,
        receiptFilename: receiptFilename,
      ),
    );
  }

  /// Cancels an entry that should never have been written.
  Future<Failure?> reverse(int paymentId, {required String reason}) =>
      _write(() => _reversePayment(_orderId, paymentId, reason: reason));

  /// Closes what is left of the debt without any money moving.
  ///
  /// Goes through the same path the other three do, so the summary on screen after it is the
  /// server's arithmetic rather than this app's guess — and the settlement guard on the order
  /// screen is reading the same number.
  Future<Failure?> writeOff({required String amount, required String reason}) =>
      _write(() => _writeOffBalance(_orderId, amount: amount, reason: reason));

  /// The shape every write shares: mark the screen busy, run it, re-read, report.
  ///
  /// **Re-read rather than appending what came back.** A payment could be appended safely; a
  /// reversal could not — it strikes through a row it does not return, and the entry above it
  /// stops being reversible. One path for all four is one fewer place for the ledger on screen
  /// to differ from the ledger in the database.
  Future<Failure?> _write(Future<Either<Failure, PaymentResult>> Function() write) async {
    final ledger = state.ledger;
    if (ledger != null) emit(OrderPaymentsState.loaded(ledger: ledger, isWorking: true));

    final result = await write();

    if (isClosed) return null;

    await load();

    return result.fold((failure) => failure, (_) => null);
  }
}
