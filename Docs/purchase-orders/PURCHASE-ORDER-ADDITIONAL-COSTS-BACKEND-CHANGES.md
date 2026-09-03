# Purchase order additional costs & line proportioning — backend changes

> **Implemented.** Everything below is what was actually built — schema, domain layer, API. Backend
> only — nothing in `frontend/` was touched. See
> [PURCHASE-ORDER-ADDITIONAL-COSTS-FRONTEND-INTEGRATION.md](PURCHASE-ORDER-ADDITIONAL-COSTS-FRONTEND-INTEGRATION.md)
> for wiring the app up to this.
>
> Companion docs: [PURCHASE-ORDERS-DESIGN.md](PURCHASE-ORDERS-DESIGN.md),
> [VENDORS-AND-PURCHASE-ORDERS.md](../vendors/VENDORS-AND-PURCHASE-ORDERS.md), and
> [COST-TRACKING-UNIT-CONVERSION.md](../costing/COST-TRACKING-UNIT-CONVERSION.md) §2, which this work
> supersedes for purchase order line costing (see §7 below).

---

## 1. Why

A purchase order line previously carried a **per-unit** cost (`unit_cost`), with `total_cost`
derived from it, and the order's `total_amount` was just the line totals summed. There was no way
to record costs that belong to the whole order rather than one line — delivery, unloading,
customs — and no notion of a landed per-unit cost that includes a share of those.

This change:

1. Inverts the line input — a line is now priced by its **total** base cost, with the per-unit
   figure derived server-side.
2. Adds a dynamic, order-level list of named additional costs.
3. Distributes their sum across lines proportional to each line's share of the order's base cost,
   producing a **final unit cost** per line that includes its allocated share.
4. Feeds that final (landed) unit cost into inventory costing when a shipment is received, so
   delivery/customs/unloading actually lands in FIFO stock valuation and COGS — the reason this
   kind of feature exists.

---

## 2. Database

**New table `purchase_order_additional_costs`**

| Column | Type | Notes |
|---|---|---|
| `purchase_order_id` | FK → `purchase_orders`, `cascadeOnDelete` | |
| `name` | string | `"Delivery"`, `"Customs"`, `"Unloading"`, ... |
| `amount` | `decimal(14,2)`, CHECK `>= 0` | |
| `timestamps` + `deleted_at` | | soft delete + audit trail, same as every table in this schema |

Synced wholesale on `PUT /purchase-orders/{id}` the same way `purchase_order_items` already is:
an entry carrying an `id` updates that cost, one without creates a new one, any existing cost
missing from the set is removed.

**`purchase_order_items`** — `unit_cost`/`total_cost` **replaced** (not kept alongside) with five
columns, because their meaning inverts:

| Column | Type | Meaning |
|---|---|---|
| `base_total_cost` | `decimal(14,2)`, CHECK `>= 0` | **Input.** What this line costs before additional costs — replaces `unit_cost` as the thing a caller types. |
| `base_unit_cost` | `decimal(12,3)`, CHECK `>= 0` | Derived: `base_total_cost / quantity_ordered`. |
| `allocated_additional_cost` | `decimal(14,2)`, CHECK `>= 0` | Derived: this line's proportional share of the order's additional costs. |
| `final_unit_cost` | `decimal(12,3)`, CHECK `>= 0` | Derived: `(base_total_cost + allocated_additional_cost) / quantity_ordered` — the **landed cost**. |
| `final_total_cost` | `decimal(14,2)`, CHECK `>= 0` | Derived: `base_total_cost + allocated_additional_cost`. |

All five nullable, the same reasoning the columns they replace carried: a line predating this
feature has nothing to backfill them with.

**`purchase_orders`** — one column added: `total_additional_cost` (`decimal(14,2)`, nullable,
CHECK `>= 0`), the sum of the order's additional costs. `total_amount` keeps its existing role
(nullable, an order's grand total) but now sums each line's `final_total_cost` instead of the old
`total_cost`, so it is already inclusive of additional costs.

Three migrations, forward-only, each with a real `down()`:

- `2026_08_13_100000_create_purchase_order_additional_costs_table.php`
- `2026_08_13_100100_replace_cost_columns_on_purchase_order_items_table.php`
- `2026_08_13_100200_add_total_additional_cost_to_purchase_orders_table.php`

---

## 3. Allocation algorithm

New Action: `App\Domain\PurchaseOrder\Actions\AllocatePurchaseOrderAdditionalCosts`. Runs after a
purchase order's lines and additional costs are both persisted (on create and on update), before
`RecalculatePurchaseOrderTotal` sums the result into the order's own totals.

1. `total_additional_cost` = sum of the order's additional-cost amounts (`0.00` if none).
2. `sum_base_cost` = sum of every line's `base_total_cost`.
3. Each line's weight = `base_total_cost / sum_base_cost`.
4. **Edge case — every line free:** if `sum_base_cost` is `0` and there is still something to
   distribute, the additional costs are split **equally** across lines instead of by an undefined
   proportion.
5. Allocation is done in integer cents, entirely through bcmath (never a float), using the
   **largest-remainder method** (Hamilton's method): each line's raw share is floored, then the
   leftover cents — the difference between the sum of the floors and the true total — are handed
   out one at a time to the lines with the largest remainder, ties broken by line id ascending.
   This guarantees the allocated shares always sum to *exactly* the additional-costs total; a
   naive per-line round would leave them a cent short or over on almost any order with more than
   one line.
6. `base_unit_cost`, `allocated_additional_cost`, `final_unit_cost`, `final_total_cost` are then
   computed per line and written via `forceFill` — never client-supplied, the same treatment
   `total_cost`/`unit` got before this feature existed.

`RecalculatePurchaseOrderTotal` was updated to sum `final_total_cost` (→ `total_amount`) and the
additional-cost amounts (→ `total_additional_cost`) — still the one place that decides what a
purchase order is planned to cost.

`App\Domain\PurchaseOrder\Support\Money` gained `roundTo(string $value, int $scale): string`
(the existing `round()` now just calls `roundTo($value, self::SCALE)`), needed to round
`base_unit_cost`/`final_unit_cost` to three decimal places instead of two.

---

## 4. Landed cost into inventory

`ReceivePurchaseOrder` now reads a line's **`final_unit_cost`** (was `unit_cost`) when building
the `StockArrivalItemData` for a shipment received against the order. So a shipment's landed cost
— and the FIFO stock batch it opens — includes the order's allocated delivery/customs/unloading
share, not just the vendor's quoted base price. This only affects receipts made **through a
purchase order** (`POST /purchase-orders/{id}/arrivals`); the generic `POST /stock-arrivals`
endpoint is untouched and still never carries a cost.

---

## 5. API changes

`POST /purchase-orders` and `PUT /purchase-orders/{id}` — request body:

- `items.*.unit_cost` → **`items.*.base_total_cost`** (required, `numeric`, `gte:0`). This is a
  breaking rename, not an addition — the field it replaces no longer exists.
- New, optional `additional_costs`: `[{ id?, name, amount }]`. Absent or empty means "no
  additional costs." On `PUT`, this follows the exact same "send the whole current set every
  time" contract `items` already does — an entry with an `id` updates that cost, one without
  creates a new one, any existing cost missing from the set is removed.

`PurchaseOrderItemResource` — `unit_cost`/`total_cost` replaced with `base_total_cost`,
`base_unit_cost`, `allocated_additional_cost`, `final_unit_cost`, `final_total_cost` (all
string-cast decimals, null only on a line predating cost tracking).

`PurchaseOrderResource` — added `total_additional_cost` and `additional_costs` (an array of
`{ id, name, amount }`, present when the relation is eager-loaded — every read path in this
codebase now loads it).

`POST /purchase-orders/{id}/arrivals` response (`StockArrivalResource`) is unchanged in shape;
only the *value* of `data.items.*.unit_cost`/`total_cost` on it now reflects the landed cost when
the order carried additional costs.

New 422: **`PurchaseOrderAdditionalCostDoesNotBelongToOrder`** — an update names an
`additional_costs.*.id` that isn't one of the order's own, `errors.additional_costs`, same shape
as the existing `PurchaseOrderItemDoesNotBelongToOrder`.

Full worked example (create):

```jsonc
// POST /purchase-orders
{
  "vendor_id": 3, "warehouse_id": 5, "order_date": "2026-08-13",
  "items": [
    { "product_variant_id": 14, "quantity_ordered": 4, "base_total_cost": 75 },
    { "product_variant_id": 22, "quantity_ordered": 6, "base_total_cost": 25 }
  ],
  "additional_costs": [
    { "name": "Delivery", "amount": 10 },
    { "name": "Customs", "amount": 3 }
  ]
}
```

```jsonc
// 201 — data
{
  "total_amount": "113.00", "total_additional_cost": "13.00",
  "additional_costs": [
    { "id": 1, "name": "Delivery", "amount": "10.00" },
    { "id": 2, "name": "Customs", "amount": "3.00" }
  ],
  "items": [
    {
      "product_variant_id": 14, "quantity_ordered": "4.000",
      "base_total_cost": "75.00", "base_unit_cost": "18.750",
      "allocated_additional_cost": "9.75",         // 75% of 13.00
      "final_total_cost": "84.75", "final_unit_cost": "21.188"
    },
    {
      "product_variant_id": 22, "quantity_ordered": "6.000",
      "base_total_cost": "25.00", "base_unit_cost": "4.167",
      "allocated_additional_cost": "3.25",          // 25% of 13.00
      "final_total_cost": "28.25", "final_unit_cost": "4.708"
    }
  ]
}
```

---

## 6. Where the code lives

```
backend/app/Domain/PurchaseOrder/
├── Models/PurchaseOrderAdditionalCost.php                 (new)
├── DTOs/PurchaseOrderAdditionalCostData.php                (new)
├── Actions/AllocatePurchaseOrderAdditionalCosts.php        (new)
├── Exceptions/PurchaseOrderAdditionalCostDoesNotBelongToOrder.php  (new)
├── Models/PurchaseOrder.php          — additionalCosts() relation, total_additional_cost cast
├── Models/PurchaseOrderItem.php      — new fillable/casts
├── DTOs/PurchaseOrderItemData.php    — unitCost → baseTotalCost
├── DTOs/PurchaseOrderData.php        — + additionalCosts
├── Actions/CreatePurchaseOrder.php   — + additional-cost rows, calls Allocate then Recalculate
├── Actions/UpdatePurchaseOrder.php   — + syncAdditionalCosts()
├── Actions/RecalculatePurchaseOrderTotal.php  — sums final_total_cost + additional costs
├── Actions/ReceivePurchaseOrder.php  — reads final_unit_cost, not unit_cost
└── Support/Money.php                 — + roundTo(value, scale)

backend/app/Domain/Audit/Enums/AuditSubject.php  — registers PurchaseOrderAdditionalCost
backend/app/Application/Api/V1/
├── Requests/PurchaseOrder/Store…/Update…  — base_total_cost + additional_costs validation
├── Resources/PurchaseOrderAdditionalCostResource.php   (new)
├── Resources/PurchaseOrderItemResource.php, PurchaseOrderResource.php
└── Controllers/PurchaseOrderController.php  — eager-loads additionalCosts on show()

backend/database/
├── migrations/2026_08_13_100000…, 100100…, 100200…   (3 new, see §2)
├── factories/PurchaseOrderAdditionalCostFactory.php  (new)
└── factories/PurchaseOrderItemFactory.php            — updated definition
```

No route or controller signature changes — additional costs travel through the existing
`POST`/`PUT /purchase-orders` payloads, same lifecycle items already have (editable only while
`status = new`).

---

## 7. Relationship to COST-TRACKING-UNIT-CONVERSION.md §2

That doc describes the original `unit_cost`/`total_cost` columns this change replaces. Its
worked examples and column table for `purchase_order_items` cost fields are superseded by §2–§5
above; everything else in that doc (units of measurement, order fulfilment stock deduction) is
unaffected.

---

## 8. Tests

`tests/Feature/Api/V1/PurchaseOrderTest.php` — the "cost & unit tracking" section was rewritten
and extended (52 tests in the file total, up from the previous count). New coverage:

- Line cost inversion: `base_total_cost` in, `base_unit_cost` derived, required on create.
- Proportional distribution across lines with unequal shares (exact percentages).
- The largest-remainder guarantee: three equal-weight lines splitting a total that doesn't divide
  evenly by three — asserts the shares still sum to *exactly* the additional-costs total.
- A single-line order receives 100% of the additional costs.
- The zero-base-cost equal-split fallback.
- Updating additional costs by `id` (in place, not duplicated) recomputes allocation.
- Sending an empty/absent `additional_costs` on update clears allocation back to base and
  soft-deletes the removed cost rows.
- Validation: `additional_costs.*.name` required, `.amount` non-negative.
- `PurchaseOrderAdditionalCostDoesNotBelongToOrder` on an update naming another order's cost id.
- Receiving a shipment carries the **landed** unit cost (base + allocated share) onto the stock
  arrival item — both the no-additional-costs case (unchanged behaviour) and the with-additional-
  costs case (new).

Verified locally (Postgres, `APP_ENV=local`): all three migrations applied and rolled back
cleanly; `PurchaseOrderTest` (52/52), `ModelConventionsTest` (6/6 — confirms the new model is
soft-deleting, audited, and morph-mapped), `StockArrivalTest` (14/14 — confirms the landed-cost
change to `ReceivePurchaseOrder` doesn't break the generic arrival path), and the full backend
suite (1057/1057) all pass.

---

## 9. Compatibility note

This is a breaking change to the request/response contract described in §5 — there is no
backward-compatible shim, per the task that requested this work. Separately, and worth flagging
for whoever picks up the frontend side: the **current** Flutter purchase-orders feature does not
send any cost field at all today (`PurchaseOrderLine.toJson()` only sends `id`,
`product_variant_id`, `quantity_ordered` — see its own docblock, which still describes the
original "no money on a purchase order" design from `VENDORS-AND-PURCHASE-ORDERS.md`). Both the
old `unit_cost` and the new `base_total_cost` are server-required, so creating a purchase order
through the live app fails validation regardless of this change — see the companion frontend
integration doc for what needs adding, not just renaming.
