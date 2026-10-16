import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/features/wallet/models/wallet_models.dart';
import 'package:dayaa_client/features/wallet/repositories/wallet_repository.dart';

class GetWalletBalance {
  const GetWalletBalance(this._repository);

  final WalletRepository _repository;

  Future<Either<Failure, String>> call() => _repository.balance();
}

class GetWalletEntries {
  const GetWalletEntries(this._repository);

  final WalletRepository _repository;

  Future<Either<Failure, Paginated<MyWalletEntry>>> call({
    required int page,
    MyWalletFilter filter = MyWalletFilter.all,
  }) => _repository.entries(page: page, filter: filter);
}

class PayOrderFromWallet {
  const PayOrderFromWallet(this._repository);

  final WalletRepository _repository;

  Future<Either<Failure, String>> call(int orderId, {String? amount, String? clientToken}) =>
      _repository.payOrder(orderId, amount: amount, clientToken: clientToken);
}
