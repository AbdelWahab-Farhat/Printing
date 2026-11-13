import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/notifications/models/push_preference.dart';
import 'package:dayaa/features/notifications/usecases/get_push_preferences.dart';
import 'package:dayaa/features/notifications/usecases/set_push_preference.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'push_preferences_cubit.freezed.dart';
part 'push_preferences_state.dart';

/// One employee's push switches — Docs/notifications/PUSH-PREFERENCES.md.
///
/// **A switch moves the moment it is tapped**, and moves back if the server refuses. The answer
/// the server sends is not laid over the screen: two switches tapped in quick succession would
/// otherwise have the first answer flick the second one back until its own answer arrived.
class PushPreferencesCubit extends Cubit<PushPreferencesState> {
  PushPreferencesCubit({
    required int userId,
    required GetPushPreferences getPreferences,
    required SetPushPreference setPreference,
  }) : _userId = userId,
       _getPreferences = getPreferences,
       _setPreference = setPreference,
       super(const PushPreferencesState.loading());

  final int _userId;
  final GetPushPreferences _getPreferences;
  final SetPushPreference _setPreference;

  Future<void> load() async {
    if (state.groups == null) emit(const PushPreferencesState.loading());

    final result = await _getPreferences(_userId);
    if (isClosed) return;

    emit(result.fold(PushPreferencesState.failure, PushPreferencesState.loaded));
  }

  Future<void> toggle({required String type, required String scope, required bool push}) async {
    final groups = state.groups;
    if (groups == null) return;

    emit(PushPreferencesState.loaded(_flip(groups, type, scope, push)));

    final result = await _setPreference(userId: _userId, type: type, scope: scope, push: push);
    if (isClosed) return;

    result.fold((failure) {
      // Back to what it was, and only this switch: another one tapped meanwhile keeps its
      // own new position.
      final now = state.groups ?? groups;
      emit(PushPreferencesState.loaded(_flip(now, type, scope, !push), failure: failure));
    }, (_) {});
  }

  static List<PushPreferenceGroup> _flip(
    List<PushPreferenceGroup> groups,
    String type,
    String scope,
    bool push,
  ) => [
    for (final group in groups)
      group.type != type
          ? group
          : group.copyWith(
              switches: [
                for (final s in group.switches) s.scope == scope ? s.copyWith(push: push) : s,
              ],
            ),
  ];
}
