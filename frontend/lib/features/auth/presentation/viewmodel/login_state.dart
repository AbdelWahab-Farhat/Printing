part of 'login_cubit.dart';

/// Everything the login screen can be, and nothing it cannot.
///
/// A Freezed union rather than a class with `isLoading`, `error` and `session` all nullable at
/// once — that shape permits `isLoading: true` together with an error, which is exactly how a
/// spinner ends up stuck on top of a failure message. Here the compiler refuses to build it,
/// and `switch` in the view is exhaustive.
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

  /// The message to hang under the phone field, if the server blamed that field.
  ///
  /// The API calls it `login` because the endpoint also accepts an email; this screen only
  /// offers a phone, so its error belongs on the phone input. Translating the name here keeps
  /// that quirk out of the widget.
  String? get phoneError => switch (this) {
    LoginFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) => fieldErrors?['login']?.firstOrNull,
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
