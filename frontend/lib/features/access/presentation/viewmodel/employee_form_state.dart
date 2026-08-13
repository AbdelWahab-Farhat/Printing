part of 'employee_form_cubit.dart';

/// What the "correct an employee's details" form is showing.
///
/// A record with fields rather than a sealed union, the same exception `AddEmployeeState`
/// makes and for the same reason: a 422 must leave all three boxes exactly where they were,
/// with the server's complaint under the one it is about.
@freezed
abstract class EmployeeFormState with _$EmployeeFormState {
  const factory EmployeeFormState({
    @Default(false) bool isSubmitting,

    /// The account as the server stored it, once saved. The screen pops with it, so the detail
    /// page behind knows the save happened without asking again.
    AuthUser? saved,

    Failure? failure,
  }) = _EmployeeFormState;

  const EmployeeFormState._();

  /// The server's complaint about one field, rendered under that field — «رقم الهاتف مستخدم
  /// مسبقاً» belongs under the number that has to change, not in a bar that has faded by the
  /// time anybody looks.
  String? get nameError => _fieldError('name');

  String? get emailError => _fieldError('email');

  String? get phoneError => _fieldError('phone');

  /// The server's complaint about the wage — a negative figure, or something that is not a
  /// number. It arrives from a *different* request than the three above, which is exactly why
  /// it is read the same way: the form shows one error under one box regardless of which
  /// endpoint objected.
  String? get salaryError => _fieldError('salary');

  /// Whether what went wrong has already been said next to a box, so the screen knows a
  /// snackbar would only repeat it.
  bool get isFieldFailure =>
      nameError != null || emailError != null || phoneError != null || salaryError != null;

  String? _fieldError(String field) => switch (failure) {
    ServerFailure(:final fieldErrors) => fieldErrors?[field]?.firstOrNull,
    _ => null,
  };
}
