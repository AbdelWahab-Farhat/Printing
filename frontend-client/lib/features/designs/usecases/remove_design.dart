import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/designs/repositories/design_repository.dart';

/// Hide a design from the library.
///
/// **The file survives**, and the server is where that is decided: an order placed last year
/// points at this design and must still be able to show what was printed.
class RemoveDesign {
  const RemoveDesign(this._repository);

  final DesignRepository _repository;

  Future<Either<Failure, Unit>> call(int id) => _repository.remove(id);
}
