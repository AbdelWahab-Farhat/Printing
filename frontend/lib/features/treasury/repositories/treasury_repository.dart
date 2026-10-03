import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/models/vendor_payment.dart';

/// الحسابات والكاش — TREASURY-DESIGN §١٠.
abstract interface class TreasuryRepository {
  /// الحسابات التي يقرؤها هذا الشخص — كلُّها لمن يحمل `treasury.view`، وما باسمه لغيره.
  Future<Either<Failure, TreasuryAccounts>> accounts({bool activeOnly = false});

  Future<Either<Failure, TreasuryAccountDetail>> account(int id);

  /// سجلّ الحساب، الأحدث أولاً، وكل سطرٍ بالرصيد الذي تركه.
  ///
  /// [filter] يقصره على مال الطلبيات أو المصاريف، و[search] على طلبيةٍ برقمها — فلترُ الخادم
  /// نفسه (`AccountLedger`): يُحسب الرصيد الجاري على السجل كله ثم يُصفّى. و[perPage] لقراءة
  /// سطرٍ واحد: ما كتبه الخادم للتوّ.
  Future<Either<Failure, Paginated<TreasuryMovement>>> movements(
    int accountId, {
    required int page,
    int? perPage,
    MovementFilter filter = MovementFilter.all,
    String? search,
  });

  /// «المصاريف» — مصاريف كل الحسابات، الأحدث أولاً. مجموعُ الفترة المصفّاة كلِّها (لا الصفحة)
  /// في `extraMeta['expenses_total']`، والمعكوسُ خارجه. §٢١.
  Future<Either<Failure, Paginated<TreasuryMovement>>> expenses({
    required int page,
    DateTime? from,
    DateTime? to,
    int? categoryId,
    int? accountId,
  });

  /// [notes] الفارغة (`''`) تمسح الملاحظات، والغائبة تتركها — `AccountData::hasNotes`.
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

  /// الحسابات التي تقبلها الطريقة، والذي سيختاره الخادم. [incoming] كاذبٌ للمال الخارج — ردٌّ
  /// أو دفعةٌ لمورد — فلا يخرج من عهدة.
  ///
  /// [orderId] الطلبية التي المالُ لها: ما دامت تنتظر في مكتب استلام، «تلقائي» خزنةُ ذلك المكتب
  /// (§١٩).
  Future<Either<Failure, AccountOptions>> accountOptions({
    required String method,
    bool incoming = true,
    int? orderId,
  });

  /// عمليةٌ يدوية واحدة. ما تحتاجه من حقول يتبع [kind] — انظر `StoreTreasuryOperationRequest`.
  ///
  /// [clientToken] مفتاحٌ يولَّد مرةً لكل نموذج ويُعاد مع كل محاولة: إن وصل الطلب الأول وانقطع
  /// الرد، أعاد الخادم العمليةَ نفسها بدل أن يكتبها مرتين.
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
  });

  Future<Either<Failure, TreasuryOperation>> reverseOperation(
    int operationId, {
    required String reason,
  });

  /// التصنيفات المفعّلة لنموذج المصروف، أو كلها لصفحة الإعدادات.
  Future<Either<Failure, List<ExpenseCategory>>> expenseCategories({bool activeOnly = true});

  Future<Either<Failure, ExpenseCategory>> saveExpenseCategory({
    int? id,
    required String name,
    bool? requiresEmployee,
    bool? isActive,
  });

  Future<Either<Failure, TreasurySettings>> settings();

  /// المفاتيح الحاضرة وحدها تتغيّر؛ [clearLock] يُرسل `locked_until: null` ليفتح القفل.
  ///
  /// [collectKind] النوعُ الذي يخصّه [collectOn] و[collectIntoId] — «التجميع عند التسوية»؛
  /// و[clearCollectInto] يرسل هدفاً فارغاً فيعود إلى افتراضي النوع. و[settleIntoSettler]
  /// «التسوية إلى حساب المسوّي» (§٢٢).
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
  });

  /// أين تُسوّى العهدة؛ [targetId] فارغٌ يعيدها إلى القاعدة المبنيّة.
  Future<Either<Failure, TreasuryAccount>> setSettlesInto({
    required TreasuryAccount custody,
    int? targetId,
  });

  Future<Either<Failure, TreasuryOwnership>> ownership();

  Future<Either<Failure, InventoryValue>> inventoryValue();

  // ── دفعات الموردين ────────────────────────────────────────────────────────────────

  Future<Either<Failure, PurchaseOrderPayments>> purchaseOrderPayments(int purchaseOrderId);

  /// تعود بالصف الذي كتبه الخادم، فيُرقَّع القسم به. [clientToken] كما في [recordOperation].
  Future<Either<Failure, VendorPayment>> payVendor({
    required int vendorId,
    required String amount,
    required String method,
    int? purchaseOrderId,
    int? accountId,
    String? reference,
    String? notes,
    String? clientToken,
  });

  /// تعود بصف العكس.
  Future<Either<Failure, VendorPayment>> reverseVendorPayment({
    required int vendorId,
    required int paymentId,
    required String reason,
  });

  /// «الحساب مع المورد» — what is owed to one vendor, and every payment. TREASURY-DESIGN §٢٠.
  Future<Either<Failure, VendorAccount>> vendorAccount(int vendorId);

  /// «يُحسب عليه دين للمورد» — an order from before the treasury that is still owed: its total
  /// goes onto the vendor's «علينا», with what was paid on it since. One way.
  Future<Either<Failure, Unit>> countOldOrderAsDebt(int purchaseOrderId);

  /// «خصم من المورد» — نقصٌ أنقصه المورد مما علينا، بلا حركة مال. يُعيد الصفَّ كما حفظه الخادم،
  /// و[clientToken] يجعل الإعادةَ آمنة كما في الدفعة.
  Future<Either<Failure, VendorPayment>> creditVendor({
    required int vendorId,
    required String amount,
    int? purchaseOrderId,
    String? notes,
    String? clientToken,
  });
}
