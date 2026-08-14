import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/business_fields/models/business_field.dart';
import 'package:dayaa/features/business_fields/repositories/business_field_repository.dart';

/// One page of مجالات العمل.
class GetBusinessFields {
  const GetBusinessFields(this._repository);

  final BusinessFieldRepository _repository;

  Future<Either<Failure, Paginated<BusinessField>>> call({
    String? search,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  }) {
    return _repository.fields(
      // Trimmed here rather than in the Cubit: a trailing space from a paste is a search that
      // silently finds nothing, and every caller would otherwise have to remember this.
      search: search?.trim(),
      isActive: isActive,
      page: page,
      perPage: perPage,
    );
  }
}
