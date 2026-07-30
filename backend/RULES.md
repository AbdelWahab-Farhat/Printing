# Printing — Backend Rules

> The binding standard for **how** we build the Printing API.
> **Clean code · Clean structure · Deliberate decisions · Every endpoint tested with real use cases.**
>
> [CLAUDE.md](CLAUDE.md) holds the general engineering rules that apply to any repository.
> **This file holds the ones specific to this backend, and wins where the two overlap.**
> Everything below is relative to `backend/`.

---

## 0. The five rules that matter most

If you remember nothing else:

1. **Test first, and in Arrange-Act-Assert.** No behaviour ships without a test written the same change. → [§6](#6-testing)
2. **Throw, never catch.** There is no `try`/`catch` in `app/`, and a test enforces it. → [§5](#5-error-handling)
3. **Organise by domain, not by file type.** Business logic in `Domain/`, HTTP in `Application/`. → [§3](#3-architecture)
4. **Never hand-write API docs.** If the spec is wrong, fix the *code*. → [§7](#7-api-spec)
5. **Migrations are forward-only.** Fix a mistake with a new migration, never by editing an applied one. → [§8](#8-database)

---

## 1. Production safety

**Detecting production:** the environment is production when `APP_ENV=production`, **or** `APP_URL`
points at the live host. Set the production host here once it exists → **`<PROD_HOST>` (fill in)**.

When the environment is production:

1. ❌ **Never** run the test suite — not even with `--filter`. The suite truncates tables.
2. ❌ **Never** run anything that writes: `db:seed`, `migrate:fresh`, `migrate:refresh`,
   `migrate:rollback`, or `tinker` writes.
3. ❌ **Never** run a destructive or schema-dropping migration.
4. ✅ Read-only artisan is fine: `route:list`, `config:show`, `about`, `queue:work`, log tailing.
5. ✅ Editing source files is fine — just never *execute* the above against production.

---

## 2. Tech stack

| Layer | Choice |
|---|---|
| Framework | Laravel 13 on PHP 8.3+ |
| Database | **PostgreSQL** (dev `printing_bags`, tests `printing_bags_test`) |
| API auth | **Sanctum** personal access tokens (Bearer) |
| API spec | **Scramble** → OpenAPI 3.1, generated from code |
| Tests | **PHPUnit** (not Pest — a deliberate choice, keep it) |
| Style | **Laravel Pint**, the single source of style truth |
| Tooling | Laravel Boost (MCP), Pail, Tinker |

Adopt only when a real requirement calls for it: `spatie/laravel-permission` (RBAC), Filament
(admin UI), Redis + Horizon (queues at scale), Reverb (websockets). **Every dependency is a
decision — justify it.**

### Commands

```bash
php artisan serve                 # http://localhost:8000
php artisan test                  # whole suite  ·  --filter=CustomerTest for one
./vendor/bin/pint                 # fix style    ·  --test to check only
php artisan migrate               # never migrate:fresh on anything shared
composer spec                     # export OpenAPI to ../Docs/openapi.json
php artisan scramble:analyze      # verify the spec generates cleanly
```

---

## 3. Architecture

**Organised by domain, not by file type.** A type-first layout (`app/Services/`, `app/DTOs/`) turns
into a drawer of unrelated files once the model count grows, and every feature edit touches six
distant folders.

```
app/
├── Domain/                     business logic — no Request, no Response, no HTTP
│   ├── <Context>/
│   │   ├── Models/
│   │   ├── Actions/            one verb, one class
│   │   ├── DTOs/               readonly, typed
│   │   ├── Queries/            reusable reads
│   │   ├── Exceptions/         this context's failures
│   │   └── <Context>Service.php   the module's ONLY public entry point
│   └── ...
├── Application/                transport only
│   ├── Api/V1/{Controllers,Requests,Resources}
│   └── Controller.php
└── Support/                    ApiEnvelope, ResponseTrait, base exceptions
```

Existing contexts: `Identity` (users, auth) and `Customer` (customers, shops).

### The rules

- **Dependencies run one way.** `Order` may depend on `Catalog`; `Catalog` must never import
  `Order`. When two contexts must react to each other, use a domain event — never a back-reference.
- **Cross-context access goes through the Service.** Another context calls `CustomerService`; it
  never touches `Customer::query()`. That seam is what lets a context change internally without a
  ripple. *Inside* a context, work lives in the Actions and Queries — the Service is the door, not
  a place for logic.
- **Controllers are thin.** Validate via FormRequest → call a Service/Action → return a Resource
  through the envelope. No business logic, no query building.
- **Actions over fat services.** One verb per class (`CreateCustomer`, `SyncCustomerShops`). A
  Service with forty methods is the old `app/Services/` drawer one level down.
- **DTOs at boundaries.** No associative arrays between layers. An array may cross into the domain
  exactly once, through a `fromArray()` on the DTO, fed by already-validated request data.
- **Resources shape every response.** Never return a raw model or `->toArray()`.
- **Enums for every status/type.** No magic strings; back state changes with explicit legal
  transitions.
- **Wrap multi-step writes in `DB::transaction`.**
- **Eager-load.** N+1 is a defect, not a style nit — and `Model::shouldBeStrict()` makes it throw
  outside production (see [§9](#9-conventions)).

### Models live outside `App\Models`

Laravel can no longer guess a model's factory. Every domain model names it, and every factory names
its model:

```php
#[UseFactory(CustomerFactory::class)]
class Customer extends Model { }

class CustomerFactory extends Factory {
    protected $model = Customer::class;
}
```

---

## 4. The response envelope

Every response — success **and** failure — has one shape, so a client parses one thing:

```json
{ "status": true, "message": "تم بنجاح", "data": {} }
```

A validation failure adds `errors` keyed by field. A paginated list adds a sibling `meta`
(`current_page`, `per_page`, `last_page`, `total`).

[`App\Support\ApiEnvelope`](app/Support/ApiEnvelope.php) is the **only** definition of that shape.
Controllers reach it through [`ResponseTrait`](app/Support/ResponseTrait.php)
(`success` · `created` · `successMessage` · `successWithPagination` · `error` ·
`validationErrorsResponse`); thrown exceptions reach it through the handlers in
[bootstrap/app.php](bootstrap/app.php). **Nothing else writes a response body.**

User-facing messages are **Arabic**.

---

## 5. Error handling

> **Throw, never catch.** There is **no `try`/`catch` anywhere in `app/`**, and
> `ErrorHandlingTest` walks the tree and fails the build if one appears.

Business code states what went wrong by throwing, then stops caring. Exactly one place turns a
failure into a response. That keeps error shaping in one file instead of scattered across every
service, and makes it impossible for one caller to swallow a failure another caller reports.

### Writing a new failure

Extend [`DomainException`](app/Support/Exceptions/DomainException.php). It defaults to **422** and
implements `ShouldntReport`, because an expected business failure is normal traffic, not a fault
worth logging:

```php
final class ShopDoesNotBelongToCustomer extends DomainException
{
    public static function make(int $shopId, int $customerId): self
    {
        return new self("المحل رقم {$shopId} لا ينتمي للعميل رقم {$customerId}");
    }
}
```

Override `httpStatus()`, `userMessage()` or `fieldErrors()` when the default is wrong. Field errors
render exactly like a validation failure, so a client can show them inline.

**No registration step.** The handler in `bootstrap/app.php` matches on the
[`ProvidesApiFailure`](app/Support/Exceptions/ProvidesApiFailure.php) *interface*, so a new failure
type is rendered correctly the moment it is written.

### What goes where

| Situation | What to do |
|---|---|
| A business rule is broken | `throw` a `DomainException` subclass |
| Input is malformed | Let the FormRequest reject it (422 automatically) |
| A genuine bug | Throw anything else — it is logged and becomes a generic 500 that never leaks its message outside local debugging |
| An infrastructure probe whose failure *is* the answer (e.g. "is the DB reachable?") | `rescue(fn () => ..., rescue: false, report: false)` — never a hand-written `try`/`catch` |

### Never

- ❌ `try`/`catch` in `app/` — the boundary already catches everything.
- ❌ Throwing Laravel's `ValidationException` from `Domain/` — that leaks an HTTP concern into the
  business layer. Throw a domain exception that carries `fieldErrors()` instead.
- ❌ Returning `null`/`false` to signal a failure a caller must interpret.

---

## 6. Testing

> **Every behaviour has a test. Change the behaviour and you change its test in the same edit,
> adding cases for what is new. A change without a test change is incomplete.**

### TDD

Write the failing test first, then the code that makes it pass. Red → green → refactor.

### AAA — Arrange, Act, Assert

Every test is visibly split into three. **Do not merge Act and Assert into one fluent chain** —
capture the result, then assert on it:

```php
public function test_update_changes_the_basic_fields(): void
{
    // Arrange
    $customer = Customer::factory()->create(['name' => 'قديم']);
    $headers = $this->auth();

    // Act
    $response = $this->withHeaders($headers)
        ->putJson("/api/v1/customers/{$customer->id}", ['name' => 'جديد', 'phone' => '0922222222']);

    // Assert
    $response->assertOk()->assertJsonPath('data.name', 'جديد');
    $this->assertDatabaseHas('customers', ['id' => $customer->id, 'name' => 'جديد']);
}
```

Omit an empty Arrange rather than writing a hollow marker. Use a `DataProvider` for families of
validation cases instead of copy-pasting near-identical tests.

### Every endpoint's checklist

Cover both the cases the user described **and** the ones they didn't that will break in production:

- ✅ **Happy path** — correct 2xx and correct `data` shape.
- ✅ **Validation** — each required / typed / bounded field rejected with 422 + field errors.
- ✅ **Auth** — unauthenticated → 401.
- ✅ **Authorization** — authenticated but forbidden → 403.
- ✅ **Not found** — missing or foreign resource → 404.
- ✅ **Lists** — pagination, filtering, sorting, the empty set, and an absurd `per_page`.
- ✅ **Boundaries** — min/max, zero, negative, Arabic text, very long input.
- ✅ **Ownership** — a request naming another owner's record is refused, and that record is
  verified untouched.
- ✅ **Envelope** — assert `status` / `message` / `data`, not just the HTTP code.
- ✅ **Invariants** — server-assigned fields cannot be supplied by the client.

### How this suite works

- **Tests run against PostgreSQL** (`printing_bags_test`), not SQLite, so they exercise the
  production driver. `ilike`, decimal precision and constraint behaviour all differ.
- **`RefreshDatabase`** on every feature test.
- **Authenticate with a real token** (`$user->createToken(...)->plainTextToken`), not
  `Sanctum::actingAs` — that produces a `TransientToken` and skips the path the app actually uses.
- **The container is reused within one test**, so an auth guard keeps returning a user whose token
  you just deleted. Call `$this->app->get('auth')->forgetGuards()` before re-checking.
- **Factories must satisfy real constraints.** Sequence-generated values, not random ones, wherever
  a unique index exists — a chance collision failing an unrelated test is a miserable bug to find.
- A bug fix ships **with the regression test** that would have caught it.

---

## 7. API spec

Every endpoint is published as OpenAPI 3.1 automatically. **Never hand-write API documentation.**

- Interactive: **`/docs/api`** · raw: **`/docs/api.json`** · export: `composer spec`.
- Scramble reads routes, FormRequests, Resources, enums and return types. This is exactly *why*
  [§3](#3-architecture) matters: clean typed code produces a correct spec for free.
- Validation rules become real schema constraints — `between:-90,90` becomes `minimum`/`maximum`,
  `confirmed` adds the confirmation field, and a comment above a rule becomes its description.
- Security is derived from route middleware, so a new `auth:sanctum` route documents its own lock.
- **If the spec is wrong, fix the code** — the FormRequest, Resource or return type. Never a doc.
- Run **`php artisan scramble:analyze`** before considering an endpoint done.

> ⚠️ **`rules()` must be statically analysable.** Scramble reads the method without running it, so
> `array_merge(parent::rules(), [...])` yields **no request body at all** — the endpoint silently
> publishes as undocumented. Write the array out in full, even if it duplicates a parent. Call a
> private method for a single dynamic rule (see
> [UpdateCustomerRequest](app/Application/Api/V1/Requests/Customer/UpdateCustomerRequest.php)).

---

## 8. Database

- **Forward-only.** Never edit an applied migration — add a new one. A migration already pushed
  describes what it *did*; only later migrations describe the current shape.
- **Enforce invariants in the database, not only in validation.** A `unique` rule loses to two
  concurrent requests that both pass the existence check before either commits; a unique index does
  not. Do both: validation gives the readable 422, the index is the guarantee.
- **No data cleanup inside a schema migration.** If a constraint cannot be applied because the data
  violates it, the migration *should* fail — deciding which of two real records to keep is a
  business decision, not a silent side effect.
- **Rename indexes alongside columns.** PostgreSQL keeps an index's original name through a column
  rename, leaving a misleading name behind.
- **Money: never a float.** Integer minor units or `decimal`, in a value object.
- **Coordinates: `decimal(10,7)`**, cast to `float` on the model so the API emits numbers rather
  than `"32.8872000"`.
- **A nullable column with required validation** is the honest answer when existing rows have no
  correct value and none can be derived. Say so in the migration docblock, and tighten to NOT NULL
  in a follow-up once the old rows are filled.
- Verify a risky migration with **`php artisan migrate --pretend`** before running it.

---

## 9. Conventions

1. **PSR-12 via Pint.** Run `./vendor/bin/pint` before committing.
2. **Strict mode is on** outside production:
   `Model::shouldBeStrict(! $this->app->isProduction())`. Lazy loading, missing attributes and
   silently discarded attributes all throw. Do not disable it to make something pass — fix the
   cause.
3. **Type everything** — parameters, returns, properties. `declare(strict_types=1)` in `app/`.
4. **Server-assigned fields are never fillable.** Identifiers, codes and computed values are
   assigned directly, never mass-assigned, so a request can never supply them.
5. **Arabic** for user-facing strings and validation messages; **English** for code, comments and
   commit messages.
6. **Comments explain *why*, not *what*.** A comment restating the code is noise; one recording a
   decision or a trap is worth keeping.
7. **Never commit secrets.** `.env` is ignored; add every new key to `.env.example`.
8. **Small named units.** If a controller method outgrows the screen, extract an Action.

---

## 10. Domain notes

**Customer codes** are `C1`, `C2`, `C3` … always `'C'` + the row id. The id is reserved from the
table's sequence *before* insert
([AllocateCustomerIdentifier](app/Domain/Customer/Actions/AllocateCustomerIdentifier.php)), so the
insert carries a final unique code, the column stays NOT NULL, and concurrent requests cannot
collide. Codes follow ids and may skip a number after a rolled-back transaction — they are
identifiers, not a count. This is the one place that depends on PostgreSQL.

**One phone, one customer.** A customer has exactly one `phone`, unique across the table. Users
likewise have exactly one. There is no multi-phone table and none should be added.

**Customers are deactivated, never deleted** (`is_active`), so history keeps pointing at a row that
still exists. There is deliberately no destroy route. An update that omits `is_active` leaves it
alone — omitting a field must never silently reactivate someone.

**Shops belong entirely to their customer** — no independent lifecycle, managed inline through the
customer's endpoints, cascading on delete. Sending `shops` replaces the whole set (`id` = update,
no `id` = create, absent from the set = delete); omitting the key leaves them untouched.

---

## 11. Git

- Feature branches; focused commits; the message explains **why**, not just what.
- The bar for merging: **Pint clean, `scramble:analyze` clean, whole suite green.**
- 🎯 Add CI (Pint + suite against PostgreSQL) so `main` cannot go red.

---

*Living document. When a rule here proves wrong, change it and record why — deliberate decisions
over cargo-culted ones.*
