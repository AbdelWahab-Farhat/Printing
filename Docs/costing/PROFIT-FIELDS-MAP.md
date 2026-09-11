# خريطة حقول الربح — من أين يأتي كل رقم

> **مرجع، لا مقترح.** يصف ما هو مبنيٌّ اليوم في `backend/`. كُتب 2026-09-11.
> رفيقه: [INVESTOR-PROFIT-FIELDS.md](../investor-deals/INVESTOR-PROFIT-FIELDS.md) — ربح المستثمر
> وقيوده. والتفصيل التاريخي في [PROFIT-AND-LOSS-COST-TRACKING.md](PROFIT-AND-LOSS-COST-TRACKING.md)
> و[PLAIN-TRANSFER-PRICE-DESIGN.md](PLAIN-TRANSFER-PRICE-DESIGN.md).

الترتيب هنا هو ترتيب حياة الطلبية: **ما يدفعه الزبون** ← **ما كلّفتنا** ← **الربح** ← **التقرير**،
ثم الحقول التي تشبه الربح وليست منه.

---

## ٠. القاعدتان اللتان تفسّران كل ما بعدهما

1. **لكل حقل محسوب كاتبٌ واحد.** الرصيد لا يُخزَّن إلا ومعه كلاس واحد يكتبه، وبقية الكود يقرأ.
   فلا يوجد رقمان لسؤال واحد. (`orders.grand_total` مثلاً لا يكتبه إلا `RecalculateOrderTotals`.)
2. **الربح نفسه غير مخزَّن.** لا عمود اسمه `profit` في `orders`. الربح دالّة على عمودين مخزَّنين:
   `grand_total − total_cogs`، تُحسب وقت القراءة.

```
                 order_items.line_total ─┐
                                          ├─► orders.items_total ─┐
        design_fee (إن كان in_house) ─────┤                       ├─► grand_total
        additional_cost ──────────────────┤                       │
        discount  (−) ────────────────────┘                       │
                                                                  │
  stock_batch_consumptions.total_cost ─► material_cost(_actual) ─┐ │
  manufacturing_cost_rates ─► production_cost_entries ─► labor/overhead ─┤
  order_items.unit_cost (وسيط) ─────────────► outsourcing_cost ─┤        │
                                                       └─► cogs ─► total_cogs
                                                                  │       │
                                                                  ▼       ▼
                                                        grand_total − total_cogs = مجمل الربح
```

---

## ١. الإيراد — ما يدفعه الزبون

| الحقل | ما هو | من يكتبه | متى |
|---|---|---|---|
| `order_items.quantity` | ما طلبه الزبون. **لا يتغيّر أبداً** | `AddOrderItem` · `SyncOrderItems` | عند الطلب/التعديل |
| `order_items.shortage_quantity` | ما نقص عند التجهيز | `SetOrderShortages` | عند «نواقص» |
| `billableQuantity()` | `quantity − shortage` (بحدٍّ أدنى صفر) — **المحاسَب عليه** | دالّة، غير مخزَّنة | — |
| `order_items.unit_price` | سعر الوحدة المتفق عليه | `AddOrderItem` (من الكتالوج أو يدوي) | عند الطلب |
| `order_items.line_total` | `unit_price × billableQuantity` | `AddOrderItem` · `SetOrderShortages` عبر `deriveLineTotal()` | كلما تغيّر أحدهما |
| `orders.items_total` | Σ `line_total` | [`RecalculateOrderTotals`](../../backend/app/Domain/Order/Actions/RecalculateOrderTotals.php) | بعد أي تغيّر |
| `orders.design_fee` | أجر التصميم | `UpdateOrder` | عند الاتفاق |
| `orders.design_source` | من صمّم | `UpdateOrder` | — |
| `orders.additional_cost` + `_reason` | خدمة إضافية (لون زائد، تغليف…) | `UpdateOrder` | — |
| `orders.discount` | الخصم | `UpdateOrder` | — |
| `orders.grand_total` | **ما يدفعه الزبون** | `RecalculateOrderTotals` | مع كل ما سبق |

```
الأساس     = items_total + design_fee(إن كان design_source = in_house) + additional_cost
grand_total = الأساس − discount            ← ويُرفض خصمٌ أكبر من الأساس، ولا يُقصّ تلقائياً
```

**ثلاث دقائق تُخطئ كثيراً:**

- **`design_fee` يبقى مكتوباً ولا يُحتسب** إن كان التصميم من الزبون. لم يُمحَ حتى لا يضيع رقمٌ كتبه
  موظّف لو أعاد المفتاح.
- **`additional_cost` داخل أساس الخصم عمداً** — سقف الخصم هو ما كان الزبون سيدفعه فعلاً.
- **`delivery_price` ليس في `grand_total` إطلاقاً** (قرار 2026-09-08: «سعر التوصيل ليس من تكاليفي
  ولا من أرباحي، هو فقط على الزبون»). يبقى على الشاشة للتسعير فقط.

---

## ٢. التكلفة — ما كلّفتنا الطلبية

### أ. من الرفّ: تكلفة المادة

| الحقل | ما هو | من يكتبه | متى |
|---|---|---|---|
| `stock_batches.unit_cost` | تكلفة الكيلو/القطعة في هذه الطبقة. **لا تتغيّر** | `ApplyStockChange::increase()` عند الوصول | وصول البضاعة |
| `stock_batches.received_at` | **مفتاح ترتيب FIFO** (لا `created_at`) | كما فوق | — |
| `stock_batch_consumptions.quantity/unit_cost/total_cost` | ما سُحب من كل طبقة ولحظتها تكلفته — **لقطة لا تتغيّر** | `ConsumeStockBatchesFifo` | كل خروج بضاعة |
| `order_items.warehouse_quantity` | ما وُزن فعلاً من الرفّ (حين تختلف وحدة البيع عن وحدة المخزن) | `SetOrderStockQuantities` · نموذج «جاهزة للطباعة» | قبل الخصم |
| `producedQuantity()` | `warehouse_quantity ?? quantity` — الكمية التي تُحسب عليها المادة **والعمالة** | دالّة | — |
| `order_items.material_cost` | **ما دفعه البند** للمادة | [`DeductOrderStock`](../../backend/app/Domain/Order/Actions/DeductOrderStock.php) | «جاهزة للطباعة» |
| `order_items.material_cost_actual` | **ما كلّفت البضاعة الشركة** | نفسه | نفسه |
| `order_items.stock_purchased_at` | البند اشترى سادته من صفقة مستثمر بسعر متفق | نفسه | نفسه |
| `order_items.fulfillment_stock_movement_id` | الحركة التي سحبت هذا البند — مؤشّر الإلغاء والتصحيح | نفسه | نفسه |

**لماذا رقمان للمادة؟** بسبب سعر السادة. كلاهما من [`MaterialCost`](../../backend/app/Domain/Order/Support/MaterialCost.php)، المكان الوحيد الذي يُشتقّان فيه:

```
لكل سحبة:  مسعَّرة؟   charged += سعر السادة × الكمية        actual += total_cost
           غير مسعّرة؟ charged += total_cost                 actual += total_cost
```

والسحبة «مسعَّرة» بشرطين معاً: الطبقة تحمل `printing_sale_price`، **و** البند مطبوع
(`OrderItem::isPrinted()` — من `production_mode` لتصنيف المنتج). فبندُ سادة يُباع كما هو لا يُسعَّر
ولو كانت بضاعته ممولة.

> **يُعاد الحساب عند «جاهزة»**: [`RestateOrderStockDeduction`](../../backend/app/Domain/Order/Actions/RestateOrderStockDeduction.php)
> — لو صحّح المكبس الوزن، تُعكس الحركة كاملة وتُسحب من جديد على نفس الطبقات، فتُكتب الأرقام كما لو
> كانت صحيحة من أول يوم.

### ب. من جدول الأجور: العمالة والماكينة والمصاريف

| الحقل | ما هو | من يكتبه | متى |
|---|---|---|---|
| `manufacturing_cost_rates.rate_per_unit` | السعر المعياري للوحدة، بثلاث طبقات: **مقاس** ← **منتج** ← **افتراضي** | إدارياً (CRUD) | قبل الطلبيات |
| `production_cost_entries` | دفتر التكاليف: صفّ لكل (بند × نوع تكلفة) مع لقطة السعر | [`ApplyManufacturingRates`](../../backend/app/Domain/Order/Actions/ApplyManufacturingRates.php) · `RecordScrapLoss` | «جاهزة» |
| `order_items.labor_cost` | مجموع صفوف العمالة | `RecalculateOrderItemManufacturingCost` | نفسه |
| `order_items.overhead_cost` | المصاريف **ووقت الماكينة** معاً (لا عمود ثالث) | نفسه | نفسه |

**نوعٌ بلا سعر يُتخطّى ولا يُفترض صفراً** — غياب السعر ثغرةُ إعداد، لا حقيقة أن البند لم يكلّف شيئاً.
(وهذا حال النظام اليوم: الجدول فارغ، فكل الطلبيات بلا عمالة.)

### ج. الوسيط

| الحقل | ما هو | من يكتبه | متى |
|---|---|---|---|
| `order_items.unit_cost` | سعر المورّد للوحدة، **مُلتقَط يوم الطلب** لا من الكتالوج اليوم | `AddOrderItem` | عند الطلب |
| `order_items.outsourcing_cost` | `unit_cost × billableQuantity` | [`ApplyOutsourcingCosts`](../../backend/app/Domain/Order/Actions/ApplyOutsourcingCosts.php) | «جاهزة» |

### د. الجمع

| الحقل | المعادلة | من يكتبه |
|---|---|---|
| `order_items.cogs` | `material + labor + overhead + outsourcing` | [`RecalculateOrderItemCost`](../../backend/app/Domain/Order/Actions/RecalculateOrderItemCost.php) |
| `orders.total_cogs` | Σ `cogs` للبنود | [`RecalculateOrderCogs`](../../backend/app/Domain/Order/Actions/RecalculateOrderCogs.php) |

**`null` تعني «لم تُحتسب بعد» ولا تعني صفراً.** البند بلا `material_cost` ولا `outsourcing_cost`
تبقى `cogs` فارغة، والطلبية كذلك — ولهذا تقول الشاشة «لم تُحتسب التكلفة بعد — تُحتسب عند وصول
الطلبية إلى «جاهزة»» بدل أن ترسم صفراً يعني «لم تكلّفنا شيئاً».

---

## ٣. الربح

```
Order::grossProfit() = grand_total − total_cogs        ← محسوبة عند القراءة، غير مخزّنة
```

| يدخل فيه | لا يدخل فيه |
|---|---|
| بيع المنتجات (`items_total`) | التوصيل (`delivery_price`) — على الزبون |
| أجر التصميم إن كان عندنا | ما لم يُحصَّل بعد (الربح استحقاقي لا نقدي) |
| الخدمة الإضافية ناقص الخصم | مصاريف الشركة العامة (لا يوجد جانب مصروفات في هذا النموذج) |
| تكلفة المادة والعمالة والمصاريف والوسيط | نصيب المستثمر — يُقتطع بعده، لا منه |

---

## ٤. تقرير الأرباح والخسائر — يختلف عمداً عن شاشة الطلبية

[`ProfitAndLossSummaryQuery`](../../backend/app/Domain/Reporting/Queries/ProfitAndLossSummaryQuery.php)،
على الطلبيات `delivered` أو `settled` داخل المدى (بتاريخ التسليم/التسوية):

```
revenue.product   = Σ items_total
revenue.service   = Σ design_fee  حيث design_source = in_house
cogs              = Σ total_cogs  −  هامش التحويل
هامش التحويل      = Σ (material_cost − material_cost_actual)      ← داخلي، لم يخرج من الشركة
gross_profit      = revenue − cogs
```

| لماذا يختلف عن «مجمل الربح» على الطلبية | |
|---|---|
| لا يعدّ `additional_cost` ولا يطرح `discount` | ليسا منتجاً ولا خدمة يعترف بها هذا الكشف |
| يحسب المادة بـ`material_cost_actual` | ربح الشركة ككل يُحسب بما كلّفت البضاعة فعلاً، لا بما دفعته المطبعة لصفقةٍ داخلها |
| `cash_collected` و`written_off` بجانبه ولا يُطرحان | أحدهما نقد والآخر استحقاق؛ خلطهما يُفسد الاثنين |

---

## ٥. حقولٌ تشبه الربح وليست منه — هذه **نقد**

| الحقل | ما هو | من يكتبه |
|---|---|---|
| `order_payments` | دفتر الدفعات: دفعة · استرجاع · إعفاء · تحصيل مندوب | `RecordOrderPayment` · `RefundOrderPayment` · `WriteOffOrderBalance` · `RecordCarrierSettlement` |
| `orders.paid_amount` | مجموع النقد المستلم | [`RecalculateOrderPayments`](../../backend/app/Domain/Order/Actions/RecalculateOrderPayments.php) |
| `orders.written_off_amount` | ما قرّرنا ألّا نُحصّله | نفسه |
| `orders.carrier_settled_amount` | ما سلّمه المندوب | نفسه |
| `orders.collected_amount` | ما قال المندوب إنه قبضه من الزبون | `ChangeOrderStatus` · `RecordNawrisWebhook` |

**لا واحد منها يدخل الربح.** طلبية مربحة غير محصَّلة ربحُها مكتوب، ونقدُها صفر — وهذا فرقٌ مقصود.

---

## ٦. متى يُكتب كل رقم — بترتيب حالات الطلبية

| الحالة | ما يُكتب |
|---|---|
| **جديدة** | `line_total` · `items_total` · `grand_total` · `unit_cost` للوسيط |
| **جاهزة للطباعة** (خروج البضاعة) | `stock_batch_consumptions` · `material_cost` · `material_cost_actual` · `stock_purchased_at` · `fulfillment_stock_movement_id` · `cogs` للبند · **ودفعُ المستثمر على طريق سعر السادة** |
| **قيد الطباعة** | لا شيء مالي |
| **جاهزة** | تصحيح الوزن (إن وقع) · `production_cost_entries` · `labor_cost` · `overhead_cost` · `outsourcing_cost` · `cogs` · **`orders.total_cogs`** ← هنا يظهر «مجمل الربح» |
| **نواقص** | `shortage_quantity` ← يعيد اشتقاق `line_total` و`grand_total` |
| **استلام مكتب / جاري التوصيل** | نقد فقط |
| **تم الاستلام** | **ربح الصفقة للمستثمر على طريق السادة** · دخول الطلبية في تقرير الأرباح |
| **تم التسوية** | تسوية نقد المندوب |
| **ملغاة** | ترجع البضاعة للرفّ (وللشركة لا للمستثمر إن كانت مُشتراة بسعر السادة) |

---

## ٧. أخطاء قراءة شائعة

1. **«الربح 724»** على طلبية مطبوعة قبل فصل سعر السادة — كان يخلط ربح البضاعة بربح الطباعة. بعد
   الفصل: ربح المطبعة = `grand_total − material_cost(بسعر السادة) − أجور`، وربح البضاعة يخصّ الصفقة.
2. **«مجمل الربح» بلا عمالة**: ما دام `manufacturing_cost_rates` فارغاً فالرقم إيرادٌ ناقص بضاعة، لا أكثر.
3. **`material_cost` ≠ تكلفة الشركة** على بندٍ مطبوع من صفقة — تلك `material_cost_actual`.
4. **`grand_total` ≠ ما سيُقبض**: التوصيل خارجه، والخصم داخله، والمقبوض في `paid_amount`.
5. **مقارنة شاشة الطلبية بتقرير الأرباح** — لن يتطابقا أبداً، و[§٤](#٤-تقرير-الأرباح-والخسائر--يختلف-عمداً-عن-شاشة-الطلبية) يقول لماذا.
