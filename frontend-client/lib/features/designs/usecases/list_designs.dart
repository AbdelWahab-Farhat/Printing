import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/repositories/design_repository.dart';

/// Read the library.
class ListDesigns {
  const ListDesigns(this._repository);

  final DesignRepository _repository;

  Future<Either<Failure, List<CustomerDesign>>> call() => _repository.list();
}
