# Investment Pools — continuous per-material pools replacing per-deal investment — the specification

**Status: Slice 0 built on branch `investment-pools` (the pool container, the settings and the
fold-in command — not yet executed); Slices 1–5 not started.** See
[INVESTMENT-FUND-PLAN.md](INVESTMENT-FUND-PLAN.md). It supersedes the *deal* model described
in [INVESTOR-DEALS-DESIGN.md](../investor-deals/INVESTOR-DEALS-DESIGN.md) and
[INVESTOR-DEALS-HOW-IT-WORKS.md](../investor-deals/INVESTOR-DEALS-HOW-IT-WORKS.md), both of which
stay in the repository: they describe deals that still exist as history and whose screens keep
rendering.

Written in English at the owner's request; the code comments it produces follow the repository's
Arabic convention as usual.

---

## 1. The idea in three lines

The company stops opening a new صفقة for every lorry. For each **material** it invests in there is
**one continuous pool** that never closes. Investors put capital into whichever pools they want, the
pool buys its material, sells it, and buys again with the proceeds.

What closes on a cycle is **the profit, not the trade** — the remaining goods and the capital roll
into the next period untouched. The thing that repeats is the **accounting period**, not the deal.

---

## 2. What already exists and is reused unchanged

This is not a rewrite. The existing Investor domain already solves most of it, and the parts below
are used exactly as they stand.

| Requirement | Where it already lives |
|---|---|
| Capital recorded as independent movements, never a balance column | [`investor_wallet_entries`](../../backend/database/migrations/2026_09_04_110500_create_investor_wallet_entries_table.php) — append-only, positive-only, corrected by reversal |
| Four pots: capital-in-wallet, capital-in-pool, unsettled profit, withdrawable profit | [`WalletEntryType::deltas()`](../../backend/app/Domain/Investor/Enums/WalletEntryType.php) |
| One investor in several pools at once | `investor_deal_shares`, already one row per (container, investor) |
| Investment stock inside ordinary inventory, no separate warehouse | `stock_batches.investor_deal_id` on ordinary FIFO cost layers |
| Remaining / sold / damaged / short, per stock item | [`DealStockPosition`](../../backend/app/Domain/Investor/Queries/DealStockPosition.php) — already returns `per_item` |
| Which materials may be invested in at all | `is_investable` on the product **category**, three-state with inheritance |
| Unsold stock carried forward, never counted as profit | true by construction — nothing liquidates at any boundary |
| Unsettled profit not withdrawable | the only door to `profit_wallet` is `profit_release` |
| Loss borne out of capital, capped at what was put in | `capital_writedown` + `loss_absorbed_by_company` |
| سعر السادة — the press buying plain stock off the shelf | [`StockPurchaseMargins`](../../backend/app/Domain/Investor/Support/StockPurchaseMargins.php) |
| Order profit split across the shelves it drew from | [`OrderDealSlices`](../../backend/app/Domain/Investor/Support/OrderDealSlices.php) |
| Expense double-count guard | `is_landed` on [`InvestorDealExpense`](../../backend/app/Domain/Investor/Models/InvestorDealExpense.php) |
| Investor portal, permissions, audit trail | unchanged |

**The ledger is already continuous, and it is already per-container.** A pool is, structurally, a
deal that never ends.

---

## 3. What actually changes

**Nothing changes for daily operations.** Receiving, printing, delivery and inventory are untouched.
The storekeeper is never asked which container, the press draws stock the same way,
`ReceivePurchaseOrder` stamps layers the same way.

| | Today | After |
|---|---|---|
| **Container** | a صفقة per purchase order — D25, D26, D27… | a pool per material, never closes |
| **Born from** | only a purchase order ([`FundPurchaseOrder`](../../backend/app/Domain/Investor/Actions/FundPurchaseOrder.php)); manual deals forbidden | capital goes in; purchases draw on the pool's cash |
| **Lifecycle** | draft → open → closed | the pool has none; its **periods** do |
| **Ownership** | `share_percent` frozen at open, from the amounts typed that day | recomputed each period from capital in that pool |
| **Company's stake** | `investor_funded_percent`, frozen from one lorry's cost | its capital weight in that pool, that period |
| **Which container** | somebody claims each purchase-order line in advance | **automatic** from the material; the only choice left is pool money or company money (§4.3) |
| **Capital in** | once, at funding; `DealTakesNoMoreCapital` refuses more | any time, effective at a period boundary (§5) |
| **Capital out** | only when the deal closes | requested any time, executes at the close |
| **Profit rows** | one per investor per order, immediately | one per investor per **period** |
| **Profit withdrawable** | when the deal closes | when the period closes |
| **Closing needs** | no stock left **and** no orders in flight | nothing — a period closes with full shelves |
| **Stock at a boundary** | n/a — the deal ends when the stock does | rolls forward at cost |
| **سعر السادة** | per deal | per purchase |
| **Loss containment** | per deal, by accident of its scope | per pool, deliberately — ink never touches paper (§6.4) |

### What the three people involved will notice

**Whoever runs the investments.** Today: create a deal for every lorry, name the investors, type the
amounts, then watch for the moment all its stock is gone and every order delivered so it can be
closed. After: fund purchases out of a pool's cash, and close the periods once a month. The «is it
closable yet?» hunt disappears.

**The investor.** Today his money is tied to *specific goods* — D25's 500 kg — and he is paid when
those particular goods are finished. After, he owns a share of everything **that pool** holds, and is
paid on a schedule. Two things he will notice: profit arrives on a clock rather than on an event,
usually sooner; and he cannot put money in on any given day — outside the grace window it waits for
the next period, which is why the warning in §5 exists.

**Everyone else.** Nothing.

### The one conceptual shift

Money stops being tied to specific goods. An investor can no longer say «that lorry is mine» — he
owns a percentage of a pool. Everything else in this design follows from that sentence.

---

## 4. What a pool is

### 4.1 One material, one pool

A pool owns a named set of stock items — one, or a basket of related shelves.

> **Each investable stock item belongs to at most one pool.** Enforced by a unique index, not by a
> convention. A cost layer carries exactly one container id, and the supply lookup answers with one
> row, so a shelf claimed by two pools would silently send an investor's goods to the wrong one.

An investor may be in **several pools at once**. Each participation is its own capital, its own
share, its own period results — exactly as he can be in several deals today, and using the same
`investor_deal_shares` rows.

### 4.2 One calendar for all pools

Period length, settlement interval and grace days are **global settings** (§7). Every pool's periods
therefore begin and end on the same dates, and «close September» is **one action that iterates the
pools**, each producing its own period row and its own distribution.

This is deliberate: per-pool calendars would mean remembering N different close dates, and a
settlement that spans pools would have no common boundary to stand on.

### 4.3 Routing a purchase — the part that gets simpler

Today somebody claims each purchase-order line for a deal in advance
([`InvestorDealSupply`](../../backend/app/Domain/Investor/Models/InvestorDealSupply.php)).

Because stock item → pool is now a **fixed mapping**, nobody chooses a pool any more. The only
decision left on a line is **pool money or company money** — a yes/no — and the pool follows from
the material. The storekeeper is still never asked, and «الموظف لا يختار الصفقة أبداً» holds more
strongly than before.

A line marked for pool money is refused if that pool's deployable cash (§5.1) will not cover it.

---

## 5. Entry and exit — the grace window

Capital must be **constant inside a period**. That single rule is what makes ownership a plain
capital ratio, with no unit ledger, no NAV valuation and no day-weighting anywhere in the system.

```
Period:  1 Oct ═════════════════════════════════════ 31 Oct
         │
         ├── days 1..N   GRACE WINDOW        N = entry_grace_days, admin-set, default 3
         │               capital added here participates for the WHOLE period
         │
         └── day N+1 →   QUEUED               enters at the next period start
                         the investor is warned before he submits
```

`entry_grace_days = 0` makes it a strict boundary. The window applies per pool, on the shared
calendar.

### Where queued money sits

In the investor's **wallet capital** — a pot that already exists. A deposit lands there as it always
has; only the `allocation` into the pool is deferred. An `investment_capital_requests` row records
the intent, naming the pool, so the dashboard can show «رأس مال منتظر الدخول» and so the investor
can cancel and withdraw before the boundary. Nothing is held in limbo and no new pot is invented.

### Exit follows the same gate

A capital **withdrawal** from a pool requested during a period executes at that pool's **close**,
after profit has been distributed, and only up to the pool's deployable cash. Two reasons, and the
second is the practical one:

- an investor who pulls capital out on day 15 has no single weight for that period, which would
  reintroduce the day-weighting this rule exists to avoid;
- the money is usually **in stock, not in cash**, and cannot be returned on demand.

**Profit withdrawals are not gated.** That money sits in the profit wallet, already settled and
ring-fenced, and may be taken at any time.

---

## 6. The equations — all of them scoped to one pool

### 6.1 Deployable cash

A pool's cash is **derived, never stored** — the standing rule of this schema.

```
book value      = Σ capital_deal(pool) + Σ profit_deal(pool)      from the ledger
stock at cost   = DealStockPosition.cost_remaining(pool)          from the cost layers

deployable cash = book value − stock at cost
```

and, held apart from it:

```
undrawn profit  = Σ profit_wallet                                 a LIABILITY, never deployable
```

A purchase that exceeds the pool's deployable cash is refused. **Undrawn profit is never available
as working capital** — it is money the company holds and does not own.

> Undrawn profit is a wallet figure and belongs to the investor, not to any one pool. It is shown on
> his screen and in the roll-up, never inside a pool's cash.

### 6.2 Period net profit

```
  realized margin        Σ priced-draw margins   (drawn in this period, this pool's layers)
                       + Σ delivered-order slices (delivered in this period, this pool's layers)
− deductible expenses    is_landed = false, booked on this pool, incurred in this period
− damage cost            spoilage, misprints, goods ruined on a cancelled order
− shortage cost
─────────────────────
= period net profit                                              may be negative
```

Everything below is about the two subtraction lines and the one rule that governs both: **a cost is
subtracted here exactly once, and never if it is already inside the cost of the goods.**

#### 6.2.1 Cancelled orders — which losses reach a pool

Four cases, and only two of them are the pool's. This is settled behaviour in the code today; it is
written out here because it is the first thing anyone will ask at a close.

| What was cancelled | Who bears it | Reaches the pool's net profit? |
|---|---|---|
| **وسيط** — `ProductionMode::Outsourced` | the company, always | **No.** No purchase order, no arrival, no cost layer, no warehouse — a pool owns nothing of it, and `ProductMustBeInvestable` refuses it outright |
| **سادة** — `ProductionMode::None`, goods sold off the shelf as they stand | nobody | **No — and this never even becomes a question.** Nothing was printed and nothing was priced, so the exact layers return to the pool **intact**, at their own cost. A clean return, not a loss |
| **Printed, priced material (سعر السادة)** | the company | **No.** The investor was paid the day the stock left the shelf. [`ReverseOrderStockDeduction`](../../backend/app/Domain/Order/Actions/ReverseOrderStockDeduction.php) credits those layers back as **company** stock at what the company paid — `purchasedLayersBelongToTheCompany` — so he is never made to hold both the money and the goods |
| **Printed, unpriced material, goods still good** | nobody | **No.** The exact layers credit back to the pool at their own cost |
| **Printed, unpriced material, goods ruined** | the pool | **Yes** — as `damage cost`, once the spoilage is recorded |

> **Only a printed line can ruin a pool's goods**, and the condition is one the code already owns:
> [`MaterialCost`](../../backend/app/Domain/Order/Support/MaterialCost.php) prices a draw only when
> the layer carries a `printing_sale_price` **and** `OrderItem::isPrinted()` — «سادة line sold off
> the shelf as it stands is not a printing job buying material». The same predicate decides whether
> returned goods can have been damaged. A سادة line and a وسيط line are never asked about.

> **The gap this exposes, and it exists today.** For a **printed** line, a cancellation credits the
> material back to the shelf *as good stock*. Paper that has already been printed on is not good
> stock. Nothing in the system knows the difference, so the ruin has to be recorded as damage by a
> person, in a second step. Until that step is taken, the pool's period shows profit it did not earn
> and stock it does not really have.
>
> **Slice 3 makes that step impossible to forget:** cancelling an order whose **printed** line drew
> unpriced pool material raises a question on the pool — «بضاعة راجعة من طلبية ملغاة: صالحة أم
> تالفة؟» — and the period **refuses to close** while any such question is unanswered. Answering
> «تالفة» writes the damage; answering «صالحة» closes the question and writes nothing.
>
> No question is raised for سادة or وسيط lines, because for them there is only one possible answer
> and a prompt with one answer is noise that trains people to click through prompts.

Spoilage during a normal production run needs none of this: [`RecordScrapLoss`](../../backend/app/Domain/Order/Actions/RecordScrapLoss.php)
already posts a `scrap_loss` movement, which [`DealStockPosition`](../../backend/app/Domain/Investor/Queries/DealStockPosition.php)
buckets as `damaged` — and on a priced pool the investor is paid for the spoiled bags at سعر السادة
rather than losing them.

#### 6.2.2 Expenses — by hand, and automatic

Both exist, and which is which is decided by `is_landed`, **set only by the server**:

| | Example | Subtracted? |
|---|---|---|
| **Automatic, already in the goods** | shipping and customs typed on the purchase order | **No.** Mirrored onto the pool for the record only. It is already inside the cost of the layers that arrived, and subtracting it again charges the investors for one customs invoice twice |
| **Automatic, not in the goods** | storage accrued monthly, transport on a sale, scrap cost | **Yes** |
| **By hand** | a shipping invoice that arrived late, a customs re-assessment, anything the purchase order never carried | **Yes** |

An invoice covering two pools' goods is booked as **two rows, one per pool**. A single row split at
read time would have to invent an apportionment rule that no screen could show its working for.

#### 6.2.3 Which period an expense belongs to

By `incurred_on`, not by when it was typed — the rule `occurred_at` already follows in the wallet.

**A closed period is immutable.** So an expense dated inside a period that has already closed is
booked to the **current open period** instead, carrying its true `incurred_on` and a visible note
naming the period it was meant for. It is never back-dated into a closed one, because that would
change a distribution already paid out.

This is the one place where a real cost can land a period late. It is deliberate, and the note is
what makes it legible rather than mysterious.

#### 6.2.4 «محسوبة مسبقاً» — the message that stops the double subtraction

The `is_landed` guard is the single most double-countable thing in the whole feature, and today it
is silent: a person looking at a pool sees a customs line and has no way to tell it was already
inside the goods.

Three places must say so out loud:

- **The expense form on a pool** — an amount that arrived from a purchase order is shown
  **read-only and marked «محسوبة مسبقاً ضمن تكلفة البضاعة — لا تُخصم مرة أخرى»**, so nobody retypes
  it as a manual expense.
- **The pool's expense list** — every row carries the badge, and the list footer shows two totals,
  «المخصوم» and «المسجَّل فقط», never one sum.
- **The period-close screen** — the net-profit breakdown prints every subtraction line, with the
  already-counted rows listed beneath it under the same wording and **excluded from the arithmetic**.

A close is an irreversible payout. The screen that triggers it has to show its working.

### 6.3 Distribution

```
investor_capital_weight = investor capital in pool ÷ total pool capital
investors' pool share   = net profit × investor_capital_weight × investor_profit_share_percent/100
company                 = net profit − investors' pool share
each investor           = investors' pool share × (his capital ÷ total investor capital in pool)
```

Largest-remainder allocation, as [`Money::allocatePercent`](../../backend/app/Domain/Investor/Support/Money.php)
already does, so the parts sum to the whole exactly.

This is [`InvestorDeal::investorsCutOf()`](../../backend/app/Domain/Investor/Models/InvestorDeal.php)
with its shape intact. Only the middle factor's source changes: period-computed from the pool's
capital, instead of frozen from one purchase order's cost.

**Worked example — the paper pool.** Capital 350,000 — A 120,000 · B 80,000 · C 80,000 · company
70,000. Period net profit 28,000.

| | Capital | | Share |
|---|---|---|---|
| Investors' side | 280,000 (80%) | `28,000 × 80% × 50%` | **11,200** |
| → A | 120,000 | `11,200 × 120/280` | 4,800 |
| → B | 80,000 | `11,200 × 80/280` | 3,200 |
| → C | 80,000 | `11,200 × 80/280` | 3,200 |
| Company | 70,000 (20%) | `28,000 − 11,200` | **16,800** |

A, who is also in the ink pool, gets a **second** distribution from that pool's own close, computed
the same way against his ink capital. The two never mix.

### 6.4 A losing period

The same formula with a negative net profit. Each investor's negative share becomes a
`capital_writedown` against **his capital in that pool**, capped there; any remainder is
`loss_absorbed_by_company`. Both row types already exist.

A loss in the ink pool **never touches** his paper capital. That containment is the whole reason you
chose pools over one fund, and it falls out of the ledger's existing per-container scoping with no
extra guard.

Capital is written down **at the close**, never carried forward. That is what keeps the identity in
§6.5 true at every boundary, and therefore what keeps ownership a plain ratio.

### 6.5 The identity a settlement asserts

Per pool:

```
Σ capital in pool + Σ unsettled profit  =  deployable cash + stock at cost
```

And across the company:

```
physical cash held  =  Σ deployable cash of every pool  +  Σ undrawn profit owed
```

Because every period releases all realized profit and writes down all realized loss, at a period
boundary the first line collapses to **book value = Σ capital**. There is no retained value for a
newcomer to dilute, which is the whole reason no NAV machinery is needed.

A settlement records both sides and the **drift** between them. A non-zero drift is a finding, not an
error to be silently absorbed.

---

### 6.6 Taking capital out

Settled by the owner on 2026-09-20; the design had not asked the question until then.

#### The minimum term

**«الحد الأدنى للبقاء» — 6 months** before an investor may *ask* to withdraw, counted from his
**first** capital into that pool.

Not from the latest top-up: restarting the clock on every deposit would make paying more into a
pool a reason to be locked in longer, which is the opposite of what a minimum term means. Not per
tranche either — that turns one stake into a row of separately-maturing parcels, and «كم أستطيع أن
أسحب اليوم؟» stops having one answer.

Money he took out **entirely** and later put back starts again. That falls out of reading the
ledger rather than a stored `joined_at`, and it is the honest answer: it is new money.

**The company is exempt.** It is the operator, it absorbs the losses that run past a partner's
capital (§6.4), and its money in the pool is working capital it has to be able to move. Locking the
house against itself protects nobody. It is exempt from the calendar, **not** from the arithmetic
below.

**The setting's default is 0**, which is the behaviour that existed before it — a deploy must not
silently lock every investor's capital on the day it runs. The term gates the **request**, never
the payout: an exit already queued was legitimate the day it was made.

#### What he may actually be paid

```
his ceiling = min( his capital in the pool ,
                   his capital weight × the pool's deployable cash )
```

**Out of the cash, never out of the goods.** `deployable_cash` is book value less stock at cost, so
an exit can never force a lorry to be sold. What cannot be covered stays pending and comes round at
the next close.

**And only his own slice of that cash.** Without the weight, whoever queued first could empty the
till: two partners each owning half of a pool holding 40,000 in cash, and the first to ask takes all
of it while the second waits on a lorry selling. Same pool, same month, same right to leave — and
the only thing that decided it was the order they walked in. The weights are taken once, before
anybody is paid, so the split does not depend on the queue.

> **«لا يسحب حتى لا يبقى له شيء في البضاعة» was considered and rejected.** Taken literally it means
> an investor may leave only when the pool holds zero stock — and a working pool always holds stock.
> It is the same trap as waiting for a press to have no orders in flight: a condition that sounds
> reasonable and never occurs. What it reaches for is the cash cap, which the first rule already is.

---

## 7. Tables

### 7.1 Changed

| Table | Change |
|---|---|
| `investor_deals` | `+ kind` — `'deal'` (legacy, read-only) or `'pool'` (continuous). `+ name` is reinstated for pools («ورق», «حبر»). `purchase_order_id`, `company_stake`, `investor_funded_percent`, `printing_sale_price` become unused on pool rows and keep their meaning on legacy rows. |
| `investor_deal_shares` | The roster of who is in a pool, with `joined_at`. `share_percent` stops being an input for pools; splits are computed per period. |
| `investor_wallet_entries` | The shape `CHECK` is amended so `profit` / `loss` may name an **investment period** as their source, not only an order. |
| `company_settings` | `+ profit_period_months` (default 1), `+ settlement_period_months` (default 6), `+ entry_grace_days` (default 3) |

`stock_batches.investor_deal_id` is **unchanged** and now points at a pool row.
`stock_batches.printing_sale_price` already exists, so سعر السادة becomes per purchase with no new
column.

### 7.2 New

**`investment_pool_items`** — which shelves a pool owns: `investor_deal_id`, `stock_item_id`.

> `UNIQUE (stock_item_id) WHERE deleted_at IS NULL` — the §4.1 invariant, held by the database. A
> dedicated table rather than reusing `investor_deal_items`, because that index cannot be expressed
> as a partial index there: `kind` lives on the parent row, and a cross-table condition is not
> indexable. One small table buys a guarantee instead of a convention.

**`investment_periods`** — one row per **(pool, period)**.

`investor_deal_id`, `starts_on`, `ends_on`, `status` (`open` / `closed`), `closed_at`, `closed_by`,
and written once at close: `opening_cash`, `closing_cash`, `opening_stock_cost`,
`closing_stock_cost`, `realized_margin`, `deductible_expenses`, `damage_cost`, `shortage_cost`,
`net_profit`, `investor_share_percent_applied`, `investor_capital_weight_applied`,
`total_pool_capital`, `total_investor_capital`.

Partial unique index: **at most one open period per pool**. The admin may move an open period's
`ends_on`; a closed period is immutable.

> These frozen columns are not a breach of «الرصيد لا يُخزَّن». They are a historical close, the way
> `manufacturing_cost_rates` snapshots an applied rate — not a running balance that could drift from
> the rows beneath it.

**`investment_period_shares`** — the per-investor record of one close: `investment_period_id`,
`investor_id`, `capital`, `share_percent`, `net_share`, `is_company`. Unique on (period, investor).

**`investment_realized_earnings`** — a pool's profit-and-loss ledger as it accrues:
`investment_period_id`, `source_type`, `source_id`, `source_sequence`, `amount`, `occurred_at`,
`recorded_by`. Unique on (source_type, source_id, source_sequence, period) — one event is never
posted twice to one pool, and one order that drew from three pools writes three rows.

> `amount` is **signed** here, unlike `investor_wallet_entries`. The positive-only rule exists in the
> wallet because a row there moves value *between pots* and the type must say which direction. This
> table is one party's P&L, where a negative margin on a dear lorry is an ordinary figure — the same
> way `orders.gross_profit` is already signed.

**`investment_capital_requests`** — queued entry and exit: `investor_id`, `investor_deal_id` (the
pool), `direction` (`in` / `out`), `amount`, `requested_at`, `effective_period_id`, `status`
(`pending` / `applied` / `cancelled`), `applied_entry_id`, `notes`.

**`investment_settlements`** — the periodic comprehensive review of your §10, **per pool**:
`investor_deal_id`, `code`, `period_from_id`, `period_to_id`, `settled_on`, `approved_by`, and the
snapshot — `total_capital`, `investor_capital`, `company_capital`, `deployable_cash`,
`stock_at_cost`, `receivables`, `liabilities`, `distributed_profit_to_date`, `damage_to_date`,
`shortage_to_date`, `drift`, `notes`.

A settlement is a **review and approval point**. It does not close the pool and does not liquidate
stock.

---

## 8. Settings screen

Global, and therefore shared by every pool (§4.2).

| Setting | Default | |
|---|---|---|
| Profit period length | 1 month | months; the admin may additionally move an open period's end date |
| Settlement period | 6 months | months |
| Entry grace days | 3 | `0` = strict boundary |
| الحد الأدنى للبقاء | 0 | months before an investor may ask to withdraw; `0` = no minimum. The company is exempt (§6.6) |
| Investor profit share | 50% | already exists |

**Next close and next settlement are derived**, not stored — the open period's `ends_on`, and the
last settlement plus the interval. The settlement snapshot publishes `next_settlement_due_on` and
`settlement_is_overdue` from that arithmetic; a pool nobody has settled yet is **not** overdue,
because inventing a due date from the day it opened would put a warning on every new pool. So a settings change can only ever affect future periods; a
closed period is unreachable from here by construction rather than by a guard someone remembers.

---

## 9. When profit is realized — which period a sale lands in

Two roads, both kept, both with their arithmetic unchanged.

| Road | Realized at | Formula |
|---|---|---|
| **Priced** — سعر السادة set on the layer | the press draws the stock, at «جاهزة للطباعة» | `sale_price × quantity − total_cost` |
| **Unpriced** | delivery, «تم الاستلام» | the order's `grand_total − total_cogs`, sliced by shelf |

What changes is only the destination: the margin is written to `investment_realized_earnings`
against the **open period of the pool that owned the layer**, instead of being split into
per-investor wallet rows on the spot. An order that drew paper and ink writes one row into each
pool's period.

**Consequence worth knowing before it surprises someone:** a priced draw is realized *earlier* than a
sale. A bag drawn on 29 September for an order delivered on 3 October belongs to **September**. That
is already how the code behaves; periods merely make it visible.

An order that draws stock but is later cancelled is handled by the existing reversal machinery, which
writes a correcting row against whichever period is open when the cancellation happens.

### 9.1 Who sets سعر السادة, and when

**Per purchase, by whoever marks the line for pool money** — the same act and the same grant
(`investors.manage`) that decides pool-or-company in §4.3, and the same moment: before the lorry
arrives, because the cost layer is stamped at the gate and can never be stamped afterwards.

Today the price is asked for once, on the funding form, and frozen for the deal's whole life
([`FundPurchaseOrderRequest`](../../backend/app/Application/Api/V1/Requests/Investor/FundPurchaseOrderRequest.php)).
That made sense when a deal *was* one lorry. A pool outlives every lorry it buys, so the price moves
onto `investor_deal_supplies` — one agreed price per purchase, 32/kg for this lorry and 35 for the
next — and `ReceivePurchaseOrder` stamps it onto the layer from there, unchanged.

The rules that survive intact: nullable (empty means «nobody said», which is the other road); minimum
`0.001`, because the column rounds to three places and anything smaller reaches the `CHECK` as a flat
zero; and **frozen once the goods arrive**, because the layers carry it and a layer is never
rewritten. Changing a price is a decision about the *next* purchase.

`investor_deals.printing_sale_price` becomes unused on pool rows and keeps its meaning on legacy
deals (§7.1).

### 9.2 A pool may hold both roads at once

**This is legal and needs no special handling.** A pool can buy one lorry at سعر السادة and the next
without it, because the road is a property of **the layer**, not of the container — the price is
stamped per batch, and [`MaterialCost`](../../backend/app/Domain/Order/Support/MaterialCost.php)
asks the layer, never the pool.

So one pool's period can accrue margin from both roads at different moments:

```
15 Sept   printed line draws lorry A's priced stock   → margin realized now
28 Sept   order carrying lorry B's stock is delivered → profit realized now
30 Sept   period closes on the sum of both
```

Both are ordinary rows in `investment_realized_earnings` against the same open period, and §6.2 adds
them without caring which road produced them. **A deal could never do this** — its single
`printing_sale_price` put it wholly on one road for life — and that restriction simply does not carry
over.

### 9.3 The shelf margin accrues to the period, and splits at the close

The one thing that genuinely changes about سعر السادة, and it is worth stating plainly because the
timing looks wrong at first glance.

Today the margin is split **the moment it is realized**, by
[`investorsCutOf()`](../../backend/app/Domain/Investor/Models/InvestorDeal.php) — the deal's frozen
`investor_funded_percent` times its `investor_profit_share_percent`. Both are known on the day,
because both were frozen when the lorry was funded.

Under pools the middle factor is **capital weight, which is not known until the period ends**. So a
priced draw on 15 September cannot be split on 15 September.

It does not need to be:

```
15 Sept   margin 4,000 realized  → ONE row in investment_realized_earnings, whole and unsplit
30 Sept   period closes          → margin joins the period's other realized earnings
                                 → §6.3 splits the period's net profit by capital weight
```

The margin is **earned** when the press takes the goods; it is **divided** when the period closes.
That is exactly the treatment every other realized figure gets, and it is why
`investment_realized_earnings` holds a whole amount with no investor on it.

**What this costs, said honestly:** a man who joins the pool on 1 October shares in a margin realized
on 15 September only if that margin had not yet been distributed — and it always has been, because
the period closed on the 30th and released everything. The grace window (§5) is what makes that true,
and it is the same argument as §6.5.

---

## 10. The company's position

The company is a **participant in each pool's capital** — one reserved `investors` row flagged
`is_company`, holding a share row per pool — and is additionally paid the operator's cut
(`investor_profit_share_percent`, 50%) out of each pool.

This is deliberate: it needs no new machinery at all. The company's money flows through the same
ledger, takes the same capital weight, and appears on the same period share table. The three-factor
formula in §6.3 is the existing two-factor one with the company's stake generalised from "frozen
fraction of one lorry" to "its capital weight in this pool this period".

---

## 11. Migration — and the old deals survive

**Production data exists.** The overriding constraint: **no existing deal is destroyed.**

### What is preserved

Legacy `investor_deals` rows are marked `kind = 'deal'` and frozen read-only. Their rows, their
wallet entries, their expenses, their stock tags, their supplies and their audit trail all stay
exactly where they are. Every existing deal screen keeps rendering.

### How pools are born

**From the open deals themselves.** The fold-in command groups every open deal's stock items, and
proposes one pool per distinct material grouping — with its name, its shelves and its opening
investors. You approve or edit that proposal before anything is written.

A legacy deal spanning two shelves that belong in two different pools is reported as a **split**, and
its capital is apportioned by the cost of the stock sitting on each side. This is the one case that
needs your eyes, and the dry-run names every instance of it.

### What moves

Only the capital and stock of **open** deals, and it is not a data rewrite: the fold-in is a
`release` from the deal plus an `allocation` to the pool, through the ordinary append-only ledger.
Reversible by reversal rows, fully audited, nothing `UPDATE`d destructively.

### Protocol

1. Full database backup. Import production into the local database.
2. `php artisan investment:fold-in --dry-run` — prints the proposed pools, every deal, every
   investor, every opening balance and every split it *would* write. **Writes nothing.**
3. Review the printout.
4. Real run: one transaction, append-only.
5. Assertion before commit: `Σ capital per investor before = Σ capital per investor after`, and
   `Σ stock at cost before = Σ stock at cost after`. Any mismatch rolls the transaction back.
6. Only after the local run is verified does this go near production.

Open deals with stock still on the shelf fold in at that stock's **cost**, so the identity in §6.5
holds from period 1 onward.

---

## 12. Screens

**Pools list / roll-up** — every pool with its capital, deployable cash, stock at cost, current
unsettled profit, and the company-wide totals beneath: total capital across pools, total cash, total
stock, **total undrawn profit owed** (shown separately, never summed into cash), next close date,
next settlement date.

**Pool detail** (your §13, per pool) — capital, investors, deployable cash, stock at cost by shelf,
period sales, unsettled profit, distributed profit, expenses.
Sections: Investors · Stock · Sales · Profit · Expenses · Periods · Settlements.

**Investor detail** — his position in **each** pool, his profit wallet (one, not per pool), pending
capital requests, per-period share history, withdrawals.

**Periods** — the register per pool, each closed period showing its frozen snapshot and per-investor
split.

**Settlements** — the history per pool, each with its snapshot and drift.

**Settings** — global, §8.

**Investor portal** — his pools and their periods.

---

## 13. What this costs

- `CloseInvestorDeal` is replaced by `CloseInvestmentPeriod`, run over every pool. Its two refusals —
  stock on the shelf, orders in flight — do **not** apply to a period close; a period closes with
  stock on the shelf, and that is the point. The in-flight concern survives in a different form:
  profit is recognised at delivery, so an order whose stock has left but which is not yet delivered
  simply has not accrued. Worth an explicit test.
- `FundPurchaseOrder` splits into two acts: *add capital to a pool* and *buy stock from pool cash*.
- `ClaimDealSupply` shrinks to a yes/no per line (§4.3) — **less** code than today.
- `PostDealEarningsForOrder` and `PostDealStockPurchases` stop writing per-investor rows and write
  one realized-earning row per pool touched.
- The per-order investor-shares screen changes meaning: during an open period it can show each
  **pool's** slice of that order, not per-investor amounts, because the weights are not known until
  the close. After the close it can show them at that period's weights.
- ~3,700 lines of tests in [tests/Feature/Investors/](../../backend/tests/Feature/Investors/) are
  reworked. Most assertions survive; the setup does not.
- [INVESTOR-DEALS-DESIGN.md](../investor-deals/INVESTOR-DEALS-DESIGN.md) and
  [INVESTOR-DEALS-HOW-IT-WORKS.md](../investor-deals/INVESTOR-DEALS-HOW-IT-WORKS.md) are marked
  superseded for new work, and kept for the legacy deals they still describe.

---

## 14. Implementation slices

| # | Slice | Contents | Risk |
|---|---|---|---|
| 0 | Pools and settings | `kind` column, `investment_pool_items` + its unique index, settings columns and screen, `investment:fold-in` with `--dry-run` and split reporting | **high** — touches live data |
| 1 | Continuous capital | `investment_capital_requests`, grace window, queued entry and exit per pool, warning before submit | medium |
| 2 | Purchases | pool-or-company yes/no per line, automatic pool routing, refuse over-spend, سعر السادة per purchase | medium |
| 3 | Period close | `investment_realized_earnings`, `investment_periods`, `CloseInvestmentPeriod` over every pool, distribution, loss write-down, `investment_period_shares`, the returned-goods question (§6.2.1) and the close-blocking guard, late-expense rule (§6.2.3) | **high** — the money |
| 4 | Settlement | `investment_settlements`, the §6.5 identities, drift reporting | low |
| 5 | Flutter | pools list + roll-up, pool detail, periods, settlements, settings, reworked investor detail, the «محسوبة مسبقاً» markings in all three places (§6.2.4) | medium |

Slices 0 and 3 carry the real risk and should each land with their tests before the next begins.

---

## 15. Settled questions

| | Decision |
|---|---|
| Pool scope | One pool per material. Each investable stock item belongs to exactly one pool (§4.1) |
| Investor in several pools | Yes. Separate capital, share and periods in each; one shared profit wallet |
| Calendar | Global settings, so all pools share period boundaries; one close action iterates them (§4.2) |
| Entry / exit valuation | Plain capital ratio, made exact by the grace-window rule (§5). No units, no NAV, no day-weighting |
| Minimum term | 6 months from his **first** capital into the pool. The company is exempt. Gates the request, not the payout (§6.6) |
| Exit ceiling | His capital weight × the pool's deployable cash, capped by what he owns — never out of goods, and never another partner's share of the cash (§6.6) |
| Company capital | Participates in each pool **and** takes the 50% operator cut (§10) |
| Losses | Written down against that pool's capital at close, capped at what each put in. Never carried forward, never crossing pools (§6.4) |
| Undrawn profit | Ring-fenced. Never working capital. A wallet figure, not a pool figure (§6.1) |
| Expenses | Manual and non-landed automatic ones are deducted; purchase-order shipping and customs are recorded and not deducted. One invoice across two pools is two rows (§6.2.2) |
| Expense period | By `incurred_on`. One dated inside a closed period goes to the open one with a visible note — never back-dated (§6.2.3) |
| Cancelled orders | وسيط and priced-material cancellations are the company's loss and never reach a pool. **سادة goods return to the pool intact and are never a loss.** Only a *printed* line's unpriced material can be ruined, and that ruin is a `damage` the close refuses to proceed without an answer on (§6.2.1) |
| Double-subtraction | Already-counted costs are marked «محسوبة مسبقاً» on the expense form, the expense list and the close screen, and excluded from the arithmetic (§6.2.4) |
| Printed products | Both roads kept, arithmetic unchanged; price moves to **per purchase**, set by whoever marks the line for pool money (§9.1) |
| Mixed roads | One pool may hold priced and unpriced lorries at once — the road is a property of the layer, not the container (§9.2) |
| Shelf margin timing | Earned when the press draws the goods, **divided** when the period closes; it accrues whole to `investment_realized_earnings` (§9.3) |
| Existing deals | Preserved in place, read-only. Open ones folded into proposed pools via the ledger (§11) |

## 16. Open

- **Moving a shelf between pools.** Not supported in this design. A stock item's pool is fixed once
  set, because its cost layers and its history carry that pool. If it is ever needed, it is a new
  pool plus a fold-in, not an `UPDATE`.
- **Receivables.** Profit is recognised at delivery, so an order delivered and not yet collected
  counts as pool cash. This is deliberate and inherited from the deal model
  ([INVESTOR-DEALS-DESIGN.md §س٨](../investor-deals/INVESTOR-DEALS-DESIGN.md)). Uncollected customer
  debt against a pool's sales becomes a **named line in its settlement**, not a silent gap.
- **Bad debt.** Not modelled today for deals either. Deferred; it belongs in the settlement.
- **Currency.** Single currency, as today.
