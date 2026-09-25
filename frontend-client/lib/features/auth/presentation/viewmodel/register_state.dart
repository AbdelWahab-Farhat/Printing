part of 'register_cubit.dart';

/// Everything the sign-up screen can be, and nothing it cannot.
@freezed
sealed class RegisterState with _$RegisterState {
  const factory RegisterState.initial() = RegisterInitial;

  const factory RegisterState.submitting() = RegisterSubmitting;

  /// Registration hands back a usable session, so nothing has to follow it with a sign-in —
  /// the customer lands on the home screen from here.
  const factory RegisterState.success(AuthSession session) = RegisterSuccess;

  const factory RegisterState.failure(Failure failure) = RegisterFailure;
}

extension RegisterStateX on RegisterState {
  bool get isSubmitting => this is RegisterSubmitting;

  String? get nameError => _fieldError('name');

  /// Where «رقم الهاتف مسجَّل مسبقاً. سجّل دخولك بدل إنشاء حساب» lands — the one refusal on this
  /// screen that is not a typo but a person who already has an account.
  String? get phoneError => _fieldError('phone');

  String? get passwordError => _fieldError('password');

  /// The server's field errors, read once rather than three near-identical switches.
  String? _fieldError(String field) => switch (this) {
    RegisterFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) => fieldErrors?[field]?.firstOrNull,
      _ => null,
    },
    _ => null,
  };
}
