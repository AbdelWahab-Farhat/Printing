import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/access/usecases/get_user.dart';
import 'package:dayaa/features/access/usecases/set_user_activation.dart';
import 'package:dayaa/features/access/usecases/set_user_password.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'employee_detail_cubit.freezed.dart';
part 'employee_detail_state.dart';

/// One employee, and the two things this screen changes about them without leaving it.
///
/// **Editing the details is not here, and neither are the roles or the wage.** All three open
/// something that owns its own state — a form and a sheet — and this Cubit re-reads afterwards,
/// which is also what makes a change somebody else made on another device show up. The wage
/// travels with the form because that is where it is typed, even though it leaves by an
/// endpoint of its own: see `EmployeeFormCubit`.
///
/// What *is* here is the work that is one tap and one request: the password, and stopping the
/// account. Each keeps the employee on screen while it is in flight, because replacing a page
/// of information with a spinner to flip one flag throws away everything the reader was
/// looking at.
class EmployeeDetailCubit extends Cubit<EmployeeDetailState> {
  EmployeeDetailCubit({
    required int userId,
    required GetUser getUser,
    required SetUserPassword setPassword,
    required SetUserActivation setActivation,
  }) : _userId = userId,
       _getUser = getUser,
       _setPassword = setPassword,
       _setActivation = setActivation,
       super(const EmployeeDetailState.loading());

  final int _userId;
  final GetUser _getUser;
  final SetUserPassword _setPassword;
  final SetUserActivation _setActivation;

  Future<void> load() async {
    // Only from nothing: a reload after an edit must not blank the screen being read.
    if (state.user == null) emit(const EmployeeDetailState.loading());

    final result = await _getUser(_userId);
    if (isClosed) return;

    emit(result.fold(EmployeeDetailState.failure, EmployeeDetailState.loaded));
  }

  /// Sets a new password. Administrators only — the server refuses everybody else.
  ///
  /// **The answer replaces the employee on screen exactly as the others do**, and carries no
  /// password with it: the response is the account, and nothing about the credential just set
  /// is ever held in this Cubit.
  /// Takes a reading the caller already has — the edit form's saved copy, or the one the roles
  /// sheet answered with, both straight from the server.
  ///
  /// The alternative was [load], which is a request for something this screen was just handed.
  /// A pull still re-reads, and so does the retry on the failure view.
  void show(AuthUser user) {
    if (isClosed) return;

    emit(EmployeeDetailState.loaded(user));
  }

  Future<bool> setPassword(String password) {
    return _change(() => _setPassword(userId: _userId, password: password));
  }

  Future<bool> setActive({required bool isActive}) {
    return _change(() => _setActivation(_userId, isActive: isActive));
  }

  /// The shape both share: keep the employee visible, run the request, put back whichever
  /// answer came.
  ///
  /// Returns whether it worked, so the sheet that called it knows whether to close. A sheet
  /// that closed on a 422 would take the typed value with it and leave the reason on a snackbar
  /// behind it.
  Future<bool> _change(
    Future<Either<Failure, AuthUser>> Function() request,
  ) async {
    final current = state.user;
    if (current == null || state.isChanging) return false;

    emit(EmployeeDetailState.changing(current));

    final result = await request();
    if (isClosed) return false;

    return result.fold(
      (failure) {
        // The employee stays on screen and the failure goes to a snackbar, unlike the customer
        // screen which replaces the page: here the reader has usually just typed something into
        // a sheet, and a page swapped for an error would lose the number they are correcting.
        emit(EmployeeDetailState.loaded(current, failure: failure));

        return false;
      },
      (updated) {
        emit(EmployeeDetailState.loaded(updated));

        return true;
      },
    );
  }
}
