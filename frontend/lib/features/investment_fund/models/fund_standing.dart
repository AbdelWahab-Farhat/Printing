import 'package:freezed_annotation/freezed_annotation.dart';

part 'fund_standing.freezed.dart';
part 'fund_standing.g.dart';

/// قيمةُ الصندوق — مفصولةً إلى بنودها لا مجموعةً في رقم.
///
/// **المجموعُ وحده ادّعاء.** من يقرأ «٢٦٬٠٠٠» يحتاج أن يعرف كم منها نقدٌ في الخزينة وكم بضاعةٌ
/// على رفّ وكم بضاعةٌ في المطبعة لم تُسلَّم بعد — وعلى هذا الرقم تُقسَّم نسبُ كل مستثمر، فبندٌ
/// مخفيٌّ فيه مالُ أحدهم.
///
/// **وكلُّ أصلٍ بتكلفته**، والهامشُ يخصّ فترةَ طلبيته لا فترةَ قبضه: بضاعةٌ خرجت في سبتمبر
/// وتُسلَّم في أكتوبر تدخل هنا بما كلّفت، وربحُها يبقى لسبتمبر.
@freezed
abstract class FundValuation with _$FundValuation {
  const factory FundValuation({
    /// ما في الخزينة فعلاً — يتحرّك عند التحصيل لا عند التسليم.
    required String cash,

    /// البضاعةُ التي ما زالت على الرفّ، بتكلفتها المجمّدة يوم وصلت.
    @JsonKey(name: 'stock_on_shelf') required String stockOnShelf,

    /// خرجت من الرفّ ولم تصل العميل بعد.
    @JsonKey(name: 'goods_in_flight') required String goodsInFlight,

    /// سُلِّمت ولم تُحصَّل — بتكلفتها، لا بما ستُقبض به.
    @JsonKey(name: 'receivables_at_cost') required String receivablesAtCost,

    /// ربحٌ يملكه مستثمرٌ ولم يصل جيبه — دَينٌ على الصندوق لا رأسُ مالٍ عامل، فيُطرح.
    @JsonKey(name: 'profit_owed') required String profitOwed,

    required String total,
  }) = _FundValuation;

  factory FundValuation.fromJson(Map<String, dynamic> json) => _$FundValuationFromJson(json);
}

/// فترةٌ من فترات الصندوق — الجاريةُ على اللوحة، وكلُّها في السجلّ.
@freezed
abstract class FundPeriod with _$FundPeriod {
  const factory FundPeriod({
    required int id,
    required String code,
    required String status,
    @JsonKey(name: 'status_label') required String statusLabel,

    @JsonKey(name: 'starts_on') required String startsOn,
    @JsonKey(name: 'ends_on') required String endsOn,

    /// آخرُ يومٍ يُقبَل فيه إيداعُ رأس مال؛ ما بعده يُحتجز للفترة التالية.
    @JsonKey(name: 'subscription_closes_on') required String subscriptionClosesOn,

    /// **حلّ موعدُها ولم تُقفَل.** الجدولةُ تُقفلها في ساعتها الأولى، فبقاءُ هذا صادقاً يعني
    /// أنها صمتت — واللوحةُ تقوله ولا تسكت عنه.
    @JsonKey(name: 'is_due_to_close') required bool isDueToClose,

    /// كم يوماً مرّ وهي مستحقّةٌ ولم تُقفَل — `null` ما لم تستحقّ، وصفرٌ يومَها.
    @JsonKey(name: 'overdue_days') int? overdueDays,

    /// **كم طلبيةً تحبسها «قيد الإغلاق».** `null` لغير المنتظِرة: المفتوحةُ لا تنتظر شيئاً بعد،
    /// والمغلقةُ لم يبقَ لها شيء.
    @JsonKey(name: 'owed_orders') int? owedOrders,

    @JsonKey(name: 'period_months') required int periodMonths,
    @JsonKey(name: 'investor_profit_share_percent')
    required String investorProfitSharePercent,

    @JsonKey(name: 'opening_stock_cost') required String openingStockCost,
    @JsonKey(name: 'opening_cash') required String openingCash,

    /// **بابُ الاكتتاب.** الخادمُ يقرّر، لا الشاشةُ بمقارنة تواريخ: قاعدةٌ واحدة تُنفَّذ في موضعٍ
    /// واحد، ولا تختلف نسخةٌ مثبَّتةٌ على هاتف عن الخادم يوم تتغيّر.
    @JsonKey(name: 'accepts_capital') @Default(false) bool acceptsCapital,

    /// **ولمن هذه النافذة؟** الداخلُ منها لا يقاسم شهراً بدأ بالفعل: نصيبُه يبدأ من الفترة
    /// التالية. والاستثناءُ أوّلُ فتراتِ الصندوق — ولا تحسبه الشاشةُ، الخادمُ يقوله.
    @JsonKey(name: 'subscription_serves_next_period')
    @Default(false)
    bool subscriptionServesNextPeriod,

    /// مدةُ حبس رأس المال المجمَّدة على هذه الفترة — ما سيُنسَخ على كل دفعةٍ تدخل فيها.
    @JsonKey(name: 'capital_lock_months') @Default(12) int capitalLockMonths,

    /// أهذه آخرُ فتراتِ دورةِ تسوية؟
    @JsonKey(name: 'ends_settlement_cycle') @Default(false) bool endsSettlementCycle,

    /// ما كُتب عليها إن أُقفلت بتجاوز — يبقى على الشاشة ولا يُطوى.
    @JsonKey(name: 'override_reason') String? overrideReason,

    /// أرقامُ الإقفال — `null` ما دامت مفتوحة، فلا يُعرض صفرٌ مكان «لم يُحسب بعد».
    @JsonKey(name: 'closed_at') String? closedAt,
    @JsonKey(name: 'net_profit') String? netProfit,
    @JsonKey(name: 'investors_pool') String? investorsPool,
    @JsonKey(name: 'company_share') String? companyShare,
    @JsonKey(name: 'sales_revenue') String? salesRevenue,
    @JsonKey(name: 'closing_stock_cost') String? closingStockCost,
    @JsonKey(name: 'closing_cash') String? closingCash,
  }) = _FundPeriod;

  factory FundPeriod.fromJson(Map<String, dynamic> json) => _$FundPeriodFromJson(json);
}

/// شريكٌ في الصندوق كما يقف اليوم.
///
/// **أربعةُ أرقامٍ لا رقمٌ واحد**: «نسبتُه» ماذا سيأخذ من ربح هذه الفترة، و«وحداتُه» بماذا
/// استحقّها، و«رأسُ ماله» ماذا وضع، و«ربحُه» ماذا أخذ ولم يسحبه. جمعُها يُخفي أيَّها يتحرّك.
@freezed
abstract class FundHolder with _$FundHolder {
  const factory FundHolder({
    @JsonKey(name: 'investor_id') required int investorId,
    required String name,
    required String units,
    @JsonKey(name: 'share_percent') required String sharePercent,
    required String capital,
    required String profit,

    /// **اكتتب في نافذة هذه الفترة، فنصيبُه منها صفر ومن التالية كامل.** وصفرٌ بجانب اسمِ رجلٍ
    /// وضع مالَه أمس يُقرأ عطباً، فيقولها السطرُ بلفظها.
    @JsonKey(name: 'share_starts_next_period')
    @Default(false)
    bool shareStartsNextPeriod,

    /// **نسبتُه في الفترة التالية لو فُتحت الليلة** — بكلّ وحداته، ومنها ما ينتظر. تقديرٌ لا
    /// عهد: إيداعٌ أو سحبٌ قبل بدئها يغيّره. والخادمُ يحسبه، لا الشاشة.
    @JsonKey(name: 'next_share_percent') @Default('0.000000') String nextSharePercent,
  }) = _FundHolder;

  factory FundHolder.fromJson(Map<String, dynamic> json) => _$FundHolderFromJson(json);
}

/// وضعُ الصندوق كما يقرؤه الخادم: قيمتُه، وفترتُه، ووحداتُه، ومن يملكها.
@freezed
abstract class FundStanding with _$FundStanding {
  const factory FundStanding({
    required FundValuation valuation,

    /// **بضاعة مشتراة لم تصل** — ثمنُها خرج من الخزينة ولم تصل الرفَّ بعد. بجانب القيمة لا
    /// داخلها، قرارُ المالك 2026-09-24: «عرض لأن المال استُعمل بالفعل».
    @JsonKey(name: 'goods_on_order') @Default('0.00') String goodsOnOrder,

    /// `null` قبل أن تُفتح أوّلُ فترة — وهي حالةٌ تُقال صراحةً لا تُخترع لها فترةٌ وهمية.
    FundPeriod? period,

    /// **سعرُ الوحدة اليوم** — ما يشتري به الداخلُ الجديد. يُحسب في الخادم ولا يُعاد حسابُه
    /// هنا: تنفيذٌ ثانٍ للقاعدة هو الذي يخالفها يوم تتغيّر.
    @JsonKey(name: 'unit_price') @Default('1.000000') String unitPrice,

    @JsonKey(name: 'units_outstanding') @Default('0.000000') String unitsOutstanding,

    @Default(<FundHolder>[]) List<FundHolder> investors,

    /// **فتراتٌ «قيد الإغلاق»** — انتهت نافذتُها وبقيت لها طلبياتٌ لم تصل أو لم تُحصَّل. لا
    /// تحبس أحداً، لكنها تبقى على اللوحة ما بقيت: «تبقى بلا حدّ، واللوحةُ تصرخ».
    @JsonKey(name: 'waiting_periods') @Default(<FundPeriod>[]) List<FundPeriod> waitingPeriods,

    /// **سعرُ السادة الافتراضي** — يصل مع اللوحة لأن شاشةَ الشراء تقرأ اللوحةَ قبل أن تُملأ
    /// حقولُها، وطلبٌ ثانٍ للإعدادات في اللحظة نفسها رحلةٌ زائدة لرقمٍ واحد. افتراضٌ يُعرض
    /// ويُغيَّر، لا قاعدةٌ في حساب.
    @JsonKey(name: 'default_plain_sale_price') String? defaultPlainSalePrice,

    /// **سقفُ اشتراك كل مستثمر اليوم** — رصيدُ محفظته. يصل مع اللوحة لأن الورقة تحتاجه قبل أن
    /// يُكتب رقم، ولأنه رصيدٌ لا يعرفه إلا الخادم: زميلٌ سجّل سحباً قبل ثانية.
    @Default(<FundSubscriber>[]) List<FundSubscriber> subscribable,
  }) = _FundStanding;

  factory FundStanding.fromJson(Map<String, dynamic> json) => _$FundStandingFromJson(json);
}

/// مستثمرٌ وما يمكن أن يشترك به اليوم.
///
/// **كلُّ المستثمرين لا حَمَلةُ الوحدات وحدهم**: الداخلُ الجديد هو بالضبط من لا وحداتِ له.
@freezed
abstract class FundSubscriber with _$FundSubscriber {
  const factory FundSubscriber({
    @JsonKey(name: 'investor_id') required int investorId,
    required String name,

    /// رأسُ ماله الحرّ — سقفُ الاشتراك.
    @JsonKey(name: 'wallet_capital') required String walletCapital,

    /// أرباحُه المتاحة — تصير رأسَ مالٍ بحركةٍ واحدة من شاشة محفظته، ثم تُشترك.
    @JsonKey(name: 'wallet_profit') required String walletProfit,
  }) = _FundSubscriber;

  factory FundSubscriber.fromJson(Map<String, dynamic> json) => _$FundSubscriberFromJson(json);
}

/// ما يعود به الخادمُ بعد إيداع — **الوحداتُ والسعرُ وموعدُ فكّ الحبس**.
///
/// يُعرض للكاشير فوراً لأنه ما لا يمكن استرجاعه بالنظر: كم وحدةً اشترى هذا المال، وبأيّ سعر،
/// وإلى متى لا يخرج. ورقمٌ يُقال بعد الكتابة أصدقُ من رقمٍ يُقدَّر قبلها.
@freezed
abstract class DepositReceipt with _$DepositReceipt {
  const factory DepositReceipt({
    required String units,
    @JsonKey(name: 'unit_price') required String unitPrice,
    @JsonKey(name: 'locked_until') String? lockedUntil,
  }) = _DepositReceipt;

  factory DepositReceipt.fromJson(Map<String, dynamic> json) => _$DepositReceiptFromJson(json);
}
