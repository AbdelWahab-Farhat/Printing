import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';

/// Proposing the next version of the artwork.
///
/// **Nothing is uploaded here.** The file lives in the customer's library — it is their
/// property, and the next order should be able to point at the same one — so what is added to
/// an order is a reference to a design that already exists. Uploading into that library is the
/// customers feature's job, and the picker on the way in is what joins the two.
class AddOrderDesign {
  const AddOrderDesign(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, void>> call(int orderId, {required int customerDesignId}) =>
      _repository.addDesign(orderId, customerDesignId: customerDesignId);
}

/// Approving a version, or turning it down with the reason why.
///
/// The reason is trimmed here for the same cause as everywhere else: a sentence of spaces
/// satisfies a required check and tells the next reader nothing. The server refuses a rejection
/// without one, and that refusal is the honest ending.
class ReviewOrderDesign {
  const ReviewOrderDesign(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, void>> call(
    int orderId,
    int designId, {
    required bool isApproved,
    String? rejectionReason,
  }) {
    final trimmed = rejectionReason?.trim();

    return _repository.reviewDesign(
      orderId,
      designId,
      isApproved: isApproved,
      rejectionReason: trimmed != null && trimmed.isNotEmpty ? trimmed : null,
    );
  }
}
