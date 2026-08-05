import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/access/models/role.dart';
import 'package:printing/features/access/usecases/create_user.dart';
import 'package:printing/features/access/usecases/get_roles.dart';
import 'package:printing/features/auth/models/auth_user.dart';

part 'add_employee_state.dart';
part 'add_employee_cubit.freezed.dart';

/// Registering a colleague: the account, and the jobs it starts with.
///
/// It loads the roles as well as submitting, because the two belong to one screen — an account
/// created with no role can sign in and do nothing, and making that a second trip through a
/// second screen is how it ends up being the normal outcome.
///
/// **The roles are optional and the list may fail to load without blocking the form.** The
/// account is the thing being created; roles can be set afterwards from the same list this
/// screen was opened from, so a dropped connection while fetching them must not stop somebody
/// registering the person standing in front of them.
class AddEmployeeCubit extends Cubit<AddEmployeeState> {
  AddEmployeeCubit({required GetRoles getRoles, required CreateUser createUser})
    : _getRoles = getRoles,
      _createUser = createUser,
      super(const AddEmployeeState());

  final GetRoles _getRoles;
  final CreateUser _createUser;

  Future<void> loadRoles() async {
    emit(state.copyWith(isLoadingRoles: true));

    final result = await _getRoles();
    if (isClosed) return;

    emit(
      result.fold(
        // Deliberately not put in `failure`: that field is the *form's* error, and an
        // unreachable role list is not a reason to paint the name box red.
        (failure) => state.copyWith(isLoadingRoles: false),
        (roles) => state.copyWith(isLoadingRoles: false, roles: roles),
      ),
    );
  }

  void toggleRole(String roleName) {
    final next = {...state.selectedRoles};
    if (!next.remove(roleName)) next.add(roleName);

    emit(state.copyWith(selectedRoles: next, failure: null));
  }

  /// Sends the form.
  ///
  /// **A `Failure.network` here is not safe to retry blindly**, and the screen says so. Both the
  /// email and the phone are unique in the database, so a request that did reach the server
  /// before the connection dropped makes the retry a 422 rather than a second account — which is
  /// the one fact that makes "أعد المحاولة" honest. The 422 is then the truthful answer: the
  /// account exists.
  Future<void> submit({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    // Ignored rather than queued: a second tap while the first request is in flight would be a
    // second POST, and the screen has already moved on by the time it answers.
    if (state.isSubmitting) return;

    emit(state.copyWith(isSubmitting: true, failure: null));

    final result = await _createUser(
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      password: password,
      roleNames: state.selectedRoles.toList()..sort(),
    );

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => state.copyWith(isSubmitting: false, failure: failure),
        (user) => state.copyWith(isSubmitting: false, created: user),
      ),
    );
  }

  /// Clears a previous failure, so the error under a field disappears as the user starts
  /// correcting it rather than lingering until the next submit.
  void clearFailure() {
    if (state.failure != null) emit(state.copyWith(failure: null));
  }
}
