# Instant Orders and Branch Employee Permissions — Final Plan

**Project:** Daya — staff app
**Source:** `Daya-Task.md` (original spec), plus the owner's answers of 2026-11-26.
**Status:** decided, not built.

Every point is tagged:

- **[Kept]** — as in the original file.
- **[Changed]** — the original said something else; the original wording and the reason are given.
- **[Added]** — not in the original file; comes from the owner's answers.

"Wallet" in the original file means a **treasury account** (a cash box, the bank). It never means
the customer's wallet. This plan says "treasury account".

---

## 1. Goal

- **[Kept]** Direct sale of plain products inside the branches from one screen, without creating
  the customer separately.
- **[Kept]** Branch employees can hand over pickup orders and instant orders and record payments.
- **[Kept]** Financial settlement stays with the manager and the accountant.

## 2. Order types

- **[Kept]** Normal order: keeps the current booking cycle, unchanged.
- **[Kept]** Instant order: direct sale at the office, on the same customers, products, stock,
  treasury accounts and orders system, with its own status path and permissions.
- **[Kept]** An order-type field, filterable, with no parallel accounting system.
- **[Added]** Instant orders use the **same order numbering** as normal orders; a type badge tells
  them apart.
- **[Added]** Instant orders appear in the **customer's app, read-only**.
- **[Added]** Mobile staff app first; the staff web gets the screens later.

## 3. Creating an instant order

### Entry point

- **[Kept]** An «طلب فوري» button on the home screen for whoever holds the create permission. It
  opens one screen.
- **[Added]** An employee with the permission but **no branch assigned** sees the button
  **disabled**, with the reason ("no branch assigned to you").
- **[Added]** The **admin** (and anyone with `branches.manage`) can create one without being
  assigned, choosing from **all active branches**.

### Customer

- **[Changed]** *Original:* name, phone, city and region are required. *Now:* name and phone
  are required; **city and region are optional** (owner's decision, 2026-11-27). The order goes
  to the branch; the address only fills the customer's record, and a region never comes without
  its city.
- **[Kept]** Search by phone after normalising it; an existing customer is loaded and linked, never
  duplicated.
- **[Kept]** A new customer is created together with the order in one successful operation; a
  failed order leaves no customer behind.
- **[Kept]** Fill in the existing customer's missing details; never replace their address with the
  office address.
- **[Added]** If the typed name or city **differs** from the stored one, the stored details stay,
  only empty fields are filled, and the employee sees a notice that the details differ.

### Pickup branch and warehouse

- **[Kept]** The pickup branch is chosen at creation, before adding products — not at a status
  change.
- **[Kept]** One branch → chosen automatically; several branches → the employee picks one.
- **[Kept]** The warehouse comes automatically from the branch settings:

  | Pickup office | Default warehouse |
  |---|---|
  | Qarji office | Primula warehouse |
  | Wali Al-Ahd office | Main warehouse |

- **[Kept]** The branch id and warehouse id are saved on the order; changing the settings later
  never touches past orders.
- **[Kept]** No manual warehouse choice, and no automatic draw from another warehouse.
- **[Kept]** Changing the branch before creating re-checks every line.

### Products and lines

- **[Kept]** Reuse the existing «إضافة منتج» UI, showing plain products only for now.
- **[Kept]** A manageable product setting «متاح للبيع الفوري», so the list can grow without code
  changes.
- **[Kept]** Show product name, size, type, sale unit, quantity available in the chosen warehouse,
  requested quantity, unit price and line total.
- **[Kept]** Several lines per order.
- **[Changed]** *Original:* quantities in kilos or the product's approved unit.
  *Now:* only products whose **sale unit equals their stock unit** for now. *Reason:* stock is
  taken at creation, so the kilos must be known then; a piece-sold, kilo-stocked product has no
  weight until someone measures it. Opening it later is a small change (a weight field per line,
  one filter removed, no data migration).
- **[Added]** The **unit price is fixed** from the product; the employee cannot change it.
- **[Kept]** Discount by permission; notes optional; total shown before and after the discount.
- **[Kept]** Design, print, delivery and deposit fields hidden; no delivery fee.

## 4. Stock

- **[Kept]** Stock is checked when a line is added **and** again on the backend at creation; the
  UI check alone is never enough.
- **[Kept]** If any line is short, the whole order is refused, naming the product, the warehouse,
  the requested and the available quantity. Example: «أكياس شحن 35×40 — مخزن بريمولا: المطلوب 10
  كجم، المتاح 7 كجم».
- **[Kept]** Repeated products across lines are summed; zero and negative quantities are refused.
- **[Changed]** *Original:* reserve the quantity at creation, deduct it at handover, release the
  reservation on cancel. *Now:* the stock is **deducted at creation** and **returned on cancel**;
  the handover deducts nothing more. *Reason:* the system has no reservation today; adding one would
  touch every stock path (normal orders at «جاهزة», shortages, transfers, counts, purchase
  reversals, investor stock, warehouse deletion) and risk the normal order cycle the file says must
  stay untouched (§15). Deducting reuses the existing, tested deduction (including FIFO cost) and
  reversal. (§16 of the original left this mechanism open.)
- **[Added]** To keep the shelf number honest, stock screens get an **«بانتظار التسليم»
  (awaiting handover)** column per product and warehouse: the quantity deducted for instant orders
  still in «جديدة». Tapping it lists those orders (code, customer, quantity, age).
  Shelf count = available + awaiting handover. It is **calculated** from the orders, never stored,
  so it cannot drift. It counts **instant «جديدة» orders only**.
- **[Kept]** Check, deduct and create in one atomic transaction, protected against concurrent
  orders (the existing row lock on stock).
- **[Kept]** Review the current stock mechanism to prevent double deduction — *done:* normal orders
  deduct at «جاهزة»; instant orders at creation; neither deducts again at handover.

Example (the original table, adapted to deduct-at-creation):

| Step | On the shelf (kg) | Awaiting handover | Available |
|---|---:|---:|---:|
| Before the order | 20 | 0 | 20 |
| Instant order of 15 kg created | 20 | 15 | 5 |
| After handover | 5 | 0 | 5 |
| Or cancelled instead | 20 | 0 | 20 |

- **[Changed]** *Original:* a suggestion to show late «جديدة» orders, no auto-cancel without
  management approval. *Now decided:* an order still «جديدة» after a **configurable number of hours
  (default 24)** gets a «متأخرة» badge and is counted on the home screen for managers and the
  branch. **Never auto-cancelled.**

## 5. Instant order statuses

| From | Allowed move | Who |
|---|---|---|
| Creating the order | جديدة | Holder of the create permission |
| جديدة | تم الاستلام | Authorised branch employee |
| جديدة | إلغاء تام | Holder of the cancel permission |
| تم الاستلام | تم التسوية | Manager or accountant |

- **[Kept]** No review, design, print, manufacturing, preparing or delivery statuses.
- **[Kept]** No direct move from «جديدة» to «تم التسوية»; no normal cancel after «تم الاستلام».
- **[Added]** These are the **existing** statuses; the order type limits which moves are allowed.
- **[Added]** A **reason is required** to cancel, as with normal orders.
- **[Added]** No converting an instant order to a delivery order: cancel it (stock returns) and
  create a normal order.
- **[Added]** Changing the branch after creation is **not allowed**: cancel and re-create.

## 6. Handover and payment

- **[Kept]** Reuse the existing status-change screen, showing the pre-set pickup office, warehouse,
  products, quantities, total, remaining, amount received, payment method, treasury account,
  receipt and notes.
- **[Kept]** The office is not chosen again at handover.
- **[Kept]** The move to «تم الاستلام» happens after the money is collected and the goods are
  handed over.
- **[Added]** **Full payment is required**: «تم الاستلام» only when the whole remaining amount is
  collected.
- **[Changed]** *Original:* the received quantity can be edited (after a policy is approved), the
  invoice recalculated and the undelivered part released; any increase needs a new check.
  *Now:* the employee may hand over **less** than ordered — the rest returns to stock and the
  invoice is recalculated — but **never more**. *Reason:* owner's decision.
- **[Kept]** A receipt is required for a bank transfer.
- **[Kept]** The payment, the stock movement and the status change are written consistently, and a
  retry never records them twice.
- **[Kept]** The branch employee cannot change the quantity, amount or treasury account after «تم
  الاستلام».
- **[Added]** Returns after «تم الاستلام» are not part of this feature; the manager uses the
  existing «undo delivery».

## 7. Treasury accounts and accounting

- **[Kept]** Keep the current treasury system; the default account comes from the branch and the
  payment method:

  | Branch | Method | Default treasury account |
  |---|---|---|
  | Qarji | Cash | Primula Qarji |
  | Wali Al-Ahd | Cash | Primula Wali Al-Ahd |
  | Qarji | Transfer or bank card | The bank |
  | Wali Al-Ahd | Transfer or bank card | The bank |

- **[Added]** For instant orders, **the branch setting wins** over today's rule that first picks a
  bank account the employee holds personally.
- **[Kept]** Changing the payment method before confirming updates the default account.
- **[Kept]** The account actually used is saved on the movement; settings changes never alter
  history.
- **[Kept]** Use the existing payment review and settlement; the manager or accountant reviews the
  payment and moves the order to «تم التسوية».
- **[Kept]** The sale amount is never booked a second time at settlement.
- **[Changed]** *Original:* Libyana and overriding the default account need separate approval.
  *Now decided:* **Libyana not now** (cash, transfer, card only). **Overriding the treasury account
  is allowed with its own permission**; the **warehouse is never overridden**.

## 8. Branch settings

- **[Changed]** *Original:* new dynamic branch settings. *Now:* built on the **existing pickup-office
  cities** (a city set to «استلام مكتب» already is the branch, and already has its cash box).
  *Reason:* no second place describing the same office. The owner chose this.
- **[Kept]** Each branch has: name, active/inactive, default warehouse, default treasury account per
  payment method, authorised employees.
- **[Kept]** New branches, warehouses, accounts and payment methods can be added later without names
  in the code.
- **[Kept]** An employee can belong to one branch or several.
- **[Kept]** An inactive branch cannot be used for a new order; its past orders stay.
- **[Kept]** A missing warehouse or account setting gives a clear error and the affected action does
  not run.
- **[Added]** A setting for the "late after" hours (default 24) — see §4.

## 9. The Branch Employee role

- **[Kept]** A «موظف الفرع» role as its own customisable set of permissions, without changing the
  production roles or current pages.

| Action | Branch employee |
|---|---|
| Search all orders | Allowed, not limited by branch, status, type or pickup method — **[Kept]** |
| View all order details | Allowed, for the operational data needed to serve the customer — **[Kept]** |
| Create an instant order, customer included | Allowed within their branches — **[Kept]** |
| View and manage instant orders | By operational permissions — **[Kept]** |
| Hand over a normal order in «استلام مكتب» | Allowed within their branches — **[Kept]** |
| Hand over a new instant order | Allowed within their branches — **[Kept]** |
| Record the amount received at handover | Allowed — **[Kept]** |
| View quantities available for sale | Allowed by permission — **[Kept]** |
| Edit a «جديدة» instant order | **Allowed**, its own permission — **[Changed]** |
| Cancel a «جديدة» instant order | **Allowed with a reason**, its own permission — **[Changed]** |
| Override the treasury account | Only with its own permission — **[Added]** |
| Create a normal order or a standalone customer | Not allowed by default — **[Kept]** |
| Design, print, manufacturing, delivery | Not allowed — **[Kept]** |
| Review payments, settle | Not allowed — **[Kept]** |
| Edit stock by hand; manage accounts, branches, permissions | Not allowed — **[Kept]** |

- **[Changed]** *Original:* editing or cancelling a new instant order is a separate permission
  needing management approval. *Now decided:* both are given to the branch employee, each as its own
  permission. Editing changes lines, quantities, discount and notes while «جديدة», re-checks stock,
  and reuses today's order-line editing.
- **[Kept]** **Last approved change:** branch membership never limits search or viewing; it only
  decides the warehouse, the treasury account and the operational actions. Actions may be granted
  across several branches.
- **[Kept]** Suggested permission names, adapted to the current structure at build time:
  `instant_orders.create`, `instant_orders.view`, `instant_orders.update`,
  `instant_orders.cancel`, `instant_orders.deliver`, `orders.search`, `orders.view`,
  `orders.create`, `pickup_orders.deliver`, `orders.settle`, `payments.review`, `inventory.view`,
  `branches.manage`.
- **[Added]** One more: a permission to override the treasury account (§7).
- **[Kept]** Permissions, status moves and branch scope are enforced in the backend and the UI,
  not by hiding buttons.

## 10. Search and handing over pickup orders

- **[Kept]** Search by order code or customer phone across all normal and instant orders, every
  status and branch, delivery orders included.
- **[Kept]** Show status, products, pickup place or method, paid and remaining amounts.
- **[Kept]** An order in «استلام مكتب» at a branch the employee is authorised for shows «نقل إلى تم
  الاستلام», using the existing payment UI.
- **[Kept]** Other statuses or branches are shown read-only; they never disappear from search.
  Example: an order in «قيد الطباعة», «جاري التوصيل» or «استلام مكتب» at another branch shows up,
  with no handover action.
- **[Kept]** Handing over a pickup order never deducts its stock again; the current mechanism stays.

## 11. Branch employee home screen

- **[Kept]** Employee and branch details, the «طلب فوري» button, the general order search.
- **[Changed 2026-11-27, owner]** Counters: instant «جديدة» and «تم الاستلام» only. *Original:*
  also «استلام مكتب» for the branch, «إلغاء تام» and «تم التسوية» (view only). Dropped from the
  app's board; the server still counts them, and the orders search still finds every one.
- **[Added]** A count of **late** instant orders (§4).
- **[Kept]** Hide normal-order creation, standalone customer creation, settlement and admin tools,
  and production statuses not needed.
- **[Kept]** Hiding a counter never hides orders from search.

## 12. Notifications and messages

- **[Added]** Instant orders offer the **invoice message only**: no «رسالة الجاهزية», and no staff
  push notifications for the instant flow.

## 13. Wireframes

**[Kept]** Guides, not final designs: dark theme, turquoise, RTL, existing components. Changes are
marked.

### Home

```text
الرئيسية — موظف الفرع / مكتب قرجي
[ طلب فوري + ]                     ← disabled with a reason if no branch [Added]
[ البحث عن طلب: الكود أو الهاتف ]
الطلبات الفورية:
[ جديدة ] [ تم الاستلام ]           ← only these two [Changed 2026-11-27]
[ متأخرة ]                          ← [Added]
```

### New instant order

```text
طلب فوري جديد
بيانات العميل: [ الهاتف ] [ الاسم ]
[ المدينة ] [ المنطقة ]
مكان الاستلام: [ مكتب قرجي ]
المخزن: مخزن بريمولا (تلقائي)
البنود: [ + إضافة منتج ]
[ الخصم ] [ ملاحظات ]
الإجمالي: ... د.ل
[ إنشاء الطلب ]
```

### Add product

```text
[ اختيار منتج سادة / مقاس ]
المخزن: مخزن بريمولا
المتاح: 7 كجم (مثال)
[ الكمية المطلوبة: 10 ]
الكمية غير متوفرة — المتاح 7 كجم
[ إضافة المنتج — معطل ]
```

### Status change

```text
الطلب الفوري — جديدة
[ تم الاستلام ] [ إلغاء تام — حسب الصلاحية ]
مكتب الاستلام: قرجي (محدد مسبقاً)
المنتجات والكميات / الإجمالي والمتبقي
[ المبلغ المقبوض ]                  ← must equal the remaining [Added]
[ كاش ] [ حوالة ] [ بطاقة مصرفية ]
المحفظة: بريمولا قرجي (تلقائي عند الكاش)   ← changeable only with permission [Added]
[ الواصل ] [ ملاحظة ]
[ نقل إلى تم الاستلام ]
```

### Branch settings

```text
[ اسم الفرع ] [ نشط / غير نشط ]
[ المخزن الافتراضي ]
[ محفظة الكاش ] [ محفظة الحوالة ]
[ محفظة البطاقة ]
[ الموظفون المصرح لهم ]
[ حفظ ]
```

### Stock screen — [Added]

```text
المنتج / المخزن | الفعلي | بانتظار التسليم | المتاح
أكياس شحن 35×40 | 20     | 15 ›             | 5
```

## 14. Reports and filters

- **[Kept]** Filters: order type, branch, warehouse, status, employee, payment method, date range.
- **[Kept]** Instant orders count in order and sales totals, and can be split out.
- **[Kept]** A cancelled order is not a sale; settlement is not a second sale.
- **[Kept]** Use the existing accounting report definitions.

## 15. Audit log and safety

- **[Kept]** Log the creator, branch, warehouse, time, status changes, quantities, stock movements,
  amounts, payment method, treasury account, who handed over and who settled.
- **[Kept]** Log edits and cancellations with their reason, by permission.
- **[Kept]** Create, handover and settle are protected against repeats (idempotency) and
  concurrency; permissions are checked in the API.

## 16. Acceptance criteria

- [ ] **[Kept]** Create an instant order and a new customer from one screen; link an existing
  customer without duplicating it.
- [ ] **[Kept]** Customer details required; the customer's address is independent of the pickup
  place.
- [ ] **[Kept]** Office and warehouse set before adding products; only eligible products shown.
- [ ] **[Kept]** Refuse the order if any line is short, including concurrent orders and repeated
  products.
- [ ] **[Changed]** Stock is deducted at creation and returned on cancel, never twice; the handover
  deducts nothing. *(Original: reserve, then deduct or release.)*
- [ ] **[Added]** The «بانتظار التسليم» column matches the «جديدة» instant orders.
- [ ] **[Kept]** The order starts «جديدة»; only the listed moves are allowed.
- [ ] **[Kept]** The right cash account per branch, and the right account for transfer and card.
- [ ] **[Kept]** Receipt required for transfers; no repeated payment on settlement or retry.
- [ ] **[Added]** «تم الاستلام» refused unless the full remaining amount is collected.
- [ ] **[Kept]** Search all orders with no limit by branch, status, type or pickup method.
- [ ] **[Kept]** Other branches' orders and delivery/production orders show read-only when the
  employee cannot act on them.
- [ ] **[Kept]** Hand over a «استلام مكتب» order within the authorised scope.
- [ ] **[Kept]** The branch employee cannot create a normal order, settle or edit stock, even
  directly through the API.
- [ ] **[Kept]** A new branch can be added with its warehouse and treasury accounts from settings.
- [ ] **[Kept]** Reports and the audit log are correct; the normal order cycle is unaffected.

## 17. Decisions (the original §16, now answered)

| # | Original open point | Decision |
|---|---|---|
| 1 | Full or partial payment | **Full payment required** |
| 2 | Libyana and its account | **Not now** |
| 3 | Branch employee edits or cancels a new order | **Both**, each its own permission; cancel needs a reason |
| 4 | Branch change after creation | **Not allowed**; cancel and re-create |
| 5 | Override the default warehouse or account | **Treasury account only, with permission**; warehouse never |
| 6 | Stock mechanism; late new orders | **Deduct at creation** + «بانتظار التسليم» column; late after **configurable hours, default 24**, never auto-cancelled |
| 7 | Quantity edits at handover; returns | **Less only**, rest back to stock; returns after «تم الاستلام» via the existing undo delivery |
| 8 | Compensation, extra costs, discounts | **Discount only**, under the existing discount permission |

## 18. Build order

- **[Kept]** Backend, order type and statuses → branch settings and permissions → stock and
  concurrency → treasury accounts and settlement → employee screens and search → reports and tests.
  These are parts of one task, not separate tasks.
- **[Added]** Mobile staff app first; the staff web afterwards.

---

## 19. Execution plan (technical)

**Environment:** local development (`APP_ENV=local`, local Postgres `printing_bags`). Tests run on
`printing_bags_test` via `RefreshDatabase`. No production access. Work stays on `main`,
uncommitted, by the owner's request.

### 19.1 How the decisions land in the existing code

| Need | Built on |
|---|---|
| Order type | New `orders.order_type` (`normal` / `instant`), enum `OrderType` |
| Branch | The existing office-pickup city; the order's `city_id` is the branch |
| Warehouse on the order | The existing `orders.fulfillment_warehouse_id`, stamped at creation |
| Stock out at creation | The existing `DeductOrderStock` (row locks, FIFO cost, shortfall message per item) |
| Stock back on cancel | The existing reversal on «إلغاء تام» (plain lines return to their batches) |
| Hand over less | The existing partial delivery, which returns plain lines to stock |
| Full payment | New guard: an instant order reaches «تم الاستلام» only with nothing remaining |
| Cash account | The existing branch cash box (`treasury_accounts.pickup_city_id`) |
| Bank / card account | New `cities.bank_transfer_account_id` / `bank_card_account_id` |
| Statuses | Existing cases; a new instant arm in `OrderStatus::allowedNext` |
| Repeat-safety on create | The existing `orders.client_token` unique key |
| Repeat-safety on handover | New: re-read and re-check the order after its row lock (today it is checked before) |
| Edit while «جديدة» | Return the whole draw and draw again, inside one transaction |
| Late | New `company_settings.instant_order_late_hours` (default 24) |
| Awaiting handover | Calculated from order lines' draw movements of instant «جديدة» orders |

### 19.2 Backend — files

**New migrations** (all reversible):
1. `add_order_type_to_orders_table` — `order_type` string, default `normal`, indexed.
2. `add_branch_settings_to_cities_table` — `is_branch_active` (default true),
   `default_warehouse_id`, `bank_transfer_account_id`, `bank_card_account_id` (nullable FKs,
   null on delete).
3. `create_branch_user_table` — city ↔ employee pivot, unique pair.
4. `add_instant_sale_to_products_table` — boolean, default false.
5. `add_instant_order_late_hours_to_company_settings_table` — small int, default 24.
6. `register_instant_order_permissions` — the permissions below, and the role «موظف الفرع».

**New permissions:** `instant_orders.view`, `.create`, `.update`, `.cancel`, `.deliver`,
`.choose_account`, `pickup_orders.deliver` (hand over «استلام مكتب» in one's own branches only;
the existing `orders.status.delivered` stays global and unchanged), `branches.manage`.
Role «موظف الفرع»: `orders.view`, `instant_orders.view/create/update/cancel/deliver`,
`pickup_orders.deliver`, `orders.payments.record`.

**New code:** `OrderType` enum; `CreateInstantOrder`, `UpdateInstantOrder` actions; phone
normaliser; instant-sale eligibility (flag + plain + listed price + same unit + has a stock item);
branch access (which branches a user may act for: assigned ones, or all active for admin /
`branches.manage`); `UpdateBranchSettings`; awaiting-handover query; exceptions for each refusal;
`InstantOrderController` (create, edit, customer lookup by phone, eligible products with
availability, my branches), `BranchController` (list, update), awaiting-handover list endpoint;
requests and resources for each.

**Modified:** `OrderStatus` (instant arm + per-type permission), `Order` (type, `isInstant`,
`isLate`, branch cash box while «جديدة»), `ChangeOrderStatus` (type-aware check, re-check after
lock, full-payment guard, pickup branch scope), `ChangeOrderStatusRequest`, `TransitionFields`
(instant handover: amount required and pre-filled; account picker only with
`instant_orders.choose_account`), `RecordOrderPayment` + `AccountResolver` (branch accounts for
instant orders; a missing one is a clear refusal), `CreateOrder` / `OrderData` (type, no delivery
price for instant), `UpdateOrder` (refuses instant orders — they have their own edit),
`OrderFilters` / `FiltersOrders` (type, warehouse, employee, payment method, late), `OrderResource`,
`HomeController` / `HomeSummaryResource` (instant counters, my-branch pickup count, late count),
`WarehouseStockResource` / `StockListQuery` (awaiting handover), product requests/resource
(`instant_sale`), `City`, `CompanySetting`, `PermissionName`, `RoleSeeder`, the staff push
listener (skips instant orders), the sales board query (type filter).

**Tests (new):** creation (new and existing customer, fill-blanks notice, shortfall message,
repeated product summed, concurrent orders for the last stock, no customer left after a failed
order, inactive branch, missing warehouse); statuses (allowed moves only, full payment, less-only
handover returns stock, cancel returns stock, no double deduction); accounts (cash box per branch,
bank/card from the branch, override needs permission, missing account refused); edit while
«جديدة»; branch settings; branch-employee API refusals (normal order, settle, stock edit);
pickup handover scope; awaiting handover; late flag; home counters; filters.

### 19.3 Staff app — files

**New:** `lib/features/instant_orders/` (models, repository, cubits, the one-screen form for
create and edit, the instant product picker with availability, customer phone lookup);
`lib/features/branches/` (branch list and branch settings page with warehouse, account and
employee pickers, active switch, late-hours setting). Tests for each.

**Modified:** `app_permission.dart` (new cases; the contract test enforces it),
`api_endpoints.dart`, `injector.dart`, `app_router.dart`, home (branch layout when the user can
create instant orders but not manage orders: «طلب فوري», search, pickup and instant counters,
late), `order.dart` (type, late), order detail (instant badge; edit opens the instant form),
orders filter (type, late), warehouse stock model and row («بانتظار التسليم» + its order list),
product form («متاح للبيع الفوري»), drawer (branches). Generated freezed files rebuilt with
`build_runner` (filtered).

### 19.4 Commands

`php -l` and scoped Pint on changed paths; targeted PHPUnit per test file, then the full suite
once in the background (~13 min, never two at once); scoped `dart analyze`; targeted
`flutter test`; filtered `build_runner`, restoring any unrelated generated files it touches.

### 19.5 Effects, rollback, risks

- **Database:** migrations run only on the test database. The local dev database is **not**
  migrated without a separate approval. No production effect. No external service is called.
- **Rollback:** nothing is committed; restore the modified files and delete the new ones. Every
  migration has a `down()`.
- **Risks:**
  1. `ChangeOrderStatus` is shared by every order; the re-check after the lock only changes the
     outcome for duplicate racing requests. The whole Orders test folder is re-run.
  2. Investor stock: drawing at creation, editing and cancelling must post and reverse investor
     purchases exactly as the «جاهزة» path does. Covered by `InstantOrderInvestorStockTest`
     (added 2026-11-27): a plain line is not bought at creation, the investor is paid from the
     order's profit at handover, an edit moves the difference on the deal's own layer, and a
     cancel puts the goods back on the deal with nothing paid.
  3. The customer app shows a «جديدة» order as «قيد المراجعة»; for an instant order that lasts
     until handover (usually minutes). Left as is.
  4. Size: roughly 45 backend and 35 app files. Built in phases, each green before the next.

### 19.6 Where the work stands (2026-11-27)

Built on `main`, **uncommitted** by request. All six phases done.

- **Backend tests:** `tests/Feature/InstantOrders/` — 46 tests, green (creation, handover and
  payment, edit, pickup scope, branches, home board, filters, late, awaiting handover, sales split,
  investor-funded stock).
- **Full backend suite:** 4,745 tests — 4 failed, all from this change (audit labels, an audit
  diff, the no-try/catch rule); fixed and re-run green, with the product tests (295).
- **App tests:** `test/features/instant_orders/` — 8 green; core, home, orders, warehouses,
  products and root suites re-run green (1,919).
- **Local dev database not migrated** — run `php artisan migrate` when ready (six new migrations).
- **Not done / follow-ups:**
  - Staff web screens (decided: later).
  - The home board's «استلام مكتب» card was removed (2026-11-27, owner), which also retires its
    branch-scope mismatch. The server still sends `pickup_count` and every status; unused.
  - The catalogue's minimum order quantity still applies to instant sales.
  - Customer app shows an instant order as «قيد المراجعة» until handover (accepted).

### 19.7 Phases

1. Backend: type, statuses, creation with stock, customer lookup.
2. Backend: branches, permissions, role, scope.
3. Backend: handover, payment, accounts, edit, cancel.
4. Backend: late, awaiting handover, home, filters, reports.
5. App: permissions, models, branch settings, product flag.
6. App: instant form, product picker, home, order detail, filters, stock column.
