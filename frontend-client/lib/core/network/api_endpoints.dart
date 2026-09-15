/// Every path the app can call, in one place.
///
/// A URL typed inline at a call site is a URL nobody can find when the API renames it, and the
/// compiler cannot help with a string. Endpoints live here, grouped by the backend resource
/// they belong to, and they are always relative — the host comes from `AppConfig.baseUrl`.
///
/// The live contract is the generated OpenAPI spec: run the backend and open
/// http://localhost:8000/docs/api. If a path here disagrees with the spec, the spec is right.
///
/// > **The customer-facing half of that API does not exist yet.** `routes/api.php` today is the
/// > staff surface, every route behind a `can:` built for an employee. So this file holds the
/// > authentication paths — which are shared — and nothing else. Add a group here the day the
/// > backend answers it, not before: an endpoint nothing calls is a promise the server has not
/// > made.
library;

abstract final class AuthEndpoints {
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';
  static const String logoutAll = '/auth/logout-all';
}
