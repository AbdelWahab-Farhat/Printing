import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/shipping_companies/models/shipping_company.dart';
import 'package:printing/features/shipping_companies/repositories/shipping_company_repository.dart';

/// The carriers, for the management screen and for the dispatch picker.
class GetShippingCompanies {
  const GetShippingCompanies(this._repository);

  final ShippingCompanyRepository _repository;

  Future<Either<Failure, Paginated<ShippingCompany>>> call({
    String? search,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  }) {
    return _repository.companies(
      search: search,
      isActive: isActive,
      page: page,
      perPage: perPage,
    );
  }
}
