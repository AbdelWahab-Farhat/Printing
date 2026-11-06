part of 'employee_wallet_cubit.dart';

@freezed
sealed class EmployeeWalletState with _$EmployeeWalletState {
  const factory EmployeeWalletState.loading() = EmployeeWalletLoading;

  const factory EmployeeWalletState.failed(Failure failure) = EmployeeWalletFailed;

  const factory EmployeeWalletState.loaded(
    EmployeeWallet wallet, {

    /// إعادةُ قراءةٍ فشلت والرأس باقٍ على ما قبلها: يقوله توست.
    Failure? refreshFailure,
  }) = EmployeeWalletLoaded;
}
