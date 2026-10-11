import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/features/wallet/models/wallet_models.dart';

/// «محفظتي» — Docs/payments/CUSTOMER-WALLET.md. لا شيء هنا يأخذ رقم عميل: المحفظة محفظةُ صاحب
/// التوكن دائماً.
abstract interface class WalletRepository {
  /// الرصيد.
  Future<Either<Failure, String>> balance();

  /// المعاملات، الأحدث أولاً. `extraMeta['balance']` الرصيد.
  Future<Either<Failure, Paginated<MyWalletEntry>>> entries({
    required int page,
    MyWalletFilter filter = MyWalletFilter.all,
  });

  /// الدفع من المحفظة على طلبية: [amount]، أو null بأكثر ما يسمح به الرصيد والمتبقي. يعود
  /// بالرصيد بعده. [clientToken] يجعل الإعادة آمنة: الرمزُ نفسه ثانيةً لا يدفع شيئاً.
  Future<Either<Failure, String>> payOrder(int orderId, {String? amount, String? clientToken});
}
