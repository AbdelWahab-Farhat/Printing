# Design Tickets — from an employee's request to an approved design on the customer's account

> **Status: built.** Branch `feat/design-tickets`. Every phase in [§13](#13-the-implementation-plan)
> is done; the app side has its own document,
> [DESIGN-TICKETS-FRONTEND-INTEGRATION.md](DESIGN-TICKETS-FRONTEND-INTEGRATION.md).

The goal as it was given: **an organised system for design requests inside دعاية.** An employee
sends the request to a designer from inside the system, follows the revisions and the review
through to approval, and on approval the design is saved automatically onto the customer's
account.

---

## 1. The first thing that has to be said: half of this is already built

Before any new table, here is what exists in the system today and what this work stands on.
**Every row here is something we will not write:**

| What exists | Where | What it buys us |
|---|---|---|
| `customer_designs` | `Domain/Customer/Models/CustomerDesign` | **"التصاميم" on a customer's account already exists** — a private disk, a signed URL generated per request, a sha256 checksum that makes uploading idempotent, and **the file is never deleted**, a commitment written into the table itself |
| `UploadCustomerDesign` | `Domain/Customer/Actions` | Sniffs the mime type from the bytes rather than the client's claim, measures dimensions, refuses a duplicate, enforces the per-customer cap |
| `order_designs` | `Domain/Order/Models/OrderDesign` | The version conversation on an order: `version` allocated rather than counted, `proposed/approved/rejected`, `rejection_reason`, `reviewed_by`, and a partial index guaranteeing **exactly one approved version** |
| `ReviewOrderDesign` | `Domain/Order/Actions` | "A version is judged once", and approving supersedes the previous winner with a written reason |
| `Comment` + `HasComments` | `Domain/Comment` | **"الرد داخل التذكرة" is one `use` line and four routes.** Already generalised onto `commentable_type` |
| `Auditable` + `HasAuditTrail` | `Domain/Audit` | **The ticket history comes free** — who created it, when, what changed, in an Arabic sentence with a signed-in causer |
| `NotificationType` + `Definitions/` | `Domain/Notification` | **A new notification is one enum case and one class.** No migration, no endpoint, **and no new app release** |
| `NotificationAudience::user()` | `Domain/Notification/Audience` | An audience of one person — built for "نقص مُسنَد إليك" already |
| The whole `Shortage` context | `Domain/Shortage` | **The architectural template for this feature**: an `N7` code, a status, assignment, a "assigned to me" queue, counters, filters, and a complete Flutter screen |
| `DesignThumbnail` · `DesignViewer` · `design_picker_sheet` | `frontend/lib/features/customers` · `orders` | **Showing a design, opening it and saving it to the device is built and tested** |
| `assign_shortage_sheet.dart` | `frontend/.../shortages/presentation/widgets` | The assignment sheet in its finished shape — copied under another name |
| `investor_portal` + `Session.isInvestor` | `frontend/lib/core/session` | **The precedent for a narrow role**: an account that never reaches the staff shell and is redirected to its own screen |

The conclusion: what is genuinely missing is **the ticket itself** — the request, the acceptance,
the status path, and the promotion of the approved design into the customer's library. That is two
tables and seven actions, not a system from scratch.

---

## 2. Architectural decision one: a ticket is **not** an order status

`OrderStatus` already has «قيد التصميم», and the temptation is to hang the design request on it.

**No.** For the reason already written into the `order_designs` migration: "لم يعجبه التصميم، حط
التالي" **is a list, not a set of order statuses.** And a ticket goes further than that:

1. **A design request may have no order at all.** A customer wants a business card before they
   order any bags. Making the order mandatory makes an employee open a fake order to reach a
   designer.
2. **A ticket lives in somebody else's queue.** The designer's queue is not the orders screen, and
   it is not read by order status.
3. **`OrderStatus` is a state machine shared by every department.** Adding «بانتظار المراجعة» and
   «تعديل مطلوب» to it means two new states on every order in the system and new branching in
   every screen that reads a status — **which is breaking existing behaviour**, exactly what was
   asked to be avoided.

**So the ticket is its own entity**, and `order_id` on it is **optional** (§4). When a ticket is
approved and does name an order, the approved design becomes available to `AddOrderDesign` with no
new line in the `Order` context at all — because `order_designs` points at `customer_designs`, and
that is precisely where the promotion lands.

---

## 3. Architectural decision two: where do the designer's files live?

This is the question the whole feature turns on, and it has three answers.

### Option A — every designer upload goes straight into `customer_designs`

Versions become rows in `design_ticket_versions` pointing at the customer's library, exactly the
way `order_designs` does.

- ✅ **Zero new media code.** `UploadCustomerDesign` unchanged, the signed URL unchanged, and every
  Flutter design widget works untouched.
- ❌ **Rejected drafts enter the customer's account.** That contradicts the written acceptance
  criterion: "التصميم النهائي **فقط** هو الذي يضاف إلى حساب الزبون كتصميم معتمد".
- ❌ Fixing it means a new column on `customer_designs` and a filter inside an endpoint **that
  works today** — a behaviour change in a screen already built, which is what we were asked to
  avoid.

### Option B — the ticket owns its files, and approval promotes the winner ← **recommended**

The ticket gets a file table of its own. On approval, `PromoteApprovedDesign` creates a
`customer_designs` row from the approved version alone.

- ✅ **The customer's account stays exactly what it is today**: approved artwork and nothing else.
  No change to an existing endpoint, no change to an existing screen. **Zero breakage.**
- ✅ "Only the final design" is guaranteed **by construction**, not by a filter somebody can forget.
- ✅ A ticket's drafts stay inside the ticket, which is where they belong: they are a work
  conversation, not the customer's property.
- ⚠️ The cost: the media mechanics (disk, path, original name, size, checksum, signed URL) get
  written for a fourth context. **And this is precisely what [BACKLOG.md](../BACKLOG.md) warns
  about in so many words**: "آليّة الإيصال … تعيش في `Order\Actions\StorePaymentReceipt`، ونسخُها
  لسياقٍ رابع خطأ". So the answer is not to copy it but to **extract** it — §5 below.

### Option C — one file uploaded once, referenced from both sides

Upload to a staging disk, move the object on approval.

- ❌ Moving the object breaks `customer_designs`'s commitment that a file never moves and is never
  erased, and it adds a new failure mode (object moved, then the insert fails) at the most
  sensitive point in the system. **Rejected.**

> **Recommendation: Option B**, with the media extraction (§5) as its prerequisite. The extraction
> is not a tax on this feature — it is a debt already recorded in BACKLOG that this work pays off,
> and `StorePaymentReceipt`, `UploadProductImage` and `UploadCustomerDesign` all benefit after it.

---

## 4. The tables

### `design_tickets`

| Column | Type | Why |
|---|---|---|
| `id` | bigint | |
| `code` | string(20) | **`D7`** — from this table's own sequence, the way a customer gets `C7` and a shortage `N7`. Reserved before the insert (the `AllocateCustomerIdentifier` precedent) so two concurrent requests cannot collide |
| `customer_id` | FK, not nullable | A ticket is **always** for a customer — an explicit acceptance criterion |
| `customer_name` | string | **A snapshot.** The `order_items.product_name` precedent: a customer gets renamed, and the ticket is a record of what was asked for. **It is also what spares the designer `customers.view`** — §6 |
| `order_id` | FK **nullable** | §2. The order if there is one, and no cascade — the ticket outlives it |
| `title` | string | "تصميم كيس شحن — أسود". What is read in the queue |
| `description` | text | The design request itself |
| `instructions` | text nullable | Notes and instructions — a second field because the description is read on the card and the instructions are only read once the ticket is opened |
| `status` | string(20) | `DesignTicketStatus` — §7 |
| `requested_by_user_id` | FK `nullOnDelete` | The employee who owns the ticket. The one who reviews and approves |
| `assigned_designer_id` | FK nullable `nullOnDelete` | The requested designer. **Null means the shared pool**, a real and common state rather than missing data (the `shortages.assigned_to_user_id` precedent) |
| `accepted_by_user_id` | FK nullable | **Who actually took it.** Deliberately separate from `assigned_designer_id`: the first is an intention, the second is a fact. "لا تضيع هوية المصمم الذي استلم الطلب" is about this column |
| `accepted_at` | timestamp nullable | |
| `completed_at` | timestamp nullable | The moment the ticket closed |
| `approved_by_user_id` | FK nullable | Who approved. A different question from who created it |
| `approved_customer_design_id` | FK nullable | **The output**: the customer-library row the approval produced. This is what makes "the ticket it came from" readable in both directions |
| `timestamps` + `softDeletes()->index()` | | RULES §10 — not optional |

**Indexes:** `(status, id)` for the list · `(assigned_designer_id, status)` for the "assigned to me"
queue · `(requested_by_user_id, status)` for "waiting on my review" · `customer_id` · `order_id`.
**A partial unique** on `code` `WHERE deleted_at IS NULL`, as every unique index in this schema is.

**Database-level constraints** (RULES §8 — validation gives the readable 422, the constraint is the
guarantee):

```sql
-- An accepted ticket has a taker and a time; an unaccepted one has neither.
CHECK ((accepted_at IS NULL) = (accepted_by_user_id IS NULL))

-- "Completed" means: closed, approved by somebody, and it produced a row in the customer's
-- library. All three together, or none of them.
CHECK (
  (status <> 'completed')
  OR (completed_at IS NOT NULL AND approved_by_user_id IS NOT NULL
      AND approved_customer_design_id IS NOT NULL)
)
```

> The second constraint is what makes "the approved design is added to the customer's account"
> **unrepresentable when wrong**, rather than a step inside an action that a later author can
> forget.

### `design_ticket_files`

One file table for the ticket, distinguished by a `kind` column:

| Column | Type | Why |
|---|---|---|
| `design_ticket_id` | FK cascade | |
| `kind` | string(20) | `brief` (the employee's attachment: the logo, a similar example) \| `submission` (the designer's upload) |
| `disk` · `path` · `original_filename` · `mime_type` · `file_kind` · `size_bytes` · `checksum` · `width_px` · `height_px` | | **The same columns as `customer_designs`, verbatim** — produced by the piece extracted in §5 |
| `version` | smallint nullable | For submissions only. **Allocated, not counted** (`max+1`, `withTrashed`) exactly as in `AddOrderDesign` |
| `status` | string(20) nullable | For submissions: `proposed` \| `approved` \| `changes_requested` |
| `review_note` | text nullable | **What has to change** — "كبّر الشعار وغيّر الرقم" |
| `reviewed_at` · `reviewed_by` | | |
| `uploaded_by_user_id` | FK | Who uploaded — the employee on a `brief`, the designer on a `submission` |
| `note` | text nullable | The designer's note sent with the design |
| `timestamps` + `softDeletes()->index()` | | |

**The shape constraint** — in the same form as the existing `shortages_source_shape`:

```sql
CHECK (
  (kind = 'submission' AND version IS NOT NULL AND status IS NOT NULL)
  OR
  (kind <> 'submission' AND version IS NULL AND status IS NULL
   AND reviewed_at IS NULL AND reviewed_by IS NULL)
)
```

**A partial unique** on `(design_ticket_id, version) WHERE kind='submission' AND deleted_at IS NULL`
— two rows claiming to be version 3 is a bug, not a decision. **And a second partial unique** on
`(design_ticket_id) WHERE status='approved' AND deleted_at IS NULL` — one approved version, the
same index that makes "which one do we print?" answerable in `order_designs`.

> **Two tables, not three, and why.** The alternative splits `design_ticket_attachments` from
> `design_ticket_versions`. We rejected it because the screen reads both from one place (an
> attachment strip and a version list), and the separation buys a distinction that the `CHECK`
> above buys with one column. **But this decision is reversible** — §12 Q2.

### One additive change to `customer_designs` (three nullable columns)

`design_ticket_id` · `designer_user_id` · `approved_at`.

Existing rows stay NULL, and NULL means "uploaded by hand" — which is true. **No existing endpoint
changes behaviour**; `CustomerDesignResource` gains three fields that are read and never sent. This
covers what the brief asked to keep for each design on the customer's account: the file, the name
(`label`, already there), the approval date, the ticket, the designer, and the notes (`notes`,
already there).

---

## 5. The debt this work pays off: `Support/Media/StoreUploadedFile`

Four contexts write the same logic today: `UploadProductImage`, `UploadCustomerDesign`,
`StorePaymentReceipt` — and this would have been the fourth. [BACKLOG.md](../BACKLOG.md) already
recorded the objection in writing.

**The proposal:** `App\Support\Media\StoreUploadedFile` — one action taking a file, a disk and a
folder, returning a `StoredFile` (a readonly DTO: `disk`, `path`, `originalFilename`, `mimeType`,
`sizeBytes`, `checksum`, `width`, `height`), and guaranteeing three things in one place:

1. **The type is sniffed from the bytes**, never taken from the client's claim.
2. **The checksum is taken before the move**, while the temporary copy is still readable.
3. **The name is generated (UUID)**, so the uploader chooses no path and two "logo.pdf" cannot
   collide.

And a `HasStoredFile` trait carrying `url()` (signed or plain, asked of the disk) and `storage()`.

**Scope of change:** a pure extraction. `UploadCustomerDesign` keeps its name and signature and
calls the new piece, so nothing above it changes. The existing tests for those three actions
**stay exactly as they are and stay green** — that is the success criterion for the extraction.

> If the extraction is declined (§12 Q3), the logic is copied a fourth time and recorded in
> BACKLOG. **The feature does not depend on this**, but it is cheaper today than after three more
> contexts.

---

## 6. Permissions — and the rule behind them

Seven new cases in `PermissionName`. The split follows the same reasoning that split `shortages.*`
five ways and `orders.payments.*` three: **separate where the level of trust differs or the job
differs, not wherever separation is possible.**

| Permission | Arabic label | Who holds it |
|---|---|---|
| `design_tickets.view` | عرض تذاكر التصميم | Designer and employee — **and it is narrowed, §6.1** |
| `design_tickets.view_all` | عرض كل تذاكر التصميم | The supervisor. Without it a user sees only what concerns them |
| `design_tickets.manage` | إنشاء وتعديل طلبات التصميم | The employee |
| `design_tickets.assign` | إسناد التذاكر إلى المصممين | The supervisor. **Separate from `manage`** on the same argument `shortages.assign` makes: routing work is not doing it |
| `design_tickets.accept` | قبول طلب تصميم | **The designer alone.** It is also what defines "designers" as a notification audience |
| `design_tickets.submit` | رفع تصميم داخل التذكرة | The designer |
| `design_tickets.review` | الموافقة على التصميم أو طلب تعديل | **The employee, and never granted to the designer role** |

### 6.1 What a designer cannot see — and how it is actually prevented

The acceptance criterion reads: "تطبيق الصلاحيات بحيث لا يستطيع المصمم الوصول لما لا يخص عمله".
That is enforced in **three layers**, not one:

1. **The query.** `DesignTicketListQuery` narrows a reader without `view_all` to: what they created,
   what is assigned to them, or what is **in the shared pool and not yet accepted**. The same shape
   `ShortageListQuery` uses to narrow on the archive.
2. **The binding.** Every route binding `{ticket}` goes through the same narrowing, so a
   colleague's ticket is **a 404 by construction** rather than by a check somebody has to remember.
3. **A snapshot instead of a grant.** The ticket carries `customer_name` (§4), so a designer reads
   the customer's name **without `customers.view`** — the permission that opens the customer's whole
   file, their orders and their money. This is the existing idiom in this schema
   (`orders.city_name`, `shortages.customer_id`) used for its purpose.

### 6.2 "The designer does not approve their own work" — not a permission question alone

The closing note in the brief is right, and withholding `design_tickets.review` from the designer
role is not enough: an administrator holds everything through `Gate::before`, and could upload a
version and then approve it.

**The answer is what the system already does in `ConfirmDepositReceipt`:** the domain itself refuses
a reviewer who is the uploader.

```php
final class DesignerCannotReviewOwnWork extends DomainException { }
```

A live precedent in this repository, not an invention: "the domain refuses the tick to the person
who made the claim, so at least two users must hold it". Separating execution from approval becomes
**a domain rule**, not an arrangement on the roles screen that one click can undo.

### 6.3 A "مصمم" role

The brief asks for a **role**. `RoleName` says roles are data unless the code references one — but
`Accountant` is already seeded there as an example with no code reference. The precedent exists.

**Recommendation:** `RoleName::Designer = 'designer'`, labelled «مصمم», seeded in `RoleSeeder`
holding `design_tickets.view` + `.accept` + `.submit` and nothing else. **No `customers.view`, no
`orders.view`, nothing further.** That gives the system a role that works on day one, and it stays
entirely the administrator's to reshape from the roles screen.

The alternative (§12 Q4): seed no role, ship only the permissions, and let the administrator
compose it — purer in theory, slower in practice.

---

## 7. The ticket's path

```text
New ──(designer accepts)──► In design ──(uploads a version)──► Under review
        جديد                 قيد التصميم                      بانتظار المراجعة
                                  ▲                                 │
                                  │                     ┌───────────┴───────────┐
                                  │                     │                       │
                      (uploads a revised version)  (changes requested)      (approved)
                                  │                     │                       │
                                  └──── Changes requested ◄┘                     ▼
                                          تعديل مطلوب                        Completed
                                                                               مكتمل
```

`DesignTicketStatus`: `New` · `InProgress` · `UnderReview` · `ChangesRequested` · `Completed`
( · `Cancelled` — §12 Q1).

### The rule that governs this enum

**There is no endpoint that changes a status.** Not one of these is picked from a dropdown — each is
written by the action that earns it:

| Status | Written by | And by nothing else |
|---|---|---|
| `New` | `CreateDesignTicket` | |
| `InProgress` | `AcceptDesignTicket` | and from `ChangesRequested` when the designer uploads again |
| `UnderReview` | `SubmitDesignVersion` | |
| `ChangesRequested` | `ReviewDesignVersion` with a "changes" verdict | |
| `Completed` | `ReviewDesignVersion` with an "approve" verdict | together with the promotion and the close, in one transaction |

This is a direct extension of what `ShortageStatus` states outright: "the status it must never offer
is the one the list never contains". `allowedNext()` here is not a source of buttons — it is **how
the actions refuse an illegal move** — and the app draws its buttons from `can_*` on the resource,
not from a list of statuses.

### Rules along the path

- **Accepted once.** An accepted ticket refuses a second acceptance with
  `DesignTicketAlreadyAccepted`. The race (two designers tapping at once) is settled by a
  conditional update `WHERE accepted_at IS NULL`, not by a PHP check that both requests pass before
  either commits — the rule RULES §8 imposes.
- **A change request requires words.** `DesignReviewRequiresNote` — on the argument
  `DesignRejectionRequiresReason` already makes verbatim: "the whole value of tracking versions is
  knowing *why* one was replaced; a rejection with no reason turns the history into a count".
- **A change request never opens a new ticket.** An explicit acceptance criterion, guaranteed by the
  fact that a version is a row and the ticket is the same ticket — the same shape `order_designs`
  chose for a written reason.
- **A version is judged once.** `DesignVersionAlreadyReviewed`.
- **Old versions are never replaced and never erased.** No endpoint swaps a version's bytes. A new
  upload is a new row with a new number. That is the table's commitment, not the action's habit.
- **After closing: read only.** No upload and no review on `Completed`. And the history stays whole
  — an acceptance criterion.

---

## 8. The API

Every route under `auth:sanctum`, each with its own `can:`, as `routes/api.php` does today.

| Verb | Path | Guard |
|---|---|---|
| `GET` | `/design-tickets` | `design_tickets.view` |
| `GET` | `/design-tickets/summary` | `design_tickets.view` — status counters. **Declared before `{ticket}`**, or the router reads the word as an id (the trap already documented at `shortages/summary`) |
| `POST` | `/design-tickets` | `design_tickets.manage` |
| `GET` | `/design-tickets/{ticket}` | `design_tickets.view` + the §6.1 narrowing |
| `PUT` | `/design-tickets/{ticket}` | `design_tickets.manage` — title, description, instructions, while it is open |
| `PATCH` | `/design-tickets/{ticket}/designer` | `design_tickets.assign` — assign, reassign and unassign, **one action for all three** as `AssignShortage` is |
| `POST` | `/design-tickets/{ticket}/acceptance` | `design_tickets.accept` |
| `POST` | `/design-tickets/{ticket}/attachments` | `design_tickets.manage` — `multipart/form-data` |
| `DELETE` | `/design-tickets/{ticket}/attachments/{file}` | `design_tickets.manage` — `scopeBindings()` |
| `POST` | `/design-tickets/{ticket}/versions` | `design_tickets.submit` — `multipart/form-data` |
| `POST` | `/design-tickets/{ticket}/versions/{version}/review` | `design_tickets.review` |
| `GET·POST·PUT·DELETE` | `/design-tickets/{ticket}/comments[/{comment}]` | `view` / `view` / the author or `comments.moderate` |
| `GET` | `/design-tickets/{ticket}/logs` | `logs.view` |

**Notes:**

- `scopeBindings()` on every route binding a file inside a ticket — so another ticket's file id is
  **a 404 by construction**, the shape `orders.designs` and `customers.designs` use today.
- **No `DELETE /design-tickets/{ticket}`** in the first phase. Deleting a ticket carries the same
  archive questions `ORDER-DELETE-AND-ARCHIVE.md` answered with three permissions. Cancellation
  (§12 Q1) is the right answer, and deletion is deferred to BACKLOG.
- `DesignTicketResource` publishes computed flags: `can_accept` · `can_submit` · `can_review` ·
  `can_assign`. **The app draws its buttons from those**, so no second copy of the route rules
  exists in Dart to drift from the first. The precedent: `TransitionFields` on an order.
- **The spec is generated** (Scramble). `rules()` is written out in full without `array_merge` —
  otherwise the endpoint publishes with no request body at all, a trap documented in RULES §7.

---

## 9. Approval: the action that closes the loop

`ApproveDesignTicket` — **one transaction** (`DB::transaction`), four steps:

1. **Refuses if the reviewer is the uploader** (§6.2).
2. `ReviewDesignVersion(approved)` — seals the version and supersedes any previously approved one
   with a written reason, exactly as `ReviewOrderDesign` does today.
3. `PromoteApprovedDesign` — creates the `customer_designs` row from the version's file, carrying
   `design_ticket_id`, `designer_user_id` and `approved_at`. **And `label` comes from the ticket's
   title**, not from the filename, because `CustomerDesign` itself says the label is the whole
   identification story — there are no PDF thumbnails.
4. Closes the ticket: `Completed` + `completed_at` + `approved_by_user_id` +
   `approved_customer_design_id`.

**Idempotency comes free:** if the same file was already in the customer's library, the sha256
checksum answers with the existing row instead of a second copy — that is `UploadCustomerDesign`'s
written behaviour today.

> **And this is where this work meets what is already built:** the design is now in the customer's
> library, so `AddOrderDesign` and `design_picker_sheet` see it immediately, **without one new line
> in the `Order` context.** Attaching the ticket's design to its order automatically on approval is
> deliberately deferred — §12 Q5.

---

## 10. Notifications and the history

### Notifications — **two types, not six**

The brief counts six events. `OrderReachedStatus` got to the answer first: one type for fifteen
statuses, because they share an audience, a route and a sentence. Here the audience splits two ways
and no further:

| Type | Audience | Events |
|---|---|---|
| `design_ticket.assigned` | The named designer, or **everybody holding `design_tickets.accept`** when it is in the shared pool | a new ticket · a reassignment |
| `design_ticket.status` | **The other party**, decided from the status: acceptance and submission → the requester; a change request → the designer; approval → both | acceptance · design submitted · changes requested · revised version uploaded · approval |

Each is one class in `Definitions/` and one case in `NotificationType` — **and nothing else**: no
migration, no endpoint, **and no new app release**, because the app renders whatever the server
sends. And the icon for `design_ticket.assigned` is `'task'` on the same argument `ShortageAssigned`
makes: work arriving, not an alarm.

`notifiesCauser(): false` on both — somebody who accepted a ticket watched it happen on their own
screen.

### The history — free

`use Auditable` + `implements HasAuditTrail`, and two cases in `AuditSubject`: `design_ticket` and
`design_ticket_file`. `auditTrailSubjects()` covers the ticket's files and its comments, so
`GET /design-tickets/{ticket}/logs` reads **the whole story**: who created it and when, who accepted
it, the messages, the files, the versions, the change requests, who approved, and the moment it
closed. That is the brief's entire "سجل التذكرة" section, for three lines of code.

> **The known trap:** a mass delete fires no model events. Any cleanup of a ticket's files iterates
> — `->each(fn ($f) => $f->delete())` — as RULES §10 requires.

---

## 11. The app (Flutter)

A new `features/design_tickets/` on the `features/shortages/` template exactly — the same layers, in
the same order as the recipe in RULES §12.

### What is reused unchanged

| Piece | Used here for |
|---|---|
| `DesignThumbnail` · `DesignViewer` | Thumbnails for attachments and versions, and full-screen viewing |
| `save_design_to_device.dart` | "Save to device" for both the designer and the employee |
| `upload_customer_design` (the upload pattern) | Uploading an attachment and a version |
| `assign_shortage_sheet.dart` | → `assign_designer_sheet.dart`, the same shape |
| `shortage_status_pill.dart` | → `ticket_status_pill.dart` |
| `shortage_filter_button.dart` · `shortages_cubit.dart` | The list, the filters and the counters |
| `AppButton` · `AppDropdown` · `showCustomDialog` · `showDestructiveDialog` · `context.showFailure` | As always — and no bare `FilledButton` in a screen |

### One change to existing code: move the two design widgets to `core/widgets/`

`DesignThumbnail` and `DesignViewer` live today in `features/customers/presentation/widgets/` and
are already used by `features/orders`. With a third feature the case is settled: **a shared widget
belongs in `core/widgets/`** — RULES §2. The move is mechanical, and with
`always_use_package_imports` enabled `flutter analyze` catches every import that did not follow.
**No behaviour changes and no pixel moves.**

### The screens

1. **`design_tickets_page`** — the list, with status tabs and counters from `/summary`. And for a
   designer, a **"shared pool"** tab (unassigned + `New`).
2. **`design_ticket_detail_page`** — the header (customer, title, status, designer), then the
   description and instructions, then the attachment strip, then **the timeline**: versions, their
   verdicts and the comments in one sequence read top to bottom.
3. **`design_ticket_form_page`** — creation: customer, title, description, instructions,
   attachments, and the designer (optional).

**Buttons are drawn from the `can_*` flags on the resource** (§8), not from `Session.can(...)` —
because the condition here is composed of the permission **and the status and this reader's role on
this ticket**, and copying that into Dart is a second copy that drifts.

### Routing a designer

On the investor precedent, verbatim: a redirect that is **a courtesy, never a boundary**, narrowed
by permission rather than by role name — `can(designTicketsAccept) && !can(viewOrders)` →
`/design-tickets`. So an administrator who sometimes designs still reaches the screen they came for.
The real boundary is `can:` on the Laravel route, exactly as `app_router.dart` says today.

---

## 12. The questions, and how they were answered

**Answered by the business on 2026-09-15.** Q1, Q3, Q4 and Q5 were decided explicitly; Q2 and
Q6–Q8 were left to the recommendation as written, which is therefore the decision. Nothing below
is open — this section is now the record of what was chosen, not a request.

| # | Question | Decision |
|---|---|---|
| **Q1** | **Can a ticket be cancelled?** The brief does not mention it, and tickets are always opened by mistake | ✅ **Decided: yes.** — `Cancelled` + `POST /{ticket}/cancellation` behind `design_tickets.manage`, with a mandatory reason. Without it a mistaken ticket sits in a designer's queue forever, and the only alternative is a delete that erases the history |
| **Q2** | **One file table or two?** | ✅ **Decided: one** (left to the recommendation)., with `kind` + a `CHECK` (§4). The screen reads both from one place, and the split buys a distinction one column already buys |
| **Q3** | **Extract `StoreUploadedFile` now?** | ✅ **Decided: yes.** (§5) — a debt already recorded in BACKLOG, and this is the fourth time. Declining is acceptable and gets recorded; the feature does not depend on it |
| **Q4** | **Seed a "مصمم" role?** | ✅ **Decided: yes.** (§6.3) — a role is what was asked for, and `Accountant` is the precedent. The administrator can reshape it from the screen at any time |
| **Q5** | **On approval, is the design attached to the order automatically?** | ✅ **Decided: no — via a checkbox.** `AddOrderDesign` refuses while an order's designs are locked by its status, and an automatic step that fails half the time is worse than a button that is pressed |
| **Q6** | **Does the designer get to see the customer's design library** to match a style? | ✅ **Deferred to BACKLOG** (left to the recommendation). The brief does not ask for it, and it opens "which customers?" — and with it `customers.view` through the back door |
| **Q7** | **A due date or a priority on the ticket?** (`due_at` / `is_urgent`) | ✅ **Deferred** (left to the recommendation). `orders.is_urgent` is a ready precedent the day it is asked for, and a column no screen reads is a column that lies |
| **Q8** | **One designer per ticket?** | ✅ **Decided: yes** (left to the recommendation). — a single `accepted_by_user_id`. Several designers on one ticket destroys "the identity of whoever took it is never lost" |

---

## 13. The implementation plan

Every phase is **mergeable on its own**: Pint clean, `scramble:analyze` clean, the whole suite green
(RULES §12).

| # | Phase | Contents |
|---|---|---|
| **0** | Decisions | ✅ **Done** — the answers in §12 |
| **1** | Media ✅ | `StoreUploadedFile` + `StoredFile` + `HasStoredFile`, and the three existing actions converted onto them. **Success criterion: their tests stay exactly as they are and stay green** |
| **2** | Permissions ✅ | Seven cases in `PermissionName` + `RoleName::Designer` + `RoleSeeder` + a grant migration |
| **3** | Schema ✅ | Two new migrations + the three-column migration on `customer_designs`. `migrate --pretend` before running |
| **4** | Domain ✅ | `DesignTicketStatus` · `DesignTicketFileKind` · the models · `CreateDesignTicket` · `AcceptDesignTicket` · `AssignDesignTicket` · `SubmitDesignVersion` · `ReviewDesignVersion` · `PromoteApprovedDesign` · `ApproveDesignTicket` · the exceptions · `DesignTicketListQuery` · `DesignTicketService` |
| **5** | API ✅ | The controller · FormRequests (`rules()` written out in full) · the resources with `can_*` · the routes · `DesignTicketCommentController` · `/logs` · `AuditSubject` |
| **6** | Notifications ✅ | Two types + two classes in `Definitions/` + two listeners |
| **7** | Tests ✅ | **Written alongside each phase, not after them** — §14 |
| **8** | The app ✅ | Move the two widgets to `core/widgets/` · the new feature · `AppPermission` · the router · `Injector` · the Cubit tests |
| **9** | Documentation ✅ | This document → "Implemented" · `DESIGN-TICKETS-FRONTEND-INTEGRATION.md` · `Docs/README.md` · `Docs/BACKLOG.md` (Q6, Q7 and deletion) · `composer spec` |

### Where the build departed from this plan

Two, both recorded rather than quietly absorbed:

1. **`DesignThumbnail` was not moved to `core/widgets/`.** §11 planned to generalise it so one
   widget drew a customer design and a ticket file alike. It takes a `CustomerDesign`, and
   changing it would have meant touching a widget two shipped features already draw with — for a
   third caller. A sibling `DesignTicketFileThumbnail` was written instead, with the same caching
   rule and the same fallback. The generalisation is the right move at the *fourth* caller, and it
   is recorded in the frontend document.

2. **Four endpoints are wired through the app and not yet on a screen** — assigning, editing a
   ticket's words, removing an attachment, and the in-ticket conversation. The API answers all of
   them and the repository calls them; what is missing is a sheet and a section. Listed by name in
   the frontend document §6.

---

## 14. Tests

RULES §6: TDD, AAA in three visible sections, PostgreSQL, and a real token rather than
`Sanctum::actingAs`.

**The per-endpoint checklist** — the happy path, validation (422 with field errors), 401, 403, 404,
lists (pagination, filtering, the empty set, an absurd `per_page`), boundaries (Arabic text, very
long input), ownership, the envelope, and invariants (a server-assigned field the client cannot
supply).

**And the cases specific to this feature:**

- ✅ An accepted ticket **refuses** a second acceptance — from a different designer in particular.
- ✅ **Execution separated from approval**: whoever uploaded a version is refused when reviewing it,
  even as an administrator.
- ✅ A change request **with no note** is refused.
- ✅ Two consecutive revision cycles **on the same ticket**, with all three versions still present
  under their numbers.
- ✅ Approval **creates exactly one row** in `customer_designs`, carrying the ticket, the designer
  and the approval date.
- ✅ Approving a file **already in the customer's library** does not create a second copy (the
  checksum).
- ✅ A closed ticket refuses uploads and reviews, **and its history reads in full after closing**.
- ✅ **A designer cannot see a colleague's ticket** — a 404, not a 403, because the narrowing is in
  the query.
- ✅ A designer reads the customer's name **without `customers.view`**, and cannot reach
  `/customers/{id}`.
- ✅ A notification reaches the designer on assignment, **and does not reach somebody who assigned
  it to themselves**.
- ✅ An impossible state refused at the database: `completed` with no `approved_customer_design_id`.

**And in Flutter** (RULES §9): each Cubit's state sequence, that **the server's Arabic message is
the one shown**, and the boundaries (an empty list, the last page, a failed extra page not wiping
what is displayed).

---

## 15. What is deliberately left out of this work

Recorded in [BACKLOG.md](../BACKLOG.md) by name and with its reason, never forgotten silently:

- **Deleting and archiving a ticket** — the three questions `ORDER-DELETE-AND-ARCHIVE.md` answered
  apply here too, and cancellation (Q1) covers the practical need.
- **The customer's design library in a designer's hands** (Q6).
- **A due date and a priority** (Q7).
- **Measuring a ticket's time** — "how many days did it sit with the designer?". No transitions
  table, on the same argument `ChangeShortageStatus` makes: `ActivityLog` already holds the answer,
  and the day the question is asked it is a query to write, not a table.
- **A reminder notification** on a stale ticket — it needs a scheduler, and that is an operations
  decision rather than a feature one.

---

*A living document. When a rule here proves wrong, change it and record why — deliberate decisions
over cargo-culted ones.*
