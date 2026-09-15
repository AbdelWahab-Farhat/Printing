# Design Tickets — the backend

> **Status: built.** Branch `feat/design-tickets`. 39 feature tests, 193 assertions, green.
> Pint clean. The plan this was built from is
> [DESIGN-TICKETS-DESIGN.md](DESIGN-TICKETS-DESIGN.md); the app side is
> [DESIGN-TICKETS-FRONTEND-INTEGRATION.md](DESIGN-TICKETS-FRONTEND-INTEGRATION.md).

Everything the server does with تذاكر التصميم: the tables, the actions, the seventeen routes, the
refusals, and the reasoning behind the choices that look odd from outside.

---

## 1. What this feature is, in one paragraph

An employee raises a design request against a customer. A designer claims it — which is a
deliberate step, so two designers never draw the same bag. They upload a version; the employee
either approves it or sends it back with words saying what to change. Sending it back loops on the
**same ticket**, as many rounds as it takes, keeping every version. Approval closes the ticket and
files the artwork on the customer's account.

The whole thing exists to stop two failures: **work done twice**, and **a request that quietly
disappears**.

---

## 2. The one rule that is not a permission

**The designer who uploaded a version cannot pass a verdict on it.**

Withholding `design_tickets.review` from the «مصمم» role is necessary and *not sufficient*. An
administrator holds every permission through `Gate::before` in `AppServiceProvider` — that is a
rule, not a granted row — so no roles screen could ever stop one person drawing a bag and signing
it off.

So the domain refuses it, in `ReviewDesignVersion`:

```php
if ((int) $version->uploaded_by_user_id === (int) $reviewer->getKey()) {
    throw DesignerCannotReviewOwnWork::make();
}
```

The precedent is exact: `PermissionName::ConfirmDepositReceipt` refuses the tick to whoever claimed
the payment, so at least two people must be involved before money is called received. Same shape,
same reason — a claim and its verification are not one person's job.

`DesignTicketResource` also reports `can_review: false` to the uploader, so the app never draws a
button the API would refuse.

---

## 3. The tables

### `design_tickets`

| Column | Notes |
|---|---|
| `code` | `DT-0001`, allocated in `booted()` |
| `customer_id` | required — a ticket is always *for* somebody |
| `customer_name` | **snapshot**, so a designer reads it without `customers.view` |
| `order_id` | nullable — a card is asked for before any order exists |
| `title`, `description`, `instructions` | the brief |
| `status` | the enum below; never written by a request |
| `requested_by_user_id` | who asked |
| `assigned_designer_id` | who it is **addressed to** — nullable, null = shared pool |
| `accepted_by_user_id`, `accepted_at` | who actually **took** it |
| `approved_customer_design_id` | what approval put on the customer's account |
| `cancellation_reason` | always present on a cancelled ticket |
| `completed_at` | |

**Two people, deliberately.** `assigned_designer_id` is the address; `accepted_by_user_id` is the
fact. Reassigning moves the first and never the second — «لا تضيع هوية المصمم الذي استلم الطلب» is
about the second.

`customer_name` being a snapshot is an **access-control feature**, not denormalisation for speed: a
designer holds no grant on `customers`, and a join would have forced one.

### `design_ticket_files`

One table for both halves of the conversation, keyed by `kind`:

- `brief` — the employee's reference files
- `submission` — the designer's versions, numbered `version` 1, 2, 3…

A submission also carries `status` (`proposed` | `approved` | `changes_requested`), `review_note`,
`reviewed_by_user_id`, `reviewed_at`. All null on a brief.

### `customer_designs` — three nullable columns

Additive only, so nothing that already writes to this table changed:
`design_ticket_id`, `design_ticket_file_id`, `source`.

---

## 4. The status enum

```
New ──accept──► InProgress ──submit──► UnderReview ──approve──► Completed
                    ▲                       │
                    └──submit── ChangesRequested ◄── request changes ──┘
```

Plus `Cancelled`, reachable from every open state, always with a reason.

**No endpoint sets a status.** Each is written by the action that earns it — `AcceptDesignTicket`,
`SubmitDesignVersion`, `ReviewDesignVersion`, `CancelDesignTicket`. `allowedNext()` is therefore
not a source of buttons but the map those actions refuse a move against; the app draws buttons from
the `can_*` flags instead.

The reason is that every one of these statuses is a claim about something a person did: somebody
took the job, somebody sent work, somebody judged it. A status a clerk could pick from a dropdown
would let a ticket say it was accepted with nobody's name against it.

`Completed` leads nowhere — approval writes artwork onto the customer's account, and undoing it
would mean deciding what happens to that row and to any order pointing at it. A customer who wants
a change after approval is asking for new work, which is a new ticket.

---

## 5. Permissions

| Permission | Arabic | Seeded to «مصمم» |
|---|---|---|
| `design_tickets.view` | عرض تذاكر التصميم الخاصة به | ✅ |
| `design_tickets.view_all` | عرض كل تذاكر التصميم | — |
| `design_tickets.manage` | إنشاء وتعديل طلبات التصميم | — |
| `design_tickets.assign` | إسناد تذاكر التصميم إلى المصممين | — |
| `design_tickets.accept` | قبول طلب التصميم | ✅ |
| `design_tickets.submit` | رفع تصميم داخل التذكرة | ✅ |
| `design_tickets.review` | الموافقة على التصميم أو طلب تعديل | — |

The «مصمم» role deliberately does **not** hold `review`, and holds no grant on `customers` — which
is why `customer_name` is a snapshot.

### Visibility is a scope, not a grant

Holding `design_tickets.view` says a reader may use this section; it does not say which tickets are
theirs. Without `view_all` a reader reaches:

- tickets they raised, **or**
- addressed to them, **or**
- accepted by them, **or**
- the unclaimed pool.

This is written **twice, deliberately** — and that is not duplication to remove:

- `FiltersDesignTickets` does it in SQL, because a page that fetched fifteen rows and dropped four
  would paginate short, and the reader would conclude the list had ended.
- `DesignTicket::isVisibleTo()` does it for a single binding, where the question is a 404 rather
  than a page.

**A colleague's ticket is a 404, never a 403.** «ليس لديك صلاحية» on a specific id confirms that
the ticket exists, which is the thing being withheld.

---

## 6. The seventeen routes

All under `/api/v1`, all requiring a Sanctum bearer token.

| Verb | Path | Permission |
|---|---|---|
| GET | `design-tickets/summary` | `.view` |
| GET | `design-tickets` | `.view` |
| POST | `design-tickets` | `.manage` |
| GET | `design-tickets/{ticket}` | `.view` |
| PUT | `design-tickets/{ticket}` | `.manage` |
| PATCH | `design-tickets/{ticket}/designer` | `.assign` |
| POST | `design-tickets/{ticket}/acceptance` | `.accept` |
| POST | `design-tickets/{ticket}/cancellation` | `.manage` |
| POST | `design-tickets/{ticket}/attachments` | `.manage` |
| DELETE | `design-tickets/{ticket}/attachments/{attachment}` | `.manage` |
| POST | `design-tickets/{ticket}/versions` | `.submit` |
| POST | `design-tickets/{ticket}/versions/{version}/review` | `.review` |
| GET·POST·PUT·DELETE | `design-tickets/{ticket}/comments` | `.view` |
| GET | `design-tickets/{ticket}/logs` | audit |

`summary` is declared **before** `{ticket}`, or the router reads the word as an id — the trap
already documented at `shortages/summary`.

`scopeBindings()` on the attachment and version routes means another ticket's file id is a 404 by
construction, rather than by a check somebody remembered to write.

### Why acceptance is a POST to a noun

`POST /design-tickets/{id}/acceptance`, not `PATCH` on the ticket. What is created is the
acceptance — a fact with a person and a time — and exactly one may ever exist. Cancellation follows
the same shape for the same reason.

---

## 7. Worked examples

### Raise a ticket

```http
POST /api/v1/design-tickets
Authorization: Bearer <token>
Content-Type: application/json

{
  "customer_id": 57,
  "title": "تصميم كيس شحن — أسود",
  "description": "ضع الشعار في المنتصف وأضف رقم الهاتف أسفله.",
  "instructions": "الخط عريض، والخلفية شفافة.",
  "assigned_designer_id": null
}
```

→ `201` · «تم إرسال طلب التصميم»

`assigned_designer_id: null` is the **shared pool** — a real answer, not a missing one. An employee
who does not know who is free leaves it empty, every designer is told, and the first to accept
claims it.

**Naming a designer without `.assign` is silently dropped, not refused.** The ticket is otherwise
entirely valid, and rejecting it would lose the employee's typing over a field they may not have
seen.

### The designer's queue, and the pool

```http
GET /api/v1/design-tickets?designer=me&status=in_progress&status=changes_requested
GET /api/v1/design-tickets?designer=none
```

`me` and `none` are words rather than ids: «me» is only knowable from the bearer token, and «none»
is a null a query string cannot otherwise carry.

### Accept it

```http
POST /api/v1/design-tickets/42/acceptance
```

→ `200`, status becomes `in_progress`.

The race is settled in PostgreSQL, not PHP:

```php
$claimed = DesignTicket::query()
    ->whereKey($ticket->getKey())
    ->whereNull('accepted_at')
    ->update([...]);
```

Exactly one of two simultaneous statements affects a row. The loser gets `422` naming the winner —
«تم قبول هذه التذكرة من أحمد» — so they know whom to talk to rather than just being told no.

### Upload a version

```http
POST /api/v1/design-tickets/42/versions
Content-Type: multipart/form-data

file: v1.png            (pdf, jpg, jpeg, png, webp · max 25 MB)
note: غيّرت الخط، قوليلي رأيك
```

→ `201`, status becomes `under_review`, `version` stamped.

The same endpoint sends the first version and every revision — a revision is a row, not a new
ticket. Accepted only from `in_progress` and `changes_requested`: a revision must not need a second
acceptance, or every round trip would cost an extra tap for nothing.

### The verdict

```http
POST /api/v1/design-tickets/42/versions/2/review

{ "verdict": "approved" }
```

```http
POST /api/v1/design-tickets/42/versions/2/review

{
  "verdict": "changes_requested",
  "note": "كبّر الشعار شوية وخلي الرقم أوضح"
}
```

`note` is **required** when the verdict is `changes_requested` — «تعديل مطلوب» with no instruction
is a rejection the designer cannot act on. `proposed` is not a verdict a reviewer may send; it is
the state a version arrives in.

### Route it, or return it to the pool

```http
PATCH /api/v1/design-tickets/42/designer
{ "assigned_designer_id": 9 }        # to a designer

PATCH /api/v1/design-tickets/42/designer
{ "assigned_designer_id": null }     # back to the shared pool
```

**`present`, not `required`** — that is what lets null mean something. Omitting the key entirely is
a `422`, because a half-built request must not quietly clear somebody's queue.

Assigning does **not** start the work. That claim is made by the designer accepting, not by a
supervisor routing — the whole reason the acceptance step exists.

### Who can do this job?

```http
GET /api/v1/users?permission=design_tickets.accept
```

Added on this branch so the designer picker lists designers. **By permission rather than by role
name**: a filter on «مصمم» would list the wrong people the day the business renames that role,
splits it, or grants the same work to a second one — silently. An unrecognised permission is
*ignored rather than refused*, because a typo that emptied the list would read as «لا يوجد موظفون»,
a sentence that is false and undiagnosable from the screen.

---

## 8. Approval — the action that closes the loop

`PromoteApprovedDesign` writes the approved file onto the customer's account as a `CustomerDesign`,
labelled from the ticket title, and links it back through `approved_customer_design_id`.

**Idempotent on checksum.** Approving a file already in the customer's library links the existing
row rather than storing the bytes twice — the same file arriving by two roads is one design.

---

## 9. Refusals

Every domain refusal is a **422** carrying an Arabic `message` written for the person reading it.
Show it; do not map it.

| Exception | Message |
|---|---|
| `DesignerCannotReviewOwnWork` | لا يمكن مراجعة تصميم رفعته بنفسك — الاعتماد من مسؤول آخر |
| `DesignTicketAlreadyAccepted` | تم قبول هذه التذكرة من {الاسم} |
| `DesignTicketBelongsToAnotherDesigner` | هذه التذكرة مُسنَدة إلى مصمم آخر |
| `DesignTicketNotAcceptedYet` | يجب قبول التذكرة قبل رفع تصميم |
| `DesignTicketIsClosed` | لا يمكن تنفيذ هذا الإجراء: التذكرة {الحالة} |
| `DesignVersionAlreadyReviewed` | النسخة رقم {n} تمت مراجعتها مسبقاً: {الحالة} |
| `DesignReviewRequiresNote` | اكتب ما المطلوب تعديله |
| `DesignTicketCancellationRequiresReason` | اكتب سبب إلغاء التذكرة |
| `NoVersionToReview` | لا يوجد تصميم بانتظار المراجعة في هذه التذكرة |
| `DesignTicketOrderBelongsToAnotherCustomer` | الطلبية رقم {n} لا تخصّ العميل رقم {n} |
| `DesignTicketTransitionNotAllowed` | لا يمكن نقل التذكرة من «{من}» إلى «{إلى}» |

Validation failures are `422` with `errors` keyed by field. Anything the reader may not see is a
`404`.

---

## 10. The media layer this work paid for

`Support/Media/` — extracted here and now the **one place** a user file is written to a disk:

- `StoreUploadedFile` — sniffs the mime from the bytes rather than trusting the filename,
  checksums before the move, generates a UUID filename
- `StoredFile` — a readonly DTO of what landed
- `HasStoredFile` — `storage()` and `url()`, signed and expiring where the disk supports it

`UploadProductImage`, `UploadCustomerDesign` and `StorePaymentReceipt` were converted onto it, and
`ProductImage` and `CustomerDesign` onto the trait. Behaviour unchanged; four copies of the same
upload logic became one.

---

## 11. Fixed after the first build: returning a ticket to the pool

The shared pool is defined by **two** columns:

```php
$query->whereNull('assigned_designer_id')->whereNull('accepted_at');
```

`AssignDesignTicket` originally cleared only the first. A ticket released *after* a designer had
accepted it therefore satisfied neither "assigned to someone" nor "in the pool" — it fell between
them.

Because the same predicate governs visibility, the consequence was worse than an empty queue:

| Who | Saw the released ticket |
|---|---|
| Every other designer | ❌ invisible entirely |
| The original designer | ✅ via `accepted_by_user_id` — the one person meant to stop |
| Supervisor with `view_all` | ✅ |

…while the status still read «قيد التصميم», counting it as work in hand. A lost ticket — the exact
failure this feature exists to prevent.

`AssignDesignTicket` now releases the whole claim when the designer is null **and** the ticket was
accepted: `accepted_at`, `accepted_by_user_id`, and the status back to «جديد». Uploaded versions
stay — the next designer needs them so they do not start the job twice.

**Reassigning to another designer is unchanged.** Naming somebody is not taking the job off the
person doing it; only a return to the pool releases.

This overturned an earlier decision that `accepted_by_user_id` was "a record of what happened" and
must survive. That record is real, but it belongs to the **audit trail**, which already holds the
acceptance and the release with their causers and times. These columns describe where the ticket
stands *now*; keeping a stale claim in them to preserve history duplicated the log and broke the
queue.

It also makes `AssignDesignTicket` the one thing that moves a ticket back to «جديد», against the
rule `allowedNext()` states. That exception is deliberate and documented at the enum: a release is
something a person did, under their own name, so the count going up is caused rather than
spontaneous. «جديد» stays out of the map because the map is published as `available_transitions`,
and it must never be a move the app can offer.

---

## 12. Tests

`tests/Feature/DesignTickets/` — **39 tests, 193 assertions.**

| File | Covers |
|---|---|
| `DesignTicketFlowTest` | the whole road new → completed, two revision rounds, cancellation, closure, storage |
| `DesignTicketAcceptanceTest` | the race, addressed-to-another, assign-does-not-start, release to pool |
| `DesignTicketReviewTest` | the own-work refusal, note required, judged once, briefs not reviewable |
| `DesignTicketAccessTest` | the 404s, the pool, `view_all`, customer name without a grant, the picker filter |
| `DesignTicketHistoryTest` | audit across ticket + files + comments, the conversation, counts matching the list |

**The two roles are built from permissions rather than from the seeded role.** A test that asked
for «مصمم» would be asserting that `RoleSeeder` is correct, which is a different claim — and the
seeder is explicitly "a starting point, not a policy" the business may reshape. What the endpoints
charge is grants, so that is what the tests hand out.

Real personal access tokens rather than `Sanctum::actingAs()`, which produces a `TransientToken` and
skips the path the app actually uses.

---

*A living document. When a rule here proves wrong, change it and record why.*
