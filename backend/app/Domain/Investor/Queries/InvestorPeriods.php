<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestorWalletEntry;

/**
 * فتراتُ مستثمرٍ واحد وربحُه في كلٍّ منها — ما تعرضه صفحتُه بدل الصفقات.
 *
 * قرارُ المالك 2026-09-25: «عرض الفترات بدلا من الصفقات». والصفقةُ القديمة التي دخلت الصندوق
 * «سوف تغلق وتضاف لربحه ومالناش علاقة بيها».
 *
 * **ربحُه في الفترة هو ما تقوله له شاشةُ الفترة** ({@see PeriodOrdersQuery})، لا حسابٌ ثانٍ:
 * الصفُّ يُفتح عليها، وصفٌّ يقول رقماً وشاشتُه تقول غيرَه سؤالٌ بلا جواب.
 *
 * **والفترةُ له إن كان شريكاً فيها أو قُيِّد له فيها شيء.** الشريكُ في فترةٍ لم تُعطِ بعدُ يراها
 * بصفرها؛ ومن ليس شريكاً قد يقع تصحيحُ طلبيةٍ قديمة على فترته المفتوحة، فيُرى من أين جاء.
 */
final class InvestorPeriods
{
    /** كما يقطع سجلُّ الفترات — خمس سنواتٍ من الأشهر. */
    private const MOST_PERIODS = 60;

    public function __construct(
        private readonly PeriodShares $shares,
        private readonly PeriodOrdersQuery $orders,
    ) {}

    /**
     * @return list<array{id: int, code: string, profit: string}> الأحدثُ أوّلاً
     */
    public function forInvestor(int $investorId): array
    {
        $stamped = InvestorWalletEntry::query()
            ->where('investor_id', $investorId)
            ->whereNotNull('investment_period_id')
            ->distinct()
            ->pluck('investment_period_id')
            ->mapWithKeys(fn ($id): array => [(int) $id => true])
            ->all();

        $periods = InvestmentPeriod::query()
            ->orderByDesc('starts_on')
            ->limit(self::MOST_PERIODS)
            ->get();

        $rows = [];

        foreach ($periods as $period) {
            $periodId = (int) $period->getKey();
            $isPartner = isset($this->shares->forPeriod($periodId)[$investorId]);

            if (! $isPartner && ! isset($stamped[$periodId])) {
                continue;
            }

            $taken = collect(($this->orders)($periodId)['investors'])
                ->firstWhere('investor_id', $investorId);

            $rows[] = [
                'id' => $periodId,
                'code' => (string) $period->code,
                'profit' => $taken['amount'] ?? '0.00',
            ];
        }

        return $rows;
    }
}
