<?php

declare(strict_types=1);

use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Models\InvestmentPeriod;
use Illuminate\Database\Migrations\Migration;

/**
 * الفترةُ المفتوحة تنتهي على حافّة شهرها — تصحيحُ ما فتحه التقويمُ القديم.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — §٠.٧، الشريحة ١٠.
 *
 * {@see OpenInvestmentPeriod} كان يحسب «البدء + شهر − يوم»، ففُتحت P1 على سيرفر التجربة من ٢٢
 * سبتمبر إلى ٢١ أكتوبر. والقرار: «الفترة الأولى… تنتهي في بداية الشهر، ثم تبدأ واحدة جديدة من
 * بداية الشهر». التقويمُ الجديد يصحّ لما يُفتح بعده؛ وهذا يصحّح الفترةَ القائمة قبله.
 *
 * ## ولماذا عبر النموذج لا `DB::table()`
 *
 * تاريخٌ يراه المستثمر تغيّر، فيُكتب في سجلّ الفترة من أين وإلى أين. والحساب نفسُه منسوخٌ هنا لا
 * مستدعىً من الفعل: الترحيلُ صورةٌ من يومه، ولا يتغيّر إن تغيّر الفعل بعده.
 *
 * ## ولا يقصّ ما مضى
 *
 * إن كانت الحافّةُ الجديدة قد فاتت — نُشر في ٥ أكتوبر — فالقصُّ إلى ٣٠ سبتمبر يُخرج من الفترة
 * أياماً وقعت فيها طلبياتٌ ومصاريفُ مختومةٌ بها. فتبقى كما هي، والتاليةُ تبدأ من الغد التالي لها
 * وتنتهي على حافّة شهرها، فيعود التقويم إلى حافّته وحده.
 *
 * أمامي فقط: لا تاريخَ قديمٌ محفوظ يُرجَع إليه، ولا يلزم — الفترةُ على الحافّة صحيحةٌ في الاتجاهين.
 */
return new class extends Migration
{
    public function up(): void
    {
        $period = InvestmentPeriod::query()->where('status', PeriodStatus::Open)->first();

        if ($period === null) {
            return;
        }

        $edge = $period->starts_on->copy()
            ->startOfMonth()
            ->addMonths(max(1, (int) $period->period_months) - 1)
            ->endOfMonth()
            ->startOfDay();

        if ($edge->equalTo($period->ends_on) || $edge->lessThan(now()->startOfDay())) {
            return;
        }

        $period->ends_on = $edge->toDateString();

        // الأولى نافذتُها كلُّ أيامها (§١٢و)؛ وما بعدها تبقى نافذتُه ولا تتجاوز نهايتَه الجديدة.
        $period->subscription_closes_on = $period->isTheFirstOfTheFund()
            || $period->subscription_closes_on->greaterThan($edge)
            ? $edge->toDateString()
            : $period->subscription_closes_on->toDateString();

        $period->save();
    }

    public function down(): void {}
};
