import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/access/models/role.dart';
import 'package:dayaa/features/access/usecases/delete_role.dart';
import 'package:dayaa/features/access/usecases/get_roles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'roles_cubit.freezed.dart';
part 'roles_state.dart';

/// The roles screen's ViewModel.
///
/// **Not a [PagedCubit], and that is not an oversight.** `GET /roles` answers a bare list: the
/// whole point of a role is that there are a handful of them, and paging a list of five would
/// add a scroll listener, a page counter and a footer spinner to solve a problem nobody has.
class RolesCubit extends Cubit<RolesState> {
  RolesCubit({required GetRoles getRoles, required DeleteRole deleteRole})
    : _getRoles = getRoles,
      _deleteRole = deleteRole,
      super(const RolesState.loading());

  final GetRoles _getRoles;
  final DeleteRole _deleteRole;

  Future<void> load() async {
    // Only from nothing: a reload after creating a role must not blank the list the user is
    // looking at and make the screen flash.
    if (state is! RolesLoaded) emit(const RolesState.loading());

    final result = await _getRoles();
    if (isClosed) return;

    emit(result.fold((f) => RolesState.failure(f), (roles) => RolesState.loaded(roles: roles)));
  }

  Future<void> refresh() => load();

  /// Deletes a role and reloads.
  ///
  /// Returns the outcome instead of emitting a "deleted" state, because what the screen does
  /// with it is show a snackbar and stay — and a state case whose only job is to be consumed
  /// once and cleared is a case that is still on screen the next time somebody looks.
  ///
  /// The refusals — a role the code references, or one somebody still holds — come back as the
  /// server's own Arabic, which says which it was. The app does not guess.
  Future<Either<Failure, String>> delete(Role role) async {
    final current = state;

    // Defensive: the screen only offers this on a deletable row and disables it while one is in
    // flight. Reached anyway, a generic failure is the honest answer — there is nothing about
    // the role to report.
    if (current is! RolesLoaded || current.deletingId != null) {
      return const Left(Failure.unexpected(message: FailureMessages.generic));
    }

    emit(current.copyWith(deletingId: role.id));

    final result = await _deleteRole(role.id);
    if (isClosed) return result;

    // Reloaded on success rather than removing the row here: `users_count` on every *other*
    // role is unaffected, but the list is small and one request is cheaper than a rule about
    // what else a delete could have changed.
    await result.fold(
      (failure) async => emit(current.copyWith(deletingId: null)),
      (_) async => load(),
    );

    return result;
  }
}
