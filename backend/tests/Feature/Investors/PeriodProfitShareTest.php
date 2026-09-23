<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Investor\Actions\DepositToFund;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Actions\RecordDealExpense;
use App\Domain\Investor\Actions\RecordWalletEntry;
use App\Domain\Investor\DTOs\DealExpenseData;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\DealExpenseKind;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Support\FundDeal;
use App\Domain\Settings\Models\CompanySetting;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

/**
 * نسبةُ المستثمرين تُقرأ من فترة المصدر — لا من الإعداد الحيّ ولا من صفّ الصندوق.
 *
 * **النسخةُ التي تُقسَّم بها ليست النسخةَ التي تُعرَض.** `OpenInvestmentPeriod` ينسخ
 * `investor_profit_share_percent` على كل فترةٍ تُفتح، وهي ما تعرضه لوحةُ الصندوق؛ و`FundDeal`
 * ينسخها مرّةً واحدة على صفّ الصندوق يوم وُلد. **و`InvestorDeal::investorsCutOf()` كانت تقرأ
 * الثانية** — وكلُّ طريقٍ يصل ديناراً إلى محفظة يمرّ بها.
 *
 * فالرقمان يتّفقان اليوم لأن كليهما نُسخ من الإعداد نفسه ولم يغيّره أحد. **ويفترقان أوّلَ ما
 * يُغيَّر:** كلُّ فترةٍ جديدة تعرض النسبة الجديدة ويدفع الدفترُ بالقديمة، بلا رقمٍ واحدٍ يظهر
 * فيه الخلاف — لأن كل رصيدٍ هنا مشيُ صفوف. والفترةُ المغلقة تسجّل القسمة القديمة تحت العنوان
 * الجديد.
 *
 * **ونصُّ القاعدة مكتوبٌ في `FundDeal` منذ ولادته:** «`investor_profit_share_percent` على صفّه
 * هو الافتراضُ يوم وُلد، والحقيقةُ التي تُقسَّم بها فترةٌ منسوخةٌ على صفّها هي». هذه الاختبارات
 * تجعل النصَّ حكماً.
 *
 * **والصفقةُ القديمة لا تُمسّ**: نسبتُها عقدٌ جُمّد يوم مولدها ولا فترةَ له، فتبقى تقرأ صفَّها.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class PeriodProfitShareTest extends TestCase
{
    use RefreshDatabase;

    private function openPeriod(): InvestmentPeriod
    {
        return app(OpenInvestmentPeriod::class)(actorId: null);
    }

    /** يضع النسبةَ في الإعدادات — ما تُنسَخ منه الفتراتُ التي تُفتح بعدها. */
    private function setSharePercent(string $percent): void
    {
        CompanySetting::query()->firstOrFail()
            ->forceFill(['investor_profit_share_percent' => $percent])->save();
    }

    /** مستثمرٌ بوحداتٍ في الصندوق — مالٌ على الطاولة ثم اشتراكٌ به. */
    private function partnerWith(string $amount): Investor
    {
        $investor = Investor::factory()->create();

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

        return $investor;
    }

    /** مصروفٌ على صفقةٍ بتاريخ وقوعه — وهو أقصرُ طريقٍ يمرّ بـ`investorsCutOf`. */
    private function expense(InvestorDeal $deal, string $amount, string $incurredOn): void
    {
        app(RecordDealExpense::class)(
            $deal,
            new DealExpenseData(
                kind: DealExpenseKind::Other,
                name: 'مصروف',
                amount: $amount,
                incurredOn: $incurredOn,
            ),
            null,
        );
    }

    /** ما حُمِّل على المستثمر من هذا المصدر، بقيمته المطلقة. */
    private function chargedTo(Investor $investor): string
    {
        return (string) InvestorWalletEntry::query()
            ->where('investor_id', $investor->id)
            ->where('type', WalletEntryType::Loss)
            ->sum('amount');
    }

    public function test_a_period_charges_by_the_rate_frozen_on_it_not_by_todays_setting(): void
    {
        // Arrange — سبتمبر فُتح على ٥٠٪، ثم رُفع الإعدادُ إلى ٣٠٪ في منتصفه.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->setSharePercent('50.00');
        $september = $this->openPeriod();
        $partner = $this->partnerWith('10000.00');

        $this->setSharePercent('30.00');

        // Act — مصروفُ ألفٍ وقع في سبتمبر.
        Carbon::setTestNow('2026-09-20 09:00:00');
        $this->expense(app(FundDeal::class)(), '1000.00', '2026-09-20');

        // Assert — ٥٠٪ لأن سبتمبر فُتح عليها، لا ٣٠٠ من إعداد اليوم.
        $this->assertSame('50.00', (string) $september->refresh()->investor_profit_share_percent);
        $this->assertSame('500.00', $this->chargedTo($partner));
    }

    public function test_the_next_period_carries_the_new_rate_and_the_ledger_follows_it(): void
    {
        // Arrange — سبتمبر على ٥٠٪ ثم يُغيَّر الإعدادُ، فتُفتح أكتوبر على ٣٠٪.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->setSharePercent('50.00');
        $september = $this->openPeriod();
        $partner = $this->partnerWith('10000.00');

        $this->setSharePercent('30.00');

        Carbon::setTestNow('2026-10-01 09:00:00');
        $september->status = PeriodStatus::Closing;
        $september->save();
        $october = $this->openPeriod();

        // Act — مصروفٌ يقع في نافذة أكتوبر.
        Carbon::setTestNow('2026-10-20 09:00:00');
        $this->expense(app(FundDeal::class)(), '1000.00', $october->starts_on->toDateString());

        // Assert — ٣٠٪، والدفترُ يتبع العنوانَ الذي تعرضه اللوحة.
        $this->assertSame('30.00', (string) $october->refresh()->investor_profit_share_percent);
        $this->assertSame('300.00', $this->chargedTo($partner));
    }

    public function test_the_fund_row_default_never_overrides_the_period_it_was_born_before(): void
    {
        // Arrange — الصندوقُ وُلد على ٥٠٪ ولا يُحدَّث عمودُه أبداً؛ ثم صار الإعدادُ ٢٠٪ وفُتحت
        // فترةٌ عليها. **والصفُّ هو ما كانت `investorsCutOf` تقرأه** — فهذا هو الخلافُ بعينه.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->setSharePercent('50.00');
        $this->openPeriod();
        $partner = $this->partnerWith('10000.00');
        $fund = app(FundDeal::class)();
        $this->assertSame('50.00', (string) $fund->investor_profit_share_percent);

        $this->setSharePercent('20.00');

        Carbon::setTestNow('2026-10-01 09:00:00');
        InvestmentPeriod::query()->where('status', PeriodStatus::Open)
            ->update(['status' => PeriodStatus::Closing->value]);
        $october = $this->openPeriod();

        // Act
        Carbon::setTestNow('2026-10-20 09:00:00');
        $this->expense($fund, '1000.00', $october->starts_on->toDateString());

        // Assert — ٢٠٠ بنسبة الفترة، لا ٥٠٠ بالافتراض المنسوخ على صفّ الصندوق.
        $this->assertSame('50.00', (string) $fund->refresh()->investor_profit_share_percent);
        $this->assertSame('200.00', $this->chargedTo($partner));
    }

    public function test_an_old_deal_keeps_its_own_frozen_rate_whatever_the_period_says(): void
    {
        // Arrange — الصفقةُ القديمة عقدٌ جُمّد يوم مولدها ولا فترةَ له. تغييرُ نسبتها بنسبة
        // الفترة يعيد كتابة اتفاقٍ وُقِّع عليه، وهو أبعدُ ما يكون عن المقصود هنا.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->setSharePercent('20.00');
        $this->openPeriod();

        $deal = InvestorDeal::factory()->create([
            'investor_profit_share_percent' => '50.00',
            'investor_funded_percent' => '100.0000',
        ]);

        // Act + Assert — القسمةُ من صفّها هي، ولو كانت الفترةُ الجارية على ٢٠٪.
        $this->assertSame('1000.00', $deal->investorsCutOf('2000.00'));
    }
}
