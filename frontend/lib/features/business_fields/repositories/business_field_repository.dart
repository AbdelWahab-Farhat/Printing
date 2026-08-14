import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/business_fields/models/business_field.dart';

/// Reading and curating مجالات العمل, stated without saying how.
abstract interface class BusinessFieldRepository {
  /// One page of fields, in the business's own order.
  ///
  /// [isActive] left null returns both the offered and the stopped ones — which is what the
  /// management screen wants. A picker asks for `true`.
  Future<Either<Failure, Paginated<BusinessField>>> fields({
    String? search,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  });

  Future<Either<Failure, BusinessField>> create({
    required String name,
    required int sortOrder,
  });

  Future<Either<Failure, BusinessField>> update(
    int fieldId, {
    required String name,
    required int sortOrder,
    required bool isActive,
  });

  /// Hides a field from the pickers. The shops already recorded under it keep it.
  Future<Either<Failure, BusinessField>> setActivation(int fieldId, {required bool isActive});

  /// Only for a row that should never have existed. The server refuses with 422 once any shop
  /// points at the field — deactivation is what retires one in use. Answers with the server's
  /// own message, so the screen says what happened in the words the API chose.
  Future<Either<Failure, String>> delete(int fieldId);
}
