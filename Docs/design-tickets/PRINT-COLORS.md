# «ألوان الطباعة» — the exact inks a design is printed in

> **§1–§8 shipped on `main`.** §9–§11 (mandatory colours, design tickets from the order,
> approval attaching the design) were built on `main` on 2026-11-11, uncommitted by request.
> Written in English; the shipped code and UI strings stay Arabic like the rest.
>
> **Decisions settled with the owner on 2026-11-02:** colors live on the design and are copied
> onto the order (option A); tickets carry them in the brief *and* on every version (T2); each
> color is a name, a code and an optional swatch; and the move into «قيد الطباعة» shows a
> read-only reminder.

---

## 1 · The request

Staff want to attach the inks to the design itself, so whoever prints does not get the shade
wrong. Optional, and any number of colors. Also in design tickets.

## 2 · What already existed

| Need | Already there |
| --- | --- |
| The artwork, owned by the customer | `customer_designs` — file never replaced, never erased |
| The artwork on one order | `order_designs` — versions pointing at the library, one approved |
| A designer's work | `design_tickets` + `design_ticket_files` (brief / submission) |
| Approved artwork into the library | `PromoteApprovedDesign` |
| A read-only box on a status move | `TransitionFieldType::Notice` |
| Every change in the history | `Auditable` + `AuditAttributeLabels` |

Nothing recorded color. People typed it into `notes`, which is where the mistakes came from.

## 3 · One color

```json
{ "name": "أحمر الشعار", "code": "PANTONE 186 C", "hex": "#E4002B" }
```

- **name**: required, at most 60 characters. How two people on the floor talk about it.
- **code**: optional, at most 60 characters. **The authority.** A Pantone or a CMYK mix, and
  what the press matches.
- **hex**: optional, `#RRGGBB`. A swatch to tell entries apart at a glance, **never the shade to
  print**. Phone screens disagree about color, and the UI says so.

At most 12 per list. Written through `PrintColors::normalise()`, which trims, turns blanks into
null, upper-cases the hex and stores an empty list as `null`. The four columns are all
`json` + `AsPrintColors`. On the wire they are always a list, and empty when there are none.

## 4 · Where the colors live

| Column | What it is |
| --- | --- |
| `customer_designs.print_colors` | The design's own colors. The source. |
| `order_designs.print_colors` | **A copy**, taken by `AddOrderDesign` when the design is attached. What the press reads. |
| `design_tickets.print_colors` | What the brief asks for. |
| `design_ticket_files.print_colors` | What a version was drawn in (submissions only). |

### Why the order holds a copy

The file cannot change under an order, but colors can be edited. An order printed last year must
keep saying which inks it was printed in, which is the same rule the file follows.

### When the copy follows the design

A copy taken today goes stale tomorrow. A clerk often attaches the file first and fills in the
colors after. So `RefreshOrderDesignColors` carries a library edit onto every version whose
order is still in `Order::designEditableStatuses()`, **and only where that copy still equals the
old value**. A version changed for its own order («هالمرة بالأزرق») keeps its own colors. Once the
order reaches «قيد الطباعة», its copy never moves again.

## 5 · The flows

**Library.** Upload (`POST customers/{c}/designs`, multipart `print_colors[0][name]`) and edit
(`PATCH customers/{c}/designs/{d}`) both accept `print_colors`; leaving the key out leaves it
alone. Edits go through `UpdateCustomerDesign`, which refreshes the open orders in the same
transaction. App: «ألوان الطباعة» in the design's options sheet, with dots on the tile.

**Order.** `PATCH orders/{o}/designs/{d}/colors` (`orders.designs.manage`) changes one version's
copy, and the body must contain `print_colors`. It is refused with `OrderDesignColorsAreLocked`
(422, under `print_colors`) once the order no longer accepts artwork. App: under each version on
«تعديل الطلبية»; read-only on the order screen.

**Ticket.**
1. The employee may add the requested colors when raising or editing the ticket. `PUT` treats
   the key as `sometimes`, so an older app's edit does not clear them.
2. Before uploading a version, the designer gets a colors sheet. It starts from the last
   version's colors, or from the brief's, and ends with «إرسال للمراجعة». Dismissing it cancels
   the upload.
3. The reviewer sees each version's colors on its tile.
4. On approval, `PromoteApprovedDesign` writes the version's colors (falling back to the brief's)
   onto the new library design. If the file is **already** in the library, its colors are filled
   only when it has none and are never overwritten, and its open orders are refreshed.

**The press.** On every move into «قيد الطباعة», `TransitionFields` adds a
`print_colors_reminder` field of type `print_colors`. It shows the approved version's copy, or
failing that the newest version that was not turned down, together with the line «طابِق الرمز لا
لون الشاشة. تُقفل الألوان بعد الانتقال إلى «قيد الطباعة»». It carries `colors`, and that key
appears on this type only. It earns no validation rule, and it is absent when there is nothing to
show. An older app draws it as «يحتاج نسخة أحدث من التطبيق», and the move still works.

**History.** `AuditValueLabels` finds `AsPrintColors` through the model's casts and shows
«أحمر الشعار (PANTONE 186 C)، أبيض» instead of JSON.

## 6 · Left out

- **The invoice PDF.**
- **Searching by color.** Nobody asked for it, which is why this is a JSON column rather than a
  table.

## 7 · Tests

- `backend/tests/Feature/Orders/OrderPrintColorsTest.php`: library validation and tidying, the
  copy on attach, the refresh rules (open, printed, overridden), the order edit and its lock,
  scoped binding, the reminder (approved, fallback, none, not answered) and the history wording.
- `backend/tests/Feature/DesignTickets/DesignTicketPrintColorsTest.php`: the brief (JSON and
  multipart), an edit keeping or changing the colors, a version's colors, promotion, the fallback
  to the brief, and an existing library file being filled but never overwritten.
- `frontend/test/core/print_colors/print_colors_test.dart`: model round-trip, hex parsing, the
  LTR code, and the editor (add, no-name refused, hex tidied, remove, limit).
- `frontend/test/features/orders/print_colors_reminder_test.dart`: the reminder parses and
  draws, and a version's copy parses, including from an older server.
- `backend/tests/Feature/Api/V1/Client/ClientDesignColorsTest.php`: §8. The customer uploads
  with colors and any code is dropped; a swatch is required; an edit reaches open orders; the
  list locks once a code exists; codes and the lock are visible; another customer's design
  returns 404; the press warning appears.
- `frontend-client/test/core/print_colors/print_colors_test.dart`: no code goes up, the model
  reads `print_colors_locked`, there is no code box, saving needs a picked swatch, codes render
  LTR, and `DesignsCubit.setColors` succeeds and is refused.

## 8 · Customers choose the colors (owner, 2026-11-02)

The customer chooses each color's **name and swatch**, and **an employee writes the code**.
The owner accepted all three recommendations:

1. **Lock.** Once an employee has written a code on any color of a design,
   `CustomerDesign::printColorsAreConfirmed()` is true and the customer can no longer change the
   list. `ChooseDesignColors` throws `PrintColorsAreConfirmed` (422, under `print_colors`), and a
   change goes through «تواصل معنا». Without the lock, a customer edit would wipe the codes.
2. **Codes are visible** to the customer, read-only. `CustomerDesignSummaryResource` sends
   `print_colors` with codes, plus `print_colors_locked`.
3. **A swatch is required** for every customer color. Choosing the color is the point of asking
   them.

**Server.** On upload (`POST client/designs`, multipart), `StoreClientDesignRequest` drops the
code rule and requires `hex`, and the controller passes the list through
`PrintColors::withoutCodes()`. Edits go to `PUT client/designs/{design}/colors`
(`UpdateClientDesignColorsRequest`, `present`) through `ChooseDesignColors`, which strips codes,
refuses a locked list, and refreshes open orders with `RefreshOrderDesignColors` in the same
transaction. The resulting color carries `code: null`, and the order copy and the reminder treat
it like any other color.

**Staff.** A color with no code shows «بلا رمز» in red on every chip. The reminder on the move
into «قيد الطباعة» swaps its line for «لون بلا رمز — أضف الرمز قبل الطباعة…» when any color
lacks a code. The move is not blocked, because only the person at the press knows whether it
can wait.

**Customer app.** The new-design dialog has the name, then an optional «ألوان الطباعة» field,
and «إنشاء» is still the only button. The design's options have a «ألوان الطباعة» row, which
opens the editor or, when locked, the colors with their codes and «اعتمد فريقنا هذه الألوان
برموزها — لتغييرها تواصل معنا». The card shows the colors as dots. The editor has a name box and
a 20-color palette, with no code box and no hex box. *(Since replaced: both apps share one sheet with
the HSV picker and a hex box, and §9 adds the basic inks above it.)*

**Release.** Existing customer-app installs keep working, since the new keys are simply ignored,
but they show none of this until a new customer-app release ships.

## 9 · Colours are mandatory on a print order (owner, 2026-11-11)

> «جعل خيار اضافة اللون اوضح ويكون اجباري لاي طلب طباعه بحيث لا تنشئ الطلبيه دون تحديد اللون
> واذا كانت لونين لا تنشئ دون تحديدهما»، and: basic inks to pick in one tap, beside the manual bar.

**A print order** is one on the standard road (`Order::isPrintedHere()`): at least one line our
press prints. Plain goods and outsourced work are not asked.

**A complete colour list** (`PrintColors::isComplete()`, `PrintColor.listIsComplete`) has at
least one colour, and every colour carries its swatch (`hex`) or a press code. A name alone does
not count: «أزرق» is how the wrong blue was printed.

### The sheet (both apps)

- **«عدد الألوان»** first: chips ١ · ٢ · ٣ · ٤ · أكثر. Picking ٢ makes two slots.
- **Every slot must have its colour.** A blank slot used to be dropped silently, which is how a
  two-colour design left with one. Now «حفظ» refuses, rings the empty slots in red and says
  «اختر لوناً لكل خانة — اللون 2». An untouched sheet still saves "no colours" where colours are
  optional; with `required: true` it does not.
- **«ألوان أساسية»** above the picker: أبيض `#FFFFFF`, أسود `#000000`, أزرق `#0057B8`, أخضر
  `#009A44`, أصفر `#FFD100`, أحمر `#E4002B`, ذهبي `#C9A227` (`print_color_presets.dart`). A tap
  fills the swatch, and the name unless somebody typed their own. Gold is drawn as a gradient
  because no flat swatch shows a metallic ink; the stored value is still one hex. The manual
  picker («أو حدّد اللون يدوياً») and the hex box stay under them.

### The rule, server side (`GuardPrintColors`)

| Moment | Rule | Refusal |
| --- | --- | --- |
| `POST /orders` (`CreateOrder`) | a non-rejected design on the order, each with complete colours — unless `design_source` is `in_house` and no design is attached yet (its colours are asked for on the design ticket, §10) | `PrintOrderNeedsADesign` (`design_ids`), `PrintOrderNeedsColors` (`print_colors`, names the design) |
| «بانتظار المراجعة» → «جديدة» (accepting a customer's request) | the same | the same |
| Every move into «قيد الطباعة» | the version the press prints (`Order::designForPress()`: approved, else newest not rejected) has complete colours | the same, worded «قبل الانتقال إلى «قيد الطباعة»» |

The creation check binds only on the clerk's door (an order born «جديدة»). A customer's request is
**not** refused at checkout: older installs would lose the checkout. It is refused at acceptance
instead, and the new customer app asks for the colours up front. An order the customer app opens
straight into «انتظار العربون» is never accepted, so it meets the rule at the press only. The
press gate is also what catches orders taken before the rule. Existing orders are otherwise left
alone, and edits are not re-checked: the press gate covers them.

**Colours typed in the new-order form** travel as
`design_colors: [{design_id, print_colors: [...]}]` (`StoreOrderRequest`; only for designs also in
`design_ids`; every colour needs `hex` or `code`). `CreateOrder` writes them to the library design
when its own list is not complete (`CustomerService::fillDesignColorsIfIncomplete`, which refreshes
open orders like any library edit); a design whose library colours are complete keeps them, and
only this order's copy takes the typed list. Anybody who may take the order may set them; the old
`customers.manage` gate on that button is gone, because a clerk who could not set colours could
not take a print order.

### The apps

- **Staff, «طلبية جديدة»:** on a print order the picker shows under every source (under «بدون
  تصميم» it means a reprint). Each chosen design is outlined in red with «مطلوب: ألوان الطباعة» and
  a full «تحديد ألوان الطباعة» button until its colours are complete; «إنشاء الطلبية» stays shut
  (`printArtworkIsReady`, `linesPrintHere` in `print_artwork.dart`). Under «من عندنا» with no
  design the form says the colours go on the design ticket. Colours are held in the form and sent
  with the order; nothing is written if the form is abandoned.
- **Staff, the order's «التصاميم»:** on a print order that still takes artwork, a version without
  complete colours says «مطلوب: ألوان الطباعة — لا تنتقل الطلبية إلى «قيد الطباعة» دونها», and the
  sheet there is `required`.
- **Customer, «سلتك»:** a chosen design without colours shows «حدّد ألوان الطباعة لهذا التصميم»
  and «تحديد ألوان الطباعة», which saves to the library through `PUT client/designs/{id}/colors`;
  «إرسال» stays shut until every chosen design has them (`designsMissingColors`).

## 10 · «تصميم طلبية» — a design ticket opened from the order (owner, 2026-11-11)

- **Where:** the order's «إضافة تذكرة» offers «تذكرة تصميم» beside «تذكرة داخلية» to somebody
  with `design_tickets.manage`, while the order still takes artwork (`designs_are_editable`).
  Otherwise it opens the internal ticket straight away, as before.
- **The form** (`DesignTicketForOrder`): customer and order locked, the chip «تصميم طلبية #N»,
  the title «تصميم طلبية N», the brief started with the order's lines, and the colours required
  when the order is printed here.
- **The kind is read off `order_id`**, so there is no new column. The chip shows on the ticket
  list, the ticket (tapping it opens the order) and the form.
- **No status move.** The owner pointed out that «جديدة» cannot reach «قيد التصميم» on the
  standard road (New → «جاهزة للطباعة» → «قيد التصميم» → «قيد الطباعة»): the warehouse weighs the
  goods at «جاهزة للطباعة». Staff move the order as they always did.
- **Server:** `CreateDesignTicket` refuses an order that no longer takes artwork, and on a print
  order refuses a brief without complete colours; `SubmitDesignVersion` refuses a version without
  complete colours (its own, else the brief's) on such a ticket. `DesignTicketResource` sends
  `print_colors_required` so the designer's sheet is `required`.
- **The press gate:** an order cannot move into «قيد الطباعة» (or «قيد التصنيع» on the وسيط road)
  while a linked design ticket is open.

## 11 · Approval puts the design on the order (owner, 2026-11-11)

Reverses DESIGN-TICKETS-DESIGN.md §12 Q5 («via a checkbox»).

- Approving the final version of a ticket linked to an order promotes it to the library as before,
  and **in the same transaction adds it to the order as a new version with status «معتمد»**
  (owner's choice; one line in `AttachApprovedTicketDesigns` if it changes), with the approved
  version's colours (else the brief's).
- **If the order does not take artwork at that moment** — «نواقص» — approval still succeeds, and
  the design is added the moment the order arrives in a status that does (`ChangeOrderStatus`).
  A cancelled or closed order gets nothing. This replaces the one-tap button the plan proposed:
  automatic is the same result with nothing for anybody to forget.
- The §10 gate keeps the order from reaching the press while the ticket is open, so the
  attachment cannot be missed on the way there.

## 12 · The colours are answered on the move itself (owner, 2026-11-11)

The press refused an order without colours, but the move screen offered no way to give them, so
staff had to back out to «تعديل الطلبية». Now the move into «قيد الطباعة» asks:

- **`print_colors_input`** (`TransitionFieldType::PrintColorsInput`, key `press_colors`) replaces
  the read-only reminder whenever the version the press will print has incomplete colours, or
  there is no version yet. `colors` carries what the version has, so the sheet opens on it.
- **Required** when a version exists; **optional** when there is none, because a design picked
  under «التصاميم» in the same move may bring complete colours of its own.
- The answer goes in the colours shape and every colour needs `hex` or `code`.
  `ChangeOrderStatus::applyPressColors()` writes it onto the press version, after any artwork the
  move attached, before the status is written; then `GuardPrintColors::forPress()` judges. Only
  the order's copy changes, as on «تعديل الطلبية».
- A version with complete colours still gets the read-only reminder.
- **Older staff apps** cannot draw the new kind, so they cannot make that move; they still reach
  the colours through «تعديل الطلبية».
- **Staff app:** `_PrintColorsAnswer` in `transition_field_input.dart`, outlined in red with
  «مطلوب» until complete; the move's send button stays shut until it is (`OrderStatusState.canSubmit`).
