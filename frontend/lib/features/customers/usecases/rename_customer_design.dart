import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/customers/repositories/customer_design_repository.dart';

/// Changes what a design is called, and the note under it.
///
/// **Not "edit the design".** The file cannot be replaced — an order points at it, so swapping
/// the bytes under a stable id would change what an order placed last year says was printed.
/// The name is the only thing here that is a matter of opinion, and the only thing that moves.
class RenameCustomerDesign {
  const RenameCustomerDesign(this._repository);

  final CustomerDesignRepository _repository;

  Future<Either<Failure, CustomerDesign>> call(
    int customerId,
    int designId, {
    required String label,
    String? notes,
  }) => _repository.rename(customerId, designId, label: label, notes: notes);
}
