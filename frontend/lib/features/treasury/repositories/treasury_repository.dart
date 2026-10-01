import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/models/vendor_payment.dart';

/// الحسابات والخزائن — TREASURY-DESIGN §١٠.
abstract interface class TreasuryRepository {
  /// The accounts this person may read — every one with `treasury.view`, their own otherwise.
  Future<Either<Failure, TreasuryAccounts>> accounts({bool activeOnly = false});

  Future<Either<Failure, TreasuryAccountDetail>> account(int id);

  /// An account's history, newest first, each line with the balance it left.
  Future<Either<Failure, Paginated<TreasuryMovement>>> movements(
    int accountId, {
    required int page,
  });

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
  });

  /// The accounts a payment method fits, and the one the treasury would pick. [incoming] false
  /// for money leaving — a refund, a vendor payment — which never comes out of custody.
  ///
  /// [orderId] names the order the money is for: while it waits at a pickup branch, «تلقائي» is
  /// that branch's cash box (§١٩).
  Future<Either<Failure, AccountOptions>> accountOptions({
    required String method,
    bool incoming = true,
    int? orderId,
  });

  /// One hand operation. Which fields it needs depends on [kind] — see
  /// `StoreTreasuryOperationRequest` on the backend.
  Future<Either<Failure, TreasuryOperation>> recordOperation({
    required OperationKind kind,
    String? amount,
    int? fromAccountId,
    int? toAccountId,
    int? categoryId,
    int? employeeId,
    String? countedBalance,
    String? notes,
  });

  Future<Either<Failure, TreasuryOperation>> reverseOperation(
    int operationId, {
    required String reason,
  });

  /// The active categories for the expense form, or every one for the settings page.
  Future<Either<Failure, List<ExpenseCategory>>> expenseCategories({bool activeOnly = true});

  Future<Either<Failure, ExpenseCategory>> saveExpenseCategory({
    int? id,
    required String name,
    bool? requiresEmployee,
    bool? isActive,
  });

  Future<Either<Failure, TreasurySettings>> settings();

  /// Only the keys present change; [clearLock] sends `locked_until: null` to unlock.
  ///
  /// [collectKind] names the kind [collectOn] and [collectIntoId] are for — «التجميع عند
  /// التسوية»; [clearCollectInto] sends a null target, back to the kind's default.
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
  });

  /// Where a custody account settles into; null [targetId] goes back to the built-in rule.
  Future<Either<Failure, TreasuryAccount>> setSettlesInto({
    required TreasuryAccount custody,
    int? targetId,
  });

  Future<Either<Failure, TreasuryOwnership>> ownership();

  Future<Either<Failure, InventoryValue>> inventoryValue();

  // ── دفعات الموردين ────────────────────────────────────────────────────────────────

  Future<Either<Failure, PurchaseOrderPayments>> purchaseOrderPayments(int purchaseOrderId);

  Future<Either<Failure, Unit>> payVendor({
    required int vendorId,
    required String amount,
    required String method,
    int? purchaseOrderId,
    int? accountId,
    String? reference,
    String? notes,
  });

  Future<Either<Failure, Unit>> reverseVendorPayment({
    required int vendorId,
    required int paymentId,
    required String reason,
  });

  /// «الحساب مع المورد» — what is owed to one vendor, and every payment. TREASURY-DESIGN §٢٠.
  Future<Either<Failure, VendorAccount>> vendorAccount(int vendorId);

  /// «يُحسب عليه دين للمورد» — an order from before the treasury that is still owed: its total
  /// goes onto the vendor's «علينا», with what was paid on it since. One way.
  Future<Either<Failure, Unit>> countOldOrderAsDebt(int purchaseOrderId);

  /// «خصم من المورد» — the vendor knocked [amount] off what is owed. No money moves.
  Future<Either<Failure, Unit>> creditVendor({
    required int vendorId,
    required String amount,
    int? purchaseOrderId,
    String? notes,
  });
}
