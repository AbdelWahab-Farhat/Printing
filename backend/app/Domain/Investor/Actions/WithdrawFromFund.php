<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Enums\UnitEntryType;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Exceptions\CapitalIsStillLocked;
use App\Domain\Investor\Exceptions\FundHasNotGotTheCash;
use App\Domain\Investor\Exceptions\WithdrawalExceedsBalance;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestmentUnit;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\FundCash;
use App\Domain\Investor\Queries\FundUnits;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Investor\Queries\PeriodForEntry;
use App\Domain\Investor\Queries\UnitPrice;
use App\Domain\Investor\Support\FundDeal;
use App\Domain\Investor\Support\Money;
use Illuminate\Support\Facades\DB;

/**
 * مستثمرٌ يسحب رأسَ ماله — ووحداتُه تخرج معه.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحتان ٣ و٤.
 *
 * ```
 * دفترُ الوحدات  ←  cancel          ما يقابل ما استردّه بسعر اليوم
 * دفترُ المحفظة  ←  release         رأسُ ماله يرجع من الصندوق إلى محفظته
 * دفترُ الخزينة  ←  capital_return  نقدٌ خرج من الصندوق
 * ```
 *
 * ## `release` لا `withdrawal` — نقيضُ الاشتراك بالضبط
 *
 * الاشتراكُ `allocation` ينقل المال من المحفظة إلى الصندوق، فالاستردادُ يعيده. و`withdrawal`
 * كان سيُنقص المحفظةَ **ومالُه ليس فيها** — هو في الصندوق — فيُخرج من جيبٍ فارغٍ ويترك جيبَ
 * الصندوق ممتلئاً إلى الأبد.
 *
 * **وما يخرج من يده نقداً حركةٌ ثالثة** يسجّلها من شاشة محفظته (`withdrawal` بطريقة دفع). هذا
 * الفعلُ يُخرجه من الصندوق ويضعه في محفظته، وهناك يقرّر: يأخذه، أو يعيد الاشتراك به في الفترة
 * التالية.
 *
 * **والنسبةُ لا تنفصل عن المال.** سحبٌ لا يُلغي وحداتٍ يترك رجلاً أخذ مالَه وبقيت نسبتُه تقاسم
 * ربحاً لم يعد يموّله — وهو أخطرُ خللٍ ممكنٍ في هذا النظام، لأنه لا يظهر في رصيدٍ واحد: كلُّ
 * الأرقام تبقى «صحيحة» ويُقسَّم الربحُ على قاسمٍ كاذب.
 *
 * ## والحبسُ يُفحص على الوحدات لا على الرصيد
 *
 * المتاحُ للسحب هو **الوحداتُ التي انقضت مدةُ حبسها × سعر اليوم**، ثم سقفُ المحفظة فوقه (يفرضه
 * {@see RecordWalletEntry} كما يفرضه دائماً، من الصفّ المقفول لا من رقمٍ قُرئ قبله). فمن أودع
 * دفعتين يخرج نصفُ ماله في موعده ونصفُه في موعد أخيه.
 *
 * ## والاسترداد بسعر اليوم
 *
 * يُلغى `المبلغ ÷ سعر الوحدة` من وحداته، لا عددٌ ثابتٌ اشتراه يوم دخل. والسعرُ في الحال السويّة
 * قريبٌ من الواحد لأن {@see FundValuation} تطرح الربحَ المستحقّ —
 * فالقيمةُ رأسُ مالٍ عامل. وحين يخسر الصندوقُ ينخفض السعر، فيُلغي الدينارُ وحداتٍ أكثر: من يخرج
 * من صندوقٍ خاسر يحمل نصيبَه من الخسارة ولا يتركه لمن بقي.
 */
final class WithdrawFromFund
{
    public function __construct(
        private readonly UnitPrice $price,
        private readonly FundUnits $units,
        private readonly RecordCashEntry $cash,
        private readonly FundCash $fundCash,
        private readonly FundDeal $fund,
        private readonly InvestorBalances $balances,
        private readonly PeriodForEntry $periodFor,
    ) {}

    /**
     * @return array{wallet_entry: InvestorWalletEntry, units: InvestmentUnit}
     */
    public function __invoke(
        int $investorId,
        string $amount,
        ?int $actorId,
        ?string $notes = null,
    ): array {
        return DB::transaction(function () use ($investorId, $amount, $actorId, $notes): array {
            $investor = Investor::query()->whereKey($investorId)->lockForUpdate()->firstOrFail();
            $id = (int) $investor->getKey();

            $unitPrice = ($this->price)();
            $unlocked = $this->units->unlockedFor($id, now());
            $ceiling = Money::round(bcmul($unlocked, $unitPrice, 8));

            if (bccomp(Money::round($amount), $ceiling, 2) > 0) {
                throw CapitalIsStillLocked::make(
                    $ceiling,
                    Money::round($amount),
                    $this->units->nextUnlockFor($id, now()),
                );
            }

            // **وسقفٌ ثانٍ على النقد.** مالُه ليس في درجٍ ينتظره: قد يكون بضاعةً على رفّ. لا
            // يمنعه الحبسُ ولا سقفُ المحفظة من أن يطلب ما لا يوجد نقداً — وهذا وحده يمنعه.
            $inTheDrawer = ($this->fundCash)();

            if (bccomp(Money::round($amount), $inTheDrawer, 2) > 0) {
                throw FundHasNotGotTheCash::make(Money::round($amount), $inTheDrawer);
            }

            // **يُكتب هنا لا عبر `RecordWalletEntry`**: `release` ليس ممّا يُسجَّل بيد — لا
            // يُفرج عن رأس مالٍ إلا فعلٌ يعرف كم تساوي وحداتُه اليوم، وهذا هو. وسقوفُه الثلاثة
            // فُحصت قبله: مدةُ الحبس، ونقدُ الخزينة، ورأسُ ماله في الصندوق.
            $fund = ($this->fund)();
            $inTheFund = $this->balances->forShare($id, (int) $fund->getKey())['capital'];

            if (bccomp(Money::round($amount), $inTheFund, 2) > 0) {
                throw WithdrawalExceedsBalance::make(Money::round($amount), $inTheFund);
            }

            $walletEntry = new InvestorWalletEntry([
                'amount' => Money::round($amount),
                'occurred_at' => now(),
                'notes' => $notes,
            ]);

            $walletEntry->investor_id = $id;
            $walletEntry->investor_deal_id = $fund->getKey();
            $walletEntry->investment_period_id = $this->periodFor->byDate(now());
            $walletEntry->type = WalletEntryType::Release;
            $walletEntry->recorded_by = $actorId;
            $walletEntry->save();

            ($this->cash)(
                type: CashEntryType::CapitalReturn,
                amount: Money::round($amount),
                sourceType: AuditSubject::InvestorWalletEntry->value,
                sourceId: (int) $walletEntry->getKey(),
                actorId: $actorId,
            );

            $cancelled = new InvestmentUnit;
            $cancelled->investor_id = $id;
            $cancelled->investment_period_id = InvestmentPeriod::open()?->getKey();
            $cancelled->type = UnitEntryType::Cancel;
            $cancelled->units = bcdiv(Money::round($amount), $unitPrice, FundUnits::SCALE);
            $cancelled->unit_price = $unitPrice;
            $cancelled->amount = Money::round($amount);
            $cancelled->source_type = AuditSubject::InvestorWalletEntry->value;
            $cancelled->source_id = $walletEntry->getKey();
            $cancelled->occurred_at = now();
            $cancelled->recorded_by = $actorId;
            $cancelled->save();

            return ['wallet_entry' => $walletEntry, 'units' => $cancelled];
        });
    }
}
