import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/vendors/models/vendor.dart';
import 'package:dayaa/features/vendors/repositories/vendor_repository.dart';
import 'package:dayaa/features/vendors/usecases/save_vendor.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'vendor_detail_cubit.freezed.dart';
part 'vendor_detail_state.dart';

/// One supplier, and the two things the screen does to it.
///
/// **It opens on the vendor the list already had.** The row that was tapped carries every field
/// this screen shows, so there is nothing to wait for — the read that follows is a correction,
/// not a first draft, and it happens under a screen that is already right.
class VendorDetailCubit extends Cubit<VendorDetailState> {
  VendorDetailCubit({
    required int vendorId,
    required VendorRepository repository,
    required SetVendorActive setActive,
    Vendor? initial,
  }) : _id = vendorId,
       _repository = repository,
       _setActive = setActive,
       super(
         initial == null
             ? const VendorDetailState.loading()
             : VendorDetailState.ready(initial),
       );

  final int _id;
  final VendorRepository _repository;
  final SetVendorActive _setActive;

  Future<void> load() async {
    emit(VendorDetailState.loading(vendor: state.vendor));

    final result = await _repository.show(_id);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => VendorDetailState.failure(failure, vendor: state.vendor),
        VendorDetailState.ready,
      ),
    );
  }

  /// Takes a reading the caller already has — the form's saved copy, straight from the server.
  ///
  /// The alternative was [load], which is a request for something this screen was just handed.
  /// A pull still re-reads, and so does the retry on the failure view.
  void show(Vendor vendor) {
    if (isClosed) return;

    emit(VendorDetailState.ready(vendor));
  }

  /// Stops offering this supplier, or brings it back. Answers with the failure, or null.
  Future<Failure?> setActive({required bool isActive}) async {
    final vendor = state.vendor;
    if (vendor == null || state.isWorking) return null;

    emit(VendorDetailState.working(vendor));

    final result = await _setActive(vendor.id, isActive: isActive);

    if (isClosed) return null;

    return result.fold(
      (failure) {
        // Back to exactly what was on screen: a refusal must not leave the switch showing a
        // state the server never accepted.
        emit(VendorDetailState.ready(vendor));

        return failure;
      },
      (updated) {
        emit(VendorDetailState.ready(updated));

        return null;
      },
    );
  }
}
