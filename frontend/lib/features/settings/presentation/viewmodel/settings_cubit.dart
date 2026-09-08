import 'package:dayaa/core/push/push_service.dart';
import 'package:dayaa/features/settings/usecases/get_settings.dart';
import 'package:dayaa/features/settings/usecases/set_notifications_enabled.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_cubit.freezed.dart';
part 'settings_state.dart';

/// The settings screen's ViewModel.
///
/// It starts *loaded* rather than loading, and that is the one decision in this file: the
/// preferences are already in memory, so a `Switch` that spent a frame in the wrong position
/// before snapping over would be an animation lying about what the device is set to.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required GetSettings getSettings,
    required SetNotificationsEnabled setNotificationsEnabled,
    required PushService push,
  }) : _setNotificationsEnabled = setNotificationsEnabled,
       _push = push,
       super(SettingsState(notificationsEnabled: getSettings.notificationsEnabled));

  final SetNotificationsEnabled _setNotificationsEnabled;
  final PushService _push;

  /// Asks the phone what it currently allows, without prompting.
  ///
  /// Called when the screen opens and again on resume, because the user may have just come back
  /// from the system settings having granted it.
  Future<void> refreshOsPermission() async {
    final allows = await _push.hasOsPermission();
    if (isClosed) return;

    emit(state.copyWith(osAllows: allows));
  }

  /// Flips the switch, then writes.
  ///
  /// The screen moves first because the store cannot meaningfully refuse — this is a `bool` in
  /// a local file, not a request — and a switch that waits for a disk write before moving feels
  /// broken to a thumb.
  Future<void> toggleNotifications({required bool isEnabled}) async {
    if (isEnabled == state.notificationsEnabled) return;

    emit(state.copyWith(notificationsEnabled: isEnabled));

    await _setNotificationsEnabled(isEnabled: isEnabled);

    // The preference and the server's device registry are two different facts, and this is the
    // only place that keeps them in step outside sign-in and sign-out.
    //
    // **Turning it off releases the token rather than just remembering a `false`.** A device
    // that stays registered would go on being pushed to; the switch would have changed nothing
    // the user could observe.
    if (isEnabled) {
      final registered = await _push.register();
      if (isClosed) return;
      // Refused at the OS level: the stored preference stays *on*, because the user's answer to
      // our question is still yes and must survive them granting permission later. The row
      // shows blocked instead.
      emit(state.copyWith(osAllows: registered));
    } else {
      await _push.release();
    }
  }
}
