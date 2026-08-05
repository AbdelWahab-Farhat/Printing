import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/pagination/paged_cubit.dart';
import 'package:printing/core/pagination/paged_state.dart';
import 'package:printing/features/shipping_companies/models/shipping_company.dart';
import 'package:printing/features/shipping_companies/usecases/get_shipping_companies.dart';

/// The carriers list.
///
/// [onlyActive] is what separates the two screens that use it: the management screen shows every
/// company including the ones we stopped dealing with, and the dispatch picker shows only the
/// ones a parcel may still be handed to.
class ShippingCompaniesCubit extends PagedCubit<ShippingCompany> {
  ShippingCompaniesCubit({
    required GetShippingCompanies getCompanies,
    bool onlyActive = false,
  }) : _getCompanies = getCompanies,
       _onlyActive = onlyActive;

  final GetShippingCompanies _getCompanies;
  final bool _onlyActive;

  @override
  Future<Either<Failure, Paginated<ShippingCompany>>> fetchPage({
    String? search,
    required int page,
  }) {
    return _getCompanies(
      search: search,
      // Null rather than false: false would ask for the retired ones only.
      isActive: _onlyActive ? true : null,
      page: page,
    );
  }
}

typedef ShippingCompaniesState = PagedState<ShippingCompany>;
typedef ShippingCompaniesInitial = PagedInitial<ShippingCompany>;
typedef ShippingCompaniesLoading = PagedLoading<ShippingCompany>;
typedef ShippingCompaniesLoaded = PagedLoaded<ShippingCompany>;
typedef ShippingCompaniesFailure = PagedFailure<ShippingCompany>;
