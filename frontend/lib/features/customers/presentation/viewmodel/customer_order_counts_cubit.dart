import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order_counts.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/usecases/get_order_counts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_order_counts_cubit.freezed.dart';
part 'customer_order_counts_state.dart';

/// How many orders this customer has, in the three groups their screen offers.
///
/// **Its own Cubit rather than three more fields on [CustomerDetailCubit], because the two
/// answer to different failures.** Losing the customer means there is nothing to draw; losing
/// the numbers means the three ways in are drawn without them, and the screen is still
/// perfectly usable. Folding them together would make a summary request that timed out blank a
/// page of contact details that arrived fine.
///
/// One request for all three: `/orders/summary` already answers per status and already takes
/// `customer_id`, so the groups are added up here. See CUSTOMER-ORDERS-SECTION.md §٣.
class CustomerOrderCountsCubit extends Cubit<CustomerOrderCountsState> {
  CustomerOrderCountsCubit({required int customerId, required GetOrderCounts getCounts})
    : _customerId = customerId,
      _getCounts = getCounts,
      super(const CustomerOrderCountsState.loading());

  final int _customerId;
  final GetOrderCounts _getCounts;

  Future<void> load() async {
    final result = await _getCounts(customerId: _customerId);
    if (isClosed) return;

    emit(
      result.fold(
        CustomerOrderCountsState.failure,
        CustomerOrderCountsState.loaded,
      ),
    );
  }
}
