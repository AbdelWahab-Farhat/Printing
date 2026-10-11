# Adding and removing products before «قيد الطباعة»

> **Branch `order-lines-edit`, uncommitted by request.** Written in English; the shipped code and
> UI strings stay Arabic like the rest. Answers the BACKLOG item **«إضافة منتج من شاشة تعديل
> الطلبية»** and moves the line lock from «جاهزة» back to «قيد الطباعة».
>
> **Every decision below was settled on 2026-10-11** — the owner chose option B (edit up to the
> press, including after the stock has left the shelf) and accepted every recommendation.

---

## 1 · The request

Staff can add a product to an order, and remove one, until the order reaches «قيد الطباعة».
Quantities stay editable over the same span.

## 2 · What already existed

| Need | Already there |
| --- | --- |
| Replace an order's lines | `PUT /orders/{id}` with `items` — `SyncOrderItems` |
| Price and write one line | `AddOrderItem` — minimum quantity, catalogue or hand price, snapshots |
| Move one line's stock | `RedrawOrderLineStock` — reverse the draw, take a new figure; zero puts it all back |
| Pay investors for what left | `OrderStockDrawn` → `PostDealStockPurchases`, recomputed per line, safe to re-run |
| Picker, live price | `showProductPicker`, `LineQuoteCubit` |

So nothing here is a new mechanism. What was missing was the rule, the bookkeeping order, and
the button.

## 3 · Where lines are open

| Zone | Statuses | An edit… |
| --- | --- | --- |
| **1 · stock still on the shelf** | جديدة · انتظار العربون · تم دفع العربون · نواقص · قيد التصميم on the وسيط road | changes the lines |
| **2 · stock already drawn** | جاهزة للطباعة · قيد التصميم on the standard road | changes the lines **and** moves each changed line's stock, then re-posts investor purchases |
| locked | قيد الطباعة onwards · بانتظار المراجعة | — |

Zone 2 is recognised by `orders.stock_deducted_at`, not by status: «قيد التصميم» is zone 1 on the
وسيط road and zone 2 on the standard one.

**«قيد الطباعة» closes.** It used to be open for quantity corrections, but on a real order every
line had already been drawn at «جاهزة للطباعة», so `FulfilledLineCannotBeReplaced` refused every
edit there. The promise was never kept; now it is not made.

**«بانتظار المراجعة» stays closed.** Staff accept a request first, then edit it as «جديدة».

## 4 · Decisions (2026-10-11)

| # | Question | Decision |
| --- | --- | --- |
| 1 | How far do lines stay open | Up to «قيد الطباعة», including after the draw (option B) |
| 2 | Customer requests | Accept first, then edit |
| 3 | Replace the set or edit it | **Edit it by line id** — kept lines keep their id, price, shortage and draw |
| 4 | Re-pricing | Only added lines and lines whose quantity changed |
| 5 | Confirm on remove | None — nothing is sent until «حفظ التعديلات» |
| 6 | Restored or reinstated orders in zone 2 | **Refused** — cancel and re-take |
| 7 | An edit that leaves zone 2 with nothing to print | **Refused** |
| 8 | Tell the customer | No |
| 9 | Who may edit in zone 2 | `orders.manage` **and** the grant for moving into «جاهزة للطباعة» |

## 5 · The line contract

`items.*.id` is optional:

| Sent | Means |
| --- | --- |
| an id, same quantity | untouched (notes and order may still change) |
| an id, new quantity | re-quoted at the new quantity; a hand-priced line keeps its price unless one is sent |
| no id | a new line, through `AddOrderItem` |
| an existing id left out | removed |

`items.*.unit_price` is honoured for «حسب الطلب» products as before — the app now sends it, which
fixes saving any order that holds such a line.

`items.*.warehouse_quantity` — in zone 2 only, for a line stocked in another unit than it is sold
in, when it is added or its quantity changes. The same figure «جاهزة للطباعة» asks for.

## 6 · Zone 2, step by step

All inside `UpdateOrder`'s transaction, with the order row locked:

1. **Guards.** The actor holds `MoveOrderToReadyToPrint`. The order's draw was never reversed
   (no `order_reversal` movement against it — a restored or reinstated order). No removed line
   carries a scrap entry. Kilo-stocked lines that need a weight have one. The warehouse holds
   enough for what is about to be drawn, counted per shelf after what is about to come back.
2. **Removed lines** → `RedrawOrderLineStock(qty 0)`. The goods go back to the layers they came
   from — the deal's, when a deal sold them.
3. **Changed lines** → `RedrawOrderLineStock(new figure)`.
4. **Added lines** → written by `AddOrderItem`, then `RedrawOrderLineStock`, which draws from
   `fulfillment_warehouse_id` because the line has no draw to reverse.
5. **`OrderStockDrawn`**, once, **while the removed lines still exist**. `PostDealStockPurchases`
   recomputes every line from the draw it now points at; a removed line no longer points at one,
   so its payment is reversed as stranded. Deleting first would hide it from that sweep
   (`OrderService::lineIdsFor` skips trashed lines) and leave an investor paid for goods back on
   his shelf.
6. Only then are the removed lines soft-deleted.

Removals run before increases so that a size swapped for another on the same shelf frees its
stock before the new one draws.

## 7 · Zone 1 details

- **«نواقص»** keeps `shortage_quantity` on kept lines; a quantity below the line's shortage is
  refused. `OrderShortagesRecorded` fires after the commit so removed lines close their shortage
  rows.
- **The road is re-read** in جديدة · انتظار العربون · تم دفع العربون, and in «نواقص» unless the
  new road is وسيط. Anywhere else an edit that would change the road is refused.
- **One bench**: the `CreateOrder` rule (no وسيط line beside an in-house one) now binds edits too.

## 8 · Money

- The total below what was paid shows as overpaid, as designed.
- A discount above the new total is refused by `DiscountExceedsTotal`, as before.
- `deposit_expected_amount` is left alone: it is the figure agreed on entering «انتظار العربون».
- The edit screen warns before saving when the new total is below what was paid.

## 9 · Where the work stands

- [x] Backend — line contract, zones, guards, stock and investor ordering
- [x] Backend tests — `OrderLinesAddRemoveTest` (23), five older tests moved to the new line
- [x] App — «إضافة منتج», live prices, weight field, overpaid warning, per-line errors
- [ ] App tests — written in `order_invoice_cubit_test.dart`; need `build_runner` before they run
- [x] Docs — ORDERS-STATUS-FLOW §6, ORDERS-DESIGN decision 11, BACKLOG. «شن تغيّر» is written at merge, when the PR has a number.

**Found on the way and fixed:**

- `RedrawOrderLineStock` with a zero figure wrote `warehouse_quantity = 0`, which the
  `order_items_warehouse_quantity_is_positive` CHECK refuses — a raw 500. Removing a drawn line
  needs that path, and so does a partial delivery where the customer leaves a whole plain line.
- Saving the lines of an order holding a «حسب الطلب» product failed with `ManualPriceRequired`,
  because the edit screen never sent a price. Kept lines now keep theirs.
- Editing an order in «نواقص» wiped `shortage_quantity` on every save.
- An edit could put a وسيط line beside an in-house one; `GuardOneBench` now binds edits too.
- `RestoreOrder` now stamps `orders.stock_redrawn_at` (backfilled from the audit trail), which is
  what lets a zone-2 edit refuse a restored order.

**Changed on purpose:** shortages keep their old window (`Order::shortagesAreEditable()` — جديدة ·
قيد التصميم · نواقص · قيد الطباعة), so declaring a shortage is exactly as before.
