<?php

namespace Tests\Feature\Console;

use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Bringing orders taken before the whole-dinar rule into line, once, by hand.
 *
 * Arrange - Act - Assert throughout.
 */
class DropFractionsFromOrderTotalsTest extends TestCase
{
    use RefreshDatabase;

    /** 100 bags at 1.833: a line of 183.30 written the way it was before the rule. */
    private function order(
        OrderStatus $status = OrderStatus::ReadyToPrint,
        string $paid = '0.00',
        string $discount = '0.00',
    ): Order {
        $order = Order::factory()->status($status)->create([
            'items_total' => '183.30',
            'discount' => $discount,
            'grand_total' => bcsub('183.30', $discount, 2),
            'paid_amount' => $paid,
        ]);

        OrderItem::factory()->for($order)->create([
            'quantity' => '100.000',
            'unit_price' => '1.833',
            'line_total' => '183.30',
        ]);

        return $order->refresh();
    }

    public function test_an_open_order_loses_its_fraction_from_the_line_and_the_total(): void
    {
        // Arrange
        $order = $this->order(paid: '50.00');

        // Act
        $this->artisan('orders:drop-fractions', ['--force' => true])->assertSuccessful();

        // Assert
        $fresh = $order->fresh();
        $this->assertSame('183.00', (string) $fresh->items()->first()->line_total);
        $this->assertSame('183.00', (string) $fresh->items_total);
        $this->assertSame('183.00', (string) $fresh->grand_total);
        $this->assertSame('133.00', $fresh->remainingAmount());
    }

    public function test_a_dry_run_writes_nothing(): void
    {
        // Arrange
        $order = $this->order();

        // Act
        $this->artisan('orders:drop-fractions', ['--dry-run' => true])
            ->expectsOutputToContain('تجربة: 1 طلبية')
            ->assertSuccessful();

        // Assert
        $this->assertSame('183.30', (string) $order->fresh()->grand_total);
        $this->assertSame('183.30', (string) $order->fresh()->items()->first()->line_total);
    }

    public function test_closed_orders_are_left_exactly_as_they_stand(): void
    {
        // Arrange — each of these was billed, and paid or abandoned, to the fraction.
        $orders = collect([
            $this->order(OrderStatus::Delivered, paid: '183.30'),
            $this->order(OrderStatus::Settled, paid: '183.30'),
            $this->order(OrderStatus::Cancelled),
        ]);

        // Act
        $this->artisan('orders:drop-fractions', ['--force' => true])->assertSuccessful();

        // Assert
        $orders->each(fn (Order $order) => $this->assertSame('183.30', (string) $order->fresh()->grand_total));
    }

    public function test_a_parcel_out_with_the_courier_is_named_and_left(): void
    {
        // Arrange — the parcel holds a COD of 183.30, and that is what the customer will be asked.
        $order = $this->order(OrderStatus::OutForDelivery);

        // Act
        $this->artisan('orders:drop-fractions', ['--force' => true])
            ->expectsOutputToContain('مع المندوب')
            ->assertSuccessful();

        // Assert
        $this->assertSame('183.30', (string) $order->fresh()->grand_total);
    }

    public function test_an_order_paid_to_the_fraction_is_named_and_left(): void
    {
        // Arrange — dropping 0.30 here would invent a 0.30 refund.
        $order = $this->order(paid: '183.30');

        // Act
        $this->artisan('orders:drop-fractions', ['--force' => true])
            ->expectsOutputToContain('يتجاوز الإجمالي')
            ->assertSuccessful();

        // Assert
        $this->assertSame('183.30', (string) $order->fresh()->grand_total);
    }

    public function test_a_discount_that_no_longer_fits_is_named_and_left(): void
    {
        // Arrange — 183.30 off 183.30 cannot survive a total of 183.
        $order = $this->order(discount: '183.30');

        // Act
        $this->artisan('orders:drop-fractions', ['--force' => true])
            ->expectsOutputToContain('الخصم')
            ->assertSuccessful();

        // Assert
        $this->assertSame('183.30', (string) $order->fresh()->items_total);
    }

    public function test_running_it_twice_changes_nothing_more(): void
    {
        // Arrange
        $order = $this->order();
        $this->artisan('orders:drop-fractions', ['--force' => true])->assertSuccessful();
        $stamp = $order->fresh()->updated_at;

        // Act
        $this->artisan('orders:drop-fractions', ['--force' => true])
            ->expectsOutputToContain('تم: 0 طلبية')
            ->assertSuccessful();

        // Assert
        $this->assertEquals($stamp, $order->fresh()->updated_at);
    }
}
