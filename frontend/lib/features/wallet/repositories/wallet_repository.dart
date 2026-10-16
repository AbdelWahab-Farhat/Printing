import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/wallet/models/wallet_models.dart';

/// «محفظة العميل» — Docs/payments/CUSTOMER-WALLET.md.
abstract interface class WalletRepository {
  Future<Either<Failure, CustomerWallet>> wallet(int customerId);

  /// سجلّ محفظةٍ واحدة إن سُمّي [customerId]، وإلا «المعاملات المالية» كلها. [search] اسم العميل
  /// أو هاتفه أو رمزه — للصفحة الجامعة وحدها.
  Future<Either<Failure, Paginated<CustomerWalletEntry>>> entries({
    int? customerId,
    required int page,
    int? perPage,
    WalletEntryFilter filter = WalletEntryFilter.all,
    String? search,
    DateTime? from,
    DateTime? to,
  });

  /// شحنٌ في المكتب. الحوالة تحمل واصلها.
  Future<Either<Failure, WalletWrite>> topUp(
    int customerId, {
    required String amount,
    required TopUpMethod method,
    int? treasuryAccountId,
    String? reference,
    String? notes,
    String? receiptPath,
    String? receiptFilename,
  });

  /// تعديلٌ باليد بسبب. [credit] زيادة، وإلا نقص.
  Future<Either<Failure, WalletWrite>> adjust(
    int customerId, {
    required String amount,
    required bool credit,
    required String reason,
  });

  /// عكسُ شحنٍ أو تعديل — يعود بسطر العكس والرصيد بعده.
  Future<Either<Failure, WalletWrite>> reverse(int entryId, {required String reason});
}
