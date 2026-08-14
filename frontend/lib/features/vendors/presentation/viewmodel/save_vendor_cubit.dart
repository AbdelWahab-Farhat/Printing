import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/vendors/models/vendor.dart';
import 'package:dayaa/features/vendors/usecases/save_vendor.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'save_vendor_cubit.freezed.dart';
part 'save_vendor_state.dart';

/// The ViewModel behind the supplier form, and behind the switch that retires one.
///
/// It holds no draft: the form owns its controllers, because those are widget-lifecycle
/// resources that must be disposed, and a Cubit is not a disposal mechanism.
///
/// **Both writes land in the same state**, and deliberately: the screen has one place to show a
/// spinner and one place to show a refusal, whether the user pressed «حفظ» or the activation
/// switch. What they have in common is that both answer with the vendor the server stored.
class SaveVendorCubit extends Cubit<SaveVendorState> {
  SaveVendorCubit({
    required SaveVendor saveVendor,
    required SetVendorActive setActive,
  }) : _saveVendor = saveVendor,
       _setActive = setActive,
       super(const SaveVendorState.initial());

  final SaveVendor _saveVendor;
  final SetVendorActive _setActive;

  Future<void> submit({
    int? id,
    required String name,
    required String phone,
    String? contactPerson,
    String? email,
    String? address,
  }) async {
    // Ignored rather than queued: a second tap while the first is in flight is a second POST,
    // and the only thing that would stop it becoming a second vendor is the phone's uniqueness
    // — which answers 422, not "you already did this".
    if (state.isSubmitting) return;

    emit(const SaveVendorState.submitting());

    final result = await _saveVendor(
      id: id,
      name: name,
      phone: phone,
      contactPerson: contactPerson,
      email: email,
      address: address,
    );

    // The screen may have been popped while the request was in flight.
    if (isClosed) return;

    emit(result.fold(SaveVendorState.failure, SaveVendorState.success));
  }

  /// Stops offering this supplier, or brings it back.
  ///
  /// Its own request because it is its own endpoint — the save above cannot carry `is_active`,
  /// so "I corrected their phone" and "I stopped dealing with them" are never one write.
  Future<void> setActive(int vendorId, {required bool isActive}) async {
    if (state.isSubmitting) return;

    emit(const SaveVendorState.submitting());

    final result = await _setActive(vendorId, isActive: isActive);

    if (isClosed) return;

    emit(result.fold(SaveVendorState.failure, SaveVendorState.success));
  }

  /// Clears a previous failure so the error under a field disappears as the user corrects it.
  void clearFailure() {
    if (state is SaveVendorFailure) emit(const SaveVendorState.initial());
  }
}
