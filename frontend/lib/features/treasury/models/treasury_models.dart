/// الحسابات والخزائن — ما ترسله نقاط الخزينة. TREASURY-DESIGN §٤، §٩.
///
/// **أصنافٌ عادية لا Freezed**، على نسق `ShortageCounts`: كلُّها للقراءة، و`fromJson` مكتوبٌ
/// باليد أقصر من التعليقات التوضيحية — فلا يحتاج الجزء كلُّه إلى توليد. وما يُرقَّع منها بعد
/// كتابةٍ نجحت له `copyWith` صغيرة بقدر الحاجة.
///
/// **المال نصٌّ من السلك إلى الشاشة**، كما في التطبيق كله: «1250.00» هو ما قاله الخادم، والمرور
/// بـ`double` تقريبٌ لم يطلبه أحد.
library;

String _string(Object? value, [String fallback = '']) => value?.toString() ?? fallback;

String? _stringOrNull(Object? value) => value?.toString();

int? _intOrNull(Object? value) => (value as num?)?.toInt();

DateTime? _dateOrNull(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

Map<String, dynamic>? _mapOrNull(Object? value) => value is Map<String, dynamic> ? value : null;

List<Map<String, dynamic>> _maps(Object? value) =>
    value is List ? value.whereType<Map<String, dynamic>>().toList(growable: false) : const [];

/// نوعُ المكان الذي فيه المال. [unknown] يُبقي نوعاً لم يسمع به هذا الإصدار مقروءاً بدل أن
/// يُسقط القائمة كلها.
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

/// من يحمل الحساب باسمه، أو من تسمّيه الحركة.
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

/// مكانٌ فيه المال: الخزنة الرئيسية، المصرف، مصرف علي، ليبيانا، النورس.
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

  /// للعهدة وحدها: أين يذهب مالها عند «تم التسوية» حين لا يختار أحد. فارغٌ = القاعدة المبنيّة:
  /// المصرف للنورس، والخزنة للمندوب.
  final int? settlesIntoId;
  final String? settlesIntoName;

  /// «يُجمَع عند التسوية» — مطفأً يُبقي مالَ الطلبيات حيث نزل ولو كان تجميعُ نوعه مفعّلاً.
  /// TREASURY-DESIGN §١٨.
  final bool isCollected;

  /// للنقد وحده: مكتبُ «استلام مكتب» الذي ينزل كاشُه هنا. TREASURY-DESIGN §١٩.
  final int? pickupCityId;

  /// الحساب الذي تنزل فيه الطريقة حين لا يُختار حساب — واحدٌ لكل نوع.
  final bool isDefault;
  final bool isActive;

  /// حساب النورس: يكتب فيه الـ webhook، ولا يُعطَّل.
  final bool isSystem;

  /// كاذبٌ للعهدة — تمتلئ من الزبائن وتُفرَّغ بالتسوية، فلا تُعرض عليها العمليات اليدوية التي
  /// ستُرفض.
  final bool isSpendable;

  /// «مصرف علي» — باسم من الحساب. فارغٌ لأدراج الشركة نفسها.
  final TreasuryPerson? holder;

  /// ما فيه — مجموعُ حركاته كما جمعها الخادم. فارغٌ حين لم يُطلب.
  final String? balance;
  final String? notes;

  /// تحت الصفر: يُرسم بالأحمر لأنه يجب أن يُرى (TREASURY-DESIGN §١٢).
  bool get isOverdrawn => (balance ?? '').startsWith('-');

  /// نسخةٌ تختلف فيما سُمّي وحده — لترقيع صفٍّ بعد كتابةٍ يعرف التطبيقُ أثرها.
  ///
  /// [clearPickupCity] لأن `null` في [pickupCityId] يعني «اتركه كما هو».
  TreasuryAccount copyWith({
    bool? isDefault,
    bool? isActive,
    bool? isCollected,
    int? pickupCityId,
    bool clearPickupCity = false,
  }) => TreasuryAccount(
    id: id,
    name: name,
    kind: kind,
    kindLabel: kindLabel,
    isDefault: isDefault ?? this.isDefault,
    isActive: isActive ?? this.isActive,
    isSystem: isSystem,
    isSpendable: isSpendable,
    holder: holder,
    balance: balance,
    notes: notes,
    settlesIntoId: settlesIntoId,
    settlesIntoName: settlesIntoName,
    isCollected: isCollected ?? this.isCollected,
    pickupCityId: clearPickupCity ? null : (pickupCityId ?? this.pickupCityId),
  );

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

/// يضع [saved] مكان نسخته في [accounts] — وإن صار افتراضياً لنوعه نزع اللقبَ عن الباقين، لأن
/// للنوع افتراضياً واحداً والخادمُ نزعه في المعاملة نفسها (`MakeSoleDefault`).
List<TreasuryAccount> withSavedAccount(List<TreasuryAccount> accounts, TreasuryAccount saved) => [
  for (final account in accounts)
    if (account.id == saved.id)
      saved
    else if (saved.isDefault && account.kind == saved.kind && account.isDefault)
      account.copyWith(isDefault: false)
    else
      account,
];

/// مكتبٌ يستلم منه الزبائن، والخزنة التي ينزل فيها كاشُه — فارغةٌ للقواعد العادية.
/// TREASURY-DESIGN §١٩.
class PickupOffice {
  const PickupOffice({required this.cityId, required this.name, this.accountId, this.accountName});

  final int cityId;
  final String name;
  final int? accountId;
  final String? accountName;

  /// المكتب نفسه بخزنةٍ أخرى — أو بلا خزنة حين يكون [account] فارغاً.
  PickupOffice servedBy(TreasuryAccount? account) =>
      PickupOffice(cityId: cityId, name: name, accountId: account?.id, accountName: account?.name);

  factory PickupOffice.fromJson(Map<String, dynamic> json) => PickupOffice(
    cityId: (json['city_id'] as num).toInt(),
    name: _string(json['name']),
    accountId: _intOrNull(json['account_id']),
    accountName: _stringOrNull(json['account_name']),
  );
}

/// «التجميع عند التسوية» لنوعٍ واحد: مفعّلٌ أم لا، والحساب الذي يُجمع فيه — فارغٌ لافتراضي
/// النوع. TREASURY-DESIGN §١٨.
class CollectionSetting {
  const CollectionSetting({required this.on, this.intoId});

  final bool on;
  final int? intoId;
}

/// «إعدادات المالية» — مفاتيح المالك على قواعد الخزينة. TREASURY-DESIGN §١٦.
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

  /// الدفعة تنزل في حساب من يسجّلها قبل افتراضي الطريقة.
  final bool ownAccountFirst;

  /// السحب والمصروف والتحويل ودفعة المورد تُرفض فوق الرصيد.
  final bool blockOverdraft;
  final bool withdrawalNeedsReason;

  /// خانة «احتفظ به الناقل» تُعرض على شاشة التسوية.
  final bool askCarrierFee;

  /// `2026-09-30` — لا شيء يدويّ بتاريخه أو قبله. فارغٌ: لا شيء مقفل.
  final String? lockedUntil;

  /// «التجميع عند التسوية» للنقد والمصارف وليبيانا. النوع الغائب منها مطفأ.
  final Map<AccountKind, CollectionSetting> collections;

  /// «خزنة كل مكتب استلام» — كل مكتب، وخزنته إن رُبطت.
  final List<PickupOffice> pickupOffices;

  CollectionSetting collectionOf(AccountKind kind) =>
      collections[kind] ?? const CollectionSetting(on: false);

  /// الإعدادات نفسها بمكاتب أخرى — حين يُعرف أثرُ ربط خزنةٍ دون إعادة القراءة.
  TreasurySettings withPickupOffices(List<PickupOffice> offices) => TreasurySettings(
    ownAccountFirst: ownAccountFirst,
    blockOverdraft: blockOverdraft,
    withdrawalNeedsReason: withdrawalNeedsReason,
    askCarrierFee: askCarrierFee,
    lockedUntil: lockedUntil,
    collections: collections,
    pickupOffices: offices,
  );

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
    pickupOffices: [
      for (final office in _maps(json['pickup_offices'])) PickupOffice.fromJson(office),
    ],
  );
}

/// كل حسابٍ يقرؤه هذا الشخص، وما فيها مجتمعة.
class TreasuryAccounts {
  const TreasuryAccounts({required this.accounts, required this.total, required this.canViewAll});

  final List<TreasuryAccount> accounts;

  /// مجموع الخادم نفسه للحسابات المفعّلة — ولمن يحمل حساباً، ماله هو وحده.
  final String total;

  /// كاذبٌ لمن يقرأ الحسابات التي باسمه وحدها.
  final bool canViewAll;

  TreasuryAccounts withAccounts(List<TreasuryAccount> accounts) =>
      TreasuryAccounts(accounts: accounts, total: total, canViewAll: canViewAll);

  factory TreasuryAccounts.fromJson(Map<String, dynamic> json) => TreasuryAccounts(
    accounts: [for (final account in _maps(json['accounts'])) TreasuryAccount.fromJson(account)],
    total: _string(json['total'], '0.00'),
    canViewAll: json['can_view_all'] == true,
  );
}

/// الداخل والخارج من نوع حركةٍ واحد على حسابٍ واحد — «الإيداعات ٥٠٠».
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

/// رأس صفحة الحساب: الحساب، وأرقامه بالنوع.
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

  /// الأرقام نفسها بحسابٍ عُدّل — التعديل لا يحرّك مالاً، فالمجاميع باقية.
  TreasuryAccountDetail withAccount(TreasuryAccount account) => TreasuryAccountDetail(
    account: account,
    totalIn: totalIn,
    totalOut: totalOut,
    byKind: byKind,
  );

  factory TreasuryAccountDetail.fromJson(Map<String, dynamic> json) {
    final totals = _mapOrNull(json['totals']) ?? const <String, dynamic>{};

    return TreasuryAccountDetail(
      account: TreasuryAccount.fromJson(json['account'] as Map<String, dynamic>),
      totalIn: _string(totals['total_in'], '0.00'),
      totalOut: _string(totals['total_out'], '0.00'),
      byKind: [for (final kind in _maps(totals['by_kind'])) KindTotal.fromJson(kind)],
    );
  }
}

/// سطرٌ واحد من سجلّ الحساب.
class TreasuryMovement {
  const TreasuryMovement({
    required this.id,
    required this.kind,
    required this.kindLabel,
    required this.isIn,
    required this.signedAmount,
    required this.isReversal,
    this.isReversible = false,
    this.isReversed = false,
    this.reversesMovementId,
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

  /// «+50.00» / «-300.00» — الإشارة هي المقصود.
  final String signedAmount;

  /// ما بقي في الحساب بعد هذا السطر — يجمعه الخادم على السجل كله، فلا تبدأ صفحةٌ مصفّاة من صفر.
  final String? balanceAfter;
  final DateTime? occurredAt;

  /// «الطلب المرتبط» — يفتح الطلبية حين تكون.
  final int? orderId;

  /// العملية اليدوية التي كتبته.
  final int? operationId;

  /// الطرف الآخر في التحويل والتسوية — «من النورس» / «إلى المصرف».
  final String? counterpartName;
  final String? categoryName;
  final String? employeeName;

  /// «الموظف الذي نفّذها».
  final String? recorderName;
  final bool isReversal;

  /// **الخادم وحده يقول إن كان يُعكس** (`is_reversible`). غائبٌ عند خادمٍ أقدم = لا عكس، فلا
  /// يُعرض زرٌّ يرفضه الخادم.
  final bool isReversible;

  /// عُكس هذا السطر — يُرسم مشطوباً.
  final bool isReversed;

  /// السطر الذي يعكسه هذا، إن كان عكساً.
  final int? reversesMovementId;
  final String? notes;

  /// السطر نفسه بعد أن عُكس: مشطوب، ولا يُعكس مرةً ثانية.
  TreasuryMovement markedReversed() => TreasuryMovement(
    id: id,
    kind: kind,
    kindLabel: kindLabel,
    isIn: isIn,
    signedAmount: signedAmount,
    isReversal: isReversal,
    isReversed: true,
    reversesMovementId: reversesMovementId,
    balanceAfter: balanceAfter,
    occurredAt: occurredAt,
    orderId: orderId,
    operationId: operationId,
    counterpartName: counterpartName,
    categoryName: categoryName,
    employeeName: employeeName,
    recorderName: recorderName,
    notes: notes,
  );

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
    isReversible: json['is_reversible'] == true,
    isReversed: json['is_reversed'] == true,
    reversesMovementId: _intOrNull(json['reverses_movement_id']),
    notes: _stringOrNull(json['notes']),
  );
}

/// عمليةٌ يدوية، كما يجيب الخادم بعد كتابتها أو عكسها.
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

/// فيمَ صُرف المصروف — إيجار، رواتب، ما احتفظ به النورس.
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

  /// «سلفة موظف» — لا معنى لها بلا الموظف الذي سُلِّمت إليه.
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

/// حسابٌ واحد قد ينزل فيه مال نموذج الدفع.
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

/// الحسابات التي تقبلها الطريقة، والذي سيختاره الخادم لهذا الشخص حين يُترك «تلقائي».
class AccountOptions {
  const AccountOptions({required this.accounts, required this.suggestedId, this.suggestedName});

  final List<AccountOption> accounts;
  final int? suggestedId;

  /// **اسمُ ما سيختاره الخادم كما سمّاه هو** (`suggested_name`) — وقد لا يكون بين [accounts]:
  /// كاشٌ يُكتب باليد وطردُ الطلبية مع النورس في الطريق ينزل في حساب النورس، وليس خياراً.
  final String? suggestedName;

  factory AccountOptions.fromJson(Map<String, dynamic> json) {
    final accounts = [
      for (final account in _maps(json['accounts'])) AccountOption.fromJson(account),
    ];
    final suggestedId = _intOrNull(json['suggested_id']);

    return AccountOptions(
      accounts: accounts,
      suggestedId: suggestedId,
      // خادمٌ أقدم لا يرسل الاسم: يُسمّى من القائمة إن كان فيها.
      suggestedName:
          _stringOrNull(json['suggested_name']) ??
          accounts.where((account) => account.id == suggestedId).firstOrNull?.name,
    );
  }
}

/// مستثمرٌ تحفظ الشركة ماله — رأس مالٍ في المحفظة، وربحٌ لم يُسحب.
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

/// «لمن المال» — ما في الأدراج، ناقصاً ما يُحفظ لغيرنا. TREASURY-DESIGN §٩.
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
    investors: [
      for (final investor in _maps(json['investors'])) InvestorHolding.fromJson(investor),
    ],
    investorsTotal: _string(json['investors_total'], '0.00'),
    fundCash: _string(json['fund_cash'], '0.00'),
    companyOwn: _string(json['company_own'], '0.00'),
  );
}

/// سطرٌ في بطاقة المخزون — مخزنٌ أو صنف، وقيمته بالتكلفة.
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

/// قيمةُ الرفوف بما كلّفته — مجموعُ دفتر المخزون، لا حساب.
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

  /// «أعلى الأصناف قيمة» — TREASURY-DESIGN §٩.
  final List<ValueLine> topItems;

  factory InventoryValue.fromJson(Map<String, dynamic> json) => InventoryValue(
    total: _string(json['total'], '0.00'),
    company: _string(json['company'], '0.00'),
    fund: _string(json['fund'], '0.00'),
    byWarehouse: [for (final line in _maps(json['by_warehouse'])) ValueLine.fromJson(line)],
    topItems: [for (final line in _maps(json['top_items'])) ValueLine.fromJson(line)],
  );
}

/// ما يفعله الإنسان بالخزينة بيده. [wire] هو ما تنتظره نقطة الخادم.
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

  /// المال يخرج من الحساب الذي فُتح منه النموذج.
  bool get takesFrom => this == withdrawal || this == expense || this == transfer;

  /// السبب إجباريٌّ دائماً في الجرد. وفي السحب يتبع «السبب إجباري عند السحب» في «إعدادات
  /// المالية»، والخادم يفرضه — والنموذج يسأل عنه فقط.
  bool get needsNotes => this == adjustment;

  /// هل يسمّي النموذج ملاحظته «السبب» بدل ملاحظةٍ اختيارية.
  bool get asksReason => this == withdrawal || this == adjustment;
}
