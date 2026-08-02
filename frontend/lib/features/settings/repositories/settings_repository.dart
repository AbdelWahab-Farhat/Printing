/// The preferences that belong to this device, not to the account.
///
/// Synchronous on purpose. These are read while a screen is being built — a `Switch` cannot be
/// drawn "later" without flicking from off to on in front of the user — and the store behind
/// them is already in memory by the time `runApp` is called. An async read here would buy
/// nothing and cost a loading state on a settings row.
///
/// It is a repository with no `Failure` for the same reason: there is no network, no parsing and
/// nothing to go wrong that the user could act on. `Either` on a `bool` from local storage would
/// be ceremony, and RULES §5 is about requests, which these are not.
abstract interface class SettingsRepository {
  /// Whether this device wants order and delivery notifications.
  ///
  /// Defaults to **on** for a device that has never been asked: a shop that misses an order
  /// because a default was quietly off has been let down by the app.
  bool get notificationsEnabled;

  Future<void> setNotificationsEnabled({required bool isEnabled});
}
