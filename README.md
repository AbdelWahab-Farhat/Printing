# Printing

Monorepo for the **Printing** product — a Laravel API with a Flutter client.

```
backend/    Laravel 13 API  ·  PostgreSQL  ·  Sanctum  ·  OpenAPI 3.1 via Scramble
frontend/   Flutter app     ·  MVVM-Clean, Cubit as the ViewModel (see frontend/README.md)
Docs/       feature documentation, one folder per feature  ·  generated openapi.json
```

Remote: `github.com/AbdelWahab-Farhat/Printing` (branch `main`).

## Live API schema & testing

The backend publishes its own OpenAPI 3.1 spec, generated from the code itself — no hand-written
docs, no annotations. Start the server and the schema is live:

```bash
cd backend && php artisan serve
```

| What | URL |
|---|---|
| **Interactive docs — send real requests** | http://localhost:8000/docs/api |
| Raw OpenAPI 3.1 spec | http://localhost:8000/docs/api.json |
| Health check | http://localhost:8000/api/v1/health |

Edit a controller, FormRequest or Resource → reload `/docs/api` → the change is already there.
Log in through the UI's **Authorize** button once and every protected endpoint becomes testable.

## Quick start (backend)

```bash
cd backend
cp .env.example .env          # then set DB_USERNAME / DB_PASSWORD for your Postgres
php artisan key:generate
createdb printing_bags && createdb printing_bags_test
php artisan migrate --seed    # seeds an admin account
php artisan serve
```

Seeded admin (local only): `admin@printing.ly` / `0910000000`, password `password`.

**Local only, and the seeder is the reason it can say so.** On a deployed box that password is
rotated by hand after seeding, and `AdminSeeder`'s second account — the demo employee — is
removed. A seeded credential is a starting point for a laptop, never a login left standing on a
server that holds customer records.

## Quick start (frontend)

```bash
cd frontend
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Freezed / JSON
flutter run --dart-define=FLAVOR=dev                       # against localhost
```

Two flavours, one env file each — see [frontend/README.md](frontend/README.md#البيئات-flavours).
`dev` reads `.env.dev`; everything else reads `.env` and is what ships.

## Deploying

Each server carries a `printing-deploy` script that pulls `main`, installs without dev
dependencies, migrates, re-caches and reloads PHP-FPM — under `set -euo pipefail` with a trap
that brings the app back out of maintenance mode if any step fails:

```bash
ssh <server> printing-deploy
```

**Hostnames, addresses and credentials are deliberately not written down here** — this repository
is public, and a deployment map is reconnaissance. They live in the operator's own notes.

### Rebuilding the caches — [`backend/bin/rebuild-caches`](backend/bin/rebuild-caches)

New code on a box does nothing until the framework caches are rebuilt, and **skipping it fails
silently in a way that looks exactly like a bug in the code**. It happened on 2026-08-23:

- a brand-new endpoint answered `404` while the controller behind it was demonstrably running —
  the same responses carried a field that only the new code adds. The cached route table had
  been written before the route existed.
- a validation rule read a config key as absent and refused every upload with «لا يمكن تجاوز 0
  صور», while the file it comes from plainly says `5`. The cached config predated the key.

Neither left a line in a log. So the step lives in the repository rather than only inside each
server's own `printing-deploy` — that script is untracked and there is one copy per box, which
is how the boxes drifted far enough for one of them to skip it. **Deploy scripts call this
file**, and it clears before it rebuilds, because `optimize` overwrites the artefacts it still
knows how to write and leaves the ones it does not:

```bash
cd /path/to/printing/backend && bin/rebuild-caches

# On the cPanel box the system `php` is not the 8.4 the app runs under:
PHP_BIN=/opt/cpanel/ea-php84/root/usr/bin/php bin/rebuild-caches
```

Three things do not travel with a deploy, all on purpose:

- **`backend/database/seeders/data/customers.php`** — the customer book is real names and phone
  numbers, so it is git-ignored and copied to a server out of band. `CustomerSeeder` says so
  plainly when it is absent rather than failing inside a `require`.
- **`backend/.env`** — written once per box. Re-generating `APP_KEY` would strand every
  encrypted value and signed URL already in that database.
- **`public/storage`** — the symlink to `storage/app/public`, where product photos are written
  while `MEDIA_DISK=public`. Git cannot carry it and `printing-deploy` does not create it, so
  it is one command per box:

  ```bash
  php artisan storage:link
  ```

  **Its absence is silent on the server and only visible in the app.** Every API response stays
  perfectly healthy — `image_url` is built from `APP_URL` and returned as always — and only the
  file behind it 404s, so the app draws its broken-image placeholder on a payload that looks
  correct in a log. This shipped to production once, and the symptom was two shelves that
  looked like they were missing photos when in fact they were missing a symlink.

  `APP_URL` in that box's `.env` is the other half: the URL is built from it, so a value left at
  `http://localhost:8000` produces links no phone can reach even once the symlink exists. Config
  is cached on a deployed box, so changing it means `php artisan config:cache` afterwards.

## Project conventions

- **[backend/RULES.md](backend/RULES.md)** — the binding Laravel API standard. Read it before
  writing any PHP.
- **[backend/CLAUDE.md](backend/CLAUDE.md)** — general engineering rules that apply to any
  repository; `RULES.md` wins where the two overlap.
- **[frontend/RULES.md](frontend/RULES.md)** — the binding Flutter standard. Read it before
  writing any Dart.
- **[Docs/](Docs/README.md)** — one folder per feature, each holding that feature's design
  documents. Start at [Docs/README.md](Docs/README.md); deferred work lives in
  [Docs/BACKLOG.md](Docs/BACKLOG.md).
