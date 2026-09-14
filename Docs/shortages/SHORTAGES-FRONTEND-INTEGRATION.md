# النواقص — connecting the Flutter app

> **Status: not started.** The backend is built, tested and green — see
> [SHORTAGES-DESIGN.md](SHORTAGES-DESIGN.md). **Nothing in `frontend/` has been touched, by
> instruction.**
>
> This file is the handover: what the endpoints answer, what to build against them, and the
> traps that will otherwise be discovered on a phone.
>
> **Updated 2026-09-13:** recording a supply now posts the goods onto a shelf — see §٣٫٥, which
> adds one conditional field to the sheet that matters most — and the «نواقص» form can be filled
> from the shelves (§٣٫٦).

---

## ٠. Where the app stands today

The app has no notion of shortages. No model, no use case, no repository, no route, no drawer
link, no permission constant.

**Nothing is broken at runtime by that.** Every endpoint is new, so nothing calls it and nothing
parses it. One thing *has* changed under the app's feet, and it is worth knowing before anything
else: **the order screen is unaffected.** `PATCH /orders/{order}/shortages` takes the same payload
and answers the same `OrderResource` it always did; `order_resource_contract_test.dart` stays
green. All the new behaviour hangs off an event fired after that write.

The shape to copy is `lib/features/purchase_orders/`, which is the closest existing screen — a
paginated list with a status chip row, a detail page, and two bottom sheets that write:

```
lib/features/shortages/
├── models/shortage.dart                 (+ .freezed.dart, .g.dart)
├── models/shortage_supply.dart          (+ .freezed.dart, .g.dart)
├── models/shortage_counts.dart          plain class, like PurchaseOrderCounts
├── models/shortages_filter.dart         plain class, like PurchaseOrdersFilter
├── usecases/shortage_usecases.dart
├── repositories/shortage_repository.dart | shortage_repository_impl.dart
└── presentation/
    ├── viewmodel/shortages_cubit.dart | shortage_detail_cubit.dart | save_shortage_cubit.dart
    ├── views/shortages_page.dart | shortage_detail_page.dart | shortage_form_page.dart
    └── widgets/shortage_card.dart | shortage_status_board.dart | shortage_filter_sheet.dart
                assign_shortage_sheet.dart | record_supply_sheet.dart | supplies_table.dart
```

---

## ١. The endpoints

Nine, all under `/api/v1`. The envelope is the usual one — `status`, `message`, `data`, and `meta`
on the paginated one — so `safeRequest` and `safePaginatedRequest` work unchanged.

| Method | Path | Permission |
| --- | --- | --- |
| `GET` | `shortages` | `shortages.view` |
| `GET` | `shortages/summary` | `shortages.view` |
| `POST` | `shortages` | `shortages.manage` |
| `GET` | `shortages/{id}` | `shortages.view` **+ archive rule** |
| `PUT` | `shortages/{id}` | `shortages.manage` **+ archive rule** |
| `PATCH` | `shortages/{id}/status` | `shortages.manage` **+ archive rule** |
| `PATCH` | `shortages/{id}/assignee` | `shortages.assign` **+ archive rule** |
| `POST` | `shortages/{id}/supplies` | `shortages.supplies.record` **+ archive rule** |
| `POST` | `shortages/{id}/supplies/{supplyId}/reversal` | `shortages.supplies.reverse` **+ archive rule** |

And one that lives on the **order** side but exists for this feature:

| Method | Path | Permission |
| --- | --- | --- |
| `GET` | `orders/{order}/stock-shortfall` | `orders.status.shortage` |

Plus `GET shortages/{id}/logs` behind `logs.view`, identical in shape to every other history
endpoint — reuse the existing `ActivityLog` model and screen.

**«+ archive rule»** means: if the shortage's order has been archived, the endpoint also demands
`orders.archive.view` and otherwise answers **403** with

```
هذا النقص يخصّ طلبية في الأرشيف، وعرضه يحتاج صلاحية عرض أرشيف الطلبات
```

Surface it as sent. It is a different sentence from the blanket «ليس لديك صلاحية», deliberately:
the reader holds the grant the endpoint asks for and is being refused by a fact about *this row*.

### ١٫١ The list

```
GET /api/v1/shortages?status[]=new&status[]=searching&assigned_to=me&page=1&per_page=20
```

| Query key | Accepts |
| --- | --- |
| `status` | repeatable — `new` · `searching` · `unavailable` · `completed` |
| `assigned_to` | a user id, **`me`**, or **`none`** |
| `product_id` · `order_id` · `customer_id` | ids |
| `source` | `manual` · `order` |
| `search` | the shortage's name, its code (`N7`), or the **order's** code |
| `page` · `per_page` | `per_page` is clamped 1–100, default 15 |

**`me` and `none` are words because neither is an id.** «me» is only knowable on the server from
the bearer token; «none» is a null a query string cannot otherwise carry, and «غير مُسنَد» is a
queue somebody actually works — it is what the board means by work nobody has picked up.

Sorted newest first, always. There is no sort parameter — see §٦ for why the list is not ordered
by open-work-first.

**The list already excludes shortages whose order is archived** unless the reader holds
`orders.archive.view`. There is nothing for the app to filter.

### ١٫٢ The board

```
GET /api/v1/shortages/summary        (same filters as the list; `status` is accepted and ignored)
```

```jsonc
{ "counts": { "new": 12, "searching": 7, "unavailable": 3, "completed": 25 }, "total": 47 }
```

The `{counts, total}` shape `/orders/summary` and `/purchase-orders/summary` already answer in, so
**copy `PurchaseOrderCounts` almost verbatim** — a `Map<String, int>` keyed by the wire value, and
`total` **read rather than summed**, so a status added after a build shipped is still inside the
number.

Every status is present, zeros included: a missing key would leave the caller choosing between a
blank and a zero, and the two mean different things.

**`status` is ignored on purpose.** A chip row exists to say what *else* there is; counting only
the status already selected would make every chip but one read zero. Every **other** filter is
kept, so «جديد ١٢» under a product filter means twelve of that product. Hand the whole filter over
without stripping anything.

### ١٫٣ One shortage

```jsonc
{
  "id": 41, "code": "N41",
  "source": "order", "source_label": "من طلبية",
  "name": "كيس شحن — 25*35",
  "unit": "kilogram", "unit_label": "كجم",

  "required_quantity": "30.000",
  "supplied_quantity": "20.000",
  "remaining_quantity": "10.000",
  "total_paid": "500.00",

  "status": "searching", "status_label": "جاري البحث",
  "is_final": false,
  "available_transitions": [ { "value": "unavailable", "label": "غير متوفر" } ],
  "is_editable": false,
  "is_stockable": true,

  "order_id": 1204, "order_item_id": 3310,
  "order": { "id": 1204, "code": "1204", "status": "shortage", "is_archived": false },

  "customer_id": 88,
  "customer": { "id": 88, "name": "محل النور", "phone": "0910000000" },

  "product_id": 12, "product_variant_id": 45,
  "product": { "id": 12, "name": "كيس شحن" },
  "variant": { "id": 45, "label": "25*35" },

  "assigned_to_user_id": 6,
  "assignee": { "id": 6, "name": "محمد", "employee_code": "E6" },
  "created_by_user_id": 2,
  "creator": { "id": 2, "name": "أحمد" },

  "description": null,

  "supplies": [ /* §١٫٤ — detail only */ ],

  "created_at": "2026-09-12T08:14:00+00:00",
  "updated_at": "2026-09-12T09:02:11+00:00"
}
```

**Every quantity and every money field is a `String`**, three decimals on quantities and two on
money, exactly as `Order` and `PurchaseOrder` carry theirs. They are summed, and a `double` is
where a figure stops being the one the server printed. Parse only to compare, never to display.

**`order`, `customer`, `product`, `variant`, `assignee`, `creator` and `supplies` are
`whenLoaded`**, so on the **list** they are absent from the JSON — not null, *absent*. The
matching `*_id` fields are always present. Make every nested object nullable in Freezed and read
the id when the object is missing.

`supplies` is sent **only on the detail endpoint**. A list of forty shortages has no use for four
hundred ledger rows.

### ١٫٤ One supply

```jsonc
{
  "id": 77, "shortage_id": 41,
  "kind": "purchased", "kind_label": "شراء",
  "quantity": "20.000",
  "amount": "500.00", "method": "cash", "method_label": "كاش",
  "reference": null,
  "occurred_on": "2026-09-11",
  "notes": null,

  "warehouse_id": 3,
  "warehouse": { "id": 3, "name": "المخزن الرئيسي" },
  "stock_movement_id": 912,
  "moved_stock": true,

  "is_reversal": false, "is_reversed": false, "is_reversible": true,
  "reverses_supply_id": null,
  "recorded_by_user_id": 6,
  "recorder": { "id": 6, "name": "محمد", "employee_code": "E6" },
  "created_at": "2026-09-11T10:20:00+00:00"
}
```

**`moved_stock` is the flag to render from**, not `warehouse_id`. The three stock fields are
null together on a purchase that moved nothing — a CHECK on the table enforces the pair, so they
cannot come apart.

`amount`, `method` and `method_label` are **null on a `resolved_externally` row** — see §٤.

**No `updated_at`, on purpose.** A ledger entry is never updated, and publishing one would invite
a client to believe it could be. Do not add the field to the model.

---

## ٢. Models

Two Freezed models and two plain classes.

**`ShortageStatus` and `ShortageSource` and `SupplyKind` each need an `unknown` case**, reached
through `@JsonKey(unknownEnumValue: ...)`, exactly as `PurchaseOrderStatus` does — so a status the
server adds after this build shipped still parses. And, exactly as there, `unknown` is what the
app *reads* and never what it *offers*: the filter sheet lists `values.where((s) => s != unknown)`.

**Do not hold a status transition list in Dart.** `available_transitions` is on every payload and
is the server's own map. A client copy would draw a «مكتمل» button the API then refuses — and
«مكتمل» is deliberately in no map at all, because it is written by arithmetic when the remainder
reaches zero and is never anybody's to choose. See §٥.

**`remaining_quantity` is sent; do not compute it.** A subtraction in Dart is a second
implementation of the rule that decides when a shortage is finished, and the two would disagree
the first time rounding entered it.

`ShortagesFilter` is a plain class like `PurchaseOrdersFilter` — it never crosses the wire and is
never stored; it travels as `extra` on one route and carries the title to put above the answer.

---

## ٣. Repository, use cases, wiring

One repository with eight methods (the list, the board, show, create, update, status, assignee,
record supply, reverse supply) over `safeRequest` / `safePaginatedRequest`. The fact that the API
spells the assignment `PATCH .../assignee` and the reversal `POST .../supplies/{id}/reversal`
never leaves the impl.

Two notes that will otherwise cost an afternoon:

* **Omit filters rather than sending them null.** The list endpoint reads its filters without
  validating them, so a literal `"null"` reaching an enum is a 500 rather than an empty page —
  the same `'vendor_id': ?vendorId` idiom `PurchaseOrderRepositoryImpl` already uses.
* **`status` is a list**, sent as `status[]=new&status[]=searching` by the client's
  `multiCompatible` format. One status travels the same way.

### Wiring — six one-line edits

| File | Edit |
| --- | --- |
| `core/network/api_endpoints.dart` | a `ShortageEndpoints` class: `index`, `summary`, `show(id)`, `status(id)`, `assignee(id)`, `supplies(id)`, `supplyReversal(id, supplyId)`, `logs(id)` |
| `core/permissions/app_permission.dart` | five cases — `shortages.view` · `.manage` · `.assign` · `.supplies.record` · `.supplies.reverse` |
| `core/di/injector.dart` | `_registerShortages()`: repository + use cases as lazy singletons, the three Cubits as **factories** |
| `core/router/app_router.dart` | `Routes.shortages = '/shortages'`, `shortageDetailPath`, `shortageForm` + guarded `GoRoute`s |
| `features/root/.../root_drawer.dart` | a `_Link` behind `AppPermission.viewShortages` — see §٦ for which section |
| — | `dart run build_runner build --delete-conflicting-outputs` |

---

## ٣٫٥. Recording a supply moves stock — which the form has to reflect

**This is the biggest thing to get right, and it is new.** A supply is not a note beside the
goods; it is the goods arriving. Posting one writes a `PurchaseArrival` onto a shelf at
`amount ÷ quantity`, which is what lets the order draw the full quantity at «جاهزة» and what
carries the money into the P&L.

For the app that means **one extra field, conditionally**:

```jsonc
POST /api/v1/shortages/41/supplies
{ "quantity": "20", "amount": "500", "method": "cash", "warehouse_id": 3 }
```

| `is_stockable` on the shortage | The sheet |
| --- | --- |
| `true` — it names a size, so it has a shelf | **show a warehouse picker, required.** Omitting it is a 422 on `warehouse_id` |
| `false` — free text, «شريط لاصق عريض» | **hide the picker.** Sending one is *also* a 422 — the caller is telling the server goods are moving when they are not |

**Read the flag, never infer it.** It is on every shortage payload; deriving it from
`product_variant_id` would put a shelf picker in front of a roll of tape.

Two refusals to surface as sent:

```
المخزن مطلوب — البضاعة المشتراة تدخل المخزون لتُخصم منه الطلبية
هذا النقص ليس صنفاً في المخزون — تُسجَّل قيمته بلا إدخال مخزني
```

> **Why the picker is not optional on a stockable shortage.** The order draws the *full* ordered
> quantity off the shelf when it reaches «جاهزة» — nothing about that subtracts the shortage. So
> sacks that never reached a warehouse leave the order refused a week later with a message about
> a balance that says nothing about the purchase. The 422 above is that failure moved to the
> moment somebody can still fix it.

**A reversal takes the goods back off the shelf**, so it can now be refused by Inventory for
reasons that have nothing to do with shortages — the layer was already drawn on by an order, or
repriced by hand. Those arrive as 422s in Inventory's own words; show them as sent.

---

## ٣٫٦. Filling the «نواقص» form from the shelves

Two additions on the order side, both read-only, neither changing how a status move behaves.

**The hint is already there.** The `shortage_{lineId}` field on the «نواقص» transition now reads:

```
من أصل 300.000 — المتوفر في كل المخازن 270.000 قطعة — يُخصم من الفاتورة
```

Render it as sent. It is deliberately **not** a default — the balance is a record and the
shortage is an observation, and they disagree exactly when this screen matters. A size the
warehouse does not carry has no stock clause at all rather than «المتوفر ٠».

**And the numbers can be fetched.** When a deduction is refused — or before trying —

```
GET /api/v1/orders/1204/stock-shortfall?warehouse_id=3      orders.status.shortage
```

```jsonc
{ "warehouse_id": 3, "available_scope": "warehouse", "is_short": true,
  "lines": [
    { "line_id": 3310, "name": "كيس شحن — 25*35", "unit_label": "قطعة",
      "required": "300.000", "available": "270.000", "suggested_shortage": "30.000" }
  ] }
```

`suggested_shortage` is what to put in that line's box. Offer «سجّلها كنواقص», prefill, and post
the **existing** `PATCH /orders/{order}/status` — there is no new write path.

* Omit `warehouse_id` and it answers across every warehouse; `available_scope` says which
  question was answered (`warehouse` | `all_warehouses`). Label a cross-site sum as one.
* **Two lines can share a shelf.** The server apportions — earlier lines fill first, the later
  one absorbs the shortfall — and the split is a *suggestion*. Let the user move it between lines
  before saving; only the total is a fact.

---

## ٤. The one thing most likely to be got wrong

**A shortage has two doors, and the app sees both.**

An employee closes a shortage from *this* section by recording what they bought. A colleague
closes the same shortage from the **order** screen, by typing what arrived into the
`received_{itemId}` fields when the order leaves «نواقص». Both are real and both stay open.

The consequences for the app:

1. **A shortage can change without this screen touching it.** After any edit on the order screen,
   the shortage list is stale. The sync runs on a queued listener, so it is *not* instant — do not
   re-fetch the shortages list synchronously after an order write and expect the new number. Let
   the user pull to refresh; `PagedCubit.refresh()` already re-runs the current term.

2. **The supplies table contains rows nobody in this section created.** They arrive with
   `kind: "resolved_externally"`, `amount: null`, `method: null`, and `is_reversible: false`.
   Render them as «وصلت من الطلبية» with a dash in the value and method columns — **not as
   `0.00`**, which would read as a free purchase and sit wrongly in anybody's mental total.

3. **Recording a supply changes the order *and* the warehouse.** The quantity is subtracted from
   the order line's shortage — putting the goods back on the customer's invoice — and a
   `PurchaseArrival` lands on the chosen shelf. If the user is deep-linked from an order, that
   order's totals are stale; so is any inventory screen they have open.

   Two cases where it silently does *not* happen, and both are correct: an **archived** order
   (`order.is_archived == true`), and an order whose lines have closed — «جاهزة» onwards. The
   purchase is recorded either way. Do not promise the invoice will change in the sheet's copy.

---

## ٥. What the server refuses, and why each message must be shown as sent

Every one of these is a 422 with its own Arabic sentence. None should be re-worded in Dart — each
names a different problem and tells the person what to do instead.

| When | Sentence |
| --- | --- |
| `status: "completed"` | «لا يُحوَّل النقص إلى «مكتمل» يدوياً — يكتمل وحده عند توفير كامل الكمية» |
| an illegal move | «لا يمكن تحويل النقص من «…» إلى «…»» |
| supply > remaining | «الكمية (…) أكبر من المتبقي من النقص (…)» — on field `quantity` |
| supply on a completed shortage | «النقص مكتمل — لا يمكن تسجيل توفير جديد عليه» |
| editing an order-born shortage | «نقصٌ مصدره طلبية — تُعدَّل كميته من شاشة الطلبية لا من هنا» |
| cutting the requirement below what was supplied | «الكمية المطلوبة (…) أقل مما تم توفيره فعلاً (…) — اعكس عملية التوفير أولاً» |
| reversing an arrival from the order | «لا تُعكس كمية وصلت من الطلبية — تُصحَّح من شاشة الطلبية» |
| reversing a reversal | «لا يُعكس قيدٌ عكسي — تُسجَّل العملية من جديد إن كان الشراء قد تمّ فعلاً» |
| reversing twice | «عملية التوفير معكوسة أصلاً» |

**Four of these are avoidable in the UI and should be**, because a form that offers an action the
API refuses is a form that teaches people to distrust it:

* `available_transitions` is on the payload — draw exactly those buttons and no others.
* `is_editable: false` greys the edit form on an order-born shortage.
* `is_reversible` on each supply row is what puts a cancel action on it; the server has already
  decided that an arrival and a reversal are not candidates.
* Cap the quantity box at `remaining_quantity` and show the remainder beside it.

**The ceiling is still checked on the server under a lock**, so the 422 can still arrive — two
clerks recording the last ten kilos at once. Handle it; do not assume the cap prevented it.

---

## ٦. The screens

### ٦٫١ The list — `/shortages`

Four blocks down one column:

1. **The chip row** — «جديد ١٢ | جاري البحث ٧ | غير متوفر ٣ | مكتمل ٢٥», from
   `/shortages/summary`, tapping filters. The acceptance criteria name this explicitly.
2. **«المسندة إليّ»** — a filter, not a screen. `assigned_to=me`. Beside it «غير مُسنَدة»
   (`assigned_to=none`), which is the queue a supervisor actually works from.
3. **Search + a filter sheet** for status, assignee, product and source.
4. **The rows.**

Each card shows: the name, **المتبقي beside المطلوب** (not just one of them), the unit, the
status chip, the assignee, and a source marker — «يدوي» or the order's code. §٨ of the brief asks
for «معرفة مصدر النقص» and the code is the whole of it.

> **Newest first, and completed rows are not buried.** Within a month of shipping, «مكتمل» will be
> the majority of the table, and a list that hid them would make the historical record — the thing
> §١٠ of the brief asks to keep — reachable only by filtering. The chip row above is what makes
> that readable.

### ٦٫٢ The detail — `/shortages/{id}`

Header: the four numbers together, because §٩ asks for exactly this block —

```
إجمالي المطلوب ٣٠ كجم · إجمالي المتوفر ٣٠ كجم · المتبقي ٠ كجم · إجمالي المدفوع ٧٦٠ د.ل
```

Then the source (with a tap-through to the order), the assignee, the status with its buttons, and
**the supplies table**: الكمية · القيمة · طريقة الدفع · الموظف · التاريخ, oldest first as the
server sorts it, reversals included and struck through.

**Reversals stay in the table.** §٩ asks for a log of every operation, and a correction that
vanished from the very screen meant to explain the numbers would make a shortage reading «١٠ كجم»
after two entries of twenty look like a mistake rather than a recorded one.

### ٦٫٣ The record-supply sheet

The one screen where the money rules bite. Three required boxes — الكمية, القيمة, طريقة الدفع —
plus optional رقم العملية, التاريخ (defaults to today on the server if omitted) and ملاحظات.

* **Payment method is a picker, never free text.** The four values are `cash` · `bank_transfer` ·
  `bank_card` · `libyana`, the same vocabulary a customer's payment uses; `method_label` is what
  to print.
* **Show «المتبقي بعد هذه العملية» live** as the quantity is typed. Partial supply is the ordinary
  case, not the exception, and the whole point is that the user sees they are leaving the shortage
  open — the same show-before-you-press idea `TransitionFields::deductionPreview()` and
  `StockEffectPreview` already establish on the order screens.
* Returns through **`context.pushForResult`**, the navigation idiom on this branch.
* **Do not pre-fill the quantity with the remainder.** `receive_arrival_sheet.dart` argues this at
  length for shipments and it holds here: pre-filling turns «كم وصل» into «أكّد ما كنا نأمله».

### ٦٫٤ Where it goes in the drawer

The sections today are: المنتجات والخدمات · المشتريات والتوصيل · الاستثمار والمالية · الإدارة
والصلاحيات · الأرشيف · الأدوات.

**Put it in «المشتريات والتوصيل».** A shortage is something to go out and buy, it sits next to
أوامر الشراء in the same person's day, and it is not a section of its own for the reason the
drawer's own comment gives: a heading exists to group rows, and one row does not earn one.

> **Careful with `AppSpeedDial`:** adding a second action to a screen that has one turns the
> extended button into a closed dial, and widget tests fail silently on `tap(find.text(...))`.

---

## ٧. Tests to add

Minimum Cubit coverage per `frontend/RULES.md` §٩, mirroring `test/features/purchase_orders/`:

* **Model** — `fromJson` over §١٫٣ with the nested objects **absent** (the list shape) and
  **present** (the detail shape); an unknown `status` string lands on `unknown`; a
  `resolved_externally` supply parses with `amount: null`.
* **Counts** — `{counts, total}` parses; `total` is read, not summed.
* **Cubit** — `assigned_to=me` and `=none` produce the right query; the status filter rides on
  `loadMore`'s pages too; `belongs()` drops a row whose status moved out of the chip on screen.
* **Widget** — `available_transitions: []` draws no status buttons; `is_editable: false` greys
  the form; a `resolved_externally` row renders a dash rather than `0.00`; the supply sheet's
  remainder line updates as the quantity is typed; **`is_stockable: false` hides the warehouse
  picker and `true` requires it**; a supply row with `moved_stock: true` names its warehouse.

---

## ٨. Checklist

- [ ] `shortage.dart`, `shortage_supply.dart` + `build_runner`
- [ ] `shortage_counts.dart`, `shortages_filter.dart` (plain classes)
- [ ] `ShortageRepository` + impl
- [ ] Use cases
- [ ] `ShortageEndpoints`
- [ ] Five `AppPermission` cases
- [ ] `_registerShortages()` in the injector
- [ ] Routes + guarded `GoRoute`s
- [ ] Drawer link in «المشتريات والتوصيل» behind `PermissionGate`
- [ ] `ShortagesCubit` (list + chips + filters), `ShortageDetailCubit`, `SaveShortageCubit`
- [ ] `ShortagesPage`, `ShortageDetailPage`, `ShortageFormPage`
- [ ] The three sheets — filter, assign, record supply (**with the conditional warehouse picker**)
- [ ] Prefill «نواقص» from `GET orders/{order}/stock-shortfall`
- [ ] Deep link both ways: order → its shortages, shortage → its order
- [ ] Tests
- [ ] `flutter analyze` clean, `dart format -l 100` on changed files only

---

## ٩. Before the screen ships

Grant the five permissions from **الأدوار والصلاحيات**. The backend adds them on deploy
(`permissions:sync`) and assigns them to **nobody** — `RoleSeeder` leaves them out deliberately,
because two of the five spend money and which employee is trusted to hand over cash for a sack is
not a question a seeder should answer. Only the administrator satisfies them by rule until
somebody hands them out.

And one open business question the screen does not depend on but the reports will:
[§١٢٫٢](SHORTAGES-DESIGN.md) — whether a shortage purchase is a cost attributed to the order or a
general expense. Nothing in the app changes either way; it is recorded now and attributed later.
