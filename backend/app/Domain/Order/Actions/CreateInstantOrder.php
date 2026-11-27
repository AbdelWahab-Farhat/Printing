<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Catalog\Models\Product;
use App\Domain\Customer\CustomerService;
use App\Domain\Customer\DTOs\CustomerData;
use App\Domain\Customer\Models\Customer;
use App\Domain\Customer\Support\PhoneNumber;
use App\Domain\Identity\Models\User;
use App\Domain\Order\DTOs\InstantOrderData;
use App\Domain\Order\DTOs\OrderData;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\OrderType;
use App\Domain\Order\Events\OrderStockDrawn;
use App\Domain\Order\Exceptions\InstantOrderRefused;
use App\Domain\Order\Exceptions\OrderNeedsAtLeastOneItem;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Support\InstantOrderBranch;
use App\Domain\Order\Support\InstantOrderStock;
use App\Domain\Order\Support\InstantSaleEligibility;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Takes an instant order: the customer, the order and its stock, in one transaction
 * (INSTANT-ORDERS-PLAN.md §3–§4).
 *
 * **Order of work, and why.**
 * 1. Branch, warehouse and every line are checked before anything is written — a refused sale
 *    leaves nothing behind, not even a new customer.
 * 2. Inside the transaction: the customer is found by phone or created; the shelf is checked
 *    under a lock; the order is taken through {@see CreateOrder} like every order (pricing,
 *    totals, discount permission, the opening timeline row); and its stock is drawn at once with
 *    {@see DeductOrderStock} — the same deduction, FIFO cost and ledger rows a normal order gets
 *    at «جاهزة». A cancel gives it back through the existing reversal.
 * 3. The production cost a plain order is given at «جاهزة» is given now, because an instant
 *    order never passes through «جاهزة».
 *
 * **Asked twice, written once.** A retried request with the same `client_token` from the same
 * employee returns the order the first one made.
 */
final class CreateInstantOrder
{
    public function __construct(
        private readonly CreateOrder $createOrder,
        private readonly DeductOrderStock $deductStock,
        private readonly ApplyManufacturingRates $applyManufacturingRates,
        private readonly RecalculateOrderCogs $recalculateCogs,
        private readonly CustomerService $customers,
        private readonly InstantOrderBranch $branches,
        private readonly InstantOrderStock $stock,
        private readonly InstantSaleEligibility $eligibility,
    ) {}

    /**
     * @return array{order: Order, customer_notice: ?string}
     *
     * @throws InstantOrderRefused
     */
    public function __invoke(InstantOrderData $data, User $actor): array
    {
        if ($data->items === []) {
            throw OrderNeedsAtLeastOneItem::make();
        }

        [$branch, $warehouseId] = $this->branches->forSale($data->branchId, $actor);
        $products = $this->eligibleProducts($data);

        return $this->place($data, $actor, (int) $branch->getKey(), $warehouseId, $products);
    }

    /**
     * @param  Collection<int, Product>  $products
     * @return array{order: Order, customer_notice: ?string}
     */
    private function place(InstantOrderData $data, User $actor, int $branchId, int $warehouseId, Collection $products): array
    {
        return DB::transaction(function () use ($data, $actor, $branchId, $warehouseId, $products): array {
            if ($data->clientToken !== null) {
                // The employee's own row serialises their retries: the second waits here, then
                // finds what the first one wrote.
                User::query()->whereKey($actor->getKey())->lockForUpdate()->first();

                $placed = Order::withTrashed()
                    ->where('created_by', $actor->getKey())
                    ->where('client_token', $data->clientToken)
                    ->first();

                if ($placed !== null) {
                    return ['order' => $placed, 'customer_notice' => null];
                }
            }

            [$customer, $notice] = $this->customer($data);

            if (! $customer->is_active) {
                throw InstantOrderRefused::customerInactive((string) $customer->name);
            }

            $this->stock->assertAvailable($data->items, $products->keyBy('id'), $warehouseId);

            $order = ($this->createOrder)(
                new OrderData(
                    customerId: (int) $customer->getKey(),
                    cityId: $branchId,
                    notes: $data->notes,
                    discount: $data->discount,
                    items: $data->items,
                    clientToken: $data->clientToken,
                ),
                $actor,
                OrderStatus::New,
                OrderType::Instant,
            );

            // Stamped before the draw, as ChangeOrderStatus does at «جاهزة»: the reversal on a
            // cancel reads `fulfillment_warehouse_id` to know where the goods go back to.
            $order->forceFill([
                'stock_deducted_at' => now(),
                'fulfillment_warehouse_id' => $warehouseId,
            ])->save();

            ($this->deductStock)($order->load('items.product'), $warehouseId, (int) $actor->getKey());

            ($this->applyManufacturingRates)($order->load('items'), (int) $actor->getKey());
            ($this->recalculateCogs)($order);

            // An investor whose stock this was is owed for it now — the same announcement the
            // «جاهزة» draw makes.
            OrderStockDrawn::dispatch((int) $order->getKey());

            return ['order' => $order->refresh(), 'customer_notice' => $notice];
        });
    }

    /**
     * The customer this phone belongs to, with blanks filled — or a new one.
     *
     * An existing customer keeps what is on file (owner's decision, 2026-11-26): only an empty
     * address is filled, and when the typed name or city differs the employee is told which
     * details were used.
     *
     * @return array{0: Customer, 1: ?string}
     */
    private function customer(InstantOrderData $data): array
    {
        // **One number, one customer, even when two counters type it at once.** A lock on the
        // normalised number for this transaction: the second sale waits here, then finds the
        // customer the first one made instead of tripping the phone's unique index.
        DB::select('SELECT pg_advisory_xact_lock(hashtext(?))', [
            'instant-customer:'.PhoneNumber::normalise($data->customerPhone),
        ]);

        $existing = $this->customers->findByPhone($data->customerPhone, lock: true);

        if ($existing === null) {
            return [$this->customers->create(new CustomerData(
                name: $data->customerName,
                phone: PhoneNumber::normalise($data->customerPhone),
                // Optional at the counter: a customer created without one simply has no address.
                addressSupplied: $data->customerCityId !== null,
                cityId: $data->customerCityId,
                regionId: $data->customerRegionId,
            )), null];
        }

        $this->customers->fillMissingAddress($existing, $data->customerCityId, $data->customerRegionId);

        return [$existing, $this->differences($existing, $data)];
    }

    private function differences(Customer $customer, InstantOrderData $data): ?string
    {
        $parts = [];

        if (trim((string) $customer->name) !== $data->customerName) {
            $parts[] = "الاسم «{$customer->name}»";
        }

        // Only a city that was typed can differ; leaving it empty says nothing about the stored one.
        if ($data->customerCityId !== null
            && $customer->city_id !== null
            && (int) $customer->city_id !== $data->customerCityId) {
            $city = $customer->city()->value('name');
            $parts[] = 'المدينة «'.($city ?? '—').'»';
        }

        return $parts === []
            ? null
            : 'بيانات العميل المحفوظة تختلف عمّا كُتب، فاستُخدمت المحفوظة: '.implode('، ', $parts);
    }

    /**
     * Every line's product, refused by name if it may not be sold instantly.
     *
     * @return Collection<int, Product>
     *
     * @throws InstantOrderRefused
     */
    private function eligibleProducts(InstantOrderData $data): Collection
    {
        $products = Product::query()
            ->with(InstantSaleEligibility::RELATIONS)
            ->whereKey(array_map(fn ($item) => $item->productId, $data->items))
            ->get()
            ->keyBy('id');

        foreach ($data->items as $index => $item) {
            $product = $products->get($item->productId);

            if ($product === null) {
                throw InstantOrderRefused::productNotEligible($index, 'المنتج', 'غير موجود');
            }

            $variant = $product->variants->firstWhere('id', $item->productVariantId);
            $refusal = $this->eligibility->refusalFor($product, $variant);

            if ($refusal !== null) {
                throw InstantOrderRefused::productNotEligible($index, (string) $product->name, $refusal);
            }
        }

        return $products;
    }
}
