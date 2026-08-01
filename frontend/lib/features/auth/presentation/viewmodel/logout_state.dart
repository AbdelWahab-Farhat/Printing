part of 'logout_cubit.dart';

/// Signing out has two moments and one outcome.
@freezed
sealed class LogoutState with _$LogoutState {
  const factory LogoutState.initial() = LogoutInitial;

  const factory LogoutState.submitting() = LogoutSubmitting;

  /// Done — the token is off this device.
  ///
  /// [failure] records that the *server* was not told, for a screen that wants to say so. It is
  /// never a reason to keep somebody signed in.
  const factory LogoutState.signedOut({Failure? failure}) = LogoutSignedOut;
}
