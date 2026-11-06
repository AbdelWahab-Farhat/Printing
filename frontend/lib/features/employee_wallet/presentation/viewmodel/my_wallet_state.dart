part of 'my_wallet_cubit.dart';

@freezed
sealed class MyWalletState with _$MyWalletState {
  const factory MyWalletState.loading() = MyWalletLoading;

  const factory MyWalletState.failed(Failure failure) = MyWalletFailed;

  const factory MyWalletState.loaded(
    String balance, {

    /// إعادةُ قراءةٍ فشلت والرقم باقٍ على ما قبلها.
    Failure? refreshFailure,
  }) = MyWalletLoaded;
}
