import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/repositories/design_repository.dart';

/// Change what a design is called. The file is never swapped.
class RenameDesign {
  const RenameDesign(this._repository);

  final DesignRepository _repository;

  Future<Either<Failure, CustomerDesign>> call({
    required int id,
    required String label,
  }) => _repository.rename(id: id, label: label);
}
