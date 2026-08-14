import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/access/usecases/set_user_salary.dart';
import 'package:dayaa/features/access/usecases/update_user.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'employee_form_cubit.freezed.dart';
part 'employee_form_state.dart';

/// Correcting an existing employee's details — a wrong number, a married name, a typo.
///
/// **Its own Cubit rather than a mode of [AddEmployeeCubit], and the fields are why.** That one
/// carries a password, a confirmation and a set of roles, because all three are decided at the
/// moment an account is created. Neither belongs here: the password is the administrator's
/// through a sheet of its own, and the roles are their own sheet. A shared Cubit would keep the
/// password controllers alive on a screen that must never send them.
///
/// ## One form, two requests
///
/// The wage is on this form and travels to a **different endpoint** — `PATCH /users/{id}/salary`
/// rather than the `PUT` that carries the name. That is not an inconsistency to tidy away: the
/// two are guarded differently on the server (`users.salary` against `users.manage`), and a
/// single endpoint would put the wage behind whichever of the two is weaker. What the person
/// filling the form sees is one screen and one «حفظ»; where those values land is this class's
/// problem, which is exactly the kind of problem a ViewModel is for.
///
/// **The wage is sent only when it changed.** That keeps the common edit — a corrected phone
/// number — down to one request, and it means somebody without `users.salary`, who is never
/// shown the box, never sends a request the server would refuse.
///
/// **Both requests are idempotent, which is what makes «أعد المحاولة» honest** if the second
/// one fails after the first succeeded: submitting again re-sends the same name to `PUT` and
/// the same figure to `PATCH`, and the outcome is the state the form is showing either way.
class EmployeeFormCubit extends Cubit<EmployeeFormState> {
  EmployeeFormCubit({required UpdateUser updateUser, required SetUserSalary setSalary})
    : _updateUser = updateUser,
      _setSalary = setSalary,
      super(const EmployeeFormState());

  final UpdateUser _updateUser;
  final SetUserSalary _setSalary;

  /// Saves the form.
  ///
  /// [salary] is `null` when the box was not on screen at all — a reader without
  /// `users.salary` — and that is different from an empty box, which is «امسح الراتب» and
  /// arrives as an empty string. Only [Some] is ever sent.
  Future<void> submit({
    required int userId,
    required String name,
    required String email,
    required String phone,
    Option<String?> salary = const None(),
  }) async {
    // Ignored rather than queued: a second tap while the first is in flight is a second PUT,
    // and the screen has already moved on by the time it answers.
    if (state.isSubmitting) return;

    emit(state.copyWith(isSubmitting: true, failure: null));

    final details = await _updateUser(userId: userId, name: name, email: email, phone: phone);
    if (isClosed) return;

    final saved = details.fold<AuthUser?>((_) => null, (user) => user);
    if (saved == null) {
      emit(state.copyWith(isSubmitting: false, failure: details.fold((f) => f, (_) => null)));

      return;
    }

    // The details are stored by now. If the wage is refused below, the form stays open saying
    // so — and it says it about the wage, because that is the half that did not land.
    final result = await salary.fold(
      () async => right<Failure, AuthUser>(saved),
      (value) => _setSalary(userId: userId, salary: value),
    );

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => state.copyWith(isSubmitting: false, failure: failure),
        (user) => state.copyWith(isSubmitting: false, saved: user),
      ),
    );
  }

  /// Clears a previous failure, so the error under a field disappears as the user starts
  /// correcting it rather than lingering until the next submit.
  void clearFailure() {
    if (state.failure != null) emit(state.copyWith(failure: null));
  }
}
