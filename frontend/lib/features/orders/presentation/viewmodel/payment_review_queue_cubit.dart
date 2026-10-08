import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/payment_settlement.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/payment_period_filter.dart';
import 'package:dayaa/features/orders/usecases/manage_order_payments.dart';

/// «مراجعة الدفعات» — every payment and refund still waiting for a check, across
/// all orders, oldest first. The reviewer's work list.
///
/// **«تحتاج مراجعة» in «مراجعة وتسوية الدفعات»** (2026-10-08): narrowed like the settlement list —
/// the period chips on «الكل» ([PaymentPeriodFilter]), the search box (order code or customer),
/// and in the advanced filter «من» / «إلى» and payments or refunds.
///
/// **A reviewed row leaves at once**, dropped locally rather than by re-reading: the person is
/// working down the list, and a re-read would throw them back to the top of it. The count under
/// the tab moves with it — [PagedCubit] keeps `total` honest on every local patch.
class PaymentReviewQueueCubit extends PagedCubit<OrderPayment> with PaymentPeriodFilter {
  PaymentReviewQueueCubit({
    required GetPaymentReviewQueue getQueue,
    required ReviewOrderPayment reviewPayment,
    DateTime Function()? now,
  }) : _getQueue = getQueue,
       _reviewPayment = reviewPayment,
       _now = now ?? DateTime.now;

  final GetPaymentReviewQueue _getQueue;
  final ReviewOrderPayment _reviewPayment;
  final DateTime Function() _now;

  @override
  DateTime clock() => _now();

  /// Payments, refunds, or — null — both. Set from the advanced filter.
  OrderPaymentType? type;

  /// Whether the advanced filter narrows the list — what lights its button.
  bool get hasAdvanced => period == SettlementPeriod.custom || type != null;

  /// How many entries wait, on the whole filtered queue rather than this page. Null before the
  /// server has answered.
  int? get waiting => switch (state) {
    PagedLoaded(:final page) => page.meta.total,
    _ => null,
  };

  /// «تطبيق» in the advanced filter: «من» / «إلى» and the type, in one load. What is typed in
  /// the search box stays.
  Future<void> applyAdvanced({DateTime? from, DateTime? to, OrderPaymentType? type}) {
    adoptDates(from: from, to: to);
    this.type = type;

    return load(search: currentSearch);
  }

  /// Marks [payment] reviewed and drops it from the list. Answers with the failure — the
  /// server's own Arabic, «لا يمكن لمن سجّل الدفعة أن يراجعها» and the like — for the screen to
  /// show.
  Future<Failure?> review(OrderPayment payment) async {
    final result = await _reviewPayment(payment.orderId, payment.id, reviewed: true);

    return result.fold((failure) => failure, (_) {
      removeById(payment.id);

      return null;
    });
  }

  @override
  Object identityOf(OrderPayment item) => item.id;

  @override
  Future<Either<Failure, Paginated<OrderPayment>>> fetchPage({String? search, required int page}) {
    final shown = range;

    return _getQueue(page: page, type: type, from: shown?.from, to: shown?.to, search: search);
  }
}

typedef PaymentReviewQueueState = PagedState<OrderPayment>;
