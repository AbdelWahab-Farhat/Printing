part of 'login_cubit.dart';

/// Everything the sign-in screen can be, and nothing it cannot.
///
/// A Freezed union rather than a class with `isLoading`, `error` and `session` all nullable at
/// once — that shape permits `isLoading: true` together with an error, which is exactly how a
/// spinner ends up stuck on top of a failure message. Here the compiler refuses to build it, and
/// `switch` in the view is exhaustive.
@freezed
sealed class LoginState with _$LoginState {
  const factory LoginState.initial() = LoginInitial;

  /// In flight. The button shows a spinner and the form is locked, so an impatient double tap
  /// cannot send a second request.
  const factory LoginState.submitting() = LoginSubmitting;

  const factory LoginState.success(AuthSession session) = LoginSuccess;

  const factory LoginState.failure(Failure failure) = LoginFailure;
}

extension LoginStateX on LoginState {
  bool get isSubmitting => this is LoginSubmitting;

  /// The message to hang under the phone field.
  ///
  /// **The key is `phone`, not `login`.** The staff endpoint accepts an email or a phone and so
  /// reports against a field called `login`, which that app then has to translate here. The
  /// customer endpoint has only ever had one identifier and names it plainly, so there is
  /// nothing to translate — see `CustomerCredentialsAreWrong`.
  ///
  /// It is also where «رقم الهاتف أو كلمة المرور غير صحيحة» lands: the server answers a wrong
  /// password, an unknown number, an account with no password and a deleted one with the same
  /// message against this same field, on purpose, so that nobody can discover which phone
  /// numbers belong to customers.
  String? get phoneError => switch (this) {
    LoginFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) => fieldErrors?['phone']?.firstOrNull,
      _ => null,
    },
    _ => null,
  };

  String? get passwordError => switch (this) {
    LoginFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) => fieldErrors?['password']?.firstOrNull,
      _ => null,
    },
    _ => null,
  };
}
