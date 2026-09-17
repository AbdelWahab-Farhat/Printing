# Design Tickets — the app side

> **Status: built.** Branch `feat/design-tickets`. `flutter analyze lib` clean, the cubit tests
> green. The API it talks to is specified in
> [DESIGN-TICKETS-BACKEND.md](DESIGN-TICKETS-BACKEND.md), planned in
> [DESIGN-TICKETS-DESIGN.md](DESIGN-TICKETS-DESIGN.md), and published at `/docs/api`.

What the Flutter app does with تذاكر التصميم, and the handful of decisions in it that are not
obvious from the code.

---

## 1. The shape

`features/design_tickets/`, on the `features/shortages/` template — the same layers in the same
order as the recipe in [RULES.md §12](../../frontend/RULES.md).

```text
models/       design_ticket · design_ticket_file · design_ticket_counts · design_tickets_filter
repositories/ design_ticket_repository (abstract) + _impl
usecases/     design_ticket_usecases.dart — thirteen verbs, one class each
presentation/ viewmodel/ design_tickets_cubit · design_ticket_detail_cubit (+ state)
              views/     design_tickets_page · design_ticket_detail_page · design_ticket_form_page
              widgets/   design_ticket_card · design_ticket_status_pill · design_version_tile
                         · review_version_sheet · assign_designer_sheet · edit_ticket_sheet
```

Registered in one `_registerDesignTickets()` in [Injector](../../frontend/lib/core/di/injector.dart),
and reached through five routes — `/design-tickets`, `/form`, `/filter`, `/:id`, and `/:id/comments`
nested under the detail.

**Two doors into the form**, because the first build had none. The list's FAB opens a customer
picker first (the form cannot exist without a customer); a customer's own screen has a «طلب تصميم»
action that passes the `Customer` as `extra` and skips the picker. The drawer carries
«تذاكر التصميم».

---

## 2. The three decisions worth writing down

### 2.1 Buttons come from the server, never from a permission

`DesignTicket` carries `can_accept`, `can_submit`, `can_review`, `can_assign` and `can_manage`,
and **every button on the detail screen is drawn from one of them.** No screen asks
`Session.can(...)` about a ticket.

The reason is that none of these is a permission question. Each is a permission **and** the
status **and** this reader's role on this particular ticket:

- a designer may accept a pool ticket and not one addressed to a colleague;
- they may upload only after accepting, and only while the ticket is open;
- **nobody may review a version they uploaded themselves** — including an administrator, who
  holds every permission by rule.

That last one cannot be expressed as a permission at all, which is the clearest reason not to
try. A client that recomputed these would be a second implementation of the state machine in
another language, and it would drift the first time a rule changed — the app would offer a button
the API then refuses, which reads to the user as the app being broken.

### 2.2 The customer's name is a snapshot, and that is an access-control feature

`customer_name` sits on the ticket. The app **must not** reach for a `Customer` to render a card
or a header: a designer holds no grant on that table, and `GET /customers/{id}` answers them 403.
The snapshot is what lets the same screen draw for a designer and for the employee who raised the
ticket.

`customer_id` travels beside it so a reader who *does* hold `customers.view` can still follow the
link.

### 2.3 A 404 on a ticket means «ليست لك», not «غير موجودة»

The server narrows every route that binds a ticket: without `design_tickets.view_all` a reader
reaches the tickets they raised, the ones addressed to them, the ones they took, and the
unclaimed pool. Anything else is a **404** rather than a 403, deliberately — «ليس لديك صلاحية» on
a specific id confirms that the ticket exists, which is the thing being withheld.

So the detail screen shows the server's own sentence and does not translate a 404 into «هذه
التذكرة محذوفة».

---

## 3. The screens

### `design_tickets_page`

A search band, the queue row, the status row, then the list.

**The queue row is on the page rather than behind a filter button**, unlike the shortages screen.
«شغلي» and «الطابور المشترك» are the two things a designer flips between all day — one is their
work, the other is where they go to find more — and a question asked that often is worth one tap
rather than two. The status chips sit beside them carrying the server's counts.

`designer=me` and `designer=none` are words rather than ids: «me» is only knowable on the server
from the bearer token, and «none» is a null a query string cannot otherwise carry.

**Returning from the detail screen re-reads the page rather than patching the row.** Almost
everything that happens on a ticket changes its status, and the chips beside the list count
statuses — a row swapped in place would leave «جديد ٣» standing over a list of two.

### `design_ticket_detail_page`

The header, the brief, the attachment strip, then the versions in order — each with its verdict
and, where it was turned back, the words saying why.

**Every version ever uploaded stays on the screen.** Nothing is removed and nothing is replaced;
that is «الاحتفاظ بجميع نسخ التصميم السابقة» as a screen rather than as a promise.

The header prints **two** people when both exist: «المصمم» is whom the ticket is addressed to and
«استلمها» is who actually took it. A reassignment moves the first and never the second.

### `design_ticket_form_page`

Title, brief, instructions. The customer is **read, not chosen** — the form is opened from a
customer's own screen and takes the `Customer` as `extra`, the shape «طلبية جديدة» already uses.

**There is no designer picker, deliberately.** Routing work is `design_tickets.assign`, a grant a
different person holds, and a field that half the shop may not use mostly teaches people they are
not allowed to touch it. A ticket raised here goes to the shared pool, every designer is told, and
the first to accept takes it — which is the behaviour the business asked for anyway. Assigning is
a tap on the ticket itself.

**Attachments are uploaded after the ticket exists**, and the form says so. A ticket lost to a
failed upload is worse than a second tap.

---

## 4. Routing a designer

On the investor precedent, verbatim — a redirect that is **a courtesy, never a boundary**,
narrowed by permission rather than by role name:

```dart
if (session.can(AppPermission.acceptDesignTickets) &&
    !session.can(AppPermission.viewOrders) &&
    at == Routes.home) {
  return Routes.designTickets;
}
```

So an administrator who sometimes designs still reaches the screen they came for, and a business
that reshapes the «مصمم» role keeps this working. The real boundary is `can:design_tickets.*` on
the Laravel routes and the narrowing in the query behind them.

---

## 5. What was reused, and the one thing that was not

Reused as they stand: `PagedCubit` and `PagedListView` for the list, `SearchField`,
`FilterOptionChip`, `AppButton`, `AppTextField`, `showDestructiveDialog`, `context.showFailure`,
`AttachmentPicker` for the uploads, and `AuditSubject` for the history screen — one enum case, and
`/design-tickets/{id}/logs` renders in the screen every other record already uses.

**`DesignThumbnail` was not reused, and the plan said it would be.** It takes a `CustomerDesign`,
and generalising it would have meant changing a widget two shipped features already draw with. A
`DesignTicketFileThumbnail` was written instead — the same caching rule, the same fallback glyph,
the same `file_kind` vocabulary, so the two stay readable side by side.

> 🎯 **Worth revisiting.** The day a third caller appears, the right move is a small
> `DesignPreview` value that both models produce, and one widget in `core/widgets/` that takes it.
> Two near-identical widgets is the cost of not breaking two working screens today; three would
> not be.

---

## 6. The four gaps that were closed

The first build shipped screens with no way in, and a detail screen whose wired-up calls nothing
reached. All four are now built.

### 6.1 Assigning — `assign_designer_sheet.dart`

A searchable sheet over the staff, on the `assign_shortage_sheet` shape. Two things in it are
decisions rather than details:

**«الطابور المشترك» is an option at the top, not the absence of one.** The server reads null as an
instruction, so the sheet offers it rather than making somebody cancel out. That is why it answers
a `DesignerChoice` rather than a bare `AuthUser?` — null is already taken by
`showModalBottomSheet` returning null on dismissal, and «أرجِعها إلى الطابور» is a decision while
swiping the sheet away is not.

**The list is narrowed with `?permission=design_tickets.accept`**, not by role name. A filter on
«مصمم» would list the wrong people the day the business renames or splits that role, and would do
so silently.

### 6.2 Editing — `edit_ticket_sheet.dart`

Title, brief, instructions. A sheet rather than the form screen, because the ticket is open behind
it and pushing a page to change one line loses the thing being corrected from view.

**The customer is not editable, deliberately.** Files and a conversation hang off a ticket by the
time anybody notices the wrong one was picked, so a mis-addressed ticket is cancelled and raised
again — which leaves an honest record. The designer is its own sheet behind its own grant, because
routing work is a different job from describing it.

### 6.3 Removing an attachment

A long press on the thumbnail, not a badge on every tile: removing a reference file is rare, and an
X on each thumbnail would put a destructive tap next to the one people actually make, which is
opening it. The affordance is **absent** rather than disabled when `can_manage` is false.

### 6.4 The in-ticket conversation

`CommentSubject.designTicket(id)` joins the shared comments feature — the same four calls a
customer's notes use, at `/design-tickets/{id}/comments`, reached from a «المحادثة» action in the
app bar and a nested `comments` route.

**Behind `design_tickets.view` like the ticket itself**, writes included: a note is part of doing
the work, not a privilege over it. Who may change *this* note is a per-row question the server
answers with `can_edit` / `can_delete` on each comment — author, or somebody holding
`comments.moderate`. Administrators pass through `Gate::before`, so they can moderate without a
granted row.

### Still not built

- **Opening a version full-screen.** Tapping a version under review opens the verdict sheet;
  tapping any other one does nothing. `DesignViewer` is the widget to reach for.

---

## 7. Two changes outside this feature

Both were needed here and both affect screens that already shipped — worth knowing before blaming
this branch for a change elsewhere.

### 7.1 The comments screen is now a chat

`comments_page.dart` draws bubbles — yours at the end, theirs at the start, capped at 78% width,
with the author's name only on incoming ones — and orders **oldest-first** with `reverse: true`.

`AlignmentDirectional` and `BorderRadiusDirectional` throughout, never `left`/`right`: this app is
RTL, where a chat mirrors, and hard-coding the English answer would put both sides of the
conversation on the wrong edge.

> ⚠️ **This also changed the customer and supplier note screens**, which share the widget — and
> those were documented as newest-first. If that ordering mattered, the change needs scoping to
> design tickets rather than reverting wholesale.

**A pre-existing crash was fixed while in here**: `_promptForBody` disposed its
`TextEditingController` in `.whenComplete()`, while the dialog was still animating out, producing
`'_dependents.isEmpty': is not true`. An `_EditBodyDialog` StatefulWidget now owns and disposes its
own controller. The bug predates this branch — verified by stashing.

### 7.2 `GET /users` takes a `permission` filter

Threaded through `access_repository` → `_impl` → `get_users` → `users_cubit` so the designer picker
can ask «من يستطيع قبول تذكرة تصميم؟». Unrecognised values are ignored rather than refused — a typo
that emptied the list would read as «لا يوجد موظفون», which is false and undiagnosable from the
screen.

---

*A living document. When a rule here proves wrong, change it and record why — deliberate decisions
over cargo-culted ones.*
