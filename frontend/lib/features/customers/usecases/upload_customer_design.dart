import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/customers/models/design_rules.dart';
import 'package:dayaa/features/customers/repositories/customer_design_repository.dart';

/// Puts one file into a customer's library.
///
/// **This is where the pre-flight check lives, and it is the reason this use case is not a
/// one-line pass-through.** [DesignRules] answers instantly whether the API would refuse the
/// file; without it, a 26 MB scan is pushed over a Libyan mobile connection for a minute to be
/// told its size. A refusal here is shaped as the same [Failure.server] the API would have
/// sent, so the row showing it cannot tell the difference and no screen needs two paths.
///
/// The server still decides. It sniffs the bytes, and the filename this checks is the client's
/// claim about them.
class UploadCustomerDesign {
  const UploadCustomerDesign(this._repository);

  final CustomerDesignRepository _repository;

  Future<Either<Failure, CustomerDesign>> call(
    int customerId, {
    required PickedFile file,
    String? label,
    String? notes,
    void Function(int sent, int total)? onProgress,
  }) async {
    if (DesignRules.reject(file) case final reason?) {
      // 422 in everything but origin — it is the code the API answers with for exactly this,
      // and matching it means a caller that switches on the status is not surprised.
      return Left(Failure.server(message: reason, statusCode: 422));
    }

    return _repository.upload(
      customerId,
      path: file.path,
      filename: file.name,
      label: label,
      notes: notes,
      onProgress: onProgress,
    );
  }
}
