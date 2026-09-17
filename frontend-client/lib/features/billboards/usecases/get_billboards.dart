import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/billboards/models/billboard.dart';
import 'package:dayaa_client/features/billboards/repositories/billboard_repository.dart';

/// What to draw at the top of the home screen.
class GetBillboards {
  const GetBillboards(this._repository);

  final BillboardRepository _repository;

  Future<Either<Failure, List<Billboard>>> call() => _repository.showing();
}
