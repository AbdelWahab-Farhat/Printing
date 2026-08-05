/// Every path the app can call, in one place.
///
/// A URL typed inline at a call site is a URL nobody can find when the API renames it, and the
/// compiler cannot help with a string. Endpoints live here, grouped by the backend resource
/// they belong to, and they are always relative — the host comes from `AppConfig.baseUrl`.
///
/// The live contract is the generated OpenAPI spec: run the backend and open
/// http://localhost:8000/docs/api. If a path here disagrees with the spec, the spec is right.
library;

abstract final class AuthEndpoints {
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';
  static const String logoutAll = '/auth/logout-all';
}

/// Who works here, what jobs exist, and what each job may do.
abstract final class AccessEndpoints {
  /// Staff accounts. Read-only from the app: accounts are created elsewhere, and all this
  /// screen changes is which roles somebody holds.
  static const String users = '/users';

  /// Replaces a user's whole set of roles — send every role they should end up with.
  static String userRoles(int userId) => '/users/$userId/roles';

  static const String roles = '/roles';

  static String role(int roleId) => '/roles/$roleId';

  /// The catalogue of everything the system can check for, already grouped into the sections a
  /// role screen renders. Read-only by design: a permission is real only because code checks
  /// for it, so there is nothing here to create.
  static const String permissions = '/permissions';
}

abstract final class CityEndpoints {
  static const String index = '/cities';

  static String show(int cityId) => '/cities/$cityId';

  static String regions(int cityId) => '/cities/$cityId/regions';

  static String region(int cityId, int regionId) => '/cities/$cityId/regions/$regionId';
}

abstract final class ProductEndpoints {
  static const String index = '/products';

  static String show(int productId) => '/products/$productId';

  static String quote(int productId) => '/products/$productId/quote';
}

abstract final class OrderEndpoints {
  static const String index = '/orders';

  /// How many orders sit in each status, under the same filters as the list.
  static const String summary = '/orders/summary';

  static String show(int orderId) => '/orders/$orderId';

  /// Moving an order. A POST, not a PATCH: the server records a row on the order's timeline as
  /// well as changing the field, so it is an event rather than an edit to a value.
  static String status(int orderId) => '/orders/$orderId/status';

  static String designs(int orderId) => '/orders/$orderId/designs';

  static String reviewDesign(int orderId, int designId) =>
      '/orders/$orderId/designs/$designId/review';
}

abstract final class CustomerEndpoints {
  static const String index = '/customers';

  static String show(int customerId) => '/customers/$customerId';

  static String activation(int customerId) => '/customers/$customerId/activation';

  /// A customer's artwork. Nested under the customer because the API scopes it that way —
  /// another customer's design id is a 404 by construction rather than by a check.
  static String designs(int customerId) => '/customers/$customerId/designs';

  static String design(int customerId, int designId) =>
      '/customers/$customerId/designs/$designId';
}
