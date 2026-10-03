<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Carrier\Models\NawrisParcel;
use App\Domain\Carrier\Models\NawrisParcelOrder;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\Models\ExpenseCategory;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryMovement;
use App\Domain\Treasury\Models\TreasuryOperation;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «المصاريف» — every account's expenses on one page. TREASURY-DESIGN §٢١.
 *
 * Arrange - Act - Assert throughout.
 */
class ExpenseListTest extends TestCase
{
    use RefreshDatabase;

    private const SECRET = 'shared-secret';

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        config()->set('services.nawris.webhook_secret', self::SECRET);
        config()->set('services.nawris.webhook_ips', []);
        config()->set('services.nawris.log_channel', 'null');
    }

    /**
     * @param  list<PermissionName>  $permissions
     * @return array{0: User, 1: array<string, string>}
     */
    private function clerk(array $permissions = [
        PermissionName::ViewTreasury,
        PermissionName::RecordTreasuryOperations,
        PermissionName::ReverseTreasuryOperations,
        PermissionName::ManageTreasury,
        PermissionName::ViewOrders,
        PermissionName::SettleOrders,
    ]): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return [$user, ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken]];
    }

    private function defaultOf(AccountKind $kind): TreasuryAccount
    {
        return TreasuryAccount::query()->where('kind', $kind->value)->where('is_default', true)->firstOrFail();
    }

    private function category(string $name): ExpenseCategory
    {
        return ExpenseCategory::factory()->create(['name' => $name]);
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function deposit(array $headers, TreasuryAccount $account, string $amount): void
    {
        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit',
            'to_account_id' => $account->id,
            'amount' => $amount,
        ], $headers)->assertCreated();
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $extra
     */
    private function expense(array $headers, TreasuryAccount $from, string $amount, ExpenseCategory $category, array $extra = []): TreasuryOperation
    {
        $response = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'expense',
            'from_account_id' => $from->id,
            'amount' => $amount,
            'category_id' => $category->id,
        ] + $extra, $headers)->assertCreated();

        return TreasuryOperation::query()->findOrFail($response->json('data.id'));
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $query
     */
    private function list(array $headers, array $query = []): TestResponse
    {
        return $this->getJson('/api/v1/treasury/expenses?'.http_build_query($query), $headers);
    }

    public function test_expenses_from_every_account_are_listed_together_newest_first(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $rent = $this->category('إيجار');
        $cash = $this->defaultOf(AccountKind::Cash);
        $bank = $this->defaultOf(AccountKind::Bank);
        $this->deposit($headers, $cash, '1000');
        $this->deposit($headers, $bank, '1000');
        $this->expense($headers, $cash, '400', $rent, ['occurred_at' => now()->subDay()->toDateString()]);
        $this->expense($headers, $bank, '150', $rent);

        // Act
        $response = $this->list($headers);

        // Assert — deposits are not expenses; each line names its account
        $response->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.amount', '150.00')
            ->assertJsonPath('data.0.account.name', $bank->name)
            ->assertJsonPath('data.0.category.name', 'إيجار')
            ->assertJsonPath('data.1.account.name', $cash->name)
            ->assertJsonPath('meta.expenses_total', '550.00');
    }

    public function test_a_reversed_expense_is_listed_struck_through_and_left_out_of_the_total(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $rent = $this->category('إيجار');
        $cash = $this->defaultOf(AccountKind::Cash);
        $this->deposit($headers, $cash, '1000');
        $mistake = $this->expense($headers, $cash, '300', $rent);
        $this->expense($headers, $cash, '100', $rent);
        $this->postJson("/api/v1/treasury/operations/{$mistake->id}/reverse", ['reason' => 'خطأ'], $headers)
            ->assertCreated();

        // Act
        $response = $this->list($headers);

        // Assert — two lines, not three: the reversal's own line is not an expense of its own
        $response->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.1.amount', '300.00')
            ->assertJsonPath('data.1.is_reversed', true)
            ->assertJsonPath('data.0.is_reversed', false)
            ->assertJsonPath('meta.expenses_total', '100.00');
    }

    public function test_what_nawris_kept_at_settlement_is_an_expense(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $order = $this->deliveredByNawris('100.00');

        // Act
        $this->withHeaders($headers)->post("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Settled->value,
            'fields' => ['settlement_fee' => '10'],
        ])->assertOk();
        $response = $this->list($headers);

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.amount', '10.00')
            ->assertJsonPath('data.0.order_id', $order->id)
            ->assertJsonPath('data.0.category.name', ExpenseCategory::query()->where('code', ExpenseCategory::CARRIER_FEE)->value('name'));
    }

    public function test_an_investor_deal_expense_is_listed(): void
    {
        // Arrange — the line a deal expense posts; it has no operation of its own
        [, $headers] = $this->clerk();
        TreasuryMovement::factory()->create([
            'account_id' => $this->defaultOf(AccountKind::Cash)->id,
            'direction' => MovementDirection::Out,
            'kind' => MovementKind::Expense,
            'amount' => '75.00',
            'source_type' => AuditSubject::InvestorDealExpense->value,
        ]);

        // Act
        $response = $this->list($headers);

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.category', null)
            ->assertJsonPath('meta.expenses_total', '75.00');
    }

    public function test_the_period_category_and_account_filters_narrow_the_list_and_its_total(): void
    {
        // Arrange
        Carbon::setTestNow('2026-10-15 12:00:00');
        [, $headers] = $this->clerk();
        $rent = $this->category('إيجار');
        $fuel = $this->category('وقود');
        $cash = $this->defaultOf(AccountKind::Cash);
        $bank = $this->defaultOf(AccountKind::Bank);
        $this->deposit($headers, $cash, '5000');
        $this->deposit($headers, $bank, '5000');
        $this->expense($headers, $cash, '1000', $rent, ['occurred_at' => '2026-09-20']);
        $this->expense($headers, $cash, '40', $fuel, ['occurred_at' => '2026-10-02']);
        $this->expense($headers, $bank, '900', $rent, ['occurred_at' => '2026-10-05']);

        // Act
        $october = $this->list($headers, ['from' => '2026-10-01', 'to' => '2026-10-31']);
        $rentOnly = $this->list($headers, ['category_id' => $rent->id]);
        $cashOnly = $this->list($headers, ['account_id' => $cash->id, 'from' => '2026-10-01']);

        // Assert
        $october->assertOk()->assertJsonCount(2, 'data')->assertJsonPath('meta.expenses_total', '940.00');
        $rentOnly->assertOk()->assertJsonCount(2, 'data')->assertJsonPath('meta.expenses_total', '1900.00');
        $cashOnly->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('meta.expenses_total', '40.00');
    }

    public function test_the_list_is_paged_but_the_total_covers_every_page(): void
    {
        // Arrange
        [, $headers] = $this->clerk();
        $rent = $this->category('إيجار');
        $cash = $this->defaultOf(AccountKind::Cash);
        $this->deposit($headers, $cash, '1000');

        foreach (range(1, 3) as $i) {
            $this->expense($headers, $cash, '10', $rent);
        }

        // Act
        $response = $this->list($headers, ['per_page' => 2]);

        // Assert
        $response->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('meta.total', 3)
            ->assertJsonPath('meta.expenses_total', '30.00');
    }

    public function test_an_end_before_the_start_is_refused(): void
    {
        // Arrange
        [, $headers] = $this->clerk();

        // Act
        $response = $this->list($headers, ['from' => '2026-10-10', 'to' => '2026-10-01']);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('to');
    }

    public function test_without_treasury_view_the_list_is_forbidden(): void
    {
        // Arrange — a driver reads his own account, not the shop's expenses
        [, $headers] = $this->clerk([PermissionName::RecordTreasuryOperations]);

        // Act
        $response = $this->list($headers);

        // Assert
        $response->assertForbidden();
    }

    private function deliveredByNawris(string $collect): Order
    {
        $order = Order::factory()->create([
            'status' => OrderStatus::OutForDelivery,
            'items_total' => $collect,
            'delivery_price' => '0.00',
            'grand_total' => $collect,
        ]);

        $parcel = NawrisParcel::factory()->create([
            'reference' => 'ref-'.$order->id,
            'code' => 'CODE-'.$order->id,
            'amount_to_collect' => $collect,
            'delivery_price_deducted' => '0.00',
        ]);

        NawrisParcelOrder::factory()->create([
            'nawris_parcel_id' => $parcel->id,
            'order_id' => $order->id,
            'amount_to_collect' => $collect,
        ]);

        $this->withHeaders(['Authorization' => 'Bearer '.self::SECRET])->postJson('/api/v1/webhooks/nawris', [
            'remote_order_id' => 'ref-'.$order->id,
            'order_code' => 'CODE-'.$order->id,
            'to_status_code' => 7,
            'to_status_text' => 'تم التسليم',
            'order_price' => $collect,
        ])->assertOk();

        return $order->refresh();
    }
}
