# Printing — Frontend (Flutter)

Placeholder. The Flutter app has **not been scaffolded yet** — by design, we agreed to build the
Laravel API first and start the app afterwards.

## Scaffold it when we're ready

```bash
cd /Users/abdelwahabfarhat/Desktop/Printing-Bags
flutter create \
  --org ly.printing \
  --project-name printing \
  --platforms=android,ios \
  frontend
```

Installed toolchain on this machine: **Flutter 3.44.6 · Dart 3.12.2**.

## Where it connects

The app talks to the Laravel API in [../backend/](../backend/):

| Environment | Base URL |
|---|---|
| iOS simulator | `http://127.0.0.1:8000/api/v1` |
| Android emulator | `http://10.0.2.2:8000/api/v1` |

Every response uses the API's envelope, so the HTTP layer unwraps `data` once, centrally:

```json
{ "status": true, "message": "تم بنجاح", "data": { } }
```

The live contract to code against is always the generated OpenAPI spec — start the backend and open
**http://localhost:8000/docs/api** (interactive) or **/docs/api.json** (raw).

## Conventions

Not written yet — the Flutter standard gets its own `RULES.md` here when the app is scaffolded.
Until then, the backend's [RULES.md](../backend/RULES.md) is the reference for the API contract
(envelope, error shape, auth).
