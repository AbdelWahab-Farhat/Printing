# Printing

Monorepo for the **Printing** product — a Laravel API with a Flutter client.

```
backend/    Laravel 13 API  ·  PostgreSQL  ·  Sanctum  ·  OpenAPI 3.1 via Scramble
frontend/   Flutter app     ·  not scaffolded yet (see frontend/README.md)
Docs/       generated openapi.json
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

## Project conventions

Two binding rules documents — read the relevant one before writing code:

- **[backend/RULES.md](backend/RULES.md)** — Laravel API standard.
- **[frontend/RULES.md](frontend/RULES.md)** — Flutter app standard.

[CLAUDE.md](CLAUDE.md) holds environment/tooling facts for AI-assisted work.
