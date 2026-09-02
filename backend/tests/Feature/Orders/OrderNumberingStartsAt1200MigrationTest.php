<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use Illuminate\Foundation\Testing\DatabaseMigrations;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * الترحيل الذي يبدأ ترقيم الطلبيات من ١٢٠٠.
 *
 * The one thing worth proving about a renumbering is that nothing came loose while the keys were
 * moving: a line still belongs to its own order, the ledger still points at the order it emptied
 * the shelf for, and the next order carries on from the last rather than landing back at 1.
 *
 * So this rolls the migration back, puts real orders in front of it — with lines, and with a
 * stock movement naming one of them — and runs it forward, which is the sequence a real database
 * sees.
 *
 * `DatabaseMigrations` rather than `RefreshDatabase`: the migration runs DDL of its own, and the
 * transaction the other trait holds open has no business wrapping it.
 *
 * Arrange - Act - Assert.
 */
class OrderNumberingStartsAt1200MigrationTest extends TestCase
{
    use DatabaseMigrations;

    public function test_it_renumbers_existing_orders_from_1200_and_carries_their_lines_with_them(): void
    {
        // Arrange — back to the numbering that started at 1, and three orders taken in a known
        // sequence, each with a line of its own.
        Artisan::call('migrate:rollback', ['--step' => 1]);

        $orders = collect(range(1, 3))->map(fn () => Order::factory()->has(OrderItem::factory(), 'items')->create());

        $this->assertSame([1, 2, 3], $orders->pluck('id')->map(intval(...))->all());

        $lineOf = $orders->mapWithKeys(fn (Order $order) => [
            (int) $order->getKey() => (int) $order->items->first()->getKey(),
        ]);

        // Act
        Artisan::call('migrate');

        // Assert — the oldest order is 1200, the numbers follow the order they were taken in,
        // and each still answers to one number rather than two.
        $renumbered = Order::query()->orderBy('id')->get();

        $this->assertSame([1200, 1201, 1202], $renumbered->pluck('id')->map(intval(...))->all());
        $this->assertSame(['1200', '1201', '1202'], $renumbered->pluck('code')->all());

        // Assert — every line moved with its own order, not merely with some order.
        foreach ($renumbered->values() as $position => $order) {
            $wasNumbered = $position + 1;

            $this->assertSame(
                [$lineOf[$wasNumbered]],
                $order->items()->pluck('id')->map(intval(...))->all(),
            );
        }
    }

    public function test_the_next_order_taken_continues_from_the_last_renumbered_one(): void
    {
        // Arrange — one order under the old numbering, renumbered by the migration.
        Artisan::call('migrate:rollback', ['--step' => 1]);
        Order::factory()->create();
        Artisan::call('migrate');

        // Act — an order taken the ordinary way, through the allocation the model does itself.
        $next = Order::factory()->create();

        // Assert
        $this->assertSame(1201, (int) $next->getKey());
        $this->assertSame('1201', $next->code);
    }

    public function test_the_first_order_on_an_empty_database_is_1200(): void
    {
        // Arrange — nothing to renumber; the migration has already run with no orders behind it.
        $this->assertSame(0, Order::query()->count());

        // Act
        $first = Order::factory()->create();

        // Assert
        $this->assertSame(1200, (int) $first->getKey());
        $this->assertSame('1200', $first->code);
    }

    public function test_it_carries_the_stock_ledger_and_the_audit_trail_across(): void
    {
        // Arrange — an order under the old numbering with a fulfillment movement naming it, and
        // an arrival whose reference is a stock arrival that happens to carry the same number.
        Artisan::call('migrate:rollback', ['--step' => 1]);

        $order = Order::factory()->create();
        $warehouse = Warehouse::factory()->create();

        $fulfillment = StockMovement::factory()->fulfillment($warehouse)
            ->create(['reference_id' => $order->getKey()]);

        $arrival = StockMovement::factory()->arrival($warehouse)
            ->create(['reference_id' => $order->getKey()]);

        $auditEntry = DB::table('activity_log')->insertGetId([
            'log_name' => 'default',
            'description' => 'created',
            'subject_type' => 'order',
            'subject_id' => $order->getKey(),
            'event' => 'created',
            'properties' => '[]',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Act
        Artisan::call('migrate');

        // Assert — the fulfillment followed the order to its new number.
        $this->assertSame(1200, (int) $fulfillment->refresh()->reference_id);

        // Assert — the arrival did not: its reference names a stock arrival, and a number that
        // means something else must not be dragged along by a renumbering of orders.
        $this->assertSame(1, (int) $arrival->refresh()->reference_id);

        // Assert — the audit trail still names the order it was written about, and no entry is
        // left pointing at the number that order no longer answers to.
        $this->assertSame(
            1200,
            (int) DB::table('activity_log')->where('id', $auditEntry)->value('subject_id'),
        );

        $this->assertSame(
            0,
            DB::table('activity_log')->where('subject_type', 'order')->where('subject_id', 1)->count(),
        );
    }
}
