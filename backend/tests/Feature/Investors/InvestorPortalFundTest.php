<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Actions\DepositToFund;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Actions\RecordWalletEntry;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\Investor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * بوابةُ المستثمر — ما يقرؤه صاحبُ المال عن حصّته في الصندوق.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class InvestorPortalFundTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    public function test_a_fresh_subscriber_is_told_his_share_starts_next_period(): void
    {
        // Arrange — اكتتب في نافذة فترةٍ بدأت، فنصيبُه منها صفر ومن التالية كامل: «تجمد نسبته
        // ولا تحسب له أرباح شهر تسعة». وصفرٌ وحده على بوابته يُقرأ ضياعاً لماله.
        Carbon::setTestNow('2026-09-01 09:00:00');
        app(OpenInvestmentPeriod::class)(actorId: null);

        $founder = Investor::factory()->create();
        $this->subscribe($founder, '3000.00');

        Carbon::setTestNow('2026-10-02 09:00:00');
        app(CloseInvestmentPeriod::class)(actorId: null, overrideReason: null);
        app(OpenInvestmentPeriod::class)(actorId: null);

        $user = User::factory()->create();
        $user->givePermissionTo(PermissionName::ViewInvestorPortal->value);
        $newcomer = Investor::factory()->create(['user_id' => $user->id]);
        $this->subscribe($newcomer, '1000.00');

        // Act
        $response = $this->withHeaders([
            'Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken,
        ])->getJson('/api/v1/investor-portal/summary');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.fund.share_percent', '0.000000')
            ->assertJsonPath('data.fund.share_starts_next_period', true)
            ->assertJsonPath('data.fund.units', '1000.000000');
    }

    private function subscribe(Investor $investor, string $amount): void
    {
        app(RecordWalletEntry::class)(
            new WalletEntryData(
                investorId: (int) $investor->id,
                type: WalletEntryType::Deposit,
                amount: $amount,
                method: 'cash',
            ),
            null,
        );

        app(DepositToFund::class)(investorId: (int) $investor->id, amount: $amount, actorId: null);
    }
}
