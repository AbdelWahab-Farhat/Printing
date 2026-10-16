import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/orders/usecases/manage_order_payments.dart' show normaliseAmount;
import 'package:dayaa/features/wallet/models/wallet_models.dart';
import 'package:dayaa/features/wallet/repositories/wallet_repository.dart';

class GetCustomerWallet {
  const GetCustomerWallet(this._repository);

  final WalletRepository _repository;

  Future<Either<Failure, CustomerWallet>> call(int customerId) => _repository.wallet(customerId);
}

class GetCustomerWalletEntries {
  const GetCustomerWalletEntries(this._repository);

  final WalletRepository _repository;

  Future<Either<Failure, Paginated<CustomerWalletEntry>>> call({
    int? customerId,
    required int page,
    int? perPage,
    WalletEntryFilter filter = WalletEntryFilter.all,
    String? search,
    DateTime? from,
    DateTime? to,
  }) => _repository.entries(
    customerId: customerId,
    page: page,
    perPage: perPage,
    filter: filter,
    search: search,
    from: from,
    to: to,
  );
}

class TopUpCustomerWallet {
  const TopUpCustomerWallet(this._repository);

  final WalletRepository _repository;

  Future<Either<Failure, WalletWrite>> call(
    int customerId, {
    required String amount,
    required TopUpMethod method,
    int? treasuryAccountId,
    String? reference,
    String? notes,
    String? receiptPath,
    String? receiptFilename,
  }) => _repository.topUp(
    customerId,
    amount: normaliseAmount(amount),
    method: method,
    treasuryAccountId: treasuryAccountId,
    reference: reference,
    notes: notes,
    receiptPath: receiptPath,
    receiptFilename: receiptFilename,
  );
}

class AdjustCustomerWallet {
  const AdjustCustomerWallet(this._repository);

  final WalletRepository _repository;

  Future<Either<Failure, WalletWrite>> call(
    int customerId, {
    required String amount,
    required bool credit,
    required String reason,
  }) => _repository.adjust(customerId, amount: normaliseAmount(amount), credit: credit, reason: reason);
}

class ReverseCustomerWalletEntry {
  const ReverseCustomerWalletEntry(this._repository);

  final WalletRepository _repository;

  Future<Either<Failure, WalletWrite>> call(int entryId, {required String reason}) =>
      _repository.reverse(entryId, reason: reason);
}
