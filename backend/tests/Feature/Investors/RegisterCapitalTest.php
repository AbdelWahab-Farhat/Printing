<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «رأس المال» في سجلّ المستثمرين هو رقمُ البطاقة الكبيرة على صفحته — المحفظةُ والصندوق.
 *
 * **لا ما بقي في صفقةٍ طُويت في الصندوق.** قرارُ المالك 2026-09-25: «اخفي صفقات سوف تغلق وتضاف
 * لربحه ومالناش علاقة بيها». الصفحةُ لا ترسم الصفقات، فسجلٌّ يعدّ باقيَها كان يقول 15,851
 * وصفحتُه 15,472.56 — السؤالُ نفسُه الذي بدأ منه هذا كلُّه. وحين تُقفَل الصفقةُ يرجع باقيها إلى
 * محفظته، فيعود إلى الرقم من هناك.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class RegisterCapitalTest extends TestCase
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
    private function headers(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(PermissionName::ViewInvestors->value);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** صفٌّ بين محفظته وصفقة — بلا طريقة دفع، كما يشترط قيدُ `_shape`. */
    private function move(Investor $investor, InvestorDeal $deal, WalletEntryType $type, string $amount): void
    {
        InvestorWalletEntry::factory()->create([
            'investor_id' => $investor->id,
            'investor_deal_id' => $deal->id,
            'type' => $type,
            'amount' => $amount,
            'method' => null,
        ]);
    }

    /**
     * ما جرى لعبدالرحمن مصغّراً: 1,000 في صفقةٍ قديمة، طُوي منها 900 في الصندوق، وبقي 100 على
     * طلبياتٍ لم تصل بعد.
     *
     * @return array{Investor, InvestorDeal}
     */
    private function foldedWithSomeLeftBehind(): array
    {
        $investor = Investor::factory()->create();
        $legacy = InvestorDeal::factory()->create(['folded_into_fund_at' => now()]);
        $fund = InvestorDeal::factory()->create();

        InvestorWalletEntry::factory()->create(['investor_id' => $investor->id, 'amount' => '1000.00']);
        $this->move($investor, $legacy, WalletEntryType::Allocation, '1000.00');
        $this->move($investor, $legacy, WalletEntryType::Release, '900.00');
        $this->move($investor, $fund, WalletEntryType::Allocation, '900.00');

        return [$investor, $legacy];
    }

    private function capitalOnTheRegister(Investor $investor): string
    {
        $response = $this->withHeaders($this->headers())->getJson('/api/v1/investors');

        $response->assertOk();

        return collect($response->json('data'))->firstWhere('id', $investor->id)['totals']['capital'];
    }

    public function test_what_waits_in_a_folded_deal_is_not_counted_in_his_capital(): void
    {
        // Arrange
        [$investor] = $this->foldedWithSomeLeftBehind();

        // Act
        $capital = $this->capitalOnTheRegister($investor);

        // Assert — 900 في الصندوق، لا 1,000.
        $this->assertSame('900.00', $capital);
    }

    public function test_it_is_counted_again_once_the_folded_deal_hands_it_back(): void
    {
        // Arrange — وصلت طلبياتُها وأُقفلت، فرجع الـ100 إلى محفظته.
        [$investor, $legacy] = $this->foldedWithSomeLeftBehind();
        $this->move($investor, $legacy, WalletEntryType::Release, '100.00');

        // Act
        $capital = $this->capitalOnTheRegister($investor);

        // Assert
        $this->assertSame('1000.00', $capital);
    }

    public function test_a_deal_that_was_never_folded_still_counts(): void
    {
        // Arrange — صفقةٌ قديمة لم تدخل الصندوق: مالُه فيها رأسُ ماله كما كان.
        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();

        InvestorWalletEntry::factory()->create(['investor_id' => $investor->id, 'amount' => '1000.00']);
        $this->move($investor, $deal, WalletEntryType::Allocation, '600.00');

        // Act
        $capital = $this->capitalOnTheRegister($investor);

        // Assert
        $this->assertSame('1000.00', $capital);
    }
}
