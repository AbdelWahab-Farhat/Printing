part of 'settings_cubit.dart';

/// What the settings screen shows.
///
/// One case, not a union — and that is the honest shape here rather than a shortcut. A union
/// earns its place when a screen moves between states that render differently; this screen has
/// exactly one rendering, because its data is already in memory and its only write cannot fail
/// in a way the user could act on. RULES §4 asks for a sealed union over *nullable fields that
/// contradict each other*, and there are none to have.
@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState({required bool notificationsEnabled}) = _SettingsState;
}
