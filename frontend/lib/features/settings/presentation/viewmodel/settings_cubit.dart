import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/features/settings/usecases/get_settings.dart';
import 'package:printing/features/settings/usecases/set_notifications_enabled.dart';

part 'settings_state.dart';
part 'settings_cubit.freezed.dart';

/// The settings screen's ViewModel.
///
/// It starts *loaded* rather than loading, and that is the one decision in this file: the
/// preferences are already in memory, so a `Switch` that spent a frame in the wrong position
/// before snapping over would be an animation lying about what the device is set to.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required GetSettings getSettings,
    required SetNotificationsEnabled setNotificationsEnabled,
  }) : _setNotificationsEnabled = setNotificationsEnabled,
       super(SettingsState(notificationsEnabled: getSettings.notificationsEnabled));

  final SetNotificationsEnabled _setNotificationsEnabled;

  /// Flips the switch, then writes.
  ///
  /// The screen moves first because the store cannot meaningfully refuse — this is a `bool` in
  /// a local file, not a request — and a switch that waits for a disk write before moving feels
  /// broken to a thumb.
  Future<void> toggleNotifications({required bool isEnabled}) async {
    if (isEnabled == state.notificationsEnabled) return;

    emit(SettingsState(notificationsEnabled: isEnabled));

    await _setNotificationsEnabled(isEnabled: isEnabled);
  }
}
