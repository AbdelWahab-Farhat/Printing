<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorDealExpense;
use App\Domain\Investor\Models\InvestorDealSupply;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderCostRefund;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasurySetting;
use App\Domain\Treasury\Queries\ExpenseLedger;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Vendor\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «استرداد التكلفة» — money coming back on a cost paid outside the vendor's bill, cancelled orders
 * included. PURCHASE-ORDER-ARRIVAL-COSTS.md §7.
 *
 * Arrange - Act - Assert throughout.
 */
class PurchaseOrderCostRefundTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    /** @return array<string, string> */
    private function auth(PermissionName ...$permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));
        $this->app->get('auth')->forgetGuards();

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** @return array<string, string> */
    private function buyer(): array
    {
        return $this->auth(
            PermissionName::ViewPurchaseOrders,
            PermissionName::ManagePurchaseOrders,
            PermissionName::RecordTreasuryOperations,
        );
    }

    /** @return array<string, string> */
    private function receiver(): array
    {
        return $this->auth(
            PermissionName::ViewInventory,
            PermissionName::ManageInventory,
            PermissionName::RecordTreasuryOperations,
        );
    }

    /** @return array<string, string> */
    private function refunder(): array
    {
        return $this->auth(PermissionName::ReverseTreasuryOperations, PermissionName::ViewPurchaseOrders);
    }

    private function cash(): TreasuryAccount
    {
        return TreasuryAccount::query()
            ->where('kind', AccountKind::Cash->value)
            ->where('is_default', true)
            ->firstOrFail();
    }

    private function balance(TreasuryAccount $account): string
    {
        return app(TreasuryService::class)->balanceOf($account->refresh());
    }

    private function owedToVendor(Vendor $vendor): string
    {
        $id = app(TreasuryService::class)->payableIdOfVendor((int) $vendor->id);

        return $id === null
            ? '0.00'
            : bcmul($this->balance(TreasuryAccount::query()->findOrFail($id)), '-1', 2);
    }

    /**
     * @param  list<array<string, mixed>>  $costs
     * @return array<string, mixed>
     */
    private function order(Vendor $vendor, StockItem $shelf, array $costs = []): array
    {
        return $this->withHeaders($this->buyer())->postJson('/api/v1/purchase-orders', [
            'vendor_id' => $vendor->id,
            'warehouse_id' => Warehouse::factory()->create()->id,
            'order_date' => now()->toDateString(),
            'items' => [['stock_item_id' => $shelf->id, 'quantity_ordered' => 10, 'base_total_cost' => 100]],
            'additional_costs' => $costs,
        ])->assertCreated()->json('data');
    }

    /** @param  array<string, mixed>  $order */
    private function move(array $order, string $status): void
    {
        $this->withHeaders($this->buyer())
            ->patchJson("/api/v1/purchase-orders/{$order['id']}/status", ['status' => $status])
            ->assertOk();
    }

    /**
     * @param  array<string, mixed>  $order
     * @param  list<array<string, mixed>>  $costs
     */
    private function receive(array $order, StockItem $shelf, array $costs = []): void
    {
        $this->withHeaders($this->receiver())->postJson("/api/v1/purchase-orders/{$order['id']}/arrivals", [
            'items' => [['stock_item_id' => $shelf->id, 'quantity' => 10]],
            'additional_costs' => $costs,
        ])->assertCreated();
    }

    /** A drawer-paid 20 on an order, cancelled. @return array{0: array<string, mixed>, 1: int, 2: string} */
    private function cancelledOrder(Vendor $vendor): array
    {
        $before = $this->balance($this->cash());
        $order = $this->order($vendor, StockItem::factory()->create(), [
            ['name' => 'توصيل', 'amount' => 20, 'treasury_account_id' => $this->cash()->id],
        ]);
        $this->move($order, 'cancelled');

        return [$order, (int) $order['additional_costs'][0]['id'], $before];
    }

    /** @param  array<string, mixed>  $order */
    private function refund(array $order, int $costId, mixed $amount, string $reason = 'أعاد السائق المبلغ'): TestResponse
    {
        return $this->withHeaders($this->refunder())->postJson(
            "/api/v1/purchase-orders/{$order['id']}/additional-costs/{$costId}/refunds",
            ['amount' => $amount, 'reason' => $reason],
        );
    }

    /** @param  array<string, mixed>  $order */
    private function undo(array $order, int $costId, int $refundId): TestResponse
    {
        return $this->withHeaders($this->refunder())->postJson(
            "/api/v1/purchase-orders/{$order['id']}/additional-costs/{$costId}/refunds/{$refundId}/reversal",
            ['reason' => 'سُجّل بالخطأ'],
        );
    }

    /** @return array<string, mixed> */
    private function shown(array $order): array
    {
        return $this->withHeaders($this->auth(PermissionName::ViewPurchaseOrders))
            ->getJson("/api/v1/purchase-orders/{$order['id']}")
            ->assertOk()
            ->json('data');
    }

    // ─────────────────────────── cancelled orders ───────────────────────────

    public function test_cancelling_leaves_a_drawer_paid_cost_spent(): void
    {
        // Arrange + Act
        $vendor = Vendor::factory()->create();
        [$order, , $before] = $this->cancelledOrder($vendor);

        // Assert — the money left, and the cost says what can still come back
        $this->assertSame(bcsub($before, '20', 2), $this->balance($this->cash()));
        $this->assertSame('20.00', $this->shown($order)['additional_costs'][0]['refundable_amount']);
    }

    public function test_a_cancelled_orders_cost_refunds_in_full_to_the_drawer_that_paid(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        [$order, $costId, $before] = $this->cancelledOrder($vendor);

        // Act
        $response = $this->refund($order, $costId, 20);

        // Assert — the drawer is whole, the expense is out of «المصاريف», the row stays
        $response->assertOk()
            ->assertJsonPath('data.additional_costs.0.amount', '20.00')
            ->assertJsonPath('data.additional_costs.0.refundable_amount', '0.00')
            ->assertJsonPath('data.additional_costs.0.refunds.0.amount', '20.00')
            ->assertJsonPath('data.additional_costs.0.refunds.0.reason', 'أعاد السائق المبلغ')
            ->assertJsonPath('data.additional_costs.0.refunds.0.is_reversed', false);
        $this->assertSame($before, $this->balance($this->cash()));
        $this->assertSame('0.00', app(ExpenseLedger::class)->total([]));
        $this->assertSame('0.00', $this->owedToVendor($vendor));
    }

    public function test_a_cost_refunds_in_parts_and_never_past_what_is_left(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        [$order, $costId, $before] = $this->cancelledOrder($vendor);

        // Act + Assert
        $this->refund($order, $costId, '12.50')->assertOk();
        $this->assertSame('7.50', app(ExpenseLedger::class)->total([]));

        $this->refund($order, $costId, '7.51')->assertUnprocessable();
        $this->assertSame(bcsub($before, '7.50', 2), $this->balance($this->cash()));

        $this->refund($order, $costId, '7.50')->assertOk();
        $this->assertSame($before, $this->balance($this->cash()));

        $this->refund($order, $costId, '0.01')->assertUnprocessable();
        $this->assertSame(2, PurchaseOrderCostRefund::query()->count());
    }

    // ─────────────────────────── what it leaves alone ───────────────────────────

    public function test_a_refund_on_a_sent_order_moves_only_the_money(): void
    {
        // Arrange — 100 of goods, 20 delivery from the drawer
        $vendor = Vendor::factory()->create();
        $bags = StockItem::factory()->create();
        $order = $this->order($vendor, $bags, [
            ['name' => 'توصيل', 'amount' => 20, 'treasury_account_id' => $this->cash()->id],
        ]);
        $this->move($order, 'arrived');

        // Act
        $this->refund($order, (int) $order['additional_costs'][0]['id'], 5)->assertOk();

        // Assert — totals and the vendor's debt are untouched, and stay so through the receipt
        $saved = PurchaseOrder::query()->findOrFail($order['id']);
        $this->assertSame('120.00', (string) $saved->total_amount);
        $this->assertSame('100.00', (string) $saved->vendor_amount);
        $this->assertSame('100.00', $this->owedToVendor($vendor));

        $this->receive($order, $bags);
        $this->assertSame('100.00', $this->owedToVendor($vendor));
        $this->assertSame('12.000', (string) StockBatch::query()->where('stock_item_id', $bags->id)->firstOrFail()->unit_cost);
    }

    public function test_a_refund_on_a_completed_order_leaves_the_stock_cost(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $bags = StockItem::factory()->create();
        $before = $this->balance($this->cash());
        $order = $this->order($vendor, $bags);
        $this->receive($order, $bags, [
            ['name' => 'نقل', 'amount' => 30, 'treasury_account_id' => $this->cash()->id],
        ]);
        $costId = (int) $this->shown($order)['additional_costs'][0]['id'];

        // Act
        $this->refund($order, $costId, 10)->assertOk();

        // Assert
        $this->assertSame(bcsub($before, '20', 2), $this->balance($this->cash()));
        $this->assertSame('13.000', (string) StockBatch::query()->where('stock_item_id', $bags->id)->firstOrFail()->unit_cost);
        $this->assertSame('100.00', $this->owedToVendor($vendor));
    }

    public function test_only_the_companys_share_of_a_funded_cost_can_come_back(): void
    {
        // Arrange — A company, B funded; 40 from the drawer splits 20 / 20
        $vendor = Vendor::factory()->create();
        $a = StockItem::factory()->create();
        $b = StockItem::factory()->create();
        $order = $this->withHeaders($this->buyer())->postJson('/api/v1/purchase-orders', [
            'vendor_id' => $vendor->id,
            'warehouse_id' => Warehouse::factory()->create()->id,
            'order_date' => now()->toDateString(),
            'items' => [
                ['stock_item_id' => $a->id, 'quantity_ordered' => 10, 'base_total_cost' => 100],
                ['stock_item_id' => $b->id, 'quantity_ordered' => 10, 'base_total_cost' => 100],
            ],
        ])->assertCreated()->json('data');
        $deal = InvestorDeal::factory()->open()->create();
        $supply = new InvestorDealSupply;
        $supply->investor_deal_id = $deal->getKey();
        $supply->source_type = AuditSubject::PurchaseOrder->value;
        $supply->source_id = $order['id'];
        $supply->stock_item_id = $b->id;
        $supply->save();
        $this->withHeaders($this->receiver())->postJson("/api/v1/purchase-orders/{$order['id']}/arrivals", [
            'items' => [['stock_item_id' => $a->id, 'quantity' => 10], ['stock_item_id' => $b->id, 'quantity' => 10]],
            'additional_costs' => [['name' => 'نقل', 'amount' => 40, 'treasury_account_id' => $this->cash()->id]],
        ])->assertCreated();
        $cost = $this->shown($order)['additional_costs'][0];
        $this->assertSame('20.00', $cost['refundable_amount']);

        // Act + Assert — past the company's 20 is refused; the deal's expense stands untouched
        $this->refund($order, (int) $cost['id'], 21)->assertUnprocessable();
        $this->refund($order, (int) $cost['id'], 20)->assertOk();
        $expense = InvestorDealExpense::query()->where('investor_deal_id', $deal->id)->sole();
        $this->assertFalse($expense->isReversed());
    }

    public function test_a_cost_owed_to_a_payable_comes_off_the_debt(): void
    {
        // Arrange — «علينا 45» to the broker
        $vendor = Vendor::factory()->create();
        $bags = StockItem::factory()->create();
        $broker = TreasuryAccount::factory()->kind(AccountKind::Payable)->create(['name' => 'المخلّص الجمركي']);
        $order = $this->order($vendor, $bags, [
            ['name' => 'جمارك', 'amount' => 45, 'treasury_account_id' => $broker->id],
        ]);
        $this->move($order, 'cancelled');

        // Act
        $this->refund($order, (int) $order['additional_costs'][0]['id'], 45)->assertOk();

        // Assert
        $this->assertSame('0.00', $this->balance($broker));
    }

    public function test_reversing_the_receipt_after_a_refund_returns_only_what_is_left(): void
    {
        // Arrange — 30 paid on arrival, 10 of it already refunded
        $vendor = Vendor::factory()->create();
        $bags = StockItem::factory()->create();
        $before = $this->balance($this->cash());
        $order = $this->order($vendor, $bags);
        $this->receive($order, $bags, [
            ['name' => 'نقل', 'amount' => 30, 'treasury_account_id' => $this->cash()->id],
        ]);
        $costId = (int) $this->shown($order)['additional_costs'][0]['id'];
        $this->refund($order, $costId, 10)->assertOk();

        // Act
        $this->withHeaders($this->receiver())->postJson(
            "/api/v1/purchase-orders/{$order['id']}/receipt-reversal",
            ['reason' => 'استُلمت على الأمر الخطأ'],
        )->assertOk();

        // Assert — whole again, not 10 over
        $this->assertSame($before, $this->balance($this->cash()));
        $this->assertSame('100.00', $this->owedToVendor($vendor));
    }

    // ─────────────────────────── taking a refund back ───────────────────────────

    public function test_a_refund_taken_back_makes_the_expense_stand_again(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        [$order, $costId, $before] = $this->cancelledOrder($vendor);
        $refundId = (int) $this->refund($order, $costId, 20)->json('data.additional_costs.0.refunds.0.id');

        // Act
        $response = $this->undo($order, $costId, $refundId);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.additional_costs.0.refundable_amount', '20.00')
            ->assertJsonPath('data.additional_costs.0.refunds.0.is_reversed', true)
            ->assertJsonPath('data.additional_costs.0.refunds.0.reversal_reason', 'سُجّل بالخطأ');
        $this->assertSame(bcsub($before, '20', 2), $this->balance($this->cash()));
        $this->assertSame('20.00', app(ExpenseLedger::class)->total([]));

        // And twice is refused, with the money where it was.
        $this->undo($order, $costId, $refundId)->assertUnprocessable();
        $this->assertSame(bcsub($before, '20', 2), $this->balance($this->cash()));
    }

    public function test_a_part_refund_taken_back_leaves_the_other_standing(): void
    {
        // Arrange — 5 and 7 refunded of 20
        $vendor = Vendor::factory()->create();
        [$order, $costId, $before] = $this->cancelledOrder($vendor);
        $this->refund($order, $costId, 5)->assertOk();
        $newest = (int) $this->refund($order, $costId, 7)->json('data.additional_costs.0.refunds.0.id');

        // Act
        $this->undo($order, $costId, $newest)->assertOk();

        // Assert — 15 still spent
        $this->assertSame(bcsub($before, '15', 2), $this->balance($this->cash()));
    }

    // ─────────────────────────── refusals ───────────────────────────

    public function test_a_new_order_is_edited_rather_than_refunded(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $order = $this->order($vendor, StockItem::factory()->create(), [
            ['name' => 'توصيل', 'amount' => 20, 'treasury_account_id' => $this->cash()->id],
        ]);

        // Act + Assert
        $this->refund($order, (int) $order['additional_costs'][0]['id'], 20)->assertUnprocessable();
        $this->assertSame(0, PurchaseOrderCostRefund::query()->count());
    }

    public function test_a_cost_on_the_vendors_bill_has_nothing_to_refund(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $order = $this->order($vendor, StockItem::factory()->create(), [['name' => 'توصيل', 'amount' => 20]]);
        $this->move($order, 'cancelled');

        // Act + Assert
        $this->refund($order, (int) $order['additional_costs'][0]['id'], 20)->assertUnprocessable();
    }

    public function test_it_needs_the_reverse_grant(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        [$order, $costId] = $this->cancelledOrder($vendor);

        // Act + Assert
        $this->withHeaders($this->buyer())->postJson(
            "/api/v1/purchase-orders/{$order['id']}/additional-costs/{$costId}/refunds",
            ['amount' => 20, 'reason' => 'أعاد السائق المبلغ'],
        )->assertForbidden();
    }

    public function test_it_needs_to_be_able_to_read_the_order_it_answers_with(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        [$order, $costId] = $this->cancelledOrder($vendor);

        // Act + Assert
        $this->withHeaders($this->auth(PermissionName::ReverseTreasuryOperations))->postJson(
            "/api/v1/purchase-orders/{$order['id']}/additional-costs/{$costId}/refunds",
            ['amount' => 20, 'reason' => 'أعاد السائق المبلغ'],
        )->assertForbidden();
        $this->assertSame(0, PurchaseOrderCostRefund::query()->count());
    }

    public function test_it_needs_a_reason_and_a_sane_amount(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        [$order, $costId] = $this->cancelledOrder($vendor);

        // Act + Assert
        $this->refund($order, $costId, 20, '')->assertUnprocessable()->assertJsonValidationErrors('reason');
        $this->refund($order, $costId, 0)->assertUnprocessable()->assertJsonValidationErrors('amount');
        $this->refund($order, $costId, '1.234')->assertUnprocessable()->assertJsonValidationErrors('amount');
    }

    public function test_another_orders_cost_is_not_found(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        [$order] = $this->cancelledOrder($vendor);
        [, $otherCostId] = $this->cancelledOrder($vendor);

        // Act + Assert
        $this->refund($order, $otherCostId, 20)->assertNotFound();
    }

    public function test_a_locked_day_refuses_it(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        [$order, $costId] = $this->cancelledOrder($vendor);
        TreasurySetting::current()->forceFill(['locked_until' => now()->toDateString()])->save();

        // Act + Assert
        $this->refund($order, $costId, 20)->assertUnprocessable();
    }

    public function test_the_refund_is_on_the_orders_history(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        [$order, $costId] = $this->cancelledOrder($vendor);
        $refundId = (int) $this->refund($order, $costId, 20)->json('data.additional_costs.0.refunds.0.id');

        // Act
        $subjects = PurchaseOrder::query()->findOrFail($order['id'])->auditTrailSubjects();

        // Assert
        $this->assertContains($refundId, $subjects[AuditSubject::PurchaseOrderCostRefund->value]);
    }
}
