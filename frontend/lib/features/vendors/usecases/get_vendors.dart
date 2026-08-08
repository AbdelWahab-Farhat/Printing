import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/vendors/models/vendor.dart';
import 'package:printing/features/vendors/repositories/vendor_repository.dart';

/// The suppliers, for the management screen and for the purchase-order picker.
///
/// [isActive] true is what the picker asks: a supplier we have stopped dealing with is never
/// the answer to «من نشتري منه».
class GetVendors {
  const GetVendors(this._repository);

  final VendorRepository _repository;

  Future<Either<Failure, Paginated<Vendor>>> call({
    String? search,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  }) {
    return _repository.vendors(
      search: search,
      isActive: isActive,
      page: page,
      perPage: perPage,
    );
  }
}
