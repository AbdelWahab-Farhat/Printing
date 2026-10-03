import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/models/vendor_payment.dart';
import 'package:dayaa/features/treasury/repositories/treasury_repository.dart';

class GetTreasuryAccounts {
  const GetTreasuryAccounts(this._repository);

  final TreasuryRepository _repository;

  Future<Either<Failure, TreasuryAccounts>> call({bool activeOnly = false}) =>
      _repository.accounts(activeOnly: activeOnly);
}

class GetTreasuryAccount {
  const GetTreasuryAccount(this._repository);

  final TreasuryRepository _repository;

  Future<Either<Failure, TreasuryAccountDetail>> call(int id) => _repository.account(id);
}

class GetAccountMovements {
  const GetAccountMovements(this._repository);

  final TreasuryRepository _repository;

  Future<Either<Failure, Paginated<TreasuryMovement>>> call(
    int accountId, {
    required int page,
    int? perPage,
    MovementFilter filter = MovementFilter.all,
    String? search,
  }) => _repository.movements(
    accountId,
    page: page,
    perPage: perPage,
    filter: filter,
    search: search,
  );
}

class GetTreasuryExpenses {
  const GetTreasuryExpenses(this._repository);

  final TreasuryRepository _repository;

  Future<Either<Failure, Paginated<TreasuryMovement>>> call({
    required int page,
    DateTime? from,
    DateTime? to,
    int? categoryId,
    int? accountId,
  }) => _repository.expenses(
    page: page,
    from: from,
    to: to,
    categoryId: categoryId,
    accountId: accountId,
  );
}

class SaveTreasuryAccount {
  const SaveTreasuryAccount(this._repository);

  final TreasuryRepository _repository;

  Future<Either<Failure, TreasuryAccount>> call({
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
  }) => _repository.saveAccount(
    id: id,
    name: name,
    kind: kind,
    isDefault: isDefault,
    isActive: isActive,
    holderUserId: holderUserId,
    notes: notes,
    isCollected: isCollected,
    pickupCityId: pickupCityId,
    clearPickupCity: clearPickupCity,
  );
}

class GetAccountOptions {
  const GetAccountOptions(this._repository);

  final TreasuryRepository _repository;

  Future<Either<Failure, AccountOptions>> call({
    required String method,
    bool incoming = true,
    int? orderId,
  }) => _repository.accountOptions(method: method, incoming: incoming, orderId: orderId);
}

class RecordTreasuryOperation {
  const RecordTreasuryOperation(this._repository);

  final TreasuryRepository _repository;

  Future<Either<Failure, TreasuryOperation>> call({
    required OperationKind kind,
    String? amount,
    int? fromAccountId,
    int? toAccountId,
    int? categoryId,
    int? employeeId,
    String? countedBalance,
    String? notes,
    String? clientToken,
  }) => _repository.recordOperation(
    kind: kind,
    amount: amount,
    fromAccountId: fromAccountId,
    toAccountId: toAccountId,
    categoryId: categoryId,
    employeeId: employeeId,
    countedBalance: countedBalance,
    notes: notes,
    clientToken: clientToken,
  );
}

class ReverseTreasuryOperation {
  const ReverseTreasuryOperation(this._repository);

  final TreasuryRepository _repository;

  Future<Either<Failure, TreasuryOperation>> call(int operationId, {required String reason}) =>
      _repository.reverseOperation(operationId, reason: reason);
}

class GetExpenseCategories {
  const GetExpenseCategories(this._repository);

  final TreasuryRepository _repository;

  Future<Either<Failure, List<ExpenseCategory>>> call({bool activeOnly = true}) =>
      _repository.expenseCategories(activeOnly: activeOnly);
}

class SaveExpenseCategory {
  const SaveExpenseCategory(this._repository);

  final TreasuryRepository _repository;

  Future<Either<Failure, ExpenseCategory>> call({
    int? id,
    required String name,
    bool? requiresEmployee,
    bool? isActive,
  }) => _repository.saveExpenseCategory(
    id: id,
    name: name,
    requiresEmployee: requiresEmployee,
    isActive: isActive,
  );
}

class GetTreasurySettings {
  const GetTreasurySettings(this._repository);

  final TreasuryRepository _repository;

  Future<Either<Failure, TreasurySettings>> call() => _repository.settings();
}

class SaveTreasurySettings {
  const SaveTreasurySettings(this._repository);

  final TreasuryRepository _repository;

  Future<Either<Failure, TreasurySettings>> call({
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
  }) => _repository.saveSettings(
    ownAccountFirst: ownAccountFirst,
    blockOverdraft: blockOverdraft,
    withdrawalNeedsReason: withdrawalNeedsReason,
    askCarrierFee: askCarrierFee,
    lockedUntil: lockedUntil,
    clearLock: clearLock,
    collectKind: collectKind,
    collectOn: collectOn,
    collectIntoId: collectIntoId,
    clearCollectInto: clearCollectInto,
    settleIntoSettler: settleIntoSettler,
  );
}

class SetSettlesInto {
  const SetSettlesInto(this._repository);

  final TreasuryRepository _repository;

  Future<Either<Failure, TreasuryAccount>> call({
    required TreasuryAccount custody,
    int? targetId,
  }) => _repository.setSettlesInto(custody: custody, targetId: targetId);
}

class GetTreasuryOwnership {
  const GetTreasuryOwnership(this._repository);

  final TreasuryRepository _repository;

  Future<Either<Failure, TreasuryOwnership>> call() => _repository.ownership();
}

class GetInventoryValue {
  const GetInventoryValue(this._repository);

  final TreasuryRepository _repository;

  Future<Either<Failure, InventoryValue>> call() => _repository.inventoryValue();
}

class GetPurchaseOrderPayments {
  const GetPurchaseOrderPayments(this._repository);

  final TreasuryRepository _repository;

  Future<Either<Failure, PurchaseOrderPayments>> call(int purchaseOrderId) =>
      _repository.purchaseOrderPayments(purchaseOrderId);
}

class GetVendorAccount {
  const GetVendorAccount(this._repository);

  final TreasuryRepository _repository;

  Future<Either<Failure, VendorAccount>> call(int vendorId) => _repository.vendorAccount(vendorId);
}

class CountOldOrderAsDebt {
  const CountOldOrderAsDebt(this._repository);

  final TreasuryRepository _repository;

  Future<Either<Failure, Unit>> call(int purchaseOrderId) =>
      _repository.countOldOrderAsDebt(purchaseOrderId);
}

class CreditVendor {
  const CreditVendor(this._repository);

  final TreasuryRepository _repository;

  Future<Either<Failure, VendorPayment>> call({
    required int vendorId,
    required String amount,
    int? purchaseOrderId,
    String? notes,
    String? clientToken,
  }) => _repository.creditVendor(
    vendorId: vendorId,
    amount: amount,
    purchaseOrderId: purchaseOrderId,
    notes: notes,
    clientToken: clientToken,
  );
}

class PayVendor {
  const PayVendor(this._repository);

  final TreasuryRepository _repository;

  Future<Either<Failure, VendorPayment>> call({
    required int vendorId,
    required String amount,
    required String method,
    int? purchaseOrderId,
    int? accountId,
    String? reference,
    String? notes,
    String? clientToken,
  }) => _repository.payVendor(
    vendorId: vendorId,
    amount: amount,
    method: method,
    purchaseOrderId: purchaseOrderId,
    accountId: accountId,
    reference: reference,
    notes: notes,
    clientToken: clientToken,
  );
}

class ReverseVendorPayment {
  const ReverseVendorPayment(this._repository);

  final TreasuryRepository _repository;

  Future<Either<Failure, VendorPayment>> call({
    required int vendorId,
    required int paymentId,
    required String reason,
  }) => _repository.reverseVendorPayment(vendorId: vendorId, paymentId: paymentId, reason: reason);
}
