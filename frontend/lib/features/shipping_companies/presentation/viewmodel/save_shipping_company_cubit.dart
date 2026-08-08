import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/shipping_companies/models/shipping_company.dart';
import 'package:printing/features/shipping_companies/usecases/save_shipping_company.dart';

part 'save_shipping_company_state.dart';
part 'save_shipping_company_cubit.freezed.dart';

/// The ViewModel behind the carrier form.
///
/// It holds no draft: the form owns its controllers, because those are widget-lifecycle
/// resources that must be disposed, and a Cubit is not a disposal mechanism.
class SaveShippingCompanyCubit extends Cubit<SaveShippingCompanyState> {
  SaveShippingCompanyCubit({required SaveShippingCompany saveCompany})
    : _saveCompany = saveCompany,
      super(const SaveShippingCompanyState.initial());

  final SaveShippingCompany _saveCompany;

  Future<void> submit({
    int? id,
    required String name,
    String? phone,
    String? notes,
    bool isActive = true,
  }) async {
    // Ignored rather than queued: a second tap while the first is in flight is a second POST,
    // and a company has no natural key the server could dedupe on.
    if (state.isSubmitting) return;

    emit(const SaveShippingCompanyState.submitting());

    final result = await _saveCompany(
      id: id,
      name: name,
      phone: phone,
      notes: notes,
      isActive: isActive,
    );

    // The screen may have been popped while the request was in flight.
    if (isClosed) return;

    emit(result.fold((f) => SaveShippingCompanyState.failure(f), (c) => SaveShippingCompanyState.success(c)));
  }

  /// Clears a previous failure so the error under a field disappears as the user corrects it.
  void clearFailure() {
    if (state is SaveShippingCompanyFailure) {
      emit(const SaveShippingCompanyState.initial());
    }
  }
}
