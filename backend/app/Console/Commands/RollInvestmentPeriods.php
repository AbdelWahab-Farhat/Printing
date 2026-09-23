<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Models\InvestmentPeriod;
use Illuminate\Console\Command;

/**
 * يُقفل فترةَ الاستثمار في موعدها ويفتح التي تليها — الإغلاقُ الآليّ من §٠.٤ و§٠.٧ في المواصفة.
 *
 * «الفترة الأولى تكون أول ما نرفع الميزة ونبدأ بتشغيل cron وتنتهي في بداية الشهر، ثم تبدأ واحدة
 * جديدة من بداية الشهر.» فالجدولةُ تحفظ ثابتاً واحداً: **فترةٌ مفتوحةٌ دائماً، ولا فترةَ مفتوحةٌ
 * بعد موعدها.** وأوّلُ تشغيلٍ على صندوقٍ بلا فترات يفتح الأولى.
 *
 * ## ولماذا كلَّ ساعةٍ لا منتصفَ الليل
 *
 * الفترةُ تستحقّ الإقفال بعد آخر لحظةٍ من يومها الأخير، والجدولةُ على هذا الصندوق **غيرُ مثبَتة
 * العمل** — وغيابُها صامت. فنداءٌ كلَّ ساعةٍ يُدرك ما فاته سابقُه، والنداءُ الذي لا يجد ما يفعله
 * لا يكتب شيئاً: كلُّ خطوةٍ هنا تسأل عن الحالة قبل أن تكتب، والإقفالُ نفسُه يدفع للشركة الفرقَ لا
 * المبلغ. وحين تصمت كلُّها تقول اللوحةُ «مستحقّة الإقفال منذ…»، والزرُّ اليدويُّ يستدعي الفعلَ نفسَه.
 *
 * ## وصمتُ شهرين يُدرَك في نداءٍ واحد
 *
 * كلُّ شهرٍ يُقفل على حدة ويُفتح بعده الذي يليه: لكلّ فترةٍ نسبُها وحَمَلتُها، فطيُّ شهرين في
 * فترةٍ واحدة يقسم ربحَ أكتوبر بنسب نوفمبر. والحدُّ على الحلقة حارسٌ لخللٍ لا يُتوقّع، لا سقفٌ
 * للصمت.
 *
 * ## والمنتظِراتُ تُتمَّم
 *
 * فترةٌ «قيد الإغلاق» تُتمَّم حين تصل آخرُ طلبياتها ويُحصَّل مالُها، والمستمعُ على الطلبيات بابُ
 * ذلك الأوّل. وهذا ظهيرُه: {@see CloseInvestmentPeriod::finalise()} يُفرج عمّا اجتمع شرطاه ويُقفل
 * ما لم يبقَ له شيء، وإعادتُه على فترةٍ لم يتغيّر فيها شيء لا تكتب شيئاً.
 */
class RollInvestmentPeriods extends Command
{
    /** حارسُ الحلقة — سنتان من الشهور، أبعدُ من أيّ صمتٍ يمرّ بلا أن يلاحظه أحد. */
    private const MOST_PERIODS_PER_RUN = 24;

    protected $signature = 'investment:roll-periods
                            {--dry-run : يقول ما كان سيفعله ولا يكتب شيئاً}';

    protected $description = 'يُقفل فترة الاستثمار التي حلّ موعدها ويفتح التي تليها، ويُتمّ الفترات المنتظِرة';

    public function handle(CloseInvestmentPeriod $close, OpenInvestmentPeriod $open): int
    {
        if ((bool) $this->option('dry-run')) {
            return $this->describe($close);
        }

        $waiting = InvestmentPeriod::query()
            ->where('status', PeriodStatus::Closing)
            ->orderBy('starts_on')
            ->get();

        foreach ($waiting as $period) {
            $after = $close->finalise($period, null);

            if ($after->status === PeriodStatus::Closed) {
                $this->info("أُقفلت الفترة {$after->code} — وصلت آخرُ طلبياتها.");
            }
        }

        for ($step = 0; $step < self::MOST_PERIODS_PER_RUN; $step++) {
            $running = InvestmentPeriod::open();

            if ($running === null) {
                $running = $open(actorId: null);
                $this->info("فُتحت الفترة {$running->code}: {$running->starts_on->toDateString()} ← {$running->ends_on->toDateString()}.");
            }

            if (! $running->isDueToClose(now())) {
                return self::SUCCESS;
            }

            $closed = $close(actorId: null);
            $this->info("أُقفلت الفترة {$closed->code} في موعدها — {$closed->status->label()}.");
        }

        $this->error('توقّفت الحلقة عند حدّها ولم تبلغ فترةً جارية — راجع الفترات.');

        return self::FAILURE;
    }

    /** ما كان سيفعله النداءُ الآن — قراءةٌ لا تكتب شيئاً. */
    private function describe(CloseInvestmentPeriod $close): int
    {
        foreach (InvestmentPeriod::query()->where('status', PeriodStatus::Closing)->orderBy('starts_on')->get() as $period) {
            $owed = count($close->owedOrdersOf($period));

            $this->info("الفترة {$period->code} قيد الإغلاق — تنتظر {$owed} من طلبياتها.");
        }

        $running = InvestmentPeriod::open();

        if ($running === null) {
            $this->info('كانت ستُفتح فترةٌ جديدة.');

            return self::SUCCESS;
        }

        if (! $running->isDueToClose(now())) {
            $this->info("الفترة {$running->code} جارية إلى {$running->ends_on->toDateString()} — لا شيء الآن.");

            return self::SUCCESS;
        }

        $this->info("كانت ستُقفَل الفترة {$running->code} (مستحقّة منذ {$running->daysOverdue(now())} يوم) وتُفتح التالية.");

        return self::SUCCESS;
    }
}
