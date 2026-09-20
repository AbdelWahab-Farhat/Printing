<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Investor\DTOs\DealExpenseData;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\CapitalRequestStatus;
use App\Domain\Investor\Enums\DealExpenseKind;
use App\Domain\Investor\Enums\ReturnedGoodsVerdict;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\InvestorService;
use App\Domain\Investor\Models\InvestmentCapitalRequest;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestmentRealizedEarning;
use App\Domain\Investor\Models\InvestmentReturnedGoodsQuestion;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorDealShare;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Investor\Support\MinimumTerm;
use App\Domain\Settings\Models\CompanySetting;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «الحد الأدنى للبقاء» — how long capital must stay before it may be asked back.
 *
 * **The default is zero, and zero is the behaviour that existed before this setting.** A man could
 * join in January, take his share of January's profit, and have his capital back at the same
 * close. Nothing in the design ever settled that; the owner has now, and these tests are what say
 * so.
 *
 * The properties that matter:
 *
 * 1. Zero changes nothing — an exit may still be asked for the day the money goes in.
 * 2. Inside the term, an exit is **refused**, and the refusal names the date.
 * 3. After the term, it is allowed and queues as before.
 * 4. **A top-up does not restart the clock** — the term runs from his *first* capital, or paying
 *    more in would be a reason to be locked in longer.
 * 5. **Money that left and came back starts again**, because it is new money.
 * 6. Capital coming **in** is never gated by it.
 * 7. An exit already queued is **not** stranded by lengthening the term afterwards.
 *
 * Arrange - Act - Assert throughout.
 */
class MinimumTermTest extends TestCase
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
    private function banker(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo([
            PermissionName::ViewInvestors->value,
            PermissionName::ManageInvestors->value,
            PermissionName::RecordInvestorMoney->value,
        ]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function term(int $months): void
    {
        CompanySetting::query()->whereKey(CompanySetting::SINGLETON_ID)
            ->update(['minimum_term_months' => $months]);
    }

    /** A pool with an open period. */
    private function pool(): InvestorDeal
    {
        $pool = InvestorDeal::factory()->pool()->create();

        InvestmentPeriod::factory()->create([
            'investor_deal_id' => $pool->getKey(),
            'starts_on' => Carbon::today()->startOfMonth()->toDateString(),
            'ends_on' => Carbon::today()->endOfMonth()->toDateString(),
        ]);

        return $pool->refresh();
    }

    /** Puts `$amount` of an investor's money into the pool, dated `$on`. */
    private function fund(
        Investor $investor,
        InvestorDeal $pool,
        string $amount,
        ?Carbon $on = null,
    ): void {
        $service = app(InvestorService::class);
        $at = $on ?? Carbon::now();

        Carbon::setTestNow($at);

        $service->recordWalletEntry(new WalletEntryData(
            investorId: (int) $investor->getKey(),
            type: WalletEntryType::Deposit,
            amount: $amount,
            method: 'cash',
        ), null);

        $service->recordWalletEntry(new WalletEntryData(
            investorId: (int) $investor->getKey(),
            type: WalletEntryType::Allocation,
            amount: $amount,
            investorDealId: (int) $pool->getKey(),
        ), null);

        Carbon::setTestNow();
    }

    private function askToLeave(InvestorDeal $pool, Investor $investor, string $amount = '10000.00')
    {
        return $this->withHeaders($this->banker())
            ->postJson("/api/v1/investment-pools/{$pool->getKey()}/capital-requests", [
                'investor_id' => $investor->getKey(),
                'direction' => 'out',
                'amount' => $amount,
            ]);
    }

    public function test_zero_months_is_the_behaviour_that_existed_before(): void
    {
        // Arrange — the default. Nothing changes until somebody sets a term.
        $this->term(0);
        $pool = $this->pool();
        $investor = Investor::factory()->create();
        $this->fund($investor, $pool, '100000.00');

        // Act — asked for the same day the money went in
        $response = $this->askToLeave($pool, $investor);

        // Assert
        $response->assertCreated();
        $this->assertSame(
            CapitalRequestStatus::Pending,
            InvestmentCapitalRequest::query()->firstOrFail()->status,
        );
    }

    public function test_an_exit_inside_the_term_is_refused(): void
    {
        // Arrange — six months, money in two months ago
        $this->term(6);
        $pool = $this->pool();
        $investor = Investor::factory()->create();
        $this->fund($investor, $pool, '100000.00', Carbon::now()->subMonthsNoOverflow(2));

        // Act
        $response = $this->askToLeave($pool, $investor);

        // Assert — refused, and nothing queued
        $response->assertStatus(422);
        $this->assertSame(0, InvestmentCapitalRequest::query()->count());
    }

    public function test_the_refusal_names_the_date_he_becomes_free(): void
    {
        // Arrange — «لا يمكنك السحب» with no date is a refusal somebody has to come back and ask
        // about
        $this->term(6);
        $pool = $this->pool();
        $investor = Investor::factory()->create();
        $since = Carbon::now()->subMonthsNoOverflow(2);
        $this->fund($investor, $pool, '100000.00', $since);

        // Act
        $response = $this->askToLeave($pool, $investor);

        // Assert
        $response->assertStatus(422);
        $this->assertStringContainsString(
            $since->copy()->addMonthsNoOverflow(6)->toDateString(),
            (string) $response->json('message'),
        );
    }

    public function test_after_the_term_the_exit_queues_as_before(): void
    {
        // Arrange
        $this->term(6);
        $pool = $this->pool();
        $investor = Investor::factory()->create();
        $this->fund($investor, $pool, '100000.00', Carbon::now()->subMonthsNoOverflow(7));

        // Act
        $response = $this->askToLeave($pool, $investor);

        // Assert
        $response->assertCreated();
        $this->assertSame(
            CapitalRequestStatus::Pending,
            InvestmentCapitalRequest::query()->firstOrFail()->status,
        );
    }

    public function test_a_top_up_does_not_restart_the_clock(): void
    {
        // Arrange — **the trap.** Measured from the latest deposit, paying more into a pool would
        // be a reason to be locked in longer, which is the opposite of what a minimum term means.
        $this->term(6);
        $pool = $this->pool();
        $investor = Investor::factory()->create();

        $this->fund($investor, $pool, '100000.00', Carbon::now()->subMonthsNoOverflow(7));
        $this->fund($investor, $pool, '50000.00', Carbon::now()->subDays(3));

        // Act
        $response = $this->askToLeave($pool, $investor);

        // Assert — the first stake is what counts, and it has matured
        $response->assertCreated();
    }

    public function test_money_that_left_and_came_back_starts_again(): void
    {
        // Arrange — he took everything out, then put new money in last week. It is new money, and
        // measuring it from a January he has no capital left from would be a fiction.
        $this->term(6);
        $pool = $this->pool();
        $investor = Investor::factory()->create();

        $this->fund($investor, $pool, '100000.00', Carbon::now()->subMonthsNoOverflow(9));

        // Written directly rather than through the service: `release` is not recordable by hand —
        // the close writes it — and this test is about how the term reads a ledger, not about who
        // may write to one.
        InvestorWalletEntry::factory()->create([
            'investor_id' => $investor->getKey(),
            'investor_deal_id' => $pool->getKey(),
            'type' => WalletEntryType::Release,
            'amount' => '100000.00',
            'method' => null,
            'occurred_at' => Carbon::now()->subMonthsNoOverflow(8),
        ]);

        $this->fund($investor, $pool, '40000.00', Carbon::now()->subWeek());

        // Act
        $response = $this->askToLeave($pool, $investor);

        // Assert — the clock runs from the return, so he is locked
        $response->assertStatus(422);
    }

    public function test_capital_coming_in_is_never_gated(): void
    {
        // Arrange — the term is about taking money out. Refusing a deposit would be absurd.
        $this->term(12);
        $pool = $this->pool();
        $investor = Investor::factory()->create();

        app(InvestorService::class)->recordWalletEntry(new WalletEntryData(
            investorId: (int) $investor->getKey(),
            type: WalletEntryType::Deposit,
            amount: '50000.00',
            method: 'cash',
        ), null);

        // Act
        $response = $this->withHeaders($this->banker())
            ->postJson("/api/v1/investment-pools/{$pool->getKey()}/capital-requests", [
                'investor_id' => $investor->getKey(),
                'direction' => 'in',
                'amount' => '50000.00',
            ]);

        // Assert
        $response->assertCreated();
    }

    public function test_lengthening_the_term_does_not_strand_a_queued_exit(): void
    {
        // Arrange — an exit already asked for was legitimate the day it was made. A settings
        // change decides what happens next; it never rewrites what already did.
        $this->term(0);
        $pool = $this->pool();
        $investor = Investor::factory()->create();
        $this->fund($investor, $pool, '100000.00');

        $this->askToLeave($pool, $investor)->assertCreated();

        // Act — the owner lengthens the term afterwards
        $this->term(12);

        // Assert — the standing request is untouched and still pending
        $this->assertSame(
            CapitalRequestStatus::Pending,
            InvestmentCapitalRequest::query()->firstOrFail()->status,
        );
    }

    public function test_the_screen_is_told_the_same_date_the_guard_enforces(): void
    {
        // Arrange — the date shown before he presses anything and the date that then refuses him
        // come from one function, so they cannot disagree.
        $this->term(6);
        $pool = $this->pool();
        $investor = Investor::factory()->create();
        $since = Carbon::now()->subMonthsNoOverflow(2);
        $this->fund($investor, $pool, '100000.00', $since);

        // Act
        $shown = MinimumTerm::freeOn((int) $investor->getKey(), (int) $pool->getKey(), 6);
        $response = $this->askToLeave($pool, $investor);

        // Assert
        $this->assertNotNull($shown);
        $this->assertStringContainsString(
            $shown->toDateString(),
            (string) $response->json('message'),
        );
    }

    public function test_one_partner_cannot_empty_the_till_by_asking_first(): void
    {
        // Arrange — **the property the ceiling is proportional for.** Two partners, half each. The
        // pool holds 40,000 in cash and 60,000 in stock. Whoever queues first must not be able to
        // take all 40,000 and leave the other waiting on a lorry selling.
        $this->term(0);
        $pool = $this->pool();

        $first = Investor::factory()->create(['name' => 'أحمد']);
        $second = Investor::factory()->create(['name' => 'علي']);

        $this->fund($first, $pool, '50000.00');
        $this->fund($second, $pool, '50000.00');

        $this->putOnTheShelf($pool, '6000.000', '10.000');

        // Both ask for everything they have.
        $this->askToLeave($pool, $first, '50000.00')->assertCreated();
        $this->askToLeave($pool, $second, '50000.00')->assertCreated();

        // Act
        app(InvestorService::class)->closePeriod($this->openPeriodOf($pool), null);

        // Assert — neither is paid, because each may draw at most his half of 40,000 and both
        // asked for 50,000. Crucially the **first** did not drain it.
        $this->assertSame(
            0,
            InvestmentCapitalRequest::query()
                ->where('status', CapitalRequestStatus::Applied->value)
                ->count(),
        );

        $balances = app(InvestorBalances::class);
        $this->assertSame(
            '50000.00',
            $balances->forShare((int) $first->getKey(), (int) $pool->getKey())['capital'],
        );
        $this->assertSame(
            '50000.00',
            $balances->forShare((int) $second->getKey(), (int) $pool->getKey())['capital'],
        );
    }

    public function test_a_partner_may_take_his_own_slice_of_the_cash(): void
    {
        // Arrange — the same pool, but he asks for what is actually his to take: half of the
        // 40,000 that is not on a shelf.
        $this->term(0);
        $pool = $this->pool();

        $first = Investor::factory()->create(['name' => 'أحمد']);
        $second = Investor::factory()->create(['name' => 'علي']);

        $this->fund($first, $pool, '50000.00');
        $this->fund($second, $pool, '50000.00');

        $this->putOnTheShelf($pool, '6000.000', '10.000');

        $this->askToLeave($pool, $first, '20000.00')->assertCreated();

        // Act
        app(InvestorService::class)->closePeriod($this->openPeriodOf($pool), null);

        // Assert — paid, and the other partner's money is untouched
        $this->assertSame(
            1,
            InvestmentCapitalRequest::query()
                ->where('status', CapitalRequestStatus::Applied->value)
                ->count(),
        );

        $balances = app(InvestorBalances::class);
        $this->assertSame(
            '30000.00',
            $balances->forShare((int) $first->getKey(), (int) $pool->getKey())['capital'],
        );
        $this->assertSame(
            '50000.00',
            $balances->forShare((int) $second->getKey(), (int) $pool->getKey())['capital'],
        );
    }

    /** Turns some of the pool's money into goods, so its cash is less than its capital. */
    private function putOnTheShelf(InvestorDeal $pool, string $quantity, string $unitCost): void
    {
        StockBatch::factory()->create([
            'stock_item_id' => StockItem::factory()->create()->getKey(),
            'investor_deal_id' => $pool->getKey(),
            'unit_cost' => $unitCost,
            'quantity_received' => $quantity,
            'quantity_remaining' => $quantity,
        ]);
    }

    private function openPeriodOf(InvestorDeal $pool): InvestmentPeriod
    {
        return InvestmentPeriod::query()
            ->where('investor_deal_id', $pool->getKey())
            ->firstOrFail();
    }

    public function test_the_company_is_not_bound_by_the_term(): void
    {
        // Arrange — **the exemption is the point, not a special case.** The term stops a partner
        // taking a month's profit and leaving with his capital. The company is the operator: it
        // absorbs the losses that run past what a partner put in, and its money in the pool is
        // working capital it has to be able to move.
        $this->term(12);
        $pool = $this->pool();

        $company = Investor::factory()->create(['name' => 'الشركة', 'is_company' => true]);
        $partner = Investor::factory()->create(['name' => 'أحمد']);

        $this->fund($company, $pool, '100000.00');
        $this->fund($partner, $pool, '100000.00');

        // Act — both ask on the day their money went in
        $companyAsked = $this->askToLeave($pool, $company);
        $partnerAsked = $this->askToLeave($pool, $partner);

        // Assert — the house may move its own money; the partner may not
        $companyAsked->assertCreated();
        $partnerAsked->assertStatus(422);
    }

    public function test_the_company_is_still_capped_by_its_slice_of_the_cash(): void
    {
        // Arrange — exempt from the calendar, **not** from the arithmetic. It cannot take money
        // that is sitting on a shelf any more than anybody else can.
        $this->term(12);
        $pool = $this->pool();

        $company = Investor::factory()->create(['name' => 'الشركة', 'is_company' => true]);
        $partner = Investor::factory()->create(['name' => 'أحمد']);

        $this->fund($company, $pool, '50000.00');
        $this->fund($partner, $pool, '50000.00');

        $this->putOnTheShelf($pool, '6000.000', '10.000');

        // Its whole stake — more than its half of the 40,000 that is not on a shelf.
        $this->askToLeave($pool, $company, '50000.00')->assertCreated();

        // Act
        app(InvestorService::class)->closePeriod($this->openPeriodOf($pool), null);

        // Assert — not paid, and its capital is untouched
        $this->assertSame(
            0,
            InvestmentCapitalRequest::query()
                ->where('status', CapitalRequestStatus::Applied->value)
                ->count(),
        );
        $this->assertSame(
            '50000.00',
            app(InvestorBalances::class)
                ->forShare((int) $company->getKey(), (int) $pool->getKey())['capital'],
        );
    }

    public function test_putting_money_in_puts_him_on_the_roster(): void
    {
        // Arrange — **the bug this test exists for.** A صفقة wrote its roster when the deal was
        // struck; a صندوق has no such moment, so the row has to be written where the money moves.
        // Without it the capital was right and the pool's «الشركاء» list was empty.
        $this->term(0);
        $pool = $this->pool();
        $investor = Investor::factory()->create(['name' => 'أحمد']);

        // Act
        $this->fund($investor, $pool, '50000.00');

        // Assert
        $share = InvestorDealShare::query()
            ->where('investor_deal_id', $pool->getKey())
            ->where('investor_id', $investor->getKey())
            ->first();

        $this->assertNotNull($share, 'putting money in did not add him to the roster');
        $this->assertNotNull($share->joined_at);
        // Null, not zero and not an even split: a pool's ownership is worked out per period from
        // capital, and a number here could only ever be read as a term somebody agreed.
        $this->assertNull($share->share_percent);
    }

    public function test_topping_up_is_not_joining_again(): void
    {
        // Arrange — he has been in the pool since March; adding more today does not change that,
        // and must not create a second row.
        $this->term(0);
        $pool = $this->pool();
        $investor = Investor::factory()->create(['name' => 'أحمد']);

        $this->fund($investor, $pool, '50000.00', Carbon::now()->subMonthsNoOverflow(6));
        $joinedAt = InvestorDealShare::query()
            ->where('investor_deal_id', $pool->getKey())
            ->where('investor_id', $investor->getKey())
            ->firstOrFail()
            ->joined_at;

        // Act
        $this->fund($investor, $pool, '20000.00');

        // Assert
        $rows = InvestorDealShare::query()
            ->where('investor_deal_id', $pool->getKey())
            ->where('investor_id', $investor->getKey())
            ->get();

        $this->assertCount(1, $rows);
        $this->assertSame(
            $joinedAt?->toDateTimeString(),
            $rows->first()?->joined_at?->toDateTimeString(),
        );
    }

    public function test_the_pool_screen_names_each_partner_and_what_he_holds(): void
    {
        // Arrange — a roster without amounts answers «من معنا؟» and leaves «بكم؟» unanswered.
        $this->term(0);
        $pool = $this->pool();

        $first = Investor::factory()->create(['name' => 'أحمد']);
        $second = Investor::factory()->create(['name' => 'علي']);

        $this->fund($first, $pool, '60000.00');
        $this->fund($second, $pool, '40000.00');

        // Act
        $response = $this->withHeaders($this->banker())
            ->getJson("/api/v1/investment-pools/{$pool->getKey()}");

        // Assert
        $response->assertOk();

        $investors = $response->json('data.investors');
        $this->assertCount(2, $investors);

        $byName = [];
        foreach ($investors as $row) {
            $byName[$row['name']] = $row;
        }

        $this->assertSame('60000.00', $byName['أحمد']['capital']);
        $this->assertSame('40000.00', $byName['علي']['capital']);
    }

    public function test_queued_capital_joins_the_roster_when_it_lands_not_when_it_is_asked(): void
    {
        // Arrange — outside the grace window his money stays in his own wallet. He is not in the
        // pool while it sits there, so the roster must not claim he is.
        $this->term(0);
        CompanySetting::query()->whereKey(CompanySetting::SINGLETON_ID)
            ->update(['entry_grace_days' => 0]);

        $pool = $this->pool();
        $investor = Investor::factory()->create(['name' => 'خالد']);

        app(InvestorService::class)->recordWalletEntry(new WalletEntryData(
            investorId: (int) $investor->getKey(),
            type: WalletEntryType::Deposit,
            amount: '30000.00',
            method: 'cash',
        ), null);

        $this->withHeaders($this->banker())
            ->postJson("/api/v1/investment-pools/{$pool->getKey()}/capital-requests", [
                'investor_id' => $investor->getKey(),
                'direction' => 'in',
                'amount' => '30000.00',
            ])->assertCreated();

        // Assert — queued, and not yet a partner
        $this->assertSame(0, InvestorDealShare::query()
            ->where('investor_deal_id', $pool->getKey())->count());

        // Act — the boundary comes round
        app(InvestorService::class)->closePeriod($this->openPeriodOf($pool), null);

        // Assert — now he is
        $this->assertSame(1, InvestorDealShare::query()
            ->where('investor_deal_id', $pool->getKey())
            ->where('investor_id', $investor->getKey())
            ->count());
    }

    public function test_the_pool_screen_shows_each_partner_his_weight(): void
    {
        // Arrange — «حصته في النظام», which §2 asks for and the roster did not answer. Derived on
        // the read, stored nowhere: it moves whenever anybody's capital moves.
        $this->term(0);
        $pool = $this->pool();

        $first = Investor::factory()->create(['name' => 'أحمد']);
        $second = Investor::factory()->create(['name' => 'علي']);

        $this->fund($first, $pool, '60000.00');
        $this->fund($second, $pool, '40000.00');

        // Act
        $response = $this->withHeaders($this->banker())
            ->getJson("/api/v1/investment-pools/{$pool->getKey()}");

        // Assert
        $response->assertOk();

        $byName = [];
        foreach ($response->json('data.investors') as $row) {
            $byName[$row['name']] = $row;
        }

        $this->assertSame('60.0000', $byName['أحمد']['share_percent']);
        $this->assertSame('40.0000', $byName['علي']['share_percent']);
    }

    public function test_a_closed_period_says_who_got_what(): void
    {
        // Arrange — **the record that existed and was reachable from nowhere.** Written at the
        // close and read by nothing, so «لماذا أخذت هذا المبلغ؟» had no answer in the app.
        $this->term(0);
        $pool = $this->pool();
        $pool->investor_profit_share_percent = '50.00';
        $pool->save();

        Investor::factory()->create(['name' => 'الشركة', 'is_company' => true]);
        $first = Investor::factory()->create(['name' => 'أحمد']);
        $second = Investor::factory()->create(['name' => 'علي']);

        $this->fund($first, $pool, '60000.00');
        $this->fund($second, $pool, '40000.00');

        InvestmentRealizedEarning::factory()->create([
            'investment_period_id' => $this->openPeriodOf($pool)->getKey(),
            'source_type' => AuditSubject::Order->value,
            'source_id' => 1,
            'amount' => '10000.00',
        ]);

        $period = $this->openPeriodOf($pool);
        app(InvestorService::class)->closePeriod($period, null);

        // Act
        $response = $this->withHeaders($this->banker())
            ->getJson("/api/v1/investment-periods/{$period->getKey()}/shares");

        // Assert — investors' half is 5,000, split 60/40; the company takes the residual 5,000
        $response->assertOk();

        $byName = [];
        foreach ($response->json('data') as $row) {
            $byName[$row['investor_name']] = $row;
        }

        $this->assertSame('3000.00', $byName['أحمد']['net_share']);
        $this->assertSame('2000.00', $byName['علي']['net_share']);
        $this->assertSame('5000.00', $byName['الشركة']['net_share']);
        $this->assertTrue($byName['الشركة']['is_company']);

        // And the weights that were applied, frozen beside the amounts
        $this->assertSame('60.0000', $byName['أحمد']['share_percent']);
        $this->assertSame('60000.00', $byName['أحمد']['capital']);
    }

    public function test_an_open_period_has_divided_nothing_yet(): void
    {
        // Arrange
        $this->term(0);
        $pool = $this->pool();
        $investor = Investor::factory()->create(['name' => 'أحمد']);
        $this->fund($investor, $pool, '50000.00');

        // Act
        $response = $this->withHeaders($this->banker())
            ->getJson("/api/v1/investment-periods/{$this->openPeriodOf($pool)->getKey()}/shares");

        // Assert
        $response->assertOk();
        $this->assertSame([], $response->json('data'));
    }

    public function test_a_period_past_its_end_is_reported_overdue(): void
    {
        // Arrange — **nothing closes a period but a person.** The date is not a deadline the
        // system enforces; it is one it reports.
        $this->term(0);
        $pool = InvestorDeal::factory()->pool()->create();

        InvestmentPeriod::factory()->create([
            'investor_deal_id' => $pool->getKey(),
            'starts_on' => Carbon::today()->subDays(40)->toDateString(),
            'ends_on' => Carbon::today()->subDays(12)->toDateString(),
        ]);

        // Act
        $response = $this->withHeaders($this->banker())
            ->getJson("/api/v1/investment-pools/{$pool->getKey()}/periods");

        // Assert
        $response->assertOk();
        $this->assertTrue($response->json('data.0.is_overdue'));
        $this->assertSame(12, $response->json('data.0.days_overdue'));
    }

    public function test_a_period_still_running_is_not_overdue(): void
    {
        // Arrange
        $this->term(0);
        $pool = $this->pool();

        // Act
        $response = $this->withHeaders($this->banker())
            ->getJson("/api/v1/investment-pools/{$pool->getKey()}/periods");

        // Assert
        $response->assertOk();
        $this->assertFalse($response->json('data.0.is_overdue'));
        $this->assertSame(0, $response->json('data.0.days_overdue'));
    }

    public function test_the_list_names_what_would_refuse_the_close(): void
    {
        // Arrange — the thing that would actually stop somebody pressing the button, said on the
        // screen where the button is rather than discovered by pressing it.
        $this->term(0);
        $pool = $this->pool();

        InvestmentReturnedGoodsQuestion::factory()->create([
            'investor_deal_id' => $pool->getKey(),
            'verdict' => ReturnedGoodsVerdict::Open,
        ]);

        // Act
        $response = $this->withHeaders($this->banker())
            ->getJson("/api/v1/investment-pools/{$pool->getKey()}/periods");

        // Assert
        $response->assertOk();
        $this->assertTrue($response->json('data.0.blocked_by_returned_goods'));
    }

    public function test_a_closed_period_is_never_overdue(): void
    {
        // Arrange — an old closed period is history, not a task
        $this->term(0);
        $pool = InvestorDeal::factory()->pool()->create();

        InvestmentPeriod::factory()->closed()->create([
            'investor_deal_id' => $pool->getKey(),
            'starts_on' => Carbon::today()->subDays(70)->toDateString(),
            'ends_on' => Carbon::today()->subDays(40)->toDateString(),
        ]);

        // Act
        $response = $this->withHeaders($this->banker())
            ->getJson("/api/v1/investment-pools/{$pool->getKey()}/periods");

        // Assert
        $response->assertOk();
        $this->assertFalse($response->json('data.0.is_overdue'));
    }

    public function test_what_has_been_charged_to_the_pool_can_be_read_back(): void
    {
        // Arrange — **the gap that made somebody save the same expense twice.** Only `POST`
        // existed, so a form that worked looked exactly like one that had not.
        $this->term(0);
        $pool = $this->pool();

        app(InvestorService::class)->recordDealExpense(
            $pool,
            new DealExpenseData(
                kind: DealExpenseKind::Storage,
                name: 'تخزين',
                amount: '1000.00',
                incurredOn: now()->toDateString(),
            ),
            null,
        );

        // Act
        $response = $this->withHeaders($this->banker())
            ->getJson("/api/v1/investment-pools/{$pool->getKey()}/expenses");

        // Assert
        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
        $this->assertSame('تخزين', $response->json('data.0.name'));
        $this->assertSame('1000.00', $response->json('data.0.amount'));
        $this->assertTrue($response->json('data.0.is_deducted'));
        $this->assertFalse($response->json('data.0.is_landed'));
        // Charged to the period that is open, which is what the close will actually subtract.
        $this->assertSame(
            $this->openPeriodOf($pool)->getKey(),
            $response->json('data.0.investment_period_id'),
        );
    }

    public function test_a_landed_cost_is_listed_and_marked_as_not_deducted(): void
    {
        // Arrange — shipping and customs typed on a purchase order are already inside the cost of
        // the layers that arrived. Printed identically to a deducted row they invite somebody to
        // add up a total the close does not use.
        $this->term(0);
        $pool = $this->pool();

        $expense = app(InvestorService::class)->recordDealExpense(
            $pool,
            new DealExpenseData(
                kind: DealExpenseKind::Shipping,
                name: 'شحن الحاوية',
                amount: '3400.00',
                incurredOn: now()->toDateString(),
            ),
            null,
        );

        // Only the server sets this — it is what «محسوبة مسبقاً» means.
        $expense->forceFill(['is_landed' => true])->save();

        // Act
        $response = $this->withHeaders($this->banker())
            ->getJson("/api/v1/investment-pools/{$pool->getKey()}/expenses");

        // Assert — listed, and plainly not deducted
        $response->assertOk();
        $this->assertTrue($response->json('data.0.is_landed'));
        $this->assertFalse($response->json('data.0.is_deducted'));

        // And the period's arithmetic agrees: it is recorded beside the sum, never inside it
        $figures = app(InvestorService::class)->periodFigures($this->openPeriodOf($pool));
        $this->assertSame('0.00', $figures['deductible_expenses']);
        $this->assertSame('3400.00', $figures['recorded_only_expenses']);
    }

    public function test_the_investors_register_says_which_row_is_the_company(): void
    {
        // Arrange — **it is not a person.** One renamed or switched off by somebody who took it
        // for an ordinary investor would stop every pool paying the company, silently, at the
        // next close.
        $company = Investor::factory()->create(['name' => 'الشركة', 'is_company' => true]);
        $person = Investor::factory()->create(['name' => 'أحمد']);

        // Act
        $response = $this->withHeaders($this->banker())->getJson('/api/v1/investors');

        // Assert
        $response->assertOk();

        $byId = [];
        foreach ($response->json('data') as $row) {
            $byId[$row['id']] = $row;
        }

        $this->assertTrue($byId[$company->getKey()]['is_company']);
        $this->assertFalse($byId[$person->getKey()]['is_company']);
    }

    public function test_a_man_who_holds_nothing_here_is_not_locked(): void
    {
        // Arrange — no capital in this pool at all. There is nothing to tell him.
        $this->term(6);
        $pool = $this->pool();
        $investor = Investor::factory()->create();

        // Act
        $free = MinimumTerm::freeOn((int) $investor->getKey(), (int) $pool->getKey(), 6);

        // Assert
        $this->assertNull($free);
    }
}
