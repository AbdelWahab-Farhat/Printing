# Nawris Integration — What Changed

> Everything the carrier integration added or altered in the backend, and why.
> Branch `nawris_integration`. Companion to [NAWRIS-INTEGRATION.md](NAWRIS-INTEGRATION.md) (the
> design) and [NAWRIS-FRONTEND-INTEGRATION.md](NAWRIS-FRONTEND-INTEGRATION.md) (the Flutter side).

---

## 0. In one paragraph

Nawris is a Libyan last-mile carrier. We push shipments to their REST API and they push status
changes back to one webhook. The integration lives in a new `Domain/Carrier` context, adds three
tables, and touches the payments domain once — to add a third way an order's debt can be closed.
**Nothing outside `Carrier` knows Nawris exists**, except the two controllers that call its service
and the two mapping columns on `cities` and `regions`.

---

## 1. Migrations

Seven, all forward-only and all reversible.

| Migration | What it does |
|---|---|
| `..._100000_add_carrier_settled_amount_to_orders_table` | `orders.carrier_settled_amount` — a **third** total beside `paid_amount` and `written_off_amount` |
| `..._100100_allow_carrier_settled_entries_in_order_payments` | Widens the `order_payments_shape` CHECK so a `carrier_settled` row may name no method |
| `..._110000_add_nawris_geography_to_cities_and_regions` | `cities.nawris_government_id`, `regions.nawris_area_id` |
| `..._120000_create_nawris_parcels_table` | The parcel: code, reference, barcode, frozen destination, frozen money |
| `..._120100_create_nawris_parcel_orders_table` | The link, keyed `(parcel_id, order_id)` |
| `..._120200_create_nawris_webhook_events_table` | Every inbound webhook, verbatim, with a unique fingerprint |
| `..._130000_add_carrier_collection_recorded_at_to_orders_table` | The payout idempotence flag |

**Two schema decisions worth knowing:**

- **The link is keyed `(parcel_id, order_id)`, never `order_id` alone.** The system the contract was
  compiled from keyed on the order, which meant re-dispatching required deleting the link row and
  the dispatch history went with it. "At most one *open* parcel per order" is enforced in code
  against `closed_at` instead — the guarantee without the amnesia.
- **`nawris_webhook_events` is neither audited nor soft-deleted.** It joins `ActivityLog` in
  `ModelConventionsTest::NOT_A_BUSINESS_RECORD`, for the reason stated there: an immutable record of
  an external event gains nothing from a second record saying it arrived, and a log that can be
  deleted is not a log. It is also the only table here that grows with traffic rather than business.

---

## 2. The payments domain — the one intrusive change

Everything else is additive. This is not, so it is the part to review hardest.

### Why it exists

We subtract our `delivery_price` from the COD before handing a parcel over, so the courier collects
that amount at the door on their own account. The order is then owed a sum **no cash of ours will
ever close**, and `SettlementRequiresFullPayment` refuses a debt — so a Nawris order could never
reach «تم التسوية» without a write-off, and a write-off would post a loss for every single delivery.

### What changed

| File | Change |
|---|---|
| `OrderPaymentType` | New case `CarrierSettled` — «سُدِّدت لدى الناقل». `isCredit()` **true**, `movedCash()` **false**, `namesAMethod()` **false** |
| `OrderPayment` | New `affectsCarrierSettlement()`, mirroring `affectsWriteOff()` — it is what routes a *reversal* back to the right total |
| `RecalculateOrderPayments` | Sums **three** buckets in one walk instead of two |
| `Order::remainingAmount()` | Subtracts all three |
| `PaymentStatus::between()` | Fourth argument; covered = paid + written_off + **carrier_settled** |
| `PaymentStatusExpression::sql()` | The same term, in SQL |
| `RecordCarrierSettlement` | The writer — row-locked, ceilinged, reason required |
| `CarrierSettlementExceedsRemaining` | Its ceiling exception |

### The two things that make it safe

- **`movedCash()` is false**, so «كم قبضنا اليوم؟» never contains money that went into a courier's
  pocket. There is a test asserting exactly that.
- **The rule lives in two places and both moved together.** `PaymentStatusExpression` mirrors
  `PaymentStatus::between()` in SQL, and its docblock says the rule is deliberately stated in
  *exactly two* places. `OrderPaymentStatusFilterTest` asserts the SQL against the enum, so the pair
  cannot drift.

### What it does *not* do

An order closed this way reads **«مدفوعة بالكامل»**, not «مشطوب فرقها». Nothing was forgiven — the
customer paid every dinar and part of it went to the courier by arrangement. That distinction is why
a third bucket exists rather than reusing the write-off.

---

## 3. The new context: `app/Domain/Carrier/`

**Not inside `Delivery`.** It writes order statuses and order payments, so it depends on `Order` —
and `Order` may depend on `Delivery`, which means `Delivery` may never import `Order`. This context
therefore sits above both, and nothing depends on it.

```
CarrierService.php              the door
Models/       NawrisParcel · NawrisParcelOrder · NawrisWebhookEvent
Actions/      DispatchToNawris · EditNawrisParcel · CancelNawrisParcel · ResendNawrisParcel
              BuildNawrisPayload · ResolveNawrisDestination · NawrisDestination
              RecordNawrisWebhook · ResolveNawrisParcel · ApplyNawrisStatus
Jobs/         ProcessNawrisWebhook              ← the first queued job in this repo
DTOs/         NawrisResponse · NawrisWebhookPayload
Enums/        NawrisStatusCode
Support/      NawrisClient · CarrierAccount
Exceptions/   6
```

**`Order` never imports `Carrier`.** `CarrierService::ordersNotLodged()` is written as a raw
`whereNotExists` against the table name rather than as an `$order->nawrisLinks()` relation, precisely
to avoid the back-reference.

---

## 4. The money, end to end

An order of 120 — 100 of bags, 20 of delivery — with a 30 deposit already taken.

| Step | Figure |
|---|---|
| `remainingAmount()` at dispatch | 120 − 30 = **90** |
| COD sent to Nawris | 90 − 20 = **70** |
| `shipment_on_sender` | `0` — the courier adds their own fee on top |
| Customer hands the courier | 70 + their fee |
| Nawris remits | **70** |
| Webhook code 7 writes | payment **70** (cash) + carrier-settled **20** (not cash) |
| Covered | 30 + 70 + 20 = 120 → **«مدفوعة بالكامل»** |

**One edge, handled:** when `remaining ≤ delivery_price` — a prepaid order — the subtraction cannot
be absorbed and the COD floors at zero. `shipment_on_sender` flips to `1` so the customer is not
charged for a delivery they already paid us for.

---

## 5. Files changed outside the new context

| File | Why |
|---|---|
| `OrderController` | Calls `CarrierService::dispatchOrder()` **after** the status change commits |
| `OrderPaymentController` | Calls `syncMoneyFor()` inside `rescue()` — a failed edit must never lose a real payment |
| `OrderResource` | Exposes `carrier_settled_amount` |
| `City` · `Region` (+ DTOs, actions, requests, resources) | The two mapping columns |
| `AuditSubject` | `nawris_parcel`, `nawris_parcel_order` |
| `AuditAttributeLabels` | Arabic names for every new column |
| `PermissionName` | `carrier.view`, `carrier.manage` |
| `AppServiceProvider` | Binds the three config-taking carrier classes |
| `config/services.php` · `config/logging.php` · `.env.example` | Credentials, the `nawris` log channel, the keys |
| `routes/api.php` | The webhook + six operations routes |

**The asymmetry in the two controller wirings is deliberate.** A failed *dispatch* surfaces — the
clerk needs to know the parcel is not lodged. A failed *edit* is rescued and logged — the payment is
real and already written, and refusing to acknowledge it because a carrier API is down would lose the
more important of the two facts.

---

## 6. Endpoints

| Method | Path | Guard |
|---|---|---|
| `POST` | `/api/v1/webhooks/nawris` | Shared secret (constant-time) **+ IP allowlist + throttle** |
| `GET` | `/api/v1/carrier/events` | `carrier.view` — `?pending=1`, `?unmatched=1` |
| `GET` | `/api/v1/carrier/parcels` | `carrier.view` — `?open=1`, `?conflict=1` |
| `GET` | `/api/v1/carrier/not-lodged` | `carrier.view` |
| `POST` | `/api/v1/carrier/orders/{order}/lodge` | `carrier.manage` |
| `POST` | `/api/v1/carrier/orders/{order}/cancel-shipment` | `carrier.manage` |
| `POST` | `/api/v1/carrier/parcels/{parcel}/resolve-conflict` | `carrier.manage` |

The webhook's guard fixes the contract's own flagged bug: the system it was compiled from wrote an
IP allowlist and **never attached it to the route**, leaving a bearer token as the sole gate on an
endpoint that moves orders and releases money.

---

## 7. What a webhook can and cannot do

**Can write:** `orders.status` (seven reachable values, always via `ChangeOrderStatus`) · the
timestamp that status stamps · `cancellation_reason` · `courier_phone` ·
`carrier_collection_recorded_at` · two `order_payments` rows on code 7 · one
`order_status_transitions` row · the `nawris_*` tables · `activity_log`.

**Can never write:** prices, discounts, order contents, customers, deposits, installments,
write-offs, **settlement**, or the deletion of anything.

> **`NawrisStatusCode` is the security boundary, not the permission system.**
> `OrderStatus::permission()` is enforced in `ChangeOrderStatusRequest` — a FormRequest — so it
> guards the HTTP route, not the action. The job calls `ChangeOrderStatus` directly and no permission
> is checked on that path. Adding a case to that enum widens what an unauthenticated POST can do, so
> it is reviewed as a security change.

The carrier system account (`nawris@carrier.local`) holds **no permissions at all** and cannot log
in — `is_active` is false and its password is random and never recorded.

---

## 8. Behaviour worth knowing before you touch it

**The state machine still decides.** Our return chain is walked one link at a time on purpose;
Nawris jumps. A move `allowedNext()` refuses is **parked** — stored with an error, `processed_at`
null — never forced. Forcing it would record a hand-over that never happened. See §3.2 of the design
doc for which codes land from which status.

**Parking discards the state change, never the information.** A parked event still stores the raw
label, the courier's phone, the collected amount and the whole payload.

**The three guards, in order:** idempotency (enum vs enum — a string comparison is silently always
false), delivery conflict (compound: a different code *and* a short amount blocks; a different code
alone only flags), price discrepancy (alert, never block).

**The price check is a floor, not an equality.** The courier adds their fee on top, so what comes
back is always ≥ what we asked for. Comparing for equality would raise a false discrepancy on every
single order.

---

## 9. Tests

**102 new tests across 7 files**, all with `Http::fake()` — no test reaches the carrier.

| File | Covers |
|---|---|
| `Orders/OrderCarrierSettlementTest` | The third bucket, its ceiling, its reversal |
| `Delivery/NawrisGeographyTest` | The mapping columns, through the API |
| `Carrier/NawrisParcelSchemaTest` | Constraints the database enforces |
| `Carrier/NawrisClientTest` | All four envelope quirks |
| `Carrier/NawrisDispatchTest` | The COD arithmetic and every precondition |
| `Carrier/NawrisWebhookTest` | The gate, the log, the three-tier resolver |
| `Carrier/NawrisStatusMappingTest` | The map and the three guards — **the regression file** |
| `Carrier/NawrisOperationsTest` | Edit, cancel, resend, the queues, authorization |

Every incident named in the contract has a test: the duplicate that paid twice, the parcel belonging
to someone else, the price check that froze orders, codes 6 and 12 falling through unmapped.

---

## 10. Before this goes to production

1. **Fill in the credentials.** `NAWRIS_AUTHENTICATION_KEY` and `NAWRIS_MAIN_CLIENT_CODE`. Dispatch
   refuses by name until both are set, so nothing breaks quietly in the meantime.
2. **Run a queue worker.** ⚠️ **This is the most likely way for the integration to fail silently.**
   `QUEUE_CONNECTION=database` is configured but this is the repo's first job, so nothing has ever
   needed `queue:work`. Without it every webhook is accepted, stored, answered `200` and never
   processed — orders stop moving while Nawris sees perfect delivery. Put a supervisor on it and an
   alert on `/carrier/events?pending=1`.
3. **Set `NAWRIS_WEBHOOK_SECRET` and `NAWRIS_WEBHOOK_IPS`.** The allowlist is skipped when empty,
   which is honest rather than lax — but the token alone is a thin gate on an endpoint that writes
   money.
4. **Create the Nawris row in `shipping_companies`** and point `NAWRIS_SHIPPING_COMPANY_ID` at it, so
   existing carrier filters and reports keep working.
5. **Map the cities.** A delivery city with no `nawris_government_id` refuses dispatch by name.
6. **Verify `shipment_on_sender` with Nawris directly.** Our whole COD subtraction rests on the
   courier adding their fee at the door. This needs a phone call, not API access — see §11.

---

## 11. What is still unverified

The contract was compiled from another codebase's observed behaviour, **not from carrier
documentation**, and nothing here has ever spoken to Nawris.

| Unknown | Consequence if wrong | Where it changes |
|---|---|---|
| **`shipment_on_sender = 0` behaviour** | Every customer under-billed by the delivery fee | `BuildNawrisPayload` |
| Status codes beyond the nine | Unmapped → no state change (fails safe) | `NawrisStatusCode` |
| `result` vs `feed` envelope keys | Empty payload read | `NawrisClient` |
| Whether `resend-request` accepts a repeated `order_code` | Re-sends refused | `ResendNawrisParcel` |
| Whether government/area ids are stable | Stored mapping rots | the two columns |
| Rate limits | Unknown | `NawrisClient` |

**This is why everything Nawris-specific lives in two files** — `NawrisClient` and
`BuildNawrisPayload`. When reality differs, two files change and the domain does not.

`NAWRIS_DRY_RUN` is in the config for the cheapest possible first check: build the payload, log it,
send nothing, and read the exact JSON before the first live parcel.
