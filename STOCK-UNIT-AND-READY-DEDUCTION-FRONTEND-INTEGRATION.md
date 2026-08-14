# Settable stock unit, and fulfilment moved to «جاهزة» — connecting the Flutter app

> **Status: not yet started.** Nothing in `frontend/` has been touched. This is a plan for
> wiring the app up to
> [STOCK-UNIT-AND-READY-DEDUCTION-BACKEND-CHANGES.md](STOCK-UNIT-AND-READY-DEDUCTION-BACKEND-CHANGES.md),
> written after surveying the current code (§0) so it names real files rather than guessing at
> the shape. Unlike a rename or a new required field, one half of this (§2) needs **no app change
> at all** — read that section first, it may be the only one that matters for a quick pass.

---

## 0. What the app already does, and doesn't

Surveyed before writing this doc, so the plan below is against the real code, not an assumption:

- **The order-status screen is already fully server-driven.** `order_status_page.dart` and
  `order.dart` both say so in their own doc comments — the screen "holds no state machine" and
  draws every transition's fields purely from `available_transitions[].fields` in the API
  response. `transition_field_input.dart` dispatches on `field.type` alone, with no per-status
  branching anywhere. Confirmed by a repo-wide search: nothing references
  `moveOrderToPrinting`/`moveOrderToReady` (the two client-side permission-enum values that exist
  for role-management screens) to gate *where* the warehouse picker appears.
- **One stale doc comment exists**, not a functional problem:
  `lib/features/orders/models/transition_field.dart`, on `TransitionFieldType.warehouse`, currently
  reads *"Asked on the way into «قيد الطباعة» (printing), and required exactly once."* That's the
  old behaviour — worth a one-line fix for accuracy (§2), but the screen doesn't act on that
  comment, only on what the API actually sends.
- **The product form has no stock-unit concept at all** — `pricing_unit` is the only unit picked
  anywhere (`product_form_page.dart` lines ~453-459), and `NewProduct`/`Product` carry only
  `pricingUnit`/`pricingUnitLabel`. This half is genuinely new UI (§3-§5).

---

## 1. What the server now returns/expects

### Product resource — two new fields

```jsonc
{
  "id": 14,
  "pricing_unit": "piece", "pricing_unit_label": "قطعة",
  "stock_unit": "kilogram", "stock_unit_label": "كيلوغرام",   // new
  …
}
```

`stock_unit`/`stock_unit_label` are present on every product response now (never null — every
product has one, defaulting to `pricing_unit` if never set otherwise). Same string-enum shape
`pricing_unit`/`pricing_unit_label` already have.

### Product create — one new optional field

`POST /products` (multipart) accepts an optional `stock_unit` alongside the existing
`pricing_unit`. **Omit it and the server defaults it to whatever `pricing_unit` was sent** — so
if the stock-unit picker described in §3 is skipped for a first pass, nothing breaks; every
product just keeps `stock_unit == pricing_unit`, exactly today's behaviour.

### Product update — unchanged, and deliberately so

`PUT /products/{id}` still has no `stock_unit` field, and sending one is simply ignored
server-side. Changing a product's stock unit after creation goes through the endpoint below,
never the product-edit form.

### New endpoint — correcting/declaring the stock unit

```
PATCH /api/v1/products/{product}/stock-unit
Body: { "unit": "kilogram" }        // "piece" | "kilogram"
→ 200, data: the full product resource, refreshed
```

Requires the `inventory.manage` permission (not `products.manage` — same split the app's
permission enum already models, since this is an inventory fact about the product). Cascades
server-side to every warehouse balance and cost batch for the product's variants — nothing for
the client to reconcile afterwards beyond refetching the product (and, if displayed, its
warehouse-stock list).

### Order status transitions — no shape change, only *which* transition carries the field

`available_transitions[].fields` for the `ready` transition now includes a `warehouse_id` field
(type `warehouse`) alongside the pre-existing `weight_kg`, with the exact same
required/hint semantics the `printing` transition used to carry:

```jsonc
// GET /orders/{id} → data.available_transitions, entry for status: "ready"
{
  "status": "ready",
  "fields": [
    {
      "key": "warehouse_id", "type": "warehouse", "label": "المخزن",
      "required": true,   // false once stock_deducted_at is already set
      "hint": "يُخصم منه ما تستهلكه هذه الطلبية من المخزون"
    },
    { "key": "weight_kg", "type": "number", "label": "الوزن (كجم)", … }
  ]
}
```

The `printing` transition's `fields` no longer includes `warehouse_id` at all — only whatever
artwork field it already carried.

---

## 2. Fulfilment timing — verify, don't build

Because the screen renders `fields` generically, **this should already work with zero code
changes**: the warehouse picker will simply appear on the «جاهزة» step of the transition form
instead of «قيد الطباعة», automatically, the next time the app talks to the updated API.

What to actually do:

1. Fix the stale comment in `lib/features/orders/models/transition_field.dart` on
   `TransitionFieldType.warehouse` — it names «قيد الطباعة» as where this is asked; say «جاهزة»
   instead, so the next person reading it isn't misled.
2. **Manual QA pass**, since this is a real behaviour change for anyone using the app day to day:
   walk an order from «جديدة» through «قيد الطباعة» to «جاهزة» and confirm the warehouse picker
   now appears at the right step, is required exactly once, and the order actually shows stock
   deducted (`stock_deducted_at`, `fulfillment_warehouse_id` on the order detail) after that move
   — not after entering printing.
3. Check any screen that reads `order.stockDeductedAt`/`fulfillmentWarehouseId` (if the detail
   page shows them) for copy that assumes "deducted when printing started" — e.g. a label or
   tooltip explaining the field, not the data itself.
4. If the progress/timeline screen (`order_status_page.dart` mentions a "steps" concept per the
   backend's own docs) has any copy describing what happens at each stage, check it doesn't say
   stock leaves the warehouse at «قيد الطباعة».

No model, repository, or usecase change needed for this part.

---

## 3. Model changes — stock unit

`lib/features/products/models/product.dart`:

```dart
@freezed
abstract class Product with _$Product {
  const factory Product({
    // … existing fields …
    @JsonKey(name: 'pricing_unit') required String pricingUnit,
    @JsonKey(name: 'pricing_unit_label') required String pricingUnitLabel,

    // New — always present, defaults to pricing_unit server-side until explicitly changed.
    @JsonKey(name: 'stock_unit') required String stockUnit,
    @JsonKey(name: 'stock_unit_label') required String stockUnitLabel,
    // … rest unchanged …
  }) = _Product;
}
```

`lib/features/products/models/new_product.dart` (the create-payload model):

```dart
@JsonKey(name: 'pricing_unit') required String pricingUnit,

/// Optional. Omit to let the server default it to [pricingUnit] — the common case, where
/// what's stocked and what's sold agree.
@JsonKey(name: 'stock_unit', includeIfNull: false) String? stockUnit,
```

Reuse the existing `PricingUnit` enum (`lib/features/products/models/pricing_unit.dart`) for the
picker's value type — it already has `piece`/`kilogram`/`unknown`, `.choices`, and
`.fromWire()`/`.wire`; nothing new needed there.

Then `dart run build_runner build`.

---

## 4. Repository / usecase changes

`lib/features/products/repositories/product_repository_impl.dart` — `create()` already spreads
`product.toJson()` into the multipart body (line ~79-103), so adding `stockUnit` to
`NewProduct` is sufficient; no method-signature change needed there.

**New repository method** for the correction endpoint, alongside the existing product methods:

```dart
/// Declares what a product's stock is counted in — cascades server-side to every warehouse
/// balance and cost batch for the product's variants. Independent of pricing_unit.
Future<Either<Failure, Product>> setStockUnit(int productId, PricingUnit unit);
```

Implementation: `PATCH /products/$productId/stock-unit`, body `{'unit': unit.wire}`, decode the
returned product resource the same way `update()` does.

A small usecase/cubit wrapping it, matching whatever pattern the product-activation toggle
(`setActivation`-equivalent, if one exists client-side) already uses — same shape of action:
one field, one confirmation, refresh the product afterward.

---

## 5. UI

- **Product create form** (`product_form_page.dart`) — alongside the existing `pricing_unit`
  `_ChoiceRow` (lines ~453-459), add an optional second row for `stock_unit`, defaulting its
  selection to mirror whatever `pricing_unit` is currently selected (only diverging when the
  user explicitly picks something else) — matches the server's own default-to-`pricing_unit`
  behaviour, so the common case stays a zero-extra-tap flow. Consider a "storage differs from
  selling unit" toggle that reveals the second picker, rather than always showing two identical
  dropdowns — most products will never need this.
- **Product create form — quantity validation**: the existing min-quantity validator (line
  ~472-474) branches on `_unit == PricingUnit.piece` for whole-vs-decimal. That branch is about
  `min_order_quantity`, which is still governed by `pricing_unit` (selling), not `stock_unit` —
  **do not** repoint it at the new field.
- **Product edit form** — no `stock_unit` field at all (matches `UpdateProductRequest` not
  accepting it). If the edit screen shows `pricing_unit` read-only or editable today, `stock_unit`
  should be shown **read-only** there if shown at all, with an explicit "change stock unit"
  action (button/menu item) that calls the new endpoint from §4 through a small confirmation
  dialog — separate from the general product-edit save, mirroring how activation toggling is
  likely already its own action rather than a field on the edit form.
- **Product detail/list screens** — anywhere `pricing_unit_label` is shown, consider whether
  `stock_unit_label` is worth surfacing too (e.g. only when it differs from `pricing_unit_label`,
  to avoid cluttering the common case where they're the same).
- **Inventory/warehouse-stock screens**, if any show a per-line `unit`/`unit_label` today (the
  backend's `WarehouseStockResource` already exposes this, per COST-TRACKING-UNIT-CONVERSION.md
  §3) — no shape change there; the value now reflects `stock_unit` rather than `pricing_unit`,
  automatically, with no client code change required.

---

## 6. Suggested order

1. Manual QA the fulfilment-timing change (§2) — likely already works, cheapest to confirm first
   and unblocks nothing else.
2. Fix the stale `transition_field.dart` comment (§2.1) — trivial, do it in the same pass.
3. Model + repository changes (§3-§4) — mechanical, `build_runner` after.
4. UI (§5) — the only genuinely new feature surface; scope it down to "create form gets an
   optional second picker" first, and treat the edit-screen correction action as a fast follow if
   the create-time default (mirror `pricing_unit`) covers the immediate need.

Verify against the live contract if anything here is in doubt: run the backend and open
`http://localhost:8000/docs/api` — if this document disagrees with it, the spec is right.

---

Last updated: 2026-08-15.
