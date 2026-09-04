import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/carrier/models/nawris_parcel.dart';
import 'package:dayaa/features/carrier/repositories/carrier_repository.dart';

/// «إرسال للنورس» — hands one order to the carrier.
///
/// **Every precondition is the server's**, and that is not laziness: whether the order is a
/// delivery, whether it is far enough along to be carried, whether its city has a Nawris
/// government id, and whether a parcel is already out for it are four rules that would each need
/// a second copy here, and a second copy is a copy that disagrees. The app decides only whether
/// to *offer* the button — see the order screen — and the server decides whether the parcel is
/// made, refusing by name so the person reads a sentence rather than a code.
class LodgeOrder {
  const LodgeOrder(this._repository);

  final CarrierRepository _repository;

  Future<Either<Failure, NawrisParcel>> call(int orderId) =>
      _repository.lodge(orderId);
}
