/// The four things that can happen to a record.
///
/// Mirrors the server's `AuditEvent`. It exists in the app only so the history screen can
/// **filter** — the words on screen still come from the entry's own `event_label`, because a
/// row written last year says what was said then, and a translation table here would quietly
/// reword it.
///
/// `restored` exists only because every model soft deletes. A schema that deleted for real
/// could never produce it.
enum AuditEvent {
  created('created', 'إنشاء'),
  updated('updated', 'تعديل'),
  deleted('deleted', 'حذف'),
  restored('restored', 'استرجاع');

  const AuditEvent(this.wire, this.label);

  /// What goes in `?event=` and what comes back in `event`.
  final String wire;

  /// What the **filter chip** says. Not what an entry says — that is the server's own
  /// `event_label`, sent with the row.
  final String label;

  /// `null` for an event this build has no case for, rather than a throw: the server may learn
  /// a fifth one, and an app already on a phone has to keep listing the other four.
  static AuditEvent? tryFromWire(String? wire) {
    for (final event in values) {
      if (event.wire == wire) return event;
    }

    return null;
  }
}
