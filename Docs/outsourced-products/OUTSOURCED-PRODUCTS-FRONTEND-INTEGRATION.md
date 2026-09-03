# وسيط — connecting the Flutter app

> How to wire `frontend/` up to the backend described in
> [OUTSOURCED-PRODUCTS.md](OUTSOURCED-PRODUCTS.md). Follows the recipe in
> [frontend/RULES.md §12](../../frontend/RULES.md) — this doc applies it to this feature rather
> than repeating the general rules.
>
> **The backend is merged and the app still runs.** Every key added is additive and the old
> `skips_production` is still spoken in both directions, so nothing here is urgent *except* §1 —
> two enum entries the frontend test suite already fails without.
>
> **Status (2026-09-03): §1 through §7 are done on this branch.** The app writes
> `production_mode` and never `skips_production`; the cost box, the vendor row and «المورد» on
> the order screen are wired as described below; `vendorRequirementFor` mirrors the
> every-line-or-none rule. One thing the backend still owes — see §10.

---

## 0. What the feature is, in one paragraph

دعاية sells things an outside vendor makes — 50 كرت بزنس, sold at 50, bought at 25. Such a product
is filed under a heading whose **`production_mode` is `outsourced`**, and each of its sizes carries
a **`cost_price`** that only authorised staff may see. When the order is taken the clerk picks the
**vendor** from the existing vendor list, and the server copies the cost onto the order so a later
price rise leaves old orders alone. The order then walks **جديدة → (قيد التصميم) → قيد التصنيع →
جاهزة** — no «جاهزة للطباعة», no «نواقص», and no warehouse is asked for on the way to «جاهزة».

---

## 1. The two changes that are already overdue

`order_status_contract_test.dart` and `permission_contract_test.dart` read the PHP enums **case for
case**. They are red right now. Both fixes are one line each.

[lib/features/orders/models/order_status.dart](../../frontend/lib/features/orders/models/order_status.dart)
— after `printing`, in the position `OrderStatus.php` declares it:

```dart
  @JsonValue('printing')
  printing('printing', 'قيد الطباعة'),

  /// The job is with an outside vendor, being made. Only وسيط orders reach it — see
  /// OUTSOURCED-PRODUCTS.md §4. It is not «قيد الطباعة» under another name: one status, one
  /// word, and the server sends the word.
  @JsonValue('manufacturing')
  manufacturing('manufacturing', 'قيد التصنيع'),
```

[lib/core/permissions/app_permission.dart](../../frontend/lib/core/permissions/app_permission.dart)
— two cases, in the same order the PHP file lists them:

```dart
  // beside viewProducts / manageProducts
  /// What the shop pays a vendor for a وسيط size, on the product **and** on the order line.
  /// Split from [viewProducts] on purpose: taking an order needs the price the customer pays and
  /// nothing else, so the server omits the key entirely for anybody without this.
  viewProductCost('products.view_cost', 'عرض سعر تكلفة المنتجات الوسيطة'),

  // beside moveOrderToPrinting
  moveOrderToManufacturing('orders.status.manufacturing', 'تحويل الطلبية إلى قيد التصنيع'),
```

With those two in, the app is *correct* — it simply cannot create a وسيط order yet. Everything
below is what makes the feature usable.

---

## 2. Endpoints

**No new endpoints.** Every change is a field on a call the app already makes.

| Verb | Path | What is new | Permission |
|---|---|---|---|
| `GET` | `/product-categories` | `production_mode`, `production_mode_label` | `products.view` |
| `POST` · `PUT` | `/product-categories`, `/{id}` | accepts `production_mode` | `products.manage` |
| `GET` | `/products`, `/products/{id}` | `product_category.production_mode`, `variants[].cost_price` | `products.view` (+ `products.view_cost` for the cost) |
| `POST` · `PUT` | `/products`, `/{id}` | accepts `variants[].cost_price` | `products.manage` |
| `POST` · `PUT` | `/orders`, `/{id}` | accepts `vendor_id` | `orders.manage` |
| `GET` | `/orders`, `/orders/{id}` | `vendor_id`, `vendor_name`, `manufacturing_started_at`, `items[].unit_cost`, `items[].outsourcing_cost` | `orders.view` |
| `POST` | `/orders/{id}/status` | accepts `{"status": "manufacturing"}` | `orders.status.manufacturing` |
| `GET` | `/vendors` | unchanged — reuse the existing feature | `vendors.view` |

---

## 3. Models

### 3.1 `ProductionMode` — new

`lib/features/products/models/production_mode.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

/// How goods under a heading come to exist — the lever an order's road is decided by.
///
/// Mirrors `ProductionMode.php`. It replaced a boolean (`skips_production`) the day «وسيط»
/// arrived, because the shop has three kinds of work and a boolean can hold two.
///
/// [unknown] for the same reason every other enum here has one: a fourth mode added on the server
/// must not turn a whole category list into a parse failure. Never send it.
enum ProductionMode {
  /// مطبوعة — we design it and we print it. What every heading is until somebody says otherwise.
  @JsonValue('in_house')
  inHouse('in_house', 'تصميم وطباعة لدينا'),

  /// سادة — already made, picked off our shelf and counted.
  @JsonValue('none')
  none('none', 'بلا تصميم وطباعة'),

  /// وسيط — an outside vendor makes it. The only mode that carries a cost price, needs a vendor
  /// on the order, and deducts nothing from a warehouse.
  @JsonValue('outsourced')
  outsourced('outsourced', 'وسيط — لدى مورد خارجي'),

  unknown('unknown', 'غير معروفة');

  const ProductionMode(this.wire, this.label);

  final String wire;
  final String label;

  /// Whether a size filed under this heading may carry «سعر التكلفة» at all. The server refuses
  /// one anywhere else with a 422, so this decides whether the box is drawn.
  bool get hasCostPrice => this == ProductionMode.outsourced;

  /// Whether an order made only of these goods must name the vendor executing it.
  bool get needsAVendor => this == ProductionMode.outsourced;
}
```

Prefer `label` from the server (`production_mode_label`) wherever one arrives; the local strings
are for a picker that must name a mode nothing is currently set to — the same split
[OrderStatus] draws.

### 3.2 `ProductCategory` — one field added, one deprecated

[product_category.dart](../../frontend/lib/features/products/models/product_category.dart):

```dart
    /// How goods under this heading come to exist — مطبوعة، سادة، أو وسيط.
    ///
    /// **This row's own answer, not the effective one.** A subheading that inherits its parent's
    /// mode reads `in_house` here, because this is the value the edit sheet puts back: showing
    /// the inherited answer would save a mode onto a child that never asked for one. What a
    /// particular *order* does is the server's to decide from its lines — see `ResolveOrderFlow`.
    @JsonKey(name: 'production_mode', unknownEnumValue: ProductionMode.unknown)
    @Default(ProductionMode.inHouse)
    ProductionMode productionMode,

    /// **Deprecated, and still sent by the server for this build.** True for سادة *and* for وسيط
    /// — neither is printed here — so it can no longer tell them apart. Read [productionMode];
    /// delete this the release after the sheet stops writing it. See OUTSOURCED-PRODUCTS.md §8.
    @JsonKey(name: 'skips_production') @Default(false) bool skipsProduction,
```

### 3.3 `ProductVariant` and `NewProductVariant` — the cost

[product.dart](../../frontend/lib/features/products/models/product.dart), on `ProductVariant`:

```dart
    /// What this size costs us when a vendor makes it — «سعر التكلفة».
    ///
    /// **Absent from the payload, not null, for anybody without `products.view_cost`** — so
    /// `null` here means one of two things and the screen must not claim it means «بلا تكلفة».
    /// Gate the row on the permission, not on the value.
    ///
    /// A decimal string, never a `double`: it is multiplied by a quantity on the server and
    /// compared against a price that is also a string.
    @JsonKey(name: 'cost_price') String? costPrice,
```

[new_product.dart](../../frontend/lib/features/products/models/new_product.dart), on
`NewProductVariant` — the same round-trip rule that already governs `stock_item_id` applies, and
for a stronger reason: **`PUT /products/{id}` replaces the whole variant set, and a size sent
without `cost_price` is saved with none.** Seed every row from `data.variants[].cost_price` and
send it back untouched, or the first price edit wipes the costs of every other size.

```dart
    /// ⚠️ Sent on every write, or it is cleared — see the note on [stockItemId]. Omitted from the
    /// body when null so «لم تُحدَّد» stays distinguishable from «امسحها».
    @JsonKey(name: 'cost_price', includeIfNull: false) String? costPrice,
```

### 3.4 `Product` — the effective mode

The product payload's `product_category` object now carries `production_mode` and
`production_mode_label`, and — unlike the categories endpoint — it is the **effective** answer,
with a parent's mode already applied. That is what the new-order form reads to decide whether to
ask for a vendor, and what the product form reads to decide whether to draw a cost box.

### 3.5 `Order` and its lines

[order.dart](../../frontend/lib/features/orders/models/order.dart):

```dart
    /// Who is making it, for an order a vendor executes. Null on everything we make ourselves.
    @JsonKey(name: 'vendor_id') int? vendorId,

    /// The vendor's name **as this order said it**. A vendor renamed since keeps its new name
    /// everywhere except here, which is the point of storing it — show this, never a lookup.
    @JsonKey(name: 'vendor_name') String? vendorName,

    /// When the job went out to the vendor. Null until it does.
    @JsonKey(name: 'manufacturing_started_at') DateTime? manufacturingStartedAt,
```

On the line class in the same file, beside `materialCost`:

```dart
    /// The copy of the size's cost price taken the day this order was made — what makes a later
    /// change to the catalogue leave this order alone.
    @JsonKey(name: 'unit_cost') String? unitCost,

    /// What the line cost in total, written when the vendor handed the job over («جاهزة»). Null
    /// before that: a price agreed with a vendor is not a cost incurred.
    @JsonKey(name: 'outsourcing_cost') String? outsourcingCost,
```

Both keys are **absent** without `products.view_cost` — same rule as `cost_price`.

### 3.6 `NewOrder`

```dart
    /// Who will make it. **Required by the server for an order whose lines are all وسيط**, and
    /// refused as a 422 on `vendor_id` when missing — the road is read off the lines, so the app
    /// cannot be told by a field rule and has to look at the products itself. See §5.
    @JsonKey(name: 'vendor_id', includeIfNull: false) int? vendorId,
```

---

## 4. The categories sheet — the change that unlocks everything else

[product_category_sheet.dart](../../frontend/lib/features/products/presentation/widgets/product_category_sheet.dart)
today draws a `SwitchListTile` for «بدون طباعة» and the repository sends `skips_production`.
Replace both with a three-way choice on `production_mode`:

- مطبوعة — `in_house`
- سادة — `none`
- **وسيط** — `outsourced`

Until this ships **there is no way to create a وسيط heading from the app**, so no product can be
one and nothing else in this document can be exercised.

The repository ([product_category_repository_impl.dart](../../frontend/lib/features/products/repositories/product_category_repository_impl.dart))
sends `'production_mode': mode.wire` in place of `'skips_production': bool`. Both are accepted;
sending the modern key is what stops the server having to guess.

> **The trap the server already guards, so you know why it is there.** An old build editing a
> وسيط heading sends `skips_production: false`, which would read as «حوّله إلى مطبوعة» and
> silently take every later order off the vendor road. The server ignores the boolean when the
> stored mode is `outsourced` and no `production_mode` came with it. Once this app sends the
> modern key, that guard stops mattering for it.

[product_category_card.dart](../../frontend/lib/features/products/presentation/widgets/product_category_card.dart)
currently prints « · بدون طباعة» off `skipsProduction`. Print `productionMode.label` instead, or
وسيط headings will read as plain ones.

---

## 5. The product form — a cost box, twice gated

[product_form_page.dart](../../frontend/lib/features/products/presentation/views/product_form_page.dart):
add a `cost_price` field to each size row, drawn only when **both** hold:

```dart
final category = /* the category currently chosen in the form */;
final showCost = category.productionMode.hasCostPrice
    && sl<Session>().can(AppPermission.viewProductCost);
```

- **The mode gate is the server's rule, not a nicety.** A `cost_price` on a product filed anywhere
  but وسيط is a 422 on `variants.N.cost_price` («سعر التكلفة لا يُسجَّل إلا على المنتجات
  الوسيطة»), which fails the whole save.
- **The permission gate is about the payload.** Without `products.view_cost` the key never arrives,
  so a form that drew the box would show an empty one and save `null` over a real cost.
- Switching the category picker to a non-وسيط heading must **clear** the boxes before saving, or
  the save is refused for a number the user can no longer see.
- Keep it a string field. Send `'25.000'`, not `25.0`.

Writing still needs `products.manage` — unchanged, and the form is already gated on it.

---

## 6. The new-order form — the vendor

[new_order_page.dart](../../frontend/lib/features/orders/presentation/views/new_order_page.dart):

1. Each line's product now carries `product_category.production_mode`. When **every** line is
   `outsourced`, the order will walk the vendor road and the server requires a vendor.
2. Show a vendor row using the existing
   [vendor_picker_sheet.dart](../../frontend/lib/features/vendors/presentation/widgets/vendor_picker_sheet.dart)
   — the same picker the purchase-order screens use. **Never a free-text box:** the field is
   `exists:vendors,id`.
3. Send `vendor_id` in the body.

**Mirror the "every line, or none" rule rather than inventing one.** One printed line beside four
وسيط ones is a printed order — the press really does have to run — and the server puts it on the
standard road, where a vendor is optional. Showing the picker for any وسيط line is fine and
harmless (the id is accepted on any order); *requiring* it in the app for a mixed order would
refuse an order the server would have taken.

The 422 to surface when it is missing arrives on `vendor_id` with the sentence «الطلبية الوسيطة
تحتاج مورداً — اختر المورد الذي سينفّذها».

The clerk **never sees or types a cost** on this screen. That is not a layout decision — the
payload does not carry one for them.

---

## 7. The order screen

- Show **المورد** from `vendor_name` when it is present, beside the customer and the destination.
- Costs (`unit_cost`, `outsourcing_cost`) render only for a holder of `products.view_cost`; check
  the permission, not the null.
- **The status screen needs nothing.** It draws whatever `available_transitions` describes, so
  «قيد التصنيع» arrives as a button with the fields the server says that move needs — which for
  this road is the ordinary optional note, and **no warehouse picker**.
- The progress bar shortens by itself: `production_flow` comes back `outsourced`, and the server's
  `progress` block already omits «جاهزة للطباعة».

## 8. What needs no work at all

| | why |
|---|---|
| Home board | Drawn from the server's own status list — a «قيد التصنيع» card appears with its Arabic and its count. |
| `GET /orders/counts` | The app holds counts in a map keyed by wire value; the new key is tolerated by construction. |
| Roles screen | The permission catalogue comes from `GET /permissions`, so both new grants appear with their Arabic labels. |
| Orders filter chips | Gains «قيد التصنيع» the moment §1 lands. |
| Vendors feature | Used as-is. |

---

## 9. Order of work

1. **§1** — two enum entries. Turns the suite green.
2. **§4** — the categories sheet. Without it nothing downstream can be created.
3. **§5** — the cost box on the product form.
4. **§6** — the vendor on the new-order form. After this the feature is usable end to end.
5. **§7** — المورد and the costs on the order screen.

Steps 3 and 4 are independent of each other; both depend on 2.

---

## 10. Two things to get right, and one to remember

- **`PUT /products/{id}` replaces the whole variant set.** A size sent without `cost_price` loses
  it, exactly as one sent without `stock_item_id` loses its shelf. Round-trip both.
- **A missing key is not `null`.** `cost_price`, `unit_cost` and `outsourcing_cost` are omitted for
  anybody without `products.view_cost`. Draw off the permission.
- **Nothing that already exists changed.** Existing orders keep their road, their numbers and
  their costs; existing categories were mapped `سادة → none`, everything else `→ in_house`; stock
  was not touched at all. See [OUTSOURCED-PRODUCTS.md §7](OUTSOURCED-PRODUCTS.md).

- **⚠️ Open on the backend: a save by somebody without `products.view_cost` wipes the costs.**
  The two rules above collide for exactly one reader — a holder of `products.manage` who lacks
  `products.view_cost`. The app never receives `cost_price` for them, so it (correctly) sends no
  key; and `SyncProductVariants` reads an absent key as «امسحه». Editing a وسيط product's name
  from such an account therefore clears every size's cost. The app cannot fix this — it has no
  number to send back. The fix belongs in `SyncProductVariants`: leave `cost_price` alone when the
  key is absent *and* the caller cannot see it. Until then, give `products.view_cost` to every
  role that holds `products.manage`.
