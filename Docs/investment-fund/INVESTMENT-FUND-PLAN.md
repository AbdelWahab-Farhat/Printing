# Investment Pools — the build plan

The companion to [INVESTMENT-FUND-DESIGN.md](INVESTMENT-FUND-DESIGN.md). That document says **what
the system is**; this one says **what gets built, in what order, and how each step is proved**.

**Status — 2026-09-20.** Branch `investment-pools`, **uncommitted and unpushed**.
**All five slices complete**, backend and Flutter, tests green. See *Where the work stands* below before resuming. Section references like «§6.2» point at the design
document.

---

## Where the work stands

Written 2026-09-20 so the next session can resume without re-deriving anything.

### Done, with tests green

| Slice | What landed |
|---|---|
| **0** | `kind` on `investor_deals`, `investment_pool_items` + its unique index, the three settings columns, `share_percent` nullable · `PoolKind`, `CreatePool`, `UpdatePool`, `SyncPoolItems`, `PoolListQuery`, `PoolData` · `InvestmentPoolController` + resource + request · `investment:fold-in` with `--dry-run` · **23 tests** |
| **1** | `investment_periods`, `investment_capital_requests` · `GraceWindow`, `OpenInvestmentPeriod`, `RequestPoolCapital`, `CancelCapitalRequest`, `ApplyCapitalRequests` · five endpoints · **12 tests** |
| **2** | `printing_sale_price` on `investor_deal_supplies` · `PoolDeployableCash`, `BuyPurchaseOrderLinesFromPools` · two endpoints · **9 tests** |
| **3** | `investment_realized_earnings`, `investment_period_shares`, `investment_returned_goods_questions`, `investment_period_id` on expenses, `is_company` on investors · `PeriodDistribution`, `PeriodNetProfit`, `CloseInvestmentPeriod`, `PostPoolEarning`, `PostContainerResult`, `RaiseReturnedGoodsQuestions`, `RecordReturnedGoodsVerdict` · `OrderStockReturned` event + listener · `ReturnedMaterialQuery` · permission `investment_periods.close` · **17 tests** (7 pure unit) |
| **4** | `investment_settlements` · `SettlementSnapshot` (the two independent derivations and the drift), `RecordSettlement` · three endpoints · permission `investment_settlements.record` · **10 tests** |
| **5** | Flutter: `investment_pools` feature — 5 models, repository, 18 usecases, 4 cubits, 4 pages, 5 widgets · a new `company_settings` feature (§8), which **did not exist in the app at all** · endpoints, DI, 5 routes, 2 drawer entries · `dart analyze lib` clean |
| **3** (finish) | The two returned-goods endpoints — `GET investment-pools/{pool}/returned-goods` (with `only_open`) and `POST investment-returned-goods/{q}/answer` · resource + request · `returnedGoodsQuestions()` on `InvestorDeal` · **17 tests** across `ReturnedGoodsQuestionTest` and `ReturnedGoodsRaisedTest` |

### Left to do

1. **~~Execute `investment:fold-in`~~ — decided against, 2026-09-20.** The fold exists to rescue
   capital stranded in a deal that still holds stock. D1 held 579 units; that drains. So instead:
   pool **D2 «أكياس الشحن»** was opened over D1's four shelves and D1 was left alone. New lorries
   open D2 layers; FIFO keeps drawing D1's older ones, so it drains while its partner goes on
   earning from it, and `CloseInvestorDeal` closes it the ordinary way when it is empty.

   **The command stays in the repository, unrun.** It is still the right tool if a deal ever has
   to be moved with stock on the shelf — but on this data it would have been a one-time migration
   script exercised once, on live money, to avoid a wait that resolves itself.
2. **~~A decision for the owner~~ — decided, 2026-09-20.** The open period's profit stays out of
   `deployable_cash`. See *The open period's profit* below, kept for the reasoning.
3. **Two pre-existing Flutter failures, neither this branch's.** Both verified: no file either
   one touches is modified or added here.

   - **`comments_page_test.dart` — 18 failures.** `a7ae7d7` added a `MarkThreadRead` call to
     `CommentsPage.initState`; the test builds its own GetIt container and registers it zero
     times.
   - **`sales_statistics_page_test.dart` — 1 failure.** It expects the caveat «…ولا وزن لها»,
     and that string exists nowhere in `lib/`. The test and the screen disagree.
3. ~~`composer spec` and the superseded banners~~ — **done.** `Docs/openapi.json` carries all 12
   pool endpoints; all three `investor-deals/` docs and the `Docs/README.md` index now say the
   صفقة is read-only-but-alive and that new work goes to `investment-fund/`.

   `scramble:export` needs `-d memory_limit=2G` like the suite does; it dies at the default 128M.

### Three defects found while finishing Slice 3, all fixed

- **One question per line was the wrong key.** `SyncPoolItems` lets a shelf move from one pool to
  another and **the cost layers stay behind** — they are what the old pool's investors paid for. A
  single cancelled line can then draw FIFO straight through the boundary, leaving ruined paper in
  both pools; under `UNIQUE (order_item_id)` only the first could ever be asked about, and the
  second pool would close its period over goods it no longer has. Migration `…101200` widens the
  index to `(order_item_id, investor_deal_id)`.
- **`ReturnedMaterialQuery` would have thrown under strict mode.** It calls `isPrinted()`, which
  walks `product.productCategory.parent`, while eager-loading only `variant` —
  `Model::shouldBeStrict()` is on everywhere but production, so every cancellation of a printed
  order would have raised a lazy-loading violation. The load is now where the read is.
- **A pre-existing factory collision, not this branch's.** `ProductVariantFactory` and
  `StockItemFactory` each kept their own `20 + (++seq % 40)` counter, and a variant mints its shelf
  at *its* size — two independent sequences feeding one unique index. Any test creating a bare shelf
  beside a variant could die on `stock_items_name_size_unique` with nothing in the message to say
  why. They share one counter now, via `StockItemFactory::nextSize()`.

### The open period's profit — **decided: it stays unspendable**

The owner's answer, 2026-09-20: a pool may **not** spend the margin it earned in the still-open
period. The reasoning below is kept because the figure is real and somebody will ask about it
again — it is named on every settlement as `undeployed_current_profit`, beside `deployable_cash`
and never added to it.



**`deployable_cash` does not let a pool spend the margin it earned this month.** It reads
`profit_deal` from the wallet ledger, and a pool's profit only ever appears there at the close and
leaves again in the same transaction, so the figure is always zero. The pool's undivided earnings
live in `investment_realized_earnings`, which that query does not consult.

The effect: a pool with 100,000 capital that buys a 60,000 lorry and sells half of it at a 10,000
margin is holding 80,000 in cash, and the purchase screen will offer it 70,000.

`PoolDeployableCash`'s own docblock says this money *is* spendable, and design §6.1 calls recycling
it «إعادة تدوير الأموال» — the point of the whole scheme. But **this changes how much money a pool
may commit**, which is the owner's call and not a bug fix to make quietly. Note that it is a
different question from «may the company use undrawn profit as working capital», answered **NO**:
that money is settled and belongs to named people, while this month's margin belongs to nobody yet.

Nothing has been changed. Slice 4 names the figure instead — `undeployed_current_profit`, its own
line on every settlement, shown beside `deployable_cash` and never added to it. Making it spendable
afterwards is one line in `PoolDeployableCash` plus its test.

### Capital in and out — the rules as the owner settled them, 2026-09-20

| | |
|---|---|
| **الحد الأدنى للبقاء** | **6 months** before an investor may *ask* to withdraw. Migration default is **0**, so a deploy never locks anybody by surprise; the value is set from the settings screen. |
| Measured from | His **first** capital into that pool — a top-up does not restart the clock, or paying more in would be a reason to be locked in longer. Money taken out entirely and later returned starts again: it is new money. |
| The company | **Exempt from the term.** It is the operator, it absorbs the losses that run past a partner's capital, and its money in the pool is working capital it has to be able to move. Still capped by the arithmetic below. |
| What he may be **paid** | His **own slice** of the pool's cash — his capital weight × `deployable_cash` — capped by what he owns. Never out of goods on a shelf. |
| Why the slice and not the pool's whole cash | Without the weight, whoever queued first could empty the till and leave the others waiting on a lorry selling. Same pool, same month, same right to leave, and only the order of asking decided it. |
| Weights | Snapshotted **before anybody is paid**, so the split does not depend on queue order. A man with two standing requests is tracked across both. |
| When it is checked | The term gates the **request**, never the payout — an exit already queued was legitimate the day it was made, and lengthening the term must not strand it. |

**«لا يسحب حتى لا يبقى له شيء في البضاعة» was considered and rejected.** Taken literally it means an
investor may leave only when the pool holds zero stock — and a working pool always holds stock. It
is the same trap as waiting for a press to have no orders in flight: a condition that sounds
reasonable and never occurs. What it was reaching for is the cash cap, which already existed.

### مدة التسوية now does something

It was stored, editable and consumed by **nothing** — zero callers. `SettlementSnapshot` now derives
`last_settled_on`, `next_settlement_due_on` and `settlement_is_overdue` from it. A pool nobody has
ever settled is **not** overdue: it has no last settlement to count from, and inventing one from the
day it opened would put a warning on every new pool, which is how people learn to ignore warnings.

### Bugs found by using it, 2026-09-20

- **Capital went in and the roster stayed empty.** A صفقة's roster *was* ownership and was written
  when the deal was struck; a صندوق has no such moment, and the migration that made
  `share_percent` nullable **for pool rosters** was written without the code that inserts the row.
  Fixed in `EnsurePoolMembership`, called from **`RecordWalletEntry`** — not from the capital
  request, because `allocation` is recordable by hand and money can reach a pool without ever
  touching a request. Four tests.
- **The roster showed names and no amounts.** Each member now carries his current capital, walked
  once for the whole list rather than per member.
- **No way to open a pool from the app.** The list, the detail, the periods, the settlements and
  the close were all built; the *create* form never was, and the usecases sat registered in DI with
  nothing calling them. Added, with an edit action on the pool screen.
- **No way to enter an expense on a pool.** The API worked all along — the route is not scoped to
  deals and `RecordDealExpense` forks on `isPool()` — but the only form was on the legacy deal
  screen. Added, with the «محسوبة مسبقاً» warning shown *before* the figure is typed.

- **`investment_period_shares` was written by the close and read by nothing.** The record of what
  each investor's weight was and what he was paid — §12's «حصة كل مستثمر» — existed faithfully in
  the database and was reachable from no endpoint and no screen. Now
  `GET investment-periods/{period}/shares`, shown as «من أخذ ماذا».
- **The roster had no percentage.** The model docblock said «no percentage — ownership is
  recomputed at every close», which is an argument against showing a *stored* share and became an
  argument against showing any. The live weight is his capital over the pool's, derived on read.
- **No endpoint listed expenses — only `POST`.** So a form that had worked looked exactly like one
  that had not, and the owner saved the same expense twice. `GET investment-pools/{pool}/expenses`
  now, listed on the pool's screen with «محسوبة مسبقاً» rows drawn differently so nobody adds up a
  total the close does not use.
- **`is_company` was exposed nowhere in the app.** The company's own investor row looked like a
  person named «الشركة» — renameable, and deactivatable by somebody who took it for an ordinary
  investor, which would have stopped every pool paying the company silently at the next close. It
  is badged in the register now, and «الشركة · موقوف» when both.
- **No screen could mark a purchase-order line for pool money.** `BuyWithPoolMoney` sat registered
  in DI, called by nothing — so stock bought after a pool was opened was never connected to it.
  This was the one the owner hit in practice.

- **A period does not close itself, and deliberately has no scheduled job.** It is reported
  overdue instead — `is_overdue`, `days_overdue`, and `blocked_by_returned_goods` on the open
  period, shown as a warning on the periods screen. A cron that pays money into withdrawable
  wallets unattended, or fails nightly in silence over one unanswered question, is worse than a
  mark somebody looks at.

### Decisions taken while building that are not in the design

- **Slice 1 absorbed the `investment_periods` table** from Slice 3. The grace window is a sentence
  about two periods; neither exists without it.
- **`CloseInvestmentPeriod` opens the next period** in the same transaction, so a pool is never
  without one — a sale realized in the gap would have nowhere to accrue.
- **`CreatePool` opens the pool's first period**, for the same reason.
- **A correction never reaches into a closed period.** `PostPoolEarning` writes the *delta* into
  whichever period is open. This is a real behavioural difference from the deal model, which could
  reverse the original outright because its profit was not released until the deal ended.
- **`PostContainerResult` is the single fork** between the two models: a legacy صفقة has
  `investorsCutOf()` applied immediately; a pool banks the **undivided** slice.
- **A pool's expense writes no `loss` rows** — it is charged to a period and subtracted once, at
  the close.
- **«تالفة» posts a stock adjustment, not an expense**, so the goods actually leave the shelf.
- **Answering a returned-goods question is `inventory.manage`, not an investor grant.** It writes
  off stock against a warehouse — the same authority every other write-off needs — and the person
  qualified to judge is the one holding the paper, not the one who divides the profit. Reading the
  queue stays `investors.view`, because it sits on the pool's screen.
- **A settlement's drift is a comparison of two derivations, not the §6.5 identity as written.**
  Asked of `PoolDeployableCash` alone that identity is a tautology — it *defines* deployable cash as
  book value less stock — so it would print zero on the day somebody wrote a lorry off the shelf.
  `SettlementSnapshot` rebuilds the right-hand side from the movements instead.
- **A loss the company absorbs is an inflow in that walk**, not drift. It moves no cash across a
  counter, but the pool really does go on holding goods it could not otherwise have paid for.
- **Signing a settlement has its own grant** (`investment_settlements.record`) although it moves no
  money: it is somebody putting their name to «these are the books», which is not the same act as
  editing a pool's shelves.
- **`minimum_term_months` is a *required* field on `PUT /settings`.** The endpoint saves the whole
  screen or nothing — its own docblock calls a partial write the drift that makes a client believe
  it saved something it did not — so the new field is required like its siblings. **Any other
  client of that endpoint must send it.**
- **No `investment.settings.manage`** — `settings.view` / `settings.manage` already fit.
- **The Flutter `AppPermission` enum was missing `investment_periods.close`** from Slice 3, so
  `permission_contract_test` was already red before Slice 4 added a second one. Both are in now.
- **The staff app had no company-settings screen at all.** `settings_page.dart` is device
  preferences and logout; the four §8 numbers had a backend endpoint and nothing calling it. Slice
  5 adds a `company_settings` feature for them, in the drawer beside the صناديق rather than under
  «الإعدادات» — a person hunting «متى تُقفل الفترة؟» looks where the pools are.
- **The close screen computes nothing.** It fetches `periodFigures` and prints it, because the
  same query backs the close itself. A second implementation in Dart is how a person approves one
  number and the ledger writes another.
- **The settlements screen leads with the drift**, above the eleven totals, for the same reason
  the table stores it: a finding under a pile of reassuring figures is decoration.
- **No Eloquent scopes** — this codebase has none; the `kind` filter lives in the Queries.
- **`{pool}` is route-bound to `kind = 'pool'`** in `AppServiceProvider`, so a legacy deal can never
  be reached through a pool route.

### Environment notes for resuming

- **PHP is off `PATH`.** Use `/c/Users/ONYX/.config/herd/bin/php84/php.exe` (8.4). The XAMPP binary
  at `/c/xampp/php/php.exe` is 8.2 and PHPUnit refuses it.
- Run the suite as `php -d memory_limit=2G vendor/bin/phpunit`. A full run takes ~13 minutes.
- **Flutter is off `PATH` too** — `/c/Users/ONYX/dev/flutter/bin/flutter.bat` and `dart.bat`.
  Scope `dart analyze` to changed paths, as with Pint.
- **Baselines to compare against**: backend **2,396 / 2,399** (only `DropProductTypeMigrationTest`
  red); Flutter **2,197 / 2,216** (only the 19 pre-existing failures above); `dart analyze lib`
  clean.
- **Never run two suites at once** — both hit `printing_bags_test` and deadlock on `RefreshDatabase`
  teardown. The deadlock errors look like real failures and are not.
- **Pint only on changed paths**, and check `git status` afterwards: scoping it to a whole domain
  folder reformats files this branch never touched.
- `DropProductTypeMigrationTest` fails on `main` too. It is **not** this branch's doing.
- **`OrderTotalWeightTest::test_weighing_the_list_costs_no_query_per_order` is flaky.** It asserts
  a query count and read 15 where it expects 14, **once in eight full runs**. It passes alone
  (10/10), passes in `tests/Feature/Orders` (684/684), and did not recur on the next full run.
  Cross-suite state warming one extra query is the likely cause. Recorded rather than dismissed:
  if it turns up again, that is the thread to pull.

---

## How to use this

Each slice below is a complete unit of work: it migrates, it builds, it tests, and it leaves the
application working. A slice is finished when its **Done when** list is true — not when the code is
written.

Slices 0 → 1 → 2 → 3 are strictly ordered; each depends on the one before. Slices 4 and 5 may follow
3 in either order.

**Slices 0 and 3 carry essentially all the risk.** Each lands with its own tests before the next
begins, and neither is bundled with another slice in one commit.

---

## Sequencing

```
  0  Pools and settings  ──►  1  Continuous capital  ──►  2  Purchases  ──►  3  Period close
     (schema only)                                                             + THE FOLD-IN
                                                                                     │
                                                                       ┌─────────────┴─────────────┐
                                                                       ▼                           ▼
                                                                4  Settlement               5  Flutter
```

> **The fold-in moved out of Slice 0 on 2026-09-20, and the reason is worth keeping.** The command
> was built in Slice 0 and run against production data, where it refused: D1 had seven orders in
> flight. That refusal is correct and cannot be relaxed — but a working press **always** has orders
> in flight, so the window it waits for does not occur. Folding before periods exist would also
> have to preserve a deal's frozen `investor_funded_percent` through a transition that Slice 3
> deletes anyway.
>
> So Slice 0 ships the schema, the pool concept and the command; **the fold is executed in Slice 3**,
> when an in-flight order simply resolves into the pool's open period and no frozen terms need to
> survive the journey. See §Slice 0 → *What is deliberately not executed yet*.

---

## Ground rules for every slice

**Verification is automated, never manual.** Tests and static analysis decide whether a slice is
done. No emulator tapping, no screenshotting a screen to see if it worked.

**Backend checks.** `php` is not on `PATH` in this environment and the full suite needs a raised
memory limit, so it is run through PHPUnit directly rather than through the artisan wrapper. Pint is
**not** clean repository-wide — always scope it to the paths the slice changed, never run it across
the repo.

**Flutter code generation.** `build_runner` stalls when launched from the agent session. The plan is
to ask the owner to run it in their own terminal at the points marked in slice 5.

**Money arithmetic is `bc*`, never floats**, at the scales the existing
[`Money`](../../backend/app/Domain/Investor/Support/Money.php) helper already fixes. Splits use
largest-remainder allocation so the parts sum to the whole exactly.

**Invariants live in PostgreSQL wherever a single row can express them**, and under a row lock in PHP
where they cannot — the discipline the existing investor schema already follows.

**Nothing is `UPDATE`d destructively in the ledger.** A correction is a further row pointing back.

---

## Slice 0 — Pools and settings

**Goal.** The pool exists as a container and the settings that govern every pool exist. The fold-in
command is built and proved, but **not executed** — see below.

> **Schema only.** Every migration here is additive and every existing row keeps its meaning, so this
> slice is reversible by reverting code and rolling back. The irreversible act — moving real money
> and re-pointing real cost layers — was moved to Slice 3.

### Migrations

| | |
|---|---|
| `add_kind_to_investor_deals_table` | `kind` — `'deal'` (legacy) or `'pool'`. Default `'deal'`, and every existing row backfilled to it, so nothing changes meaning on deploy. `name` reinstated for pools |
| `create_investment_pool_items_table` | `(investor_deal_id, stock_item_id)`, plus `UNIQUE (stock_item_id) WHERE deleted_at IS NULL` — the §4.1 invariant, held by the database |
| `add_investment_settings_to_company_settings_table` | `profit_period_months` (1), `settlement_period_months` (6), `entry_grace_days` (3), each with a range `CHECK` |
| `allow_null_share_percent_for_pool_rosters` | `investor_deal_shares.share_percent` becomes nullable. A pool's roster carries **null**, not zero and not an even split: ownership is recomputed from capital at every close, and any figure here would be a second answer to a question that already has one |

### Domain

- `Enums/PoolKind` — `deal` / `pool`, with `label()`.
- `InvestorDeal` gains `isPool()` — one predicate, not a second Eloquent model on the same table:
  this codebase has no single-table inheritance anywhere, and two models over one row would get the
  chance to disagree about it.
- **The `kind` filter lives in the Queries, not in a model scope.** This codebase defines no Eloquent
  scopes at all; reusable reads are `Queries/` classes. `PoolListQuery` selects pools and
  `DealListQuery` gains the matching filter — without which the day pools arrived would have been the
  day the deals screen silently started listing them.
- `Actions/CreatePool`, `Actions/SyncPoolItems` — the latter puts every shelf through
  `CatalogService::stockItemInvestability()`, exactly as `SyncDealItems` does today, so وسيط and
  non-investable headings are refused at the door.
- `Queries/PoolListQuery`.
- `SettingsService` and `CompanySetting` extended with the three new values.

### The fold-in command

`php artisan investment:fold-in [--dry-run]`

The dry-run prints, and writes nothing:

1. the **proposed pools** — connected components over the shelves the open deals share, with their
   materials, the deals feeding each, and the opening capital per investor;
2. each component's opening stock at cost;
3. a **warning on any component holding more than one material**, which is usually right («ورق ٧٠غ»
   and «ورق ٩٠غ» belong together) and occasionally not — the one judgement only the owner can make.

> **There is no «split» case, and the earlier draft of this plan was wrong to promise one.** Pools are
> derived as connected components, so a deal never straddles two of them: a deal funding two shelves
> *is* what binds those shelves into one pool. A split can only arise once a grouping override exists,
> which is not built — so apportionment machinery would have been code with no way to reach it.

The real run is one transaction, append-only: a `release` from the deal and an `allocation` to the
pool, through the ordinary ledger. Before commit it asserts

```
Σ capital per investor before  =  Σ capital per investor after
Σ stock at cost before         =  Σ stock at cost after
```

and rolls back on any mismatch.

### API and permissions

`investment-pools` index / store / show / update / logs, and the existing `settings` endpoints grown
to carry the calendar. Reuses `investors.view` / `investors.manage` and `settings.view` /
`settings.manage` — **no new permission**: the existing four fit exactly, and a fifth would have been
ceremony.

**`{pool}` is bound in `AppServiceProvider` to `kind = 'pool'`.** Without it `PUT
/investment-pools/7` would rename a legacy صفقة, breaking the one promise this whole migration makes.
A binding rather than a check per controller method, so the guarantee covers every pool route added
in the slices after this one.

### Tests

- A pool is created and its shelves attached; a non-investable shelf is refused.
- **The unique index refuses a second pool claiming the same stock item.**
- Legacy deals are untouched, still readable, still rendering — the existing deal test suite passes
  unchanged.
- `--dry-run` writes nothing at all (asserted by row counts before and after).
- The fold-in preserves capital per investor and stock at cost.
- Two deals sharing a shelf land in **one** pool; deals on unrelated shelves get a pool each.
- The pool inherits every frozen term, so `investorsCutOf()` gives the same answer on both sides of
  the fold (see the bug below).
- A pool's roster carries a null percentage.
- A legacy deal cannot be reached through a pool route.
- Settings changes are range-checked, and a partial payload is refused rather than resetting what it
  omits.

### What is deliberately not executed yet

**The command is built and tested in this slice; the fold itself happens in Slice 3.**

Running `--dry-run` against production data on 2026-09-20 returned:

```
صفقات لها طلبيات لم تُسلَّم بعد — انتظر تسليمها قبل الترحيل:
  D1 — 1285، 1287، 1290، 1291، 1293، 1295، 1297
```

Two groups, and both blocks are real:

| Orders | Why they block |
|---|---|
| 1285, 1287, 1290, 1291, 1295 | carry **unpriced** lines — the investor is still riding the sale, and that profit has not been attributed yet |
| 1293, 1297 (and 1285 in part) | priced and paid, but not yet «جاهزة» — a restatement can still credit the draw back to the deal's own layers |

A working press always has orders in one of those states, so **waiting for a clean window is not a
plan**. And the fold is materially easier after periods exist: an in-flight order then resolves into
the pool's open period, instead of needing a deal's frozen terms carried across a transition that
Slice 3 removes.

What production actually holds, for whoever runs the fold later:

- **one** open deal, D1 — one purchase order, one proposed pool
- 4 shelves, 7 cost layers, **12,319.30** of stock at cost
- `investor_profit_share_percent` 50.00 · `investor_funded_percent` **93.1808** · `company_stake`
  1,160.01 · `printing_sale_price` **32.000** (it is on the سعر السادة road)

> **A bug this uncovered, fixed in the command now.** Attribution reads the *layer's* container id
> at delivery, so the moment the fold re-points those layers an in-flight order is paid by the pool.
> A pool taking `investor_funded_percent`'s column default of **100** would have paid the investors
> for goods they did not buy — D1's real figure is **93.1808**, and the company owns the other 6.82%
> of every dinar those seven orders earn. `openPool()` now carries all four frozen terms across, and
> a test asserts `investorsCutOf()` gives the same answer on both sides of the fold.

### Done when

The existing investor suite is green · the new pool, settings and fold-in tests pass · the dry-run
runs against production data and its refusal or its report has been read · legacy deal screens still
render.

---

## Slice 1 — Continuous capital

**Goal.** Capital goes into and out of a pool continuously, gated to period boundaries by the grace
window, and the investor is told what will happen before he commits.

### Migration

`create_investment_capital_requests_table` — `investor_id`, `investor_deal_id`, `direction`
(`in`/`out`), `amount`, `requested_at`, `effective_period_id`, `status`
(`pending`/`applied`/`cancelled`), `applied_entry_id`, `notes`.

### Domain

- `Support/GraceWindow` — **the single place** the question «is today still inside the window?» is
  answered. Restated in two callers, the form and the action come to disagree about a boundary day.
- `Actions/RequestPoolCapital` — inside the window, allocates immediately; outside, queues.
- `Actions/CancelCapitalRequest` — a pending request is cancelled and the money stays in the wallet.
- `Actions/ApplyCapitalRequests` — invoked by period open (slice 3); stubbed here and tested
  directly.
- `Queries/PoolCapitalPosition`.
- The `DealTakesNoMoreCapital` guard is removed **for pools only**; legacy deals keep it.

### API

The pool resource must expose `current_period`, `grace_window_ends_on` and
`capital_takes_effect_on`, so the app can warn **before** submission rather than reporting a
surprise afterwards. That warning is the requirement, not a nicety.

`POST investment-pools/{pool}/capital` · `DELETE investment-capital-requests/{request}` ·
`GET investment-pools/{pool}/capital-requests`.

### Tests

Inside the window → an `allocation` is written immediately · outside → queued, and **no** allocation
exists · a queued request applies at the next period open and not before · cancelling leaves the
money in the wallet and writes no allocation · `entry_grace_days = 0` makes every request queue ·
an exit request queues and does not reduce capital until the close.

### Done when

All of the above pass, and the pool endpoint returns an effective date that matches what
`RequestPoolCapital` actually does for the same day.

---

## Slice 2 — Purchases from pool cash

**Goal.** A pool buys its material out of its own cash, and nobody chooses a pool by hand.

### Migration

Per-purchase سعر السادة on the supply row, so the price is agreed per lorry rather than once per
container. `stock_batches.printing_sale_price` already exists and needs no change.

### Domain

- `Queries/PoolDeployableCash` — the §6.1 identity, derived and never stored.
- `Actions/MarkPurchaseOrderLineForPool` — the surviving decision is **pool money or company money**,
  a yes/no. The pool itself follows from the material (§4.3).
- `ClaimDealSupply` shrinks to automatic routing.
- `InvestorService::poolForStockItem()` replaces the per-line claim lookup.
- `Exceptions/PoolCannotAffordThePurchase`.

### Tests

A purchase within deployable cash succeeds · one over it is refused, naming the shortfall · routing
is automatic from the stock item, with no pool named in the payload · receipt stamps the pool id and
the agreed price onto the cost layer · an unmarked line stays company stock and carries no pool ·
undrawn profit is **excluded** from deployable cash (the §6.1 ring-fence, asserted directly).

### Done when

All of the above pass, and the receiving flow is unchanged from the storekeeper's side — asserted by
the existing purchase-order and receipt tests passing untouched.

---

## Slice 3 — Period close

**Goal.** A period closes, profit is distributed, losses are written down, and the next period opens
with the stock and capital rolled forward.

> **The largest slice, and the one that moves money irreversibly.** Budget for it accordingly: the
> test list below is not optional scope.

### Migrations

`create_investment_periods_table` · `create_investment_period_shares_table` ·
`create_investment_realized_earnings_table` · `create_investment_returned_goods_questions_table` ·
`amend_investor_wallet_entries_shape_check` so `profit` / `loss` may name an investment period as
their source rather than only an order.

### Domain

- `Actions/OpenInvestmentPeriod` — opens the row and applies queued capital requests.
- `Actions/CloseInvestmentPeriod` — net profit, distribution, loss write-down, `profit_release`,
  queued exits, the frozen snapshot.
- `Actions/CloseAllPeriods` — iterates the pools on the shared calendar (§4.2).
- `Actions/RecordReturnedGoodsVerdict` — «صالحة» or «تالفة».
- `Queries/PeriodNetProfit` — the §6.2 formula, **in one place only**.
- `Support/PeriodDistribution` — pure, largest-remainder, no database access, so it is testable as
  arithmetic.
- `PostDealEarningsForOrder` and `PostDealStockPurchases` rewritten to write one realized-earning row
  per pool touched, instead of per-investor wallet rows.
- A listener raising the returned-goods question on cancellation of a **printed, unpriced** line —
  and only that case (§6.2.1).
- The late-expense rule in `RecordDealExpense` (§6.2.3).

### API and permissions

`GET investment-pools/{pool}/periods` · `GET .../periods/{period}` ·
`POST investment-periods/{period}/close` · `POST investment-returned-goods/{question}/verdict`.
New permission `investment.periods.close` — closing pays money out and is not the same authority as
editing a pool.

### Tests

**Arithmetic**
- net profit = realized margin − deductible expenses − damage − shortage
- a landed expense is recorded and **not** subtracted
- a non-landed automatic expense **is** subtracted
- an expense dated inside a closed period lands in the open one, keeping its true `incurred_on`
- the distribution sums to the net profit exactly, with largest-remainder rounding
- the company receives its capital weight **plus** the operator cut

**Losses**
- a losing period writes down capital, capped at what each investor put in
- the remainder becomes `loss_absorbed_by_company`
- **a loss in one pool never touches another pool's capital**

**Gating**
- the close refuses while any returned-goods question is unanswered
- «صالحة» writes nothing; «تالفة» writes the damage
- no question is raised for a سادة or a وسيط line
- a closed period is immutable
- at most one open period per pool

**Timing**
- a priced draw lands in the period it was **drawn**, not the period of delivery
- an unpriced sale lands in the period of **delivery**
- `profit_release` makes profit withdrawable, and not before
- a queued capital exit executes at the close, after distribution, within deployable cash

### Done when

Every test above passes · a full period can be opened, traded through and closed on seeded data with
the §6.5 identity holding at the boundary · the existing order, inventory and purchase-order suites
are untouched and green.

---

## Slice 4 — Settlement

**Goal.** A periodic assertion that the books match reality, with the difference named rather than
absorbed.

`create_investment_settlements_table` · `Actions/RecordSettlement` · `Queries/SettlementSnapshot`
computing both §6.5 identities and the drift · `GET`/`POST investment-pools/{pool}/settlements`.

**Tests.** The identity holds exactly on a pool that has only traded · a stock adjustment made
outside the investment flow produces a non-zero drift that is **reported, not silently absorbed** ·
a settlement neither closes the pool nor liquidates stock · undrawn profit appears as a liability and
never inside deployable cash.

**Done when** the identity is asserted in a test that would fail if any equation in §6 drifted.

---

## Slice 5 — Flutter

**Goal.** The screens, and the three places the double-subtraction message has to appear.

New `features/investment/` — pools list with the company-wide roll-up, pool detail, periods register,
settlements, settings. `features/investors/` detail reworked for a multi-pool position with one
shared profit wallet. Investor portal re-pointed.

**The three «محسوبة مسبقاً» markings (§6.2.4)** are scope, not polish:
the expense form (read-only, marked) · the expense list (badge, and **two** totals in the footer) ·
the close screen (every subtraction line printed, already-counted rows excluded from the arithmetic).

**The capital warning before submit** (§5) is likewise scope.

> Code generation: the owner runs `build_runner` after the model and state classes land, and again
> after any freezed/json change. It is not launched from the agent session.

**Done when** widget and cubit tests cover the pools list, the pool detail and the capital-request
warning, and `flutter analyze` is clean on the new feature directory.

---

## Cross-cutting closeout

- Regenerate `openapi.json` (generated, never hand-written).
- Mark [INVESTOR-DEALS-DESIGN.md](../investor-deals/INVESTOR-DEALS-DESIGN.md) and
  [INVESTOR-DEALS-HOW-IT-WORKS.md](../investor-deals/INVESTOR-DEALS-HOW-IT-WORKS.md) superseded for
  new work, kept for the legacy deals they still describe.
- Update [Docs/README.md](../README.md).
- Pint, scoped to the paths touched.

---

## Risk register

| Risk | Where | Mitigation |
|---|---|---|
| Production capital or stock lost in the fold-in | slice 3 | Dry-run report reviewed before any write; append-only fold-in; before/after assertions roll back on mismatch; legacy rows never deleted |
| A shelf legitimately belongs to two pools | slice 3 | **Answered for today's data: it cannot arise.** Production holds one open deal on one purchase order, so the fold proposes exactly one pool. The question returns only if a second pool is opened by hand |
| Double-subtracted expense pays investors twice | slice 3 | `is_landed` set only by the server; the §6.2.4 markings; a test per expense kind |
| Ruined stock credited back as good | slice 3 | The returned-goods question, and the close refusing to proceed while one is open |
| A period closed on wrong figures — irreversible | slice 3 | The close screen prints its full working; `PeriodNetProfit` is the single definition; closed periods immutable |
| Rounding drift across many investors | slice 3 | Largest-remainder allocation, asserted to sum exactly |
| Existing order/inventory flows broken | 2, 3 | Those suites must pass untouched at the end of each slice |

---

## Not in scope

Moving a shelf between pools (§16) · recognition at collection rather than delivery · bad debt ·
multi-currency · any change to receiving, printing, delivery or inventory from the operator's side.
