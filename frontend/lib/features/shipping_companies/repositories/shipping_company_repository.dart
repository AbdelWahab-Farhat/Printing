import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/shipping_companies/models/shipping_company.dart';

/// What the app can ask and tell about the carriers, stated without saying how.
abstract interface class ShippingCompanyRepository {
  /// [isActive] true is what the dispatch picker asks: a carrier we stopped dealing with is
  /// never the answer to «من سيأخذها».
  Future<Either<Failure, Paginated<ShippingCompany>>> companies({
    String? search,
    bool? isActive,
    int page,
    int perPage,
  });

  Future<Either<Failure, ShippingCompany>> create({
    required String name,
    String? phone,
    String? notes,
    bool isActive,
  });

  Future<Either<Failure, ShippingCompany>> update(
    int id, {
    required String name,
    String? phone,
    String? notes,
    bool isActive,
  });

  /// Answers with the server's own message, like every other command here.
  Future<Either<Failure, String>> delete(int id);
}
