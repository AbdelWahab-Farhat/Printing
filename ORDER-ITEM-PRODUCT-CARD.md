# The product's card on an order line

> **Implemented.** Backend and app both — what is below is what was built.
>
> Companion docs: [ORDERS-DESIGN.md](ORDERS-DESIGN.md),
> [ORDERS-SHORTAGE-AND-LINES.md](ORDERS-SHORTAGE-AND-LINES.md),
> [PRODUCT-IMAGES-SCREEN-DESIGN.md](PRODUCT-IMAGES-SCREEN-DESIGN.md).

---

## 1. Why

A line on «تفاصيل الطلبية» said what was sold and what it cost, and nothing else. The product
behind it was a name on an invoice — so anybody who wanted the size chart, the price tiers or
the photograph left the order, opened the products tab, and searched for a word they had just
read on screen.

The line carries the catalogue's own card now: the photograph, the code, the name, the size —
and a tap opens the product.

---

## 2. What the API sends

`OrderItemResource` gained two keys. Both are **absent when the `product` relation was not
loaded** — a list payload, or any older client reading a newer server — and the app treats
absent and null the same way.

| Key | Type | Notes |
|---|---|---|
| `product_code` | `string` | The live catalogue code (`P7`), not part of the snapshot. |
| `product_image` | `ProductImageResource \| null` | The **primary image only**; null for a product with no photographs. |

Both are sent on the **list** as well as on one order — `OrderListQuery` eager-loads
`items.product.images` beside the lines it already loaded. Only the primary image is ever
serialized, so a page of fifteen orders signs one URL per line, not one per photograph.

**The snapshot is untouched.** `product_name`, `variant_label` and `pricing_unit_label` are
still what was true when the order was taken — a product renamed since must not rewrite an old
invoice. The two new keys are deliberately the opposite: they describe the catalogue row as it
stands today, because their whole purpose is to open that row.

`OrderService::loadForDisplay()` now eager-loads `items.product.images`. A four-line order was
otherwise four extra queries, and `Model::shouldBeStrict()` would have thrown before it got as
far as being slow.

Tests: `tests/Feature/Orders/OrderTest.php` — the code and the primary image arrive on a line,
a product with no photograph sends `null`, and the lines of one order read their products in a
single query.

---

## 3. What the app draws

`OrderItemCard` (`frontend/lib/features/orders/presentation/widgets/order_item_card.dart`)
replaces the plain two-line row inside «البنود». One card per line, inside the section:

- **Identity** — thumbnail (52dp), the code in the primary colour, the product name, the size
  on its own line, and a chevron at the trailing edge.
- A hairline rule, then the **figures** — `الكمية × السعر` on one side, the line total in bold
  on the other, then the shortage line and the cost line exactly as before.
- «تسجيل تلف» stays a text button on the card; its own tap never reaches the card underneath.

Three rules it keeps:

1. **Only a real photograph fills the slot.** No tinted placeholder glyph — `ProductCard`
   learned on the catalogue screen that the same shape on every row teaches the eye to skip the
   column.
2. **The chevron appears only when there is somewhere to go.** `onOpenProduct` is null without
   `products.view`, and an arrow onto a 403 is worse than no arrow. The line still names what
   was sold.
3. **Nothing is re-read on the way back** from the product screen. The line is a snapshot;
   editing the product must not change what this invoice says.

Tests: `frontend/test/features/orders/order_item_card_test.dart`.


---

## 4. What the list card draws

`OrderCard` gained a list at its foot, under a hairline — **one line per item**: the
thumbnail, the product's name, and the quantity ordered in its own unit
(`100.000 كيلوغرام`), the quantity sitting at the far edge where the eye can run down it.

- **The quantity is the one that was ordered**, not the billable one the invoice is built on.
  Nothing on this card puts a rate beside it that the arithmetic would have to agree with, and
  the figure agreed with the customer is what somebody scanning the queue is looking for. A
  shortage keeps its red line on the order's own screen.
- **Two lines, then a fold.** Anything past the second is behind «عرض الكل (٥)» / «إخفاء» —
  five lines under every card pushes the next card off the screen. The open and close are one
  `AnimatedSize` movement, not a jump in the card's height.
- **The fold's tap is its own.** The whole card is a single tap that opens the order; the
  toggle sits deeper in the gesture arena and never opens it.
- A product with no photograph draws no grey placeholder — but its slot is **held open** when
  any other line in the same order has one, so the names stay in a column.
- An order whose lines were not sent draws no list at all.

Tests: `frontend/test/features/orders/order_card_items_test.dart`, and
`tests/Feature/Orders/OrderTest.php` for the page that carries the products.
