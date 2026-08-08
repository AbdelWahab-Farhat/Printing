part of 'vendor_detail_cubit.dart';

/// Everything the supplier screen can be.
///
/// **Each case carries the vendor it already has**, which is what lets a refusal put the user
/// back on the screen they were reading rather than on an error page. Only a deep link — which
/// arrives with no row behind it — starts with nothing to show.
@freezed
sealed class VendorDetailState with _$VendorDetailState {
  const factory VendorDetailState.loading({Vendor? vendor}) = VendorDetailLoading;

  const factory VendorDetailState.ready(Vendor vendor) = VendorDetailReady;

  /// The activation is in flight. The vendor stays on screen and the actions lock.
  const factory VendorDetailState.working(Vendor vendor) = VendorDetailWorking;

  const factory VendorDetailState.failure(Failure failure, {Vendor? vendor}) =
      VendorDetailFailure;
}

extension VendorDetailStateX on VendorDetailState {
  /// What is on screen, whatever else is happening.
  Vendor? get vendor => switch (this) {
    VendorDetailLoading(:final vendor) => vendor,
    VendorDetailReady(:final vendor) => vendor,
    VendorDetailWorking(:final vendor) => vendor,
    VendorDetailFailure(:final vendor) => vendor,
  };

  bool get isWorking => this is VendorDetailWorking;
}
