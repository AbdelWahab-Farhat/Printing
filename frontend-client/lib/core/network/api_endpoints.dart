/// Every path the app can call, in one place.
///
/// A URL typed inline at a call site is a URL nobody can find when the API renames it, and the
/// compiler cannot help with a string. Endpoints live here, grouped by the backend resource
/// they belong to, and they are always relative — the host comes from `AppConfig.baseUrl`.
///
/// The live contract is the generated OpenAPI spec: run the backend and open
/// http://localhost:8000/docs/api. If a path here disagrees with the spec, the spec is right.
///
/// **Everything here is under `/client`, and that prefix is the wall between the two apps.**
/// The staff API lives beside it in `routes/api.php`, guarded by `can:` against a user who holds
/// roles; this app's routes live in `routes/api_client.php` behind the `customer` guard, and a
/// customer's token cannot satisfy the other one. A path here without the prefix would be a
/// request that 401s no matter how good the token is — which is the point.
library;

/// Signing in, and the session.
///
/// **No email anywhere.** The staff app logs in with an email *or* a phone; a customer account
/// has no email at all — see Docs/customer-app/CUSTOMER-APP-DESIGN.md §٢ for why that is the
/// reason these accounts do not live in the `users` table.
abstract final class AuthEndpoints {
  static const String register = '/client/auth/register';
  static const String login = '/client/auth/login';
  static const String me = '/client/auth/me';
  static const String logout = '/client/auth/logout';
  static const String logoutAll = '/client/auth/logout-all';
}

/// What the shop is showing on the home screen.
///
/// The schedule is applied on the server — a banner whose window has closed never leaves it — so
/// this is simply «what to draw», in order.
/// What is waiting for the customer, as one number per tile.
abstract final class BadgeEndpoints {
  static const String index = '/client/badges';
}

abstract final class BillboardEndpoints {
  static const String index = '/client/billboards';
}

/// The catalogue, and what a quantity of it costs.
abstract final class CatalogEndpoints {
  static const String categories = '/client/product-categories';
  static const String products = '/client/products';

  static String product(int id) => '/client/products/$id';

  /// **A POST although it writes nothing.** The quantity and the size belong in a body, and a
  /// price that lands in a URL lands in logs and browser history.
  static String quote(int productId) => '/client/products/$productId/quote';
}

/// The customer's own artwork — uploaded once, pointed at by every order.
abstract final class DesignEndpoints {
  static const String index = '/client/designs';
  static const String store = '/client/designs';

  static String design(int id) => '/client/designs/$id';
}

/// Where an order can be sent.
///
/// **One call, never paged, and the regions come with their cities.** A destination picker is
/// one screen that has to contain every answer — a paged one is a picker somebody scrolls off
/// the end of and concludes we do not deliver to their city.
abstract final class DeliveryEndpoints {
  static const String cities = '/client/cities';
}

/// «متاجري» — متاجر العميل، ومنها تختار السلة وجهة الطلبية.
abstract final class ShopEndpoints {
  static const String index = '/client/shops';
  static const String store = '/client/shops';

  static String shop(int id) => '/client/shops/$id';

  /// منتقي «مجال العمل» في نموذج المتجر: المعروضة وحدها.
  static const String businessFields = '/client/business-fields';
}

/// «طلباتي».
///
/// The workshop's nineteen statuses reach this app as eight *stages* — the server does the
/// collapsing, so nothing here needs a table of its own. `?open=1` narrows to the ones still
/// moving.
abstract final class OrderEndpoints {
  static const String index = '/client/orders';
  static const String store = '/client/orders';

  /// تسعير السلة قبل إرسالها. POST ولا يكتب شيئاً — السطور جسمٌ لا رابط.
  static const String quote = '/client/orders/quote';

  static String order(int id) => '/client/orders/$id';
}

/// Reaching a person.
///
/// **There is no «mark as read» path**, deliberately: opening a thread marks it read, because
/// reading a conversation is what makes it read and a separate call is one this app would forget
/// on the screen where it matters.
abstract final class SupportEndpoints {
  static const String tickets = '/client/support/tickets';

  static String ticket(int id) => '/client/support/tickets/$id';

  static String messages(int ticketId) => '/client/support/tickets/$ticketId/messages';

  /// قناةُ العميل الحيّة — له وحده، والخادم يقارن الرقم برمز الدخول قبل أن يوقّع.
  static String customerChannel(int customerId) => 'private-customers.$customerId';

  /// اسمُ الحدث حين تتغيّر إحدى تذاكره — رسالة، إغلاق، إعادة فتح، قراءة. الحمولة `{ticket, message}`.
  static const String changedEvent = 'support.ticket.changed';
}

/// البثّ الحيّ.
abstract final class RealtimeEndpoints {
  /// حيث تُوقَّع قنوات العميل الخاصة. **جوابُه خارج المغلّف** — `{"auth": "…"}` كما يقرؤه Pusher.
  static const String auth = '/client/broadcasting/auth';
}
