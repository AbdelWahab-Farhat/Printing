import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/usecases/get_customer.dart';
import 'package:printing/features/customers/usecases/set_customer_activation.dart';

part 'customer_detail_state.dart';
part 'customer_detail_cubit.freezed.dart';

/// One customer, and the two things this screen can do to them.
///
/// Editing is not here: it belongs to the form, which owns its own Cubit. This one re-reads
/// afterwards, which is also what makes an edit made on a *different* device show up.
class CustomerDetailCubit extends Cubit<CustomerDetailState> {
  CustomerDetailCubit({
    required int customerId,
    required GetCustomer getCustomer,
    required SetCustomerActivation setActivation,
  }) : _customerId = customerId,
       _getCustomer = getCustomer,
       _setActivation = setActivation,
       super(const CustomerDetailState.loading());

  final int _customerId;
  final GetCustomer _getCustomer;
  final SetCustomerActivation _setActivation;

  Future<void> load() async {
    // Only from nothing: a reload after an edit must not blank the screen the user is reading.
    if (state.customer == null) emit(const CustomerDetailState.loading());

    final result = await _getCustomer(_customerId);
    if (isClosed) return;

    emit(result.fold(CustomerDetailState.failure, CustomerDetailState.loaded));
  }

  /// Turns the customer on or off.
  ///
  /// The customer stays on screen throughout — [CustomerDetailState.changing] carries them —
  /// because replacing a page of information with a spinner to flip one flag loses everything
  /// the user was looking at.
  Future<void> setActive({required bool isActive}) async {
    final current = state.customer;
    if (current == null || state.isChanging) return;

    emit(CustomerDetailState.changing(current));

    final result = await _setActivation(_customerId, isActive: isActive);
    if (isClosed) return;

    emit(
      result.fold(
        // The failure replaces the page rather than sitting beside it: this screen has one
        // source of truth, and a customer shown as active next to "could not deactivate" is a
        // screen lying about which of the two it believes.
        CustomerDetailState.failure,
        CustomerDetailState.loaded,
      ),
    );
  }
}
