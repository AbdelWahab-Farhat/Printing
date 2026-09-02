import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/warehouses/models/warehouse.dart';
import 'package:dayaa/features/warehouses/usecases/delete_warehouse.dart';
import 'package:dayaa/features/warehouses/usecases/get_warehouses.dart';

/// المخازن — the list screen's ViewModel.
///
/// Paging, the debounce and the out-of-order guard come from [PagedCubit]. What is added is the
/// one thing the list itself does to a row: remove it.
class WarehousesCubit extends PagedCubit<Warehouse> {
  WarehousesCubit({
    required GetWarehouses getWarehouses,
    required DeleteWarehouse deleteWarehouse,
  }) : _getWarehouses = getWarehouses,
       _deleteWarehouse = deleteWarehouse;

  final GetWarehouses _getWarehouses;
  final DeleteWarehouse _deleteWarehouse;

  @override
  Object identityOf(Warehouse item) => item.id;

  @override
  Future<Either<Failure, Paginated<Warehouse>>> fetchPage({
    String? search,
    required int page,
  }) {
    return _getWarehouses(search: search, page: page);
  }

  /// Removes a warehouse and re-reads the list.
  ///
  /// Answers with the failure so the screen can say why nothing changed — «ما زال يحتوي على
  /// مخزون» is the server's rule, and the app does not guess at it.
  Future<Failure?> remove(Warehouse warehouse) async {
    final result = await _deleteWarehouse(warehouse.id);

    if (isClosed) return null;

    final failure = result.fold<Failure?>((failure) => failure, (_) => null);
    if (failure == null) await refresh();

    return failure;
  }
}

/// A name for `PagedState<Warehouse>`, so the view reads as a warehouses screen.
typedef WarehousesState = PagedState<Warehouse>;
typedef WarehousesInitial = PagedInitial<Warehouse>;
typedef WarehousesLoading = PagedLoading<Warehouse>;
typedef WarehousesLoaded = PagedLoaded<Warehouse>;
typedef WarehousesFailure = PagedFailure<Warehouse>;
