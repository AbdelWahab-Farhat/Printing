import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';
import 'package:dayaa/features/employee_wallet/repositories/employee_wallet_repository.dart';
import 'package:dayaa/features/orders/usecases/manage_order_payments.dart' show normaliseAmount;

class GetEmployeeWallet {
  const GetEmployeeWallet(this._repository);

  final EmployeeWalletRepository _repository;

  Future<Either<Failure, EmployeeWallet>> call(int userId) => _repository.wallet(userId);
}

class GetMyWallet {
  const GetMyWallet(this._repository);

  final EmployeeWalletRepository _repository;

  Future<Either<Failure, EmployeeWallet>> call() => _repository.myWallet();
}

class GetEmployeeWalletEntries {
  const GetEmployeeWalletEntries(this._repository);

  final EmployeeWalletRepository _repository;

  Future<Either<Failure, Paginated<EmployeeWalletEntry>>> call(
    EmployeeWalletLedger ledger, {
    required int page,
    EmployeeWalletEntryFilter filter = EmployeeWalletEntryFilter.all,
    String? search,
    DateTime? from,
    DateTime? to,
  }) => _repository.entries(
    ledger,
    page: page,
    filter: filter,
    search: search,
    from: from,
    to: to,
  );
}

class DepositToEmployeeWallet {
  const DepositToEmployeeWallet(this._repository);

  final EmployeeWalletRepository _repository;

  Future<Either<Failure, EmployeeWalletWrite>> call(
    int userId,
    EmployeeMoneyDraft draft, {
    required String clientToken,
  }) => _repository.deposit(
    userId,
    draft.copyWith(amount: normaliseAmount(draft.amount)),
    clientToken: clientToken,
  );
}

class CreditEmployeeWallet {
  const CreditEmployeeWallet(this._repository);

  final EmployeeWalletRepository _repository;

  Future<Either<Failure, EmployeeWalletWrite>> call(
    int userId,
    EmployeeCreditDraft draft, {
    required String clientToken,
  }) => _repository.credit(
    userId,
    draft.copyWith(amount: normaliseAmount(draft.amount)),
    clientToken: clientToken,
  );
}

class WithdrawFromEmployeeWallet {
  const WithdrawFromEmployeeWallet(this._repository);

  final EmployeeWalletRepository _repository;

  Future<Either<Failure, EmployeeWalletWrite>> call(
    int userId,
    EmployeeMoneyDraft draft, {
    required String clientToken,
  }) => _repository.withdraw(
    userId,
    draft.copyWith(amount: normaliseAmount(draft.amount)),
    clientToken: clientToken,
  );
}

class AdjustEmployeeWallet {
  const AdjustEmployeeWallet(this._repository);

  final EmployeeWalletRepository _repository;

  Future<Either<Failure, EmployeeWalletWrite>> call(
    int userId, {
    required String amount,
    required bool credit,
    required String reason,
    required String clientToken,
  }) => _repository.adjust(
    userId,
    amount: normaliseAmount(amount),
    credit: credit,
    reason: reason,
    clientToken: clientToken,
  );
}

class ReverseEmployeeWalletEntry {
  const ReverseEmployeeWalletEntry(this._repository);

  final EmployeeWalletRepository _repository;

  Future<Either<Failure, EmployeeWalletWrite>> call(int entryId, {required String reason}) =>
      _repository.reverse(entryId, reason: reason);
}
