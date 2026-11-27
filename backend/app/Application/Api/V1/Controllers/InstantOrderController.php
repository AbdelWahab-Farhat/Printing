<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Requests\Order\StoreInstantOrderRequest;
use App\Application\Api\V1\Requests\Order\UpdateInstantOrderRequest;
use App\Application\Api\V1\Resources\InstantProductResource;
use App\Application\Api\V1\Resources\OrderResource;
use App\Application\Controller;
use App\Domain\Catalog\Models\Product;
use App\Domain\Customer\CustomerService;
use App\Domain\Delivery\Models\City;
use App\Domain\Delivery\Support\BranchAccess;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\InventoryService;
use App\Domain\Order\Actions\CreateInstantOrder;
use App\Domain\Order\Actions\UpdateInstantOrder;
use App\Domain\Order\DTOs\InstantOrderData;
use App\Domain\Order\Exceptions\InstantOrderRefused;
use App\Domain\Order\Models\Order;
use App\Domain\Order\OrderService;
use App\Domain\Order\Support\InstantOrderBranch;
use App\Domain\Order\Support\InstantSaleEligibility;
use App\Support\ApiEnvelope;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * @tags Instant orders
 *
 * «الطلبات الفورية» — a counter sale of plain stock at a branch (INSTANT-ORDERS-PLAN.md). Every
 * endpoint here is for the screen that takes one; moving an instant order afterwards goes through
 * the ordinary status endpoint, which knows the instant road.
 */
class InstantOrderController extends Controller
{
    use ResponseTrait;

    public function __construct(
        private readonly OrderService $orders,
        private readonly BranchAccess $branches,
    ) {}

    /**
     * Branches I may sell from
     *
     * The active office-pickup branches this employee is assigned to — every active one for
     * whoever holds `branches.manage`. Empty means the «طلب فوري» button is shown disabled.
     */
    public function branches(Request $request): JsonResponse
    {
        $user = $this->actor($request);

        $branches = $this->branches->sellingBranchesFor($user)->load('defaultWarehouse');

        return $this->success($branches->map(fn (City $branch): array => [
            'id' => (int) $branch->getKey(),
            'name' => (string) $branch->name,
            'warehouse_id' => $branch->default_warehouse_id,
            'warehouse_name' => $branch->defaultWarehouse?->name,
        ])->values());
    }

    /**
     * Find a customer by phone
     *
     * Exact match on the normalised number. Only what the instant form shows: name, phone and
     * address — a branch employee does not hold `customers.view`.
     */
    public function customer(Request $request, CustomerService $customers): JsonResponse
    {
        $request->validate(['phone' => ['required', 'string', 'max:30']]);

        $customer = $customers->findByPhone((string) $request->query('phone'));

        return $this->success([
            'found' => $customer !== null,
            'customer' => $customer === null ? null : [
                'id' => (int) $customer->getKey(),
                'name' => (string) $customer->name,
                'phone' => (string) $customer->phone,
                'is_active' => (bool) $customer->is_active,
                'city_id' => $customer->city_id,
                'city_name' => $customer->city()->value('name'),
                'region_id' => $customer->region_id,
                'region_name' => $customer->region()->value('name'),
            ],
        ]);
    }

    /**
     * Products an instant order may sell
     *
     * Plain, listed-price, same-unit products switched on for instant sale, each with only its
     * eligible sizes, their price tiers, and what the branch's warehouse holds of each.
     */
    public function products(
        Request $request,
        InstantSaleEligibility $eligibility,
        InstantOrderBranch $branch,
        InventoryService $inventory,
    ): JsonResponse {
        $request->validate(['branch_id' => ['required', 'integer']]);

        [, $warehouseId] = $branch->forSale((int) $request->query('branch_id'), $this->actor($request));

        $products = $eligibility->eligibleProducts();

        $stockItemIds = $products
            ->flatMap(fn (Product $product) => $product->variants->pluck('stock_item_id'))
            ->filter()
            ->map(fn ($id): int => (int) $id)
            ->unique()
            ->values()
            ->all();

        $available = $inventory->balancesFor($warehouseId, $stockItemIds);

        return $this->successWithMeta(
            $products->map(fn (Product $product) => (new InstantProductResource($product))->withAvailability($available))->values(),
            ['warehouse_id' => $warehouseId, 'warehouse_name' => $inventory->warehouseName($warehouseId)],
        );
    }

    /**
     * Take an instant order
     *
     * The customer (found by phone, or created), the order and its stock in one step. Refused
     * whole — nothing written, not even the customer — when the branch is inactive or not the
     * employee's, a product may not be sold instantly, or the warehouse is short of any line.
     *
     * `meta.customer_notice` says when the customer on file differs from what was typed: the
     * stored details were kept.
     */
    public function store(StoreInstantOrderRequest $request, CreateInstantOrder $create): JsonResponse
    {
        $result = $create(InstantOrderData::fromArray($request->validated()), $this->actor($request));

        return ApiEnvelope::ok(
            new OrderResource($this->orders->loadForDisplay($result['order'])),
            'تم إنشاء الطلب الفوري',
            201,
            ['customer_notice' => $result['customer_notice']],
        );
    }

    /**
     * Edit an instant order
     *
     * Lines, quantities, discount and notes, while it is still «جديدة». The stock the order drew
     * goes back and the new lines are drawn again in one step, so the shelf is never counted twice.
     */
    public function update(UpdateInstantOrderRequest $request, Order $order, UpdateInstantOrder $update): JsonResponse
    {
        if (! $order->isInstant()) {
            throw InstantOrderRefused::notInstant();
        }

        $updated = $update(
            $order,
            InstantOrderData::items($request->validated('items')),
            number_format((float) ($request->validated('discount') ?? 0), 2, '.', ''),
            $request->validated('notes'),
            $this->actor($request),
        );

        return $this->success(
            new OrderResource($this->orders->loadForDisplay($updated)),
            'تم تعديل الطلب الفوري',
        );
    }

    private function actor(Request $request): User
    {
        /** @var User $user */
        $user = $request->user();

        return $user;
    }
}
