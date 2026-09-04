import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/carrier/models/nawris_parcel.dart';

/// Handing an order to the carrier, and the two ways of taking it back.
///
/// **The read-only monitoring surface is deliberately absent** — the event queue, the parcel
/// list, the conflict resolutions. No screen asks for them yet, and an interface that declares
/// methods nothing calls is a promise the app has not made.
abstract interface class CarrierRepository {
  /// `POST /carrier/orders/{id}/lodge` — creates the parcel with Nawris.
  ///
  /// **Does not change the order's status.** The order stays in «جاهزة» until Nawris reports a
  /// courier is holding it, and then their webhook moves it — see `NawrisStatusCode` case 4.
  /// A screen that advanced the status itself would be describing a journey nobody had started.
  Future<Either<Failure, NawrisParcel>> lodge(int orderId);

  /// `POST /carrier/orders/{id}/resend` — sends a returned parcel out again.
  ///
  /// **Answers a different parcel from the one that went out.** A second journey is a second
  /// parcel row: the first closes and keeps its history, and the new one carries its own code and
  /// its own COD — which may have changed, because a payment can be taken while the goods are
  /// back on the shelf. Null when there is nothing out to re-send.
  Future<Either<Failure, NawrisParcel?>> resend(int orderId);

  /// `POST /carrier/orders/{id}/delete-shipment` — deletes it at Nawris **and** here.
  ///
  /// **Null when there was nothing out**, which is an answer rather than a failure: pressing it
  /// twice is a person checking.
  Future<Either<Failure, NawrisParcel?>> deleteShipment(int orderId);

  /// `POST /carrier/orders/{id}/unlink` — drops our claim, speaking to nobody.
  ///
  /// For a parcel deleted in the Nawris portal: nothing reaches us when that happens, so our
  /// side goes on saying a parcel is out and the order cannot be sent again. Null carries the
  /// same meaning it does above.
  Future<Either<Failure, NawrisParcel?>> unlink(int orderId);
}
