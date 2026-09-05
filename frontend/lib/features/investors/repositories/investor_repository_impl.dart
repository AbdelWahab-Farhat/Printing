import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/investors/models/deal_order.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/models/investor_deal.dart';
import 'package:dayaa/features/investors/repositories/investor_repository.dart';
import 'package:dio/dio.dart';

class InvestorRepositoryImpl implements InvestorRepository {
  const InvestorRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<Investor>>> investors({
    String? search,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<Investor>(
      () => _dio.get(
        InvestorEndpoints.investors,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          // Omitted rather than sent null: a null in a query string arrives as the literal
          // "null" and the API would filter on it.
          if (search != null && search.isNotEmpty) 'search': search,
          if (isActive != null) 'is_active': isActive ? 1 : 0,
        },
      ),
      parseItem: (row) => Investor.fromJson(row),
    );
  }

  @override
  Future<Either<Failure, Investor>> investor(int id) {
    return safeRequest<Investor>(
      () => _dio.get(InvestorEndpoints.investor(id)),
      parse: (data) => Investor.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Investor>> createInvestor({
    required String name,
    String? phone,
    String? notes,
  }) {
    return safeRequest<Investor>(
      () => _dio.post(
        InvestorEndpoints.investors,
        data: <String, dynamic>{
          'name': name,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      ),
      parse: (data) => Investor.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Unit>> recordWalletEntry({
    required int investorId,
    required String type,
    required String amount,
    int? investorDealId,
    String? method,
    String? reference,
    String? notes,
  }) {
    return safeRequest<Unit>(
      () => _dio.post(
        InvestorEndpoints.wallet(investorId),
        data: <String, dynamic>{
          'type': type,
          'amount': amount,
          // Sent only for the one type that names a deal and the ones that name a method — the
          // server refuses the wrong combination outright, mirroring the shape its own database
          // constraint enforces.
          'investor_deal_id': ?investorDealId,
          if (method != null && method.isNotEmpty) 'method': method,
          if (reference != null && reference.isNotEmpty) 'reference': reference,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      ),
      parse: (_) => unit,
    );
  }

  @override
  Future<Either<Failure, Paginated<InvestorDeal>>> deals({
    String? search,
    String? status,
    int? investorId,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<InvestorDeal>(
      () => _dio.get(
        InvestorEndpoints.deals,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty) 'status': status,
          'investor_id': ?investorId,
        },
      ),
      parseItem: (row) => InvestorDeal.fromJson(row),
    );
  }

  @override
  Future<Either<Failure, Paginated<DealOrder>>> dealOrders(
    int dealId, {
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<DealOrder>(
      () => _dio.get(
        InvestorEndpoints.dealOrders(dealId),
        queryParameters: <String, dynamic>{'page': page, 'per_page': perPage},
      ),
      parseItem: (row) => DealOrder.fromJson(row),
    );
  }

  @override
  Future<Either<Failure, InvestorDeal>> deal(int id) {
    return safeRequest<InvestorDeal>(
      () => _dio.get(InvestorEndpoints.deal(id)),
      parse: (data) => InvestorDeal.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, InvestorDeal>> fundPurchaseOrder(
    int purchaseOrderId,
    Map<String, dynamic> body,
  ) {
    return safeRequest<InvestorDeal>(
      () => _dio.post(
        InvestorEndpoints.fundPurchaseOrder(purchaseOrderId),
        data: body,
      ),
      parse: (data) => InvestorDeal.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, InvestorDeal>> closeDeal(int id) {
    return safeRequest<InvestorDeal>(
      () => _dio.post(InvestorEndpoints.closeDeal(id)),
      parse: (data) => InvestorDeal.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Unit>> recordExpense({
    required int dealId,
    required String kind,
    required String name,
    required String amount,
    required String incurredOn,
    String? notes,
  }) {
    return safeRequest<Unit>(
      () => _dio.post(
        InvestorEndpoints.dealExpenses(dealId),
        data: <String, dynamic>{
          'kind': kind,
          'name': name,
          'amount': amount,
          'incurred_on': incurredOn,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      ),
      parse: (_) => unit,
    );
  }
}
