# Compensation orders — «طلبية تعويض»

> **Status: planned, not built.** Plan agreed 2026-11-14; decisions 2, 3 and 4 below are still
> open. Branch to be: `order-compensation` (not created yet). Nothing in code has changed.

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
| 2 | Goods that belong to investors | **Open** — see §5. Recommended: (a) at cost. |
| 3 | Link to the original order | **Open** — see §6. Recommended: required, except reason «مجاملة». |
| 4 | Who pays delivery on a compensation order | **Open — owner decides after seeing the rest.** Depends on the `delivery-payer` branch (uncommitted, not on main). Options: build on top of it · wait for its merge · leave delivery as today (customer pays the courier). |
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
