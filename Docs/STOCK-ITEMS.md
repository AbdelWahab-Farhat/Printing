# Stock items and materials — what changed, and what the app has to do

> Backend work on branch `warehouse_update`, covering two related changes shipped together:
> **stock items** (breaking) and **stock item groups** (additive).
> The generated API spec is [openapi.json](openapi.json); this is the human version and the
> frontend migration guide.

---

## 1. The change in one picture

A warehouse used to hold a **product's size**. It now holds a **stock item** — a material at a
size — and those sizes are filed under a **stock item group**, the material itself.

```
                 BEFORE                                          AFTER

Product ─1:N─> ProductVariant ─1:N─> WarehouseStock   StockItemGroup «كيس شحن»
                     │                                      │
                     └─1:N─> StockMovement                  ├── StockItem «كيس شحن 25*35» ─┬─1:N─> WarehouseStock
                     └─1:N─> StockBatch                     ├── StockItem «كيس شحن 35*40»  ├─1:N─> StockMovement
                     └─1:N─> PurchaseOrderItem              └── StockItem «كيس شحن 45*50»  ├─1:N─> StockBatch
                     └─1:N─> StockArrivalItem                            ▲                 ├─1:N─> PurchaseOrderItem
                                                                         │                 └─1:N─> StockArrivalItem
   one shelf per product size                    ProductVariant ─N:1─────┘
                                                        │
                                                  Product ─N:1─> StockItemGroup
                                                        (say the material once)
```

## 2. Why

«أكياس الشحن» (مطبوعة) at 25\*35 and «أكياس الشحن السادة» at 25\*35 are two catalogue rows and
**one pile of bags**. Before this, each kept a private balance over stock that was bought once, on
one purchase line, at one price. An order for 300 of one and 400 of the other passed two separate
checks against two shelves of 500 — and then came up short on the floor.

What separates those two products is the *printing*, which is a manufacturing cost rate keyed per
variant. Not a different material.

**The rule:** sharing runs **across products at one size, never across sizes**. «كيس شحن 25\*35»
and «كيس شحن 35\*40» are two stock items, two balances, two FIFO stacks and two purchase order
lines at two prices — so per-size costing is fully intact.

**The group** exists because, with stock items alone, every product size had to be pointed at its
shelf by hand: four decisions for two products at two sizes, and one wrong click splits the heap
again. Naming the material once on the product removes the decision entirely.

---

## 3. The two resources

### `StockItemGroup` — «مجموعة أصناف», the material

Holds nothing: no balance, no cost layer, no size. Server-assigned code `G1`, `G2`…

```jsonc
{
  "id": 3,
  "code": "G3",
  "name": "كيس شحن",
  "default_unit": "piece",          // what a size created under it starts out counted in
  "default_unit_label": "قطعة",
  "description": null,
  "is_active": true,
  "sort_order": 0,
  "items_count": 4,                 // list endpoint only
  "products_count": 2,              // list endpoint only
  "items": [ /* StockItemResource[], smallest first — show endpoint only */ ]
}
```

It is a table of its own rather than a `parent_id` on `stock_items` on purpose: a self-referencing
table makes a parent and a child two kinds of row wearing one shape, and every picker in Inventory
would need to remember to filter one out. A group is its own type, so it simply cannot hold stock.

### `StockItem` — the shelf, a material at a size

Server-assigned code `S1`, `S2`…

```jsonc
{
  "id": 1,
  "code": "S1",
  "stock_item_group_id": 3,
  "stock_item_group": { "id": 3, "code": "G3", "name": "كيس شحن" },
  "name": "كيس شحن",                 // a grouped item carries its material's name
  "width_cm": 25,                    // null for something counted without dimensions
  "height_cm": 35,
  "display_name": "كيس شحن 25*35",   // composed server-side — render it, never rebuild it
  "unit": "piece",                   // what THIS shelf is counted in
  "unit_label": "قطعة",
  "description": null,
  "is_active": true,
  "sort_order": 0,
  "variants_count": 2                // how many product sizes draw on it — list endpoint only
}
```

Uniqueness is `(name, width_cm, height_cm)`. `stock_item_groups.name` is uniquely indexed for the
same reason — a grouped item carries its group's name, so two groups sharing one would fight over
the same shelf.

---

## 4. Endpoints

### New

| Method | Path | Permission |
|---|---|---|
| `GET` `POST` | `/v1/stock-item-groups` | `inventory.view` / `inventory.manage` |
| `GET` `PUT\|PATCH` `DELETE` | `/v1/stock-item-groups/{stock_item_group}` | `inventory.view` / `inventory.manage` |
| `GET` | `/v1/stock-item-groups/{stock_item_group}/logs` | `logs.view` |
| `GET` `POST` | `/v1/stock-items` | `inventory.view` / `inventory.manage` |
| `GET` `PUT\|PATCH` `DELETE` | `/v1/stock-items/{stock_item}` | `inventory.view` / `inventory.manage` |
| `PATCH` | `/v1/stock-items/{stock_item}/unit` | `inventory.manage` |
| `GET` | `/v1/stock-items/{stock_item}/logs` | `logs.view` |

Group list filters: `search`, `is_active`, `per_page`.
Item list filters: `search`, `is_active`, `width_cm`, `height_cm`, `per_page`.

`width_cm` + `height_cm` is what a shelf picker should use — given a 25\*35 variant, offer the
25\*35 shelves first.

No new permissions exist server-side; both reuse the `inventory.*` pair.

### Removed

| Gone | Replaced by |
|---|---|
| `PATCH /v1/products/{product}/stock-unit` | `PATCH /v1/stock-items/{stock_item}/unit` |

### Renamed query filters

| Endpoint | Before | After |
|---|---|---|
| `GET /v1/warehouses/{id}/stocks` | `?product_variant_id=` | `?stock_item_id=` |
| `GET /v1/stock-movements` | `?product_variant_id=` | `?stock_item_id=` |

---

## 5. Contract diff

### ⚠️ Breaking — `product_variant_id` → `stock_item_id`

Request bodies:

| Endpoint | Field |
|---|---|
| `POST /v1/stock-movements/arrivals` · `transfers` · `fulfillments` · `adjustments` | `stock_item_id` |
| `POST /v1/stock-arrivals` | `items[].stock_item_id` |
| `POST\|PUT /v1/purchase-orders` | `items[].stock_item_id` |
| `POST /v1/purchase-orders/{id}/arrivals` | `items[].stock_item_id` |

Responses:

| Resource | Before | After |
|---|---|---|
| `WarehouseStock` | `product_variant_id`, `product_variant { id, label, product_id, product_code, product_name, image_url }` | `stock_item_id`, `stock_item { id, code, name, width_cm, height_cm, display_name }` |
| `StockMovement` | same pair | same swap |
| `PurchaseOrderItem` | same pair | same swap |
| `StockArrivalItem` | same pair | same swap |

⚠️ **`image_url` and `product_name` are gone from stock lines.** A pile is not one product's —
naming or picturing either of the two products that share it would be picking one arbitrarily and
telling the storekeeper the wrong thing. `unit`, `unit_label`, `quantity`, `low_stock_threshold`
and `is_low_stock` are unchanged.

`Product` **loses** `stock_unit` and `stock_unit_label`. `pricing_unit` / `pricing_unit_label` are
untouched: that is what the customer is charged by, and it never moved.

### Additive — new fields

| Resource | New |
|---|---|
| `ProductVariant` | `stock_item_id` (nullable), `stock_item { …, unit, unit_label }` |
| `Product` | `stock_item_group_id` (nullable), `stock_item_group { id, code, name, default_unit, default_unit_label }` |
| `StockItem` | `stock_item_group_id` (nullable), `stock_item_group { id, code, name }` |

| Request | New field |
|---|---|
| `POST\|PUT /v1/products` | `stock_item_group_id`, `variants[].stock_item_id` — both nullable |
| `POST /v1/stock-items` | `stock_item_group_id` — nullable; supplying it makes `name` and `unit` optional |

### Unchanged on purpose

`order_items.product_variant_id` — you sell a *size*, not a shelf.
`product_price_tiers` — every size keeps its own price list.
`manufacturing_cost_rates.product_variant_id` — printing a 25\*35 costs different labour from a
45\*60, even on identical film.

---

## 6. How a product gets linked

### The resolution rule, on every product save

| | Condition | Result |
|---|---|---|
| **1** | The payload gave `variants[].stock_item_id` | That wins. Always. |
| **2** | The product has a `stock_item_group_id` | The group's item at that variant's size — **created if absent** |
| **3** | Neither | `null`, exactly as before |

Rule 1 is the escape hatch — a 25\*35 bag deliberately cut from a wider sheet keeps saying so.
Rule 3 is why products with no material behave exactly as they did.

**A created shelf takes the group's `default_unit`, never the product's `pricing_unit`.** A thing
bought in by weight and sold by the piece needs those two to differ, and the shelf's side of that
pair belongs to the material.

### Worked example

```bash
# 1 — the material, once
POST /v1/stock-item-groups
{ "name": "كيس شحن", "default_unit": "piece" }        → id 3, code G3

# 2 — the printed product names it; both sizes file themselves
POST /v1/products            (multipart/form-data — the photo is required)
  name=أكياس الشحن المطبوعة
  product_category_id=4
  stock_item_group_id=3
  pricing_unit=piece   pricing_mode=tiered   min_order_quantity=100
  image=@bag.jpg
  variants[0][label]=25*35  variants[0][width_cm]=25  variants[0][height_cm]=35
  variants[1][label]=35*40  variants[1][width_cm]=35  variants[1][height_cm]=40

# 3 — the plain product names the SAME material and lands on the SAME shelves
POST /v1/products
  name=أكياس الشحن السادة
  stock_item_group_id=3
  variants[0][label]=25*35  variants[0][width_cm]=25  variants[0][height_cm]=35
```

Nobody picked a shelf. Step 2 minted two stock items; step 3 reused one of them.

Required on the product: `name`, `product_category_id`, `pricing_unit`, `pricing_mode`,
`min_order_quantity`, `image`. Nested variants use bracket notation, not a JSON blob.

---

## 7. Behaviour the UI has to handle

**Shortfall messages name the shelf.** An order refused at «جاهزة» says
«الكمية المتوفرة من **«كيس شحن 25\*35»** في المخزن (500.000) لا تكفي للكمية المطلوبة (700.000)»
instead of «كيس شحن — 25\*35». If any screen parses that string, stop.

**Requirements total per shelf, not per line.** Two order lines drawing on one pile are added
together before either is compared. Orders that used to pass may now correctly fail — that is the
point of the change, not a regression. Warn the warehouse staff.

**A size can have no shelf.** `stock_item_id` is nullable, because a quote-only size is never
stocked. Any stock movement against such a size is refused with a readable 422 under
`errors.stock_item_id`: ««المنتج — المقاس» غير مرتبط بصنف مخزني — اربطه بصنف قبل حركة المخزون».

**Renaming a group renames every size of it**, in one transaction. Required, not tidy: a grouped
item carries its material's name, and that is what keeps `(name, size)` identifying one shelf. Say
so in the confirm dialog.

**Changing a group's `default_unit` does not touch existing shelves.** It decides what a size
created *later* is counted in. An existing shelf's unit is snapshotted onto every balance and cost
layer that touched it, and moving it is still `PATCH /stock-items/{stock_item}/unit`.

**Deletes are guarded.** A stock item is refused while any warehouse holds it, and again while any
product size draws from it (`errors.stock_item`). A group is refused while any size or any product
points at it, naming both counts at once (`errors.stock_item_group`).

### ⚠️ The trap that will bite

**On `PUT /products`, omitting `variants[].stock_item_id` clears that variant's link** — it does
not preserve it. The whole variant set is replaced on each save, so a half-stated variant is the
odd one out.

An app that loads a product, edits only a price, and PUTs the variants back **without** re-sending
`stock_item_id` will silently detach every size from its shelf, and nobody finds out until an order
fails at «جاهزة». Two safe options:

- round-trip `stock_item_id` with every variant (the GET hands it to you), **or**
- omit the `variants` key entirely when you are not editing sizes.

The product-level `stock_item_group_id` is *not* like this: omitting it keeps the current material,
the same rule `slug` and `is_active` follow.

---

## 8. Two limits, stated plainly

**A stock item's group is set at creation and cannot be changed by `PUT`.** Re-filing a size under
another material would rename it, and a rename is the one edit that can collide with an existing
shelf. Nothing in the ordinary flow needs it. A dedicated action if you ever want it.

**A product's material cannot be *cleared* through `PUT /products`.** Omitting it leaves the
current one alone. Clearing would silently detach every size on that very save.

---

## 9. Flutter migration

Not started — backend only, as agreed. One ordered plan covering both changes, arranged so the app
compiles again as early as possible. File counts from a survey of `lib/`: 33 files touch
`product_variant_id`, 11 touch `stock_unit`.

### Step 1 — two new feature modules

`lib/features/stock_item_groups/` and `lib/features/stock_items/`, each mirroring
`lib/features/warehouses/`: freezed model, repository, usecases, cubit, list page, form page.
Register both in `lib/core/di/injector.dart`; add `StockItemEndpoints` and
`StockItemGroupEndpoints` to `lib/core/network/api_endpoints.dart`.

No permission constants to add — both reuse `inventory.view` / `inventory.manage`.

### Step 2 — warehouses (the breaking core)

| File | What to do |
|---|---|
| `features/warehouses/models/warehouse_stock.dart` | `productVariantId` → `stockItemId`; replace the `StockVariant` nested class with `StockItem`; **delete every `image_url` use** |
| `features/warehouses/models/stock_movement.dart` | same swap |
| `features/warehouses/repositories/warehouse_repository.dart` + `_impl.dart` | filter param rename |
| `features/warehouses/usecases/get_stock_movements.dart` | filter param rename |
| `features/warehouses/usecases/record_stock_movement.dart` | payload key rename |
| `features/warehouses/presentation/viewmodel/record_movement_cubit.dart` + `_state.dart` | the picker now selects a stock item |
| `features/warehouses/presentation/widgets/record_movement_sheet.dart` | swap the variant picker for a stock-item picker |
| `features/warehouses/presentation/viewmodel/stock_movements_cubit.dart` | filter rename |
| `features/warehouses/presentation/views/stock_movements_page.dart` | render `stock_item.display_name` |

Then `dart run build_runner build --delete-conflicting-outputs`.

⚠️ The shelf list loses the product thumbnail. Decide what replaces it — the item `code` reads well
on a row and `display_name` carries the size.

### Step 3 — purchasing

`features/purchase_orders/models/purchase_order.dart` ·
`.../presentation/viewmodel/save_purchase_order_state.dart` ·
`.../presentation/views/purchase_order_form_page.dart` ·
`.../presentation/widgets/receive_arrival_sheet.dart` ·
`.../repositories/purchase_order_repository.dart` · `.../usecases/purchase_order_usecases.dart` ·
`features/vendors/models/stock_arrival.dart` · `features/vendors/repositories/vendor_repository.dart`

Line items name a stock item; the product+size picker becomes a stock-item picker.

### Step 4 — products (where the value lands)

`features/products/models/product.dart` — drop `stockUnit`/`stockUnitLabel`; add
`stockItemGroupId` + the nested group.
`features/products/models/new_product.dart` — drop `stock_unit`; add `stock_item_group_id`, and
`stock_item_id` on the variant sub-model.
`features/products/presentation/views/product_form_page.dart` — **one material picker at the top of
the form. That is the whole feature from the user's side.** With a material set, the per-variant
shelf picker can move behind an "advanced" toggle.
`.../viewmodel/save_product_cubit.dart` · `.../usecases/save_product.dart` — carry both fields.
`product_detail_page.dart` · `product_detail_cubit.dart` · `product_repository*.dart` — remove the
stock-unit display and the `setProductStockUnit` call.

**Delete** `features/products/usecases/set_product_stock_unit.dart` — its endpoint is gone. The
equivalent control belongs on the stock-item screen from step 1.

### Step 5 — leave alone

`features/orders/**` and `features/manufacturing_cost_rates/**` still speak `product_variant_id`,
correctly. **Do not sweep them with a project-wide rename** — that is the easiest mistake to make
here.

---

## 10. Backend notes worth knowing

- `products.stock_unit` was **dropped**; `stock_items.unit` replaces it. The deliberate split
  between "what the customer is charged by" and "what the shelf is counted in" survives intact —
  the second half simply has one owner now, so two products sharing a pile cannot disagree.
- FIFO cost layers pool across products sharing a shelf. Costs get *more* accurate, not less.
- **Profit & loss is completely untouched.** It sums cached columns (`total_cogs`, `material_cost`,
  `labor_cost`, `overhead_cost`, `items_total`, `design_fee`, `order_payments.amount`), none of
  which changed name, type or meaning. Only the `material_cost` *values* shift, because FIFO pools
  differently.
- `order_items.warehouse_quantity` is unchanged: what the operator types is what moves. No
  conversion factor exists anywhere.

### Two bugs found and fixed on the way

- `purchase_order_items` had a `distinct` validation rule but **no unique index** — the exact
  half-measure RULES.md §8 warns about. Added `purchase_order_items_one_line_per_item`.
- With that index in place, `UpdatePurchaseOrder::syncItems()` failed on an ordinary save: it
  created before it deleted, so an idless line for an existing stock item collided with the row
  about to be removed. It now matches on `stock_item_id` as the natural key — which also stops a PO
  line losing its identity and audit trail on every update.

### Migrations

Ten in total: seven for stock items (one of which drops `products.stock_unit` and re-keys five
tables), three additive for groups. The group migration **backfills** one group per distinct
`stock_items.name` and repoints every item, so an existing database keeps working.

---

## 11. Known pre-existing bugs (not caused by this work)

`php artisan migrate:fresh --seed` fails for two reasons that predate all of it:

1. `RoleSeeder` calls `forgetCachedPermissions()` at the end of `run()` instead of the start, so
   `syncPermissions()` runs against a stale cache → *There is no permission named `customers.view`*.
2. `DatabaseSeeder`'s `WithoutModelEvents` mutes the `creating` hook that assigns `products.code`,
   so seeding through it violates the NOT NULL constraint. `StockItem` and `StockItemGroup` use the
   same pattern, so this now affects three models.

Workaround: `php artisan migrate:fresh`, then `php artisan permission:cache-reset`, then run the
seeders individually (`db:seed --class=CatalogSeeder`, etc.).

---

## 12. Verification

| | |
|---|---|
| `php artisan test` | **1333 / 1333**, 4,410 assertions |
| `./vendor/bin/pint --test` | clean |
| `php artisan scramble:analyze` | clean |
| Seeded catalogue | 10 products · 8 materials · 24 stock items · 25 variants (24 linked, 1 correctly null) |

The tests worth reading first, at the bottom of `StockItemGroupTest`: a product files every size
automatically · two products on one material land on the same shelves · an explicit stock item
beats the material · a product with no material leaves its sizes unlinked · a created size takes
the material's unit not the product's · a material never disturbs a balance that already exists.

And in `OrderWorkflowTest`: two products sharing a shelf are weighed against it together — the
failure this whole change exists to prevent.

Requires **PHP 8.4+** — the project's `composer.json` platform check refuses 8.2.
