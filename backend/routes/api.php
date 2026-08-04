<?php

use App\Application\Api\V1\Controllers\ActivityLogController;
use App\Application\Api\V1\Controllers\AuthController;
use App\Application\Api\V1\Controllers\CityController;
use App\Application\Api\V1\Controllers\CustomerController;
use App\Application\Api\V1\Controllers\CustomerDesignController;
use App\Application\Api\V1\Controllers\HealthController;
use App\Application\Api\V1\Controllers\PermissionController;
use App\Application\Api\V1\Controllers\ProductController;
use App\Application\Api\V1\Controllers\ProductImageController;
use App\Application\Api\V1\Controllers\RegionController;
use App\Application\Api\V1\Controllers\RoleController;
use App\Application\Api\V1\Controllers\StockMovementController;
use App\Application\Api\V1\Controllers\UserController;
use App\Application\Api\V1\Controllers\WarehouseController;
use App\Application\Api\V1\Controllers\WarehouseStockController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API routes — v1
|--------------------------------------------------------------------------
| Everything is versioned. A published contract is never changed in place;
| breaking changes go into a new `v2` group instead.
|
| These routes are the input to the OpenAPI spec at /docs/api.json — adding a
| route here makes it show up in the docs UI automatically.
*/

Route::prefix('v1')->group(function (): void {
    Route::get('health', HealthController::class)->name('health');

    Route::prefix('auth')->name('auth.')->group(function (): void {
        // Throttled: unauthenticated and worth brute-forcing.
        Route::post('register', [AuthController::class, 'register'])
            ->middleware('throttle:6,1')
            ->name('register');

        Route::post('login', [AuthController::class, 'login'])
            ->middleware('throttle:6,1')
            ->name('login');

        Route::middleware('auth:sanctum')->group(function (): void {
            Route::get('me', [AuthController::class, 'me'])->name('me');
            Route::post('logout', [AuthController::class, 'logout'])->name('logout');
            Route::post('logout-all', [AuthController::class, 'logoutAll'])->name('logout-all');
        });
    });

    Route::middleware('auth:sanctum')->group(function (): void {
        /*
         * Access is declared here with `can:` rather than checked inside controllers, so the
         * permission a route needs sits next to the route itself — there is no endpoint whose
         * guard you have to open a controller to discover.
         *
         * An administrator satisfies all of these by rule (Gate::before), so none of them ever
         * needs granting to that role.
         */

        // ── access management ───────────────────────────────────────────────────────────
        Route::get('permissions', [PermissionController::class, 'index'])
            ->middleware('can:roles.manage')->name('permissions.index');

        Route::apiResource('roles', RoleController::class)
            ->middleware('can:roles.manage');

        Route::get('users', [UserController::class, 'index'])
            ->middleware('can:users.view')->name('users.index');

        Route::patch('users/{user}/roles', [UserController::class, 'syncRoles'])
            ->middleware('can:users.manage')->name('users.roles');

        // ── customers ───────────────────────────────────────────────────────────────────
        // No destroy route on purpose: a customer is deactivated, never deleted, so orders
        // and history keep pointing at a row that still exists.
        Route::apiResource('customers', CustomerController::class)
            ->only(['index', 'show'])
            ->middleware('can:customers.view');

        Route::apiResource('customers', CustomerController::class)
            ->only(['store', 'update'])
            ->middleware('can:customers.manage');

        Route::patch('customers/{customer}/activation', [CustomerController::class, 'setActivation'])
            ->middleware('can:customers.manage')->name('customers.activation');

        // A customer's artwork. `scoped()` makes {design} resolve *within* {customer}, so
        // another customer's design id is a 404 by construction rather than by a check somebody
        // has to remember — the same shape products.images and cities.regions already use.
        //
        // No `show`: the list carries every field, and a design is only ever met in a list.
        // No route replaces a file — see CustomerDesignController.
        Route::apiResource('customers.designs', CustomerDesignController::class)
            ->only(['index'])
            ->middleware('can:customers.view')
            ->scoped();

        Route::apiResource('customers.designs', CustomerDesignController::class)
            ->only(['store', 'update', 'destroy'])
            ->middleware('can:customers.manage')
            ->scoped();

        // ── catalogue ───────────────────────────────────────────────────────────────────
        // Reading the catalogue and pricing a quantity are everyday work; changing what things
        // cost is not. Hence two permissions rather than one.
        Route::apiResource('products', ProductController::class)
            ->only(['index', 'show'])
            ->middleware('can:products.view');

        // Pricing lives behind an endpoint rather than in the client, so the number a customer
        // is shown and the number written to an order come from the same code.
        Route::post('products/{product}/quote', [ProductController::class, 'quote'])
            ->middleware('can:products.view')->name('products.quote');

        // Same rule as customers: a product is deactivated, never deleted, so past orders keep
        // pointing at a row that still exists.
        Route::apiResource('products', ProductController::class)
            ->only(['store', 'update'])
            ->middleware('can:products.manage');

        Route::patch('products/{product}/activation', [ProductController::class, 'setActivation'])
            ->middleware('can:products.manage')->name('products.activation');

        // scoped() makes {image} resolve *within* {product}, so another product's image id is a
        // 404 rather than something every controller method has to remember to check.
        Route::apiResource('products.images', ProductImageController::class)
            ->only(['store', 'update', 'destroy'])
            ->parameters(['images' => 'image'])
            ->middleware('can:products.manage')
            ->scoped();

        // ── delivery map ────────────────────────────────────────────────────────────────
        // Reading is its own permission because anyone taking an order needs the city and
        // region lists to fill it in; curating that map is a separate, rarer job.
        //
        // Unlike customers and products, a city *is* deletable: it is reference data the
        // business curates, not a record history points back at. That will want revisiting
        // when Orders lands — see DeliveryService::deleteCity().
        Route::apiResource('cities', CityController::class)
            ->only(['index', 'show'])
            ->middleware('can:cities.view');

        Route::apiResource('cities', CityController::class)
            ->only(['store', 'update', 'destroy'])
            ->middleware('can:cities.manage');

        // Nested and scoped: a region has no life outside its city, so {region} resolves
        // *within* {city} and another city's region id is a 404 by construction.
        Route::apiResource('cities.regions', RegionController::class)
            ->only(['index', 'show'])
            ->middleware('can:cities.view')
            ->scoped();

        Route::apiResource('cities.regions', RegionController::class)
            ->only(['store', 'update', 'destroy'])
            ->middleware('can:cities.manage')
            ->scoped();

        // ── inventory ───────────────────────────────────────────────────────────────────
        // One pair of permissions covers warehouses, balances and the ledger. Splitting them
        // would produce guards that cannot usefully be granted alone: whoever may transfer
        // stock between two warehouses is administering both of them.
        Route::apiResource('warehouses', WarehouseController::class)
            ->only(['index', 'show'])
            ->middleware('can:inventory.view');

        Route::apiResource('warehouses', WarehouseController::class)
            ->only(['store', 'update', 'destroy'])
            ->middleware('can:inventory.manage');

        // A balance line has no life outside its warehouse, so `scoped()` resolves {stock}
        // *within* {warehouse} — another warehouse's line id is a 404 by construction, the
        // same shape products.images and cities.regions already use.
        //
        // Read-only apart from the alert threshold, and that is the point of the whole context:
        // a quantity is never written by a request. It moves because a movement below explains
        // it, in the same transaction. There is deliberately no PUT on a stock line.
        Route::get('warehouses/{warehouse}/stocks', [WarehouseStockController::class, 'index'])
            ->middleware('can:inventory.view')->name('warehouses.stocks.index');

        Route::patch('warehouses/{warehouse}/stocks/{stock}/threshold', [WarehouseStockController::class, 'setThreshold'])
            ->scopeBindings()
            ->middleware('can:inventory.manage')->name('warehouses.stocks.threshold');

        // The ledger. One feed to read, four ways to write to it — an arrival has no source, a
        // fulfillment has no destination, an adjustment has a direction instead of either, so
        // each is its own endpoint with its own body rather than one route carrying a type
        // discriminator and four optional fields.
        Route::get('stock-movements', [StockMovementController::class, 'index'])
            ->middleware('can:inventory.view')->name('stock-movements.index');

        Route::prefix('stock-movements')->name('stock-movements.')
            ->middleware('can:inventory.manage')
            ->group(function (): void {
                Route::post('arrivals', [StockMovementController::class, 'arrivals'])->name('arrivals');
                Route::post('transfers', [StockMovementController::class, 'transfers'])->name('transfers');
                Route::post('fulfillments', [StockMovementController::class, 'fulfillments'])->name('fulfillments');
                Route::post('adjustments', [StockMovementController::class, 'adjustments'])->name('adjustments');
            });

        // ── audit trail ─────────────────────────────────────────────────────────────────
        // Every record's history hangs off the record itself, so `{product}` resolves, 404s
        // and — where a resource is scoped — nests exactly as it does on the endpoint beside
        // it. One `/logs?subject_type=…&subject_id=…` endpoint would have had to reimplement
        // all of that, and would have got it wrong for one resource eventually.
        //
        // All of them are behind `logs.view` rather than the permission that guards the record.
        // Reading a history is a different decision from reading the record: it surfaces what
        // *everyone* has done, including people and prices the reader has no other way to see.
        // Someone who may edit products is not automatically someone who may audit their
        // colleagues.
        Route::middleware('can:logs.view')->group(function (): void {
            Route::get('logs', [ActivityLogController::class, 'index'])->name('logs.index');

            Route::get('users/{user}/logs', [UserController::class, 'logs'])->name('users.logs');
            Route::get('roles/{role}/logs', [RoleController::class, 'logs'])->name('roles.logs');
            Route::get('customers/{customer}/logs', [CustomerController::class, 'logs'])->name('customers.logs');
            Route::get('products/{product}/logs', [ProductController::class, 'logs'])->name('products.logs');
            Route::get('cities/{city}/logs', [CityController::class, 'logs'])->name('cities.logs');

            // The warehouse and the alert thresholds set on its shelves. Not the movements —
            // those are a ledger rather than a change log, and `/stock-movements?warehouse_id=`
            // is the reader built for them.
            Route::get('warehouses/{warehouse}/logs', [WarehouseController::class, 'logs'])->name('warehouses.logs');

            // Scoped like the rest of the nested region routes: another city's region id is a
            // 404 here too, not a history leaked from the wrong place.
            Route::get('cities/{city}/regions/{region}/logs', [RegionController::class, 'logs'])
                ->scopeBindings()
                ->name('cities.regions.logs');
        });
    });
});
