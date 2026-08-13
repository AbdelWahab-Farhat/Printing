import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/api_endpoints.dart';
import 'package:printing/core/network/safe_request.dart';
import 'package:printing/features/customers/models/customer_comment.dart';
import 'package:printing/features/customers/repositories/customer_comment_repository.dart';

/// Fulfils [CustomerCommentRepository] over HTTP.
class CustomerCommentRepositoryImpl implements CustomerCommentRepository {
  const CustomerCommentRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, List<CustomerComment>>> comments(int customerId) {
    return safeRequest<List<CustomerComment>>(
      () => _dio.get(CustomerEndpoints.comments(customerId)),
      // `safeRequest`, not `safePaginatedRequest`: `data` is the bare list with no `meta`
      // beside it, and the paginated parser would report a malformed response for a reply that
      // is exactly what the API promised.
      parse: (data) => (data! as List)
          .whereType<Map<String, dynamic>>()
          .map(CustomerComment.fromJson)
          .toList(growable: false),
    );
  }

  @override
  Future<Either<Failure, CustomerComment>> add(int customerId, {required String body}) {
    return safeRequest<CustomerComment>(
      () => _dio.post(
        CustomerEndpoints.comments(customerId),
        data: <String, dynamic>{'body': body.trim()},
      ),
      parse: (data) => CustomerComment.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, CustomerComment>> edit(
    int customerId,
    int commentId, {
    required String body,
  }) {
    return safeRequest<CustomerComment>(
      () => _dio.patch(
        CustomerEndpoints.comment(customerId, commentId),
        data: <String, dynamic>{'body': body.trim()},
      ),
      parse: (data) => CustomerComment.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, String>> remove(int customerId, int commentId) {
    // A command: there is no body to parse and nothing left to show, so the answer is the
    // server's own message.
    return safeCommand(() => _dio.delete(CustomerEndpoints.comment(customerId, commentId)));
  }
}
