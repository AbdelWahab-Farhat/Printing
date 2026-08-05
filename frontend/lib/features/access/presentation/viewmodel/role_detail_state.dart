part of 'role_detail_cubit.dart';

/// Everything the role screen can be.
@freezed
sealed class RoleDetailState with _$RoleDetailState {
  const factory RoleDetailState.loading() = RoleDetailLoading;

  const factory RoleDetailState.loaded({
    required Role role,

    /// The role's own permissions, already sorted into the catalogue's sections.
    ///
    /// Computed in the Cubit rather than in the widget, because it is a rule about data — which
    /// permission belongs to which part of the business — and the screen's job is to draw the
    /// answer, not work it out. Empty for a role that grants nothing, **and for the
    /// administrator**, whose access comes from a gate rule rather than rows: see
    /// [Role.grantsEverything], which is what the screen shows instead.
    required List<PermissionGroup> groups,
  }) = RoleDetailLoaded;

  const factory RoleDetailState.failure(Failure failure) = RoleDetailFailure;
}
