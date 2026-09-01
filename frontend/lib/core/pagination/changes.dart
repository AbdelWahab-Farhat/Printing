/// What a detail screen hands back to the list it was opened from.
///
/// The other half of `PagedCubit`'s patching. That one can replace a row without a request —
/// but only if somebody gives it the new row, and only if it is told when there is nothing to
/// give. This is that somebody.
///
/// A detail screen watches its own Cubit and calls [saw] with every reading that goes past. On
/// the way out it pops [result], which is the newest reading **when it differs from the first**
/// and null when it does not. So:
///
///   * opened, read, backed out → null → the list does not move,
///   * edited, deactivated, a status moved → the new row → the list redraws it in place,
///   * edited and edited back → null, because the row behind already looks like that.
///
/// **Against the first reading rather than the previous one**, which is what makes the third
/// case work: the question is not "did anything happen on this screen" but "is the row behind me
/// out of date", and those differ exactly when a change was undone.
///
/// Equality is the model's, and every model here is Freezed — so this compares what the row
/// says, not which object says it.
class Changes<T> {
  T? _first;
  T? _latest;

  /// One reading of the thing this screen is about. Null states — loading, a failure before
  /// anything arrived — are not readings and are ignored.
  void saw(T? reading) {
    if (reading == null) return;

    _first ??= reading;
    _latest = reading;
  }

  /// The row worth handing back, or null when the list behind is already showing it.
  T? get result => _latest == _first ? null : _latest;
}
