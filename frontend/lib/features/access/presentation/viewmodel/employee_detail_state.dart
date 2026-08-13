part of 'employee_detail_cubit.dart';

/// Everything the employee screen can be.
///
/// [changing] carries the employee it is changing, so the screen keeps showing them while a
/// request is in flight — a detail screen that blanks to a spinner because one number was typed
/// has thrown away everything the reader was looking at.
///
/// **[loaded] carries an optional [failure], which the customer screen has no equivalent of.**
/// The difference is where the failure comes from: there, the only change is a switch, so a
/// failed one may replace the page. Here it is usually a value somebody has just typed into a
/// sheet, and the right answer is to keep the page, keep the sheet open, and say what went
/// wrong — so the failure rides *with* the employee rather than instead of them.
@freezed
sealed class EmployeeDetailState with _$EmployeeDetailState {
  const factory EmployeeDetailState.loading() = EmployeeDetailLoading;

  const factory EmployeeDetailState.loaded(AuthUser user, {Failure? failure}) =
      EmployeeDetailLoaded;

  /// Loaded, and a change is on its way.
  const factory EmployeeDetailState.changing(AuthUser user) = EmployeeDetailChanging;

  /// Nothing to show at all — the first read failed.
  const factory EmployeeDetailState.failure(Failure failure) = EmployeeDetailFailure;
}

extension EmployeeDetailStateX on EmployeeDetailState {
  /// The employee, whenever there is one to show — including mid-change.
  AuthUser? get user => switch (this) {
    EmployeeDetailLoaded(:final user) => user,
    EmployeeDetailChanging(:final user) => user,
    _ => null,
  };

  bool get isChanging => this is EmployeeDetailChanging;
}
