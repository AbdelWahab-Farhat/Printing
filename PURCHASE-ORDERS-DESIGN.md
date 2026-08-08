# Purchase Orders — backend changes

> **Implemented.** Everything below is what was actually built — schema, domain layer, API,
> permissions, and the link into Vendors/StockArrivals. Nothing here is a proposal.
>
> Companion doc: [PURCHASE-ORDERS-FRONTEND-INTEGRATION.md](PURCHASE-ORDERS-FRONTEND-INTEGRATION.md)
> for wiring the Flutter app up to this.

---

## 1. Why

Every stock arrival today is unplanned — nothing records that an order was *placed* with a
vendor before it shows up. Purchase Orders close that gap: a document that says what was
ordered, tracks how much of it has actually arrived (partial shipments included), and
automatically reconciles itself the moment a shipment is posted against it.

---

## 2. The lifecycle

```
new ──────► arrived ──────► completed
 │             │
 └────────► cancelled ◄──────┘
```

| Status | Meaning | Reached by |
|---|---|---|
| `new` | Just created. The only status a PO may still be edited in (`PUT`). | `POST /purchase-orders` |
| `arrived` | In motion — sent to the vendor, or partway received. Deliberately covers both "awaiting the vendor" and "some lines partially received"; there is no separate `partially_received` case. | `PATCH .../status` (`arrived`), or automatically the moment the first shipment posts against a `new` order |
| `completed` | Every line's `quantity_received >= quantity_ordered`. Final. | Only by receiving — **never a manual target** |
| `cancelled` | Written off. Final. | `PATCH .../status` (`cancelled`), from `new` or `arrived` only |

Enforced centrally in `PurchaseOrderStatus::allowedNext()` — nothing else holds an opinion about
what follows what.

---

## 3. Database

**`purchase_orders`**

| Column | Type | Notes |
|---|---|---|
| `vendor_id` | FK → `vendors`, `cascadeOnDelete` | |
| `warehouse_id` | FK → `warehouses`, nullable, `nullOnDelete` | nullable at the DB level only (a warehouse can be deleted once empty); **required** by the create/update request |
| `status` | string, default `new`, indexed | backed by `PurchaseOrderStatus` |
| `order_date` | date | |
| `expected_date` | date, nullable | |
| `notes` | text, nullable | |
| `timestamps` + `deleted_at` | | soft delete + audit trail, same as every model in this schema |

**`purchase_order_items`**

| Column | Type | Notes |
|---|---|---|
| `purchase_order_id` | FK, `cascadeOnDelete` | |
| `product_variant_id` | FK, `cascadeOnDelete` | |
| `quantity_ordered` | `decimal(12,3)`, CHECK `> 0` | |
| `quantity_received` | `decimal(12,3)`, default `0`, CHECK `>= 0` | only ever incremented by `ReceivePurchaseOrder` |
| `timestamps` + `deleted_at` | | |

**`stock_arrivals`** — one column added:

| Column | Type | Notes |
|---|---|---|
| `purchase_order_id` | FK → `purchase_orders`, nullable, `nullOnDelete` | null for the (majority) of arrivals that were never ordered ahead of time |

---

## 4. The API

Base path `/api/v1`, same envelope and pagination as every other endpoint (`{status, message,
data}`, `meta` on lists).

| Verb | Path | Permission | Notes |
|---|---|---|---|
| `GET` | `/purchase-orders` | `purchase_orders.view` | filter with `vendor_id`, `warehouse_id`, `status` |
| `POST` | `/purchase-orders` | `purchase_orders.manage` | creates a `new` order with its lines |
| `GET` | `/purchase-orders/{id}` | `purchase_orders.view` | |
| `PUT` | `/purchase-orders/{id}` | `purchase_orders.manage` | only while `new` — 422 otherwise. Lines are replaced wholesale (see §6) |
| `PATCH` | `/purchase-orders/{id}/status` | `purchase_orders.manage` | body: `{"status": "arrived"}` or `{"status": "cancelled"}` — nothing else is accepted here |
| `POST` | `/purchase-orders/{id}/arrivals` | **`inventory.manage`** | receives a shipment against the order — see §5 |
| `GET` | `/purchase-orders/{id}/logs` | `logs.view` | audit trail, includes the lines |

### Response shapes

`PurchaseOrderResource`:

```json
{
  "id": 12,
  "vendor_id": 3,
  "vendor": { "id": 3, "name": "..." },
  "warehouse_id": 5,
  "warehouse": { "id": 5, "name": "..." },
  "status": "arrived",
  "status_label": "قيد الاستلام",
  "order_date": "2026-08-08",
  "expected_date": "2026-08-15",
  "notes": null,
  "items": [ /* PurchaseOrderItemResource[] */ ],
  "created_at": "2026-08-08T12:00:00+00:00",
  "updated_at": "2026-08-08T12:00:00+00:00"
}
```

`PurchaseOrderItemResource`:

```json
{
  "id": 40,
  "product_variant_id": 14,
  "product_variant": { "id": 14, "label": "34*44", "product_id": 14, "product_code": "P14", "product_name": "..." },
  "quantity_ordered": "10.000",
  "quantity_received": "4.000",
  "quantity_remaining": "6.000"
}
```

`POST .../arrivals` does **not** return a `PurchaseOrderResource`. It returns the created
`StockArrivalResource` (identical shape to `POST /stock-arrivals`), now carrying
`purchase_order_id`. Re-fetch `GET /purchase-orders/{id}` to see the order's own updated status
and line totals.

---

## 5. Receiving a shipment — the important part

`POST /purchase-orders/{id}/arrivals` — body:

```json
{
  "invoice_number": "INV-2001",
  "notes": null,
  "items": [
    { "product_variant_id": 14, "quantity": 10 }
  ]
}
```

No `vendor_id`/`warehouse_id` — both come from the order itself. `received_by` is stamped from
the authenticated user, never accepted in the body.

What happens, in one transaction:

1. Refused (422) if the order is `completed` or `cancelled`.
2. Every line is checked *before* anything is written: a `product_variant_id` not on the order
   is refused, and a line whose running total would exceed `quantity_ordered` is refused —
   nothing partially lands.
3. The shipment is posted through the exact same path `POST /stock-arrivals` uses
   (`VendorService::recordStockArrival()` → `InventoryService::recordMovement()`), so the
   warehouse balance and `stock_movements` ledger move exactly as they always have.
4. Each line's `quantity_received` is incremented.
5. The order's status is recomputed: every line fully received → `completed`; otherwise →
   `arrived`. A `new` order can jump straight to `completed` in one shipment.

**Guarded by `inventory.manage`, not `purchase_orders.manage`.** Deliberate: posting a shipment
is squarely inventory's job, the same reasoning that already guards `POST /stock-arrivals`. A
user who can only draft/send/cancel purchase orders cannot post stock against them, and vice
versa — the two are genuinely separate jobs on the frontend's permission model too.

---

## 6. Editing (`PUT`) — line replacement semantics

Only legal while `status = new`. The whole line set is replaced from what's sent:

- A line with an `id` → updates that line (quantity, and its variant).
- A line without an `id` → creates a new line.
- An existing line **missing** from the payload → removed.

Same contract `shops[]` uses on the customer endpoint. Send the *entire* current set every time,
not a diff.

---

## 7. Permissions

Two new cases in `PermissionName`:

| Value | Label | Group |
|---|---|---|
| `purchase_orders.view` | عرض أوامر الشراء | أوامر الشراء |
| `purchase_orders.manage` | إنشاء وتعديل أوامر الشراء وإرسالها وإلغاؤها | أوامر الشراء |

Receiving reuses the **existing** `inventory.manage`/`inventory.view` pair — no new permission
for it.

---

## 8. Where the code lives

```
backend/app/Domain/PurchaseOrder/
├── Models/PurchaseOrder.php, PurchaseOrderItem.php
├── Enums/PurchaseOrderStatus.php
├── DTOs/PurchaseOrderData.php, PurchaseOrderItemData.php,
│        ReceivePurchaseOrderData.php, ReceivePurchaseOrderItemData.php
├── Exceptions/  (6 domain exceptions — all 422, all Arabic messages)
├── Actions/CreatePurchaseOrder.php, UpdatePurchaseOrder.php, SendPurchaseOrder.php,
│           CancelPurchaseOrder.php, ReceivePurchaseOrder.php
├── Queries/PurchaseOrderFilters.php, PurchaseOrderListQuery.php
└── PurchaseOrderService.php        ← the only door other code should use

backend/app/Application/Api/V1/
├── Controllers/PurchaseOrderController.php
├── Requests/PurchaseOrder/  (Store, Update, ChangeStatus, ReceivePurchaseOrderArrival)
└── Resources/PurchaseOrderResource.php, PurchaseOrderItemResource.php
```

**Dependency direction: `PurchaseOrder` depends on `Vendor`, never the reverse.**
`ReceivePurchaseOrder` calls `VendorService::recordStockArrival()`; `Vendor`'s own models have no
relation pointing back at `PurchaseOrder` (that would close a dependency loop). The convenience
relation for "every shipment against this order" lives on `PurchaseOrder::stockArrivals()`
instead — the side that's already allowed to know about the other.

Touched (not created) in the Vendor context: `StockArrivalData` gained an optional
`purchaseOrderId` (always null through the generic `POST /stock-arrivals` endpoint — only
`ReceivePurchaseOrder` ever sets it), `RecordStockArrival` writes the column, and
`StockArrivalResource` now exposes `purchase_order_id`.

---

## 9. Tests

`tests/Feature/Api/V1/PurchaseOrderTest.php` — 37 tests, full CRUD/status/receiving matrix
including the permission split in §5, over-receipt, receiving an unordered variant, and the
document+ledger+balance triple-check on every successful receive. Two tests added to
`StockArrivalTest.php` confirming the generic endpoint never accepts a client-supplied
`purchase_order_id`.
