import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/carrier/models/nawris_parcel.dart';
import 'package:dayaa/features/carrier/repositories/carrier_repository.dart';

/// «إعادة الإرسال» — sends a returned parcel out again.
///
/// **The odd one out in this file**: the other two let go of a hand-over, this one repeats it.
/// It lives here because the app treats all three the same way — ask, send, name the parcel that
/// came back — and because the server answers all three with «لا توجد شحنة مفتوحة» when there is
/// nothing out.
///
/// The parcel it answers with is a **new** one. The old row stays, closed, carrying the history of
/// the first journey.
class ResendCarrierShipment {
  const ResendCarrierShipment(this._repository);

  final CarrierRepository _repository;

  Future<Either<Failure, NawrisParcel?>> call(int orderId) =>
      _repository.resend(orderId);
}

/// «حذف الشحنة من النورس» — deletes it at their end and closes ours.
///
/// **For a parcel that never went anywhere**: the wrong address, the wrong order, a hand-over
/// somebody wants to redo. It stops existing on both sides and the order can be sent again.
class DeleteCarrierShipment {
  const DeleteCarrierShipment(this._repository);

  final CarrierRepository _repository;

  Future<Either<Failure, NawrisParcel?>> call(int orderId) =>
      _repository.deleteShipment(orderId);
}

/// «فكّ الربط» — lets go of the parcel without telling Nawris anything.
///
/// **For a parcel somebody deleted in the Nawris portal.** Nothing reaches us when they do, so
/// our side goes on saying a parcel is out and «إرسال للنورس» refuses the order — and asking
/// them to delete it again would only earn an error about a parcel that is already gone. This is
/// the way out, and it is the one carrier action in the app that makes no call to the carrier.
class UnlinkCarrierShipment {
  const UnlinkCarrierShipment(this._repository);

  final CarrierRepository _repository;

  Future<Either<Failure, NawrisParcel?>> call(int orderId) =>
      _repository.unlink(orderId);
}
