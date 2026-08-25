import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/stock_items/models/stock_item.dart';
import 'package:dayaa/features/stock_items/models/stock_unit.dart';
import 'package:dayaa/features/stock_items/repositories/stock_item_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [StockItemRepository] over HTTP.
class StockItemRepositoryImpl implements StockItemRepository {
  const StockItemRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<StockItem>>> items({
    String? search,
    bool? isActive,
    int? widthCm,
    int? heightCm,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<StockItem>(
      () => _dio.get(
        StockItemEndpoints.index,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          // Omitted rather than sent as null or empty: the server reads a blank `search` as
          // absent anyway, but a null in a query string arrives as the literal "null" and would
          // be searched for.
          if (search != null && search.isNotEmpty) 'search': search,
          if (isActive != null) 'is_active': isActive ? 1 : 0,
          'width_cm': ?widthCm,
          'height_cm': ?heightCm,
        },
      ),
      parseItem: StockItem.fromJson,
    );
  }

  @override
  Future<Either<Failure, StockItem>> item(int stockItemId) {
    return safeRequest<StockItem>(
      () => _dio.get(StockItemEndpoints.show(stockItemId)),
      parse: (data) => StockItem.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, StockItem>> create({
    int? stockItemGroupId,
    String? name,
    int? widthCm,
    int? heightCm,
    required StockUnit unit,
    String? description,
    required bool isActive,
    required int sortOrder,
  }) {
    return safeRequest<StockItem>(
      () => _dio.post(
        StockItemEndpoints.index,
        data: <String, dynamic>{
          'stock_item_group_id': ?stockItemGroupId,
          // Sent even under a material, where the server would fill it in from the group: a
          // payload that says what it is creating is a payload a log can be read back from.
          if (name != null && name.isNotEmpty) 'name': name,
          'width_cm': ?widthCm,
          'height_cm': ?heightCm,
          'unit': unit.wire,
          'description': description,
          'is_active': isActive,
          'sort_order': sortOrder,
        },
      ),
      parse: (data) => StockItem.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, StockItem>> update(
    int stockItemId, {
    required String name,
    int? widthCm,
    int? heightCm,
    String? description,
    required bool isActive,
    required int sortOrder,
  }) {
    return safeRequest<StockItem>(
      () => _dio.put(
        StockItemEndpoints.show(stockItemId),
        // Every key present, nulls included, because the server treats this as a full
        // replacement: an absent `width_cm` is the same as a null one, an absent `is_active`
        // re-offers a stopped shelf and an absent `sort_order` renumbers it to zero. There is no
        // `unit` and no `stock_item_group_id` here — the API carries no rule for either, so
        // sending them would be silently ignored rather than refused.
        data: <String, dynamic>{
          'name': name,
          'width_cm': widthCm,
          'height_cm': heightCm,
          'description': description,
          'is_active': isActive,
          'sort_order': sortOrder,
        },
      ),
      parse: (data) => StockItem.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, StockItem>> setUnit(int stockItemId, {required StockUnit unit}) {
    return safeRequest<StockItem>(
      // The only field the endpoint takes. `unit.wire` rather than a label read off a row: the
      // sheet offers `StockUnit.choices`, so the empty wire of `unknown` cannot reach here.
      () => _dio.patch(
        StockItemEndpoints.unit(stockItemId),
        data: <String, dynamic>{'unit': unit.wire},
      ),
      parse: (data) => StockItem.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, StockItem>> setVariants(int stockItemId, List<int> variantIds) {
    return safeRequest<StockItem>(
      // Sent even when empty, which is why the server validates it `present` rather than
      // `required`: «لا شيء يسحب من هذه المادة» is an answer, and dropping the key would make it
      // indistinguishable from a request that forgot to say.
      () => _dio.put(
        StockItemEndpoints.variants(stockItemId),
        data: <String, dynamic>{'variant_ids': variantIds},
      ),
      parse: (data) => StockItem.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, String>> delete(int stockItemId) {
    return safeCommand(() => _dio.delete(StockItemEndpoints.show(stockItemId)));
  }
}
