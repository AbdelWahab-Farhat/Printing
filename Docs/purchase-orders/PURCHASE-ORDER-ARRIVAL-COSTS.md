# Purchase order arrival costs — «مصاريف عند وصول البضاعة»

> **In progress** on branch `purchase-arrival-costs` (uncommitted). See «Where the work stands» at
> the end.
>
> Builds on [PURCHASE-ORDER-ADDITIONAL-COSTS-BACKEND-CHANGES.md](PURCHASE-ORDER-ADDITIONAL-COSTS-BACKEND-CHANGES.md)
> (order-level costs and their allocation), [PURCHASE-ORDER-RECEIPT-REVERSAL.md](PURCHASE-ORDER-RECEIPT-REVERSAL.md),
> and TREASURY-DESIGN §٨ / §٢٠.

---

## 1. Why

The delivery fee, the porters, the customs broker — they are usually paid **when the lorry
arrives**, and nothing could record them then:

1. Additional costs were editable only while the order was `new`; receiving makes it `completed`.
2. Every additional cost went into `total_amount`, which is the **vendor's debt** (§٢٠). A
   transporter paid in cash at the door was counted twice — out of the drawer, and owed to the
   vendor.
3. A cost's share was divided by `quantity_ordered`, so on a short shipment part of what was paid
   never reached the stock's cost.

## 2. The owner's decisions (2026-10-11)

| # | Decision |
|---|---|
| 1 | Arrival costs are entered **on the receive screen**, in the same request. Repricing after the receipt is a later phase. |
| 2 | On a **funded** line, its share of an arrival cost is a **deal expense** (`RecordDealExpense` / `RecordFundExpense`), not layer cost — «a deal's cost is agreed once». **Amended 2026-10-12 for the fund:** a fund line's share names the order and lands in the layers' cost ([FUND-EXPENSE-ON-GOODS.md](../investor-deals/FUND-EXPENSE-ON-GOODS.md), decision 5). Old deals keep this rule. |
| 3 | On a company line, the landed cost is worked out over the quantity **received**, so everything paid lands in the stock. |
| 4 | Planned costs on the order form get the same «who was paid» choice. |
| 5 | Three answers to «who was paid»: **on the vendor's bill** · **paid now from a drawer** · **owed to** a manual «التزام» account. |

## 3. The design

### Who was paid — `purchase_order_additional_costs.treasury_account_id`

| Value | Meaning | Treasury |
|---|---|---|
| null | on the vendor's bill | in `vendor_amount` → the vendor's payable, as before |
| cash / bank / wallet | paid now | `out · expense` from that drawer, source = the cost row |
| a manual payable | owed to someone else | `out · expense` on that payable — «علينا» grows; paid off later by a transfer |

The movement is kept equal to the cost by `SyncDebt` (kind `expense`) — the same idempotent
repost-with-revision the vendor debt uses — so editing a planned cost's amount or drawer, or
removing it, reverses and reposts. It lists in «المصاريف» with the order named in its note, and
is not reversible by hand there (it has no operation): it follows its document.

A vendor's own payable and the customer-excess payable are refused. Naming any account needs
`treasury.record`. Like a deal expense, a drawer short of money does not refuse the receipt — the
money was paid.

### What the vendor is owed — `purchase_orders.vendor_amount`

`vendor_amount = total_amount − costs paid to somebody else`. Written by
`RecalculatePurchaseOrderTotal` beside `total_amount`, and it replaces `total_amount` everywhere
the vendor's debt is read: `SyncPurchaseOrderDebt`, `VendorPaymentSummary`, `PostVendorPayables`,
`CountOldOrderAsDebt`, and the «لا دفع مقدّم» guard in `UpdatePurchaseOrder`. Backfilled equal
to `total_amount` — every existing cost was on the vendor's bill.

### Receiving with arrival costs

`POST /purchase-orders/{id}/arrivals` gains `additional_costs: [{name, amount, treasury_account_id?}]`.
In the receipt's one transaction:

1. The cost rows are written with `stock_arrival_id` = the new arrival.
2. **Each** arrival cost is split over the lines that received anything, weighted by the base
   value of what arrived (`base_total_cost × received ÷ ordered`), in cents, largest remainder
   (the existing algorithm, extracted to `Support/LargestRemainder`).
3. A line's shares add up to `purchase_order_items.arrival_additional_cost`.
4. The layer's unit cost — `landed_unit_cost` on the line:
   - **company line:** `(base_total_cost × R ÷ Q + allocated_additional_cost + arrival_additional_cost) ÷ R`
   - **funded line:** `final_unit_cost`, unchanged; its arrival shares become deal expenses —
     one per (cost, deal), `source_type = purchase_order_additional_cost`. A funded share needs a
     drawer (a deal expense is money that left), so «vendor's bill» or «owed» on a funded line is
     refused.
5. The company part of a cost paid by a drawer/payable posts its `expense` movement; totals and
   the vendor's debt are recomputed.

### Receipt reversal

Undoes the arrival costs with the receipt: their movements are reversed, their deal expenses
reversed, the rows soft-deleted, the lines' `arrival_additional_cost` / `landed_unit_cost`
cleared, totals and vendor debt recomputed.

### Cancelling an order

A planned cost paid from a drawer **stays** — the money left. Its row stays on the cancelled
order and in «المصاريف».

## 4. Schema — one migration

| Table | Column | |
|---|---|---|
| `purchase_order_additional_costs` | `stock_arrival_id` FK nullable | null = planned on the order |
| | `treasury_account_id` FK nullable | §3 |
| | `recorded_by` FK users nullable | |
| `purchase_order_items` | `arrival_additional_cost` decimal(14,2) nullable | |
| | `landed_unit_cost` decimal(12,3) nullable | what the layer opened at |
| `purchase_orders` | `vendor_amount` decimal(14,2) nullable | backfilled = `total_amount` |

`investor_deal_expenses.source_type/source_id` already exist and are used as they are.

## 5. Decided while building

- **Naming an account needs `treasury.record`** — the grant behind «مصروف». Asked only of what
  the request changes, so a buyer without it may still edit an order whose delivery was paid
  (`CostAccountGrant`). A storekeeper without it records arrival costs on the vendor's bill.
- **A short drawer does not refuse the receipt** — like a deal expense: the money was paid.
- **The deal expense's kind is «أخرى»**, named after the cost («نقل», «جمارك»). Its
  `source_type = purchase_order_additional_cost`, and it cannot be reversed by hand — not from
  the deal, not from the fund's «مصاريف الفترة» (`can_reverse` false); reversing the receipt does it.
- **The cost's treasury movement has no operation**, so «المصاريف» shows it without «عكس»: it
  follows its document, as a deal expense does.
- **Reversing a receipt does not guard «لا دفع مقدّم»**: if the vendor was already paid past the
  new `vendor_amount`, their payable reads «لنا عنده». Rare; a vendor credit is not involved.
- **`LargestRemainder`** (Support) is the one split both allocations use; the planned allocation
  now reads only planned costs (`stock_arrival_id IS NULL`).
- **The landed-cost test in `PurchaseOrderTest` changed on purpose** (decision 3): 6 of 10 with a
  10.00 fee now enter at 5.667, not 5.000.

## 6. Where the work stands (2026-10-11)

- [x] Backend: migration, models, `LargestRemainder`, receive / create / update / reverse,
      `TreasuryService::{syncExpense, expenseAccount}`, `InvestorService::{recordSupplyExpense,
      reverseSupplyExpensesOf}`, requests + `CostAccountGrant`, resources, audit labels
- [x] Backend tests — `PurchaseOrderArrivalCostsTest` (15) with `PurchaseOrderTest`,
      `PurchaseOrderReceiptReversalTest`, `StockArrivalTest`, `Investors/`, `Treasury/`, `Audit/`:
      749 green in one run. The full suite was not run.
- [x] Flutter: model fields, `AdditionalCostRow` shared by the form and the receive sheet,
      «تكاليف الوصول» on the receive sheet, detail page sections
- [x] **«الحساب» is back on every cost row — the owner's call, 2026-10-12** (reversing 2026-10-11's
      «vendor's bill only», after a cost on a funded line was refused with nothing to pick). A
      `TreasuryAccountPicker` in `AdditionalCostRow` (`unsetLabel: «على فاتورة المورد»`,
      `payables: true`): drawers and hand-opened «علينا», not a vendor's or a system payable, and
      no «تلقائي». Shown only with `treasury.record` (`CostAccountGrant`); without it a cost stays
      on the vendor's bill. On the receive sheet and the order form alike.
- [x] Flutter tests: `arrival_costs_test.dart` (8); purchase-order and treasury tests green
      except `treasury_settings_page_test` «التسوية إلى حساب المسوّي», which fails on main too
      (it looks for a sentence the page no longer has)
- [ ] `Docs/openapi.json` — stale on main already (a regenerate rewrites ~800 lines); left alone
