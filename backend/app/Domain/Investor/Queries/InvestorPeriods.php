<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Investor\Models\InvestmentPeriod;

/**
 * فتراتُ مستثمرٍ واحد وربحُه في كلٍّ منها — ما تعرضه صفحتُه بدل الصفقات.
 *
 * قرارُ المالك 2026-09-25: «عرض الفترات بدلا من الصفقات». والصفقةُ القديمة التي دخلت الصندوق
 * «سوف تغلق وتضاف لربحه ومالناش علاقة بيها».
 *
 * **الفترةُ له إن كان شريكاً فيها وحدها** — «الفترات التي مشارك فيها مستثمر فقط سواء منتهية أو
 * مستمرة» — بنسب {@see PeriodShares} نفسِها التي تعرضها شاشةُ الشركاء. **لا بختم صفوفه**: كلُّ
 * صفٍّ في المحفظة يُختم بفترة يومه، فمن اكتتب في نافذة P1 يحمل إيداعُه واكتتابُه ختمَها وهو
 * ينتظر P2 — وهكذا ظهر «بادي 2» في P1.
 *
 * **وربحُه فيها هو ما تقوله له شاشةُ الفترة** ({@see PeriodOrdersQuery})، لا حسابٌ ثانٍ: الصفُّ
 * يُفتح عليها، وصفٌّ يقول رقماً وشاشتُه تقول غيرَه سؤالٌ بلا جواب.
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
        $periods = InvestmentPeriod::query()
            ->orderByDesc('starts_on')
            ->limit(self::MOST_PERIODS)
            ->get();

        $rows = [];

        foreach ($periods as $period) {
            $periodId = (int) $period->getKey();

            if (! isset($this->shares->forPeriod($periodId)[$investorId])) {
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
