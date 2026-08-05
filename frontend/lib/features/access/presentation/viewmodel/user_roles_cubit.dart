import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/access/models/role.dart';
import 'package:printing/features/access/usecases/get_roles.dart';
import 'package:printing/features/access/usecases/sync_user_roles.dart';
import 'package:printing/features/auth/models/auth_user.dart';

part 'user_roles_state.dart';
part 'user_roles_cubit.freezed.dart';

/// Choosing which jobs one person holds.
///
/// It owns the *pending* selection as well as the list to choose from, because the two have to
/// be shown together and the sheet must survive a rebuild without losing what has been ticked.
/// The selection is only sent when the user says so — ticking a box does not fire a request,
/// which is what makes "give them three roles" one round trip instead of three.
class UserRolesCubit extends Cubit<UserRolesState> {
  UserRolesCubit({
    required int userId,
    required Set<String> initialRoles,
    required GetRoles getRoles,
    required SyncUserRoles syncUserRoles,
  }) : _userId = userId,
       _initial = initialRoles,
       _getRoles = getRoles,
       _syncUserRoles = syncUserRoles,
       super(UserRolesState(selected: initialRoles));

  final int _userId;
  final Set<String> _initial;
  final GetRoles _getRoles;
  final SyncUserRoles _syncUserRoles;

  /// Loads the roles there are to choose from. The selection is already known — it came off the
  /// row that was tapped — so nothing about it waits for this.
  Future<void> load() async {
    emit(state.copyWith(isLoadingRoles: true, failure: null));

    final result = await _getRoles();
    if (isClosed) return;

    emit(
      result.fold(
        (failure) => state.copyWith(isLoadingRoles: false, failure: failure),
        (roles) => state.copyWith(isLoadingRoles: false, roles: roles),
      ),
    );
  }

  /// Ticks or unticks one role. Local only — see the class comment.
  void toggle(String roleName) {
    final next = {...state.selected};
    if (!next.remove(roleName)) next.add(roleName);

    // The failure goes with the first edit: an error about the previous attempt, still on
    // screen while the user changes what they are asking for, describes a request nobody made.
    emit(state.copyWith(selected: next, failure: null, saved: null));
  }

  /// Sends the whole set. A no-op while one is in flight, and when nothing has changed.
  Future<void> save() async {
    if (state.isSaving || !state.hasChangesAgainst(_initial)) return;

    emit(state.copyWith(isSaving: true, failure: null));

    final result = await _syncUserRoles(
      userId: _userId,
      roleNames: state.selected.toList()..sort(),
    );

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => state.copyWith(isSaving: false, failure: failure),
        (user) => state.copyWith(isSaving: false, saved: user),
      ),
    );
  }

  /// What the user started with — the screen compares against it to know whether to enable the
  /// save button, so it is the Cubit's to remember rather than the widget's.
  Set<String> get initialRoles => _initial;
}
