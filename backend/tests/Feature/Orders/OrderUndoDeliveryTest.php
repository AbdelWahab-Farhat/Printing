<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Carrier\Enums\NawrisStatusCode;
use App\Domain\Carrier\Models\NawrisParcel;
use App\Domain\Carrier\Models\NawrisParcelOrder;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Investor\Actions\UnwindDealEarningsForOrder;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorDealShare;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Models\OrderStatusTransition;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * Taking back a delivery recorded by mistake.
 *
 * > **The order goes back exactly where it was delivered from, read from its timeline. The
 * > investors' profit comes off with it; the money taken at the door stays.**
 *
 * «تم الاستلام» keeps its one road forward on the map — this is an undo of one recorded move, like
 * the reinstatement of a cancellation. A partial delivery, a settled order and a delivery Nawris
 * reported are each refused, with the reason.
 *
 * Arrange - Act - Assert throughout.
 */
class OrderUndoDeliveryTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    /**
     * @return array<string, string>
     */
    private function auth(PermissionName ...$permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** Someone who marks orders delivered, and may say one was not. */
    private function dispatcher(): array
    {
        return $this->auth(
            PermissionName::ViewOrders,
            PermissionName::ViewOrderPayments,
            PermissionName::RecordOrderPayments,
            PermissionName::MarkOrdersDelivered,
            PermissionName::UndoOrderDelivery,
        );
    }

    /** An order delivered from `$from`, with the move on its timeline and one line on it. */
    private function delivered(OrderStatus $from = OrderStatus::OutForDelivery): Order
    {
        $order = Order::factory()->create([
            'status' => OrderStatus::Delivered,
            'delivered_at' => now(),
            'items_total' => '330.00',
            'delivery_price' => '0.00',
            'grand_total' => '330.00',
        ]);

        OrderItem::factory()->create(['order_id' => $order->getKey()]);

        OrderStatusTransition::factory()->create([
            'order_id' => $order->getKey(),
            'from_status' => $from,
            'to_status' => OrderStatus::Delivered,
        ]);

        return $order->refresh();
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function undo(array $headers, Order $order, ?string $reason = 'سُجّل التسليم على الطلبية الخطأ'): TestResponse
    {
        return $this->withHeaders($headers)->postJson(
            "/api/v1/orders/{$order->id}/undo-delivery",
            array_filter(['reason' => $reason]),
        );
    }

    // ─────────────────────────────── the undo itself ──────────────────────────────────

    public function test_it_puts_the_order_back_where_it_was_delivered_from(): void
    {
        // Arrange
        $order = $this->delivered(OrderStatus::OutForDelivery);

        // Act
        $response = $this->undo($this->dispatcher(), $order);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.status', OrderStatus::OutForDelivery->value)
            ->assertJsonPath('message', 'تم التراجع عن التسليم، وأُعيدت الطلبية إلى «'.OrderStatus::OutForDelivery->label().'»');

        $order->refresh();
        $this->assertSame(OrderStatus::OutForDelivery, $order->status);
        $this->assertNull($order->delivered_at);
    }

    public function test_an_order_collected_at_the_office_goes_back_to_the_office(): void
    {
        // Arrange — the destination is read, never chosen.
        $order = $this->delivered(OrderStatus::OfficePickup);

        // Act
        $this->undo($this->dispatcher(), $order)->assertOk();

        // Assert
        $this->assertSame(OrderStatus::OfficePickup, $order->refresh()->status);
    }

    public function test_an_order_that_was_settled_and_unsettled_goes_back_to_where_it_was_delivered_from(): void
    {
        // Arrange — the timeline of order 1258: «استلام مكتب» → «تم الاستلام» → «تم التسوية»,
        // then un-settled back to «تم الاستلام». The newest row into «تم الاستلام» is the
        // un-settlement, and it must not be mistaken for the delivery.
        $order = $this->delivered(OrderStatus::OfficePickup);
        OrderStatusTransition::factory()->create([
            'order_id' => $order->getKey(),
            'from_status' => OrderStatus::Delivered,
            'to_status' => OrderStatus::Settled,
        ]);
        OrderStatusTransition::factory()->create([
            'order_id' => $order->getKey(),
            'from_status' => OrderStatus::Settled,
            'to_status' => OrderStatus::Delivered,
        ]);

        // Act
        $offered = $this->withHeaders($this->dispatcher())->getJson("/api/v1/orders/{$order->id}");
        $this->undo($this->dispatcher(), $order)->assertOk();

        // Assert
        $offered->assertJsonPath('data.undo_delivery_to', OrderStatus::OfficePickup->value);
        $this->assertSame(OrderStatus::OfficePickup, $order->refresh()->status);
    }

    public function test_the_move_is_written_on_the_timeline_with_its_reason(): void
    {
        // Arrange
        $order = $this->delivered();

        // Act
        $this->undo($this->dispatcher(), $order, 'العميل لم يستلم بعد')->assertOk();

        // Assert
        $this->assertDatabaseHas('order_status_transitions', [
            'order_id' => $order->id,
            'from_status' => OrderStatus::Delivered->value,
            'to_status' => OrderStatus::OutForDelivery->value,
            'reason' => 'العميل لم يستلم بعد',
        ]);
    }

    public function test_it_demands_a_reason(): void
    {
        // Arrange
        $order = $this->delivered();

        // Act
        $response = $this->undo($this->dispatcher(), $order, null);

        // Assert
        $response->assertStatus(422)->assertJsonStructure(['errors' => ['reason']]);
        $this->assertSame(OrderStatus::Delivered, $order->refresh()->status);
    }

    public function test_the_grant_to_deliver_is_not_the_grant_to_undo(): void
    {
        // Arrange
        $order = $this->delivered();
        $headers = $this->auth(PermissionName::ViewOrders, PermissionName::MarkOrdersDelivered);

        // Act
        $response = $this->undo($headers, $order);

        // Assert
        $response->assertForbidden();
        $this->assertSame(OrderStatus::Delivered, $order->refresh()->status);
    }

    // ─────────────────────────────── what it refuses ──────────────────────────────────

    public function test_a_settled_order_is_sent_to_the_unsettle_first(): void
    {
        // Arrange
        $order = $this->delivered();
        $order->forceFill(['status' => OrderStatus::Settled])->save();

        // Act
        $response = $this->undo($this->dispatcher(), $order);

        // Assert
        $response->assertStatus(422);
        $this->assertStringContainsString('تراجع عن التسوية أولاً', (string) $response->json('message'));
        $this->assertSame(OrderStatus::Settled, $order->refresh()->status);
    }

    public function test_a_partial_delivery_is_refused(): void
    {
        // Arrange — some bags came back at the door and the invoice shrank.
        $order = $this->delivered();
        $order->items()->firstOrFail()->forceFill(['undelivered_quantity' => '50.000', 'undelivered_disposition' => 'restocked'])->save();

        // Act
        $response = $this->undo($this->dispatcher(), $order);

        // Assert
        $response->assertStatus(422);
        $this->assertSame(OrderStatus::Delivered, $order->refresh()->status);
    }

    public function test_a_delivery_nawris_reported_is_refused(): void
    {
        // Arrange
        $order = $this->delivered();
        $parcel = NawrisParcel::factory()->create([
            'code' => '3702994',
            'remote_status_code' => NawrisStatusCode::Delivered->value,
        ]);
        NawrisParcelOrder::factory()->create([
            'nawris_parcel_id' => $parcel->getKey(),
            'order_id' => $order->getKey(),
        ]);

        // Act
        $response = $this->undo($this->dispatcher(), $order);

        // Assert
        $response->assertStatus(422);
        $this->assertStringContainsString('3702994', (string) $response->json('message'));
        $this->assertSame(OrderStatus::Delivered, $order->refresh()->status);
    }

    // ─────────────────────────────── money around it ──────────────────────────────────

    public function test_the_investors_profit_comes_back_off(): void
    {
        // Arrange — the delivery credited a share of this order to an investor.
        $order = $this->delivered();
        $investor = Investor::factory()->create();
        // A deal he holds all of — the reversal splits by the same shares the posting did.
        $deal = InvestorDeal::factory()->open()->create(['investor_profit_share_percent' => '50.00']);
        InvestorDealShare::factory()->create([
            'investor_deal_id' => $deal->getKey(),
            'investor_id' => $investor->getKey(),
            'share_percent' => '100.00',
            'committed_amount' => '30000.00',
        ]);
        DB::table('investor_wallet_entries')->insert([
            'investor_id' => $investor->id,
            'investor_deal_id' => $deal->id,
            'type' => WalletEntryType::Profit->value,
            'amount' => '90.00',
            'source_type' => 'order',
            'source_id' => $order->id,
            'source_sequence' => 1,
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Act
        $this->undo($this->dispatcher(), $order)->assertOk();

        // Assert — reversed, and named for what happened rather than as a deletion.
        $balances = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        $this->assertSame('0.00', $balances['deals'][(int) $deal->id]['profit']);
        $this->assertDatabaseHas('investor_wallet_entries', [
            'investor_id' => $investor->id,
            'type' => WalletEntryType::Reversal->value,
            'notes' => UnwindDealEarningsForOrder::REASON_DELIVERY_UNDONE,
        ]);
    }

    public function test_money_taken_at_the_door_stays_on_the_ledger(): void
    {
        // Arrange
        $headers = $this->dispatcher();
        $order = $this->delivered();
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/payments", [
            'amount' => '330.00',
            'method' => PaymentMethod::Cash->value,
        ])->assertCreated();

        // Act
        $this->undo($headers, $order)->assertOk();

        // Assert
        $this->assertSame('330.00', (string) $order->refresh()->paid_amount);
        $this->assertDatabaseCount('order_payments', 1);
    }

    // ───────────────────────── the offer on the order ──────────────────────────────────

    public function test_the_order_names_where_the_undo_will_send_it(): void
    {
        // Arrange
        $order = $this->delivered(OrderStatus::OfficePickup);

        // Act
        $response = $this->withHeaders($this->dispatcher())->getJson("/api/v1/orders/{$order->id}");

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.undo_delivery_to', OrderStatus::OfficePickup->value)
            ->assertJsonPath('data.undo_delivery_to_label', OrderStatus::OfficePickup->label());
    }

    public function test_no_undo_is_offered_on_a_partial_delivery_or_without_the_grant(): void
    {
        // Arrange
        $partial = $this->delivered();
        $partial->items()->firstOrFail()->forceFill(['undelivered_quantity' => '50.000', 'undelivered_disposition' => 'restocked'])->save();
        $whole = $this->delivered();

        // Act & Assert
        $this->withHeaders($this->dispatcher())->getJson("/api/v1/orders/{$partial->id}")
            ->assertOk()->assertJsonPath('data.undo_delivery_to', null);
        $this->withHeaders($this->auth(PermissionName::ViewOrders))->getJson("/api/v1/orders/{$whole->id}")
            ->assertOk()->assertJsonPath('data.undo_delivery_to', null);
    }
}
