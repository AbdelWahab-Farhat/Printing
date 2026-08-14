import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order_counts.dart';
import 'package:dayaa/features/purchase_orders/usecases/purchase_order_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'vendor_purchase_order_counts_cubit.freezed.dart';
part 'vendor_purchase_order_counts_state.dart';

/// How many purchase orders this supplier has, in the groups their screen offers.
///
/// **Its own Cubit rather than more fields on [VendorDetailCubit], because the two answer to
/// different failures.** Losing the supplier means there is nothing to draw; losing the numbers
/// means the ways in are drawn without them, and the screen is still perfectly usable. Folding
/// them together would let a summary request that timed out blank a page of contact details that
/// arrived fine.
///
/// One request for all four numbers: `/purchase-orders/summary` answers per status and takes
/// `vendor_id`, so the groups are added up here. See VENDOR-PURCHASE-ORDERS-SECTION.md §٢.
class VendorPurchaseOrderCountsCubit
    extends Cubit<VendorPurchaseOrderCountsState> {
  VendorPurchaseOrderCountsCubit({
    required int vendorId,
    required GetPurchaseOrderCounts getCounts,
  }) : _vendorId = vendorId,
       _getCounts = getCounts,
       super(const VendorPurchaseOrderCountsState.loading());

  final int _vendorId;
  final GetPurchaseOrderCounts _getCounts;

  Future<void> load() async {
    final result = await _getCounts(vendorId: _vendorId);
    if (isClosed) return;

    emit(
      result.fold(
        VendorPurchaseOrderCountsState.failure,
        VendorPurchaseOrderCountsState.loaded,
      ),
    );
  }
}
