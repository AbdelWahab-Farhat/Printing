import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/stock_item_groups/models/stock_item_group.dart';
import 'package:dayaa/features/stock_item_groups/repositories/stock_item_group_repository.dart';
import 'package:dayaa/features/stock_items/models/stock_unit.dart';
import 'package:dio/dio.dart';

/// Fulfils [StockItemGroupRepository] over HTTP.
class StockItemGroupRepositoryImpl implements StockItemGroupRepository {
  const StockItemGroupRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<StockItemGroup>>> groups({
    String? search,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<StockItemGroup>(
      () => _dio.get(
        StockItemGroupEndpoints.index,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          // Omitted rather than sent as null: a null in a query string arrives as the literal
          // "null" and the API would filter on it.
          if (search != null && search.isNotEmpty) 'search': search,
          // The server reads this through `FILTER_VALIDATE_BOOLEAN`, which is why 1/0 travels
          // rather than "true"/"false" — the same shape the warehouse filters use.
          if (isActive != null) 'is_active': isActive ? 1 : 0,
        },
      ),
      parseItem: StockItemGroup.fromJson,
    );
  }

  @override
  Future<Either<Failure, StockItemGroup>> group(int groupId) {
    return safeRequest<StockItemGroup>(
      () => _dio.get(StockItemGroupEndpoints.show(groupId)),
      parse: (data) => StockItemGroup.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, StockItemGroup>> create({
    required String name,
    required StockUnit defaultUnit,
    String? description,
    bool isActive = true,
  }) {
    return safeRequest<StockItemGroup>(
      () => _dio.post(
        StockItemGroupEndpoints.index,
        data: <String, dynamic>{
          'name': name,
          'default_unit': defaultUnit.wire,
          'description': description,
          'is_active': isActive,
        },
      ),
      parse: (data) => StockItemGroup.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, StockItemGroup>> update(
    int groupId, {
    required String name,
    StockUnit? defaultUnit,
    String? description,
    bool? isActive,
  }) {
    return safeRequest<StockItemGroup>(
      () => _dio.put(
        StockItemGroupEndpoints.show(groupId),
        data: <String, dynamic>{
          'name': name,
          // Absent keeps the current unit — the rule the request states in so many words. Null
          // is for a caller that never put the choice on screen; the edit sheet does, so it
          // sends back whatever the user is looking at.
          if (defaultUnit != null) 'default_unit': defaultUnit.wire,
          // **Always sent, null included.** The rule is `sometimes|nullable`, so an absent key
          // means «leave it» and an explicit null means «erase it» — and somebody who cleared
          // the box meant the second one. Omitting an emptied field is how a note nobody can
          // delete happens.
          'description': description,
          'is_active': ?isActive,
        },
      ),
      parse: (data) => StockItemGroup.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, String>> delete(int groupId) {
    return safeCommand(() => _dio.delete(StockItemGroupEndpoints.show(groupId)));
  }
}
