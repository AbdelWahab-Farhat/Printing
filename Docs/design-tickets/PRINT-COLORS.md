# «ألوان الطباعة» — the exact inks a design is printed in

> **Branch `print-colors`, uncommitted by request.** Written in English; the shipped code and UI
> strings stay Arabic like the rest.
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
a 20-color palette, with no code box and no hex box.

**Release.** Existing customer-app installs keep working, since the new keys are simply ignored,
but they show none of this until a new customer-app release ships.
