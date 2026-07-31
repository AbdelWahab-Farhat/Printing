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

abstract final class CustomerEndpoints {
  static const String index = '/customers';

  static String show(int customerId) => '/customers/$customerId';

  static String activation(int customerId) => '/customers/$customerId/activation';
}
