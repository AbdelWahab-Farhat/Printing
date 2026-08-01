import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/usecases/create_customer.dart';
import 'package:printing/features/customers/usecases/update_customer.dart';

part 'add_customer_state.dart';
part 'add_customer_cubit.freezed.dart';

/// The ViewModel for the "add a customer" screen.
///
/// It talks to a use case, never to a repository or to Dio, and it holds no `BuildContext` —
/// a Cubit that imports `material.dart` has stopped being testable without a widget tree.
class AddCustomerCubit extends Cubit<AddCustomerState> {
  AddCustomerCubit({
    required CreateCustomer createCustomer,
    required UpdateCustomer updateCustomer,
  }) : _createCustomer = createCustomer,
       _updateCustomer = updateCustomer,
       super(const AddCustomerState.initial());

  final CreateCustomer _createCustomer;
  final UpdateCustomer _updateCustomer;

  /// Sends the form.
  ///
  /// **On a [Failure.network] here, retrying is safe** — which is not true of every create.
  /// The phone number is unique in the database, not merely in validation, so a request that
  /// did reach the server before the connection dropped makes the retry a 422 rather than a
  /// second customer. That is the one fact that makes "أعد المحاولة" an honest offer on this
  /// screen; a create without such a key would need the button to say something else.
  /// Creates when [customerId] is null, saves when it is not.
  ///
  /// One method for both, because the screen, the validation and the 422 mapping are the same
  /// either way — the only thing that differs is which use case is called and, inside it, what
  /// an empty shops list means.
  Future<void> submit({
    int? customerId,
    required String name,
    required String phone,
    List<ShopInput> shops = const [],
  }) async {
    // Ignored rather than queued: a second tap while the first request is in flight would be a
    // second POST, and the screen has already moved on by the time it answers.
    if (state.isSubmitting) return;

    emit(const AddCustomerState.submitting());

    final result = customerId == null
        ? await _createCustomer(name: name, phone: phone, shops: shops)
        : await _updateCustomer(
            customerId: customerId,
            name: name,
            phone: phone,
            shops: shops,
          );

    // The screen may have been popped while the request was in flight, and emitting into a
    // closed Cubit throws.
    if (isClosed) return;

    emit(result.fold(AddCustomerState.failure, AddCustomerState.success));
  }

  /// Clears a previous failure so the error under a field disappears as soon as the user
  /// starts correcting it, rather than lingering until the next submit.
  void clearFailure() {
    if (state is AddCustomerFailure) emit(const AddCustomerState.initial());
  }
}
