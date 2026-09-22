<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Investor\Actions\DepositToFund;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Actions\RecordWalletEntry;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Investor\Support\FundDeal;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * الصندوقُ صفٌّ في جدول الصفقات، ولا يجوز أن يكون صفقةً على الشاشة.
 *
 * {@see FundDeal} يصفه: «صفٌّ واحد لا يُنشئه أحدٌ ولا يراه أحد،
 * ويُقفَل أبداً». وهو وصفٌ كان صحيحاً في النيّة وحدها — `DealListQuery` كان يعرضه مع الصفقات،
 * و`CloseInvestorDeal` كان يقبل إغلاقه. **ووقع ذلك فعلاً** على سيرفر التجربة في ٢٢ سبتمبر
 * ٢٠٢٦: أُغلق الصندوق، فأعاد الإقفالُ رأسَ مال ثلاثة مستثمرين (١٧٬٠٠٠) إلى محافظهم بصفوف
 * `release` بينما بقيت وحداتُهم قائمة، ثم صار كلُّ اشتراكٍ جديد يُرفض بـ«الصفقة FUND «مغلقة»».
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class TheFundIsNotADealTest extends TestCase
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
     * @param  list<PermissionName>  $permissions
     * @return array<string, string>
     */
    private function headersFor(array $permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** يسلّم المالَ على الطاولة أولاً، ثم يشترك به في الصندوق — حدثان في يومين. */
    private function deposit(Investor $investor, string $amount): void
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

        app(DepositToFund::class)(
            investorId: (int) $investor->id,
            amount: $amount,
            actorId: null,
        );
    }

    public function test_the_deals_screen_does_not_list_the_fund(): void
    {
        // Arrange — دفعةُ شراءٍ قديمة يراها المستخدم، والصندوقُ إلى جانبها في الجدول نفسه.
        $headers = $this->headersFor([PermissionName::ViewInvestors]);
        $legacy = InvestorDeal::factory()->create();
        app(FundDeal::class)();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/investor-deals');

        // Assert — صفٌّ واحد: الصفقة القديمة. والصندوقُ لا بابَ له من هنا، فلا زرَّ إغلاقٍ
        // يُضغط عليه بالخطأ.
        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.code', $legacy->code);
    }

    public function test_an_investors_own_page_does_not_list_the_fund_among_his_deals(): void
    {
        // Arrange — رجلٌ ماله في الصندوق وفي دفعةِ شراءٍ قديمة. وقسمُ «في الصفقات» على صفحته
        // كان يعرضهما صفَّين، وصفُّ الصندوق يفتح صفحةَ الصفقة بزرِّ إغلاقها — وهذا هو الباب
        // الذي أُغلق منه فعلاً: رابطُ قائمة الصفقات رُفع من الدرج، وبقي هذا مفتوحاً.
        $headers = $this->headersFor([PermissionName::ViewInvestors]);
        app(OpenInvestmentPeriod::class)(actorId: null);
        $investor = Investor::factory()->create();
        $this->deposit($investor, '3000.00');

        $legacy = InvestorDeal::factory()->open()->create();
        app(RecordWalletEntry::class)(
            new WalletEntryData(
                investorId: (int) $investor->id,
                type: WalletEntryType::Deposit,
                amount: '1000.00',
                method: 'cash',
            ),
            null,
        );
        app(RecordWalletEntry::class)(
            new WalletEntryData(
                investorId: (int) $investor->id,
                type: WalletEntryType::Allocation,
                amount: '1000.00',
                investorDealId: (int) $legacy->getKey(),
            ),
            null,
        );

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/investors/{$investor->id}");

        // Assert — صفقتُه القديمة وحدها. ومالُه في الصندوق لم يضِع من الشاشة: بابُه لوحةُ
        // الصندوق، وهي تقوله بوحداتٍ ونسبةٍ ورأسِ مال.
        $response->assertOk()
            ->assertJsonCount(1, 'data.balances.deals')
            ->assertJsonPath('data.balances.deals.0.investor_deal_id', (int) $legacy->getKey())
            ->assertJsonPath('data.balances.deals.0.capital', '1000.00');
    }

    public function test_the_fund_refuses_to_be_closed_and_keeps_everybodys_capital_where_it_is(): void
    {
        // Arrange — صندوقٌ حيّ فيه رأسُ مال مستثمرٍ اشترى به وحدات.
        $headers = $this->headersFor([PermissionName::ManageInvestors, PermissionName::ViewInvestors]);
        app(OpenInvestmentPeriod::class)(actorId: null);
        $investor = Investor::factory()->create();
        $this->deposit($investor, '3000.00');
        $fund = app(FundDeal::class)();

        // Act — المالكُ يضغط «إغلاق الصفقة» على الصندوق.
        $response = $this->withHeaders($headers)->postJson("/api/v1/investor-deals/{$fund->id}/close");

        // Assert — يُرفض، ويبقى مفتوحاً. ولا صفَّ `release` واحد: الإقفالُ كان يعيد رأسَ المال
        // إلى المحافظ وتبقى الوحداتُ قائمة، فيصير للرجل نصيبٌ في صندوقٍ لم يعد ماله فيه.
        $response->assertStatus(422)
            ->assertJsonPath('message', 'الصندوق ليس صفقةً تُغلَق — ما يُقفَل هو فترةُ الأرباح');

        $this->assertSame('open', $fund->refresh()->status->value);
        $this->assertNull($fund->closed_at);
        $this->assertSame(0, InvestorWalletEntry::query()
            ->where('investor_deal_id', $fund->getKey())
            ->where('type', WalletEntryType::Release)
            ->count());
    }

    public function test_a_real_purchase_lot_still_closes(): void
    {
        // Arrange — الحارسُ ضيّقٌ عمداً: الصفقاتُ القديمة (دفعاتُ الشراء) ما زالت تُغلق ببابها.
        $headers = $this->headersFor([PermissionName::ManageInvestors]);
        $legacy = InvestorDeal::factory()->open()->create();

        // Act
        $response = $this->withHeaders($headers)->postJson("/api/v1/investor-deals/{$legacy->id}/close");

        // Assert
        $response->assertOk();
        $this->assertSame('closed', $legacy->refresh()->status->value);
    }

    public function test_a_fund_that_was_already_closed_is_put_back_together(): void
    {
        // Arrange — حالُ سيرفر التجربة بعد ٢٢ سبتمبر: مالُ المستثمر رجع إلى محفظته بصفّ
        // `release`، وبقيت وحداتُه، والصندوقُ مغلق.
        app(OpenInvestmentPeriod::class)(actorId: null);
        $investor = Investor::factory()->create();
        $this->deposit($investor, '3000.00');
        $fund = app(FundDeal::class)();
        $closedAt = now();

        DB::table('investor_wallet_entries')->insert([
            'investor_id' => $investor->id,
            'investor_deal_id' => $fund->getKey(),
            'type' => WalletEntryType::Release->value,
            'amount' => '3000.00',
            'occurred_at' => $closedAt,
            'created_at' => $closedAt,
            'updated_at' => $closedAt,
        ]);
        DB::table('investor_deals')->where('id', $fund->getKey())
            ->update(['status' => 'closed', 'closed_at' => $closedAt]);

        $broken = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        self::assertSame('3000.00', $broken['wallet']['capital']);
        self::assertSame('0.00', $broken['deals'][$fund->getKey()]['capital']);

        // Act — الهجرةُ التصحيحية.
        $this->runTheRepairMigration();

        // Assert — الصندوقُ مفتوح، والمالُ عاد إليه بصفّ عكسٍ لا بمسحِ صفّ، والاشتراكُ يمرّ.
        $fund->refresh();
        self::assertSame('open', $fund->status->value);
        self::assertNull($fund->closed_at);

        $fixed = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        self::assertSame('0.00', $fixed['wallet']['capital']);
        self::assertSame('3000.00', $fixed['deals'][$fund->getKey()]['capital']);

        self::assertSame(1, InvestorWalletEntry::query()
            ->where('type', WalletEntryType::Reversal)->count());

        $newcomer = Investor::factory()->create();
        $this->deposit($newcomer, '1000.00');
        self::assertSame('1000.00', app(InvestorBalances::class)
            ->forInvestor((int) $newcomer->id)['deals'][$fund->getKey()]['capital']);
    }

    public function test_the_repair_leaves_an_honest_redemption_alone(): void
    {
        // Arrange — `release` على الصندوق ليس دائماً خطأ: هو بابُ الاسترداد أيضاً. صندوقٌ لم
        // يُغلق قطّ، وفيه استردادٌ حقيقي.
        app(OpenInvestmentPeriod::class)(actorId: null);
        $investor = Investor::factory()->create();
        $this->deposit($investor, '3000.00');
        $fund = app(FundDeal::class)();

        DB::table('investor_wallet_entries')->insert([
            'investor_id' => $investor->id,
            'investor_deal_id' => $fund->getKey(),
            'type' => WalletEntryType::Release->value,
            'amount' => '1000.00',
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Act
        $this->runTheRepairMigration();

        // Assert — لا عكسَ لشيء: الصندوقُ مفتوحٌ أصلاً، فالهجرةُ لا شأن لها به.
        self::assertSame(0, InvestorWalletEntry::query()
            ->where('type', WalletEntryType::Reversal)->count());
        self::assertSame('1000.00', app(InvestorBalances::class)
            ->forInvestor((int) $investor->id)['wallet']['capital']);
    }

    private function runTheRepairMigration(): void
    {
        (require database_path('migrations/2026_09_22_100000_undo_the_closing_of_the_fund.php'))->up();
    }
}
