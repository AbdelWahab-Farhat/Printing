# Compensation orders — «طلبية تعويض»

> **Status: built 2026-11-14, uncommitted, on the `delivery-payer` branch** (built on top of the
> delivery payer at the owner's request, not on a branch of its own). Every decision in §3 is
> final. What was built, and how it differs from the plan, is §8.

---

## 1. The request

An order whose goods leave stock like any other order, but which the customer does not pay
for — a replacement for a misprint, a damaged parcel, a short delivery. Today the only way to do
this is a 100% discount, and the owner does not want to use the discount for it.

---

## 2. What already exists (scan of 2026-11-14)

| Path today | What it does for a free order |
|---|---|
| **100% discount** | Allowed — `RecalculateOrderTotals` accepts a discount up to the full total, and `ChangeOrderStatus` already handles a zero total (records «العربون 0»). Needs `orders.discount`. |
| **Full write-off** (`WriteOffOrderBalance`, `orders.payments.write_off`) | Invoice keeps its price, the whole balance is written off with a reason. Company covers the fund's share (`CashEntryType::WriteOffCoveredByCompany`); investors are paid as if sold. Shown under `write_offs` in the P&L. |
| Shortages, scrap, partial delivery | Related, but none of them sends goods out for free. |
| Duplicate / reorder an order | Does not exist. |

### Why the 100% discount is wrong for this — not just awkward

1. **The P&L counts it as revenue.** `ProfitAndLossSummaryQuery` sums `items_total` as revenue
   and leaves the discount out, so a fully discounted order reports its full price as sales.
2. **The fund gets 0 cash for its goods.** `PostFundProceedsForOrder::targetsFor()` returns
   nothing when `grand_total ≤ 0` — the goods leave the fund's shelf and nobody pays for them.
3. **Investor deals are charged a loss.** `OrderDealSlices` spreads `grand_total − items_total`
   over the lines, so revenue becomes 0 while material and labour remain; the profit goes
   negative and `InvestorDeal::investorsCutOf()` charges the investors their share of it.

### Why the full write-off is only a stopgap

Its money side is right, but the order asks for a deposit until written off, Nawris collects
cash unless the write-off happens before dispatch, the order reads «مشطوبة», compensation mixes
with bad debts in reports, and there is no link to the original order.

---

## 3. Decisions

| # | Question | Answer |
|---|---|---|
| 1 | Approach | **Decided: B — a compensation order type** (§4). |
| 2 | Goods that belong to investors | **Decided: (a) at cost** — see §5. |
| 3 | Link to the original order | **Decided: always optional** — see §6. When given: the same customer's, and not itself a compensation. |
| 4 | Who pays delivery on a compensation order | **Decided: the employee chooses**, with the ordinary delivery-payer switch — no special default. When we pay, the fee is the company's alone; investors share none of it. |
| 5 | When the switch can change | **Decided:** only before «جاهزة», while lines are still editable. |
| 6 | Customer app | **Decided:** show the order, labelled «تعويض», no price owed. |

---

## 4. The design (option B)

- **One switch on the new-order page**, «طلبية تعويض», with a reason and (per decision 3) the
  original order.
- **Customer side:** `grand_total = 0`; line prices still show what the goods are worth. No
  deposit step, Nawris collects 0, «تم التسوية» allowed at once, «تعويض» badge everywhere.
  A discount or additional cost is refused on a compensation order.
- **Stock:** unchanged path — `DeductOrderStock` at «جاهزة», cost written to `total_cogs`.
- **Investors:** per decision 2, never through the negative-profit path above.
- **P&L:** price kept out of revenue; cost stays in COGS; a new line «خسائر التعويض» under
  `losses`, beside scrap and partial delivery — shown, never subtracted, as that section does.
- **Permission:** new `orders.compensation`, separate from `orders.discount`, seeded on nobody.

### Reasons (closed set, like `AdditionalCostReason`)

| Code | Label |
|---|---|
| `print_defect` | خطأ طباعة |
| `wrong_item` | منتج أو مقاس خاطئ |
| `delivery_damage` | تلف في التوصيل |
| `previous_shortage` | نقص في طلبية سابقة |
| `goodwill` | مجاملة |
| `other` | أخرى (needs a note) |

---

## 5. Decision 2 — investor-owned goods (open)

Worked example: 1,000 bags at list price 0.50 = **500 د.ل**; the bags cost the investor's deal
**300**; our printing labour **50**; the deal is 100% investor-funded with a **50%** profit share.

| | **(a) At cost** — recommended | **(b) As if sold** | **(c) Not allowed** | *Today's 100% discount* |
|---|---|---|---|---|
| Investor gets back for the goods | 300 | 500 | — | **0** |
| Investor's profit | 0 | +75 | — | **−175** |
| Compensation costs the company | **350** | **425** | 350 (own stock) | 175 |
| Reads as | "your goods were used, here is their money" | "your goods were sold" | investors never involved | investor pays for our mistake |

- (a) fair to both sides — no loss, no profit on a sale that did not happen.
- (b) matches how write-offs behave today; pays a profit nobody paid.
- (c) simplest; a compensation order cannot be made if the item exists only in investor stock.

**Changing it later:** for new orders, easy — the rule lives in one place, and can be made an
owner setting so no release is needed. For orders already delivered, possible but deliberate:
both investor postings reconcile to a target, so a one-off command could restate them — but that
moves balances investors have already seen, so only on the owner's instruction.

---

## 6. Decision 3 — link to the original order (open)

- **Required:** order #1200, 500 bags, 100 misprinted → compensation #1250 for 100 bags must
  pick #1200 and «خطأ طباعة». #1200 shows «عُوِّضت بالطلبية #1250», #1250 shows
  «تعويض عن #1200». Answers "what did misprints cost us this month?".
- **Optional:** 200 free bags to apologise for slow service across several orders — no single
  order at fault; a required link would block it or force a wrong one.
- **Recommended middle path:** required, except reason `goodwill`. When given, the original must
  belong to the same customer and must not itself be a compensation order.

---

## 7. Build plan (after decisions 2 and 3)

**Environment:** local development, branch `order-compensation`, one migration on the local
database, no external services, left uncommitted until the owner says so.

**Backend**
- Migration `add_compensation_to_orders_table`: `is_compensation` (bool, default false),
  `compensation_reason` (string 30, nullable), `compensation_note` (string 500, nullable),
  `compensates_order_id` (nullable FK → `orders`). Real `down()`.
- `Domain/Order/Enums/CompensationReason.php` (new).
- `Order` casts + helpers; `RecalculateOrderTotals` (total 0); `CreateOrder`, `UpdateOrder`,
  `OrderData`, `StoreOrderRequest`, `UpdateOrderRequest` (switch, reason, link, lock at «جاهزة»).
- `PermissionName::CompensationOrders` (`orders.compensation`) + seeder.
- Investor rule (decision 2): `OrderDealSlices`, `PostDealEarningsForOrder`,
  `PostFundProceedsForOrder`, new `CashEntryType` case for the company covering the fund.
- `ProfitAndLossSummaryQuery`: exclude from revenue, add `losses.compensation`.
- `OrderResource`, client order resources, `AuditAttributeLabels`.

**Staff app** (`frontend/`)
- Order model fields (**owner runs `build_runner`**), new-order switch + reason + original-order
  picker, badge on card and detail, list filter, permission, fund cash row label, P&L line.

**Customer app** (`frontend-client/`) — «تعويض» label, no amount owed.

**Tests**
- Compensation order: total 0, stock leaves at «جاهزة», no deposit, settles, Nawris collects 0,
  discount refused, switch locked after «جاهزة», permission enforced.
- Investor: fund and deal postings at a zero total under the chosen rule.
- P&L: revenue excludes it, loss line shows its cost.
- Run only the affected suites, phpunit directly with `memory_limit=2G`, never two at once.

**Risks**
- Financial code (investor postings) — needs a specialist review pass before merge.
- Decision 4 may add a dependency on the `delivery-payer` branch.

---

## 8. What was built (2026-11-14)

On the `delivery-payer` branch, uncommitted. Where the build differs from §7, it says so.

### Backend

- **Migration** `2026_11_14_200000_add_compensation_to_orders_table`: the four columns of §7, an
  index on `is_compensation`, and the fund cash ledger's CHECK constraint widened by one type.
  Real `down()` (soft-deletes rows of the new type, as the earlier reshapes do).
- **Switching on an existing order is its own endpoint**, not a field on the edit form:
  `PATCH orders/{order}/compensation` (`ChangeOrderCompensation`) — the delivery payer's pattern.
  The edit form re-sends the whole order, and a flag that zeroes the total must not ride along.
  Creating an order takes the four fields directly (`StoreOrderRequest`, `CreateOrder`).
- **Rules** (`GuardCompensation`): `orders.compensation` both ways; no discount and no additional
  cost (refused, not dropped — remove them first); the original, when named, is the same
  customer's, not a compensation, and not the order itself; an order that other compensations
  name as their original cannot become one. Open while `itemsAreEditable()`.
- **Total**: `RecalculateOrderTotals` writes `grand_total = 0`; `items_total` keeps the lines.
  Deposit, Nawris COD and settlement already handled a zero total — nothing changed there.
- **Investors, at cost**: `OrderDealSlices::atCost()` — revenue = material of each deal draw,
  no conversion cost, no extras, no courier fee; profit exactly 0, so `PostDealEarningsForOrder`
  posts nothing. Draws the press already bought off the shelf are skipped, as on any order.
- **Fund cash**: new `CashEntryType::CompensationCoveredByCompany` (`compensation_by_company`) —
  the company pays the fund its goods' cost when the order reaches «تم الاستلام». Posted by
  `PostFundProceedsForOrder` (third target) through `PostCompensationCoverWhenDeliveryMoves`, which
  listens to delivery, undo-delivery, archive and restore (`OrderStockRedrawn`) and acts on
  compensation orders only. Reconciled to a target, so repeats change nothing.
- **P&L**: compensation orders are out of revenue (product and design fee); their cost stays in
  COGS and is named under `losses.compensation` (internal shelf margin netted out, and goods left
  behind on a partial delivery left to `losses.partial_delivery` so the total counts them once).
- **Sales statistics** leave compensation orders out — nothing was sold.
- **Resources**: `OrderResource` (`is_compensation`, reason + label, note, original id + code,
  `compensated_by`, `can_change_compensation`; the delivery-payer warnings say the fee is the
  company's alone), client list and detail (`is_compensation`), audit labels, list filter
  `?is_compensation=1`.

### Staff app

New-order section «التعويض» (switch, reason chips, words, optional original-order picker; hides
the discount and the additional cost), «التعويض» section on the order screen with the links both
ways and a sheet to switch it, «تعويض» badge on the card, a compensation line in «الحساب», the
P&L line «خسائر التعويض», the fund cash row icon, the permission, and a «طلبيات التعويض فقط» tick
on the order filter sheet (live list and archive alike; sends `is_compensation=1`).

### Customer app

«تعويض — بلا مقابل» on the order card, «طلبية تعويض — مجاني» on the order's money card.

### Tests

`tests/Feature/Orders/CompensationOrderTest.php` (31 tests), `frontend/test/features/orders/
compensation_test.dart` (5), one in `frontend-client/test/features/orders/order_detail_page_test.dart`.

### Still open

- **Fund stock the press already bought.** When a printed line drew fund stock carrying
  `printing_sale_price`, the fund was paid the shelf price at the draw (`StockSoldToPress`); the
  compensation does not undo that, so on those goods the fund keeps the shelf margin, not exactly
  the cost. Consistent with every other order (goods the press bought are the press's) — owner to
  confirm.
- Production migrate needs the owner's OK at the time.
