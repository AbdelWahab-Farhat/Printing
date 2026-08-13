<?php

use App\Application\Api\V1\Controllers\ActivityLogController;
use App\Application\Api\V1\Controllers\AuthController;
use App\Application\Api\V1\Controllers\BusinessFieldController;
use App\Application\Api\V1\Controllers\CityController;
use App\Application\Api\V1\Controllers\CustomerController;
use App\Application\Api\V1\Controllers\CustomerDesignController;
use App\Application\Api\V1\Controllers\HealthController;
use App\Application\Api\V1\Controllers\HomeController;
use App\Application\Api\V1\Controllers\ManufacturingCostRateController;
use App\Application\Api\V1\Controllers\OrderController;
use App\Application\Api\V1\Controllers\OrderPaymentController;
use App\Application\Api\V1\Controllers\PermissionController;
use App\Application\Api\V1\Controllers\ProductController;
use App\Application\Api\V1\Controllers\ProductImageController;
use App\Application\Api\V1\Controllers\ProfitAndLossController;
use App\Application\Api\V1\Controllers\PurchaseOrderController;
use App\Application\Api\V1\Controllers\RegionController;
use App\Application\Api\V1\Controllers\RoleController;
use App\Application\Api\V1\Controllers\ShippingCompanyController;
use App\Application\Api\V1\Controllers\StockArrivalController;
use App\Application\Api\V1\Controllers\StockMovementController;
use App\Application\Api\V1\Controllers\UserController;
use App\Application\Api\V1\Controllers\VendorController;
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

        // ── the home screen ─────────────────────────────────────────────────────────────
        // The one endpoint in this file with no `can:` beside it. See HomeController: it is the
        // landing screen, and a permission here would show a blank front door to somebody whose
        // job is a single status transition.
        Route::get('home/summary', [HomeController::class, 'summary'])->name('home.summary');

        // ── access management ───────────────────────────────────────────────────────────
        Route::get('permissions', [PermissionController::class, 'index'])
            ->middleware('can:roles.manage')->name('permissions.index');

        Route::apiResource('roles', RoleController::class)
            ->middleware('can:roles.manage');

        Route::get('users', [UserController::class, 'index'])
            ->middleware('can:users.view')->name('users.index');

        // `users.create` is deliberately **not** a PermissionName case — it is a gate ability
        // defined in AppServiceProvider, so it cannot be ticked onto a role from the roles
        // screen and only an administrator satisfies it. Reads like every other guard on this
        // page precisely so that delegating it later changes nothing here.
        Route::post('users', [UserController::class, 'store'])
            ->middleware('can:users.create')->name('users.store');

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

        // ── مجالات العمل ────────────────────────────────────────────────────────────────
        // What a customer's shop sells. Reading is granted to every role — the customer form
        // cannot be filled in without the list — while curating the list is a rarer job, so it
        // is split off exactly as the delivery map's is.
        //
        // A destroy route exists, unlike customers and products, because this is a curated list
        // and a typo in it should be removable. The action refuses once any shop points at the
        // field; deactivation is what retires one in use.
        Route::apiResource('business-fields', BusinessFieldController::class)
            ->only(['index', 'show'])
            ->middleware('can:business_fields.view')
            ->parameters(['business-fields' => 'business_field']);

        Route::apiResource('business-fields', BusinessFieldController::class)
            ->only(['store', 'update', 'destroy'])
            ->middleware('can:business_fields.manage')
            ->parameters(['business-fields' => 'business_field']);

        Route::patch('business-fields/{business_field}/activation', [BusinessFieldController::class, 'setActivation'])
            ->middleware('can:business_fields.manage')->name('business-fields.activation');

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

        // ── orders ──────────────────────────────────────────────────────────────────────
        // The state machine's guards are *not* here, and that is the one deliberate exception
        // to this file's own rule. The permission a status change costs depends on the status
        // being asked for, which lives in the request body — a route cannot see it. So
        // ChangeOrderStatusRequest::authorize() looks it up from OrderStatus and answers 403,
        // and the route below only asks that the caller be allowed to see the order at all.
        //
        // Same reasoning for the discount: `orders.discount` is enforced inside the domain, so
        // it holds for a console command and a future import too, not only for this endpoint.
        // Declared *before* the resource: `apiResource` registers `/orders/{order}`, and
        // implicit binding would try to resolve the word "summary" as an order id and 404.
        Route::get('orders/summary', [OrderController::class, 'statusCounts'])
            ->middleware('can:orders.view')->name('orders.summary');

        Route::apiResource('orders', OrderController::class)
            ->only(['index', 'show'])
            ->middleware('can:orders.view');

        Route::apiResource('orders', OrderController::class)
            ->only(['store', 'update'])
            ->middleware('can:orders.manage');

        // No destroy route, for the same reason customers and products have none: an order is
        // the record everything else points at, and «ملغاة كلياً» is the business's own way of
        // ending one — with a reason attached, which a delete would throw away.
        Route::post('orders/{order}/status', [OrderController::class, 'changeStatus'])
            ->middleware('can:orders.view')->name('orders.status');

        // What is missing from each line — and therefore what the customer is charged, since a
        // line is billed for what is left of it. `can:` sits here rather than in the request
        // because unlike a status change this endpoint costs the same grant whatever it says:
        // the person who declares a shortage is the person who corrects one.
        Route::patch('orders/{order}/shortages', [OrderController::class, 'setShortages'])
            ->middleware('can:orders.status.shortage')->name('orders.shortages');

        // Designs are chosen from the customer's library, never uploaded here. scoped() makes
        // {design} resolve *within* {order}, so another order's design id is a 404 by
        // construction rather than by a check somebody has to remember.
        Route::post('orders/{order}/designs', [OrderController::class, 'storeDesign'])
            ->middleware('can:orders.designs.manage')->name('orders.designs.store');

        Route::post('orders/{order}/designs/{design}/review', [OrderController::class, 'reviewDesign'])
            ->scopeBindings()
            ->middleware('can:orders.designs.manage')->name('orders.designs.review');

        // Bags spoiled producing one line. Guarded by inventory.manage rather than an orders.*
        // permission — it draws stock and posts a FIFO cost the same way a fulfillment does, so
        // it is squarely part of the stock ledger regardless of which controller the route lives
        // on, the same reasoning PurchaseOrderController::receiveArrival() already carries.
        Route::post('orders/{order}/items/{item}/scrap', [OrderController::class, 'storeScrapLoss'])
            ->scopeBindings()
            ->middleware('can:inventory.manage')->name('orders.items.scrap');

        // ── an order's money ────────────────────────────────────────────────────────────
        // A ledger, not a balance. There is deliberately no PUT and no DELETE: an entry is
        // written once, and a mistake is undone by writing a second entry beside it — which is
        // the whole answer to "financial entries must be reversible". The stock ledger below
        // is built the same way for the same reason.
        //
        // Reading is its own permission rather than riding on `orders.view`: the person
        // printing the bags sees the order and has no business with what the customer paid.
        // And **money going out has its own permission again** — taking a deposit is a
        // receptionist's daily work, while putting a hand back into the drawer, whether as a
        // refund or as a cancelled entry, belongs to whoever answers for it.
        Route::get('orders/{order}/payments', [OrderPaymentController::class, 'index'])
            ->middleware('can:orders.payments.view')->name('orders.payments.index');

        Route::post('orders/{order}/payments', [OrderPaymentController::class, 'store'])
            ->middleware('can:orders.payments.record')->name('orders.payments.store');

        // Declared *before* the `{payment}` route below: implicit binding would otherwise try to
        // resolve the word "refunds" as a payment id and 404 — the same trap `orders/summary`
        // sits in front of.
        Route::post('orders/{order}/payments/refunds', [OrderPaymentController::class, 'refund'])
            ->middleware('can:orders.payments.reverse')->name('orders.payments.refund');

        // scopeBindings(): another order's payment id is a 404 by construction rather than by a
        // check somebody has to remember — the same shape orders.designs already uses.
        Route::post('orders/{order}/payments/{payment}/reverse', [OrderPaymentController::class, 'reverse'])
            ->scopeBindings()
            ->middleware('can:orders.payments.reverse')->name('orders.payments.reverse');

        // ── manufacturing cost rates ────────────────────────────────────────────────────
        // What a unit of production standard-costs at — applied automatically when an order
        // enters printing, never typed per job. Reading is separate from managing for the same
        // reason purchase_orders.* splits paperwork from the ledger it feeds.
        Route::apiResource('manufacturing-cost-rates', ManufacturingCostRateController::class)
            ->only(['index', 'show'])
            ->middleware('can:manufacturing_cost_rates.view')
            ->parameters(['manufacturing-cost-rates' => 'manufacturing_cost_rate']);

        Route::apiResource('manufacturing-cost-rates', ManufacturingCostRateController::class)
            ->only(['store', 'update', 'destroy'])
            ->middleware('can:manufacturing_cost_rates.manage')
            ->parameters(['manufacturing-cost-rates' => 'manufacturing_cost_rate']);

        Route::patch('manufacturing-cost-rates/{manufacturing_cost_rate}/activation', [ManufacturingCostRateController::class, 'setActivation'])
            ->middleware('can:manufacturing_cost_rates.manage')->name('manufacturing-cost-rates.activation');

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

        // Who carries the parcels. Its own permission pair: the person who agrees rates with
        // a carrier is not the person who maintains the list of neighbourhoods.
        Route::apiResource('shipping-companies', ShippingCompanyController::class)
            ->only(['index', 'show'])
            ->middleware('can:shipping_companies.view');

        Route::apiResource('shipping-companies', ShippingCompanyController::class)
            ->only(['store', 'update', 'destroy'])
            ->middleware('can:shipping_companies.manage');

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

        // ── vendors ─────────────────────────────────────────────────────────────────────
        // Its own permission pair, split from inventory.* for the same reason customers.* is
        // split from products.*: agreeing terms with a supplier is a different job from
        // receiving what they sent. No destroy route — a vendor is deactivated, never deleted,
        // so every shipment already on record keeps pointing at a real row.
        Route::apiResource('vendors', VendorController::class)
            ->only(['index', 'show'])
            ->middleware('can:vendors.view');

        Route::apiResource('vendors', VendorController::class)
            ->only(['store', 'update'])
            ->middleware('can:vendors.manage');

        Route::patch('vendors/{vendor}/activation', [VendorController::class, 'setActivation'])
            ->middleware('can:vendors.manage')->name('vendors.activation');

        // ── purchase orders ─────────────────────────────────────────────────────────────
        // Stock ordered ahead of it arriving: new → arrived → completed, with cancelled
        // reachable from either open status. Drafting, editing, sending and cancelling sit
        // behind their own pair, the same split vendors.* draws from inventory.* above — but
        // receiving a shipment against one is guarded by inventory.manage instead, declared
        // beside the resource routes below rather than here, because posting a shipment is
        // squarely part of that area regardless of which door it came in through. See
        // PurchaseOrderController's own docblock.
        Route::apiResource('purchase-orders', PurchaseOrderController::class)
            ->only(['index', 'show'])
            ->middleware('can:purchase_orders.view');

        Route::apiResource('purchase-orders', PurchaseOrderController::class)
            ->only(['store', 'update'])
            ->middleware('can:purchase_orders.manage');

        Route::patch('purchase-orders/{purchase_order}/status', [PurchaseOrderController::class, 'changeStatus'])
            ->middleware('can:purchase_orders.manage')->name('purchase-orders.status');

        Route::post('purchase-orders/{purchase_order}/arrivals', [PurchaseOrderController::class, 'receiveArrival'])
            ->middleware('can:inventory.manage')->name('purchase-orders.arrivals');

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

        // Declared before the `{stock}` route below so that «summary» is read as the word it is
        // rather than as an id somebody could have called a shelf.
        Route::get('warehouses/{warehouse}/stocks/summary', [WarehouseStockController::class, 'summary'])
            ->middleware('can:inventory.view')->name('warehouses.stocks.summary');

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

        // Stock arrivals: a vendor-linked document with one or more lines, sitting on top of the
        // ledger above rather than replacing it — each line still posts through
        // `InventoryService::recordMovement()`. No update or destroy route, the same rule
        // `stock-movements` follows: a posted arrival is never edited.
        Route::get('stock-arrivals', [StockArrivalController::class, 'index'])
            ->middleware('can:inventory.view')->name('stock-arrivals.index');

        Route::post('stock-arrivals', [StockArrivalController::class, 'store'])
            ->middleware('can:inventory.manage')->name('stock-arrivals.store');

        Route::get('stock-arrivals/{stock_arrival}', [StockArrivalController::class, 'show'])
            ->middleware('can:inventory.view')->name('stock-arrivals.show');

        // ── reports ─────────────────────────────────────────────────────────────────────
        // Revenue against cost of goods sold, over a period. Its own permission rather than a
        // ride on `orders.view`: this is the one screen that puts every order's money and every
        // order's cost side by side, which is a different sensitivity from either alone.
        Route::get('reports/profit-loss', [ProfitAndLossController::class, 'summary'])
            ->middleware('can:reports.pnl.view')->name('reports.profit-loss');

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
            Route::get('business-fields/{business_field}/logs', [BusinessFieldController::class, 'logs'])
                ->name('business-fields.logs');
            Route::get('products/{product}/logs', [ProductController::class, 'logs'])->name('products.logs');
            Route::get('cities/{city}/logs', [CityController::class, 'logs'])->name('cities.logs');
            Route::get('orders/{order}/logs', [OrderController::class, 'logs'])->name('orders.logs');
            Route::get('shipping-companies/{shippingCompany}/logs', [ShippingCompanyController::class, 'logs'])
                ->name('shipping-companies.logs');

            // The warehouse and the alert thresholds set on its shelves. Not the movements —
            // those are a ledger rather than a change log, and `/stock-movements?warehouse_id=`
            // is the reader built for them.
            Route::get('warehouses/{warehouse}/logs', [WarehouseController::class, 'logs'])->name('warehouses.logs');

            Route::get('vendors/{vendor}/logs', [VendorController::class, 'logs'])->name('vendors.logs');

            Route::get('stock-arrivals/{stock_arrival}/logs', [StockArrivalController::class, 'logs'])
                ->name('stock-arrivals.logs');

            Route::get('purchase-orders/{purchase_order}/logs', [PurchaseOrderController::class, 'logs'])
                ->name('purchase-orders.logs');

            Route::get('manufacturing-cost-rates/{manufacturing_cost_rate}/logs', [ManufacturingCostRateController::class, 'logs'])
                ->name('manufacturing-cost-rates.logs');

            // Scoped like the rest of the nested region routes: another city's region id is a
            // 404 here too, not a history leaked from the wrong place.
            Route::get('cities/{city}/regions/{region}/logs', [RegionController::class, 'logs'])
                ->scopeBindings()
                ->name('cities.regions.logs');
        });
    });
});
