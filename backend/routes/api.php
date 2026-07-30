<?php

use App\Application\Api\V1\Controllers\AuthController;
use App\Application\Api\V1\Controllers\CustomerController;
use App\Application\Api\V1\Controllers\HealthController;
use App\Application\Api\V1\Controllers\ProductController;
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
        // No destroy route on purpose: a customer is deactivated, never deleted, so orders
        // and history keep pointing at a row that still exists.
        Route::apiResource('customers', CustomerController::class)
            ->only(['index', 'store', 'show', 'update']);

        Route::patch('customers/{customer}/activation', [CustomerController::class, 'setActivation'])
            ->name('customers.activation');

        // Same rule as customers: a product is deactivated, never deleted, so past orders keep
        // pointing at a row that still exists.
        Route::apiResource('products', ProductController::class)
            ->only(['index', 'store', 'show', 'update']);

        Route::patch('products/{product}/activation', [ProductController::class, 'setActivation'])
            ->name('products.activation');

        // Pricing lives behind an endpoint rather than in the client, so the number a customer
        // is shown and the number written to an order come from the same code.
        Route::post('products/{product}/quote', [ProductController::class, 'quote'])
            ->name('products.quote');
    });
});
