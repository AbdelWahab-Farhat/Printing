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
  order('orders', 'الطلبية'),

  /// A supplier. The path segment matches the API's, so the history screen's own URL is the
  /// record's — see the note on [path].
  vendor('vendors', 'المورد'),

  /// The paperwork raised against one. Its lines share this history: the server returns the
  /// document's entries and its items' together, because a quantity changing is a change to
  /// the order.
  purchaseOrder('purchase-orders', 'أمر الشراء'),

  /// A standing manufacturing cost. Its history is the one that answers «منذ متى ونحن نحسب
  /// العمالة بهذا الرقم؟», which no order can answer on its own: an order keeps the amount it was
  /// charged, never the rate that produced it.
  manufacturingCostRate('manufacturing-cost-rates', 'معدل تكلفة التصنيع');

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
