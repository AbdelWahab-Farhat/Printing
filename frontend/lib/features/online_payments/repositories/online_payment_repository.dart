import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/online_payments/models/online_payment_models.dart';

/// «المدفوعات الإلكترونية» — Docs/payments/CUSTOMER-WALLET.md §٥.
abstract interface class OnlinePaymentRepository {
  /// محاولات الشحن، الأحدث أولاً. [search] مرجعنا أو اسم الزبون أو هاتفه.
  Future<Either<Failure, Paginated<PaymentIntent>>> intents({
    required int page,
    IntentFilter filter = IntentFilter.all,
    String? search,
  });

  /// يسأل EzonePay عن المحاولة: مدفوعةٌ تُشحن مرّةً واحدة، وفائتةٌ تنتهي.
  Future<Either<Failure, PaymentIntent>> recheck(String uuid);

  Future<Either<Failure, OnlinePaymentMethods>> methods();

  /// يفعّل الطريقة أو يطفئها، أو يضع حدودها. حدٌّ فارغ = بلا حد.
  Future<Either<Failure, OnlinePaymentMethodSetting>> updateMethod(
    int id, {
    bool? isActive,
    Map<String, String?>? limits,
  });

  /// «تحويل Ezone إلى المصرف» — [kept] ما احتفظت به EzonePay عند التحويل.
  Future<Either<Failure, EzonePayout>> recordPayout({
    required String amount,
    String? kept,
    int? toAccountId,
    String? reference,
    required String clientToken,
  });
}
