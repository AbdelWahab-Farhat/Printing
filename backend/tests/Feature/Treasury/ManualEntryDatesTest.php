<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Shortage\Models\Shortage;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasurySetting;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Vendor\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * تاريخُ المال الذي يُدخله إنسان — على كل شاشةٍ يخرج منها مالٌ أو يدخل، لا على شاشة الحسابات وحدها.
 *
 * **قاعدتان، والإصلاحُ أن تنطبقا في كل مكان.** «مقفل حتى تاريخ» في «إعدادات المالية» كانت تحرس
 * العمليات اليدوية ودفعة المورد وحدهما؛ فشراءُ نقصٍ أو مصروفُ صندوقٍ أو حركةُ محفظةٍ بتاريخٍ في
 * شهرٍ أُقفل كانت تدخله بلا سؤال. والثانية: **لا شيء يُؤرَّخ قبل آخر نقطة عدٍّ للحساب** —
 * رصيدُه الافتتاحي أو آخرُ «جرد الحساب». الجردُ شهادةُ المالك أن الدرج كان فيه كذا يومها، وحركةٌ
 * تُدسّ قبله تكذّبها بلا أثر.
 *
 * **والتاريخُ الذي هو يومٌ بلا ساعة** (`occurred_on` للنواقص، `incurred_on` للمصروف) يُقاس باليوم:
 * يُرفض في يومٍ قبل يوم الجرد، ويمرّ في يومه نفسه — فشراءُ اليوم لا يُردّ لأن الخزنة عُدّت صباحاً.
 *
 * وسحبُ المستثمر — رأسَ مالٍ أو ربحاً — مالٌ يخرج باليد، فيمنعه «منع الرصيد السالب» كالسحب من
 * شاشة الحسابات. أمّا شراءُ النقص والمصروف فلا: شراءٌ وقع فعلاً يُسجَّل ولو لم يكفِ الدرج.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class ManualEntryDatesTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        // يومٌ ثابت تُقاس منه كلُّ التواريخ أدناه.
        $this->travelTo(Carbon::parse('2026-10-15 12:00:00'));
    }

    /**
     * موظّفٌ يسجّل المال من كل شاشة.
     *
     * @return array<string, string>
     */
    private function clerk(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, [
            PermissionName::ViewTreasury,
            PermissionName::RecordTreasuryOperations,
            PermissionName::AdjustTreasuryBalances,
            PermissionName::ReverseTreasuryOperations,
            PermissionName::ManageTreasury,
            PermissionName::ViewVendorPayments,
            PermissionName::RecordVendorPayments,
            PermissionName::ViewShortages,
            PermissionName::RecordShortageSupplies,
            PermissionName::ViewInvestors,
            PermissionName::RecordInvestorMoney,
            PermissionName::RecordDealExpenses,
        ]));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function defaultOf(AccountKind $kind): TreasuryAccount
    {
        return TreasuryAccount::query()
            ->where('kind', $kind->value)
            ->where('is_default', true)
            ->firstOrFail();
    }

    private function balance(TreasuryAccount $account): string
    {
        return app(TreasuryService::class)->balanceOf($account);
    }

    private function lockUntil(string $day): void
    {
        TreasurySetting::current()->forceFill(['locked_until' => $day])->save();
    }

    private function setOverdraftBlock(bool $on): void
    {
        TreasurySetting::current()->forceFill(['block_overdraft' => $on])->save();
    }

    /**
     * «جرد الحساب» بتاريخٍ — أو الآن حين لا يُعطى.
     *
     * @param  array<string, string>  $headers
     */
    private function countDrawer(
        array $headers,
        TreasuryAccount $account,
        string $counted,
        ?string $on = null,
    ): int {
        return (int) $this->postJson('/api/v1/treasury/operations', array_filter([
            'type' => 'adjustment',
            'to_account_id' => $account->id,
            'counted_balance' => $counted,
            'notes' => 'جرد',
            'occurred_at' => $on,
        ]), $headers)->assertCreated()->json('data.id');
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function deposit(array $headers, TreasuryAccount $account, string $at): TestResponse
    {
        return $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit',
            'to_account_id' => $account->id,
            'amount' => '50',
            'occurred_at' => $at,
        ], $headers);
    }

    /**
     * شراءُ عشرة كيلو بمئة دينار نقداً، بيومه.
     *
     * @param  array<string, string>  $headers
     */
    private function supply(array $headers, Shortage $shortage, string $on): TestResponse
    {
        return $this->postJson("/api/v1/shortages/{$shortage->id}/supplies", [
            'quantity' => '10',
            'amount' => '100',
            'method' => 'cash',
            'occurred_on' => $on,
        ], $headers);
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function dealExpense(array $headers, InvestorDeal $deal, string $on): TestResponse
    {
        return $this->postJson("/api/v1/investor-deals/{$deal->id}/expenses", [
            'kind' => 'customs', 'name' => 'جمرك', 'amount' => '200', 'incurred_on' => $on,
        ], $headers);
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function fundExpense(array $headers, string $on): TestResponse
    {
        return $this->postJson('/api/v1/investment/expenses', [
            'kind' => 'shipping', 'name' => 'نقل', 'amount' => '200', 'incurred_on' => $on,
        ], $headers);
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, string>  $entry
     */
    private function wallet(array $headers, Investor $investor, array $entry): TestResponse
    {
        return $this->postJson("/api/v1/investors/{$investor->id}/wallet", $entry, $headers);
    }

    // ── «مقفل حتى تاريخ» على كل مسار ───────────────────────────────────────────────────

    public function test_a_shortage_purchase_dated_inside_the_locked_period_is_refused(): void
    {
        // Arrange — أُقفل الحساب حتى ١٠ أكتوبر.
        $headers = $this->clerk();
        $this->lockUntil('2026-10-10');
        $shortage = Shortage::factory()->create(['required_quantity' => '30.000']);

        // Act
        $inside = $this->supply($headers, $shortage, '2026-10-10');
        $after = $this->supply($headers, $shortage, '2026-10-11');

        // Assert — يومُ القفل نفسُه داخلَه، واليومُ الذي يليه حرّ.
        $inside->assertUnprocessable()->assertJsonValidationErrors('occurred_on');
        $after->assertCreated();
        $this->assertSame('-100.00', $this->balance($this->defaultOf(AccountKind::Cash)));
    }

    public function test_a_deal_or_fund_expense_dated_inside_the_locked_period_is_refused(): void
    {
        // Arrange
        $headers = $this->clerk();
        $this->lockUntil('2026-10-10');
        $deal = InvestorDeal::factory()->open()->create();

        // Act
        $dealInside = $this->dealExpense($headers, $deal, '2026-10-09');
        $fundInside = $this->fundExpense($headers, '2026-10-09');
        $fundAfter = $this->fundExpense($headers, '2026-10-12');

        // Assert
        $dealInside->assertUnprocessable()->assertJsonValidationErrors('incurred_on');
        $fundInside->assertUnprocessable()->assertJsonValidationErrors('incurred_on');
        $fundAfter->assertOk();
        $this->assertSame('-200.00', $this->balance($this->defaultOf(AccountKind::Cash)));
    }

    public function test_an_investor_cash_entry_dated_inside_the_locked_period_is_refused(): void
    {
        // Arrange
        $headers = $this->clerk();
        $this->lockUntil('2026-10-10');
        $investor = Investor::factory()->create();
        $cash = fn (string $type, string $amount, string $at) => $this->wallet(
            $headers,
            $investor,
            ['type' => $type, 'amount' => $amount, 'method' => 'cash', 'occurred_at' => $at],
        );

        // Act
        $depositInside = $cash('deposit', '1000', '2026-10-08T10:00');
        $depositAfter = $cash('deposit', '1000', '2026-10-11T10:00');
        $takenInside = $cash('withdrawal', '100', '2026-10-09T10:00');

        // Assert
        $depositInside->assertUnprocessable()->assertJsonValidationErrors('occurred_at');
        $depositAfter->assertCreated();
        $takenInside->assertUnprocessable()->assertJsonValidationErrors('occurred_at');
        $this->assertSame('1000.00', $this->balance($this->defaultOf(AccountKind::Cash)));
    }

    // ── سحبُ المستثمر لا يأخذ ما ليس في الدرج ─────────────────────────────────────────

    public function test_an_investor_capital_withdrawal_is_refused_past_the_drawer(): void
    {
        // Arrange — أودع في المصرف، والخزنة فارغة.
        $headers = $this->clerk();
        $investor = Investor::factory()->create();
        $this->wallet($headers, $investor, [
            'type' => 'deposit', 'amount' => '1000', 'method' => 'bank_transfer',
        ])->assertCreated();

        // Act
        $fromCash = $this->wallet($headers, $investor, [
            'type' => 'withdrawal', 'amount' => '300', 'method' => 'cash',
        ]);
        $fromBank = $this->wallet($headers, $investor, [
            'type' => 'withdrawal', 'amount' => '300', 'method' => 'bank_transfer',
        ]);

        // Assert
        $fromCash->assertUnprocessable()->assertJsonValidationErrors('amount');
        $fromBank->assertCreated();
        $this->assertSame('0.00', $this->balance($this->defaultOf(AccountKind::Cash)));
        $this->assertSame('700.00', $this->balance($this->defaultOf(AccountKind::Bank)));
    }

    public function test_an_investor_profit_withdrawal_is_refused_past_the_drawer(): void
    {
        // Arrange — ربحٌ أُفرج عنه في محفظته، والخزنة فارغة.
        $headers = $this->clerk();
        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->open()->create();
        $release = new InvestorWalletEntry(['amount' => '500.00', 'occurred_at' => now()]);
        $release->investor_id = $investor->id;
        $release->investor_deal_id = $deal->id;
        $release->type = WalletEntryType::ProfitRelease;
        $release->save();
        $payOut = ['type' => 'profit_withdrawal', 'amount' => '200', 'method' => 'cash'];

        // Act
        $blocked = $this->wallet($headers, $investor, $payOut);
        $this->setOverdraftBlock(false);
        $allowed = $this->wallet($headers, $investor, $payOut);

        // Assert — والمالكُ يملك أن يُطفئ المنع، كما في السحب من شاشة الحسابات.
        $blocked->assertUnprocessable()->assertJsonValidationErrors('amount');
        $allowed->assertCreated();
        $this->assertSame('-200.00', $this->balance($this->defaultOf(AccountKind::Cash)));
    }

    // ── لا شيء قبل آخر جرد ─────────────────────────────────────────────────────────────

    public function test_a_hand_operation_cannot_be_dated_before_the_accounts_latest_count(): void
    {
        // Arrange — عُدّت الخزنة يوم ١٢ أكتوبر، وجردٌ بيومٍ بلا ساعة يشهد بآخر ذلك اليوم.
        $headers = $this->clerk();
        $cash = $this->defaultOf(AccountKind::Cash);
        $this->countDrawer($headers, $cash, '1000', '2026-10-12');

        // Act
        $dayBefore = $this->deposit($headers, $cash, '2026-10-11T18:00:00');
        $sameDay = $this->deposit($headers, $cash, '2026-10-12T10:00:00');
        $dayAfter = $this->deposit($headers, $cash, '2026-10-13T09:00:00');

        // Assert
        $dayBefore->assertUnprocessable()->assertJsonValidationErrors('occurred_at');
        $sameDay->assertUnprocessable()->assertJsonValidationErrors('occurred_at');
        $dayAfter->assertCreated();
        $this->assertSame('1050.00', $this->balance($cash));
    }

    public function test_a_count_cannot_be_dated_before_the_previous_one(): void
    {
        // Arrange
        $headers = $this->clerk();
        $cash = $this->defaultOf(AccountKind::Cash);
        $this->countDrawer($headers, $cash, '1000', '2026-10-12');

        // Act
        $response = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'adjustment',
            'to_account_id' => $cash->id,
            'counted_balance' => '900',
            'notes' => 'جرد متأخر',
            'occurred_at' => '2026-10-11',
        ], $headers);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('occurred_at');
        $this->assertSame('1000.00', $this->balance($cash));
    }

    public function test_a_reversed_count_no_longer_holds_the_floor(): void
    {
        // Arrange — جردٌ أُدخل خطأً ثم عُكس.
        $headers = $this->clerk();
        $cash = $this->defaultOf(AccountKind::Cash);
        $count = $this->countDrawer($headers, $cash, '1000', '2026-10-12');
        $this->postJson("/api/v1/treasury/operations/{$count}/reverse", [
            'reason' => 'خطأ',
        ], $headers)->assertCreated();

        // Act
        $response = $this->deposit($headers, $cash, '2026-10-11T10:00:00');

        // Assert
        $response->assertCreated();
        $this->assertSame('50.00', $this->balance($cash));
    }

    public function test_a_vendor_payment_cannot_be_dated_before_the_accounts_latest_count(): void
    {
        // Arrange
        $headers = $this->clerk();
        $bank = $this->defaultOf(AccountKind::Bank);
        $this->countDrawer($headers, $bank, '5000', '2026-10-12');
        $vendor = Vendor::factory()->create();
        $pay = fn (string $at) => $this->postJson("/api/v1/vendors/{$vendor->id}/payments", [
            'amount' => '100', 'method' => 'bank_transfer', 'paid_at' => $at,
        ], $headers);

        // Act
        $before = $pay('2026-10-11T10:00:00');
        $after = $pay('2026-10-13T10:00:00');

        // Assert
        $before->assertUnprocessable()->assertJsonValidationErrors('paid_at');
        $after->assertCreated();
        $this->assertSame('4900.00', $this->balance($bank));
    }

    public function test_a_shortage_purchase_cannot_fall_on_a_day_before_the_latest_count(): void
    {
        // Arrange — عُدّت الخزنة هذا الصباح.
        $headers = $this->clerk();
        $cash = $this->defaultOf(AccountKind::Cash);
        $this->countDrawer($headers, $cash, '1000');
        $shortage = Shortage::factory()->create(['required_quantity' => '30.000']);

        // Act
        $yesterday = $this->supply($headers, $shortage, '2026-10-14');
        $today = $this->supply($headers, $shortage, '2026-10-15');

        // Assert — شراءُ اليوم يمرّ ولو عُدّ الدرجُ صباحاً.
        $yesterday->assertUnprocessable()->assertJsonValidationErrors('occurred_on');
        $today->assertCreated();
        $this->assertSame('900.00', $this->balance($cash));
    }

    public function test_a_deal_expense_cannot_fall_on_a_day_before_the_latest_count(): void
    {
        // Arrange
        $headers = $this->clerk();
        $cash = $this->defaultOf(AccountKind::Cash);
        $this->countDrawer($headers, $cash, '1000');
        $deal = InvestorDeal::factory()->open()->create();

        // Act
        $yesterday = $this->dealExpense($headers, $deal, '2026-10-14');
        $today = $this->dealExpense($headers, $deal, '2026-10-15');

        // Assert
        $yesterday->assertUnprocessable()->assertJsonValidationErrors('incurred_on');
        $today->assertOk();
        $this->assertSame('800.00', $this->balance($cash));
    }

    public function test_an_investor_cash_entry_cannot_be_dated_before_the_latest_count(): void
    {
        // Arrange
        $headers = $this->clerk();
        $cash = $this->defaultOf(AccountKind::Cash);
        $this->countDrawer($headers, $cash, '1000');
        $investor = Investor::factory()->create();

        // Act
        $backdated = $this->wallet($headers, $investor, [
            'type' => 'deposit',
            'amount' => '500',
            'method' => 'cash',
            'occurred_at' => '2026-10-14T10:00',
        ]);
        $now = $this->wallet($headers, $investor, [
            'type' => 'deposit', 'amount' => '500', 'method' => 'cash',
        ]);

        // Assert
        $backdated->assertUnprocessable()->assertJsonValidationErrors('occurred_at');
        $now->assertCreated();
        $this->assertSame('1500.00', $this->balance($cash));
    }
}
