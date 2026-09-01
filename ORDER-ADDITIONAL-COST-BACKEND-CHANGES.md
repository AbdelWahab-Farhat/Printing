# Additional cost on an order — backend changes

> **Implemented.** Everything below is what was actually built — schema, domain layer, API, tests.
> **Backend only — nothing in `frontend/` was touched.** See
> [ORDER-ADDITIONAL-COST-FRONTEND-INTEGRATION.md](ORDER-ADDITIONAL-COST-FRONTEND-INTEGRATION.md)
> for wiring the app up to this.
>
> Companion docs: [ORDERS-DESIGN.md](ORDERS-DESIGN.md),
> [NEW-ORDER-DESIGN.md](NEW-ORDER-DESIGN.md),
> [ORDER-INVOICE-MESSAGE.md](ORDER-INVOICE-MESSAGE.md), and
> [PURCHASE-ORDER-ADDITIONAL-COSTS-BACKEND-CHANGES.md](PURCHASE-ORDER-ADDITIONAL-COSTS-BACKEND-CHANGES.md),
> which solves a similarly-named but **different** problem — see §8.

---

## 1. Why

An order could only ever be made *cheaper* than its products came to. There was `discount`, and
nothing going the other way — so a charge for special packaging, transport to somewhere the
delivery price does not cover, or a modification agreed after the fact had nowhere to live.
Staff were absorbing them, or folding them into a line's price, which put a number on the
invoice that disagreed with the catalogue.

The requested shape, in the brief's own worked example:

| Item | Value |
|---|---|
| قيمة المنتجات | 120 د.ل |
| التكلفة الإضافية | 10 د.ل |
| **إجمالي الطلب** | **130 د.ل** |

with an optional reason beside the figure, visible on the order, on the invoice and in the
accounts, and counted in what the customer is asked to pay.

**The brief's own closing note is the load-bearing constraint:** the discount and the additional
cost stay two separate figures and are never merged into one, so that any later movement in an
order's total can be read for what it was.

---

## 2. Database

One migration, forward-only, with a real `down()`:
`2026_09_01_100000_add_additional_cost_to_orders_table.php`

| Column | Type | Notes |
|---|---|---|
| `additional_cost` | `decimal(12,2)`, default `0`, after `discount` | Zero rather than nullable, for the reason `written_off_amount` is: nothing was ever charged on top of an existing order, and that is a fact we know rather than one we are missing |
| `additional_cost_reason` | `string(30)`, nullable | One of `AdditionalCostReason` — a **code**, not prose |
| `additional_cost_note` | `string(500)`, nullable | The words beside the code: «علبة كرتون مزدوجة» |

`decimal(12,2)` matches every other money column on `orders`, so the sum stays exact.

**Two decisions worth keeping:**

**A column of its own, never folded into `discount`.** The arithmetic would have allowed it — a
discount of −10 adds ten to the total just as well. It is refused because the two answer
different questions, and the question asked of an order months later is «لماذا تغيّر الإجمالي؟».
An answer of "the discount was −10" is a puzzle, not an answer.

**The reason is a code, not free text.** This is money the business collects, and the question
eventually asked of collected money is «كم حصّلنا مقابل التغليف هذا الربع؟». A hand-typed column
answers that with «تغليف»، «تغليف خاص»، «كرتون» and «تغليف!!» — one category in four spellings.
The code is also what keeps §8 open.

---

## 3. The reason

`App\Domain\Order\Enums\AdditionalCostReason` — a closed set, shaped exactly like `DesignSource`:

| Code | Label |
|---|---|
| `special_packaging` | تغليف خاص |
| `extra_service` | خدمة إضافية |
| `modification` | تعديل |
| `transport` | نقل |
| `other` | أخرى |

`label()` for display, `values()` for validation, and `needsNote()` — true for `Other` alone,
because «أخرى» on its own carries no information at all.

**Cast on `Order`, which is the whole of what translates it in the change history.**
`AuditValueLabels` derives from `casts()` rather than from a hand-kept dictionary, so the log
reads «سبب التكلفة الإضافية: تغليف خاص ← نقل» with nothing written for it. A test in
`ActivityLogTest` pins that.

---

## 4. Domain

**`RecalculateOrderTotals` — still the one place that decides what an order costs:**

```
grand_total = items_total + design_fee + delivery_price + additional_cost − discount
```

The additional cost joins `beforeDiscount`, the base the discount is measured against — so an
order of 350 carrying a 10 charge may be discounted by 360 and reach zero, but never below it.
That is deliberate: the ceiling on a discount is what the customer would otherwise pay, and a
packaging charge is part of that. `DiscountExceedsTotal` still fires above the widened base.

**`OrderData`** carries `additionalCost` (through `money()`, never a float),
`additionalCostReason` and `additionalCostNote`.

**`CreateOrder::guardAdditionalCost()`** — refuses an amount above zero without
`orders.additional_cost`, and the three columns go on together through `forceFill`: an amount,
why it was charged, and the words beside it are one decision, not three fields. None of them is
in `#[Fillable]`, exactly as `discount` is not.

**`UpdateOrder::guardAdditionalCost()`** — refuses only a **change**, compared on the amount.
Every edit re-sends the whole order, so a clerk without the grant correcting the notes on an
order that already carries a charge sends its figure back untouched; refusing that would make
such an order uneditable by everybody else over a field nobody touched. The same reasoning
`guardDiscount` already used.

**`AdditionalCostRequiresPermission`** (403) — its own refusal with its own sentence, «لا تملك
صلاحية إضافة تكلفة إضافية على الطلبية».

**Untouched, and worth saying so:** `remainingAmount()`, `PaymentStatus`, `RecordOrderPayment`
and `WriteOffOrderBalance` all read `grand_total`, so the charge flows into what is owed, into
the payment status and into every settlement guard without a line of change. That is the whole
reason the figure was added to the total rather than reported beside it.

---

## 5. Permission

`PermissionName::AddOrderAdditionalCost = 'orders.additional_cost'` — «إضافة تكلفة إضافية على
الطلبية», in the «الطلبيات» group. `RoleSeeder` creates it from `cases()`; no role is granted it
by default, exactly as none is granted `orders.discount`.

**Its own grant rather than the discount's**, which was a real choice: the two fields look alike
and are not. One gives money away and the other asks the customer for more, and a business may
reasonably trust a role with exactly one of them. Sharing `orders.discount` would also have left
the permissions screen saying «منح خصم على الطلبية» beside a checkbox that does something else.

Enforced **inside the domain**, not on the route — so a console command or a future importer
cannot get past it either.

---

## 6. API

`POST /api/v1/orders` and `PUT /api/v1/orders/{order}` accept three new optional fields; the
resource publishes four.

**Request:**

```jsonc
{
  "customer_id": 12, "city_id": 3,
  "items": [ { "product_id": 8, "product_variant_id": 14, "quantity": "300" } ],

  "additional_cost": "10.00",
  "additional_cost_reason": "special_packaging",
  "additional_cost_note": "علبة كرتون مزدوجة"
}
```

Validation, in both requests:

| Field | Rule |
|---|---|
| `additional_cost` | `nullable`, `numeric`, `min:0`, `max:9999999999.99` |
| `additional_cost_reason` | required once `additional_cost > 0`; must be one of the five codes |
| `additional_cost_note` | `nullable`, `string`, `max:500` — **required** when the reason is `other` and there is an amount |

Both conditionals are decisions rather than technical constraints, and each is one line if the
business wants it relaxed. The reason is required because it is the axis this money is read
along afterwards; without it the column is half empty on the day somebody first asks for the
report.

**Response** (`OrderResource`), beside the existing `discount`:

```jsonc
{
  "items_total": "120.00",
  "delivery_price": "0.00",
  "discount": "0.00",
  "additional_cost": "10.00",
  "additional_cost_reason": "special_packaging",
  "additional_cost_reason_label": "تغليف خاص",
  "additional_cost_note": "علبة كرتون مزدوجة",
  "grand_total": "130.00"
}
```

The label travels with the code for the same reason `design_source_label` does: a client
translating the code itself would be keeping a second copy of a list this API owns.

Refusals: **403** `AdditionalCostRequiresPermission`; **422** on `additional_cost` (negative),
`additional_cost_reason` (missing or unknown), `additional_cost_note` (missing under «أخرى»).

No new routes, and no hand-written API docs — Scramble generates the spec from the code.

---

## 7. Reporting, and what was deliberately *not* changed

**`ProfitAndLossSummaryQuery` is unchanged.** `additional_cost` is absent from revenue there, as
`delivery_price` and `discount` already are: all three sit inside `grand_total`, and none of them
is a product or a service that statement recognises. Folding the packaging charge into
`revenue.service` would make the report disagree with its own treatment of delivery, which is the
inconsistency the omission avoids. A comment in that file now says so, so the next reader does
not take it for an oversight.

**One knock-on worth stating.** An order's gross profit is `grand_total − total_cogs`, so the
charge raises it — the app's «التكلفة والربح» section included. That is exactly what
`delivery_price` already does today, and the charge usually covers a real cost this system does
not track, so the figure is optimistic in the same way and to the same degree it always was. If
the business wants packaging costed rather than merely charged, that is a separate piece of work
with a cost side to it.

---

## 8. Upgrading later to several charges per order — without losing data

Only one charge fits on an order today. Should the business outgrow that, the path is written
down here rather than left to be rediscovered, and **the reason code is what makes it lossless**.

Four forward-only migrations:

1. `create_order_additional_costs_table` — `order_id`, `reason`, `note`, `amount`, `sort_order`,
   timestamps, soft deletes. Shaped like the existing `purchase_order_additional_costs`.
2. **A backfill**: every order with `additional_cost > 0` becomes one row carrying its code, its
   words and its amount. Precedent for this exact move already exists in this repo —
   `backfill_stock_items_for_existing_variants` and `backfill_opening_balance_stock_batches`.
   Had the reason been free text, those rows would be named by whatever was typed and the
   category would be gone; with a code, each lands classified.
3. `orders.additional_cost` **stays** and changes meaning: from "a number somebody typed" to
   "the cached sum of the rows" — precisely what `paid_amount` is to `order_payments`, and
   `total_additional_cost` to `purchase_order_additional_costs`. Written by
   `RecalculateOrderTotals` alone.
4. `additional_cost_reason` and `additional_cost_note` are dropped in a later, separate
   migration once the backfill is verified — the way `drop_weight_kg_from_orders_table` did it —
   or kept.

**Nothing breaks on the day:** `grand_total`, the payments, `remainingAmount` and the P&L all
read `additional_cost`, which still exists with the same arithmetic meaning; `OrderResource`
gains `additional_costs: []` *beside* the scalar, so an app build already on a clerk's phone
keeps working while a newer one renders the list; the permission is unchanged.

**The one honest limit:** the backfill produces one row per historical order. An order charged
«تغليف + نقل» inside a single number comes through as one line under whichever reason was picked
— not because anything was lost, but because the breakdown was never recorded in that era.
Recorded data is preserved in full; unrecorded data is not invented.

**The signal that says when to do it:** the free-text note filling up with «تغليف + نقل». That is
staff adding up in their heads what the system should be adding for them.

---

## 9. Files

**New**

- `app/Domain/Order/Enums/AdditionalCostReason.php`
- `app/Domain/Order/Exceptions/AdditionalCostRequiresPermission.php`
- `database/migrations/2026_09_01_100000_add_additional_cost_to_orders_table.php`

**Changed**

- `app/Domain/Order/DTOs/OrderData.php` — three fields
- `app/Domain/Order/Models/Order.php` — two casts
- `app/Domain/Order/Actions/RecalculateOrderTotals.php` — the sum
- `app/Domain/Order/Actions/CreateOrder.php` — guard + persist
- `app/Domain/Order/Actions/UpdateOrder.php` — guard + persist
- `app/Domain/Identity/Enums/PermissionName.php` — the grant, its label, its group
- `app/Application/Api/V1/Requests/Order/StoreOrderRequest.php` — rules, messages, attributes
- `app/Application/Api/V1/Requests/Order/UpdateOrderRequest.php` — the same rules
- `app/Application/Api/V1/Resources/OrderResource.php` — four keys
- `app/Application/Api/V1/Controllers/OrderController.php` — endpoint docs
- `app/Domain/Audit/AuditAttributeLabels.php` — three Arabic column names
- `app/Domain/Reporting/Queries/ProfitAndLossSummaryQuery.php` — comment only, no arithmetic
- `routes/api.php` — comment only
- `database/factories/OrderFactory.php` — `'additional_cost' => '0.00'`
- `database/seeders/OrderDemoSeeder.php` — a demo order charged for special packaging

**Tests**

- `tests/Feature/Orders/OrderTest.php` — a «التكلفة الإضافية» section of twelve cases: the 403,
  the arithmetic, the brief's worked example (120 + 10 = 130), the two figures staying separate,
  the widened discount ceiling, all four validation refusals, the guard on update, an edit that
  leaves the charge alone, and the charge being taken back off.
- `tests/Feature/Api/V1/ActivityLogTest.php` — the reason reads «تغليف خاص» in the history.

---

## 10. Running it

```bash
php artisan migrate
php artisan test --filter=Order          # includes the new section
./vendor/bin/pint
```

**Note for this machine:** the project requires PHP ≥ 8.4.1 and the `php` on `PATH` is XAMPP's
8.2.12, which refuses to boot the autoloader. Use Herd's:
`~/.config/herd/bin/php84/php.exe artisan …`
