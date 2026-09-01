# تكلفة الوحدة عند إدخال كمية إلى المخزون

> **الحالة: منفَّذ — `flutter analyze` نظيف و`flutter test` أخضر** (عدا عطل قائم لا صلة له،
> §٨). الـ API كان يقبل `unit_cost` منذ أن نزل نظام طبقات التكلفة، والتطبيق هو الذي لم يكن
> يرسله. يبقى هذا المستند مرجعاً لما حدث ولماذا.
>
> نطاق هذا المستند: **إدخال التكلفة وقت إدخال الكمية فقط** (التوريد وتسوية الزيادة).
> تصحيح تكلفة دفعة موجودة، وقائمة «بضاعة بلا تكلفة»، وشاشة الدفعات — كلها في
> [STOCK-COST-FROM-INVENTORY-FRONTEND-INTEGRATION.md](STOCK-COST-FROM-INVENTORY-FRONTEND-INTEGRATION.md)
> ولا شيء منها مطلوب لإغلاق هذه المهمة.

---

## ١. المشكلة، بشقّيها

### أ) عطل حيّ يراه أمين المخزن اليوم

`POST /stock-movements/adjustments` مع `direction=increase` **يفشل في كل مرة**.

الخادم يشترط `unit_cost`:

```php
// backend/app/Application/Api/V1/Requests/Inventory/RecordAdjustmentRequest.php
'unit_cost' => ['required_if:direction,increase', 'numeric', 'gte:0', 'max:999999999.999'],
'unit_cost.required_if' => 'تكلفة الوحدة مطلوبة عند تسجيل زيادة',
```

والتطبيق يرسل أربعة حقول فقط:

```dart
// frontend/lib/features/warehouses/repositories/warehouse_repository_impl.dart:174-190
'stock_item_id': stockItemId,
'warehouse_id': warehouseId,
'quantity': quantity,
'direction': isIncrease ? 'increase' : 'decrease',
if (notes != null && notes.isNotEmpty) 'notes': notes,
```

النتيجة: ٤٢٢ برسالة «تكلفة الوحدة مطلوبة عند تسجيل زيادة» — عن حقل **لم تعرضه الاستمارة أصلاً**.
فأمين المخزن يقرأ رفضاً لا يستطيع تنفيذه. **هذا إصلاح عطل، لا ميزة جديدة.**

### ب) العطل الصامت — وهو الأخطر

`POST /stock-movements/arrivals` يقبل `unit_cost` **اختيارياً**، والتطبيق لا يرسله. فكل توريد
يُسجَّل من التطبيق **يفتح طبقة تكلفة بقيمة `0.000`**، ولا أحد يرى شيئاً. المشكلة تظهر بعد أسابيع
في مكان آخر تماماً: في ربح الطلبات.

---

## ٢. ماذا يحدث بالضبط — الرحلة الكاملة للرقم

```
استمارة تسجيل الحركة
        │  unit_cost
        ▼
POST /stock-movements/arrivals   (أو adjustments + direction=increase)
        ▼
RecordStockMovement  ──(معاملة واحدة + قفل صف واحد)──▶  ApplyStockChange
                                                            ├─ warehouse_stocks.quantity   (الرصيد)
                                                            └─ stock_batches               (طبقة التكلفة)
                                                                  │  unit_cost يُختم هنا، مرة واحدة
                                                                  ▼
                                        ConsumeStockBatchesFifo ─── الأقدم received_at أولاً
                                                                  ▼
                                                     stock_batch_consumptions.total_cost
                                                                  ▼
                                        DeductOrderStock ─▶ order_items.material_cost  (مُجمَّد)
                                                                  ▼
                                                   orders.total_cogs ─▶ الربح الإجمالي ─▶ P&L
```

### النقطتان اللتان تفسّران كل شيء

**١. التكلفة تُختم لحظة فتح الطبقة، ولا باب للخروج.** لا شيء في النظام يعدّل
`stock_batches.unit_cost` بعد إنشائها إلا مسار إعادة التقييم الجديد
(`PATCH /stock-batches/{id}/cost`) الذي يحتاج صلاحية `inventory.revalue` وسبباً مكتوباً وشاشة
لم تُبنَ بعد. عملياً: **الرقم الذي لا تكتبه اليوم لن يُكتب لاحقاً.**

**٢. الصفر يُستهلك أولاً.** ترتيب FIFO هو `received_at, id`. طبقة بتكلفة صفر ليست طبقة نائمة —
هي أول ما يسحب منه الطلب القادم. فكل توريد سُجِّل بلا تكلفة يتحوّل إلى طلب بـ
`material_cost = 0`.

### الفرق بين الحالتين، بالأرقام

| ماذا أرسل التطبيق | طبقة التكلفة | أول طلب يسحب ٢٠٠ منها | الربح المُعلن |
|---|---|---|---|
| `unit_cost` غائب | `0.000` | `material_cost = 0` | **مُبالَغ فيه بكامل قيمة المادة** |
| `unit_cost = "3.500"` | `3.500` | `material_cost = 700` | صحيح |

وهذا ليس افتراضياً: ترحيل الأرصدة الافتتاحية
([`2026_08_12_100200_backfill_opening_balance_stock_batches.php`](backend/database/migrations/2026_08_12_100200_backfill_opening_balance_stock_batches.php))
أنشأ طبقة `unit_cost = 0` لكل رفّ بتاريخ `1970-01-01` **عمداً**، لتُستهلك قبل أي طبقة مُسعَّرة.
كل حركة إدخال بلا تكلفة تضيف طبقة جديدة إلى نفس الطابور.

### ماذا **لا** يحدث

- **لا شيء بأثر رجعي.** `order_items.material_cost` يُجمَّد عند أول دخول للطلب في «جاهزة
  للطباعة» أو «جاهزة»، ولا يُعاد حسابه. الطلبات القديمة تبقى كما هي.
- **الرصيد لا يتأثر.** `warehouse_stocks.quantity` لا علاقة له بالتكلفة إطلاقاً — إرسال التكلفة
  أو إغفالها لا يغيّر عدد القطع على الرفّ بمقدار واحد.
- **النقل الداخلي والنقص لا يفتحان طبقة.** النقل ينقل الطبقات كما هي بأسعارها، والنقص يستهلك
  طبقات قائمة. لا مكان لتكلفة في أيٍّ منهما — وهذا سبب القاعدة في §٤.

### تحذير للإدارة قبل التنفيذ

بعد هذا الإصلاح **سينخفض الربح الإجمالي المُعلن على الطلبات الجديدة، وبشكل ملحوظ**. هذا
**تصحيح لا انحدار**: أرقام اليوم خاطئة في الاتجاه المُطمئن. لكن من يقرأ تقرير الأرباح يجب أن
يُخبَر قبل أن يلاحظ بنفسه.

---

## ٣. أين تجد كل شيء

### الملفات التي ستعدّلها (أربعة)

| # | الملف | ماذا فيه الآن |
|---|---|---|
| ١ | [warehouse_repository.dart:206-233](frontend/lib/features/warehouses/repositories/warehouse_repository.dart#L206-L233) | تواقيع `recordArrival` و`recordAdjustment` — بلا `unitCost` |
| ٢ | [warehouse_repository_impl.dart:142-190](frontend/lib/features/warehouses/repositories/warehouse_repository_impl.dart#L142-L190) | بناء الـ body — وفيه أيضاً عطل `notes` (§٥-ب) |
| ٣ | [record_stock_movement.dart:47-86](frontend/lib/features/warehouses/usecases/record_stock_movement.dart#L47-L86) | `MovementKind` + التطبيع + توزيع الحركة على المستودع |
| ٤ | [record_movement_sheet.dart:231-248](frontend/lib/features/warehouses/presentation/widgets/record_movement_sheet.dart#L231-L248) | حقل الكمية — التكلفة تأتي بعده مباشرة |

بالإضافة إلى:

| # | الملف | ماذا يُضاف |
|---|---|---|
| ٥ | [record_movement_state.dart:21-44](frontend/lib/features/warehouses/presentation/viewmodel/record_movement_state.dart#L21-L44) | `unitCostError` + إضافته إلى `hasFieldErrors` |
| ٦ | [record_movement_cubit.dart:23-47](frontend/lib/features/warehouses/presentation/viewmodel/record_movement_cubit.dart#L23-L47) | تمرير `unitCost` عبر `submit` |
| ٧ | [record_stock_movement_test.dart](frontend/test/features/warehouses/record_stock_movement_test.dart) | الاختبارات — **تُكتب أولاً** |

### ما لا تحتاج لمسّه

- **الـ DI** ([injector.dart:1070](frontend/lib/core/di/injector.dart#L1070)) — لا تبعيّة جديدة.
- **الـ endpoints** ([api_endpoints.dart:143-149](frontend/lib/core/network/api_endpoints.dart#L143-L149)) — لا مسار جديد.
- **موديل `StockMovement`** — الرد لا يتغيّر شكله.
- **الخادم كله.** لا هجرة، لا صلاحية، لا مسار. الـ API جاهز ومختبَر.

### أين يفتح المستخدم هذه الاستمارة

من زرّ «تسجيل حركة» العائم في شاشة الأرصدة:
[warehouse_stocks_page.dart:124](frontend/lib/features/warehouses/presentation/views/warehouse_stocks_page.dart#L124).
هي المدخل الوحيد في التطبيق — `showRecordMovementSheet` لا يُستدعى من مكان آخر.

---

## ٤. القاعدة التي تحكم التنفيذ كله

**نوعان فقط من الحركات يفتحان طبقة تكلفة، فهما وحدهما من يحمل سعراً.**

| النوع | يفتح طبقة؟ | التكلفة |
|---|---|---|
| `arrival` — توريد | نعم | **اختيارية** — فارغة ⇒ الطبقة تُفتح بـ `0.000` |
| `increase` — تسوية بالزيادة | نعم | **مطلوبة** — الخادم يرفض بدونها |
| `transfer` — نقل داخلي | لا، ينقل طبقات قائمة | تُحذف |
| `decrease` — تسوية بالنقص | لا، يستهلك طبقات | تُحذف |

**هذه القاعدة تعيش في `MovementKind`، لا في الودجت.** لو كان إخفاء الحقل هو ما يمنع إرسال
السعر، لتسرّب رقمٌ كُتب ثم تراجع عنه المستخدم بتبديل الشريحة إلى «تحويل». الإخفاء تجميل؛ الحذف
قاعدة.

```dart
// في record_stock_movement.dart، داخل enum MovementKind
bool get opensCostLayer => this == MovementKind.arrival || this == MovementKind.increase;
bool get requiresCost   => this == MovementKind.increase;
```

**القاعدة الثانية: الحقل الفارغ = `null`، وليس `'0'`.**
«لا نعرف سعرها» و«سعرها صفر» ادّعاءان مختلفان. الأول يترك الطبقة قابلة للاكتشاف في طابور
«بضاعة بلا تكلفة» ليُصحّحها إنسان لاحقاً؛ الثاني يقول إن إنساناً قرّر أنها بلا قيمة، فتختفي من
الطابور نهائياً. **لا ترسل مفتاح `unit_cost` أصلاً عندما يكون الحقل فارغاً.**

**القاعدة الثالثة: التطبيع في نفس مكان تطبيع الكمية.** لوحة المفاتيح العربية تُخرج `٣٫٥`
و`3,5`، وكلاهما يجب أن يصل الـ API كـ `3.5`. هذا يحدث في `RecordStockMovement`، سطر واحد بجوار
سطر الكمية القائم:

```dart
// record_stock_movement.dart:63 — الموجود اليوم
final amount = Validators.toWesternDigits(quantity.trim()).replaceAll(',', '.');
```

---

## ٥. التنفيذ، ملفاً ملفاً

> اكتب الاختبارات أولاً (§٦). هذه الفقرة هي ما يجعلها تنجح.

### أ) `WarehouseRepository` — العقد

أضف `String? unitCost` إلى `recordArrival` و`recordAdjustment` **فقط**. `recordTransfer` لا
يأخذها — والمترجم هو ما يمنع أحداً من تمريرها هناك لاحقاً.

### ب) `warehouse_repository_impl` — السلك

```dart
'unit_cost': ?unitCost,
```

الصيغة `?unitCost` (وهي المستخدمة أصلاً في `movements()` بهذا الملف، سطر ١٣٢) **تُسقط المفتاح**
عندما تكون القيمة `null` بدل إرساله فارغاً — وهو بالضبط ما تطلبه القاعدة الثانية.

**وأصلح `notes` وأنت هنا.** الخادم يشترط `notes` على **اتجاهَي** التسوية (`required`, `min:3`)،
والمستودع يرسلها فقط إن لم تكن فارغة:

```dart
if (notes != null && notes.isNotEmpty) 'notes': notes,   // ← هذا ما يُسقطها
```

الاستمارة تتحقق منها بالفعل، فالعطل لا يظهر إلا إذا تجاوزت رسالةٌ ما التحقق المحلي — لكنه سطر
يُسقط حقلاً مطلوباً، ويُصلَح بنفس الصيغة: `'notes': ?notes` مع تمرير `null` بدل السلسلة الفارغة
من الاستمارة.

### ج) `RecordStockMovement` — القاعدة

- بارامتر واحد جديد: `String? unitCost`.
- التطبيع كتطبيع الكمية، **بعد** التأكد أن الحقل غير فارغ.
- التوزيع على المستودع يمرّرها في حالتَي `arrival` و`increase` فقط. الحالتان الأخريان لا تعرفان
  بوجودها.

```dart
final cost = (unitCost == null || unitCost.trim().isEmpty)
    ? null
    : Validators.toWesternDigits(unitCost.trim()).replaceAll(',', '.');
```

لاحظ أن `MovementKind.increase` و`MovementKind.decrease` يشتركان اليوم في فرع `switch` واحد
يستدعي `recordAdjustment`. مرّر `cost` في ذلك الفرع كما هو: عندما يكون النوع `decrease` تكون
`cost` قد حُذفت أصلاً — إما بمعرفة `opensCostLayer` قبل الاستدعاء، أو لأن الاستمارة لم تُظهر
الحقل ولم تُرسل شيئاً. **الأنظف: احذفها صراحة قبل الـ `switch`** بدل الاعتماد على الاستمارة:

```dart
final layerCost = kind.opensCostLayer ? cost : null;
```

### د) `record_movement_sheet` — الحقل

بعد حقل الكمية مباشرة، ومحكوم بـ `_kind.opensCostLayer`:

- **التسمية: «تكلفة الوحدة (لكل كغم)»**، بنفس منطق حقل الكمية فوقه الذي يقول
  «الكمية (كيلوغرام)» — الوحدة موجودة في `_unitLabel` (سطر ٧١). «التكلفة» وحدها تُقرأ على أنها
  ثمن الشحنة كاملة في استمارة كان سؤالها السابق كمية.
- **التحقق:** `Validators.decimal(min: 0)` عندما `requiresCost`، وملفوفاً بـ
  `Validators.optional(...)` عندما لا يكون كذلك.
- `keyboardType: numberWithOptions(decimal: true)` و`textDirection: TextDirection.ltr` — كحقل
  الكمية بالضبط.
- `errorText: state.unitCostError`، و`onChanged` يستدعي `clearFailure()`.
- **امسح المتحكّم عند تبديل الشريحة إلى نوع لا يفتح طبقة**، بنفس منطق `_source = null` الموجود
  في `onChanged` للشرائح (سطر ١٩٦): رقمٌ مخفيّ ثم عاد للظهور بعد جولتين من التبديل يفاجئ من
  كتبه.

### هـ) `RecordMovementState` — رسالة الخادم

```dart
String? get unitCostError => _fieldError('unit_cost');
```

وأضفه إلى `hasFieldErrors`. بدون هذه الإضافة تُبتلع رسالة «تكلفة الوحدة مطلوبة عند تسجيل زيادة»
خلف سناك‑بار عام، وهي الرسالة الوحيدة التي تشرح العطل الحيّ.

### و) `RecordMovementCubit` — التمرير

بارامتر `String? unitCost` في `submit`، يُمرَّر كما هو. لا منطق هنا.

---

## ٦. الاختبارات — تُكتب قبل الكود

الملف قائم: [record_stock_movement_test.dart](frontend/test/features/warehouses/record_stock_movement_test.dart)،
بـ ٢٨٤ سطراً على نمط Arrange‑Act‑Assert. أضف إليه، بنفس النمط:

| الحالة | التأكيد |
|---|---|
| توريد بتكلفة | `recordArrival` يُستدعى بـ `unitCost: '3.5'` |
| زيادة بتكلفة | `recordAdjustment` يُستدعى بـ `unitCost: '3.5'` و`isIncrease: true` |
| **نقل** بتكلفة مكتوبة | `recordTransfer` لا يملك البارامتر أصلاً — والمترجم هو الاختبار |
| **نقص** بتكلفة مكتوبة | `recordAdjustment` يُستدعى بـ `unitCost: null` |
| حقل فارغ / مسافات | `unitCost: null` — **وليس `'0'`** |
| `٣٫٥` و`3,5` | كلاهما يصل كـ `'3.5'` |

وفي طبقة السلك (اختبار على `warehouse_repository_impl` أو mock للـ Dio): **مفتاح `unit_cost`
غائب تماماً** من الـ body عندما تكون القيمة `null` — لا موجود بقيمة `null`.

**تنبيه على الموك القائم:** كل `when(...)` في `setUp` يعدّد البارامترات المسمّاة صراحة
(`quantity: any(named: 'quantity')` …). إضافة بارامتر جديد إلى العقد تجعل الموك لا يطابق
الاستدعاء، فتفشل اختبارات كانت خضراء برسالة غامضة. حدّث الثلاثة في `setUp` مع العقد.

### التحقق النهائي

```bash
cd frontend
flutter analyze
flutter test test/features/warehouses/
```

**لا تشغّل `dart format`** — نسخة الـ SDK المثبّتة تعيد تنسيق ١٣٥ ملفاً لم تلمسها.

---

## ٧. اقتراح «آخر سعر معروف» — لاحقاً، وبشرط

الخادم يرسل على `GET /stock-items/{id}` **فقط**:

```jsonc
"last_known_unit_cost": {
  "unit_cost": "3.500",
  "received_at": "2026-08-12T09:00:00+00:00",
  "source_type_label": "توريد"
}
```

مصدره [StockItemResource.php:59](backend/app/Application/Api/V1/Resources/StockItemResource.php#L59)،
وهو `whenLoaded('latestCostedBatch')` — أي **غائب عن قائمة الأصناف**. والمنتقي في الاستمارة
(`showStockItemPicker`) يقرأ من القائمة، فالشريحة تحتاج نداءً إضافياً بـ `GetStockItem(id)` بعد
اختيار المادة. لهذا هي مرحلة تالية، لا جزء من هذا الإصلاح.

عندما تُبنى، **الشكل غير قابل للتفاوض**:

```
آخر سعر معروف: ٣٫٥٠٠ د.ل / كغم — توريد ١٢ أغسطس        [ استخدامه ]
```

- **الصندوق يبدأ فارغاً.** الصندوق المملوء يُقبَل بعادة الإصبع، فتدخل الدفاتر تكلفةٌ لم يقرّرها
  أحد. اللمسة هي الإقرار.
- **التاريخ والمصدر يُعرضان، لا الرقم وحده.** «آخر سعر: ٣٫٥٠٠» تدعو للقبول؛ «٣٫٥٠٠ — توريد ١٢
  أغسطس» تدعو للحكم، وهو ما يقف الرجل عند الرفّ ليفعله.

---

## ٨. قائمة التحقق

- [x] اختبارات `record_stock_movement_test.dart` — كُتبت أولاً وفشلت، ثم خضراء (٧ حالات جديدة)
- [x] `WarehouseRepository` — `unitCost` على `recordArrival` و`recordAdjustment` دون سواهما
- [x] `_impl` — `'unit_cost': ?unitCost`، وإصلاح إسقاط `notes` على الحركات الثلاث
- [x] `MovementKind.opensCostLayer` و`requiresCost`
- [x] `RecordStockMovement` — التطبيع، والحذف على النقل والنقص
- [x] حقل التكلفة في الاستمارة، مُسمّى بالوحدة، ويُمسح عند تبديل الشريحة
- [x] `unitCostError` في الحالة، ومضاف إلى `hasFieldErrors`
- [x] `flutter analyze` نظيف · `flutter test` أخضر
- [ ] **إبلاغ من يقرأ تقرير الأرباح**: الربح الإجمالي على الطلبات الجديدة **سينخفض** (§٢) — قرار
      إداري، خارج الكود
- [ ] عطل قائم لا صلة له: `permission_contract_test` يطلب `AppPermission.revalueStock` مقابل
      `inventory.revalue` الذي نزل مع عمل الخادم. سطر واحد، لكنه بوّابة شاشة إعادة التقييم
      (المرحلة ٣) لا هذا الإصلاح
