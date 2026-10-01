<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Support\FundDeal;
use App\Domain\Treasury\Models\TreasuryAccount;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * The dashboard's two read-only cards — whose the money is, and what the shelves are worth.
 * TREASURY-DESIGN §٩.
 *
 * Arrange - Act - Assert throughout.
 */
class TreasuryOverviewTest extends TestCase
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
    private function owner(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, [
            PermissionName::ViewTreasury,
            PermissionName::RecordTreasuryOperations,
            PermissionName::ViewInvestors,
            PermissionName::RecordInvestorMoney,
        ]));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    public function test_money_kept_for_an_investor_is_not_counted_as_the_company_s_own(): void
    {
        // Arrange — 10,000 on hand, of which 4,000 is an investor's deposit
        $headers = $this->owner();
        $investor = Investor::factory()->create(['name' => 'عبدالرحمن']);
        $cash = TreasuryAccount::query()->where('kind', 'cash')->where('is_default', true)->firstOrFail();

        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit', 'to_account_id' => $cash->id, 'amount' => '6000',
        ], $headers)->assertCreated();
        $this->postJson("/api/v1/investors/{$investor->id}/wallet", [
            'type' => 'deposit', 'amount' => '4000', 'method' => 'cash',
        ], $headers)->assertCreated();

        // Act
        $response = $this->getJson('/api/v1/treasury/ownership', $headers);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.total_held', '10000.00')
            ->assertJsonPath('data.investors_total', '4000.00')
            ->assertJsonPath('data.investors.0.name', 'عبدالرحمن')
            ->assertJsonPath('data.company_own', '6000.00');
    }

    public function test_the_shelves_are_valued_at_cost_split_between_the_company_and_the_fund(): void
    {
        // Arrange
        $headers = $this->owner();
        $warehouse = Warehouse::factory()->create(['name' => 'المخزن الرئيسي']);
        StockBatch::factory()->create([
            'warehouse_id' => $warehouse->id, 'unit_cost' => '2.000', 'quantity_remaining' => '100.000',
        ]);
        StockBatch::factory()->create([
            'warehouse_id' => $warehouse->id, 'unit_cost' => '5.000', 'quantity_remaining' => '10.000',
            'investor_deal_id' => app(FundDeal::class)()->getKey(),
        ]);
        StockBatch::factory()->create([
            'warehouse_id' => $warehouse->id, 'unit_cost' => '9.000', 'quantity_remaining' => '0.000',
        ]);

        // Act
        $response = $this->getJson('/api/v1/treasury/inventory-value', $headers);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.total', '250.00')
            ->assertJsonPath('data.company', '200.00')
            ->assertJsonPath('data.fund', '50.00')
            ->assertJsonPath('data.by_warehouse.0.name', 'المخزن الرئيسي')
            ->assertJsonPath('data.top_items.0.value', '200.00');
    }

    public function test_both_cards_need_the_treasury_grant(): void
    {
        // Arrange
        $user = User::factory()->create();
        $headers = ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];

        // Act & Assert
        $this->getJson('/api/v1/treasury/ownership', $headers)->assertForbidden();
        $this->getJson('/api/v1/treasury/inventory-value', $headers)->assertForbidden();
    }
}
