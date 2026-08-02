/// Which kind of record a history belongs to.
///
/// **This is the whole reason there is one history screen and not six.** Every model in this
/// system keeps a complete change log — that is a standing rule, not a per-feature choice — and
/// the API hangs each one off the record itself: `/customers/7/logs`, `/products/3/logs`,
/// `/orders/12/logs`. Only the path segment and the noun differ, so those are the only two
/// things this carries.
///
/// Adding a model to the audit screen is one case here. Nothing else changes.
enum AuditSubject {
  customer('customers', 'العميل'),
  product('products', 'المنتج'),
  city('cities', 'المدينة'),
  user('users', 'المستخدم'),
  role('roles', 'الدور'),
  order('orders', 'الطلبية');

  const AuditSubject(this.path, this.noun);

  /// The API's resource segment. Also what appears in the app's own URL, so a history is
  /// linkable.
  final String path;

  /// What to call one of these in a sentence — «سجل تعديلات العميل».
  final String noun;

  /// `null` for a segment this build has no case for, rather than a throw: a deep link is
  /// somebody else's text, and a wrong one should be a polite screen, not a crash.
  static AuditSubject? tryFromPath(String? path) {
    for (final subject in values) {
      if (subject.path == path) return subject;
    }

    return null;
  }
}
