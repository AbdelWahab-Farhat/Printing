import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';

/// «محفظة الموظف» — Docs/employees/EMPLOYEE-WALLET-DESIGN.md §٧.
///
/// **[clientToken] يولّده التطبيق قبل الإرسال**، فلا تكتب الإعادةُ حركةً ثانية: الخادم يعيد السطر
/// الأول. ويبقى هو نفسه ما دامت الورقة مفتوحة.
abstract interface class EmployeeWalletRepository {
  Future<Either<Failure, EmployeeWallet>> wallet(int userId);

  /// محفظةُ القارئ نفسه — بلا صلاحية، وقراءةً فقط.
  Future<Either<Failure, EmployeeWallet>> myWallet();

  /// [search] اسم الموظف أو هاتفه أو رمزه — لتبويب «الموظفون» في «المعاملات المالية» وحده.
  Future<Either<Failure, Paginated<EmployeeWalletEntry>>> entries(
    EmployeeWalletLedger ledger, {
    required int page,
    EmployeeWalletEntryFilter filter = EmployeeWalletEntryFilter.all,
    String? search,
    DateTime? from,
    DateTime? to,
  });

  /// مالٌ سلّمه الموظف. الحوالة تحمل واصلها.
  Future<Either<Failure, EmployeeWalletWrite>> deposit(
    int userId,
    EmployeeMoneyDraft draft, {
    required String clientToken,
  });

  /// راتبٌ أو مكافأة صارت على الشركة — مصروفٌ بلا كاش.
  Future<Either<Failure, EmployeeWalletWrite>> credit(
    int userId,
    EmployeeCreditDraft draft, {
    required String clientToken,
  });

  /// مالٌ قبضه الموظف. لا يتجاوز الرصيد، ولا ما في الحساب ما دام «منع الرصيد السالب» مفعّلاً.
  Future<Either<Failure, EmployeeWalletWrite>> withdraw(
    int userId,
    EmployeeMoneyDraft draft, {
    required String clientToken,
  });

  /// تعديلٌ باليد بسبب. [credit] زيادة، وإلا نقص.
  Future<Either<Failure, EmployeeWalletWrite>> adjust(
    int userId, {
    required String amount,
    required bool credit,
    required String reason,
    required String clientToken,
  });

  /// عكسُ سطر — يعود بسطر العكس والرصيد بعده.
  Future<Either<Failure, EmployeeWalletWrite>> reverse(int entryId, {required String reason});
}
