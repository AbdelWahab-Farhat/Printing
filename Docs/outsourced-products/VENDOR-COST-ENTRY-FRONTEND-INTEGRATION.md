# «تكلفة المورد» — the Flutter side

> The app side of [OUTSOURCED-PRODUCTS.md §6.1–6.2](OUTSOURCED-PRODUCTS.md): the vendor's cost on a
> وسيط line, typed when the order is taken or edited, required at the first «جاهزة», and filled
> late on the old orders that went past «جاهزة» without one.
>
> **Status (2026-10-21): built and merged with the backend in PR #28 (`a667f969`).** It is in no
> released staff build yet: 1.9.0 (8) predates it. The user-facing summary is
> [changes/PR-28-OUTSOURCED-VENDOR-COST.md](../changes/PR-28-OUTSOURCED-VENDOR-COST.md).
> Where this document and the shipped API disagree, **the API is right**.

---

## 0. The feature, in one paragraph

A «حسب الطلب» size has no `cost_price` in the catalogue, because the vendor quotes each job. Its
وسيط line therefore came in with `unit_cost` null, was costed at nothing at «جاهزة», and the order
showed «لم تُحتسب» instead of a profit. The figure now has three ways in, all writing the same
column `order_items.unit_cost`:

| Where | Screen | Grant | Required? |
|---|---|---|---|
| Taking / editing the order | «طلبية جديدة», «تعديل الطلبية» | `products.view_cost` | no |
| The first move to «جاهزة» | the status screen | anybody making the move | yes, when the line has no cost |
| After «جاهزة», once per line | the order screen | `orders.manage` **and** `products.view_cost` | — |

Nothing downstream changed: `cogs`, `total_cogs`, `gross_profit` and «مجمل الربح» are computed
by the server as before. The app only sends the number and redraws what comes back.

---

## 1. Endpoints

| Verb | Path | What is new | Permission |
|---|---|---|---|
| `POST` | `/orders` | accepts `items.*.unit_cost` | `orders.manage`; the key needs `products.view_cost` |
| `PUT` | `/orders/{id}` | accepts `items.*.unit_cost` | same |
| `GET` | `/orders/{id}` | `lines_awaiting_vendor_cost: int[]` | `orders.view`; the key needs `products.view_cost` |
| `POST` | `/orders/{id}/status` → `ready` | one `unit_cost_{itemId}` field per وسيط line in `available_transitions` | unchanged |
| `POST` | `/orders/{order}/items/{item}/vendor-cost` | **new** — body `{"unit_cost": "12.5"}`, returns the order | `orders.manage` + `products.view_cost` |

`items.*.unit_cost` and `unit_cost` share one rule: `numeric`, `min:0`, `max:9999999.999`, ASCII
digits only.

---

## 2. Models

[new_order.dart](../../frontend/lib/features/orders/models/new_order.dart), on `NewOrderItem`:

```dart
@JsonKey(name: 'unit_cost', includeIfNull: false) String? unitCost,
```

[order.dart](../../frontend/lib/features/orders/models/order.dart), on `Order`:

```dart
@JsonKey(name: 'lines_awaiting_vendor_cost') @Default(<int>[]) List<int> linesAwaitingVendorCost,
```

`OrderItem.unitCost` and `OrderItem.outsourcingCost` were already there and did not change.

---

## 3. Taking the order — «طلبية جديدة»

[order_line_row.dart](../../frontend/lib/features/orders/presentation/widgets/order_line_row.dart),
[new_order_page.dart](../../frontend/lib/features/orders/presentation/views/new_order_page.dart),
[take_order.dart](../../frontend/lib/features/orders/usecases/take_order.dart).

- **Box:** «تكلفة المورد لل‹الوحدة›» under the line, drawn when the reader holds
  `products.view_cost` **and** `OrderLineDraft.takesVendorCost`, i.e. the product's
  `production_mode.hasCostPrice`.
- **Opens on the catalogue's figure** (`variant.costPrice`) where there is one, so the clerk
  corrects a number rather than retyping it.
- **Sends** `unit_cost` only under the same two conditions. `TakeOrder` turns Arabic-Indic digits
  into ASCII and turns a blank box into no key at all.
- **Error:** `items.{index}.unit_cost` under the box. It is registered in `_renderedKey`, so it
  never shows twice as a snackbar.

What the server does with the key:

| Sent | On a new وسيط line |
|---|---|
| a number | that number — typed beats the catalogue |
| no key | the catalogue's `cost_price`, or null; «جاهزة» asks for it later |
| any key, on a line of ours | ignored, like `unit_price` on a listed product |
| any key, from a reader without `products.view_cost` | **422** «لا تملك صلاحية تحديد تكلفة المورد», not a silent drop |

---

## 4. Editing the order — «تعديل الطلبية»

[order_edit_page.dart](../../frontend/lib/features/orders/presentation/views/order_edit_page.dart),
[order_invoice_cubit.dart](../../frontend/lib/features/orders/presentation/viewmodel/order_invoice_cubit.dart),
[order_invoice_state.dart](../../frontend/lib/features/orders/presentation/viewmodel/order_invoice_state.dart),
[update_order_invoice.dart](../../frontend/lib/features/orders/usecases/update_order_invoice.dart).

- **Box:** same label, drawn for `products.view_cost`, on a وسيط line (`isOrderedAlone`), and only
  while the lines are editable (`isEditable`). From «قيد التصنيع» on the lines are shut, so the
  «جاهزة» box is the last place the figure can change.
- **State:** `InvoiceLine.unitCost` (as typed) and `originalUnitCost` (what the line opened with).
  `cubit.setUnitCost(lineId, value)` writes it.
- **Sends only a change.** `costChanged` is true when the box is non-empty and differs from
  `originalUnitCost`. Unchanged, the key is left out. Empty is never a change: the server reads an
  absent key on a kept line as «leave it».
- **Save is shut** while `hasValidCost` is false (not a number, or negative).
- **A cost-only edit does not re-price the line**: the server keeps the line's price and
  snapshots.
- **Error:** `state.unitCostErrorAt(index)` reads `items.{index}.unit_cost`.

---

## 5. The first «جاهزة» — nothing to build

[TransitionFields.php](../../backend/app/Domain/Order/Support/TransitionFields.php) describes the
box, and the status screen draws it like any other server field. **This part already works in
1.9.0.**

For each وسيط line, on the **first** move to «جاهزة» (`ready_at` null), the server adds:

| | Line without a cost | Line with a cost |
|---|---|---|
| `key` | `unit_cost_{itemId}` | `unit_cost_{itemId}` |
| `type` | `number` | `number` |
| `label` | «تكلفة المورد لل‹الوحدة› — ‹المنتج› (‹المقاس›)» | same |
| `required` | **true**, offered to anybody making the move | false |
| `value` | null | the line's cost, pre-filled |
| `hint` | «من فاتورة المورد — تُحتسب على ‹الكمية›» | «المتفق عليه يوم الطلب — صحّحه إن اختلفت فاتورة المورد» |
| offered to | everybody | `products.view_cost` holders only |

- Values go back as `fields.unit_cost_{itemId}`, the same as every transition field.
- **The domain refuses the move** if a line would still have no cost (a caller that skips the
  form): 422 on `items`, «لا يمكن اعتبار الطلبية جاهزة قبل تحديد تكلفة المورد لكل سطر — تنقص
  تكلفة: …». `items` is not a field on the screen, so `hasUnrenderedErrors` shows it as a
  snackbar.

---

## 6. Filling an old order — «تسجيل تكلفة المورد»

[order_detail_page.dart](../../frontend/lib/features/orders/presentation/views/order_detail_page.dart),
[order_item_card.dart](../../frontend/lib/features/orders/presentation/widgets/order_item_card.dart),
[record_vendor_cost_sheet.dart](../../frontend/lib/features/orders/presentation/widgets/record_vendor_cost_sheet.dart),
[record_vendor_cost.dart](../../frontend/lib/features/orders/usecases/record_vendor_cost.dart).

**Where the button goes is the server's answer.** `lines_awaiting_vendor_cost` lists the line ids
that need a figure. The card draws «تسجيل تكلفة المورد» on exactly those, when the session holds
both grants. The list is empty when:

- the reader lacks `products.view_cost` (the key is absent; the model defaults to `[]`);
- the order has not reached «جاهزة», is not on the وسيط road, or is archived;
- the payload is a list row, which does not carry the lines.

Since «جاهزة» now requires the figure, only orders taken before PR #28 can have any.

**The call.** The sheet returns the text as typed. `RecordVendorCost` trims it and converts the
digits (`Validators.toWesternDigits`, which also takes the Persian digits the box admits), and
posts `{"unit_cost": "…"}`. The answer is the whole order, with the new `total_cogs` and
`gross_profit`:

```dart
cubit.replace(updated);
context
  ..handBack(updated)          // the list behind is patched, not refetched
  ..showSuccess('سُجّلت تكلفة المورد');
```

**Refusals** (422 on `unit_cost`, shown by `context.showFailure`):

| Message | When |
|---|---|
| «تكلفة المورد تُسجَّل على بنود الوسيط فقط» | the line is not وسيط |
| «الطلبية لم تصل إلى «جاهزة» بعد — تُطلب تكلفة المورد عند الانتقال إليها» | `ready_at` is null |
| «سُجّلت تكلفة هذا البند من قبل، ولا تُعدَّل بعد «جاهزة»» | the line already has an `outsourcing_cost`; also a double tap, since the server locks the line |

An item from another order is a 404 (`scopeBindings`). Without both grants it is a 403.

The server costs the line at `unit_cost × (quantity − shortage)`, as «جاهزة» would have.
**The app does no arithmetic**: it redraws from the order it gets back.

---

## 7. Rules that bite

- **Absent is not null.** `unit_cost`, `outsourcing_cost` and `lines_awaiting_vendor_cost` are all
  missing for a reader without `products.view_cost`. Gate on the permission, never on the value.
- **Never send `unit_cost` from a reader without `products.view_cost`.** It is a 422 that fails
  the whole order save, not a dropped key.
- **ASCII only.** `٠٫٨` from a Libyan keyboard fails `numeric`. Convert beside the API call, as
  `TakeOrder`, `InvoiceLineUpdate` and `RecordVendorCost` do.
- **No correction after «جاهزة».** This is the owner's decision of 2026-10-20. Do not add an edit
  button on a costed line; the server would refuse it.
- **No investor money moves.** A وسيط order draws on no deal's shelf, so no fund or deal screen
  needs refreshing.

---

## 8. Tests

- Flutter: [vendor_cost_entry_test.dart](../../frontend/test/features/orders/vendor_cost_entry_test.dart).
  It covers what `TakeOrder` and `OrderInvoiceCubit` send: ASCII when typed, no key when blank or
  unchanged, never from a reader without the grant, never on a line of ours, and save shut on a
  non-number. 9 tests, green on 2026-10-21.
- Backend: `tests/Feature/Orders/OutsourcingCostEntryTest.php`.

---

## 9. Open

- **The prose under the boxes goes against the house UI rule** of no explanatory lines. Two
  places:
  - the `helperText` «ما يتقاضاه المورد عن هذه الطلبية — يُطلب عند «جاهزة» إن تُرك فارغاً» on
    both forms;
  - the subtitle «وصل هذا البند إلى «جاهزة» دون تكلفة… تُسجَّل مرة واحدة ولا تُعدَّل بعدها.» and
    the `helperText` with the quantity, both in the late-fill sheet.

  Remove them, or keep them as a deliberate exception: the user decides.
- **No `delivery_loss` back-fill.** On a delivered order, the late fill fixes the profit, but the
  P&L does not name the slice left at the counter. This is a backend note and needs no app work.
