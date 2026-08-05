import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/access/models/role.dart';
import 'package:printing/features/access/usecases/create_role.dart';
import 'package:printing/features/access/usecases/get_permissions.dart';
import 'package:printing/features/access/usecases/update_role.dart';

part 'role_form_state.dart';
part 'role_form_cubit.freezed.dart';

/// Creating a role, and editing one. The same screen, because it is the same two questions:
/// what is it called, and what may it do.
///
/// **The ticked set lives here, not in the widget.** It has to survive a rebuild — the
/// catalogue arrives after the first frame, the keyboard opens and closes over the name field,
/// and a 422 redraws the form — and a `setState` set would lose twenty ticks to any of those.
///
/// The catalogue is fetched, not read off `AppPermission`: the sections are the server's, and a
/// build that is behind the API should still be able to grant the permission it cannot name.
class RoleFormCubit extends Cubit<RoleFormState> {
  RoleFormCubit({
    required GetPermissions getPermissions,
    required CreateRole createRole,
    required UpdateRole updateRole,
  }) : _getPermissions = getPermissions,
       _createRole = createRole,
       _updateRole = updateRole,
       super(const RoleFormState());

  final GetPermissions _getPermissions;
  final CreateRole _createRole;
  final UpdateRole _updateRole;

  /// Loads the catalogue and, when editing, seeds the ticks from the role being edited.
  Future<void> load({Role? editing}) async {
    emit(
      state.copyWith(
        isLoadingCatalogue: true,
        // Seeded from the role rather than fetched again: the list that opened this screen
        // already carried its permissions, and asking twice for the same answer is a wait the
        // user pays for nothing.
        selected: editing?.permissionNames ?? const <String>{},
        failure: null,
      ),
    );

    final result = await _getPermissions();
    if (isClosed) return;

    emit(
      result.fold(
        (failure) => state.copyWith(isLoadingCatalogue: false, failure: failure),
        (catalogue) => state.copyWith(isLoadingCatalogue: false, catalogue: catalogue),
      ),
    );
  }

  void toggle(String permissionName) {
    final next = {...state.selected};
    if (!next.remove(permissionName)) next.add(permissionName);

    emit(state.copyWith(selected: next, failure: null));
  }

  /// Ticks or unticks a whole section at once.
  ///
  /// «حالات الطلبيات» alone is ten checkboxes, and a delivery coordinator wants all of them.
  /// Partly-ticked counts as off, so one tap fills the section — which is the direction people
  /// mean when they reach for a group toggle.
  void toggleGroup(PermissionGroup group) {
    final names = group.names;
    final next = {...state.selected};

    if (names.every(next.contains)) {
      next.removeAll(names);
    } else {
      next.addAll(names);
    }

    emit(state.copyWith(selected: next, failure: null));
  }

  /// Sends the form. Creates when [roleId] is null, saves when it is not.
  ///
  /// One method for both, because the screen, the validation and the 422 mapping are identical
  /// — only which use case is called differs.
  Future<void> submit({int? roleId, required String name}) async {
    // Ignored rather than queued: a second tap while the first request is in flight would
    // create a second role, and the unique name would make it a 422 rather than a duplicate —
    // but the screen has already moved on by the time either answers.
    if (state.isSubmitting) return;

    emit(state.copyWith(isSubmitting: true, failure: null));

    final permissions = state.selected.toList()..sort();

    final result = roleId == null
        ? await _createRole(name: name, permissions: permissions)
        : await _updateRole(roleId: roleId, name: name, permissions: permissions);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => state.copyWith(isSubmitting: false, failure: failure),
        (role) => state.copyWith(isSubmitting: false, saved: role),
      ),
    );
  }

  /// Clears a previous failure, so the error under the name field disappears as the user starts
  /// correcting it rather than lingering until the next submit.
  void clearFailure() {
    if (state.failure != null) emit(state.copyWith(failure: null));
  }
}
