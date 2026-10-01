import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/treasury/models/vendor_payment.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «المدفوع للمورد» على أمر شراء — الإجمالي والمدفوع والمتبقي، والدفعات. TREASURY-DESIGN §٨.
///
/// **يُرقَّع ولا يُعاد.** الدفعة والخصم والعكس تعود من الخادم بصفّها، فيوضع الصف أعلى القائمة
/// وتتحرّك الأرقام بمبلغه — بالتعريف نفسه الذي يجمع به الخادم (`PurchaseOrderPayments`). وحده
/// «يُحسب عليه دين للمورد» يُعيد القراءة: ما صار عليه الأمرُ بعده يعرفه الخادم وحده.
class PurchaseOrderPaymentsCubit extends Cubit<PurchaseOrderPaymentsState> {
  PurchaseOrderPaymentsCubit({
    required this.purchaseOrderId,
    required this.vendorId,
    required GetPurchaseOrderPayments getPayments,
    required PayVendor payVendor,
    required ReverseVendorPayment reversePayment,
    required CreditVendor creditVendor,
    required CountOldOrderAsDebt countAsDebt,
  }) : _getPayments = getPayments,
       _payVendor = payVendor,
       _reversePayment = reversePayment,
       _creditVendor = creditVendor,
       _countAsDebt = countAsDebt,
       super(const PurchaseOrderPaymentsLoading());

  final int purchaseOrderId;
  final int vendorId;
  final GetPurchaseOrderPayments _getPayments;
  final PayVendor _payVendor;
  final ReverseVendorPayment _reversePayment;
  final CreditVendor _creditVendor;
  final CountOldOrderAsDebt _countAsDebt;

  Future<void> load() async {
    final previous = switch (state) {
      final PurchaseOrderPaymentsLoaded loaded => loaded,
      _ => null,
    };

    if (state is PurchaseOrderPaymentsFailed) emit(const PurchaseOrderPaymentsLoading());

    final result = await _getPayments(purchaseOrderId);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => previous == null
            ? PurchaseOrderPaymentsFailed(failure)
            : PurchaseOrderPaymentsLoaded(previous.payments, refreshFailure: failure),
        (payments) => PurchaseOrderPaymentsLoaded(payments),
      ),
    );
  }

  /// دفعةٌ للمورد على هذا الأمر. null عند النجاح، والرفضُ غير ذلك — النموذج يعرضه تحت حقوله.
  Future<Failure?> pay({
    required String amount,
    required String method,
    int? accountId,
    String? reference,
    String? notes,
    String? clientToken,
  }) async {
    final result = await _payVendor(
      vendorId: vendorId,
      purchaseOrderId: purchaseOrderId,
      amount: amount,
      method: method,
      accountId: accountId,
      reference: reference,
      notes: notes,
      clientToken: clientToken,
    );

    return result.fold((failure) => failure, (payment) {
      if (state case final PurchaseOrderPaymentsLoaded loaded when !isClosed) {
        emit(PurchaseOrderPaymentsLoaded(loaded.payments.withPayment(payment)));
      }

      return null;
    });
  }

  /// «خصم من المورد» على هذا الأمر — لا يتحرّك فيه مال. null عند النجاح.
  Future<Failure?> credit({required String amount, String? notes, String? clientToken}) async {
    final result = await _creditVendor(
      vendorId: vendorId,
      purchaseOrderId: purchaseOrderId,
      amount: amount,
      notes: notes,
      clientToken: clientToken,
    );

    return result.fold((failure) => failure, (credit) {
      if (state case final PurchaseOrderPaymentsLoaded loaded when !isClosed) {
        emit(PurchaseOrderPaymentsLoaded(loaded.payments.withPayment(credit)));
      }

      return null;
    });
  }

  /// «يُحسب عليه دين للمورد» — أمرٌ من قبل الخزينة ما زال مستحقاً يدخل «علينا». null عند النجاح.
  Future<Failure?> countAsDebt() async {
    final result = await _countAsDebt(purchaseOrderId);
    final failure = result.fold<Failure?>((failure) => failure, (_) => null);

    if (failure == null && !isClosed) await load();

    return failure;
  }

  /// يعكس [payment] بسبب. null عند النجاح.
  Future<Failure?> reverse(VendorPayment payment, {required String reason}) async {
    final result = await _reversePayment(
      vendorId: vendorId,
      paymentId: payment.id,
      reason: reason,
    );

    return result.fold((failure) => failure, (reversal) {
      if (state case final PurchaseOrderPaymentsLoaded loaded when !isClosed) {
        emit(PurchaseOrderPaymentsLoaded(loaded.payments.withReversal(payment, reversal)));
      }

      return null;
    });
  }
}

sealed class PurchaseOrderPaymentsState {
  const PurchaseOrderPaymentsState();
}

final class PurchaseOrderPaymentsLoading extends PurchaseOrderPaymentsState {
  const PurchaseOrderPaymentsLoading();
}

final class PurchaseOrderPaymentsFailed extends PurchaseOrderPaymentsState {
  const PurchaseOrderPaymentsFailed(this.failure);

  final Failure failure;
}

final class PurchaseOrderPaymentsLoaded extends PurchaseOrderPaymentsState {
  const PurchaseOrderPaymentsLoaded(this.payments, {this.refreshFailure});

  final PurchaseOrderPayments payments;

  /// قراءةٌ فشلت والقسم باقٍ على ما قبلها.
  final Failure? refreshFailure;
}
