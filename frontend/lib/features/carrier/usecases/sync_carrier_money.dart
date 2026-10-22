import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/carrier/models/carrier_money_sync.dart';
import 'package:dayaa/features/carrier/repositories/carrier_repository.dart';

/// «إعادة إبلاغ نورس» — sends the order's money to Nawris again.
///
/// For a parcel whose last change they refused: the courier is still collecting the old amount.
/// They may refuse again, and that comes back as an answer — [CarrierMoneySync.told] false — not
/// as a failure.
class SyncCarrierMoney {
  const SyncCarrierMoney(this._repository);

  final CarrierRepository _repository;

  Future<Either<Failure, CarrierMoneySync?>> call(int orderId) =>
      _repository.syncMoney(orderId);
}
