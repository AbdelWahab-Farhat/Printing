import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/access/models/role.dart';
import 'package:printing/features/access/usecases/get_permissions.dart';
import 'package:printing/features/access/usecases/get_role.dart';

part 'role_detail_state.dart';
part 'role_detail_cubit.freezed.dart';

/// One role: what it is, who holds it, and — the point of the screen — **what it actually
/// grants, in sections somebody can read.**
///
/// It fetches two things, and needs both before it can draw anything useful: the role, whose
/// permissions arrive as one flat list of twenty-odd Arabic phrases, and the catalogue, which is
/// what says «تحويل الطلبية إلى جاهزة» belongs under «حالات الطلبيات». A flat list is technically
/// the same information and practically unreadable, so the grouping is not decoration.
///
/// The two requests go out **together**, not one after the other: they do not depend on each
/// other, and serialising them would double the wait for no reason.
class RoleDetailCubit extends Cubit<RoleDetailState> {
  RoleDetailCubit({
    required int roleId,
    required GetRole getRole,
    required GetPermissions getPermissions,
  }) : _roleId = roleId,
       _getRole = getRole,
       _getPermissions = getPermissions,
       super(const RoleDetailState.loading());

  final int _roleId;
  final GetRole _getRole;
  final GetPermissions _getPermissions;

  Future<void> load() async {
    // Only from nothing: coming back from the edit screen reloads, and blanking a screen the
    // user is reading to show a spinner they did not ask for is the wrong answer.
    if (state is! RoleDetailLoaded) emit(const RoleDetailState.loading());

    // Both futures are created before either is awaited, so the requests overlap. `Future.wait`
    // would do the same but flatten the two result types into one list and need a cast back.
    final roleRequest = _getRole(_roleId);
    final catalogueRequest = _getPermissions();

    final roleResult = await roleRequest;
    final catalogueResult = await catalogueRequest;

    if (isClosed) return;

    // The role decides whether there is a screen at all. Without it there is nothing to show,
    // so its failure wins.
    roleResult.fold(
      (failure) => emit(RoleDetailState.failure(failure)),
      (role) => emit(
        RoleDetailState.loaded(
          role: role,
          // A catalogue that failed does not blank the screen: the role is what the user came
          // for, and its permissions still list — just ungrouped, under one heading. Falling
          // back to nothing here would hide the whole answer to protect a subheading.
          groups: groupHeldPermissions(
            held: role.permissionNames,
            catalogue: catalogueResult.getOrElse(() => const []),
          ),
        ),
      ),
    );
  }

  Future<void> refresh() => load();
}
