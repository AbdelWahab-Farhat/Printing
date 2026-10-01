/// الحسابات والخزائن — what the treasury endpoints send. TREASURY-DESIGN §٤, §٩.
///
/// **Plain classes, not Freezed**, like `ShortageCounts`: every one is read-only, none is copied
/// or compared, and a hand-written `fromJson` is shorter than the annotations — and adding the
/// feature needs no code generation.
///
/// Money stays a `String` from wire to screen, as everywhere in this app: «1250.00» is what the
/// server said, and a `double` on the way would be a rounding nobody asked for.
library;

String _string(Object? value, [String fallback = '']) => value?.toString() ?? fallback;

String? _stringOrNull(Object? value) => value?.toString();

int? _intOrNull(Object? value) => (value as num?)?.toInt();

DateTime? _dateOrNull(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

Map<String, dynamic>? _mapOrNull(Object? value) => value is Map<String, dynamic> ? value : null;

List<Map<String, dynamic>> _maps(Object? value) =>
    value is List ? value.whereType<Map<String, dynamic>>().toList(growable: false) : const [];

/// What kind of place the money is in. [unknown] keeps a kind this build has never heard of
/// readable rather than failing the whole list.
enum AccountKind {
  cash('cash'),
  bank('bank'),
  wallet('wallet'),
  custody('custody'),
  unknown('unknown');

  const AccountKind(this.wire);

  final String wire;

  static AccountKind fromWire(Object? value) =>
      values.firstWhere((kind) => kind.wire == value, orElse: () => AccountKind.unknown);
}

/// Someone an account is held by, or whom a movement names.
class TreasuryPerson {
  const TreasuryPerson({required this.id, required this.name, this.employeeCode});

  final int id;
  final String name;
  final String? employeeCode;

  static TreasuryPerson? fromJson(Object? json) {
    final map = _mapOrNull(json);
    if (map == null) return null;

    return TreasuryPerson(
      id: (map['id'] as num).toInt(),
      name: _string(map['name']),
      employeeCode: _stringOrNull(map['employee_code']),
    );
  }
}

/// A place money is: الخزنة الرئيسية، المصرف، مصرف علي، ليبيانا، النورس.
class TreasuryAccount {
  const TreasuryAccount({
    required this.id,
    required this.name,
    required this.kind,
    required this.kindLabel,
    required this.isDefault,
    required this.isActive,
    required this.isSystem,
    required this.isSpendable,
    this.holder,
    this.balance,
    this.notes,
    this.settlesIntoId,
    this.settlesIntoName,
    this.isCollected = true,
    this.pickupCityId,
  });

  final int id;
  final String name;
  final AccountKind kind;
  final String kindLabel;

  /// Custody only: where its money goes at «تم التسوية» when nobody picks. Null: the built-in
  /// rule — the bank for Nawris, the cash box for a driver.
  final int? settlesIntoId;
  final String? settlesIntoName;

  /// «يُجمَع عند التسوية» — false keeps its order money where it landed, even with its kind's
  /// collection on. TREASURY-DESIGN §١٨.
  final bool isCollected;

  /// Cash only: the «استلام مكتب» branch whose cash lands here. TREASURY-DESIGN §١٩.
  final int? pickupCityId;

  /// The account a method falls back to when nobody chose one — one per kind.
  final bool isDefault;
  final bool isActive;

  /// The Nawris account: the webhook writes to it and it cannot be switched off.
  final bool isSystem;

  /// False for custody — it fills from customers and empties by settlement, so the hand
  /// operations that would be refused on it are not offered.
  final bool isSpendable;

  /// «مصرف علي» — whose name the account is in. Null for the company's own drawers.
  final TreasuryPerson? holder;

  /// What it holds — the sum of its movements, as the server added it. Null when not asked for.
  final String? balance;
  final String? notes;

  /// Below zero: shown red, because it is meant to be seen (TREASURY-DESIGN §١٢).
  bool get isOverdrawn => (balance ?? '').startsWith('-');

  factory TreasuryAccount.fromJson(Map<String, dynamic> json) => TreasuryAccount(
    id: (json['id'] as num).toInt(),
    name: _string(json['name']),
    kind: AccountKind.fromWire(json['kind']),
    kindLabel: _string(json['kind_label']),
    isDefault: json['is_default'] == true,
    isActive: json['is_active'] != false,
    isSystem: json['is_system'] == true,
    isSpendable: json['is_spendable'] != false,
    holder: TreasuryPerson.fromJson(json['holder']),
    balance: _stringOrNull(json['balance']),
    notes: _stringOrNull(json['notes']),
    settlesIntoId: _intOrNull(json['settles_into_account_id']),
    settlesIntoName: _stringOrNull(_mapOrNull(json['settles_into'])?['name']),
    isCollected: json['is_collected'] != false,
    pickupCityId: _intOrNull(json['pickup_city_id']),
  );
}

/// A branch customers collect from, and the cash box its cash lands in — null for the usual
/// rules. TREASURY-DESIGN §١٩.
class PickupOffice {
  const PickupOffice({required this.cityId, required this.name, this.accountId, this.accountName});

  final int cityId;
  final String name;
  final int? accountId;
  final String? accountName;

  factory PickupOffice.fromJson(Map<String, dynamic> json) => PickupOffice(
    cityId: (json['city_id'] as num).toInt(),
    name: _string(json['name']),
    accountId: _intOrNull(json['account_id']),
    accountName: _stringOrNull(json['account_name']),
  );
}

/// «التجميع عند التسوية» for one kind: whether it is on, and the account it collects into —
/// null for the kind's default. TREASURY-DESIGN §١٨.
class CollectionSetting {
  const CollectionSetting({required this.on, this.intoId});

  final bool on;
  final int? intoId;
}

/// «إعدادات المالية» — the owner's switches over the treasury's rules. TREASURY-DESIGN §١٦.
class TreasurySettings {
  const TreasurySettings({
    required this.ownAccountFirst,
    required this.blockOverdraft,
    required this.withdrawalNeedsReason,
    required this.askCarrierFee,
    this.lockedUntil,
    this.collections = const {},
    this.pickupOffices = const [],
  });

  /// A payment lands in the recorder's own account before the method's default.
  final bool ownAccountFirst;

  /// Withdrawals, expenses, transfers and vendor payments are refused above the balance.
  final bool blockOverdraft;
  final bool withdrawalNeedsReason;

  /// «احتفظ به الناقل» is asked on the settle screen.
  final bool askCarrierFee;

  /// `2026-09-30` — nothing by hand dated on or before it. Null: nothing is locked.
  final String? lockedUntil;

  /// «التجميع عند التسوية», for cash, bank and wallet. A kind missing from it is off.
  final Map<AccountKind, CollectionSetting> collections;

  /// «خزنة كل مكتب استلام» — every pickup branch, with its box if one is linked.
  final List<PickupOffice> pickupOffices;

  CollectionSetting collectionOf(AccountKind kind) =>
      collections[kind] ?? const CollectionSetting(on: false);

  factory TreasurySettings.fromJson(Map<String, dynamic> json) => TreasurySettings(
    ownAccountFirst: json['own_account_first'] != false,
    blockOverdraft: json['block_overdraft'] != false,
    withdrawalNeedsReason: json['withdrawal_needs_reason'] != false,
    askCarrierFee: json['ask_carrier_fee'] != false,
    lockedUntil: _stringOrNull(json['locked_until']),
    collections: {
      for (final kind in const [AccountKind.cash, AccountKind.bank, AccountKind.wallet])
        kind: CollectionSetting(
          on: json['collect_${kind.wire}'] == true,
          intoId: _intOrNull(json['collect_${kind.wire}_into_id']),
        ),
    },
    pickupOffices: _maps(json['pickup_offices']).map(PickupOffice.fromJson).toList(growable: false),
  );
}

/// Every account the reader may see, and what they hold together.
class TreasuryAccounts {
  const TreasuryAccounts({required this.accounts, required this.total, required this.canViewAll});

  final List<TreasuryAccount> accounts;

  /// The server's own sum of the active accounts — for a holder, their own money only.
  final String total;

  /// False for somebody reading only the accounts in their name.
  final bool canViewAll;

  factory TreasuryAccounts.fromJson(Map<String, dynamic> json) => TreasuryAccounts(
    accounts: _maps(json['accounts']).map(TreasuryAccount.fromJson).toList(growable: false),
    total: _string(json['total'], '0.00'),
    canViewAll: json['can_view_all'] == true,
  );
}

/// In and out of one kind of movement on one account — «الإيداعات ٥٠٠».
class KindTotal {
  const KindTotal({
    required this.kind,
    required this.label,
    required this.moneyIn,
    required this.moneyOut,
    required this.net,
  });

  final String kind;
  final String label;
  final String moneyIn;
  final String moneyOut;
  final String net;

  factory KindTotal.fromJson(Map<String, dynamic> json) => KindTotal(
    kind: _string(json['kind']),
    label: _string(json['label']),
    moneyIn: _string(json['in'], '0.00'),
    moneyOut: _string(json['out'], '0.00'),
    net: _string(json['net'], '0.00'),
  );
}

/// The top of an account's page: the account, and its figures by kind.
class TreasuryAccountDetail {
  const TreasuryAccountDetail({
    required this.account,
    required this.totalIn,
    required this.totalOut,
    required this.byKind,
  });

  final TreasuryAccount account;
  final String totalIn;
  final String totalOut;
  final List<KindTotal> byKind;

  factory TreasuryAccountDetail.fromJson(Map<String, dynamic> json) {
    final totals = _mapOrNull(json['totals']) ?? const <String, dynamic>{};

    return TreasuryAccountDetail(
      account: TreasuryAccount.fromJson(json['account'] as Map<String, dynamic>),
      totalIn: _string(totals['total_in'], '0.00'),
      totalOut: _string(totals['total_out'], '0.00'),
      byKind: _maps(totals['by_kind']).map(KindTotal.fromJson).toList(growable: false),
    );
  }
}

/// One line of an account's history.
class TreasuryMovement {
  const TreasuryMovement({
    required this.id,
    required this.kind,
    required this.kindLabel,
    required this.isIn,
    required this.signedAmount,
    required this.isReversal,
    this.balanceAfter,
    this.occurredAt,
    this.orderId,
    this.operationId,
    this.counterpartName,
    this.categoryName,
    this.employeeName,
    this.recorderName,
    this.notes,
  });

  final int id;
  final String kind;
  final String kindLabel;
  final bool isIn;

  /// «+50.00» / «-300.00» — the sign is the point.
  final String signedAmount;

  /// What the account held after this line — added over the whole history on the server, so a
  /// filtered page does not restart it at zero.
  final String? balanceAfter;
  final DateTime? occurredAt;

  /// «الطلب المرتبط» — opens the order when there is one.
  final int? orderId;

  /// The hand operation that wrote it — a reversal is offered from it.
  final int? operationId;

  /// The other side of a transfer or a settlement — «من النورس» / «إلى المصرف».
  final String? counterpartName;
  final String? categoryName;
  final String? employeeName;

  /// «الموظف الذي نفّذها».
  final String? recorderName;
  final bool isReversal;
  final String? notes;

  factory TreasuryMovement.fromJson(Map<String, dynamic> json) => TreasuryMovement(
    id: (json['id'] as num).toInt(),
    kind: _string(json['kind']),
    kindLabel: _string(json['kind_label']),
    isIn: json['direction'] == 'in',
    signedAmount: _string(json['signed_amount'], '0.00'),
    balanceAfter: _stringOrNull(json['balance_after']),
    occurredAt: _dateOrNull(json['occurred_at']),
    orderId: _intOrNull(json['order_id']),
    operationId: _intOrNull(json['operation_id']),
    counterpartName: _stringOrNull(_mapOrNull(json['counterpart_account'])?['name']),
    categoryName: _stringOrNull(_mapOrNull(json['category'])?['name']),
    employeeName: _stringOrNull(_mapOrNull(json['employee'])?['name']),
    recorderName: _stringOrNull(_mapOrNull(json['recorder'])?['name']),
    isReversal: json['is_reversal'] == true,
    notes: _stringOrNull(json['notes']),
  );
}

/// A hand operation, as the server answers after writing or reversing one.
class TreasuryOperation {
  const TreasuryOperation({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.amount,
    required this.isReversible,
  });

  final int id;
  final String type;
  final String typeLabel;
  final String amount;
  final bool isReversible;

  factory TreasuryOperation.fromJson(Map<String, dynamic> json) => TreasuryOperation(
    id: (json['id'] as num).toInt(),
    type: _string(json['type']),
    typeLabel: _string(json['type_label']),
    amount: _string(json['amount'], '0.00'),
    isReversible: json['is_reversible'] == true,
  );
}

/// What an expense was for — rent, salaries, what Nawris kept.
class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.requiresEmployee,
    required this.isActive,
    required this.isSystem,
  });

  final int id;
  final String name;

  /// «سلفة موظف» — meaningless without the employee it was handed to.
  final bool requiresEmployee;
  final bool isActive;
  final bool isSystem;

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) => ExpenseCategory(
    id: (json['id'] as num).toInt(),
    name: _string(json['name']),
    requiresEmployee: json['requires_employee'] == true,
    isActive: json['is_active'] != false,
    isSystem: json['is_system'] == true,
  );
}

/// One account a payment form may land money in.
class AccountOption {
  const AccountOption({
    required this.id,
    required this.name,
    required this.kindLabel,
    required this.isDefault,
  });

  final int id;
  final String name;
  final String kindLabel;
  final bool isDefault;

  factory AccountOption.fromJson(Map<String, dynamic> json) => AccountOption(
    id: (json['id'] as num).toInt(),
    name: _string(json['name']),
    kindLabel: _string(json['kind_label']),
    isDefault: json['is_default'] == true,
  );
}

/// The accounts a method fits, and the one the treasury would pick for this person.
class AccountOptions {
  const AccountOptions({required this.accounts, required this.suggestedId});

  final List<AccountOption> accounts;
  final int? suggestedId;

  factory AccountOptions.fromJson(Map<String, dynamic> json) => AccountOptions(
    accounts: _maps(json['accounts']).map(AccountOption.fromJson).toList(growable: false),
    suggestedId: _intOrNull(json['suggested_id']),
  );
}

/// An investor whose money the company is keeping — capital in the wallet, profit not withdrawn.
class InvestorHolding {
  const InvestorHolding({
    required this.id,
    required this.name,
    required this.capital,
    required this.profit,
  });

  final int id;
  final String name;
  final String capital;
  final String profit;

  factory InvestorHolding.fromJson(Map<String, dynamic> json) => InvestorHolding(
    id: (json['id'] as num).toInt(),
    name: _string(json['name']),
    capital: _string(json['capital'], '0.00'),
    profit: _string(json['profit'], '0.00'),
  );
}

/// «لمن المال» — what the drawers hold, less what is kept for others. TREASURY-DESIGN §٩.
class TreasuryOwnership {
  const TreasuryOwnership({
    required this.totalHeld,
    required this.investors,
    required this.investorsTotal,
    required this.fundCash,
    required this.companyOwn,
  });

  final String totalHeld;
  final List<InvestorHolding> investors;
  final String investorsTotal;
  final String fundCash;
  final String companyOwn;

  factory TreasuryOwnership.fromJson(Map<String, dynamic> json) => TreasuryOwnership(
    totalHeld: _string(json['total_held'], '0.00'),
    investors: _maps(json['investors']).map(InvestorHolding.fromJson).toList(growable: false),
    investorsTotal: _string(json['investors_total'], '0.00'),
    fundCash: _string(json['fund_cash'], '0.00'),
    companyOwn: _string(json['company_own'], '0.00'),
  );
}

/// A line of the inventory card — a warehouse or a material, and what it is worth at cost.
class ValueLine {
  const ValueLine({required this.name, required this.value, this.quantity});

  final String name;
  final String value;
  final String? quantity;

  factory ValueLine.fromJson(Map<String, dynamic> json) => ValueLine(
    name: _string(json['name']),
    value: _string(json['value'], '0.00'),
    quantity: _stringOrNull(json['quantity']),
  );
}

/// What the shelves are worth at what they cost — the stock ledger's total, not an account.
class InventoryValue {
  const InventoryValue({
    required this.total,
    required this.company,
    required this.fund,
    required this.byWarehouse,
    required this.topItems,
  });

  final String total;
  final String company;
  final String fund;
  final List<ValueLine> byWarehouse;
  final List<ValueLine> topItems;

  factory InventoryValue.fromJson(Map<String, dynamic> json) => InventoryValue(
    total: _string(json['total'], '0.00'),
    company: _string(json['company'], '0.00'),
    fund: _string(json['fund'], '0.00'),
    byWarehouse: _maps(json['by_warehouse']).map(ValueLine.fromJson).toList(growable: false),
    topItems: _maps(json['top_items']).map(ValueLine.fromJson).toList(growable: false),
  );
}

/// What a person does to the treasury by hand. [wire] is what the endpoint expects.
enum OperationKind {
  deposit('deposit', 'إيداع'),
  withdrawal('withdrawal', 'سحب'),
  expense('expense', 'مصروف'),
  transfer('transfer', 'تحويل'),
  adjustment('adjustment', 'جرد الحساب'),
  opening('opening', 'رصيد افتتاحي');

  const OperationKind(this.wire, this.label);

  final String wire;
  final String label;

  /// Money leaves the account the form opened from.
  bool get takesFrom => this == withdrawal || this == expense || this == transfer;

  /// The reason is always mandatory on a count. On a withdrawal it follows «السبب إجباري عند
  /// السحب» in «إعدادات المالية», which the server enforces — the form only asks for it.
  bool get needsNotes => this == adjustment;

  /// Whether the form calls its note «السبب» rather than an optional note.
  bool get asksReason => this == withdrawal || this == adjustment;
}
