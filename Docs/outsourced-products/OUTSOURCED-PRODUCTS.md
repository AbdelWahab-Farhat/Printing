# وسيط — products a vendor makes for us

> Backend only. The Flutter app is a follow-up; §8 says exactly what it will need and what the
> API does to keep the shipped build working in the meantime.
> Completes [ORDERS-STATUS-FLOW.md](../../ORDERS-STATUS-FLOW.md) and
> [PRODUCT-CATEGORIES.md](../../PRODUCT-CATEGORIES.md); cancels nothing in either.
> Wiring the app up to it: [OUTSOURCED-PRODUCTS-FRONTEND-INTEGRATION.md](OUTSOURCED-PRODUCTS-FRONTEND-INTEGRATION.md).

---

## 1. What the business asked for

دعاية sells things it does not make. A customer orders 50 كرت بزنس; دعاية prices it, sends it to
an outside vendor, and follows it until the vendor hands it back finished. Between those two
moments there is no design queue of ours, no press of ours, and no shelf of ours — but there **is**
a cost, and it is the number that decides whether the job made money.

Four requirements, and everything below is one of them:

1. A product can be marked **وسيط**, and only such a product carries a **سعر التكلفة**.
2. The vendor is **chosen from the vendor list** when the order is taken — never typed.
3. The cost is set by whoever is authorised, on the product. The clerk taking the order neither
   enters it nor sees it, and the order keeps **a copy of the cost as it stood that day**.
4. The road is **جديدة → قيد التصنيع → جاهزة**, with **قيد التصميم** in front of it when the job
   needs artwork first. No «جاهز للتصنيع» — دعاية does not run the manufacturing, so there is
   nothing to be *ready* for.

---

## 2. The type is a third value on the category, not a new column

«النوع» stopped being a column on the product when مطبوعة/سادة became two headings — see
[PRODUCT-CATEGORIES.md](../../PRODUCT-CATEGORIES.md). وسيط joins them there, which means the boolean
that answered «هل يُطبع؟» now has three answers and has to say which:

| `production_mode` | التصنيف | what it means |
|---|---|---|
| `in_house` | مطبوعة | we design it and we print it — every order before this document |
| `none` | سادة | already made, picked off our shelf and counted |
| `outsourced` | **وسيط** | a vendor makes it; we send the job and follow it until it is ready |

`product_categories.skips_production` becomes `production_mode`, backfilled `true → none`,
`false → in_house`, and dropped. Forward-only, as every migration here is.

**Why not `is_outsourced` on the product.** Two booleans on two tables can contradict each other —
a product both سادة and وسيط has no answer — and it would fork the one thing that classifies a
product, three releases after that fork was deliberately closed. The price of one list is that a
product becomes وسيط by being filed under a وسيط heading, and that is the cheaper of the two.

A parent's answer still reaches its children, and still only where the child has not said
otherwise: `productionMode()` returns the child's own mode when it is not `in_house`, and the
parent's otherwise. That is the same rule `skipsProduction()` had, written for three values.

---

## 3. The cost lives on the size, and is not shown to everyone

**On the variant, not the product.** A sale price is a tier on a `product_variant`, and an order
line is always a variant — so a cost on the product could not be compared against the price it has
to be compared against. `product_variants.cost_price`, nullable, `CHECK >= 0`.

**Refused where it would mean nothing.** `variants.*.cost_price` on a product whose category is not
`outsourced` is a 422 in Arabic, not a silently stored number. A cost on a product we make
ourselves would be a second, unowned answer to a question `production_cost_entries` already
answers properly.

**Two permissions, because setting and seeing are two decisions.** Writing needs `products.manage`,
which the شخص المخوّل has and the order clerk does not. *Seeing* needs the new
`products.view_cost` — `ProductVariantResource` omits the key entirely without it, exactly as
`StockMovementController` already does for `inventory.view_cost`. The clerk taking an order is on
the `staff` role, which holds `products.view`; it does not hold the new one, so the number never
reaches their screen and requirement 3 is met by the payload rather than by the layout.

---

## 4. The road

### The status

```php
case Manufacturing = 'manufacturing';   // «قيد التصنيع»
```

with its own permission `orders.status.manufacturing` and its own column
`orders.manufacturing_started_at`. «كم يوماً تقعد الطلبية عند المورد؟» is the first question this
feature will be asked, and a denormalised timestamp is how every other status answers it.

**Not a per-flow label on «قيد الطباعة».** One status, one word, wherever it is drawn — chips,
filters, the audit dictionary and the home board all read `label()`, and a word that changed with
the road would fork all four. A `case` is what `OrderStatus` asks for in exchange, and its own
docblock says so.

### The flow

`OrderFlow::Outsourced`, «مسار الوسيط», resolved from the lines at intake by `ResolveOrderFlow`
under the rule it already applies: **every line, or none**. An order carrying one printed bag
beside four outsourced ones is a printed order — the press really does have to run — and the
unknown case still takes the road that asks *more* of the shop.

| flow | الطريق |
|---|---|
| `standard` | جديدة → جاهزة للطباعة → (قيد التصميم) → قيد الطباعة → جاهزة |
| `no_production` | جديدة → جاهزة |
| **`outsourced`** | **جديدة → (قيد التصميم) → قيد التصنيع → جاهزة** |

The outsourced arms, precisely:

- `New → [Designing, Manufacturing]` — straight to the vendor, or through design first. **No
  «جاهزة للطباعة»**: that status is the door into *our* press and the moment *our* warehouse lets
  the goods go, and neither happens here. **No «نواقص»**: we hold no stock of an outsourced
  product, so there is nothing to be short of.
- `Designing → [Manufacturing, Cancelled]`
- `Manufacturing → [Ready, Designing, Cancelled]` — back to design for a correction, exactly as
  «قيد الطباعة» already allows.
- `Ready` onward: the eleven shared arms. A parcel comes home the same way whoever made it.

`hasProduction()` was a boolean and can no longer answer, because قيد التصميم **is** on this road
while جاهزة للطباعة is not. `allowedNext()` becomes a three-arm `match` over the flow, each arm
falling through to the shared map for everything past «جاهزة», and `mainLine()` is built per flow
rather than filtered — a bar that drew جاهزة للطباعة on a وسيط order would claim a step nobody
takes, which is the same lie the detour handling exists to prevent.

### Nothing comes off our shelf

`OrderFlow::deductsStock()` — true for `standard` and `no_production`, false for `outsourced` —
is read in exactly two places: `ChangeOrderStatus`, which skips the deduction, and
`TransitionFields`, which stops asking for `warehouse_id` and the per-line warehouse quantities.
Both, so that what is asked for and what is done cannot drift apart; that pairing is already the
rule in `TransitionFields`.

Without it the move into «جاهزة» would demand a warehouse and then throw `VariantHasNoStockItem` —
and it would be right to: a وسيط size points at no shelf, correctly.

---

## 5. The vendor

`orders.vendor_id` (nullable, restrict on delete) and `orders.vendor_name`, snapshotted the way
`city_name` and `customer_shop_name` already are: a vendor renamed next year must not rewrite an
order taken this year.

**Chosen, never typed** — `exists:vendors,id` withoutTrashed, from the list the purchase-order
screens already pick from.

**Required by the domain, not by the request.** Whether a vendor is owed depends on the flow, and
the flow is not known until the lines exist — `ResolveOrderFlow` runs after them. So `CreateOrder`
resolves the flow and then throws `OutsourcedOrderNeedsAVendor` («الطلبية الوسيطة تحتاج مورداً»)
inside the same transaction: an order that should have named a vendor never lands half-taken.

**On the order, not the line.** The road is already an all-or-nothing property of the order, and
the requirement names one vendor per order. An order needing two vendors is two orders. If that
turns out to be wrong, `order_items.vendor_id` is the change, and it is a bigger one.

---

## 6. The cost, from the catalogue to the P&L

Two columns on the line: `unit_cost` — the copy of `product_variants.cost_price` as it stood the
day the order was taken — and `outsourcing_cost`, what the line cost in total.

**`unit_cost` is written by the action, never by the request**, the same treatment `unit_price`
gets. It is force-filled by `AddOrderItem`/`SyncOrderItems` from the variant. **This is the whole
of «تغيير تكلفة المنتج لاحقاً لا يغيّر تكلفة الطلبات السابقة»**: the line keeps the number it was
taken at, because nothing ever reads the catalogue for it again.

**Snapshotted at intake, recognised at «جاهزة».** `ApplyOutsourcingCosts` writes
`outsourcing_cost = unit_cost × chargedQuantity` from the hook `ChangeOrderStatus` already runs
when an order first reaches ready — the same moment `ApplyManufacturingRates` fires for a printed
order. Cost is recognised when the goods exist, so an order cancelled on the vendor's bench does
not report a cost it never incurred, and a shortage-reduced quantity is costed at what was actually
delivered.

`RecalculateOrderItemCost` gains it as a fourth component, and its "null until `material_cost`"
guard becomes "null until material **or** outsourcing cost". An outsourced line never touches a
shelf, so `material_cost` stays null on it forever and the old guard would leave `cogs` null and
the P&L blind to the one cost this feature exists to record. `RecalculateOrderCogs` needs no
change: it sums whatever the lines know.

**Cancellation leaves it standing**, exactly as it leaves `material_cost` standing —
`ReverseOrderStockDeduction` says why: the cost columns are the historical record of what the work
actually cost before the order was written off, and the reversal is a separate accounting event
rather than a rewrite of what happened. Nothing special is needed for the وسيط road: an order
written off before «جاهزة» never had a cost recognised in the first place.

**And the clerk does not see any of it.** `order_items.unit_cost` and `outsourcing_cost` sit behind
`products.view_cost` in `OrderItemResource` — the same grant that guards the catalogue number they
were copied from, because hiding a figure on one screen and sending it on another is a lock on one
door of two.

---

## 7. Are orders taken before this affected?

**No.** Seven reasons, each a fact about the code rather than an intention:

1. **The road is a snapshot.** `production_flow` is stamped at intake and `ResolveOrderFlow`
   re-reads it only while the order is «جديدة». Every existing order keeps the road it was taken
   on; the third one is unreachable for them.
2. **No constraint stands in the way of a new status.** `orders.status` is `string(30)` with no
   CHECK and no PostgreSQL enum type, so `manufacturing` needs no data migration and invalidates
   no row.
3. **The two existing arms do not move.** The `match` is reorganised into three; `standard` and
   `no_production` come out identical, and a test pins both roads so a progress bar on an
   in-flight order cannot shift under it.
4. **Every new column is nullable** — `orders.vendor_id`, `orders.vendor_name`,
   `orders.manufacturing_started_at`, `order_items.unit_cost`, `order_items.outsourcing_cost`,
   `product_variants.cost_price`. Null on an old row means what it should: this never applied here.
5. **COGS is arithmetically unchanged.** The relaxed guard is an `||`; with `outsourcing_cost` null
   on every existing line, `cogs` and `orders.total_cogs` compute exactly as before — and nothing
   recomputes them on a closed order anyway.
6. **Stock deduction is untouched.** `deductsStock()` answers true for both existing roads.
7. **Nothing is taken away from a payload.** `cost_price` is new, so hiding it behind a permission
   removes no key anyone is reading today.

The one migration that rewrites existing rows is the category one, and it preserves behaviour by
construction — `ProductionModeMigrationTest` asserts it row for row.

Two things change on screens without any order changing:

- The home board gains a «قيد التصنيع» card reading zero, because `HomeSummaryResource` maps
  `OrderStatus::cases()` and the app draws a card per row. That is the design: a status added to
  the business appears there without an app release.
- `GET /orders/counts` gains a `manufacturing: 0` key, which the app holds in a map keyed by wire
  value and tolerates by construction.

And one thing genuinely lost, small and worth writing down: a category-history entry written
*before* this migration names `skips_production`, and that word is no longer in
`AuditAttributeLabels` — `AuditAttributeLabelsTest` refuses a label for a column that no longer
exists, on the grounds that the real column then goes out unlabelled instead. Those old rows draw
as the raw column name, which is what every unlabelled column has always done. Nothing after the
migration is affected: `production_mode` is labelled «طريقة التنفيذ».

---

## 8. What the shipped app needs, and what keeps it alive until then

The Flutter build in people's hands **writes** `skips_production` when a category is saved and
**reads** it on the category card («بدون طباعة»). Renaming the column without keeping the key
would break a screen in production, so:

- `ProductCategoryResource` keeps emitting `skips_production` as a derived, read-only alias
  (`production_mode !== in_house`) beside the new `production_mode`.
- Both category requests keep accepting `skips_production` — `true → none`, `false → in_house` —
  and `production_mode` wins when both arrive.
- **The trap:** an old build editing a وسيط category sends `skips_production: false` and would
  demote it to `in_house`. So `skips_production` is *ignored* when the stored mode is `outsourced`
  and no `production_mode` was sent. A test pins it.

Everything else added here is additive — `production_mode`, `cost_price`, `vendor_id`,
`vendor_name` — and an app that does not know a key ignores it.

**Two things the backend cannot do alone**, stated so nobody discovers them later:

1. A وسيط order needs `vendor_id`, and the shipped app does not send it. Outsourced orders are
   creatable through the API and refused from the current build, in Arabic. The feature is
   installed, not yet reachable from the phone.
2. `order_status_contract_test.dart` and `permission_contract_test.dart` read these PHP enums case
   for case and go red the moment `manufacturing` and the two permissions land. The fix is three
   lines in two Dart enums — not app work, but it has to happen or that suite stays failing.

When the app is picked up: a cost box per size on the product form, shown only for an outsourced
category and only to a holder of `products.view_cost`; a vendor row on the new-order form using the
existing `vendor_picker_sheet`; المورد on the order screen. The status screen needs nothing — it
draws whatever `available_transitions` describes.

---

## 9. Two decisions worth revisiting if the business disagrees

- **One vendor per order.** §5. Per-line is `order_items.vendor_id` and a picker per line.
- **Cost per size, not per product.** §3. If every وسيط product turns out to have exactly one
  size, a single column on `products` would be simpler — but it cannot be compared with a price
  that is per size.
