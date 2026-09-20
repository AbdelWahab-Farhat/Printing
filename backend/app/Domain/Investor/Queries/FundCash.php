<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Investor\Models\InvestmentCashEntry;
use App\Domain\Investor\Support\Money;

/**
 * كم في خزينة الصندوق الآن — السقفُ الذي يُشترى تحته ويُسحب تحته.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحة ٤.
 *
 * **ولماذا سقفٌ على النقد لا على القيمة.** قيمةُ الصندوق تشمل بضاعةً على رفٍّ وطلبياتٍ لم
 * تُحصَّل. الشراءُ منها — أو السحبُ منها — إنفاقُ مالٍ لم يصل: يُوقّع أمرُ شراء فلا يُدفع،
 * ويُطلَب سحبٌ فلا يوجد في الدرج. فالسقفُ هو ما في الدفتر نقداً، لا ما يساويه الصندوق.
 *
 * وهي المشيةُ نفسُها التي تمشيها {@see FundValuation::cash()} — مستخرجةٌ هنا ليقرأها حارسٌ
 * بلا أن يحسب قيمةَ الصندوق كلَّها لأجل رقمٍ واحد.
 */
final class FundCash
{
    public function __invoke(): string
    {
        $total = '0';

        foreach (InvestmentCashEntry::query()->with('reversedEntry')->get() as $entry) {
            $total = bcadd($total, $entry->signedAmount(), 8);
        }

        return Money::round($total);
    }
}
