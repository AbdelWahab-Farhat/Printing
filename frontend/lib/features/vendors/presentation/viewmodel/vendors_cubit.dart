import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/vendors/models/vendor.dart';
import 'package:dayaa/features/vendors/usecases/get_vendors.dart';

/// The suppliers list.
///
/// [onlyActive] is what separates the two screens that use it: the management screen shows every
/// supplier including the ones we stopped dealing with, and the purchase-order picker shows only
/// the ones an order may still be raised against.
class VendorsCubit extends PagedCubit<Vendor> {
  VendorsCubit({required GetVendors getVendors, bool onlyActive = false})
    : _getVendors = getVendors,
      _onlyActive = onlyActive;

  final GetVendors _getVendors;
  final bool _onlyActive;

  @override
  Object identityOf(Vendor item) => item.id;

  @override
  Future<Either<Failure, Paginated<Vendor>>> fetchPage({
    String? search,
    required int page,
  }) {
    return _getVendors(
      search: search,
      // Null rather than false: false would ask for the retired ones only.
      isActive: _onlyActive ? true : null,
      page: page,
    );
  }

  /// A deactivated supplier stays on the list rather than being dropped from it.
  ///
  /// The default [PagedCubit.belongs] already says so; it is spelled out because the neighbouring
  /// lists say the opposite. Unlike a status filter, this one is «كل الموردين» — a supplier that
  /// vanished on being switched off would look deleted, which is precisely the thing this
  /// feature refuses to do. The picker's copy is narrowed by the *server*, on its own request.
  @override
  bool belongs(Vendor item) => true;
}

typedef VendorsState = PagedState<Vendor>;
typedef VendorsInitial = PagedInitial<Vendor>;
typedef VendorsLoading = PagedLoading<Vendor>;
typedef VendorsLoaded = PagedLoaded<Vendor>;
typedef VendorsFailure = PagedFailure<Vendor>;
