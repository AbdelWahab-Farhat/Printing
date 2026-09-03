# Settable stock unit, and fulfilment moved to «جاهزة» — the Flutter app

> **Implemented.** Everything below is what was actually built in `frontend/`, against
> `STOCK-UNIT-AND-READY-DEDUCTION-BACKEND-CHANGES.md`. Branch: `fix_some_bugs`.
>
> The two halves of this landed very differently, and that is the headline: **the fulfilment-timing
> change needed no app code at all** (§1) — only stale copy corrected — while the stock unit is a
> genuinely new field, a new endpoint and two new pieces of UI (§2–§5).
>
> Verified: `flutter analyze` clean, `flutter test` **1237/1237** passing.

---

## 1. Fulfilment timing — nothing to build, four things to correct

The order-status screen renders `available_transitions[].fields` exactly as sent and holds no
state machine, so the warehouse picker moved from «قيد الطباعة» to «جاهزة» on its own the moment
the API started sending it there. Confirmed by reading the code, not assumed: `transition_field_input.dart`
dispatches on `field.type` alone, and nothing in the app gates *where* a warehouse picker appears.

What did need changing was **copy that named the old step** — four places that would have sent a
reader looking for a figure that is not there yet:

| File | What it said | What it says now |
|---|---|---|
| [order_cost_section.dart](../../frontend/lib/features/orders/presentation/widgets/order_cost_section.dart) | «تُحتسب عند دخول الطلبية **«قيد الطباعة»**» — **on screen, user-facing** | «تُحتسب عند وصول الطلبية إلى **«جاهزة»**» |
| [transition_field.dart](../../frontend/lib/features/orders/models/transition_field.dart) | `warehouse` is "asked on the way into «قيد الطباعة»" | «جاهزة», plus a note that *which* move asks is the server's call and this comment is not load-bearing |
| [order.dart](../../frontend/lib/features/orders/models/order.dart) | three docs on `total_cogs`, `fulfillment_warehouse_id`/`stock_deducted_at` and the per-line costs | «جاهزة», and why it is a better fit: lines are frozen by «جاهزة» but editable through «قيد الطباعة» |
| [order_line_costs.dart](../../frontend/lib/features/orders/presentation/widgets/order_line_costs.dart) | "null until the line reaches «قيد الطباعة»" | «جاهزة» |

One more, which reads differently now: `_mayScrap` in
[order_detail_page.dart](../../frontend/lib/features/orders/presentation/views/order_detail_page.dart)
gates the scrap-loss action on `fulfillmentWarehouseId != null` rather than on a status. That was
already right and needed no change — the comment now says so explicitly, because reading the
warehouse instead of the status is exactly what let the deduction move without touching this line.

**Still worth a manual pass**, since this is a real behaviour change day to day: walk an order
«جديدة» → «قيد الطباعة» → «جاهزة» and confirm the warehouse picker now appears on the last step,
is asked exactly once, and `stock_deducted_at` lands there and not earlier.

---

## 2. Models

[product.dart](../../frontend/lib/features/products/models/product.dart) — two new **required** fields.
Required rather than defaulted: the server sends them on every product (defaulting `stock_unit`
to `pricing_unit` until somebody says otherwise), so modelling them as optional would be the app
disagreeing with the contract to save nine test fixtures.

```dart
@JsonKey(name: 'stock_unit') required String stockUnit,
@JsonKey(name: 'stock_unit_label') required String stockUnitLabel,
```

Plus one getter, which is what every screen actually asks:

```dart
/// False for nine bags in ten — which is what this is for: printing both labels
/// unconditionally would repeat the same word everywhere to be informative in one place.
bool get stocksInAnotherUnit => stockUnit != pricingUnit;
```

[new_product.dart](../../frontend/lib/features/products/models/new_product.dart) — one new **optional**
field, `includeIfNull: false`. Omitted on the common path so the server applies its own default;
sending `pricing_unit`'s value back would be the app repeating the server's rule at it, and the
first place the two could drift.

`PricingUnit` was reused as-is — it already has `piece`/`kilogram`, `.choices`, `.fromWire()` and
`.wire`. Nothing new there.

---

## 3. Repository, use case, DI

- **New endpoint** in [api_endpoints.dart](../../frontend/lib/core/network/api_endpoints.dart):
  `ProductEndpoints.stockUnit(id)` → `/products/{id}/stock-unit`.
- **New repository method** — `setStockUnit(int productId, PricingUnit unit)`, a `PATCH` with
  body `{'unit': unit.wire}`, decoding the refreshed `ProductResource` the way `update()` does.
- **New use case** [set_product_stock_unit.dart](../../frontend/lib/features/products/usecases/set_product_stock_unit.dart),
  matching `SetProductCategoryActivation`'s shape.
- `SaveProduct` / `SaveProductCubit` take an optional `stockUnit` and pass it through. `create()`
  already spreads `product.toJson()` into the multipart body, so the field needed no plumbing there.
- Registered in [injector.dart](../../frontend/lib/core/di/injector.dart) with the catalogue, with a note
  that the *grant* is `inventory.manage` even though the id is a product's.

---

## 4. UI

**Product create form** ([product_form_page.dart](../../frontend/lib/features/products/presentation/views/product_form_page.dart))
— a switch, «وحدة المخزون تختلف عن وحدة البيع», that reveals a second choice row. Two dropdowns on
every product would be two identical dropdowns on nine bags in ten, so the common case stays a
zero-extra-tap flow and the key is omitted entirely. The storage unit mirrors the selling unit
while the switch is off, so changing one cannot leave a stale answer behind the other.

Shown **only when adding**: `PUT /products/{id}` has no rule for `stock_unit` and ignores the key,
so a control on the edit form would silently do nothing.

The min-quantity validator still branches on `_unit` (the *selling* unit) and deliberately not on
the new field — a per-kilo shelf does not make a per-piece bag orderable by the half. There is now
a comment saying so, because it is exactly the line somebody would "fix".

**Product detail** ([product_detail_page.dart](../../frontend/lib/features/products/presentation/views/product_detail_page.dart)):

- A «وحدة المخزون» fact row, **only when it differs** from the pricing unit.
- A new speed-dial action, «وحدة المخزون», gated by `AppPermission.manageInventory` — a sheet to
  pick the unit, then a confirmation that says what the pick actually does (relabels every
  warehouse balance and cost batch for the product's variants; the quantities themselves do not
  change), then the call.

`ProductDetailCubit` gained `setStockUnit`, which needed **no new state case**: the endpoint
answers with the whole product, so success lands as an ordinary `loaded` and there is no follow-up
`GET`. A failure is returned to the screen rather than emitted — replacing a product somebody is
reading with an error page is not what "that did not work" should look like.

---

## 5. Tests

Written first, then the code. New and changed:

- **`set_product_stock_unit_wire_test.dart`** (new) — the `PATCH` verb, the path, `{'unit': …}` as
  the whole body, and both units on the product that comes back.
- **`product_model_test.dart`** — `stock_unit` parsed beside `pricing_unit`, and
  `stocksInAnotherUnit` both ways.
- **`save_product_test.dart`** — the key is absent from the body when nothing was chosen, and
  present and separate when it was.
- **`product_detail_cubit_test.dart`** — the refreshed product replaces what is on screen with one
  request and no reload; a refusal leaves the product untouched and hands the message back; a
  change landing after the screen is gone is not emitted.
- **`product_form_seeding_test.dart`** — the storage picker appears only after the switch, and
  never on the edit form.
- **`order_cost_section_test.dart`** — the "not costed yet" line now has to name «جاهزة».
- Six fixture files gained `stockUnit`/`stockUnitLabel` — mechanical, from the two fields being
  required.

---

## 6. Not done

- **Inventory/warehouse-stock screens** — no change was needed. `WarehouseStockResource`'s
  `unit`/`unit_label` now reflect `stock_unit` automatically; the shape did not move.
- **Manual QA of the fulfilment move** (§1) — code-side it is a no-op, but the behaviour change is
  real and wants walking through on a device once.

---

Last updated: 2026-08-15.
