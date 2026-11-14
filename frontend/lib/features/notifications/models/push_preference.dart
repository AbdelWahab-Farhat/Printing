import 'package:freezed_annotation/freezed_annotation.dart';

part 'push_preference.freezed.dart';
part 'push_preference.g.dart';

/// One notification type on an employee's push settings — Docs/notifications/PUSH-PREFERENCES.md.
///
/// A type that is one switch carries a single [PushSwitch] whose `scope` is `''`; `order.status`
/// carries one per status that rings.
///
/// **Only group notifications are listed.** What reaches the employee by name always pushes,
/// and the bell is never switched off — the server leaves those out rather than sending switches
/// that would do nothing.
@freezed
abstract class PushPreferenceGroup with _$PushPreferenceGroup {
  const factory PushPreferenceGroup({
    required String type,
    required String label,
    required String icon,
    required List<PushSwitch> switches,
  }) = _PushPreferenceGroup;

  const PushPreferenceGroup._();

  factory PushPreferenceGroup.fromJson(Map<String, dynamic> json) =>
      _$PushPreferenceGroupFromJson(json);

  /// Drawn as one row, not a heading over rows.
  bool get isSingle => switches.length == 1 && switches.first.scope.isEmpty;
}

/// Whether one kind of group notification wakes the employee's phone.
@freezed
abstract class PushSwitch with _$PushSwitch {
  const factory PushSwitch({required String scope, required String label, required bool push}) =
      _PushSwitch;

  factory PushSwitch.fromJson(Map<String, dynamic> json) => _$PushSwitchFromJson(json);
}
