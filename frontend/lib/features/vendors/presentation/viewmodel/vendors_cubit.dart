import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/pagination/paged_cubit.dart';
import 'package:printing/core/pagination/paged_state.dart';
import 'package:printing/features/vendors/models/vendor.dart';
import 'package:printing/features/vendors/usecases/get_vendors.dart';

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

  /// Puts back a vendor a form or an activation toggle changed, without re-reading the page.
  ///
  /// Kept in place rather than dropped even when it has just been switched off: unlike a status
  /// filter, this list is «كل الموردين» — a supplier that vanished on being deactivated would
  /// look deleted, which is precisely the thing this feature refuses to do.
  void replace(Vendor updated) {
    final current = state;
    if (current is! PagedLoaded<Vendor>) return;

    emit(
      current.copyWith(
        page: Paginated<Vendor>(
          items: [
            for (final vendor in current.page.items)
              if (vendor.id == updated.id) updated else vendor,
          ],
          meta: current.page.meta,
        ),
      ),
    );
  }
}

typedef VendorsState = PagedState<Vendor>;
typedef VendorsInitial = PagedInitial<Vendor>;
typedef VendorsLoading = PagedLoading<Vendor>;
typedef VendorsLoaded = PagedLoaded<Vendor>;
typedef VendorsFailure = PagedFailure<Vendor>;
