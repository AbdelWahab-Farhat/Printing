<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Identity\Models\User;
use App\Domain\Investor\Actions\ReverseWalletEntry;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * عكسُ مالٍ من قبل الخزينة: لا حسابَ مختوماً عليه ولا حركةَ يُعكس ظلُّها، لكنّ يومَ الافتتاح عدّه في
 * رصيد حسابِ طريقته (§١١). فالعكسُ يصيب ذلك الحساب — المصرفَ لحوالة، لا الخزنةَ دائماً.
 *
 * Arrange - Act - Assert throughout.
 */
class ReversalFallbackTest extends TestCase
{
    use RefreshDatabase;

    private function defaultOf(AccountKind $kind): TreasuryAccount
    {
        return TreasuryAccount::query()->where('kind', $kind->value)->where('is_default', true)->firstOrFail();
    }

    private function balance(TreasuryAccount $account): string
    {
        return app(TreasuryService::class)->balanceOf($account);
    }

    public function test_reversing_an_old_bank_deposit_takes_it_out_of_the_bank_not_the_cash_box(): void
    {
        // Arrange — إيداعٌ بحوالة سُجّل قبل الخزينة
        $user = User::factory()->create();
        $deposit = InvestorWalletEntry::factory()->create([
            'type' => WalletEntryType::Deposit,
            'amount' => '1000.00',
            'method' => 'bank_transfer',
            'treasury_account_id' => null,
        ]);

        // Act
        app(ReverseWalletEntry::class)($deposit, (int) $user->id, 'إيداعٌ لم يصل');

        // Assert
        $this->assertSame('-1000.00', $this->balance($this->defaultOf(AccountKind::Bank)));
        $this->assertSame('0.00', $this->balance($this->defaultOf(AccountKind::Cash)));
    }

    public function test_reversing_an_old_bank_withdrawal_puts_it_back_in_the_bank(): void
    {
        // Arrange — سحبٌ بحوالة سُجّل قبل الخزينة
        $user = User::factory()->create();
        $withdrawal = InvestorWalletEntry::factory()->create([
            'type' => WalletEntryType::Withdrawal,
            'amount' => '400.00',
            'method' => 'bank_transfer',
            'treasury_account_id' => null,
        ]);

        // Act
        app(ReverseWalletEntry::class)($withdrawal, (int) $user->id, 'سحبٌ لم يُصرف');

        // Assert
        $this->assertSame('400.00', $this->balance($this->defaultOf(AccountKind::Bank)));
        $this->assertSame('0.00', $this->balance($this->defaultOf(AccountKind::Cash)));
    }
}
