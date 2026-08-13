import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/api_endpoints.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/network/safe_request.dart';
import 'package:printing/features/access/models/role.dart';
import 'package:printing/features/access/repositories/access_repository.dart';
import 'package:printing/features/auth/models/auth_user.dart';

/// Fulfils [AccessRepository] over HTTP.
///
/// The request bodies are assembled here, so the fact that the API spells the field
/// `permissions` and expects machine names rather than labels never leaves this file.
class AccessRepositoryImpl implements AccessRepository {
  const AccessRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<AuthUser>>> users({
    String? search,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<AuthUser>(
      () => _dio.get(
        AccessEndpoints.users,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          // Omitted rather than sent as null: a null in a query string arrives as the literal
          // "null" and the API would filter on it.
          if (search != null && search.isNotEmpty) 'search': search,
        },
      ),
      parseItem: AuthUser.fromJson,
    );
  }

  @override
  Future<Either<Failure, AuthUser>> createUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    List<String> roleNames = const [],
  }) {
    return safeRequest<AuthUser>(
      () => _dio.post(
        AccessEndpoints.users,
        data: <String, dynamic>{
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          // Laravel's `confirmed` rule looks for exactly this key. The form asks for the
          // password twice and checks them itself, so by here they are known to match — the
          // server checks again because it is the one that decides.
          'password_confirmation': password,
          'roles': roleNames,
        },
      ),
      parse: (data) => AuthUser.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, AuthUser>> user(int userId) {
    return safeRequest<AuthUser>(
      () => _dio.get(AccessEndpoints.user(userId)),
      parse: (data) => AuthUser.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, AuthUser>> updateUser({
    required int userId,
    required String name,
    required String email,
    required String phone,
  }) {
    return safeRequest<AuthUser>(
      () => _dio.put(
        AccessEndpoints.user(userId),
        // Three keys and no fourth. A `password` here would be ignored by the server, and
        // sending one anyway would put a live credential in a log for nothing.
        data: <String, dynamic>{'name': name, 'email': email, 'phone': phone},
      ),
      parse: (data) => AuthUser.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, AuthUser>> setUserPassword(int userId, String password) {
    return safeRequest<AuthUser>(
      () => _dio.patch(
        AccessEndpoints.userPassword(userId),
        data: <String, dynamic>{
          'password': password,
          // Laravel's `confirmed` rule looks for exactly this key. The sheet asks twice and
          // checks them itself, so by here they match — the server checks again because it is
          // the one that decides.
          'password_confirmation': password,
        },
      ),
      parse: (data) => AuthUser.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, AuthUser>> setUserSalary(int userId, String? salary) {
    return safeRequest<AuthUser>(
      () => _dio.patch(
        AccessEndpoints.userSalary(userId),
        // Sent even when null, unlike every optional query parameter in this file: the endpoint
        // requires the key to be present, because an explicit null is how «لم يُحدَّد» is
        // recorded and an absent one would be indistinguishable from a half-built request.
        data: <String, dynamic>{'salary': salary},
      ),
      parse: (data) => AuthUser.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, AuthUser>> setUserActivation(int userId, {required bool isActive}) {
    return safeRequest<AuthUser>(
      () => _dio.patch(
        AccessEndpoints.userActivation(userId),
        data: <String, dynamic>{'is_active': isActive},
      ),
      parse: (data) => AuthUser.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, AuthUser>> syncUserRoles(int userId, List<String> roleNames) {
    return safeRequest<AuthUser>(
      () => _dio.patch(
        AccessEndpoints.userRoles(userId),
        data: <String, dynamic>{'roles': roleNames},
      ),
      parse: (data) => AuthUser.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, List<Role>>> roles() {
    return safeRequest<List<Role>>(
      () => _dio.get(AccessEndpoints.roles),
      parse: _parseRoles,
    );
  }

  @override
  Future<Either<Failure, Role>> role(int roleId) {
    return safeRequest<Role>(
      () => _dio.get(AccessEndpoints.role(roleId)),
      parse: (data) => Role.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Role>> createRole({
    required String name,
    required List<String> permissions,
  }) {
    return safeRequest<Role>(
      () => _dio.post(
        AccessEndpoints.roles,
        data: <String, dynamic>{'name': name, 'permissions': permissions},
      ),
      parse: (data) => Role.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Role>> updateRole({
    required int roleId,
    required String name,
    List<String>? permissions,
  }) {
    return safeRequest<Role>(
      () => _dio.put(
        AccessEndpoints.role(roleId),
        data: <String, dynamic>{
          'name': name,
          // Omitted, not sent as null: the endpoint reads "no `permissions` key" as «leave the
          // set alone» and an empty array as «strip every permission». A null would be neither.
          'permissions': ?permissions,
        },
      ),
      parse: (data) => Role.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, String>> deleteRole(int roleId) {
    return safeCommand(() => _dio.delete(AccessEndpoints.role(roleId)));
  }

  @override
  Future<Either<Failure, List<PermissionGroup>>> permissions() {
    return safeRequest<List<PermissionGroup>>(
      () => _dio.get(AccessEndpoints.permissions),
      parse: (data) => (data as List)
          .whereType<Map<String, dynamic>>()
          .map(PermissionGroup.fromJson)
          .toList(growable: false),
    );
  }

  /// `GET /roles` answers a bare list rather than a page — there are few roles by definition,
  /// so the endpoint does not paginate and neither does this.
  List<Role> _parseRoles(dynamic data) => (data as List)
      .whereType<Map<String, dynamic>>()
      .map(Role.fromJson)
      .toList(growable: false);
}
