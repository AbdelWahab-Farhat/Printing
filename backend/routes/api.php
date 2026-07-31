<?php

use App\Application\Api\V1\Controllers\ActivityLogController;
use App\Application\Api\V1\Controllers\AuthController;
use App\Application\Api\V1\Controllers\CityController;
use App\Application\Api\V1\Controllers\CustomerController;
use App\Application\Api\V1\Controllers\HealthController;
use App\Application\Api\V1\Controllers\PermissionController;
use App\Application\Api\V1\Controllers\ProductController;
use App\Application\Api\V1\Controllers\ProductImageController;
use App\Application\Api\V1\Controllers\RegionController;
use App\Application\Api\V1\Controllers\RoleController;
use App\Application\Api\V1\Controllers\UserController;
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

            // Scoped like the rest of the nested region routes: another city's region id is a
            // 404 here too, not a history leaked from the wrong place.
            Route::get('cities/{city}/regions/{region}/logs', [RegionController::class, 'logs'])
                ->scopeBindings()
                ->name('cities.regions.logs');
        });
    });
});
