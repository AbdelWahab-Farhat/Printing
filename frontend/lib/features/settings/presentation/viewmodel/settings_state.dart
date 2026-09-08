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
  const factory SettingsState({
    required bool notificationsEnabled,

    /// What the **phone** says, which is a different question from [notificationsEnabled].
    ///
    /// They can disagree, and that disagreement is the whole reason this field exists: the
    /// stored preference can say «مفعّل» while iOS or Android 13+ silently blocks every
    /// notification. A switch that reads yes while the phone says no is worse than no switch at
    /// all, because it stops the user looking for the real cause.
    @Default(true) bool osAllows,
  }) = _SettingsState;

  const SettingsState._();

  /// The user said yes and the phone says no — the state the row must show as blocked, with a
  /// way into the system settings.
  bool get isBlockedByOs => notificationsEnabled && !osAllows;
}
