<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Investor\Models\InvestmentUnit;
use DateTimeInterface;
use Illuminate\Database\Eloquent\Collection;

/**
 * كم وحدةً قائمة، ولمن — مشياً على دفتر الوحدات.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحة ٣.
 *
 * لا عمودَ رصيدٍ هنا كبقيّة دفاتر هذا النظام: العددُ مشيُ صفوفٍ بـ{@see InvestmentUnit::signedUnits()}،
 * فالعكسُ نقيضُ ما يعكسه ولا شيء هنا يحتاج أن يعرف ذلك.
 *
 * **والدقةُ ستُّ خانات في كل موضع.** مشيةٌ بخانتين تُسقط أجزاءَ الوحدة من نصيب صاحبها، ثم تظهر
 * فرقاً لا يفسّره أحد يوم تُجمع النسبُ فلا تبلغ مئة.
 */
final class FundUnits
{
    public const SCALE = 6;

    /** كلُّ الوحدات القائمة في الصندوق. */
    public function outstanding(?DateTimeInterface $asOf = null): string
    {
        return $this->walk(null, $asOf);
    }

    /** ما يملكه واحدٌ منها. */
    public function heldBy(int $investorId, ?DateTimeInterface $asOf = null): string
    {
        return $this->walk($investorId, $asOf);
    }

    /**
     * ما يملكه كلُّ واحدٍ، في مشيةٍ واحدة — ما تقرؤه النسب.
     *
     * والصفرُ يُحذف: من ألغى وحداتِه كلَّها ليس شريكاً، وإبقاؤه بصفرٍ يجعله سطراً في كشفٍ لا
     * يعنيه، وقاسماً في قسمةٍ لا نصيب له فيها.
     *
     * @return array<int, string>
     */
    public function byInvestor(?DateTimeInterface $asOf = null): array
    {
        $totals = [];

        foreach ($this->entries($asOf) as $entry) {
            $id = (int) $entry->investor_id;
            $totals[$id] = bcadd($totals[$id] ?? '0', $entry->signedUnits(), self::SCALE);
        }

        return array_filter($totals, fn (string $units): bool => bccomp($units, '0', self::SCALE) > 0);
    }

    /**
     * وحداتُه التي انقضت مدةُ حبسها — وهي وحدها ما يمكن أن يخرج.
     *
     * **الحبسُ على الدفعة لا على الرجل**: «كل deposit Timer خاص به لوحده ويجمد معه». فمن أودع
     * مئةَ ألفٍ في يناير ومئةً في يونيو يُفرَج عن الأولى وحدها في يناير التالي.
     *
     * والإلغاءاتُ السابقة تُطرح من المُفرَج عنه لا من المحبوس: لا يمكن أن يكون قد سحب محبوساً —
     * هذا الحارسُ نفسُه منعه — فما سحبه كان من هذا الجيب.
     */
    public function unlockedFor(int $investorId, DateTimeInterface $on): string
    {
        $unlocked = '0';

        foreach ($this->entries(null) as $entry) {
            if ((int) $entry->investor_id !== $investorId) {
                continue;
            }

            $signed = $entry->signedUnits();

            if (bccomp($signed, '0', self::SCALE) < 0) {
                $unlocked = bcadd($unlocked, $signed, self::SCALE);

                continue;
            }

            if (! $entry->isLockedOn($on)) {
                $unlocked = bcadd($unlocked, $signed, self::SCALE);
            }
        }

        return bccomp($unlocked, '0', self::SCALE) < 0
            ? bcadd('0', '0', self::SCALE)
            : $unlocked;
    }

    /** أقربُ يومٍ يُفرَج فيه عن شيءٍ من وحداته — ما تقوله الرسالةُ لمن طلب سحباً مبكراً. */
    public function nextUnlockFor(int $investorId, DateTimeInterface $on): ?string
    {
        $next = null;

        foreach ($this->entries(null) as $entry) {
            if ((int) $entry->investor_id !== $investorId || ! $entry->isLockedOn($on)) {
                continue;
            }

            $date = $entry->locked_until?->toDateString();

            if ($date !== null && ($next === null || $date < $next)) {
                $next = $date;
            }
        }

        return $next;
    }

    private function walk(?int $investorId, ?DateTimeInterface $asOf): string
    {
        $total = '0';

        foreach ($this->entries($asOf) as $entry) {
            if ($investorId !== null && (int) $entry->investor_id !== $investorId) {
                continue;
            }

            $total = bcadd($total, $entry->signedUnits(), self::SCALE);
        }

        return bcadd($total, '0', self::SCALE);
    }

    /**
     * @return Collection<int, InvestmentUnit>
     */
    private function entries(?DateTimeInterface $asOf)
    {
        return InvestmentUnit::query()
            ->with('reversedEntry')
            // **بـ`occurred_at` لا بـ`created_at`**: «كم كان يملك يوم أُغلقت النافذة» سؤالٌ عن
            // متى وقع الإيداعُ لا متى كُتب، وهو الانضباطُ نفسه في كل دفترٍ هنا. والعكسُ الذي
            // يُكتب بعد الحدّ لا يُحسب داخلَه — فصورةُ ذلك اليوم تبقى صورةَ ذلك اليوم.
            ->when($asOf !== null, fn ($q) => $q->where('occurred_at', '<=', $asOf))
            ->get();
    }
}
