import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/usecases/manage_order_payments.dart';

/// «مراجعة الدفعات» — every payment and refund still waiting for a check, across
/// all orders, oldest first. The reviewer's work list.
///
/// **A reviewed row leaves at once**, dropped locally rather than by re-reading: the person is
/// working down the list, and a re-read would throw them back to the top of it. The count under
/// the tab moves with it — [PagedCubit] keeps `total` honest on every local patch.
class PaymentReviewQueueCubit extends PagedCubit<OrderPayment> {
  PaymentReviewQueueCubit({
    required GetPaymentReviewQueue getQueue,
    required ReviewOrderPayment reviewPayment,
  }) : _getQueue = getQueue,
       _reviewPayment = reviewPayment;

  final GetPaymentReviewQueue _getQueue;
  final ReviewOrderPayment _reviewPayment;

  /// Payments, refunds, or — null — both.
  OrderPaymentType? type;

  /// How many entries wait, on the whole filtered queue rather than this page. Null before the
  /// server has answered.
  int? get waiting => switch (state) {
    PagedLoaded(:final page) => page.meta.total,
    _ => null,
  };

  Future<void> showType(OrderPaymentType? value) {
    if (value == type) return Future<void>.value();

    type = value;

    return load();
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
    return _getQueue(page: page, type: type);
  }
}

typedef PaymentReviewQueueState = PagedState<OrderPayment>;
