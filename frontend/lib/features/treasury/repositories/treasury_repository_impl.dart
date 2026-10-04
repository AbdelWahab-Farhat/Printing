import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/models/vendor_payment.dart';
import 'package:dayaa/features/treasury/repositories/treasury_repository.dart';
import 'package:dio/dio.dart';

class TreasuryRepositoryImpl implements TreasuryRepository {
  const TreasuryRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, TreasuryAccounts>> accounts({bool activeOnly = false}) {
    return safeRequest<TreasuryAccounts>(
      () =>
          _dio.get(TreasuryEndpoints.accounts, queryParameters: {if (activeOnly) 'active_only': 1}),
      parse: (data) => TreasuryAccounts.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, TreasuryAccountDetail>> account(int id) {
    return safeRequest<TreasuryAccountDetail>(
      () => _dio.get(TreasuryEndpoints.account(id)),
      parse: (data) => TreasuryAccountDetail.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Paginated<TreasuryMovement>>> movements(
    int accountId, {
    required int page,
    int? perPage,
    MovementFilter filter = MovementFilter.all,
    String? search,
  }) {
    return safePaginatedRequest<TreasuryMovement>(
      () => _dio.get(
        TreasuryEndpoints.movements(accountId),
        // المفاتيح الفارغة تُحذف ولا تُرسل — RULES §٦.
        queryParameters: {'page': page, 'per_page': ?perPage, ...filter.query, 'search': ?search},
      ),
      parseItem: (json) => TreasuryMovement.fromJson(json),
    );
  }

  @override
  Future<Either<Failure, Paginated<TreasuryMovement>>> expenses({
    required int page,
    DateTime? from,
    DateTime? to,
    int? categoryId,
    int? accountId,
    String? search,
  }) {
    return safePaginatedRequest<TreasuryMovement>(
      () => _dio.get(
        TreasuryEndpoints.expenses,
        queryParameters: {
          'page': page,
          if (from != null) 'from': _day(from),
          if (to != null) 'to': _day(to),
          'category_id': ?categoryId,
          'account_id': ?accountId,
          'search': ?search,
        },
      ),
      parseItem: (json) => TreasuryMovement.fromJson(json),
    );
  }

  static String _day(DateTime at) =>
      '${at.year.toString().padLeft(4, '0')}-${at.month.toString().padLeft(2, '0')}-'
      '${at.day.toString().padLeft(2, '0')}';

  @override
  Future<Either<Failure, TreasuryAccount>> saveAccount({
    int? id,
    required String name,
    String? kind,
    bool? isDefault,
    bool? isActive,
    int? holderUserId,
    String? notes,
    bool? isCollected,
    int? pickupCityId,
    bool clearPickupCity = false,
  }) {
    // في التعديل يُترك المفتاح الغائب كما هو، و`null` في الجسم تعني «امسحه».
    final body = <String, dynamic>{
      'name': name,
      'kind': ?kind,
      'is_default': ?isDefault,
      'is_active': ?isActive,
      'holder_user_id': ?holderUserId,
      // فارغةً تمسح الملاحظات، وغائبةً تتركها (`AccountData::hasNotes`).
      'notes': ?notes,
      'is_collected': ?isCollected,
      'pickup_city_id': ?pickupCityId,
      // المفتاح الآخر الذي له معنى وهو فارغ: هذه الخزنة لم تعد تخدم مكتبها.
      if (clearPickupCity) 'pickup_city_id': null,
    };

    return safeRequest<TreasuryAccount>(
      () => id == null
          ? _dio.post(TreasuryEndpoints.accounts, data: body)
          : _dio.put(TreasuryEndpoints.account(id), data: body),
      parse: (data) => TreasuryAccount.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, AccountOptions>> accountOptions({
    required String method,
    bool incoming = true,
    int? orderId,
  }) {
    return safeRequest<AccountOptions>(
      () => _dio.get(
        TreasuryEndpoints.accountOptions,
        queryParameters: {
          'method': method,
          'purpose': incoming ? 'in' : 'out',
          'order_id': ?orderId,
        },
      ),
      parse: (data) => AccountOptions.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, TreasuryOperation>> recordOperation({
    required OperationKind kind,
    String? amount,
    int? fromAccountId,
    int? toAccountId,
    int? categoryId,
    int? employeeId,
    String? countedBalance,
    String? notes,
    String? clientToken,
  }) {
    return safeRequest<TreasuryOperation>(
      () => _dio.post(
        TreasuryEndpoints.operations,
        data: {
          'type': kind.wire,
          'amount': ?amount,
          'from_account_id': ?fromAccountId,
          'to_account_id': ?toAccountId,
          'category_id': ?categoryId,
          'employee_id': ?employeeId,
          'counted_balance': ?countedBalance,
          'notes': ?notes,
          'client_token': ?clientToken,
        },
      ),
      parse: (data) => TreasuryOperation.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, TreasuryOperation>> reverseOperation(
    int operationId, {
    required String reason,
  }) {
    return safeRequest<TreasuryOperation>(
      () => _dio.post(TreasuryEndpoints.reverseOperation(operationId), data: {'reason': reason}),
      parse: (data) => TreasuryOperation.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, ExpenseCategory>> saveExpenseCategory({
    int? id,
    required String name,
    bool? requiresEmployee,
    bool? isActive,
  }) {
    final body = <String, dynamic>{
      'name': name,
      'requires_employee': ?requiresEmployee,
      'is_active': ?isActive,
    };

    return safeRequest<ExpenseCategory>(
      () => id == null
          ? _dio.post(TreasuryEndpoints.expenseCategories, data: body)
          : _dio.put(TreasuryEndpoints.expenseCategory(id), data: body),
      parse: (data) => ExpenseCategory.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, TreasurySettings>> settings() {
    return safeRequest<TreasurySettings>(
      () => _dio.get(TreasuryEndpoints.settings),
      parse: (data) => TreasurySettings.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, TreasurySettings>> saveSettings({
    bool? ownAccountFirst,
    bool? blockOverdraft,
    bool? withdrawalNeedsReason,
    bool? askCarrierFee,
    String? lockedUntil,
    bool clearLock = false,
    AccountKind? collectKind,
    bool? collectOn,
    int? collectIntoId,
    bool clearCollectInto = false,
    bool? settleIntoSettler,
  }) {
    return safeRequest<TreasurySettings>(
      () => _dio.put(
        TreasuryEndpoints.settings,
        data: <String, dynamic>{
          'own_account_first': ?ownAccountFirst,
          'settle_into_settler': ?settleIntoSettler,
          'block_overdraft': ?blockOverdraft,
          'withdrawal_needs_reason': ?withdrawalNeedsReason,
          'ask_carrier_fee': ?askCarrierFee,
          'locked_until': ?lockedUntil,
          // المفتاح الوحيد الذي له معنى وهو فارغ: افتح القفل.
          if (clearLock) 'locked_until': null,
          if (collectKind != null) ...{
            'collect_${collectKind.wire}': ?collectOn,
            'collect_${collectKind.wire}_into_id': ?collectIntoId,
            // هدفٌ فارغ: عُد إلى افتراضي النوع.
            if (clearCollectInto) 'collect_${collectKind.wire}_into_id': null,
          },
        },
      ),
      parse: (data) => TreasurySettings.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, TreasuryAccount>> setSettlesInto({
    required TreasuryAccount custody,
    int? targetId,
  }) {
    return safeRequest<TreasuryAccount>(
      () => _dio.put(
        TreasuryEndpoints.account(custody.id),
        data: <String, dynamic>{'name': custody.name, 'settles_into_account_id': targetId},
      ),
      parse: (data) => TreasuryAccount.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, List<ExpenseCategory>>> expenseCategories({bool activeOnly = true}) {
    return safeRequest<List<ExpenseCategory>>(
      () => _dio.get(
        TreasuryEndpoints.expenseCategories,
        queryParameters: {if (activeOnly) 'active_only': 1},
      ),
      parse: (data) => [
        for (final row in (data as List<dynamic>).whereType<Map<String, dynamic>>())
          ExpenseCategory.fromJson(row),
      ],
    );
  }

  @override
  Future<Either<Failure, TreasuryOwnership>> ownership() {
    return safeRequest<TreasuryOwnership>(
      () => _dio.get(TreasuryEndpoints.ownership),
      parse: (data) => TreasuryOwnership.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, InventoryValue>> inventoryValue() {
    return safeRequest<InventoryValue>(
      () => _dio.get(TreasuryEndpoints.inventoryValue),
      parse: (data) => InventoryValue.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, PurchaseOrderPayments>> purchaseOrderPayments(int purchaseOrderId) {
    return safeRequest<PurchaseOrderPayments>(
      () => _dio.get(TreasuryEndpoints.purchaseOrderPayments(purchaseOrderId)),
      parse: (data) => PurchaseOrderPayments.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, VendorPayment>> payVendor({
    required int vendorId,
    required String amount,
    required String method,
    int? purchaseOrderId,
    int? accountId,
    String? reference,
    String? notes,
    String? clientToken,
  }) {
    return safeRequest<VendorPayment>(
      () => _dio.post(
        TreasuryEndpoints.vendorPayments(vendorId),
        data: {
          'amount': amount,
          'method': method,
          'purchase_order_id': ?purchaseOrderId,
          'treasury_account_id': ?accountId,
          'reference': ?reference,
          'notes': ?notes,
          'client_token': ?clientToken,
        },
      ),
      parse: (data) => VendorPayment.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, VendorPayment>> reverseVendorPayment({
    required int vendorId,
    required int paymentId,
    required String reason,
  }) {
    return safeRequest<VendorPayment>(
      () => _dio.post(
        TreasuryEndpoints.reverseVendorPayment(vendorId, paymentId),
        data: {'reason': reason},
      ),
      parse: (data) => VendorPayment.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, VendorAccount>> vendorAccount(int vendorId) {
    return safeRequest<VendorAccount>(
      () => _dio.get(TreasuryEndpoints.vendorPayments(vendorId)),
      parse: (data) => VendorAccount.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Unit>> countOldOrderAsDebt(int purchaseOrderId) {
    return safeRequest<Unit>(
      () => _dio.post(TreasuryEndpoints.countOldOrderAsDebt(purchaseOrderId)),
      parse: (_) => unit,
    );
  }

  @override
  Future<Either<Failure, VendorPayment>> creditVendor({
    required int vendorId,
    required String amount,
    int? purchaseOrderId,
    String? notes,
    String? clientToken,
  }) {
    return safeRequest<VendorPayment>(
      () => _dio.post(
        TreasuryEndpoints.vendorPayments(vendorId),
        data: {
          'type': 'credit',
          'amount': amount,
          'purchase_order_id': ?purchaseOrderId,
          'notes': ?notes,
          'client_token': ?clientToken,
        },
      ),
      parse: (data) => VendorPayment.fromJson(data as Map<String, dynamic>),
    );
  }
}
