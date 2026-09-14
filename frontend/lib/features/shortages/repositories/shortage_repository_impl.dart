import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:dayaa/features/shortages/models/shortage_counts.dart';
import 'package:dayaa/features/shortages/models/shortage_supply.dart';
import 'package:dayaa/features/shortages/repositories/shortage_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [ShortageRepository] over HTTP.
///
/// The fact that the API spells the assignment `PATCH .../assignee` and the undo
/// `POST .../supplies/{id}/reversal` never leaves this file.
class ShortageRepositoryImpl implements ShortageRepository {
  const ShortageRepositoryImpl(this._dio);

  final Dio _dio;

  /// The filters both the list and the board are asked with, in one place.
  ///
  /// **Omitted rather than sent as null.** The list endpoint reads its filters without validating
  /// them, so a literal `"null"` reaching an enum is a 500 rather than an empty page — the same
  /// idiom `PurchaseOrderRepositoryImpl` uses.
  Map<String, dynamic> _filters({
    String? assignedTo,
    int? productId,
    int? orderId,
    int? customerId,
    String? source,
    String? search,
  }) => <String, dynamic>{
    'assigned_to': ?assignedTo,
    'product_id': ?productId,
    'order_id': ?orderId,
    'customer_id': ?customerId,
    'source': ?source,
    'search': ?search,
  };

  @override
  Future<Either<Failure, Paginated<Shortage>>> shortages({
    List<String> statuses = const <String>[],
    String? assignedTo,
    int? productId,
    int? orderId,
    int? customerId,
    String? source,
    String? search,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<Shortage>(
      () => _dio.get(
        ShortageEndpoints.index,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          // A list, sent as `status[]=new&status[]=searching` by the client's `multiCompatible`
          // format. One status travels the same way and is read the same way.
          if (statuses.isNotEmpty) 'status': statuses,
          ..._filters(
            assignedTo: assignedTo,
            productId: productId,
            orderId: orderId,
            customerId: customerId,
            source: source,
            search: search,
          ),
        },
      ),
      parseItem: Shortage.fromJson,
    );
  }

  @override
  Future<Either<Failure, ShortageCounts>> statusCounts({
    String? assignedTo,
    int? productId,
    int? orderId,
    int? customerId,
    String? source,
    String? search,
  }) {
    return safeRequest<ShortageCounts>(
      // **No `status` here, and that is the point of the board.** The server ignores it anyway;
      // sending it would only suggest to the next reader that it mattered.
      () => _dio.get(
        ShortageEndpoints.summary,
        queryParameters: _filters(
          assignedTo: assignedTo,
          productId: productId,
          orderId: orderId,
          customerId: customerId,
          source: source,
          search: search,
        ),
      ),
      parse: (data) => ShortageCounts.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Shortage>> shortage(int shortageId) {
    return safeRequest<Shortage>(
      () => _dio.get(ShortageEndpoints.show(shortageId)),
      parse: (data) => Shortage.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Shortage>> create({
    required String name,
    required String quantity,
    int? productId,
    int? productVariantId,
    String? unit,
    int? assignedToUserId,
    String? description,
  }) {
    return safeRequest<Shortage>(
      () => _dio.post(
        ShortageEndpoints.index,
        data: <String, dynamic>{
          'name': name,
          'required_quantity': quantity,
          'product_id': ?productId,
          'product_variant_id': ?productVariantId,
          'unit': ?unit,
          'assigned_to_user_id': ?assignedToUserId,
          'description': ?description,
        },
      ),
      parse: (data) => Shortage.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Shortage>> update(
    int shortageId, {
    required String name,
    required String quantity,
    int? assignedToUserId,
    String? description,
  }) {
    return safeRequest<Shortage>(
      () => _dio.put(
        ShortageEndpoints.show(shortageId),
        data: <String, dynamic>{
          'name': name,
          'required_quantity': quantity,
          'assigned_to_user_id': ?assignedToUserId,
          'description': ?description,
        },
      ),
      parse: (data) => Shortage.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Shortage>> changeStatus(int shortageId, {required String status}) {
    return safeRequest<Shortage>(
      () => _dio.patch(
        ShortageEndpoints.status(shortageId),
        data: <String, dynamic>{'status': status},
      ),
      parse: (data) => Shortage.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Shortage>> assign(int shortageId, {required int? userId}) {
    return safeRequest<Shortage>(
      // Sent as an explicit null rather than omitted: here the null **is** the instruction —
      // «خُذها من صاحبها» — and omitting the key would say «leave it as it is».
      () => _dio.patch(
        ShortageEndpoints.assignee(shortageId),
        data: <String, dynamic>{'assigned_to_user_id': userId},
      ),
      parse: (data) => Shortage.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, ShortageSupply>> recordSupply(
    int shortageId, {
    required String quantity,
    String? amount,
    String? method,
    int? warehouseId,
    String? reference,
    String? occurredOn,
    String? notes,
  }) {
    return safeRequest<ShortageSupply>(
      () => _dio.post(
        ShortageEndpoints.supplies(shortageId),
        data: <String, dynamic>{
          'quantity': quantity,
          'amount': ?amount,
          'method': ?method,
          // Omitted on a shortage with no shelf — sending one there is a 422 in its own right,
          // because it tells the server goods are moving when they are not.
          'warehouse_id': ?warehouseId,
          'reference': ?reference,
          // The server defaults it to today when it is absent, so an untouched date box sends
          // nothing rather than this phone's idea of the day.
          'occurred_on': ?occurredOn,
          'notes': ?notes,
        },
      ),
      parse: (data) => ShortageSupply.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, ShortageSupply>> reverseSupply(
    int shortageId,
    int supplyId, {
    String? notes,
  }) {
    return safeRequest<ShortageSupply>(
      () => _dio.post(
        ShortageEndpoints.supplyReversal(shortageId, supplyId),
        data: <String, dynamic>{'notes': ?notes},
      ),
      parse: (data) => ShortageSupply.fromJson(data as Map<String, dynamic>),
    );
  }
}
