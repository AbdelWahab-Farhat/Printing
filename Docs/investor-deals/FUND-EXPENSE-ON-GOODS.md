# مصروفُ الصندوق على البضاعة — يتبع البضاعةَ لا تاريخَه

> **الحالة:** مُنفَّذ 2026-10-12 على `main` — انظر §٧ «ما بُني». لم يُنشر على أيّ خادم.
> يبني على [CONTINUOUS-FUND-DESIGN.md](CONTINUOUS-FUND-DESIGN.md) و
> [PURCHASE-ORDER-ARRIVAL-COSTS.md](../purchase-orders/PURCHASE-ORDER-ARRIVAL-COSTS.md).

---

## ١. المشكلة

ربحُ الطلبية يُقسَّم على مستثمري **فترة الطلبية** (`placed_at`) بوحداتهم. ومصروفُ الصندوق يُقسَّم
على مستثمري **فترة يوم وقوعه** (`incurred_on`) — `RecordFundExpense` ← `RecordDealExpense` ←
`PostDealShare`. فشحنُ بضاعةٍ دُفع في الفترة ١ يحمله مستثمرو الفترة ١ وحدهم، وربحُ بيعها في
الفترة ٢ يقاسمه من دخل في الفترة ٢ — على تكلفةٍ لا تشمل الشحن.

| | أ | ب |
|---|---|---|
| أ وحده في الفترة ١ بـ11,000: بضاعة 10,000 + شحن 1,000 مصروفاً. ب يدخل الفترة ٢ بـ11,000 (٥٠٪). البيع 13,000، والربح الحقيقي 2,000 | | |
| **اليوم** | 500 | 1,500 |
| **بعد هذا التصميم** | 1,000 | 1,000 |

وتكاليفُ الوصول على بندٍ ممولٍ من الصندوق تقع اليوم كلُّها على فترة يوم الاستلام (القرار ٢ في
PURCHASE-ORDER-ARRIVAL-COSTS §٢)، فتصيبها المشكلةُ نفسها.

## ٢. قرارات المالك — 2026-10-12

| # | القرار |
|---|---|
| ١ | مصروفُ الصندوق يمكن **ربطُه بطلب شراء**. |
| ٢ | يتوزّع على **كل وحدات** ذلك الطلب التي وصلت — بيعت أو لم تُبع. |
| ٣ | حصةُ الباقي على الرفّ **تدخل تكلفة تلك البضاعة**، فيحملها من يقاسم ربحَ بيعها لاحقاً. |
| ٤ | حصةُ المباع **على فترة البيع نفسها** — الفترة التي أخذت ربحَ تلك الطلبية، بنسب مستثمريها. والمغلقةُ تقع على المفتوحة، كأي تصحيحٍ اليوم (`PeriodForEntry::floorOf`). |
| ٥ | تكاليفُ الوصول على بندٍ ممولٍ من **الصندوق** تتبع القاعدةَ نفسها (عند الاستلام لم يُبع شيء، فتدخل التكلفةَ كلَّها). يُلغي القرارَ ٢ من 2026-10-11 **للصندوق وحده**؛ الصفقاتُ القديمة كما هي. |
| ٦ | المصروفُ غيرُ المربوط بطلب شراء (إيجار، رواتب) يبقى مصروفَ فترةٍ كما الآن. |
| ٧ | المصاريف المسجّلة قبل هذا **تبقى كما هي** — لا تحويل. |
| ٨ | عكسُ استلام طلب الشراء **يعكس معه** كلَّ مصروفٍ مربوطٍ به، لا يُرفض. |

## ٣. القاعدة بالأرقام

طلبُ شراءٍ وصل منه 100 كيس، والمصروف 1,000 ← 10 لكل كيس. بيع 90 وبقي 10:

- **الـ10 الباقية:** `unit_cost` لطبقاتها يرتفع 10 ← 100 في قيمة البضاعة. تُطرح من ربح بيعها لاحقاً.
- **الـ90 المباعة:** 900 تُقسَّم على الطلبيات التي أخذتها بكمياتها، وكلُّ حصةٍ تُكتب خسارةً على
  مستثمري **فترة تلك الطلبية** — كما كُتب لهم ربحُها.

طلبُ شراءٍ فيه أكثر من بند: المصروفُ يُقسَّم أولاً على بنود الصندوق **بقيمة كل بند**
(`base_total_cost`) — طريقةُ `AllocatePurchaseOrderAdditionalCosts` نفسُها — ثم على وحدات كل بند.
بنودُ الشركة في الطلب نفسه لا تدخل: هذا مصروفُ الصندوق.

## ٤. التصميم

### ٤.١ أيُّ وحدات؟

وحداتُ البند = `purchase_order_items.quantity_received` (تراكميّ، يُنقص عند عكس الاستلام).

طبقاتُ البند تُعرف **بحركة الوصول** لا بـ`reference_id` (الذي يحمل رقمَ طلبيةٍ في مشتريات العجز):
`stock_arrivals.purchase_order_id` ← `stock_arrival_items.stock_movement_id` ←
`stock_batches.stock_movement_id`. ويأتي معها كلُّ نسخها — النقلُ بين المخازن
(`relocateBatches`) والتسليمُ للصندوق (`handOverBatches`) يحملان `stock_movement_id` الأصلي. يُؤخذ
منها ما `investor_deal_id` = الصندوق.

### ٤.٢ القسمة

لكلّ بند: `حصة البند` من التقسيم بالقيمة (بالقروش، الباقي الأكبر).

- `Δ` = حصة البند ÷ الكمية الواصلة، **مقرّبةً لأسفل إلى ٣ منازل** (دقة `unit_cost`).
- **حصةُ الرفّ** = Σ (`quantity_remaining` × Δ) على طبقات البند.
- **حصةُ المباع** = حصةُ البند − حصةُ الرفّ ← تُقسَّم على المستهلكين بكمياتهم (الباقي الأكبر).
  التقريبُ لأسفل يجعل فرقَ الفلوس يقع هنا، فالمجموعُ يساوي المصروفَ بقرشه.
- لا مستهلكَ وفرقُ تقريبٍ باقٍ ← صفٌّ واحد على فترة `incurred_on`.

### ٤.٣ مَن «المستهلك» وما فترتُه

استهلاكاتُ طبقات البند (`stock_batch_consumptions`) تحت حركاتٍ **غير معكوسة**:

| الحركة | مستهلك؟ | فترتُه |
|---|---|---|
| `order_fulfillment` (ومنها شراءُ المكينة من الرفّ) | نعم | فترةُ الطلبية: `coalesce(placed_at, created_at)` — ما يقرؤه `PeriodForEntry` للربح |
| `scrap_loss` | نعم | فترةُ الطلبية (`reference_id`) |
| `adjustment` نازلة: `damage` / `shortage` / `count_correction` | نعم | يومُ الحركة |
| `internal_transfer` / `ownership_transfer` / `arrival_reversal` | لا — الوحداتُ مستمرّة في طبقةٍ أخرى أو خرجت مع الاستلام | — |

### ٤.٤ ما يُكتب

**عمودان على `investor_deal_expenses`:** `purchase_order_id` (nullable FK) و
`landed_through_consumption_id` (آخرُ استهلاكٍ وُجد لحظةَ الهبوط — حدٌّ بين ما حُمِّل للمستهلك وما
حمل Δ في تكلفته).

**جدولٌ جديد `fund_expense_charges`** — صفٌّ لكلّ جزءٍ من المصروف:

| العمود | |
|---|---|
| `investor_deal_expense_id` | المصروف |
| `kind` | `shelf` (رفع تكلفة طبقة) · `consumer` (حصةُ مستهلك) · `rounding` |
| `stock_batch_id` | الطبقة (shelf) |
| `stock_movement_id` | حركةُ المستهلك (consumer) |
| `order_id` | الطلبية إن وُجدت — للشاشة |
| `quantity`, `unit_amount`, `amount` | الكمية، وΔ، والمبلغ |
| `charged_on`, `investment_period_id` | يومُ المصدر وفترتُه بعد الأرضية |
| `reverses_charge_id` | العكس — صفوفٌ لا تُعدَّل |
| timestamps + `deleted_at` + Auditable | قاعدةُ كل نموذج |

**الفعل `LandFundExpenseOnGoods`** — يناديه `RecordFundExpense` حين يحمل المصروفُ طلبَ شراء، تحت
قفل الصندوق وقفل أرصدة المخزن (ترتيبُ `ApplyStockChange`):

1. يقرأ بنود الصندوق وطبقاتها ومستهلكيها (§٤.١–٤.٣) في `Queries/PurchaseOrderFundUnits`.
2. صفوف `shelf`: يرفع `unit_cost` لكل طبقةٍ فيها باقٍ بمقدار Δ.
3. صفوف `consumer`: كلُّ صفٍّ **مصدرٌ** لـ`PostDealShare` (`AuditSubject::FundExpenseCharge`)،
   و`PeriodForEntry::dateOf` يقرأ له يومَ مستهلكه، فتُكتب خسارةُ الشركاء بنسب فترة البيع، ويدخل
   نصيبُ الشركة نقدَ الصندوق (`ExpenseCoveredByCompany`) — كما يفعل `coverTheCompanysShare` اليوم.
4. **الخزينةُ ونقدُ الصندوق كما هما:** خروجُ المبلغ كلِّه من الدرج، وقيدُ `Expense` في نقد الصندوق.
   حصةُ الرفّ تنقص النقدَ وتزيد البضاعةَ بالقدر نفسه، فسعرُ الوحدة لا يتحرّك.
5. لا صفوف `loss` بتاريخ `incurred_on` — `RecordDealExpense::chargeInvestors` يُتخطّى للمصروف المربوط.

### ٤.٥ ما يحدث بعد الهبوط

- **إلغاءُ طلبيةٍ أخذت وحداتٍ قبل الهبوط:** `CreditBackStockBatches` يردّها إلى **الطبقة نفسها**،
  وتلك صارت تحمل Δ. فحصةُ الطلبية تُعكس (`PostDealShare` بصفر) في اللحظة نفسها، وإلا حُسب نصيبُ
  تلك الوحدات مرتين. **الخطافُ هناك**، لأنه الموضعُ الوحيد الذي ترجع فيه وحداتٌ إلى طبقة.
- **تعديلُ البند والتسليمُ الجزئي** (`RedrawOrderLineStock`): يعكس السحبَ كلَّه (فتُعكس الحصة) ثم
  يسحب من جديد بالتكلفة الجديدة التي فيها Δ — فينتقل نصيبُها من الحصة إلى تكلفة البضاعة، بلا تكرار.
- **إلغاءُ شراء المكينة** (`stock_purchased_at`): الوحداتُ لا ترجع إلى طبقة الصندوق، بل تُفتح لها
  طبقةُ شركةٍ بسعر المكينة. الصندوقُ باعها، فالحصةُ **تبقى** على فترة البيع.
- **وحداتٌ دخلت بعد الهبوط** (استلامٌ جديد بعد عكس استلام): لا Δ عليها — المصروفُ وُزّع على ما وصل
  يومَها. الاستلامُ يُعكس فقط بعد عكس المصروف (§٤.٧).

### ٤.٦ عكسُ المصروف

بالمسار نفسه، بإشارةٍ معاكسة:

- صفوفُ `consumer` القائمة ← تُعكس (عكسُ خسارة الشركاء ونصيب الشركة).
- لكل صفٍّ `shelf`: الباقي اليوم من طبقته ونسخها ← `unit_cost` ينقص Δ. وما استُهلك منها **بعد**
  `landed_through_consumption_id` حمل Δ في تكلفته ← يُردّ لمستهلكه **ربحاً** في فترة بيعه
  (صفوف `consumer` موجبة).
- الخزينةُ ونقدُ الصندوق يعودان كما اليوم (`ReverseDealExpense`).
- **يُرفض 422** إن وقع أيٌّ من ذلك في فترةٍ **مغلقة** — امتدادٌ لقاعدة اليوم «مصروفُ فترةٍ أُقفلت
  يُرفض».

### ٤.٧ عكسُ استلام طلب الشراء

- تكاليفُ الوصول على بند الصندوق: `ReversePurchaseOrderReceipt` يعكس مصروفَها اليوم
  (`reverseSupplyExpensesOf`)؛ يبقى كذلك، ويجري **قبل** سحب الطبقات، فلا يبقى Δ على طبقةٍ تُسحب.
- مصروفٌ ربطه أحدٌ بيده بهذا الطلب: **يُعكس مع الاستلام تلقائياً** (القرار ٨)، بسبب العكس نفسه،
  وقبل سحب الطبقات. ولا يقع ما يمنعه: `WithdrawArrivalStockBatches` يرفض أصلاً طبقةً استُهلك منها،
  فحين يجوز عكسُ الاستلام لا مستهلكَ قائماً — يُرفع Δ عن الرفّ لا غير.

### ٤.٨ الأرقام والشاشات

- **«مصاريف الفترة»** (`CloseInvestmentPeriod::expensesOf`, `PeriodExpensesQuery`) و
  **«مصاريف الصندوق»** (`FundExpensesQuery`): المصروفُ المربوط يُعدّ **بصفوف `consumer`/`rounding`
  في فترتها** لا بمبلغه في فترة `incurred_on`. حصةُ الرفّ ليست مصروفَ فترة — تظهر لاحقاً في «تكلفة
  البضاعة المباعة» لفترة بيعها. يبقى مجموعُ القائمة المصفّاة = رقمَ شاشة الفترة (الاختبارُ القائم).
- **البطاقة** في «مصاريف الصندوق»: رقمُ طلب الشراء، و«على البضاعة X · على المبيعات Y».
- **«المصروف»** في تطبيق الموظفين: حقلٌ اختياري «طلب الشراء» — يعرض طلباتِ الشراء التي أدخلت
  بضاعةً للصندوق. بلا سطر شرحٍ تحته.
- **«بضاعة»** في لوحة الصندوق ترتفع بحصة الرفّ، ونقدُه ينقص بالمصروف كلِّه — كما يجب.

### ٤.٩ الحدود — مكتوبةٌ لا مخفيّة

- الصفقاتُ القديمة لا تتغيّر، و`RevalueStockBatch` يبقى يرفض الطبقات الممولة.
- `adjustment` بسبب `unit_change` (`SetStockItemUnit`) يفتح طبقاتٍ لا تحمل حركةَ الوصول، فتخرج
  الوحداتُ من نسب البند. نادرٌ، ويُعامل كمستهلكٍ في يومه.
- `MovementListQuery` يعرض `quantity_received × unit_cost` للاستلام كلِّه — فيُظهر Δ على المستهلَك
  أيضاً. **تُرك كما هو عن قصد:** هو ما يفعله اليومَ بعد كل «تصحيح تكلفة» (`RevalueStockBatch`)،
  أي «ما تقوله الطبقةُ إنّ البضاعة كلّفته الآن». عرضٌ فقط، ولا يقرؤه رقمٌ ماليّ.
- `consumedQuantity()` على الطبقة لا يُستعمل هنا؛ القسمةُ من صفوف الاستهلاك نفسها.

## ٥. خطة التنفيذ

**الهدف:** §٢ كما هو، للصندوق وحده.

**البيئة:** محلية — `APP_ENV=local`، قاعدة `printing_bags` على localhost، على `main` مباشرةً. لا نشر في
هذه الخطة.

**ملفات تُنشأ — الخادم:**
- `database/migrations/2026_10_12_100000_land_fund_expenses_on_goods.php` — العمودان + الجدول.
- `app/Domain/Investor/Models/FundExpenseCharge.php` + `database/factories/…/FundExpenseChargeFactory.php`
- `app/Domain/Investor/Enums/FundExpenseChargeKind.php`
- `app/Domain/Investor/Actions/LandFundExpenseOnGoods.php`
- `app/Domain/Investor/Actions/ReverseFundExpenseCharges.php` — العكس (§٤.٥ و§٤.٦)
- `app/Domain/Investor/Queries/PurchaseOrderFundUnits.php`
- `app/Domain/Investor/Queries/FundPurchaseOrdersQuery.php` — قائمةُ الحقل
- `tests/Feature/Investors/FundExpenseOnGoodsTest.php`

**ملفات تُعدَّل — الخادم:**
- `Actions/RecordFundExpense.php`, `Actions/RecordDealExpense.php` (تخطّي `chargeInvestors` للمربوط),
  `Actions/ReverseDealExpense.php`, `DTOs/DealExpenseData.php`, `Models/InvestorDealExpense.php`
- `Queries/PeriodForEntry.php`, `Queries/PeriodExpensesQuery.php`, `Queries/FundExpensesQuery.php`,
  `Actions/CloseInvestmentPeriod.php` (`expensesOf`)
- `Domain/Inventory/Actions/CreditBackStockBatches.php` (الخطاف)
- `Domain/PurchaseOrder/Actions/ReceivePurchaseOrder.php` (بند الصندوق ← هبوط),
  `ReversePurchaseOrderReceipt.php` (عكسُ المصروفات المربوطة قبل السحب)
- `Domain/Inventory/Queries/MovementListQuery.php` (§٤.٩)
- `Domain/Audit/Enums/AuditSubject.php`, `Domain/Audit/AuditAttributeLabels.php`
- `Application/Api/V1/Controllers/InvestmentFundController.php` (`purchase_order_id` في
  `storeExpense`، و`GET investment/purchase-orders`، و`/logs` للصفوف)،
  `Resources/InvestorDealExpenseResource.php`، `routes/api.php`
- اختباراتٌ قائمة تتغيّر توقّعاتُها: تكاليفُ الوصول على بند الصندوق، و`FundExpensesTest`،
  واختبارات «مصاريف الفترة».

**ملفات — تطبيق الموظفين:**
- `investment_fund/presentation/widgets/fund_expense_sheet.dart` (حقل «طلب الشراء»)
- `investment_fund/models/fund_expense.dart` (+ طلب الشراء والقسمة) و`build_runner`
- `investment_fund/presentation/widgets/fund_expense_card.dart`
- المستودع والحالات: قائمة طلبات الشراء، و`purchase_order_id` في التسجيل
- `core/network/api_endpoints.dart`
- اختبارات: الورقة، و`fund_expenses_page_test.dart`

**ملفات — التوثيق:** هذا الملف، وإشارةٌ في CONTINUOUS-FUND-DESIGN، وتعديلُ القرار ٢ في
PURCHASE-ORDER-ARRIVAL-COSTS.

**الأوامر:**
`php artisan migrate` (محلياً) · `php -d memory_limit=2G artisan test` على نسخة phpunit بقاعدةٍ
خاصّة · `./vendor/bin/pint <ملفاتي>` · `dart run build_runner build` (البناء الكامل لا
`--build-filter`) · `flutter analyze` · `flutter test` على الملفات المتأثرة.

**أثرُ قاعدة البيانات:** هجرةٌ **إضافية فقط** — عمودان nullable وجدولٌ جديد، و`down()` يحذفهما. لا
تعديل لبيانات قائمة (القرار ٧). محلياً فقط.

**خدماتٌ خارجية:** لا شيء.

**التحقق — الاختبارات أولاً (TDD، AAA):**
1. لم يُبع شيء ← المصروفُ كلُّه في `unit_cost`، لا صفوف `loss`، النقدُ والخزينة يخرجان.
2. بيع جزء ← Δ على الباقي، وحصصُ الطلبيات على فترة كلٍّ منها. **فترتان بشريكين مختلفين: الداخلُ
   الجديد لا يُحمَّل شيئاً من بيع الفترة ١.**
3. فترةُ البيع مغلقة ← الحصة على المفتوحة.
4. بيع الكلّ ← كلُّه على المستهلكين.
5. بندان بقيمتين ← القسمة بالقيمة؛ بندُ الشركة خارجها.
6. نُقلت البضاعة إلى مخزنٍ آخر ← النسخةُ ترتفع، والنقلُ ليس مستهلكاً.
7. إلغاءُ طلبيةٍ أخذت قبل الهبوط ← حصتُها تُعكس، والوحداتُ ترجع بـΔ.
8. تعديلُ بندٍ بعد الهبوط ← الحصةُ تُعكس والسحبُ الجديد بـΔ.
9. عكسُ المصروف ← يرجع كلُّ شيء، والمستهلَك بعد الهبوط يُردّ له ربحُه؛ يُرفض مع فترةٍ مغلقة.
10. عكسُ الاستلام مع مصروفٍ مربوط ← يُعكس المصروفُ معه، ويعود `unit_cost` والنقد.
11. تكلفةُ وصولٍ على بند الصندوق عند الاستلام ← في `unit_cost`.
12. «مصاريف الفترة» و«مصاريف الصندوق» تعدّان الحصص لا المبلغ؛ المجموعان متساويان.
13. التقريب: المجموعُ = المصروف بقرشه في كل الحالات.

ثم اختباراتُ المستثمرين كاملةً، واختباراتُ الشاشتين، و`flutter analyze`.

**الرجوع:** `git revert` للالتزام، والهجرةُ تُعكس بـ`migrate:rollback --step=1` محلياً.

**المخاطر:**
- **مالٌ يتحرّك بين فترات.** أخطرُ ما في الخطة الخطافُ في `CreditBackStockBatches`: لو فات، حُسب
  نصيبُ الوحدات الراجعة مرتين. اختبارا ٧ و٨ له.
- القفلُ: يرفع `unit_cost` لطبقاتٍ قد تُسحب في اللحظة نفسها — يأخذ قفلَ أرصدة المخزن أولاً كما
  يفعل كل كاتبٍ هنا.
- الخادمُ في الإنتاج متأخّرٌ أصلاً (PR #24 و#25 و«مصاريف الصندوق» لم تُنشر)؛ هذه تُضاف إلى ما ينتظر.

## ٦. الأسئلة — أُجيب عنها 2026-10-12

1. المصاريف القديمة: تبقى كما هي (القرار ٧).
2. عكسُ الاستلام مع مصروفٍ مربوط: يُعكس المصروفُ معه (القرار ٨).

## ٧. ما بُني — 2026-10-12

**الخادم**

| الملف | ما فيه |
|---|---|
| `2026_10_12_100000_land_fund_expenses_on_goods.php` | `investor_deal_expenses.purchase_order_id` و`landed_through_consumption_id`؛ `stock_movements.purchased_layers_to_company`؛ جدول `fund_expense_charges` |
| `Actions/LandFundExpenseOnGoods` | الهبوط، والعكس، وردُّ الحصة حين ترجع الوحدات، والحارسُ على الفترات المغلقة |
| `Actions/PostFundExpenseCharge` | كتابةُ صفٍّ على المحافظ ونقد الصندوق وعكسُه — موجبٌ: خسارةٌ + `ExpenseCoveredByCompany`؛ سالبٌ: ربحٌ + `CompanyPayout` |
| `Queries/PurchaseOrderFundUnits` | بنودُ الصندوق في الأمر، وطبقاتُها ونسخُها، ومستهلكوها |
| `Queries/GoodsExpenseCharges` | ما وقع من كل مصروفٍ في كل فترة — يقرؤه الإقفال والشاشتان |
| `Queries/FundPurchaseOrdersQuery` + `GET investment/purchase-orders` | قائمةُ الحقل في ورقة المصروف |
| `Inventory/Events/StockCreditedBack` + `Listeners/ReturnExpenseChargesWhenStockComesBack` | الخطاف (§٤.٥) — حدثٌ لا نداء، فالمخزونُ لا يعتمد على الاستثمار |
| `GET investment/expense-charges/{charge}/logs` | سجلُّ كل صفّ — قاعدةُ كل نموذج |

تعديلات: `RecordFundExpense` (يقفل الرفوف ثم الصندوق، ويهبط بدل التغطية)، `RecordDealExpense`
(لا تحميلَ بالتاريخ للمربوط)، `ReverseDealExpense` (الحارسُ والعكسُ للمربوط)، `ReceivePurchaseOrder`
(تكلفةُ الوصول على بند الصندوق تسمّي الأمر)، `ReversePurchaseOrderReceipt` (يعكس المربوطَ قبل السحب)،
`PeriodForEntry` (فترةُ الصفّ = فترةُ طلبيته)، `CloseInvestmentPeriod::expensesOf`، `PeriodExpensesQuery`،
`FundExpensesQuery`، `FundProfitOwed`، `FundCashLedger`، `InvestorDealExpenseResource` (`purchase_order`
و`split`)، و`CoverCompanyExpenseSharesCommand` يتخطّى المربوط.

**تطبيق الموظفين:** حقلُ «أمر الشراء» في «مصروف على الصندوق» (اختياري، `placeholder` «لا يخصّ أمر
شراء»)، وسطرٌ في بطاقة «مصاريف الصندوق»: «أمر الشراء 12 · على البضاعة 400 · على المبيعات 600».

**الاختبارات:** `tests/Feature/Investors/FundExpenseOnGoodsTest.php` — 19 حالة؛ في التطبيق: ورقةُ المصروف
(حالتان) وبطاقةُ القائمة (حالة).

**الشكلُ الذي ظهر في التنفيذ ولم يكن في الخطة:** حصةُ ما بِيع بعد الهبوط تُردّ عند العكس **ربحاً** —
ونصيبُ الشركة منها يخرج إليها `CompanyPayout`، لأن ربحَ تلك الطلبية الذي ستقبضه الشركةُ نقص بالفرق
نفسه. بدونه كان الفرقُ يبقى نقداً في الصندوق فيرفع سعرَ الوحدة بمالٍ ليس للشركاء.

