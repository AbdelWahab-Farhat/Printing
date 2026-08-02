import 'package:printing/features/settings/repositories/settings_repository.dart';

/// Reads this device's preferences.
///
/// Synchronous, so the screen's first frame already has the right switch position — see
/// [SettingsRepository] for why that matters more than it looks.
class GetSettings {
  const GetSettings(this._repository);

  final SettingsRepository _repository;

  bool get notificationsEnabled => _repository.notificationsEnabled;
}
