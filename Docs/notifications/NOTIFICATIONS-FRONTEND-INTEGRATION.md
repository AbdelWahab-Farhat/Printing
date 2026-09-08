# Notifications — connecting the Flutter app

> **Status (٢٠٢٦-٠٩-٠٩): built, and the backend is merged on `main` (`7ef66d3`).** This was the
> plan for the app side of
> [NOTIFICATIONS-BACKEND-CHANGES.md](NOTIFICATIONS-BACKEND-CHANGES.md), written at the same time
> as it so the contract was agreed once rather than negotiated twice. Where this document and the
> shipped API disagree, **the API is right** — the live spec is `/docs/api`.
>
> **Two things in §11 are deliberately still open, and both are noted where they belong:**
>
> * **iOS push is untested code.** The APNs key now exists (`J24ZP25BJQ`, team `XJF65LWZ2J`) and
>   is uploaded to the *production* slot of the `daya-bdf70` Firebase project — but the
>   *development* slot is empty, so a debug build talks to the APNs sandbox and finds no key
>   there. Nothing on iOS has been observed delivering a push. Do not report it as working.
> * **No route to the system settings.** §7 asks for a one-tap `openAppSettings` from the blocked
>   state. The blocked state itself is implemented — the row goes red and says the phone is
>   blocking — but the tap is not, because every way to open the OS settings page needs a new
>   dependency (`app_settings` or `permission_handler`) and `pubspec.yaml` says plainly that
>   every dependency is a decision. Left for whoever wants to make it.
>
> The **in-app centre owes FCM nothing** and works on every phone today, iPhones included. That
> is the sentence to reach for when somebody asks why iOS «ما عندهاش إشعارات»: the mailbox is
> complete there; the phone is simply not woken by it yet.

---

## 0. What is already here

More than usual, and it changes the size of the job.

- **The settings toggle exists and does nothing.**
  [`SetNotificationsEnabled`](../../frontend/lib/features/settings/usecases/set_notifications_enabled.dart)
  stores a `SharedPreferences` bool and its docblock states plainly that no push service is wired
  up. It also predicts this work: *"The verb this class exists for arrives with that service —
  registering or releasing the device token — and it arrives **here**, in one file."* Follow that.
  It defaults to **on**, so a device that has never been asked will receive notifications the day
  push lands; a shop that turned it *off* must stay off.
- **The router already expects notification taps.** [`app_router.dart`](../../frontend/lib/core/router/app_router.dart)
  guards at `:481`, `:558`, `:863` and `:1043` all name *"a deep link, a notification tap or a
  stale back-stack entry"* as the thing they defend against. **Deep-linking from a notification is
  already safe** — do not add a second layer of guarding.
- **`AppIcons.notifications`** exists at
  [`app_icons.dart:466`](../../frontend/lib/core/utils/app_icons.dart#L466) — a platform-adaptive
  bell, unused.
- **`Paginated<T>`, `safeRequest`, `Failure`, `Session`** all exist. The list screen is ordinary.

**No push dependency exists.** `pubspec.yaml` has no `firebase_core`, no `firebase_messaging`, no
local-notifications package.

---

## 1. What the server offers

Seven endpoints, all `auth:sanctum`. Reading is behind no permission — every account reads its own
mail. Only sending an announcement is guarded.

| | |
|---|---|
| `GET /notifications` | paginated, newest first, `?unread=true` |
| `GET /notifications/unread-count` | `{ "count": 3 }` |
| `POST /notifications/{id}/read` | |
| `POST /notifications/read-all` | |
| `POST /notifications/devices` | `{ token, platform }` |
| `DELETE /notifications/devices` | `{ token }` |
| `POST /notifications/announcements` | `{ title, body, audience }` — **`notifications.broadcast`**, §10 |

One item:

```jsonc
{
  "id": 412,
  "type": "order.shortage",
  "title": "طلبية O145 في النواقص",
  "body": "كيس شحن 25*35 — ناقص 200",
  "icon": "warning",
  "route": "/orders/145",     // NULLABLE — an announcement has nothing to open
  "is_read": false,
  "created_at": "2026-09-07T09:14:22+02:00"
}
```

**`route` is nullable and the app must handle it**, not treat it as a malformed payload. Model it
as `String?` and make the tile non-tappable when it is null — a manual announcement («اجتماع
الساعة ٤») carries no destination by design, and it is the common case, not an edge one.

Marking another user's notification read returns **404, not 403** — the server refuses by
pretending it does not exist, so treat a 404 here as ordinary rather than as a bug.

---

## 2. Endpoints file

Added to [`api_endpoints.dart`](../../frontend/lib/core/network/api_endpoints.dart) in the
existing style:

```dart
abstract final class NotificationEndpoints {
  static const String list = '/notifications';
  static const String unreadCount = '/notifications/unread-count';
  static const String readAll = '/notifications/read-all';
  static const String devices = '/notifications/devices';

  static String read(int id) => '/notifications/$id/read';
}
```

---

## 3. The rendering contract — the rule that matters most

**The app must never `switch` on `type` to decide what to draw.**

`title`, `body`, `icon` and `route` are all server-rendered. The app draws whatever arrives and
pushes `route` at the router. The consequence is the entire point of the backend design: **a new
notification type appears in an already-shipped build with no app release.** The day someone adds
`if (type == 'stock.low')` to a widget, that property is gone and every future notification needs
a store submission.

Two places the app is allowed to interpret, both with a fallback:

```dart
/// The server's small, stable icon vocabulary. An unknown key is not an error — it is a newer
/// backend, and the bell must still draw. Same reasoning as [Session.unrecognised].
IconData _iconFor(String key) => switch (key) {
  'warning'      => AppIcons.warning,
  'order'        => AppIcons.orders,
  'inventory'    => AppIcons.warehouse,
  'money'        => AppIcons.payments,
  'announcement' => AppIcons.campaign,
  _              => AppIcons.notifications,   // ← the fallback is the feature
};
```

And `route`: **null means the tile does not navigate.** A non-null route that finds no matching
GoRoute — an older app, a newer backend — must land on the notification list rather than the
router's error page. **A tap that goes nowhere is acceptable; a tap that shows a crash screen is
not.**

---

## 4. Feature layout

Standard MVVM-Clean per [RULES.md §2](../../frontend/RULES.md), nothing unusual:

```
lib/features/notifications/
├── models/
│   ├── app_notification.dart            Freezed + JSON  (not `Notification` — Flutter owns that name)
│   └── unread_count.dart
├── repositories/
│   ├── notifications_repository.dart        abstract interface class
│   └── notifications_repository_impl.dart   Dio via safeRequest — the only file importing dio
├── usecases/
│   ├── get_notifications.dart
│   ├── get_unread_count.dart
│   ├── mark_notification_read.dart
│   ├── mark_all_read.dart
│   ├── register_device_token.dart
│   ├── release_device_token.dart
│   └── send_announcement.dart               § 10
└── presentation/
    ├── viewmodel/
    │   ├── notifications_cubit.dart + _state.dart      the list screen
    │   └── unread_badge_cubit.dart + _state.dart       the bell's count
    ├── views/notifications_page.dart
    └── widgets/notification_tile.dart
```

> **Name the model `AppNotification`.** `Notification` collides with `dart:ui`'s and with
> `firebase_messaging`'s, and the resulting import shadowing is a genuinely miserable afternoon.

State is a Freezed sealed union per RULES §4 — `initial` / `loading` / `loaded` / `failure`, never
adjacent nullable fields. `if (isClosed) return;` before every `emit` after an `await`. `fold`
with explicit closures, never constructor tear-offs (RULES §4.7 — it builds and then breaks
`flutter build --release`).

---

## 5. The bell — **two** placements, not one

This is the part most likely to be under-budgeted.

**① The staff shell.** [`root_page.dart`](../../frontend/lib/features/root/presentation/views/root_page.dart)
already has an `actions:` list on its `AppBar` (currently one conditional history button). The
bell goes there.

**② The investor portal.** [`investor_portal_page.dart`](../../frontend/lib/features/investor_portal/presentation/views/investor_portal_page.dart)
is **outside the shell** — the router comment at `:415` says *"Top level, beside the splash and
the login screen rather than inside the shell — the investor gets a page and no way out of it"*,
enforced by the redirect at `:1131`. **The shell's bell is invisible to an investor.** Its own
`AppBar` has an `actions:` list (currently just refresh) and needs the same widget.

So build a shared `NotificationBell` widget with the badge inside it and drop it into both, rather
than writing the badge inline in `RootPage`. That is the whole cost of investor support on the app
side, and doing it now costs nothing.

### The badge count

`UnreadBadgeCubit`, provided **above** the shell in the router so it survives tab switches, and
refreshed on:

- app resume (`AppLifecycleState.resumed`),
- an arriving FCM message while the app is in the foreground,
- returning from the notifications list,
- sign-in.

**Not on a timer.** Polling a count every N seconds to catch what push already delivers is battery
spent to duplicate a working channel.

The `ValueListenableBuilder<int>` on `session.revision` in `RootPage` is the pattern to copy for
rebuilding on session change.

---

## 6. Device token registration

**One file owns this**, as `SetNotificationsEnabled`'s docblock instructs. The four moments:

| When | What |
|---|---|
| Sign-in succeeds | request OS permission (§7), get the FCM token, `POST /notifications/devices` |
| Toggle switched **on** | same |
| Toggle switched **off** | `DELETE /notifications/devices` |
| **Sign-out** | `DELETE /notifications/devices` — **before** the token is cleared from storage |

**Sign-out is the one that must not be forgotten.** Skip it and the phone keeps receiving the
previous user's notifications — in a shop where one counter phone is shared between employees,
that is a live data leak, not an annoyance. It has to be part of the logout path itself, beside
where `TokenStorage` is cleared, not left to a screen to remember. The same reasoning
`AuthRepositoryImpl` already applies to `Session.adopt`.

FCM also rotates tokens on its own (`onTokenRefresh`) — re-register on every rotation.

---

## 7. OS permission, and the toggle that can lie

**iOS is shipping**, so this is a real state and not a formality.

- **iOS** requires an explicit permission prompt. **Android 13+ does too** (`POST_NOTIFICATIONS`).
  Either can be denied, and iOS will not re-prompt after a denial — the user must go to Settings.
- **So «تفعيل الإشعارات» can sit "on" while the OS silently blocks everything.** A toggle that
  says yes while the phone says no is worse than no toggle, because it stops the user looking for
  the real cause.

The settings row must therefore reflect *both*: when the app preference is on but OS permission
is denied, show it as blocked with a one-tap route to the system settings page
(`openAppSettings`), in Arabic. Do not silently flip the stored preference to off — the user's
answer to *our* question is still yes, and it must survive them granting permission later.

**Ask for permission at sign-in, not at app launch.** A prompt on the splash screen, before the
user has seen anything worth being notified about, is the classic way to get a permanent denial
that cannot be re-requested.

---

## 8. FCM plumbing

New dependencies: `firebase_core`, `firebase_messaging`. Plus `flutter_local_notifications` if
foreground banners are wanted on Android — **iOS can present them natively** via
`setForegroundNotificationPresentationOptions`, Android cannot.

Three states, three behaviours:

| App state | What happens | What the app does |
|---|---|---|
| **Foreground** | `onMessage` | no OS banner on Android by default — show an in-app banner or just refresh the badge |
| **Background** | `onMessageOpenedApp` fires on tap | `context.push(data['route'])` |
| **Terminated** | `getInitialMessage()` on start | same, but **after** the splash has resolved the session |

**The terminated case is the one that breaks.** `getInitialMessage()` must be read *after* the
splash has decided whether there is a usable session — the router's `initialLocation` is
`Routes.splash` precisely because *"it is the one place that decides whether there is a usable
session, so no other screen has to guess."* Navigating from a cold-start notification before that
resolves sends an unauthenticated user at an authenticated screen.

**Android:** create a notification channel whose id matches the server's
`android.notification.channel_id` (`dayaa_default`). A mismatch means Android 8+ **silently
drops** the notification — no error, no log, nothing on screen.

**iOS — ⚠️ push cannot be tested yet.** APNs requires a `.p8` key from a *paid* Apple Developer
account uploaded to Firebase, and **that key does not exist; it is to be added in production
later** (backend doc §9). Until then:

- **Build the iOS side anyway.** The code is identical to Android's — `firebase_messaging`
  abstracts the difference — so leaving it out means coming back to a cold feature later. Push
  capability and background modes still go in the Xcode project now.
- **But it is unverifiable on iOS**, and it must not be reported as working. Every iOS push path
  is untested code until the key lands; say so in the PR rather than letting a green Android test
  run imply both.
- **The in-app centre works on iPhone from day one** — it is a plain authenticated endpoint and
  owes FCM nothing. An iPhone user has a complete, working mailbox throughout; they are simply
  not woken by it. **That is worth saying out loud to whoever asks why iOS "has no
  notifications".**
- `aps.badge` arrives from the server, so the icon badge needs no app-side arithmetic when it does
  start working.

Both platforms need their Firebase config files provisioned — `google-services.json` and
`GoogleService-Info.plist`, **one pair per flavour** (§9). **Neither is a secret**, unlike the
backend's service account JSON.

---

## 9. Flavours

The app has two flavours reading two env files (`dev` → `.env.dev`, everything else → `.env`).
**Two Firebase projects are being set up, one per environment** (backend doc §9), so each flavour
carries its own `google-services.json` / `GoogleService-Info.plist`.

This is not tidiness. A Firebase project owns the device-token registry, and a token minted under
one project is meaningless to the other — so a single shared project means a push fired from a
developer's laptop reaches whatever real device is registered, **the shop's counter phone
included**, with no flag capable of preventing it. Two projects make that structurally impossible
rather than a thing to remember. Same discipline as `NAWRIS_DRY_RUN` on the backend.

---

## 10. Sending an announcement

The one screen in this feature that *writes* rather than reads — a person composes «اجتماع الساعة
٤» and it lands on every phone. Backend contract in
[NOTIFICATIONS-BACKEND-CHANGES.md](NOTIFICATIONS-BACKEND-CHANGES.md) §8.1.

### A new `AppPermission` case

The backend adds `notifications.broadcast` to `PermissionName` as a **grantable** permission
(backend doc §8.1) — deliberately *not* a Gate, so the business can delegate it to a floor manager
later with one tick on the roles screen and no deploy.

The app needs the matching case in
[`app_permission.dart`](../../frontend/lib/core/permissions/app_permission.dart), or `Session.can`
cannot be asked about it and the name lands in `Session.unrecognised` instead:

```dart
broadcastNotifications('notifications.broadcast'),
```

> **Gate it on `can`, never on `isAdmin`.** They give the same answer today, because no role holds
> the permission and administrators pass everything through `Gate::before` — which makes
> `isAdmin` a tempting shortcut that will *work*. It is still wrong: the day somebody ticks this
> onto «مدير الإنتاج», the server starts accepting their announcements and the app goes on hiding
> the button, and the bug is invisible from either side alone. `Session.isAdmin`'s own docblock
> says to reach for `can` first, and reserves itself for powers that have **no** permission —
> this one has one.

### The screen

`lib/features/notifications/presentation/views/compose_announcement_page.dart`, reached from the
notifications list's app bar — **not** from the drawer. It is a rare action that belongs beside the
thing it produces, and the list is where the sender goes to confirm it arrived.

Wrapped in `PermissionGate(AppPermission.broadcastNotifications)`, the same courtesy every other
guarded control uses — and it inherits `PermissionGate`'s listening on `session.revision`, so a
grant added while the app is open reveals the entry without a restart.

**A courtesy, never a boundary** — `can:notifications.broadcast` on the route is the boundary,
exactly as [`Session`](../../frontend/lib/core/session/session.dart)'s docblock insists. Never
relax the server-side check because the app hides the button.

Three fields:

| | |
|---|---|
| العنوان | required, short |
| النص | required, multiline |
| المستلمون | «الجميع» or a role, from the roles the app already fetches |

### Four things this screen must get right

- **Confirm before sending.** This is the one action in the application that interrupts every
  employee at once, and it cannot be recalled. A confirmation dialog naming the audience
  («سيصل هذا إلى كل الموظفين — ٢٣ شخصاً») is not friction, it is the feature.
- **Disable the button while the request is in flight.** The server throttles a rapid second send
  and answers 429, but a double-tapped send button should never reach that point. Handle the 429
  as a plain Arabic message, not a generic failure.
- **No draft persistence, no scheduling, no recall.** The backend offers none of these; the screen
  must not imply them.
- **The sender is excluded from their own announcement**, server-side. So a successful send shows
  a confirmation on screen and **no new notification in their own bell** — that is correct
  behaviour, not a bug to "fix" by refreshing harder.

---

## 11. Checklist

- [x] `firebase_core`, `firebase_messaging` added; Firebase config files provisioned per flavour
- [x] `NotificationEndpoints` added to `api_endpoints.dart`
- [x] `AppNotification` model + `Paginated` list, `dart run build_runner build`
- [x] Repository contract + impl (the only file importing `dio`)
- [x] Six usecases
- [x] `NotificationsCubit` + `UnreadBadgeCubit`, both sealed-union states
- [x] `NotificationsPage` — list, pull to refresh, pagination, mark-read on tap, "قراءة الكل"
- [x] Shared `NotificationBell` widget with badge
- [x] Bell wired into **`RootPage`** `actions:`
- [x] Bell wired into **`InvestorPortalPage`** `actions:`
- [x] Token registered on sign-in, on toggle-on, and on `onTokenRefresh`
- [x] **Token released on sign-out and on toggle-off** — §6
- [~] OS permission requested at sign-in ✅; blocked state shown in settings ✅; **route to the system settings not built** — needs a new dependency, see the status note at the top — §7
- [x] Foreground / background / **terminated** handled; terminated deferred until after the splash — §8
- [x] Android notification channel id matches the server's
- [~] iOS: push capability + background modes enabled ✅ (`Runner.entitlements`, `UIBackgroundModes`). APNs key uploaded to the **production slot only**, so **the iOS push path is still untested and must be reported as such** — §8
- [x] Unknown `icon` falls back; **null `route` does not navigate**; unknown route lands on the list, never the error page — §3
- [x] `broadcastNotifications` added to `AppPermission` — §10
- [x] Compose-announcement screen behind `PermissionGate` (**`can`, not `isAdmin`** — §10), with the confirmation dialog and 429 handling
- [x] All registrations added to [`Injector`](../../frontend/lib/core/di/injector.dart)
- [x] `flutter analyze` clean (only the four pre-existing issues on `main`, none in this feature) · tests green. **`dart format` not run** — the installed SDK's tall style reflows dozens of untouched files, so formatting is left to whoever owns that decision.
