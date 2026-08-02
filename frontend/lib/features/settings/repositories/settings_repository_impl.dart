import 'package:printing/features/settings/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fulfils [SettingsRepository] over `SharedPreferences`.
///
/// Not the secure store: a notification preference is not a secret, and `flutter_secure_storage`
/// is asynchronous and hits the Keychain — both of which this has no use for. RULES §10 puts the
/// token there and everything else here, and this is the "everything else".
class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._prefs);

  /// The stored key. Namespaced, because `SharedPreferences` is one flat map shared with every
  /// plugin in the app.
  static const String notificationsKey = 'settings.notifications_enabled';

  final SharedPreferences _prefs;

  @override
  bool get notificationsEnabled => _prefs.getBool(notificationsKey) ?? true;

  @override
  Future<void> setNotificationsEnabled({required bool isEnabled}) =>
      _prefs.setBool(notificationsKey, isEnabled);
}
