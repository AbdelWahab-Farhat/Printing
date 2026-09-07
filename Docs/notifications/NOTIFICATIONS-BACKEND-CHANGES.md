# Notifications — backend changes

> **Phase 1 built.** The spine, both channels, all seven endpoints, announcements, the retention
> prune and `order.shortage` end to end are implemented and tested on the `add_notifications`
> branch. Phase 2 — the rest of the catalogue in §8 — is not.
> **Backend only** — nothing in `frontend/` was touched. The app side is a separate job,
> specified in [NOTIFICATIONS-FRONTEND-INTEGRATION.md](NOTIFICATIONS-FRONTEND-INTEGRATION.md).
>
> **One thing changed during the build**: `google/auth` could not be installed, so the OAuth
> assertion is signed in-house. §9 records why.
>
> 🚀 **Deploying this? Start at [§15](#15-deployment-checklist).** Every item on that list fails
> *silently* — no error, no log line, every screen still working — so it is a checklist rather
> than a paragraph.
>
> Chosen transport: **in-app notification centre + FCM push**, Android **and iOS**. Websockets
> (Reverb) were considered and rejected; outbound customer messaging (SMS/WhatsApp) is explicitly
> out of scope — see §2.
>
> Resolves two deferred items in [BACKLOG.md](../BACKLOG.md): «إشعار العميل عند تغيّر الحالة»
> (the staff half only) and «ذكر زميل في ملاحظة، وإشعاره» (unblocks it entirely).

---

## 1. Why

There is no notification system in this project at all. `Notifiable` sits on
[User](../../backend/app/Domain/Identity/Models/User.php) unused, there is no `notifications`
table, no device tokens and no send channel. The app's settings screen already carries a
«تفعيل الإشعارات» switch that writes a preference nothing reads — the docblock on
`SetNotificationsEnabled` says so plainly, and predicts this change.

Meanwhile the events worth telling somebody about already happen and are already announced:
[`Order/Events/`](../../backend/app/Domain/Order/Events/) plus the `Event::listen` lines in
[AppServiceProvider](../../backend/app/Providers/AppServiceProvider.php). The gap is not
detection. It is that nothing turns a domain event into something a person sees.

**The design goal that shapes every decision below: adding the *next* notification must cost one
enum case, one small class and one listener line — no migration, no endpoint, and no Flutter
release.** Anything that breaks that property has moved the work rather than done it.

---

## 2. Scope

**In**

- A `Notification` domain context, with a pluggable channel and a pluggable audience.
- Two channels: **database** (the in-app centre) and **FCM push** (Android + iOS).
- Four endpoints for the centre, two for device registration, one for announcements.
- One notification definition end to end in phase 1; the proposed catalogue in phase 2 (§8).
- **Manual announcements** («اجتماع الساعة ٤») — a person writes a message and sends it to every
  employee, behind a new **grantable** `notifications.broadcast` permission. §8.1.

**Out, deliberately**

- **Customer-facing messages.** A customer has no account — [BACKLOG.md](../BACKLOG.md)'s
  «إشعار العميل عند تغيّر الحالة» is outbound SMS/WhatsApp through a paid gateway, with opt-out
  handling and a per-message cost. Different problem, different contract. It feeds off the same
  events when it comes, which is part of why this is worth building first.
- **Investor notifications.** Deferred — see §5.3 for the seam that keeps them cheap, and why the
  audience abstraction must exist *now* even though it goes unused.
- **Websockets.** Reverb needs a persistent daemon the cPanel host fights, and it still would not
  wake a closed app, so it does not replace push. [RULES.md §2](../../backend/RULES.md) already
  lists it as adopt-only-on-a-real-requirement.
- **Laravel's built-in `notifications` table / `DatabaseNotification`.** Rejected: its `data`
  column is an untyped JSON blob, colliding with RULES §3 ("DTOs at boundaries", "Resources shape
  every response", "no magic strings"), and it has no audience concept at all — every call site
  would still hand-write who receives it, which is precisely the part that has to scale.

---

## 3. Database

Three new tables. Forward-only, each with a real `down()`.

### `notifications` — the event, one row per occurrence

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `type` | string(64), indexed | a `NotificationType` value — `order.shortage`, `stock.low` |
| `subject_type` | string, nullable | morph **alias** from [AuditSubject](../../backend/app/Domain/Audit/Enums/AuditSubject.php), never a class name |
| `subject_id` | bigint, nullable | |
| `payload` | `jsonb` | the frozen snapshot the sentence is rendered from — §4.2 |
| `dedupe_key` | string(128), nullable, indexed | storm control — §4.4 |
| `causer_id` | FK → `users`, nullable, `nullOnDelete` | who caused it; excluded from their own notification |
| `created_at` | timestamp, indexed | **no `updated_at`** — a notification is immutable |

### `notification_recipients` — fan-out, one row per person

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `notification_id` | FK → `notifications`, `cascadeOnDelete` | |
| `user_id` | FK → `users`, `cascadeOnDelete` | |
| `read_at` | timestamp, nullable | |
| | unique `(notification_id, user_id)` | a person is notified once |
| | index `(user_id, read_at)` | the unread count is one indexed scan |

**Fan-out on write, not on read.** One row per recipient makes per-user read state trivial and
`unread-count` a single indexed `COUNT`. At this business's headcount — tens of staff — the row
multiplication is irrelevant. Fan-out on read would make the unread badge, the most-called
endpoint in the whole feature, the most expensive query in it.

### `device_tokens` — where a push goes

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `user_id` | FK → `users`, `cascadeOnDelete` | |
| `token` | string(255), **unique** | the FCM registration token |
| `platform` | string(16) | `android` · `ios` · `web` |
| `last_used_at` | timestamp, nullable | |
| `timestamps` | | |

Two deliberate departures, both recorded here because they will look like mistakes later:

- **Hard delete, not soft** — the one table in this schema that does not follow
  [RULES.md §10](../../backend/RULES.md). When FCM answers `UNREGISTERED` the token is dead;
  keeping the row to push at forever is not an audit trail, it is a leak. §12 covers the test
  this affects.
- **`token` is unique table-wide, not per user.** A phone handed from one employee to another
  re-registers the same FCM token under a new `user_id`, and the registration endpoint
  **reassigns** the row rather than inserting a second one — otherwise the previous holder keeps
  receiving the new holder's notifications on a device they no longer have.

---

## 4. The domain layer

```
app/Domain/Notification/
├── Models/
│   ├── Notification.php
│   ├── NotificationRecipient.php
│   └── DeviceToken.php
├── Enums/
│   ├── NotificationType.php          the catalogue — one case per kind
│   └── DevicePlatform.php
├── Contracts/
│   ├── NotificationDefinition.php    what a kind must declare
│   └── NotificationChannel.php       deliver(Notification, User): void
├── Definitions/                      ← THE EXTENSION POINT, one file per kind
│   ├── OrderReachedShortage.php
│   └── ...
├── Channels/
│   ├── DatabaseChannel.php
│   └── PushChannel.php
├── Audience/
│   ├── NotificationAudience.php      value object with named constructors — §5
│   └── ResolveRecipients.php
├── Actions/
│   ├── PublishNotification.php
│   ├── MarkAsRead.php
│   ├── MarkAllAsRead.php
│   ├── RegisterDeviceToken.php
│   └── ReleaseDeviceToken.php
├── Queries/
│   ├── NotificationFilters.php
│   └── NotificationListQuery.php
├── Listeners/                        one thin queued listener per domain event
├── Jobs/
│   └── DeliverPushNotification.php
├── Support/
│   └── FcmClient.php                 every HTTP call to FCM, and nothing else
├── Exceptions/
└── NotificationService.php           the module's only public door
```

### 4.1 Dependency direction

**Notification listens; nothing listens to Notification.** It may read `Order`, `Inventory` and
`PurchaseOrder` through their Services to build a payload; none of them import it. Same
arrangement as "Orders announces, Investment listens", already documented in
[AppServiceProvider](../../backend/app/Providers/AppServiceProvider.php) — one listener line per
kind, nothing more.

### 4.2 Render at read, from a frozen payload

A definition declares the payload it freezes (`order_id`, `order_code`, `stock_item_name`,
`shortfall`) and renders the Arabic sentence from it. The sentence is produced by
`NotificationResource` at read time and **is not stored**.

Three things this buys, all of which storing the rendered text loses:

- An Arabic typo is one deploy, not a permanently wrong row sitting in everyone's mailbox.
- The list needs no joins and survives a soft-deleted order — the payload is a snapshot, not a
  pointer.
- A second language later is a code change, not a migration.

### 4.3 Publishing is queued, and dispatched after commit

**This is the rule most likely to be got wrong, because the neighbouring listeners teach the
opposite.** `PostEarningsWhenOrderIsFinalised` is *deliberately synchronous inside the
transaction* — it moves money, so the status and the money land together or not at all, and its
docblock says exactly that.

Notifications are the inverse. **Every notification listener is `ShouldQueue` and dispatched
after commit.** A failed FCM call must never roll back an order status change, and a notification
about a transaction that later rolled back must never have been sent at all. Put this in the
docblock of the first listener, or the next person copies the wrong neighbour.

### 4.4 Storm control

`dedupe_key` plus a "not again within N hours" rule on publish. And the definitions themselves
notify on a **crossing**, not a state: `stock.low` fires when a balance moves from above its
threshold to at-or-below it, never on every movement while it sits there.

The same discipline rules out a per-order `investor.profit` (§8) that would buzz an active
investor several times a day. **A bell everybody learns to ignore has cost more than it
delivered** — that is the failure mode this section exists to prevent.

---

## 5. Audience — the part that makes this scale

`PublishNotification` never receives a list of users. It receives an **audience**, and
`ResolveRecipients` turns that into users.

### 5.1 By permission — the ordinary case

```php
public function audience(Notification $n): NotificationAudience
{
    return NotificationAudience::permission(PermissionName::ViewOrders);
}
```

Resolved through `spatie/laravel-permission`. **You never maintain a "who gets what" list** — you
reuse the catalogue in
[PermissionName](../../backend/app/Domain/Identity/Enums/PermissionName.php) that the roles screen
already curates. A role created next year receives the right notifications the day it exists,
with no code change. This is the single highest-leverage decision in the document.

**The causer is excluded by default.** Somebody who just changed a status does not need to be told
they changed it. Without this rule every action notifies its own author and the bell becomes an
echo. A definition can opt back in where the confirmation genuinely matters.

### 5.2 By user, or by role — the directed cases

`NotificationAudience::user($userId)`. What @mentions will use when
[BACKLOG.md](../BACKLOG.md)'s «ذكر زميل في ملاحظة» is picked up: a `mentions` join table plus one
definition, and nothing else.

`NotificationAudience::role($roleId)` and `::everyone()` — what announcements use (§8.1). Roles
are administrator-created data, so a new role is a new possible audience with no code change.

### 5.3 The variant that is specified but not built

`NotificationAudience::investorFor($dealId)` is **reserved in phase 1 and implemented later.**
Two reasons it must be anticipated rather than discovered:

- **It is the one audience that must not be a permission.** `investor_portal.view` is granted to
  the «مستثمر» role, so resolving it by permission would send every investor's money notification
  to every other investor — and to every administrator, since `Gate::before` passes them
  unconditionally. It resolves through `investors.user_id`, exactly as the portal's own docblock
  requires: *"there is no id in any path here, and that is the security."*
- If phase 1 types the audience as `PermissionName` — the tempting simplification, since every
  launch notification is permission-based — then adding investors later changes the signature of
  `PublishNotification`, every definition, and every test.

**So `NotificationAudience` ships as a value object with named constructors — `permission`,
`user`, `role`, `everyone`, and `investorFor` reserved but unimplemented.** Roughly forty lines,
and the difference between "add a class" and "reshape the core".

Worth knowing when that phase arrives: `investors.user_id` is **nullable** — the model docblock
says *"most investors will never sign in"* — so investor notifications will always reach a
minority. That is fine (no row is written for the rest), but it is a convenience, never a channel
the business can rely on.

---

## 6. Channels

`NotificationChannel` is an interface; `PublishNotification` fans out to every channel a
definition asks for.

### 6.1 `DatabaseChannel`

Always on, and cannot be disabled. The in-app centre is the record; push is a courtesy on top of
it. A user who has push switched off still has a complete mailbox when they open the app.

### 6.2 `PushChannel` → FCM HTTP v1

Queued via `DeliverPushNotification`, one job per recipient.

- **FCM HTTP v1** — `POST https://fcm.googleapis.com/v1/projects/{project}/messages:send`, OAuth2
  bearer from a service account. **The legacy server key is retired and must not be used.**
- **`FcmClient` mirrors
  [`NawrisClient`](../../backend/app/Domain/Carrier/Support/NawrisClient.php) deliberately** — one
  class that is the only file knowing FCM's shapes, config injected as one array through a
  three-line binding in `AppServiceProvider` (so a test can hand it a different base URL or a
  dry-run flag without touching global state), its own log channel, and secrets never logged.
  That file is the template; follow it rather than inventing a second style for the same job.
- **No `try`/`catch`** — RULES §5. `Http::throw()` converts a transport failure; a logical
  rejection is raised by reading the body. New domain exceptions: `FcmIsNotConfigured`,
  `FcmRejectedRequest`.
- **`FCM_DRY_RUN`**, copied from `NAWRIS_DRY_RUN`: build the payload, log it, send nothing. The
  cheapest possible verification before the first live push.
- **Dead tokens are pruned on the spot.** `UNREGISTERED` or `INVALID_ARGUMENT` deletes the
  `device_tokens` row and the job **succeeds** — it is not a failure to retry. Anything else
  throws and the queue retries with backoff.

### 6.3 The message shape — both platforms

iOS is shipping, so the message carries platform override blocks. This is the whole of iOS's
backend cost:

```jsonc
{
  "message": {
    "token": "…",
    "notification": { "title": "…", "body": "…" },   // required — see below
    "data":  { "notification_id": "412", "route": "/orders/145" },
    "android": { "priority": "high", "notification": { "channel_id": "dayaa_default" } },
    "apns": {
      "headers": { "apns-priority": "10" },
      "payload": { "aps": { "sound": "default", "badge": 3 } }
    }
  }
}
```

- **The `notification` block is mandatory, not optional.** A data-only message will not display
  on iOS while the app is backgrounded or terminated without a Notification Service Extension.
  Android would tolerate data-only; iOS does not, so both get the same shape.
- **`aps.badge` carries that recipient's unread count**, which costs one indexed `COUNT` per job
  (the `(user_id, read_at)` index above exists partly for this). Worth it: an iOS app icon
  showing a stale badge is a bug users report, and the alternative is the app maintaining a
  count it cannot know while it is not running.
- **`android.notification.channel_id`** must match the channel the app creates — see the frontend
  doc. A mismatch means Android 8+ silently drops the notification.

### 6.4 What a push may contain

**A push is readable on a locked screen by whoever is holding the phone.** So it carries a safe
title, the `notification_id` and the `route` — and **never** an amount, a customer name, a phone
number or a profit figure. The app fetches detail through the authenticated endpoint after the
tap.

This is a rule about the *push*, not the notification: the in-app centre may say «ربح ٤٥٠ د.ل»
because reaching it required a login.

---

## 7. API

All under `auth:sanctum` in the existing `v1` group. **Reading is behind no permission at all** —
every account reads its own mail. The one exception is sending an announcement, which is a power
over other people's phones rather than a view of your own (§8.1).

| Method | Path | |
|---|---|---|
| `GET` | `/notifications` | paginated, newest first, `?unread=true` |
| `GET` | `/notifications/unread-count` | `{ "count": 3 }` |
| `POST` | `/notifications/{notification}/read` | |
| `POST` | `/notifications/read-all` | |
| `POST` | `/notifications/devices` | register an FCM token — `{ token, platform }` |
| `DELETE` | `/notifications/devices` | release it, on logout — `{ token }` |
| `POST` | `/notifications/announcements` | send an announcement — **`can:notifications.broadcast`** plus `throttle`, the only guarded route here — §8.1 |

**Ownership is resolved from the token, never from the path.** `{notification}` is scoped to the
signed-in user's recipient rows, and another person's id returns **404, not 403** — the same
instinct as `investor-portal` carrying no id at all. RULES §6's ownership case is a required test
here, not an optional one.

`NotificationResource`:

```jsonc
{
  "id": 412,
  "type": "order.shortage",
  "title": "طلبية O145 في النواقص",
  "body": "كيس شحن 25*35 — ناقص 200",
  "icon": "warning",           // small stable vocabulary; the app has a fallback
  "route": "/orders/145",      // deep link, pushed through the app's existing guards
                               // NULLABLE — an announcement has nothing to open
  "is_read": false,
  "created_at": "2026-09-07T09:14:22+02:00"
}
```

**`title`, `body`, `icon` and `route` are all server-rendered, and that is what keeps the app out
of the loop.** A new notification type appears in an already-shipped build with no release. If
the app ever has to `switch` on `type` to know what to draw, this property is gone and §1's design
goal with it.

**`DELETE /notifications/devices` must be called on logout**, or the phone keeps receiving the
previous user's notifications. The frontend doc makes this a hard requirement of the logout path,
not a courtesy.

---

## 8. The catalogue

**Phase 1 ships exactly one, end to end**, to prove the spine: **`order.shortage` — confirmed.**
«نواقص» is the status that most needs a human to act on, and the moment already exists inside
[`ChangeOrderStatus`](../../backend/app/Domain/Order/Actions/ChangeOrderStatus.php).

**Phase 2 — confirmed.** One small PR each, no schema change:

| `type` | Trigger | Audience | Route |
|---|---|---|---|
| `order.shortage` | `ChangeOrderStatus` → Shortage | `orders.view` | `/orders/{id}` |
| `order.status_changed` | `ChangeOrderStatus` | `orders.view` | `/orders/{id}` |
| `stock.low` | balance **crosses** `low_stock_threshold` | `inventory.view` | `/stock-items/{id}` |
| `purchase_order.received_short` | arrival received with a shortfall | `purchase_orders.view` | `/purchase-orders/{id}` |
| `order.payment_recorded` | payment recorded | `orders.view` | `/orders/{id}` |
| `investor.profit_released` | **later phase** — §5.3 | `investorFor(deal)` | `/investor` |

> Confirmed as the phase-2 set. Should any of them turn out to be noise once staff live with it,
> **removing one is deleting a definition and a listener line** — no migration, no client
> release. That reversibility is the reason the list could be agreed before anyone had used it.

### 8.1 Manual announcements — the one notification a person writes

`POST /notifications/announcements`, guarded by `can:notifications.broadcast`.

### A permission, not a Gate — chosen deliberately, for delegation

"Administrators only" has two spellings in this codebase and they mean different things. A `Gate`
(the `users.create` / `users.password` pattern) makes a power **ungrantable** — it never appears
on the roles screen and nothing can tick it onto a role. A **`PermissionName` case** makes it
grantable, and administrators-only is then simply the state of the grants rather than a rule in
the code.

**This one is a permission**, because the business expects to delegate it — a floor manager
announcing a shift change should not require a code change:

```php
// Sending a message to every employee's phone at once. Its own permission rather than part of
// any other: it is not a view of anything, it is a power over other people's attention, and the
// person who edits products is not automatically the person who may interrupt the whole shop.
//
// A permission rather than a Gate — unlike `users.create` — because this is meant to be
// delegated. Today no role holds it, so it is administrators-only through Gate::before alone
// (see below); the day it should be a floor manager's, that is one tick box and no deploy.
case BroadcastNotifications = 'notifications.broadcast';
```

Add it to `label()` («إرسال إشعار عام لكل الموظفين») and to the group map, under a new
«الإشعارات» group, so it appears on the roles screen like every other permission.

### Administrators-only on day one needs no code and no grant

**Nothing is seeded, and no role is given this permission.** Administrators already pass every
ability unconditionally through
[`Gate::before`](../../backend/app/Providers/AppServiceProvider.php), so with the permission held
by nobody, the endpoint is administrators-only by construction — not by a rule that has to be
written, tested and later removed.

Delegating it later is then **one tick on the roles screen, with no deploy at all** — which is
strictly better than the Gate's "one deliberate edit", and is the reason for choosing this side
of the trade.

> **The risk this accepts, recorded so it is a decision and not an accident:** a permission is a
> checkbox, and a checkbox can be ticked onto «محاسب» by whoever administers roles. That is the
> cost of delegability, and it is the intended trade here. The mitigations are that the roles
> screen shows the label above (which says plainly that it reaches *every* employee), that every
> grant is written to the audit trail by
> [RecordRolePermissionChange](../../backend/app/Domain/Identity/Actions/RecordRolePermissionChange.php),
> and that each send is itself audited (below) and rate limited.

Request:

```jsonc
{
  "title": "اجتماع",
  "body":  "اجتماع الساعة ٤ في المكتب",
  "audience": { "kind": "role", "role_id": 3 }   // or { "kind": "everyone" }
}
```

Audience is **`everyone`** (every active, non-investor account) **or a role** — roles are
administrator-created data, so this needs no code change as the business grows. It reuses
`NotificationAudience` with one added constructor, `role($id)`; it does **not** get a bespoke
path.

Four things make this different from every other notification, and all four are deliberate:

- **The text is authored, not rendered.** This is the single exception to §4.2: `title` and `body`
  are stored in the payload as typed and echoed back verbatim. There is no definition to render
  from, because a human already wrote the sentence. Every *other* type keeps the frozen-payload
  rule, and this one must not become a precedent for storing rendered text.
- **`route` is `null`.** There is nothing to open. The app must handle a null route as "tap does
  nothing" — §3 of the frontend doc — and this is the case that proves it.
- **It is audited by hand.** A notification is a system consequence and is excluded from the audit
  trail (§12); an announcement is a **deliberate human act performed under someone's name**, and
  «من أرسل هذا؟» is a question that will be asked. It gets an `ActivityLog` row written
  explicitly, the same way
  [RecordRolePermissionChange](../../backend/app/Domain/Identity/Actions/RecordRolePermissionChange.php)
  covers a pivot that has no model. `causer_id` on the row is not enough on its own, because
  notifications are pruned (§10) and the audit trail is not.
- **It is rate limited.** This is the one endpoint in the application that can put a message on
  every phone in the company, so it carries a `throttle` middleware. Not a hypothetical: a
  double-tapped send button is the ordinary way this goes wrong.

Storm control (§4.4) does **not** apply — two identical announcements ten minutes apart are two
deliberate acts, and silently swallowing the second would be a bug.

### 8.2 New domain events

Three do not exist yet and are added in their **owning** context, following the shape of
`Order/Events/`:

- `OrderStatusChanged` (Order) — the moment exists in `ChangeOrderStatus`; only the announcement
  is missing.
- `StockFellBelowThreshold` (Inventory) — must carry *crossed*, not *is below*, or §4.4 is lost.
- `PurchaseOrderReceivedShort` (PurchaseOrder).

---

## 9. Config, dependencies, environment

**No new composer dependency — and not by choice.**

The plan called for `google/auth`. **It cannot be installed.** Composer's `block-insecure` audit
refuses to resolve `league/commonmark`, which `laravel/framework` requires, so *nothing* can be
added to this project as it stands:

```
laravel/framework v13.23.0 requires league/commonmark ^2.8.1
 -> found league/commonmark[2.8.1, ..., 2.10.0] but these were not loaded,
    because they are affected by security advisories.
```

`--no-audit` does not lift it; only listing ten advisory IDs under `audit.ignore`, or setting
`block-insecure: false`, would — and neither is a change to make in passing for a convenience
library. **This is pre-existing and unrelated to notifications**: `league/commonmark 2.8.3` is
already installed and locked, so the project already carries whatever exposure exists. It is
worth dealing with on its own terms, because until it is, **no dependency in this project can be
added or updated.**

So `GoogleServiceAccountToken` signs the assertion itself — about forty lines using
`ext-openssl`, which the framework already requires, so nothing changes about deployment.

**We only ever *sign*, never *verify***, and that is what makes this reasonable rather than
reckless: JWT's dangerous ground is verification — `alg: none`, algorithm confusion,
non-constant-time comparison — and none of it is on this path. The algorithm is fixed at RS256,
the key is ours, and Google validates the result. The send stays a plain `Http::post()` inside
`FcmClient`, so the NawrisClient pattern holds either way.

If the advisory block is cleared later, swapping `google/auth` back in is one class and no change
anywhere else. RULES §2 requires every dependency to be a justified decision; this is the
justification for having none.

`config/services.php` gains an `fcm` block in the house style. Nothing has a working default: an
unset key raises `FcmIsNotConfigured` before any HTTP call, rather than sending an empty string
and relaying whatever Google says about it.

```php
'fcm' => [
    'project_id'      => env('FCM_PROJECT_ID'),
    'credentials'     => env('FCM_CREDENTIALS_PATH'),   // path to the service account JSON
    'connect_timeout' => (int) env('FCM_CONNECT_TIMEOUT', 5),
    'timeout'         => (int) env('FCM_TIMEOUT', 15),
    'log_channel'     => env('FCM_LOG_CHANNEL', 'fcm'),
    'dry_run'         => (bool) env('FCM_DRY_RUN', false),
],
```

Every key goes into `.env.example` (RULES §9.7). **The service account JSON is a secret and is
never committed** — it is copied to each box out of band, exactly like `.env` and the customer
book, and the [README](../../README.md)'s "three things do not travel with a deploy" list gains a
fourth.

### Prerequisites outside this repository

| | |
|---|---|
| **Two Firebase projects** | `dev` and `production`, separate. See below — this is not optional. |
| Service account JSON | one per project, downloaded from Firebase, placed on each box, path in `.env` |
| **APNs auth key (`.p8`)** | **required for iOS push — not available yet.** See below. |
| Android package name / iOS bundle id | registered in both Firebase projects |

**Two Firebase projects, not one.** A project owns the device-token registry, and a token minted
under one is meaningless to the other. Sharing a single project means a push fired from a
developer's laptop reaches whatever real device is registered — the shop's counter phone
included — and there is no environment flag that prevents it, because the token does not know
which machine is calling. Two projects make that structurally impossible rather than a thing to
remember, the same instinct as `NAWRIS_DRY_RUN`. They are free at this volume.

### iOS push is deferred by dependency, not by design

**The APNs key does not exist yet and will be added in production later.** Nothing reaches an
iPhone until a `.p8` key from a *paid* Apple Developer account is uploaded to Firebase.

**This changes no backend code.** FCM abstracts both platforms, the `apns` block in §6.3 ships
from day one, and it is inert until the key exists — so there is no "iOS phase" to come back and
build here. The consequences are:

- **Android push works first**, on whatever timetable the key takes.
- **The in-app centre works on both platforms immediately**, since it is a plain authenticated
  endpoint and owes FCM nothing. An iPhone user has a complete, working mailbox the whole time —
  they simply are not woken by it.
- The app-side work is unaffected too, but it cannot be *tested* on iOS until the key lands. The
  frontend doc records this.

**It is the longest lead item in the plan**, because it depends on an Apple Developer membership
and on whoever holds that account rather than on any work in this repository. Worth starting well
before the code needs it.

---

## 10. Operational requirements

Three of these are outside the codebase, and skipping any of them fails **silently**.

1. **A queue worker must actually be running — ⚠️ UNVERIFIED, and nobody on the development side
   has production access to check.**

   `QUEUE_CONNECTION=database` and the existing `ProcessNawrisWebhook` imply a worker exists, but
   this has **not been confirmed on any deployed box**, and it is written here rather than left
   as an assumption precisely because the person who can check is not the person who wrote this.

   **Whoever deploys this must verify it before the feature is announced to staff.** Every push
   is a queued job: with no worker, notifications never arrive, and *nothing anywhere says so* —
   no error, no log line, no failed request. The rows simply sit in `jobs` forever while the app
   looks perfectly healthy. This is the same class of silent failure as the missing
   `storage:link` and the stale route cache the [README](../../README.md) already documents, and
   it is the single most likely reason for this feature to appear broken on launch day.

   ```bash
   # On the server — is anything consuming the queue?
   ps aux | grep 'queue:work'

   # And is the table draining, or growing?
   php artisan queue:monitor default
   ```

   If no worker runs, one must be supervised (systemd, Supervisor, or a cPanel cron running
   `queue:work --stop-when-empty` on a short interval). **Do not treat "the Nawris webhook seems
   to work" as proof** — that job is dispatched rarely enough that a worker restarted by hand
   months ago would look identical to one running under supervision.
2. **The scheduler is not registered at all.** There is no `withSchedule` in
   [bootstrap/app.php](../../backend/bootstrap/app.php), so no cron entry exists on any box.
   Retention pruning needs both the registration and the cron.
3. **`bin/rebuild-caches` on deploy.** New routes plus new config keys is precisely the situation
   the README documents as failing silently — a live controller answering 404 because the cached
   route table predates the route.

**Retention:** read notifications pruned after **90 days**, unread after **1 year**. A console
command plus a scheduled entry. (Assumption, not a stated requirement — one line to change.)

### The queue is not only about push — know which half fails without it

The obvious reading of "push needs a worker" is wrong in an important way, so it is written out:

| | Needs a running worker? |
|---|---|
| `order.shortage`, and every future event-driven type | **Yes — entirely.** No worker, **no notification at all**, not even the in-app row. |
| An announcement's in-app rows | **No.** `SendAnnouncement` runs inside the HTTP request. |
| An announcement's push | Yes |

The asymmetry is a consequence of §4.3: the event-driven listeners are `ShouldQueue` so they
cannot roll back the order they are about, which means the *whole* notification — mailbox
included — happens on the queue. So a stalled worker does not degrade the centre to
"in-app only"; for automatic notifications it silently switches the feature off, while every
screen keeps working and nothing is logged.

**Announcements are the exception worth remembering during an incident**: if staff report that
announcements arrive but shortages never do, that is this, and the worker is the first thing to
check.

### The prune runs on UTC

`config/app.php` sets `'timezone' => 'UTC'` and no `APP_TIMEZONE` is set, so `dailyAt('03:30')`
is 03:30 UTC — **05:30 in Libya**. Still off-hours, but it does not mean what it reads as, and
anybody moving the window should move it in UTC.

### Its own log channel

`FCM_LOG_CHANNEL=fcm` writes `storage/logs/fcm.log` (daily, 14 days), added to
`config/logging.php` beside the carrier's. When a notification does not arrive on somebody's
phone the first question is always «did we even try?», and that should not have to be dug out of
the application log. The service account key never reaches it — only the message built and the
status returned. Leave the variable blank to log nothing.

---

## 11. Security, privacy and scale

The trades this feature makes deliberately. None is a defect; all four are worth knowing before
somebody discovers them the hard way.

### An announcement's text is printed on every lock screen, verbatim

§6.4 keeps *automatic* notifications clean — the shortage push carries an order code and no
customer name, and a test asserts it. **An announcement is the one that cannot be scrubbed**,
because a human wrote the sentence and echoing it back is the whole feature (§8.1).

So whoever holds `notifications.broadcast` can put arbitrary text on the lock screen of every
employee's phone, where it is readable without unlocking. That is inherent, not fixable, and it
is the strongest argument for keeping the permission ungranted by default. **Say it out loud to
whoever is given it**, rather than leaving them to find out.

### A leaked device token is a quiet denial of service

`token` is unique table-wide and registering an existing one **moves** it to the caller
(§3, `RegisterDeviceToken`). That is required: a counter phone passed between employees must stop
delivering the previous holder's notifications.

The cost: anyone who learns a colleague's FCM registration token can register it to their own
account, and the colleague silently stops receiving push. **No data leaks** — the victim's device
would show the attacker's notifications, not the other way round — but the victim's push is off
and nothing tells them.

Accepted because an FCM token is not casually obtainable and the blast radius is one person's
push, with the in-app centre unaffected. If it ever matters, the fix is to refuse a token already
registered to a different account and require an explicit release first.

### The service account JSON is a private key on disk

A fourth item for the README's «three things do not travel with a deploy»: it is copied to each
box out of band like `.env`, must never enter git, and its file permissions matter as much as
`.env`'s. Nothing logs it — see `GoogleServiceAccountToken`.

### Announcement fan-out is synchronous in the request

`SendAnnouncement` resolves the audience, writes every recipient row and dispatches every push
job **inside the HTTP request**. At this business's headcount that is a fast query and a handful
of jobs. At several hundred employees it becomes a slow request that should move to a job of its
own — the seam is already there, since `PublishNotification` does not care who calls it.

The iOS badge also costs one indexed `COUNT` per device per notification (§6.3), for the same
reason: the app cannot count while it is not running.

---

## 12. Conventions this change touches

- **`ModelConventionsTest` will fail the build** unless `Notification`, `NotificationRecipient`
  and `DeviceToken` are added to `NOT_A_BUSINESS_RECORD` in
  [ModelConventionsTest](../../backend/tests/Feature/Audit/ModelConventionsTest.php), **with the
  reasoning written into the constant** as `ActivityLog` and `NawrisWebhookEvent` already have.
  They are high-volume event records, not business records: auditing a notification would write a
  log row saying a log row arrived, and soft-deleting one defeats the point of pruning it. **Do
  not weaken the test — extend its documented exclusion.**
- **`AuditSubject`** gains no case for these three, since they are never a subject. But a
  definition writing `subject_type` must use an alias **already registered** there.
- **`PermissionName` gains one case** — `notifications.broadcast` (§8.1) — plus its `label()` and
  a new «الإشعارات» group entry, so it appears on the roles screen. Adding a permission is a code
  change by design: *"a permission is only real because something in the codebase checks for
  it."* **No role is granted it**; administrators-only follows from `Gate::before` alone.
- **The announcement endpoint writes an `ActivityLog` row by hand**, following
  [RecordRolePermissionChange](../../backend/app/Domain/Identity/Actions/RecordRolePermissionChange.php).
  It is the one notification that is a deliberate human act rather than a system consequence, and
  it must stay attributable after the notification rows themselves are pruned.
- **Scramble:** `rules()` written out in full, never `array_merge` — or the endpoints publish
  undocumented. Run `php artisan scramble:analyze` before calling any endpoint done.
- **Envelope:** every response through `ResponseTrait`; the list through `successWithPagination`.
- **Arabic** for every user-facing string, including rendered sentences and FCM titles.
- **`declare(strict_types=1)`** and full type coverage throughout, per RULES §9.3.

---

## 13. Testing

Per RULES §6 — Arrange-Act-Assert, against PostgreSQL, authenticating with a real Sanctum token.
Beyond the standard endpoint checklist, four cases exist because of this feature specifically:

- **Ownership** — marking another user's notification read returns 404, and that row is asserted
  untouched.
- **Audience** — publishing to a permission notifies exactly its holders, excludes the causer,
  and notifies nobody when the permission is held by no one.
- **Dedupe** — the same event twice inside the window writes one notification, not two.
- **Push never leaks** — `Http::fake()` asserts no real call is made, that the payload carries no
  amount or customer name (§6.4), and that an `UNREGISTERED` response **deletes the token row and
  succeeds** rather than retrying. RULES §9 forbids tests sending real notifications; `dry_run` is
  the second belt.

And four for announcements specifically (§8.1):

- **Authorization, three cases** — an administrator passes with no grant at all (via
  `Gate::before`); an ordinary employee holding no such grant gets 403; **and an ordinary employee
  who *has* been granted `notifications.broadcast` succeeds.** That third assertion is the one
  that proves delegation actually works, and it is the whole reason this is a permission rather
  than a Gate — without it, a regression could silently make the feature administrators-only
  forever and every other test would still pass.
- **Audience** — `everyone` reaches every active account and **no investor**; `role` reaches
  exactly that role's members.
- **The activity row is written**, with the right causer, and survives pruning the notification.
- **Throttling** — a rapid second send is refused with 429, and writes nothing.

---

## 14. Assumptions recorded

Locked defaults, each a one-line change if wrong:

| | |
|---|---|
| Firebase auth library | **none** — the assertion is signed in-house, because Composer cannot install anything at all right now. §9 |
| Push payload content | safe title only, lock-screen visible — §6.4 |
| Retention | 90 days read / 1 year unread — §10 |
| Platforms | Android **and** iOS — but **iOS push is blocked on an APNs key that does not exist yet**; the in-app centre works on both from day one — §9 |
| Firebase projects | **two — dev and production, separate. Confirmed** — §9 |
| Phase-1 pilot | `order.shortage` — **confirmed** |
| Phase-2 catalogue | **confirmed** — §8 |
| Manual announcements | in scope, behind a **grantable `notifications.broadcast` permission** — §8.1. Administrators-only today because **no role holds it**, delegatable later with one tick and no deploy. |
| Announcement audience | «الجميع» = every active **employee**; investors are excluded. Or one role. Free text, no scheduling, no recall once sent. |
| Investor notifications | deferred, audience constructor reserved — §5.3 |
| Queue worker | **unverified in production** — §10.1, the launch-day risk |

---

## 15. Deployment checklist

Everything between «the code is merged» and «a notification reaches a phone». **Each unticked box
below fails silently** — no error, no log line, every screen still working — which is why this is
a list rather than a paragraph.

### Before the feature is announced to staff

- [ ] **Migrations run** — the three in §3.
- [ ] **`bin/rebuild-caches`** — new routes *and* new config keys, the exact case the
      [README](../../README.md) documents as a live controller answering 404.
- [ ] **A queue worker is running, and supervised.** ⚠️ **Not verified on any box.** Without it
      `order.shortage` produces **nothing at all** — see §10, the asymmetry table. Check with
      `ps aux | grep queue:work`, then supervise it (systemd, Supervisor, or a cPanel cron running
      `queue:work --stop-when-empty`). **Do not take «the Nawris webhook works» as proof**: that
      job fires rarely enough that a worker somebody restarted by hand months ago looks identical
      to a supervised one.
- [ ] **A cron entry for `schedule:run`** — the first scheduled work this application has ever
      had. Without it the tables grow forever.
      ```
      * * * * * cd /path/to/backend && php artisan schedule:run >> /dev/null 2>&1
      ```
- [ ] **`failed_jobs` is watched by somebody.** A push that fails three times lands there and
      nowhere else.

### Push — additionally, and only when Firebase exists

- [ ] **Two Firebase projects**, dev and production separate (§9 — a shared one lets a laptop
      reach the shop's counter phone).
- [ ] **Service account JSON on each box**, path in `FCM_CREDENTIALS_PATH`. A private key:
      out of band like `.env`, never committed, file permissions to match.
- [ ] **`.env` filled**: `FCM_PROJECT_ID`, `FCM_CREDENTIALS_PATH`, `FCM_ANDROID_CHANNEL_ID`,
      `FCM_LOG_CHANNEL`, `FCM_DRY_RUN`.
- [ ] **`FCM_DRY_RUN=true` for the first deploy**, then read `storage/logs/fcm.log` and confirm
      the payload before letting one leave the box.
- [ ] **Android package name and iOS bundle id** registered in both projects.
- [ ] **APNs `.p8` key uploaded to Firebase** — ⚠️ *does not exist yet*. Needs a paid Apple
      Developer account. **Nothing reaches an iPhone until it does**, and it is the longest lead
      item in the whole plan.

**Until every push box is ticked, `PushChannel` skips silently and the in-app centre works
normally.** That is deliberate: an unconfigured install must not fill `failed_jobs` with jobs
that could never have succeeded.

### Decide before granting

- [ ] **Who holds `notifications.broadcast`.** No role holds it, so it is administrators-only
      today through `Gate::before` alone. Whoever is given it can put arbitrary text on every
      employee's lock screen — read §11 before ticking that box on the roles screen.

### Not part of this checklist, because the app does not exist yet

The endpoints have no consumer until the Flutter side is built —
[NOTIFICATIONS-FRONTEND-INTEGRATION.md](NOTIFICATIONS-FRONTEND-INTEGRATION.md). Staff will see
nothing until then, however green the boxes above are.
