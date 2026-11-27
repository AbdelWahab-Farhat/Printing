<?php

declare(strict_types=1);

namespace Tests\Feature\InstantOrders;

use App\Domain\Customer\Models\Customer;
use App\Domain\Delivery\Models\City;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Enums\RoleName;
use App\Domain\Identity\Models\Role;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Inventory\Models\WarehouseStock;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Support\SellsAtTheCounter;
use Tests\TestCase;

/**
 * Everything around the counter: the branch settings, the home board, the late flag, the
 * «بانتظار التسليم» column, the filters and the sales split — INSTANT-ORDERS-PLAN.md §4, §8, §11, §13.
 */
class InstantOrderBoardsTest extends TestCase
{
    use RefreshDatabase;
    use SellsAtTheCounter;

    protected function setUp(): void
    {
        parent::setUp();

        $this->registerPermissions();
    }

    private function admin(): User
    {
        Role::findOrCreate(RoleName::Admin->value, 'web');

        $user = User::factory()->create();
        $user->assignRole(RoleName::Admin->value);

        return $user;
    }

    public function test_the_owner_sets_up_a_branch_and_past_orders_are_untouched(): void
    {
        // Arrange
        $branch = $this->counterBranch();
        $accounts = $this->branchAccounts($branch);
        [$product, $variant] = $this->plainProduct();
        $this->stockUp($branch->default_warehouse_id, $variant, '10');
        $employee = $this->branchEmployee($branch);
        $past = $this->takeInstantOrder($branch, $employee, $product, $variant, 2);

        $warehouse = Warehouse::factory()->create(['name' => 'المخزن الرئيسي']);
        $box = TreasuryAccount::factory()->kind(AccountKind::Cash)->create();
        $bank = TreasuryAccount::factory()->kind(AccountKind::Bank)->create();
        $newcomer = User::factory()->create();

        // Act
        $response = $this->withHeaders($this->headersFor($this->admin()))->putJson("/api/v1/branches/{$branch->id}", [
            'is_branch_active' => true,
            'default_warehouse_id' => $warehouse->id,
            'cash_account_id' => $box->id,
            'bank_transfer_account_id' => $bank->id,
            'bank_card_account_id' => null,
            'employee_ids' => [$newcomer->id],
        ]);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.default_warehouse.name', 'المخزن الرئيسي')
            ->assertJsonPath('data.cash_account.id', $box->id)
            ->assertJsonPath('data.bank_card_account', null)
            ->assertJsonPath('data.employees.0.id', $newcomer->id);

        $this->assertNull($accounts['cash']->refresh()->pickup_city_id, 'the old box lost the branch');
        $this->assertSame((int) $branch->id, (int) $box->refresh()->pickup_city_id);
        $this->assertNotSame((int) $warehouse->id, (int) $past->refresh()->fulfillment_warehouse_id, 'a past order keeps its warehouse');

        // The old employee is no longer assigned, so they may no longer sell there.
        $this->withHeaders($this->headersFor($employee))->getJson('/api/v1/instant-orders/branches')
            ->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_branch_accounts_must_fit_their_method(): void
    {
        $branch = $this->counterBranch();
        $bank = TreasuryAccount::factory()->kind(AccountKind::Bank)->create();

        $this->withHeaders($this->headersFor($this->admin()))->putJson("/api/v1/branches/{$branch->id}", [
            'is_branch_active' => true,
            'default_warehouse_id' => null,
            'cash_account_id' => $bank->id,
            'bank_transfer_account_id' => null,
            'bank_card_account_id' => null,
            'employee_ids' => [],
        ])->assertUnprocessable()->assertJsonValidationErrors('cash_account_id');
    }

    public function test_branch_settings_need_the_grant(): void
    {
        $branch = $this->counterBranch();
        $employee = $this->branchEmployee($branch);

        $this->withHeaders($this->headersFor($employee))->getJson('/api/v1/branches')->assertForbidden();
        $this->withHeaders($this->headersFor($employee))->putJson('/api/v1/branches/late-hours', ['instant_order_late_hours' => 2])
            ->assertForbidden();

        $this->withHeaders($this->headersFor($this->admin()))->putJson('/api/v1/branches/late-hours', ['instant_order_late_hours' => 6])
            ->assertOk()->assertJsonPath('data.instant_order_late_hours', 6);

        $this->withHeaders($this->headersFor($this->admin()))->getJson('/api/v1/branches')
            ->assertOk()->assertJsonPath('meta.instant_order_late_hours', 6);
    }

    public function test_the_home_board_counts_instant_orders_late_ones_and_my_branch_pickups(): void
    {
        // Arrange
        $branch = $this->counterBranch();
        $other = $this->counterBranch(name: 'مكتب ولي العهد');
        [$product, $variant] = $this->plainProduct();
        $this->stockUp($branch->default_warehouse_id, $variant, '20');
        $employee = $this->branchEmployee($branch);

        $fresh = $this->takeInstantOrder($branch, $employee, $product, $variant, 1);
        $old = $this->takeInstantOrder($branch, $employee, $product, $variant, 1);
        $old->forceFill(['placed_at' => now()->subHours(30)])->save();

        $customer = Customer::factory()->create();
        Order::factory()->forCustomer($customer)->officePickup()->status(OrderStatus::OfficePickup)->create(['city_id' => $branch->id]);
        Order::factory()->forCustomer($customer)->officePickup()->status(OrderStatus::OfficePickup)->create(['city_id' => $other->id]);

        // Act
        $board = $this->withHeaders($this->headersFor($employee))->getJson('/api/v1/home/summary')->assertOk()->json('data.instant');

        // Assert
        $this->assertTrue($board['can_create']);
        $this->assertSame([['id' => $branch->id, 'name' => 'مكتب قرجي']], $board['branches']);
        $this->assertSame(2, collect($board['statuses'])->firstWhere('status', 'new')['count']);
        $this->assertSame(1, $board['late_count']);
        $this->assertSame(24, $board['late_after_hours']);
        $this->assertSame(1, $board['pickup_count'], 'only my branch');

        // The list behind the late counter, and the flag on each order.
        $late = $this->withHeaders($this->headersFor($employee))->getJson('/api/v1/orders?late=1')->assertOk();
        $this->assertSame([$old->id], collect($late->json('data'))->pluck('id')->all());
        $this->assertTrue($late->json('data.0.is_late'));

        $this->withHeaders($this->headersFor($employee))->getJson("/api/v1/orders/{$fresh->id}")
            ->assertJsonPath('data.is_late', false)
            ->assertJsonPath('data.order_type_label', 'فورية');
    }

    public function test_the_home_board_is_absent_without_the_instant_grant(): void
    {
        $user = User::factory()->create();
        $user->givePermissionTo(PermissionName::ViewOrders->value);

        $this->withHeaders($this->headersFor($user))->getJson('/api/v1/home/summary')
            ->assertOk()->assertJsonMissingPath('data.instant');
    }

    public function test_the_orders_list_filters_by_type_warehouse_employee_and_payment_method(): void
    {
        // Arrange
        $branch = $this->counterBranch();
        $this->branchAccounts($branch);
        [$product, $variant] = $this->plainProduct();
        $this->stockUp($branch->default_warehouse_id, $variant, '20');
        $employee = $this->branchEmployee($branch);
        $instant = $this->takeInstantOrder($branch, $employee, $product, $variant, 1);
        $normal = Order::factory()->create();

        $this->withHeaders($this->headersFor($employee))->postJson("/api/v1/orders/{$instant->id}/status", [
            'status' => OrderStatus::Delivered->value,
            'fields' => ['payment_amount' => 10, 'payment_method' => 'cash'],
        ])->assertOk();

        $ids = fn (string $query) => collect($this->withHeaders($this->headersFor($employee))
            ->getJson('/api/v1/orders?'.$query)->assertOk()->json('data'))->pluck('id')->all();

        // Assert
        $this->assertSame([$instant->id], $ids('order_type=instant'));
        $this->assertContains($normal->id, $ids('order_type=normal'));
        $this->assertNotContains($instant->id, $ids('order_type=normal'));
        $this->assertSame([$instant->id], $ids('warehouse_id='.$branch->default_warehouse_id));
        $this->assertSame([$instant->id], $ids('created_by='.$employee->id));
        $this->assertSame([$instant->id], $ids('payment_method=cash'));
        $this->assertSame([], $ids('payment_method=bank_card'));
    }

    public function test_the_stock_list_shows_what_is_awaiting_handover_and_which_orders_hold_it(): void
    {
        // Arrange
        $branch = $this->counterBranch();
        $this->branchAccounts($branch);
        [$product, $variant] = $this->plainProduct();
        $this->stockUp($branch->default_warehouse_id, $variant, '20');
        $employee = $this->branchEmployee($branch);
        $waiting = $this->takeInstantOrder($branch, $employee, $product, $variant, 6);
        $collected = $this->takeInstantOrder($branch, $employee, $product, $variant, 4);

        $this->withHeaders($this->headersFor($employee))->postJson("/api/v1/orders/{$collected->id}/status", [
            'status' => OrderStatus::Delivered->value,
            'fields' => ['payment_amount' => 40, 'payment_method' => 'cash'],
        ])->assertOk();

        $keeper = User::factory()->create();
        $keeper->givePermissionTo(PermissionName::ViewInventory->value);
        $warehouseId = $branch->default_warehouse_id;

        // Act
        $line = $this->withHeaders($this->headersFor($keeper))->getJson("/api/v1/warehouses/{$warehouseId}/stocks")
            ->assertOk()->json('data.0');

        // Assert — 20 − 6 − 4 = 10 available, 6 still on the shelf for the waiting customer.
        $this->assertSame('10.000', $line['quantity']);
        $this->assertSame('6.000', $line['awaiting_handover']);

        $stock = WarehouseStock::query()->where('warehouse_id', $warehouseId)->sole();
        $orders = $this->withHeaders($this->headersFor($keeper))
            ->getJson("/api/v1/warehouses/{$warehouseId}/stocks/{$stock->id}/awaiting-handover")
            ->assertOk()->json('data');

        $this->assertSame([$waiting->id], collect($orders)->pluck('order_id')->all());
        $this->assertSame('6.000', $orders[0]['quantity']);
    }

    public function test_the_sales_board_counts_instant_sales_and_can_split_them_out(): void
    {
        // Arrange
        $branch = $this->counterBranch();
        $this->branchAccounts($branch);
        [$product, $variant] = $this->plainProduct('10.000');
        $this->stockUp($branch->default_warehouse_id, $variant, '20');
        $employee = $this->branchEmployee($branch);
        $sold = $this->takeInstantOrder($branch, $employee, $product, $variant, 3);
        $this->takeInstantOrder($branch, $employee, $product, $variant, 5); // never handed over

        $this->withHeaders($this->headersFor($employee))->postJson("/api/v1/orders/{$sold->id}/status", [
            'status' => OrderStatus::Delivered->value,
            'fields' => ['payment_amount' => 30, 'payment_method' => 'cash'],
        ])->assertOk();

        $reader = User::factory()->create();
        $reader->givePermissionTo(PermissionName::ViewSalesStatisticsReport->value);
        $today = now()->toDateString();

        // Act
        $all = $this->withHeaders($this->headersFor($reader))->getJson("/api/v1/reports/sales-statistics?from={$today}&to={$today}");
        $normalOnly = $this->withHeaders($this->headersFor($reader))->getJson("/api/v1/reports/sales-statistics?from={$today}&to={$today}&order_type=normal");

        // Assert
        $all->assertOk()->assertJsonPath('data.sales_value.total', '30.00');
        $normalOnly->assertOk()->assertJsonPath('data.sales_value.total', '0.00');
    }

    public function test_the_instant_sale_switch_is_saved_on_the_product(): void
    {
        [$product] = $this->plainProduct();

        $show = $this->withHeaders($this->headersFor($this->admin()))->getJson("/api/v1/products/{$product->id}");

        $show->assertOk()->assertJsonPath('data.is_instant_sale', true);
    }

    public function test_a_delivery_city_is_not_listed_as_a_branch(): void
    {
        $this->counterBranch();
        City::factory()->create();

        $this->withHeaders($this->headersFor($this->admin()))->getJson('/api/v1/branches')
            ->assertOk()->assertJsonCount(1, 'data');
    }
}
