<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Investor\Actions\WithdrawFromFund;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestmentUnit;
use App\Domain\Investor\Support\FundDeal;
use App\Domain\Investor\Support\Money;

/**
 * موقفُ مستثمرٍ من الصندوق: ما وضعه فيه، ووحداتُه، ونسبتُه في الفترة الجارية، ودفعاتُه بمواعيد فكّها.
 *
 * **بابان يقرآنه، وتعريفٌ واحد.** بوابتُه يقرؤها هو، وصفحتُه يقرؤها المدير — وكانت الصفحةُ لا
 * تقوله أصلاً: الصندوقُ محذوفٌ من «في الصفقات» عمداً، فكان رجلٌ مالُه كلُّه فيه يُقرأ «رصيد
 * المحفظة 0» و«لا مال له في أي صفقة». نسختان من هذا الحساب في متحكّمين هما الطريقُ إلى أن
 * تختلف الشاشتان على مال رجلٍ واحد.
 *
 * **`capital` ما وضعه ولم يسترده**، من الدفتر كما تقوله لوحةُ الصندوق في سطر كلّ شريك، وهو سقفُ
 * ما يسترده ({@see WithdrawFromFund}). و`value` وحداتُه × سعرَ اليوم — قريبٌ منه في الحال السويّة،
 * وينخفض عنه حين يخسر الصندوق.
 *
 * **والحبسُ دفعةً دفعة** لأنه كذلك: «كل deposit Timer خاص به لوحده». رقمٌ واحد كان سيقول
 * «محبوسٌ إلى ٢٠٢٨» لمن نصفُ ماله يخرج في ٢٠٢٧.
 */
final class FundStanding
{
    public function __construct(
        private readonly FundUnits $units,
        private readonly UnitPrice $price,
        private readonly PeriodShares $shares,
        private readonly InvestorBalances $balances,
        private readonly FundDeal $fund,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function forInvestor(int $investorId): array
    {
        $held = $this->units->heldBy($investorId);
        $price = ($this->price)();
        $open = InvestmentPeriod::open();

        // بلا إنشاء: هذه قراءةٌ لا تكتب. ولا صندوقَ بعد يعني لا مالَ فيه لأحد.
        $fundId = $this->fund->idOrNull();

        $locks = InvestmentUnit::query()
            ->where('investor_id', $investorId)
            ->whereNotNull('locked_until')
            ->whereDoesntHave('reversedBy')
            ->orderBy('locked_until')
            ->get()
            ->map(fn (InvestmentUnit $row): array => [
                'units' => (string) $row->units,
                'amount' => (string) $row->amount,
                'locked_until' => $row->locked_until?->toDateString(),
                'is_locked' => $row->isLockedOn(now()),
            ])
            ->all();

        $shares = $open === null ? [] : $this->shares->forPeriod((int) $open->getKey());

        return [
            'capital' => $fundId === null ? '0.00' : $this->balances->forShare($investorId, $fundId)['capital'],
            'units' => $held,
            'unit_price' => $price,
            'value' => Money::round(bcmul($held, $price, 8)),
            'share_percent' => $shares[$investorId] ?? '0.000000',

            // **صفرٌ بجانب مالٍ في الصندوق سؤالٌ لا خبر.** من اكتتب في نافذة فترةٍ بدأت لا
            // يقاسمها — «تجمد نسبته ولا تحسب له أرباح شهر تسعة إنما تحسب له أرباح شهر عشرة» —
            // فيُقال متى يبدأ نصيبُه بدل أن يُحسب أن مالَه ضاع.
            'share_starts_next_period' => $open !== null
                && ! isset($shares[$investorId])
                && bccomp($held, '0', FundUnits::SCALE) > 0,
            'unlocked_units' => $this->units->unlockedFor($investorId, now()),
            'period' => $open === null ? null : [
                'code' => $open->code,
                'starts_on' => $open->starts_on->toDateString(),
                'ends_on' => $open->ends_on->toDateString(),
                'accepts_capital' => $open->acceptsCapitalOn(now()),
            ],
            'deposits' => $locks,
        ];
    }
}
