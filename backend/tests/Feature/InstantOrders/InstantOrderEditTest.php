<?php

declare(strict_types=1);

namespace Tests\Feature\InstantOrders;

use App\Domain\Customer\Models\Customer;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Support\SellsAtTheCounter;
use Tests\TestCase;

/**
 * Editing an instant order while it is «جديدة», and handing over a normal pickup order in one's
 * own branch — INSTANT-ORDERS-PLAN.md §9–§10.
 */
class InstantOrderEditTest extends TestCase
{
    use RefreshDatabase;
    use SellsAtTheCounter;

    protected function setUp(): void
    {
        parent::setUp();

        $this->registerPermissions();
    }

    public function test_a_quantity_change_moves_only_the_difference_and_reprices(): void
    {
        // Arrange
        $branch = $this->counterBranch();
        [$product, $variant] = $this->plainProduct('10.000');
        $this->stockUp($branch->default_warehouse_id, $variant, '20');
        $employee = $this->branchEmployee($branch);
        $order = $this->takeInstantOrder($branch, $employee, $product, $variant, 15);
        $line = $order->items()->sole();

        // Act
        $this->withHeaders($this->headersFor($employee))->putJson("/api/v1/instant-orders/{$order->id}", [
            'items' => [['id' => $line->id, 'product_id' => $product->id, 'product_variant_id' => $variant->id, 'quantity' => 18]],
            'notes' => 'زاد ٣ كيلو',
        ])->assertOk();

        // Assert
        $order->refresh();
        $this->assertSame('180.00', (string) $order->grand_total);
        $this->assertSame('زاد ٣ كيلو', $order->notes);
        $this->assertSame('2.000', $this->shelf((int) $branch->default_warehouse_id, $variant));
        $this->assertSame((int) $line->id, (int) $order->items()->sole()->id, 'the line is kept, not replaced');
    }

    public function test_an_edit_counts_the_orders_own_stock_as_available_to_it(): void
    {
        $branch = $this->counterBranch();
        [$product, $variant] = $this->plainProduct('10.000', 'أكياس شحن', '35×40');
        $this->stockUp($branch->default_warehouse_id, $variant, '20');
        $employee = $this->branchEmployee($branch);
        $order = $this->takeInstantOrder($branch, $employee, $product, $variant, 15);
        $line = $order->items()->sole();

        $refused = $this->withHeaders($this->headersFor($employee))->putJson("/api/v1/instant-orders/{$order->id}", [
            'items' => [['id' => $line->id, 'product_id' => $product->id, 'product_variant_id' => $variant->id, 'quantity' => 25]],
        ])->assertUnprocessable();

        $this->assertSame(['أكياس شحن 35×40 — مخزن بريمولا: المطلوب 25 كجم، المتاح 20 كجم'], $refused->json('errors.items'));
        $this->assertSame('5.000', $this->shelf((int) $branch->default_warehouse_id, $variant), 'nothing moved');
    }

    public function test_lines_can_be_added_and_removed(): void
    {
        // Arrange
        $branch = $this->counterBranch();
        [$first, $firstSize] = $this->plainProduct('10.000');
        [$second, $secondSize] = $this->plainProduct('4.000', 'أكياس قمامة', '50×60');
        $this->stockUp($branch->default_warehouse_id, $firstSize, '20');
        $this->stockUp($branch->default_warehouse_id, $secondSize, '20');
        $employee = $this->branchEmployee($branch);
        $order = $this->takeInstantOrder($branch, $employee, $first, $firstSize, 5);

        // Act — drop the first product, take 3 of the second.
        $this->withHeaders($this->headersFor($employee))->putJson("/api/v1/instant-orders/{$order->id}", [
            'items' => [['product_id' => $second->id, 'product_variant_id' => $secondSize->id, 'quantity' => 3]],
        ])->assertOk();

        // Assert
        $order->refresh();
        $this->assertSame('12.00', (string) $order->grand_total);
        $this->assertSame('20.000', $this->shelf((int) $branch->default_warehouse_id, $firstSize));
        $this->assertSame('17.000', $this->shelf((int) $branch->default_warehouse_id, $secondSize));
    }

    public function test_only_a_new_order_is_edited_and_only_by_the_grant_at_ones_branch(): void
    {
        $branch = $this->counterBranch();
        $this->branchAccounts($branch);
        [$product, $variant] = $this->plainProduct('10.000');
        $this->stockUp($branch->default_warehouse_id, $variant, '20');
        $employee = $this->branchEmployee($branch);
        $order = $this->takeInstantOrder($branch, $employee, $product, $variant, 5);
        $payload = ['items' => [['product_id' => $product->id, 'product_variant_id' => $variant->id, 'quantity' => 4]]];

        $stranger = $this->branchEmployee($this->counterBranch(name: 'مكتب ولي العهد'));
        $this->withHeaders($this->headersFor($stranger))->putJson("/api/v1/instant-orders/{$order->id}", $payload)
            ->assertUnprocessable();

        $employee->roles()->detach();
        $employee->givePermissionTo([PermissionName::ViewOrders->value, PermissionName::CreateInstantOrders->value]);
        $this->withHeaders($this->headersFor($employee))->putJson("/api/v1/instant-orders/{$order->id}", $payload)
            ->assertForbidden();

        $seller = $this->branchEmployee($branch);
        $this->withHeaders($this->headersFor($seller))->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Delivered->value,
            'fields' => ['payment_amount' => 50, 'payment_method' => 'cash'],
        ])->assertOk();

        $this->withHeaders($this->headersFor($seller))->putJson("/api/v1/instant-orders/{$order->id}", $payload)
            ->assertUnprocessable();
    }

    public function test_a_branch_employee_hands_over_pickup_orders_at_their_own_branch_only(): void
    {
        // Arrange
        $mine = $this->counterBranch();
        $theirs = $this->counterBranch(name: 'مكتب ولي العهد');
        $employee = $this->branchEmployee($mine);
        $customer = Customer::factory()->create();

        $here = Order::factory()->forCustomer($customer)->officePickup()->status(OrderStatus::OfficePickup)->create(['city_id' => $mine->id]);
        $there = Order::factory()->forCustomer($customer)->officePickup()->status(OrderStatus::OfficePickup)->create(['city_id' => $theirs->id]);
        $printing = Order::factory()->forCustomer($customer)->status(OrderStatus::Printing)->create();

        // Act / Assert — every one of them is found and read.
        foreach ([$here, $there, $printing] as $order) {
            $this->withHeaders($this->headersFor($employee))->getJson("/api/v1/orders/{$order->id}")->assertOk();
        }

        $this->withHeaders($this->headersFor($employee))
            ->getJson('/api/v1/orders?search='.$there->code)
            ->assertOk()
            ->assertJsonPath('data.0.id', $there->id);

        // Only the order at their own branch offers — and accepts — the handover.
        $offered = fn (Order $order) => collect($this->withHeaders($this->headersFor($employee))
            ->getJson("/api/v1/orders/{$order->id}")->json('data.available_transitions'))->pluck('status')->all();

        $this->assertSame([OrderStatus::Delivered->value], $offered($here));
        $this->assertSame([], $offered($there));
        $this->assertSame([], $offered($printing));

        $this->withHeaders($this->headersFor($employee))->postJson("/api/v1/orders/{$there->id}/status", [
            'status' => OrderStatus::Delivered->value,
        ])->assertForbidden();

        $this->withHeaders($this->headersFor($employee))->postJson("/api/v1/orders/{$here->id}/status", [
            'status' => OrderStatus::Delivered->value,
        ])->assertOk();

        $this->assertSame(OrderStatus::Delivered, $here->refresh()->status);
    }
}
