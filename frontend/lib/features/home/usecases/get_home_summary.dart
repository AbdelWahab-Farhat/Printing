import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/home/models/home_summary.dart';
import 'package:dayaa/features/home/repositories/home_repository.dart';

/// Reads the home screen's snapshot of the business.
class GetHomeSummary {
  const GetHomeSummary(this._repository);

  final HomeRepository _repository;

  Future<Either<Failure, HomeSummary>> call() => _repository.summary();
}
