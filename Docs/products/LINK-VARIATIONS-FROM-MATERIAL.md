# ربط المقاسات من المادة — spec, and what it costs

> Requested 2026-08-25: hide التصنيفات (`StockItemGroup`) from the inventory tab **and** from the
> product form, and link product variations to a material from the material's own screen instead —
> a products list, each opening its variations, multi-select, sent once.

---

## 1. What exists today

| | |
|---|---|
| the link | `product_variants.stock_item_id`, nullable |
| the only writer | `POST\|PUT /products` — the whole product body |
| who resolves it | `SyncProductVariants::resolveStockItemId()` |
| precedence | explicit `stock_item_id` → the product's category → null |
| the reader the picker needs | `GET /products` already eager-loads `variants.stockItem` |
| a picker with this exact shape | `variant_picker_sheet.dart`, single-select |

**There is no endpoint that sets `stock_item_id` on a variant.** A selection that spans three
products cannot be sent as three product bodies — those carry prices, images and tiers that this
screen has no business rewriting, and a concurrent price edit would be silently reverted.

## 2. What has to be built

**Backend — a new endpoint.**

```
PUT /stock-items/{stock_item}/variants     can:inventory.manage
{ "variant_ids": [12, 13, 41] }
```

* one action, one transaction, audited per variant (a link moving is a real change);
* refuses a variant whose product is deleted, and a variant id that does not exist;
* the answer re-reads the material with its variants so the screen redraws from the server.

**Frontend.**

* the التصنيفات segment leaves the المخزون tab — the strip becomes المخازن · المواد;
* the «تصنيف المادة» picker leaves the product form and the product detail page;
* `save_product` keeps round-tripping `stock_item_group_id` **unchanged** — hiding a control that
  still round-trips is safe, deleting the round-trip clears every product's category on its next
  save;
* a new multi-select sheet on the material: products → variations → tick → save once, modelled on
  `variant_picker_sheet.dart` (which already opens a product's sizes underneath it).

## 3. What hiding the category actually costs

**The automatic mint stops.** Today, naming a category on a product creates a material for every
size it carries, at that size, with the category's unit — `ResolveStockItemForVariant`. That is
the entire reason `stock_item_group_id` exists. With the picker gone from the product form, a new
product's sizes are born unlinked and **every one of them must be linked by hand** from the
material side.

For a product with six sizes that is six ticks instead of one choice. It is also six chances to
tick the right box, where before there were none — which is the trade being asked for.

**Material names stop being dictated.** A filed material takes its name from its category, which is
what keeps `(name, width_cm, height_cm)` naming one pile. Typed by hand, «كيس شحن» and «كيس الشحن»
are two piles, and nothing notices until an order is short.

**Existing data is untouched.** Hiding is not deleting: `stock_item_groups` keeps its rows, its
endpoints and its audit trail, products keep their `stock_item_group_id`, and every material
already filed stays filed.

## 4. Open questions — these change the endpoint's shape

### Q1 · Does the tick list *replace* or *add*?

**Replace** — the material's variations are exactly what was ticked, and unticking one unlinks it.
Matches what a multi-select looks like it does, and gives unlinking a home.
**Add** — ticking links, unticking does nothing, and unlinking needs its own gesture elsewhere.

> **Answer: replace.** The endpoint takes the whole list and makes it true — links what is in it,
> unlinks what it dropped. `variant_ids: []` empties the material deliberately.

### Q2 · A variation already drawing on another material

Ticking it here moves the link. Past movements stay where they are — they are keyed by material,
not by variation — but everything this size deducts from now on comes off a different pile.

**Move silently** · **move after a confirm naming the old material** · **refuse, and make the
person unlink it first**.

> **Answer: move after a confirm that names the old material.** The picker marks such a variation
> and the confirm says which pile it leaves, because the person ticking it usually cannot see that
> from the row.

### Q3 · Does the category keep working behind the scenes?

**Yes** — products that already have one keep minting materials automatically on save; the control
is merely invisible. New products get none, because nothing can set it.
**No** — the resolution stops entirely and `stock_item_id` comes only from this new screen.

> **Answer: yes, it keeps working.** Nothing on the server changes. `save_product` keeps
> round-tripping `stock_item_group_id`, so a product that has a category keeps minting its sizes
> on every save, and nothing already filed comes loose.

### Q4 · Where does the material's screen live?

The material has a form and no detail screen. The link list can be a section **inside the form**
(below the fields), or a **row action** on the material card that opens the picker directly, like
the category's sheet does.

> **Answer: a section inside the form.**
>
> Which leaves one thing to decide that the question did not ask: the links save through their own
> endpoint, so «حفظ» now means two requests. Order matters — the material is saved first, and the
> links second, because on a **new** material there is no id to link to until the first one
> answers. A link request that fails after the material was stored leaves the material stored and
> the screen open on the selection, saying so; the alternative — refusing to store the material
> because the links failed — would throw away typing to protect a list that can be re-sent.
