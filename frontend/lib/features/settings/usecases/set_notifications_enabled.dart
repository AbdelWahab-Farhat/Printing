import 'package:dayaa/features/settings/repositories/settings_repository.dart';

/// Turn notifications on or off for this device.
///
/// **Today it stores a preference and nothing more.** There is no push service wired up yet, so
/// nothing reads this but the switch itself. It is here rather than absent because the answer
/// has to survive the day the service lands: a shop that turned notifications off on the phone
/// at the counter must not start buzzing the moment push is deployed.
///
/// The verb this class exists for arrives with that service — registering or releasing the
/// device token — and it arrives *here*, in one file, rather than in the widget that owns the
/// switch.
class SetNotificationsEnabled {
  const SetNotificationsEnabled(this._repository);

  final SettingsRepository _repository;

  Future<void> call({required bool isEnabled}) =>
      _repository.setNotificationsEnabled(isEnabled: isEnabled);
}
