<?php

declare(strict_types=1);

namespace Tests\Support;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductCategory;
use App\Domain\Catalog\Models\ProductPriceTier;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Delivery\Models\City;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\DTOs\StockMovementData;
use App\Domain\Inventory\InventoryService;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Inventory\Models\WarehouseStock;
use App\Domain\Order\Models\Order;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use Spatie\Permission\Models\Permission;

/**
 * A branch, its warehouse, plain stock on the shelf and an employee at the counter — what every
 * instant-order test starts from (INSTANT-ORDERS-PLAN.md).
 */
trait SellsAtTheCounter
{
    protected function registerPermissions(): void
    {
        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    protected function counterBranch(?Warehouse $warehouse = null, string $name = 'مكتب قرجي'): City
    {
        $branch = City::factory()->officePickup()->create(['name' => $name]);

        // The first branch's warehouse carries the plan's own example name; any further one is
        // named after its branch (warehouse names are unique).
        $warehouse ??= Warehouse::factory()->create([
            'name' => Warehouse::query()->where('name', 'مخزن بريمولا')->exists() ? 'مخزن '.$name : 'مخزن بريمولا',
        ]);

        $branch->forceFill(['default_warehouse_id' => $warehouse->getKey()])->save();

        return $branch->refresh();
    }

    /**
     * A plain product sold and stocked by the kilo, switched on for instant sale.
     *
     * @return array{0: Product, 1: ProductVariant}
     */
    protected function plainProduct(string $unitPrice = '10.000', string $name = 'أكياس شحن', string $label = '35×40'): array
    {
        $category = ProductCategory::factory()->skipsProduction()->create();

        $product = Product::factory()->perKilogram()->create([
            'name' => $name,
            'product_category_id' => $category->getKey(),
            'min_order_quantity' => 1,
            'is_instant_sale' => true,
        ]);

        $item = StockItem::factory()->unit(PricingUnit::Kilogram)->create();

        $variant = ProductVariant::factory()->drawingFrom($item)->create([
            'product_id' => $product->getKey(),
            'label' => $label,
        ]);

        ProductPriceTier::factory()->create([
            'product_variant_id' => $variant->getKey(),
            'min_quantity' => 1,
            'unit_price' => $unitPrice,
        ]);

        return [$product->refresh(), $variant->refresh()];
    }

    protected function stockUp(Warehouse|int $warehouse, ProductVariant $variant, string $quantity, string $unitCost = '5'): void
    {
        $keeper = User::factory()->create();

        app(InventoryService::class)->recordMovement(StockMovementData::arrival([
            'stock_item_id' => $variant->stock_item_id,
            'to_warehouse_id' => $warehouse instanceof Warehouse ? $warehouse->getKey() : $warehouse,
            'quantity' => $quantity,
            'unit_cost' => $unitCost,
        ], (int) $keeper->getKey()));
    }

    protected function shelf(int $warehouseId, ProductVariant $variant): string
    {
        return (string) (WarehouseStock::query()
            ->where('warehouse_id', $warehouseId)
            ->where('stock_item_id', $variant->stock_item_id)
            ->value('quantity') ?? '0.000');
    }

    /**
     * The branch's cash box and its bank account (for transfers and cards).
     *
     * @return array{cash: TreasuryAccount, bank: TreasuryAccount}
     */
    protected function branchAccounts(City $branch): array
    {
        $cash = TreasuryAccount::factory()->kind(AccountKind::Cash)->create(['name' => 'كاش '.$branch->name]);
        $cash->forceFill(['pickup_city_id' => $branch->getKey()])->save();

        $bank = TreasuryAccount::factory()->kind(AccountKind::Bank)->create(['name' => 'المصرف '.$branch->name]);

        $branch->forceFill([
            'bank_transfer_account_id' => $bank->getKey(),
            'bank_card_account_id' => $bank->getKey(),
        ])->save();

        return ['cash' => $cash->refresh(), 'bank' => $bank->refresh()];
    }

    /** An instant order taken through the API, as the counter would. */
    protected function takeInstantOrder(City $branch, User $employee, Product $product, ProductVariant $variant, string|int $quantity): Order
    {
        $response = $this->withHeaders($this->headersFor($employee))
            ->postJson('/api/v1/instant-orders', $this->sale($branch, [[$product, $variant, $quantity]]));

        $response->assertCreated();

        return Order::query()->findOrFail($response->json('data.id'));
    }

    /** An employee holding the seeded «موظف الفرع» role, assigned to these branches. */
    protected function branchEmployee(City ...$branches): User
    {
        $user = User::factory()->create();
        $user->assignRole('موظف الفرع');

        foreach ($branches as $branch) {
            $branch->employees()->attach($user->getKey());
        }

        return $user;
    }

    /** @return array<string, string> */
    protected function headersFor(User $user): array
    {
        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * @param  list<array{0: Product, 1: ProductVariant, 2: string|int|float}>  $lines
     * @param  array<string, mixed>  $customer
     * @return array<string, mixed>
     */
    protected function sale(City $branch, array $lines, array $customer = [], array $extra = []): array
    {
        $home = $customer['city_id'] ?? City::factory()->create()->getKey();

        return [
            'branch_id' => $branch->getKey(),
            'customer' => [
                'phone' => '0912345678',
                'name' => 'عميل الكاونتر',
                'city_id' => $home,
                ...$customer,
            ],
            'items' => array_map(fn (array $line): array => [
                'product_id' => $line[0]->getKey(),
                'product_variant_id' => $line[1]->getKey(),
                'quantity' => $line[2],
            ], $lines),
            ...$extra,
        ];
    }
}
